use strict;
use warnings;

use Test::More;
use t::Utils;

BEGIN {
    use_ok( 'AnyEvent::Promises', 'make_promise', 'deferred' );
}

subtest make_promise_with_success => sub {
    run_event_loop(
        sub {
            my $cv = shift;
            my $p1 = make_promise('ok');
            my $p2 = make_promise( sub {'ok'} );
            $p1->then(
                sub {
                    ok( $p2->is_fulfilled,
                        'in next tick promise from code is fulfilled too' );
                }
            );
            ok( $p1->is_fulfilled,
                'promise created from value is fulfilled' );
            ok( $p2->is_pending,
                'promise from code is pending, code was not evaluated yet' );
            my $w; $w = AE::timer(0,0, sub {undef $w; $cv->send });
        }
    );
};

subtest make_promise_with_throw => sub {
    my @data;
    run_event_loop(
        sub {
            my $cv = shift;
            my $p = make_promise( sub {die "oops\n"} );
            ok( $p->is_pending,
                'promise from code is pending, code was not evaluated yet' );
            $p->then(sub {
                fail("promise is rejected");
            }, sub {
                is( shift(), "oops\n", "make_promise created a rejected response");
            })->then( sub { $cv->send;  });
        }
    );
};

done_testing();
