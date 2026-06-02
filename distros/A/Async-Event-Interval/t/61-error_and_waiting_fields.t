use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use Test::More;
use Time::HiRes ();

use Async::Event::Interval;

my $mod = 'Async::Event::Interval';

# Poll-until-condition with a wall-clock deadline. Replaces fixed select()
# sleeps in blocks that wait for an asynchronous state transition (callback
# crash registers, restart clears flag, etc.) so the tests are robust on
# slow VMs without inflating wall-clock on healthy runs. Returns 1 on
# condition met, 0 on deadline hit.

sub poll_until {
    my ($cond, $timeout) = @_;
    $timeout //= 5;
    my $deadline = Time::HiRes::time() + $timeout;
    while (! $cond->()) {
        return 0 if Time::HiRes::time() >= $deadline;
        select(undef, undef, undef, 0.05);
    }
    return 1;
}

# --- 'error' field --------------------------------------------------------

# 1: brand-new event (never started) → error=0
{
    my $e = $mod->new(0, sub {});
    is $e->info->{error}, 0, "new event: info() error=0";
    my $snap = $mod->events;
    is $snap->{$e->id}{error}, 0, "new event: events() error=0";
}

# 2: healthy running event → error=0
{
    my $e = $mod->new(0.1, sub {});
    $e->start;
    select(undef, undef, undef, 0.25);
    is $e->info->{error}, 0, "running event: info() error=0";
    my $snap = $mod->events;
    is $snap->{$e->id}{error}, 0, "running event: events() error=0";
    $e->stop;
}

# 3: callback dies (one-shot) → error=1
{
    my $e = $mod->new(0, sub { die "boom\n" });
    $e->start;
    poll_until(sub { $e->info->{error} == 1 });
    is $e->info->{error}, 1, "one-shot crash: info() error=1";
    my $snap = $mod->events;
    is $snap->{$e->id}{error}, 1, "one-shot crash: events() error=1";
}

# 4: callback dies (interval mode) → error=1
{
    my $e = $mod->new(0.1, sub { die "boom\n" });
    $e->start;
    poll_until(sub { $e->info->{error} == 1 });
    is $e->info->{error}, 1, "interval crash: info() error=1";
    my $snap = $mod->events;
    is $snap->{$e->id}{error}, 1, "interval crash: events() error=1";
}

# 5: error=1 persists until restart
{
    my $e = $mod->new(0, sub { die "boom\n" });
    $e->start;
    poll_until(sub { $e->info->{error} == 1 });
    is $e->info->{error}, 1, "persistent error: first snapshot";
    select(undef, undef, undef, 0.2);
    is $e->info->{error}, 1, "persistent error: second snapshot still 1";
}

# 6: restart() resets error=0 in the snapshot
# Uses a slow interval so we can observe error=0 in the window before
# the next iteration fires and crashes again.
{
    my $e = $mod->new(2, sub { die "boom\n" });
    $e->start;
    # Poll on error() (not info->{error}) so the _detect_crash side effect
    # clears _started; otherwise restart() warns "Event already running..."
    # on slow VMs where the child sets the shared flag before it exits.
    poll_until(sub { $e->error });
    is $e->info->{error}, 1, "after crash: error=1";

    $e->restart;
    select(undef, undef, undef, 0.2);
    is $e->info->{error}, 0, "right after restart: error=0 (cleared)";

    $e->stop;
}

# 7: timeout() breach → error=1
{
    my $e = $mod->new(0, sub { select(undef, undef, undef, 5) });
    $e->timeout(1);
    $e->start;
    poll_until(sub { $e->info->{error} == 1 });
    is $e->info->{error}, 1, "timeout breach: info() error=1";
}

# 8: stop() does NOT set error=1
{
    my $e = $mod->new(0.1, sub {});
    $e->start;
    select(undef, undef, undef, 0.3);
    $e->stop;
    is $e->info->{error}, 0, "after stop(): error=0";
}

# 9: external kill → error=1 via _detect_crash fallback
{
    my $e = $mod->new(60, sub { sleep 60 });
    $e->immediate(1);
    $e->start;
    select(undef, undef, undef, 0.3);
    my $pid = $e->pid;
    ok $pid, "external-kill setup: have pid";
    kill 'KILL', $pid;
    select(undef, undef, undef, 0.3);
    # Trigger _detect_crash by calling error()
    $e->error;
    is $e->info->{error}, 1, "external SIGKILL: info() error=1 via fallback";
}

# 10: errors count and error flag are independent
{
    my $e = $mod->new(0, sub { die "boom\n" });
    $e->start;
    # Poll on error() so _detect_crash runs (clears _started, increments
    # crash bookkeeping) before we look at the shared errors counter.
    poll_until(sub { $e->error });
    is $e->errors, 1, "first crash: errors=1";
    is $e->info->{error}, 1, "first crash: error=1";

    $e->restart;
    poll_until(sub { $e->error });
    is $e->errors, 2, "second crash: errors=2 (cumulative)";
    is $e->info->{error}, 1, "second crash: error=1 (current)";
}

# 11: multi-event independence
{
    my $crash = $mod->new(0, sub { die "boom\n" });
    my $ok    = $mod->new(0.1, sub {});
    $crash->start;
    $ok->start;
    select(undef, undef, undef, 0.4);
    my $snap = $mod->events;
    is $snap->{$crash->id}{error}, 1, "multi-event: crashed event has error=1";
    is $snap->{$ok->id}{error},    0, "multi-event: healthy event has error=0";
    $ok->stop;
}

# 12: events() error field matches error() method
{
    my $e = $mod->new(0, sub { die "boom\n" });
    $e->start;
    # Poll on error() so _detect_crash has set _crashed before the
    # equality check; otherwise the shared flag may be 1 while the
    # method-form returns 0 (child not yet observed dead).
    poll_until(sub { $e->error });
    my $method = $e->error ? 1 : 0;
    is $e->info->{error}, $method,
        "snapshot error matches error() method ($method)";
}

# --- 'waiting' field ------------------------------------------------------

# 13: brand-new event (never started) → waiting=1
{
    my $e = $mod->new(0, sub {});
    is $e->info->{waiting}, 1, "new event: info() waiting=1";
    my $snap = $mod->events;
    is $snap->{$e->id}{waiting}, 1, "new event: events() waiting=1";
}

# 14: healthy running interval event → waiting=0
{
    my $e = $mod->new(0.1, sub {});
    $e->start;
    select(undef, undef, undef, 0.25);
    is $e->info->{waiting}, 0, "running interval: info() waiting=0";
    my $snap = $mod->events;
    is $snap->{$e->id}{waiting}, 0, "running interval: events() waiting=0";
    $e->stop;
}

# 15: after stop() → waiting=1
{
    my $e = $mod->new(0.1, sub {});
    $e->start;
    select(undef, undef, undef, 0.3);
    $e->stop;
    is $e->info->{waiting}, 1, "after stop(): info() waiting=1";
}

# 16: one-shot finished cleanly → waiting=1
{
    my $e = $mod->new(0, sub {});
    $e->start;
    select(undef, undef, undef, 0.4);
    is $e->info->{waiting}, 1, "one-shot done: info() waiting=1";
}

# 17: crashed callback → waiting=1 (paired with error=1)
{
    my $e = $mod->new(0, sub { die "boom\n" });
    $e->start;
    poll_until(sub { $e->info->{error} == 1 });
    is $e->info->{waiting}, 1, "crashed: info() waiting=1";
    is $e->info->{error},   1, "crashed: info() error=1";
}

# 18: timeout breach → waiting=1
{
    my $e = $mod->new(0, sub { select(undef, undef, undef, 5) });
    $e->timeout(1);
    $e->start;
    poll_until(sub { $e->info->{waiting} == 1 });
    is $e->info->{waiting}, 1, "timeout breach: info() waiting=1";
}

# 19: restart() → waiting=0 again
{
    my $e = $mod->new(0.1, sub {});
    $e->start;
    select(undef, undef, undef, 0.2);
    $e->stop;
    is $e->info->{waiting}, 1, "before restart: waiting=1";
    $e->restart;
    select(undef, undef, undef, 0.2);
    is $e->info->{waiting}, 0, "after restart: waiting=0";
    $e->stop;
}

# 20: snapshot waiting field matches waiting() method
{
    my $e = $mod->new(0.1, sub {});
    $e->start;
    select(undef, undef, undef, 0.2);
    my $method = $e->waiting ? 1 : 0;
    is $e->info->{waiting}, $method,
        "running: snapshot waiting matches waiting() method ($method)";
    $e->stop;

    my $method2 = $e->waiting ? 1 : 0;
    is $e->info->{waiting}, $method2,
        "stopped: snapshot waiting matches waiting() method ($method2)";
}

# 21: multi-event mixed states
{
    my $running = $mod->new(0.1, sub {});
    my $stopped = $mod->new(0.1, sub {});
    $running->start;
    $stopped->start;
    select(undef, undef, undef, 0.2);
    $stopped->stop;

    my $snap = $mod->events;
    is $snap->{$running->id}{waiting}, 0, "multi-event: running has waiting=0";
    is $snap->{$stopped->id}{waiting}, 1, "multi-event: stopped has waiting=1";
    $running->stop;
}
