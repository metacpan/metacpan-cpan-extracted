use v5.40;
use blib;
use Acme::Parataxis qw[async fiber await_sleep];
use Acme::Parataxis::Ticker;
use Test2::V1 -ipP;
use Time::HiRes 'time';
$|++;
sub live_count { Acme::Parataxis::get_live_fiber_count() }

# Receipt-based cadence margins measure the host as much as the ticker: shared CI runners wake timers tens of
# milliseconds late, which stretches the mean and span receipts and starves the fired count with no ticker logic
# involved. This is not Stress-only: the macOS legs of the regular CI matrix measured mean 0.123s, span 3.57s and
# fired 4 against limits of 0.110/3.10/5, while a quiet local run sits at 0.100/2.90/7. Stress jobs (marked by
# PARATAXIS_STRESS_*) are the same problem turned up further. Every CI task script exports AUTOMATED_TESTING=1 and
# local ./Build test does not, so those margins run at full strength only where a quiet host can be assumed. The
# dropped >= 3 bound is one of those margins: dropped counts up with fired, fired starves first on a late host, and
# a stress macOS leg measured dropped 2, so it rides the same gate. The structural assertions in the same subtests
# (fired = dropped + pending, pending <= 1, monotonic receipts) still run everywhere; dropped counts only superseded
# fired ticks, so the identity holds exactly even when a late wakeup makes the ticker leapfrog boundaries (those are
# counted separately as skipped, never fired).
my $stress_env  = !!( $ENV{PARATAXIS_STRESS_SECONDS} || $ENV{PARATAXIS_STRESS_ITER} );
my $skip_timing = $stress_env || !!$ENV{AUTOMATED_TESTING};
subtest 'strict cadence under load: 100ms ticks hold their period while do_work takes 30ms' => sub {
    my @arrivals;
    async {
        my $tick = Acme::Parataxis::Ticker->new( interval => 100 );
        while ( my $t = $tick->wait_next ) {
            push @arrivals, time;
            last if @arrivals >= 30;
            await_sleep(30);    # do_work
        }
        $tick->stop;
    };
    is scalar @arrivals, 30, 'collected 30 ticks';
    my $span = $arrivals[-1] - $arrivals[0];
    my $mean = $span / $#arrivals;
    cmp_ok $mean, '>=', 0.090, 'mean period stayed at (or just under) the nominal 100ms';
    cmp_ok $span, '>',  2.70,  'the 29 periods spanned a little under 3 seconds';
    if ($skip_timing) {
        note 'upper cadence margins skipped: automated CI hosts wake timers late enough that these would measure the host, not the ticker';
    }
    else {
        cmp_ok $mean, '<=', 0.110, 'and never crept up towards 130ms - the 30ms of work did not accumulate';
        cmp_ok $span, '<',  3.10,  'and not a millisecond more: no drift over several seconds';
    }

    # Control: the loop the Ticker exists to replace, with the same work and the same nominal period.
    my ( $n_start, $cycles );
    async {
        $cycles  = 12;
        $n_start = time;
        for ( 1 .. $cycles ) { await_sleep(30); await_sleep(100) }
    };
    my $naive = ( time - $n_start ) / $cycles;
    cmp_ok $naive,         '>', 0.120, 'control: the naive do_work + await_sleep loop really does drift (~130ms a cycle)';
    cmp_ok $naive - $mean, '>', 0.015, 'and lands measurably slower per cycle than the Ticker, so the cadence above is not vacuous';
};
subtest 'a slow consumer drops ticks instead of queueing them up' => sub {
    my ( $fired, $dropped, $pending, @got );
    async {
        my $tick = Acme::Parataxis::Ticker->new( interval => 40 );
        await_sleep(300);    # nobody is listening: several periods go by
        $fired   = $tick->fired;
        $dropped = $tick->dropped;
        $pending = $tick->pending;
        while ( my $t = $tick->wait_next ) {
            push @got, $t;
            last if @got >= 3;
            await_sleep(150);    # still far slower than the 40ms period
        }
        $tick->stop;
    };
    if ($skip_timing) {
        note 'fired and receipt-gap margins skipped: automated CI hosts wake timers late enough that these would measure the host, not the ticker';
    }
    else {
        cmp_ok $fired,   '>=', 5, 'several ticks fired while nobody was listening';
        cmp_ok $dropped, '>=', 3, 'the superseded ticks were dropped rather than kept';
    }
    is $dropped + $pending, $fired, 'every fired tick is pending or dropped, never kept';
    cmp_ok $pending,    '<=', 1, 'only one uncollected tick was ever outstanding - there is no stale-tick backlog to work through';
    cmp_ok scalar @got, '>=', 2, 'the slow consumer still received ticks';
    ok( ( !grep { $got[$_] <= $got[ $_ - 1 ] } 1 .. $#got ), 'each tick it received is newer than the last - no stale tick is replayed' );
    if ( !$skip_timing ) {
        cmp_ok $got[1] - $got[0], '>', 0.08, 'and consecutive receipts jumped over whole periods instead of draining them one by one';
    }
};
subtest 'stop() releases a parked wait_next and leaves no fiber behind' => sub {
    my $base = live_count();
    my $res  = 'UNSET';
    my $elapsed;
    async {
        my $tick = Acme::Parataxis::Ticker->new( interval => 5000 );
        my $f    = fiber { $res = $tick->wait_next };
        await_sleep(30);    # let the consumer park on the 5s period
        my $t0 = time;
        $tick->stop;
        $f->await;
        $elapsed = time - $t0;
    };
    ok !defined $res, 'the parked wait_next returned undef rather than sitting out the full 5s period';
    cmp_ok $elapsed, '<', 2, 'and it was released promptly by stop()';
    is live_count(), $base, 'no fiber was left behind once the ticker stopped';
};
subtest 'stop() is idempotent and wait_next is undef afterwards' => sub {
    my ( $first, $post, $st1, $st2, $pre, $base );
    $base = live_count();
    async {
        my $tick = Acme::Parataxis::Ticker->new( interval => 30 );
        $first = $tick->wait_next;
        $st1   = $tick->stop;
        $st2   = $tick->stop;
        $post  = $tick->wait_next;
    };
    ok defined $first, 'the first tick arrived';
    ok $st1,           'stop() reports that it did work the first time';
    ok !$st2,          'and is a no-op the second time';
    ok !defined $post, 'wait_next returns undef once the ticker has stopped';

    # Stopping before the ticker ever produces a tick must still end wait_next immediately.
    async {
        my $tick = Acme::Parataxis::Ticker->new( interval => 5000 );
        $tick->stop;
        $pre = defined $tick->wait_next ? 'tick' : 'undef';
    };
    is $pre,         'undef', 'a ticker stopped before its first tick ends wait_next straight away';
    is live_count(), $base,   'and neither stopped ticker left a fiber running';
};
subtest 'a Ticker built outside run() still ticks inside it, and wait_next croaks off-fiber' => sub {
    my $built = Acme::Parataxis::Ticker->new( interval => 60 );
    like dies { $built->wait_next }, qr/scheduled fiber/, 'wait_next croaks when called outside a scheduled fiber';
    my $got;
    async { $got = $built->wait_next; $built->stop };
    ok defined $got, 'constructed before run(), it still delivered a tick once the scheduler was running';
    is live_count(), 0, 'and stopped cleanly';
};
#
done_testing;
