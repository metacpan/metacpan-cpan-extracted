use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield await_sleep];
use Acme::Parataxis::Semaphore;
use Acme::Parataxis::Signal;
use Acme::Parataxis::Channel;
use Acme::Parataxis::CancellationToken;
use Acme::Parataxis::Future;
use Test2::V1 -ipP;
use experimental 'class';
$|++;

class Local::Txn {
    field $out : param;
    field $seq : param = 0;
    method act     { ${$out} .= "a$seq" }
    method DESTROY { ${$out} .= "d$seq" }
}

sub wait_sem ( $s = undef ) {
    $s //= Acme::Parataxis::Semaphore->new( count => 0 );
    $s->down;
}
subtest 'register/unregister bookkeeping' => sub {
    async {
        my $tok = Acme::Parataxis::CancellationToken->new;
        is $tok->waiters,    0,                            'no waiters to start';
        is $tok->register,   Acme::Parataxis->current_fid, 'register returns the current fiber id';
        is $tok->waiters,    1,                            'one waiter after register';
        is $tok->register,   Acme::Parataxis->current_fid, 're-registering is deduped';
        is $tok->waiters,    1,                            'still one waiter (deduped)';
        is $tok->unregister, Acme::Parataxis->current_fid, 'unregister returns the fiber id';
        is $tok->waiters,    0,                            'no waiters after unregister';
        ok !$tok->cancelled, 'token not cancelled';
    };
};
subtest 'cancel wakes a parked fiber with Error::Cancelled' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
    async {
        my $tok = Acme::Parataxis::CancellationToken->new;
        my $w   = fiber {
            $tok->register;
            my $e = dies { wait_sem($sem) };
            $tok->unregister;
            die $e if $e;
        };
        yield;    # let the fiber park on the semaphore
        is $sem->waiters, 1, 'one fiber parked on the semaphore';
        $tok->cancel;
        my $caught = dies { $w->await };
        ok $caught,                                                           'cancelled fiber did not return normally';
        ok ref($caught) && $caught->isa('Acme::Parataxis::Error::Cancelled'), 'await rethrows Error::Cancelled to the parent';
        is $sem->waiters, 0, 'cancelled waiter was deregistered from the semaphore';
    };
};
subtest 'cancel is idempotent' => sub {
    async {
        my $tok = Acme::Parataxis::CancellationToken->new;
        ok $tok->cancel,    'first cancel returns true';
        ok !$tok->cancel,   'second cancel is a no-op';
        ok $tok->cancelled, 'token stays cancelled';
    };
};
subtest 'a cancelled token interrupts the next park of a running fiber' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
    my $got = '';
    async {
        my $tok = Acme::Parataxis::CancellationToken->new;
        my $w   = fiber {
            $tok->register;
            $got .= 'A';
            yield;    # running, between parks
            my $e = dies { wait_sem($sem) };
            $got .= ( $e && ref $e && $e->isa('Acme::Parataxis::Error::Cancelled') ) ? 'B' : 'C';
            $tok->unregister;
            return;    # the fiber survives; only the interrupted wait died
        };
        yield;
        $tok->cancel;    # while the fiber is running, not parked
        $w->await;
    };
    is $got, 'AB', 'the next park after cancel throws immediately';
};
subtest 'unregister prevents a later cancel' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
    my $got = '';
    async {
        my $tok = Acme::Parataxis::CancellationToken->new;
        my $w   = fiber {
            $tok->register;
            $tok->unregister;
            wait_sem($sem);
            $got .= 'W';
        };
        yield;
        $tok->cancel;    # nobody left registered
        ok $tok->cancelled, 'token cancelled';
        $sem->up;        # the waiter still wakes normally
        $w->await;
    };
    is $got, 'W', 'an unregistered fiber is not interrupted by cancel';
};
subtest 'error surface: wait_reason and kind' => sub {
    async {
        my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
        my $tok = Acme::Parataxis::CancellationToken->new;
        my $w   = fiber {
            $tok->register;
            my $e = dies { wait_sem($sem) };
            $tok->unregister;
            die $e if $e;
            return;
        };
        yield;
        $tok->cancel;
        my $caught = dies { $w->await };
        ok ref($caught) && $caught->isa('Acme::Parataxis::Error::Cancelled'), 'Error::Cancelled delivered';
        is $caught->kind,             'cancelled',      'kind() is "cancelled"';
        is $caught->wait_reason->[0], 'Semaphore down', 'wait_reason names the parked wait';
    };
};
subtest 'a cancelled parked fiber does not leave a stale id behind' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
    async {
        my $tok = Acme::Parataxis::CancellationToken->new;
        my $w   = fiber {
            $tok->register;
            my $val = eval { wait_sem($sem) };
            $tok->unregister;
            return;
        };
        yield;
        $tok->cancel;                                # interrupts and deregisters the parked fiber, freeing its id
        my $ok = eval { $w->await; 1 };
        ok defined eval {1}, 'sanity: process healthy after cancellation';
        my $n = fiber { wait_sem($sem); 'held' };    # reuses the freshly freed id
        is $sem->waiters, 1, 'a new fiber parked on the same semaphore';
        $sem->up;
        is $n->await,     'held', 'up wakes only the new fiber (no spurious wake)';
        is $sem->waiters, 0,      'no stray waiters remain';
    };
};
subtest 'destructors run while a cancelled wait unwinds' => sub {
    my $trace = '';
    my $sem   = Acme::Parataxis::Semaphore->new( count => 0 );
    async {
        my $tok = Acme::Parataxis::CancellationToken->new;
        my $w   = fiber {
            $tok->register;
            my $tx = Local::Txn->new( out => \$trace, seq => 1 );
            $tx->act;                           # a1
            my $e = dies { wait_sem($sem) };    # parked here when cancelled
            $tok->unregister;
            die $e if $e;
            return;
        };
        yield;
        $tok->cancel;
        my $caught = dies { $w->await };
        ok $caught, 'wait aborted by the cancel';
    };
    like $trace, qr/^a1d1/, 'the in-scope destructor ran during the unwind';
};
subtest 'channel: blocking getter is cancelled cleanly' => sub {
    my $ch = Acme::Parataxis::Channel->new( capacity => 1 );
    my @got;
    async {
        my $tok = Acme::Parataxis::CancellationToken->new;
        my $w   = fiber {
            $tok->register;
            my $e = dies { push @got, $ch->get; () };
            $tok->unregister;
            die $e if $e;
            return;
        };
        yield;
        is $ch->size, 0, 'channel empty: getter is parked';
        $tok->cancel;
        my $caught = dies { $w->await };
        ok $caught, 'blocked getter cancelled';
        my $z = fiber { push @got, $ch->get; 'z' };
        $ch->put('fresh');
        $z->await;
        is $got[0], 'fresh', 'a later getter still receives data after a cancelled getter';
    };
};
#
done_testing;
