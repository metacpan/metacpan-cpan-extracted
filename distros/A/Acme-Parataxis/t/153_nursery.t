use v5.40;
use blib;
use Acme::Parataxis qw[run spawn fiber yield await_sleep with_timeout nursery async];
use Acme::Parataxis::CancellationToken;
use Acme::Parataxis::Nursery;
use Test2::V1 -ipP;
$|++;
{

    package DtorProbe;
    our $n = 0;
    sub new     { bless {}, shift }
    sub DESTROY { $n++ }
}
subtest 'all children are joined before the block returns; the block value comes back' => sub {
    my @done;
    my $rv = async {
        nursery(
            sub ($n) {
                $n->spawn( sub { await_sleep(5); push @done, 'a' } );
                $n->spawn( sub { await_sleep(5); push @done, 'b' } );
                $n->spawn( sub { await_sleep(5); push @done, 'c' } );
                return 42;
            }
        );
    };
    is $rv,                     42,      'nursery returned the block value';
    is join( ',', sort @done ), 'a,b,c', 'all three children ran to completion before the nursery returned';
};
subtest 'a failing child cancels its siblings and the nursery throws an aggregate' => sub {
    my ( $s1, $s2 ) = ( 0, 0 );
    my $err;
    async {
        $err = dies {
            nursery(
                sub ($n) {
                    $n->spawn( sub { await_sleep(50); $s1 = 1 } );
                    $n->spawn( sub { await_sleep(50); $s2 = 1 } );
                    $n->spawn( sub { die 'boom' } );
                }
            );
        };
    };
    ok ref($err) && $err->isa('Acme::Parataxis::Error::Nursery'), 'a Nursery aggregate error was thrown';
    like "$err", qr/^nursery failure: boom\b/, 'the aggregate stringifies to its primary (natural) failure';
    my $primary = $err->primary;
    like "$primary", qr/^boom\b/, 'the first non-cancelled failure is the primary';
    my @kinds = map {
        eval { $_->kind }
            // 'plain'
    } $err->failures;
    is join( ',', sort @kinds ), 'cancelled,cancelled,plain', 'the failure list mixes the real error with the cancelled siblings';
    ok !$s1 && !$s2, 'the sleeping siblings were cancelled mid-wait, never reaching their finish line';
};
subtest 'cancellation propagates into nested waits and tokens' => sub {
    my ( $wt_done, $tok_done ) = ( 0, 0 );
    async {
        eval {
            nursery(
                sub ($n) {
                    $n->spawn(
                        sub {
                            with_timeout( 80, sub { await_sleep(100); $wt_done = 1 } );
                        }
                    );
                    $n->spawn( sub { die 'boom' } );
                }
            );
        };
        eval {
            nursery(
                sub ($n) {
                    $n->spawn(
                        sub {
                            my $tok = Acme::Parataxis::CancellationToken->new;
                            $tok->register;
                            await_sleep(100);
                            $tok_done = 1;
                            $tok->unregister;
                        }
                    );
                    $n->spawn( sub { die 'boom' } );
                }
            );
        };
    };
    ok !$wt_done,  'a child parked inside a with_timeout was cancelled (propagated to the nested deadline token)';
    ok !$tok_done, 'a child parked on its own registered token was cancelled';
};
subtest 'the nursery token is public: cancelling it cancels the children' => sub {
    my $done = 0;
    async {
        eval {
            nursery(
                sub ($n) {
                    is ref( $n->token ), 'Acme::Parataxis::CancellationToken', 'the block sees the nursery token';
                    $n->token->cancel;
                    $n->spawn( sub { await_sleep(30); $done = 1 } );
                }
            );
        };
    };
    ok !$done, 'a user-cancelled token cancels the children like a failed sibling';
};
subtest 'a block error cancels its children, drains them, and rethrows the block error' => sub {
    my ( $block_err, $done ) = ( undef, 0 );
    async {
        $block_err = dies {
            nursery(
                sub ($n) {
                    $n->spawn( sub { await_sleep(50); $done = 1 } );
                    die 'block died';
                }
            );
        };
    };
    like "$block_err", qr/^block died/, 'the block error propagates unchanged';
    ok !$done, 'the child was cancelled, not left running';
};
subtest 'a nursery inside with_timeout propagates the timeout and drains its children' => sub {
    my ( $t_err, $done ) = ( undef, 0 );
    async {
        $t_err = dies {
            with_timeout(
                10,
                sub {    # deadline shorter than the join, so the enclosing timeout must win
                    nursery(
                        sub ($n) {
                            $n->spawn( sub { await_sleep(200); $done = 1 } );
                            $n->spawn( sub { await_sleep(200) } );
                        }
                    );
                }
            );
        };
    };
    ok ref($t_err) && $t_err->isa('Acme::Parataxis::Error::Timeout'), 'the enclosing timeout wins over the join';
    ok !$done,                                                        'the children were cancelled and drained, not left running';
};
subtest 'destructors of in-flight children run during cancellation' => sub {
    $DtorProbe::n = 0;
    async {
        eval {
            nursery(
                sub ($n) {
                    $n->spawn( sub { my $d = DtorProbe->new; await_sleep(50) } );
                    $n->spawn( sub { die 'boom' } );
                }
            );
        };
    };
    is $DtorProbe::n, 1, 'the cancelled child gave back its in-flight object while unwinding';
};
subtest 'a bare fiber inside the block is not adopted by the nursery' => sub {
    my $plain = 0;
    async {
        nursery(
            sub ($n) {
                fiber { await_sleep(2); $plain = 1 };
            }
        );
        ok !$plain, 'the bare fiber is not joined by the nursery and is still running when it returns';
    };
    ok $plain, 'the independent fiber completed on its own after the nursery returned';
};
subtest 'no orphan fibers on any exit path' => sub {
    my $base = Acme::Parataxis::get_live_fiber_count();
    async {
        eval {
            nursery(
                sub ($n) {
                    $n->spawn( sub { await_sleep(20) } );
                    $n->spawn( sub { die 'x' } );
                }
            );
        };
        nursery(
            sub ($n) {
                $n->spawn( sub {1} );
                $n->spawn( sub { await_sleep(1); 'ok' } );
            }
        );
    };
    is Acme::Parataxis::get_live_fiber_count(), $base, 'success and failure paths both leave zero live fibers';
};
subtest 'nursery() and ->spawn croak outside a scheduled fiber' => sub {
    like dies {
        nursery( sub {1} )
    }, qr/scheduled fiber/, 'nursery() croaks at the top level';
    my $n = Acme::Parataxis::Nursery->new;
    like dies {
        $n->spawn( sub {1} )
    }, qr/scheduled fiber/, '->spawn croaks at the top level';
};
#
done_testing;
