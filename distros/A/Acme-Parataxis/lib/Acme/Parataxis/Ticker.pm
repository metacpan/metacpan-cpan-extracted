use v5.40;
no warnings qw[experimental::class recursion];
use feature 'class';
#
class Acme::Parataxis::Ticker v0.1.1 {
    use Carp qw[croak];
    use Time::HiRes     qw[time];
    use Acme::Parataxis qw[await_sleep];
    use Acme::Parataxis::CancellationToken;
    use Acme::Parataxis::Channel;

    # A drift-free interval timer. `while (1) { do_work(); await_sleep($ms) }` runs every $ms *plus* however long
    # do_work took, so the loop drifts later and later. A Ticker instead sleeps only the *remainder* of each
    # interval, measured against absolute tick boundaries, so ticks land on the boundary regardless of how long the
    # consumer took to ask for the last one.
    #
    # A background fiber walks those boundaries and try_put's each tick time into a capacity-1 channel. Before each
    # put it drains whatever the consumer has not collected yet, so exactly one tick can ever be outstanding and it
    # is always the newest: a slow consumer silently loses ticks instead of accumulating a stale backlog it would
    # then have to work through.
    field $interval : reader : param;    # milliseconds between ticks
    field $channel;                      # capacity 1 - the single un-collected tick, if any
    field $stop_token;                   # interrupts the ticker fiber's await_sleep when stop() is called
    field $running : reader = false;
    field $fired   : reader = 0;         # ticks produced
    field $dropped : reader = 0;         # ticks discarded: superseded uncollected ones (boundaries missed while the

    # host slept past the schedule are counted as skipped, never as fired)
    field $skipped : reader = 0;         # tick boundaries leapfrogged after a late wakeup: never fired, never delivered

    # after waking far behind schedule
    field $next_at;                      # absolute time of the next tick boundary
    ADJUST {
        croak 'Ticker->new( interval => $ms ) requires a positive interval' unless defined $interval && $interval > 0;
        $channel    = Acme::Parataxis::Channel->new( capacity => 1 );
        $stop_token = Acme::Parataxis::CancellationToken->new( kind => 'cancel' );
        $running    = true;
        my $interval_s = $interval / 1000;

        # The boundary math rides Acme::Parataxis::mock_time, so inside run( virtual => 1 ) a Ticker created during
        # the run ticks on *virtual* boundaries and can be driven with Parataxis->advance; outside one it is the wall
        # clock, exactly as before.
        $next_at = Acme::Parataxis::mock_time() + $interval_s;
        Acme::Parataxis::fiber {

            # stop() interrupts the sleep below (which also recalls the armed pool job, so a stopped ticker never
            # keeps the run alive); the interrupt surfaces as an exception out of await_sleep and unwinds here.
            # The catch is deliberately empty: that throw is how stop() gets in, and a real fault in the loop has
            # always been swallowed rather than escalated to the fiber's owner.
            try {
                $stop_token->register;
                while ($running) {
                    my $remain = $next_at - Acme::Parataxis::mock_time();
                    await_sleep( $remain * 1000 ) if $remain > 0;
                    last unless $running;

                    # Newest wins: drop the tick the consumer never collected before publishing this one.
                    while ( $channel->size ) {
                        my ( $got, $stale ) = $channel->try_get;
                        last unless $got;
                        $dropped++;
                    }
                    $channel->try_put($next_at);
                    $fired++;
                    $next_at += $interval_s;

                    # Wound far behind schedule: leapfrog the boundaries already missed rather than burst-firing
                    # them all at once on the next pass. Never fired, so they cannot count as dropped: the invariant
                    # fired == dropped + pending + consumed (Ticker.pod) stays exact on hosts that wake timers late.
                    while ( $next_at <= Acme::Parataxis::mock_time() ) { $next_at += $interval_s; $skipped++ }
                }
            }
            catch ($e) { }

            # A finished fiber must not stay registered on the token, or a later stop() would interrupt an id that
            # no longer names a live waiter.
            try { $stop_token->unregister } catch ($e) {
            }
            ();
        };
    }

    # Block until the next tick. Returns the tick's scheduled time, or undef once the ticker has been stopped, so
    # `while (my $t = $tick->wait_next) { ... }` terminates on stop(). Must run inside a scheduled fiber.
    method wait_next () {
        my $fid = Acme::Parataxis->current_fid;
        croak 'wait_next() must be called from inside a scheduled fiber' if $fid < 0;
        return undef unless $running;
        my ( $got, $tick ) = $channel->try_get;
        return $tick if $got;

        # Park on the channel. stop() shuts the channel down, which releases this wait with undef, so a consumer
        # can never hang on a ticker that was stopped underneath it. The semaphore's re-check makes a tick that
        # lands between try_get and here arrive without an extra park.
        my $v = $channel->get;
        return undef unless $running;
        return $v;
    }

    # Halt the ticker: stop publishing, release any consumer parked in wait_next, and interrupt the ticker fiber's
    # sleep so it unwinds and its armed pool job is recalled. Idempotent, and safe before the fiber ever runs.
    method stop () {
        return 0 unless $running;
        $running = false;
        $channel->shutdown;
        $stop_token->cancel;
        return 1;
    }

    # Ticks still waiting to be collected (0 or 1; never a backlog).
    method pending () { $channel->size }
};
#
1;
