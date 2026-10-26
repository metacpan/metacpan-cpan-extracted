use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield await_sleep with_timeout atomically retry];
use Acme::Parataxis::TVar;    # compile the STM class up front so ->new is available before any atomically runs
use Test2::V1 -ipP;
$|++;
subtest 'a single-writer transfer commits exactly once' => sub {
    my $a = Acme::Parataxis::TVar->new( value => 100 );
    my $b = Acme::Parataxis::TVar->new( value => 100 );
    my ( $runs, $rv );
    async {
        my $f = fiber {
            $rv = atomically {
                $runs++;
                my $from = $a->get;
                my $to   = $b->get;
                $a->set( $from - 50 );
                $b->set( $to + 50 );
                1;
            };
        };
        $f->await;
    };
    is $runs,     1,   'the block ran exactly once (clean single-writer commit)';
    is $rv,       1,   'the transaction value is the block.s return';
    is $a->value, 50,  'debit committed';
    is $b->value, 150, 'credit committed';
};
subtest 'classic deadlock: opposing transfers roll back and retry, neither hangs' => sub {
    my $a = Acme::Parataxis::TVar->new( value => 100 );
    my $b = Acme::Parataxis::TVar->new( value => 100 );
    my ( $r1, $r2 );
    async {
        my $f1 = fiber {
            $r1 = atomically {
                my $x = $a->get;
                my $y = $b->get;
                yield;    # open a gap so the two transactions overlap
                $a->set( $x - 40 );
                $b->set( $y + 40 );
                1;
            };
        };
        my $f2 = fiber {
            $r2 = atomically {
                my $x = $b->get;
                my $y = $a->get;
                yield;    # opposite direction, same account pair
                $b->set( $x - 40 );
                $a->set( $y + 40 );
                1;
            };
        };
        $f1->await;
        $f2->await;
    };
    is $r1,                   1,   'transfer A->B committed';
    is $r2,                   1,   'transfer B->A committed';
    is $a->value + $b->value, 200, 'the ledger is conserved after rollback-retry';
};
subtest 'writes are invisible until commit' => sub {
    my $v = Acme::Parataxis::TVar->new( value => 1 );
    my $seen;
    async {
        my $w = fiber {
            atomically {
                my $x = $v->get;
                $v->set( $x + 1000 );    # staged only - must not leak
                yield;                   # stall inside the transaction
                1;
            };
        };
        my $reader = fiber { $seen = $v->value };    # committed read, no transaction
        $reader->await;
        $w->await;
    };
    is $seen,     1,    'a parallel reader sees the pre-transaction value while the write is staged';
    is $v->value, 1001, 'the write lands only after commit';
};
subtest 'retry parks on the read set and wakes when a read TVar changes' => sub {
    my $v = Acme::Parataxis::TVar->new( value => 0 );
    my $got;
    async {
        my $w = fiber {
            $got = atomically {
                my $x = $v->get;
                retry unless $x;    # parks the fiber until $v changes
                $x;
            };
        };
        await_sleep(30);            # let the executor schedule the waiter past the park
        ok $v->waiters >= 1, 'the retry waiter is registered on the TVar it read';

        # NB: a bare $v->get / $v->set here would itself croak ("must occur inside an atomically
        # block") - the waiter's read was already journaled by the fiber's own atomically above,
        # and a retry waiter only wakes on a *commit* to a TVar it read:
        atomically( sub { $v->set(7) } );    # a commit is what wakes a retry waiter
        $w->await;
    };
    is $got, 7, 'retry reran and returned once its read TVar changed';
    ok $v->waiters == 0, 'the waiter deregistered after the wake';
};
subtest 'a nested atomically joins the outer log (read-your-writes)' => sub {
    my $a = Acme::Parataxis::TVar->new( value => 10 );
    my $got;
    async {
        my $f = fiber {
            $got = atomically {
                my $x = $a->get;
                $a->set( $x + 5 );
                my $inner = atomically {
                    my $y = $a->get;      # must see the staged +5
                    $a->set( $y * 2 );    # joins the outer write set
                    $y;
                };
                $inner;
            };
        };
        $f->await;
    };
    is $got,      15, 'inner atomically saw the outer write (read-your-writes)';
    is $a->value, 30, 'the nested write set committed as one transaction';
};
subtest 'with_timeout aborts a parked transaction cleanly' => sub {
    my $v = Acme::Parataxis::TVar->new( value => 1 );
    my $caught;
    async {
        my $f = fiber {
            $caught = dies {
                with_timeout(
                    30,
                    sub {
                        atomically {
                            my $x = $v->get;
                            $v->set( $x + 1 );
                            retry;    # park; the deadline must interrupt the txn
                            1;
                        };
                    }
                );
            };
        };
        $f->await;
    };
    ok ref($caught) && $caught->isa('Acme::Parataxis::Error::Timeout'), 'a timeout interrupts a retry-parked transaction';
    is $v->value, 1, 'the aborted transaction committed nothing';
};
subtest 'TVar / atomically / retry croak outside the right context' => sub {
    my $v = Acme::Parataxis::TVar->new( value => 1 );
    like dies { $v->get }, qr[TVar operations must occur inside a scheduled fiber], 'get() outside a fiber';
    like dies {
        atomically( sub {1} )
    }, qr[must be called from inside a scheduled fiber], 'atomically() outside a fiber';
    async {
        fiber {
            like dies { $v->get },    qr[TVar operations must occur inside an atomically block],    'get() outside a txn';
            like dies { $v->set(2) }, qr[TVar operations must occur inside an atomically block],    'set() outside a txn';
            like dies {retry},        qr[retry\(\) must be called from inside an atomically block], 'retry() outside a txn';
            like dies {retry},        qr[inside],                                                   'retry() outside a fiber';
            like dies {retry},        qr[retry\(\) must be called from inside an atomically block], 'retry() outside a txn';
            like dies { $v->get },    qr[TVar operations must occur inside an atomically block],    'get() must still go through the txn';
        };
    };
};
#
done_testing;
