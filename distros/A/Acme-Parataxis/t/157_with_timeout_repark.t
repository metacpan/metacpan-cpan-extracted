use v5.40;
use blib;
use Time::HiRes     qw[time];
use Acme::Parataxis qw[async fiber nursery await_sleep with_timeout];
use Acme::Parataxis::Channel;
use Acme::Parataxis::CancellationToken;
use Acme::Parataxis::Nursery;
use Test2::V1 -ipP;
$|++;

# R2 regression: with_timeout's re-park branch (Parataxis.pm "parent interrupted mid-await while the child is still
# parked"). The parent must not unwind its frame while the child's coroutine is mid-park; it re-parks registered for the
# child's death, so the scheduler lets the child unwind and reaps it before the frame unwinds. (The 0xC0000005 crash
# this branch used to guard against -- destroying a parked coroutine -- is fixed at the C layer; the branch
# is retained so an abandoned child dies by unwinding rather than being yanked.) Two interrupt sources exercise it:
#   (a) a nursery cancelling a child that is parked in a with_timeout await (deterministic, no timing);
#   (b) an enclosing with_timeout deadline firing while the child is parked in an inner nursery join.
subtest 'a nursery cancelling a child parked in a with_timeout await reaps the grandchild' => sub {
    my ( $err, $inner_done ) = ( undef, 0 );
    my $base = Acme::Parataxis::get_live_fiber_count();
    async {
        $err = dies {
            nursery(
                sub ($n) {
                    $n->spawn(
                        sub {
                            with_timeout( 0, sub { await_sleep(300); $inner_done = 1 } );
                        }
                    );
                    $n->spawn( sub { die 'boom' } );
                }
            );
        };
    };
    ok ref($err) && $err->isa('Acme::Parataxis::Error::Nursery'), 'the nursery aggregate is thrown';
    like "$err", qr/^nursery failure: boom\b/, 'the real failure is the primary';
    ok !$inner_done, 'the grandchild inside the with_timeout was cancelled, not run to completion';
    is Acme::Parataxis::get_live_fiber_count(), $base, 'no fiber leaked: the still-parked grandchild coroutine was reaped without crashing';
};
subtest 'the enclosing deadline fires while the child is parked in an inner nursery join' => sub {
    my ( $err, $done ) = ( undef, 0 );
    my $base = Acme::Parataxis::get_live_fiber_count();
    async {
        $err = dies {
            with_timeout(
                20,
                sub {    # outer deadline: fires while the inner child is still parked
                    with_timeout(
                        0,
                        sub {    # inner frame: exists only to be interrupted out from under
                            nursery(
                                sub ($n) {
                                    $n->spawn( sub { await_sleep(300); $done = 1 } );
                                    $n->spawn( sub { await_sleep(300) } );
                                }
                            );
                        }
                    );
                }
            );
        };
    };
    ok ref($err) && $err->isa('Acme::Parataxis::Error::Timeout'), 'the outer timeout propagates to the caller';
    ok !$done,                                                    'the deepest grandchild was cancelled and drained by the teardown';
    is Acme::Parataxis::get_live_fiber_count(), $base, 'no fiber leaked: the still-parked grandchild coroutine was reaped without crashing';
};
subtest 'the scheduler is clean afterwards: a later with_timeout runs normally' => sub {
    my $second;
    async {
        eval {
            with_timeout(
                20,
                sub {
                    with_timeout(
                        0,
                        sub {
                            nursery(
                                sub ($n) {
                                    $n->spawn( sub { await_sleep(300) } );
                                }
                            );
                        }
                    );
                }
            );
        };
        $second = eval {
            with_timeout( 300, sub { await_sleep(2); 'still-works' } );
        };
    };
    is $second, 'still-works', 'with_timeout works after a re-park teardown';
};
subtest 'innermost deadline wins, the outermost acts as backstop' => sub {
    my ( $err, $elapsed );
    my $ch = Acme::Parataxis::Channel->new;
    async {
        my $t0 = time;
        $err = dies {
            with_timeout(
                20,
                sub {
                    with_timeout( 2000, sub { $ch->get } );
                }
            );
        };
        $elapsed = ( time - $t0 ) * 1000;
    };
    ok ref($err) && $err->isa('Acme::Parataxis::Error::Timeout'), 'the outer 20ms bound aborts the inner 2000ms bound';
    ok $elapsed < 1000,                                           "aborted by the outer bound at ${elapsed}ms, not left to the inner bound";
};
subtest 'the outer deadline still kills a re-park after the inner fires' => sub {
    my ( $inner_at, $inner_err, $repark_at, $repark_err );
    my $ch = Acme::Parataxis::Channel->new;
    async {
        with_timeout(
            300,
            sub {
                my $t0 = time;
                $inner_err = dies {
                    with_timeout( 30, sub { $ch->get } );
                };
                $inner_at = ( time - $t0 ) * 1000;
                my $t1 = time;
                $repark_err = dies { $ch->get };
                $repark_at  = ( time - $t1 ) * 1000;
            }
        );
    };
    ok ref($inner_err)  && $inner_err->isa('Acme::Parataxis::Error::Timeout'),  'the inner deadline fires first';
    ok ref($repark_err) && $repark_err->isa('Acme::Parataxis::Error::Timeout'), 'the outer deadline kills the re-park too';
    ok $repark_at < 2000, "re-park lost at ${repark_at}ms under the 300ms backstop, it did not hang";
};
subtest 're-parking after the deadline fired fails fast instead of deadlocking' => sub {
    my ( $e1, $e2, $elapsed );
    my $ch = Acme::Parataxis::Channel->new;
    async {
        with_timeout(
            50,
            sub {
                $e1 = dies { $ch->get };
                my $t1 = time;
                $e2      = dies { $ch->get };
                $elapsed = ( time - $t1 ) * 1000;
            }
        );
    };
    ok( $e1 && ref($e1) && $e1->isa('Acme::Parataxis::Error::Timeout'), 'the first park timed out' );
    ok(
        $e2 && ref($e2) && $e2->isa('Acme::Parataxis::Error::Timeout'),
        'the re-park under the fired deadline failed fast with ::Timeout (no deadlock)'
    );
    ok $elapsed < 500, "re-park failed fast at ${elapsed}ms, it did not wait";
};
subtest 'a re-park reuses the armed timer instead of arming a second one' => sub {
    my ( $first_err, $repark_err, $repark_at, $jobs );
    my $ch  = Acme::Parataxis::Channel->new;
    my $sig = Acme::Parataxis::Channel->new;
    async {
        my $tok = Acme::Parataxis::CancellationToken->new;
        fiber { await_sleep(20); $tok->cancel; $sig->put(1) };
        fiber {
            with_timeout(
                700, $tok,
                sub {
                    $first_err = dies { $ch->get };
                    my $t0 = time;
                    $repark_err = dies { $ch->get };
                    $repark_at  = ( time - $t0 ) * 1000;
                }
            );
        };
        $sig->get;    # the canceller fiber is done and its sleep job reclaimed: outstanding is exactly the one ~700ms helper
        $jobs = Acme::Parataxis::get_outstanding_jobs();
        await_sleep(700);
    };
    ok( $first_err && ref($first_err) && $first_err->isa('Acme::Parataxis::Error::Cancelled'), 'the cancel token tore the first park' );
    is $jobs, 1, 'only the original deadline helper is armed: the re-park did not stack a second timer for the same bound';
    ok(
        $repark_err && ref($repark_err) && $repark_err->isa('Acme::Parataxis::Error::Timeout'),
        'the re-park was served by the reused helper (::Timeout), so it did not deadlock'
    );
    ok $repark_at < 5000 && $repark_at > 400, "re-park resolved at ${repark_at}ms - by the ~700ms deadline helper, not instantly";
};
subtest 'a cancel scope and a with_timeout deadline coexist on one park' => sub {
    my ( $err, $done );
    async {
        my $ch  = Acme::Parataxis::Channel->new;
        my $tok = Acme::Parataxis::CancellationToken->new;
        fiber {
            $tok->register;
            $err = dies {
                with_timeout( 2000, sub { $ch->get } );
            };
            $done = 1;
        };
        await_sleep(20);
        $tok->cancel;
        await_sleep(30);
    };
    ok $done, 'the park settled';
    ok( $err && ref($err) && $err->isa('Acme::Parataxis::Error::Cancelled'), 'the cancel scope tore the deadline-bound park' );
};
#
done_testing;
