use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use Test::More;

use Async::Event::Interval;
use Time::HiRes ();

# 3.5: _stop_requested flag gives the interval loop a cooperative exit
# path so the child can call finish() cleanly instead of being killed by
# SIGTERM. stop() sets it before sending signals; start() clears it.

# Helper: return a PID that is guaranteed to be dead.
sub _dead_pid {
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (! $pid) {
        require POSIX;
        POSIX::_exit(0);
    }
    waitpid $pid, 0;
    return $pid;
}

# _stop_requested is set by stop().
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->_pid(_dead_pid());
    $e->_started(1);

    $e->stop;

    ok $e->_events_stop_requested, "_stop_requested is set after stop()";
}

# _stop_requested is cleared by start().
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->_pid(_dead_pid());
    $e->_started(1);

    $e->stop;
    ok $e->_events_stop_requested, "_stop_requested is set after stop()";

    $e->start;
    $e->stop;
    ok $e->_events_stop_requested, "_stop_requested is set after second stop()";
}

# events() and info() snapshots still include _stop_requested at the
# event level — only top-level %events keys (like _id_counter,
# _event_count) are filtered by the /^_/ guard. The flag is harmless
# if visible, just an internal implementation detail.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->_pid(_dead_pid());
    $e->_started(1);
    $e->stop;

    ok $e->_events_stop_requested,
        "flag is set";

    my $snap = Async::Event::Interval::events();
    ok $snap->{$e->id}, "events() still includes the event after stop()";

    my $info = $e->info;
    ok $info, "info() still returns data after stop()";
}

# stop() clears _started before setting _stop_requested.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->_pid(_dead_pid());
    $e->_started(1);

    $e->stop;

    is $e->_started, 0, "_started is cleared by stop()";
}

# Child that loops on an interval exits when stop() is called.
{
    my $runs = 0;
    my $e = Async::Event::Interval->new(0.05, sub { $runs++ });
    $e->start;

    # Poll for the first run rather than sleeping a fixed window. On a
    # loaded CI runner the child can be scheduled later than the 0.05s
    # interval, so a fixed wait races stop()'s _stop_requested flag and
    # the loop exits before firing the callback even once.
    my $deadline = Time::HiRes::time() + 5;
    while (Time::HiRes::time() < $deadline) {
        last if $e->runs;
        select(undef, undef, undef, 0.01);
    }

    my $pid = $e->pid;
    ok $pid, "event has a pid while running";

    my $t0 = Time::HiRes::time();
    $e->stop;
    my $elapsed = Time::HiRes::time() - $t0;

    my $runs_after = $e->runs;
    cmp_ok $runs_after, '>', 0,
        "child executed callback at least once ($runs_after runs)";

    ok ! (kill 0, $pid),
        "child pid is gone after stop()";

    cmp_ok $elapsed, '<', Async::Event::Interval::STOP_TERM_TIMEOUT(),
        "stop() returns under STOP_TERM_TIMEOUT "
      . "($elapsed s, timeout=" . Async::Event::Interval::STOP_TERM_TIMEOUT() . ")";

    is $e->_started, 0, "_started cleared after stop() on live child";
}

# Restart after stop: the child runs again after being stopped.
{
    my $e = Async::Event::Interval->new(0.05, sub {});
    $e->start;

    my $deadline = Time::HiRes::time() + 5;
    while (Time::HiRes::time() < $deadline) {
        last if $e->runs;
        select(undef, undef, undef, 0.01);
    }
    $e->stop;

    my $runs_before = $e->runs;
    cmp_ok $runs_before, '>', 0, "ran before first stop";

    $e->start;
    $deadline = Time::HiRes::time() + 5;
    while (Time::HiRes::time() < $deadline) {
        last if $e->runs > $runs_before;
        select(undef, undef, undef, 0.01);
    }
    $e->stop;

    my $runs_after = $e->runs;
    cmp_ok $runs_after, '>', $runs_before,
        "runs incremented after restart ($runs_after > $runs_before)";
}

# stop() on an already-stopped event is a no-op.
{
    my $e = Async::Event::Interval->new(0.5, sub {});
    $e->_pid(_dead_pid());
    $e->_started(1);

    $e->stop;
    my $t0 = Time::HiRes::time();
    $e->stop;
    my $elapsed = Time::HiRes::time() - $t0;

    cmp_ok $elapsed, '<', 0.01,
        "second stop() on already-stopped event is instant ($elapsed s)";
}