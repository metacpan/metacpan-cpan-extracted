use v5.40;
use blib;
use Acme::Parataxis qw[run fiber yield await_sleep];
use Test2::V1 -ipP;
$|++;

# Regression: destroying a fiber while it is parked mid-yield. destroy_coro used to walk the parked fiber's live
# context stack and free its activation slots in the shared PadLists / global CvDEPTH counters of the subroutines it
# was inside (yield, the wait helpers, run). Those slots belong to every fiber activating the same sub at the same
# depth, so the *next* fiber to enter one -- usually the very next round, once the freed id is reused -- died with a
# 0xC0000005 in Perl_clear_defarray. The C fix only unwalks a fiber whose context stack has been unwound to
# exhaustion (si_cxix < 0, i.e. reaped after finishing); a parked fiber's shared slots are left to normal reuse, and
# its own closures release their pads with user_cv. Every round below destroys a parked fiber and then runs a fresh
# one, so the freed id is reused; before the fix rounds 2+ crashed the interpreter.
subtest 'destroying a fiber parked on a bare yield then reusing its id survives repeated rounds' => sub {
    for my $round ( 1 .. 3 ) {
        run(
            sub {
                my $parked = fiber { yield('WAITING'); 7 };
                ok !$parked->is_done, "round $round: the fiber is parked";
                Acme::Parataxis::destroy_coro( $parked->fid );
                my $g = fiber {7};
                is $g->await, 7, "round $round: a fiber created after the destroy still runs";
            }
        );
    }
};
subtest 'destroying a fiber parked in a scheduled wait (await_sleep) is safe too' => sub {
    run(
        sub {
            my $parked = fiber { await_sleep(1000); 1 };
            ok !$parked->is_done, 'the sleeper is parked on its job';
            Acme::Parataxis::destroy_coro( $parked->fid );
            my $g = fiber {7};
            is $g->await, 7, 'a fiber created after destroying a sleep-parked fiber still runs';
        }
    );
};
subtest 'destroying a finished fiber is unaffected (control)' => sub {
    run(
        sub {
            my $done = fiber {7};
            $done->await;
            Acme::Parataxis::destroy_coro( $done->fid );
            my $g = fiber {7};
            is $g->await, 7, 'a fiber created after destroying a finished fiber still runs';
        }
    );
};
#
done_testing;
