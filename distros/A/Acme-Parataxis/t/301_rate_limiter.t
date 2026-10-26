use v5.40;
no warnings 'recursion';    # fibers run on separate heap stacks; Perl's C-stack-depth heuristic misfires there
use blib;
use Acme::Parataxis qw[async fiber yield await_sleep with_timeout dump_fibers];
use Acme::Parataxis::RateLimiter;
use Test2::V1 -ipP;
use Time::HiRes 'time';
$|++;

# Fibers run on separate heap stacks; Perl's C-stack-depth heuristic can misfire and falsely report "Deep recursion"
# (it ignores lexical 'no warnings' once a framework such as Test2 is loaded). Genuine runaway recursion inside a fiber
# surfaces as a hang, access violation, or croak the harness already catches, so filter the noise.
BEGIN {
    $SIG{__WARN__} = sub { return if $_[0] =~ /^Deep recursion on subroutine/; warn @_ }
}
sub live_count { Acme::Parataxis::get_live_fiber_count() }
my $BASE      = live_count();
my $FIBER_CAP = Acme::Parataxis::get_max_fibers();    # platforms without MAP_NORESERVE (OpenBSD) clamp this to what fits under RLIMIT_DATA

# The 3x+1 upper bound on the span below is an upper cadence margin, and like the ticker's it measures the host as
# much as the limiter: shared CI runners wake timers tens of milliseconds late, which stretches the span with no
# limiter logic involved. A macOS leg of the regular CI matrix measured 8.62s against the 7.9s bound while the same
# run sits comfortably inside on a quiet local host. Every CI task script exports AUTOMATED_TESTING=1 and local
# ./Build test does not, so this margin runs at full strength only where a quiet host can be assumed. The structural
# assertions in the same subtest (no overshoot, cost >= theoretical, no fiber left behind) still run everywhere; only
# this upper bound relaxes.
my $stress_env  = !!( $ENV{PARATAXIS_STRESS_SECONDS} || $ENV{PARATAXIS_STRESS_ITER} );
my $skip_timing = $stress_env || !!$ENV{AUTOMATED_TESTING};
subtest 'thousands of concurrent acquire never exceed rate x wall-time + burst' => sub {

    # The worker count is a deliberate load shape rather than the old hard 1024 table ceiling, which set_max_fibers
    # replaced: the fiber table grows on demand now. On platforms without MAP_NORESERVE the library clamps the
    # default fiber limit to the data-segment budget, so the burst is scaled to leave room for the ticker and the
    # run fiber; the "thousands" still come from each worker acquiring again as tokens refill.
    my ( $workers, $each, $rate, $burst ) = ( $FIBER_CAP < 800 ? $FIBER_CAP - 8 : 800, 3, 1000, 100 );
    my $N = $workers * $each;
    my ( $t0, @t );
    async {
        my $rl = Acme::Parataxis::RateLimiter->new( rate => $rate, burst => $burst );
        $t0 = time;
        my @fibers = map {
            fiber {
                for ( 1 .. $each ) { $rl->acquire(1); push @t, time }
            }
        } 1 .. $workers;
        $_->await for @fibers;
        $rl->stop;
    };
    @t = sort { $a <=> $b } @t;
    is scalar @t, $N, "all $N acquisitions completed";

    # The guarantee: by elapsed time T at most rate*T + burst requests may have been served, so the request
    # numbered k cannot have completed before (k - burst)/rate.
    my ( $viol, $worst ) = ( 0, 0 );
    for my $k ( 1 .. @t ) {
        my $need = ( $k - $burst ) / $rate;
        my $over = $need - ( $t[ $k - 1 ] - $t0 );
        $worst = $over if $over > $worst;
        $viol++ if $over > 0.002;    # 2ms of slack for clock granularity
    }
    is $viol, 0, sprintf( 'not one acquire beat rate x elapsed + burst (worst overshoot %.1fms)', $worst * 1000 );
    my $span = $t[-1] - $t0;
    my $need = ( $N - $burst ) / $rate;
    cmp_ok $span, '>=', $need - 0.002, sprintf( 'and the run cost at least the theoretical %.2fs', $need );
    if ($skip_timing) {
        note 'upper-bound margin skipped: automated CI hosts wake timers late enough that this would measure the host, not the limiter';
    }
    else {
        cmp_ok $span, '<', $need * 3 + 1, 'and finished near the requested rate instead of stalling';
    }
    is live_count(), $BASE, 'no fiber left behind';
};
subtest 'acquires park when the bucket is empty and resume as tokens refill - no busy-wait' => sub {
    my ( $waited, $row );
    async {
        my $rl = Acme::Parataxis::RateLimiter->new( rate => 10, burst => 1 );
        $rl->acquire(1);
        is $rl->tokens, 0, 'the single burst token has been spent, so the bucket is empty';
        my $t0 = time;
        my $f  = fiber { $rl->acquire(1); $waited = time - $t0 };

        # Let it park without sleeping: main sleeping here would let a refill land first.
        my $n = 0;
        yield while $rl->waiters == 0 && $n++ < 20_000;
        is $rl->waiters, 1, 'the acquire parked on the empty bucket';
        ($row) = grep { $_->{fid} == $f->fid } @{ dump_fibers() };
        is $row->{state},     'WAITING',             'it is parked, not spinning - a busy-wait would show RUNNABLE or RUNNING';
        is $row->{reason}[0], 'RateLimiter acquire', 'and its wait reason names the limiter';
        $f->await;
        is $rl->waiters, 0, 'the refill woke it and it left the waiter list';
        $rl->stop;
    };
    cmp_ok $waited, '>=', 0.080, 'it waited for the ~100ms refill rather than spinning straight through';
    cmp_ok $waited, '<',  0.500, 'and woke on that refill rather than hanging';
    is live_count(), $BASE, 'no fiber left behind';
};
subtest 'a deadline interrupts a parked acquire and the waiter unregisters' => sub {
    my ( $err, $parked_waiters, $after_waiters, $later );
    async {
        my $rl = Acme::Parataxis::RateLimiter->new( rate => 2, burst => 1 );    # one token, then one per 500ms
        $rl->acquire(1);
        my $f = fiber {
            $err = dies {
                with_timeout( 80, sub { $rl->acquire(1) } );
            };
        };
        my $n = 0;
        yield while $rl->waiters == 0 && $n++ < 20_000;
        $parked_waiters = $rl->waiters;
        $f->await;
        $after_waiters = $rl->waiters;

        # The bucket must still be usable: a later acquire still collects a token when one is refilled.
        my $g = fiber { $rl->acquire(1); $later = 1 };
        $g->await;
        $rl->stop;
    };
    is $parked_waiters, 1, 'the acquire really was parked on the empty bucket when the deadline was armed';
    ok ref($err) && $err->isa('Acme::Parataxis::Error::Timeout'), 'the deadline threw Error::Timeout';
    is $after_waiters, 0, 'the interrupted waiter unregistered itself, so no later refill can wake a fiber that no longer wants a token';
    ok $later, 'the bucket still hands out tokens afterwards';
    is live_count(), $BASE, 'no fiber left behind';
};
subtest 'burst-vs-strict-rate: the burst is instant, the sustained rate is exactly rate' => sub {
    my ( $burst_ms, $steady_ms );
    async {
        my $rl = Acme::Parataxis::RateLimiter->new( rate => 50, burst => 20 );    # 20 instant, then 1 per 20ms
        my $t0 = time;
        $rl->acquire(1) for 1 .. 20;
        $burst_ms = ( time - $t0 ) * 1000;
        my $t1 = time;
        $rl->acquire(1) for 1 .. 5;
        $steady_ms = ( time - $t1 ) * 1000;
        $rl->stop;
    };
    cmp_ok $burst_ms,  '<',  20,  'all 20 burst tokens were spent back to back, without waiting a period between them';
    cmp_ok $steady_ms, '>=', 70,  'once empty, 5 more tokens cost at least 4 refill periods - the sustained rate is real';
    cmp_ok $steady_ms, '<',  400, 'and no more than that, so it settles on rate rather than some fraction of it';
    is live_count(), $BASE, 'no fiber left behind';
};
subtest 'stop() lets a parked acquirer through instead of stranding it' => sub {
    my ( $released, $post, $st1, $st2 );
    async {
        my $rl = Acme::Parataxis::RateLimiter->new( rate => 1, burst => 1 );
        $rl->acquire(1);
        my $f = fiber { $rl->acquire(1); $released = 1 };
        my $n = 0;
        yield while $rl->waiters == 0 && $n++ < 20_000;
        is $rl->waiters, 1, 'a fiber is parked waiting for a token';
        $st1 = $rl->stop;
        $f->await;
        $st2  = $rl->stop;
        $post = dies { $rl->acquire(1) };
    };
    ok $released, 'the parked acquire was released when the limiter stopped, so the run could end';
    ok $st1,      'stop() reports it did work the first time';
    ok !$st2,     'and is a no-op the second time';
    like $post, qr/stopped/, 'a later acquire croaks instead of parking forever with nobody to refill';
    is live_count(), $BASE, 'no fiber left behind';
};
#
done_testing;
