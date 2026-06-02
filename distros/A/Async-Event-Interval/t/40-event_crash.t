use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use Test::More;

# CORE::GLOBAL::kill hook for the §3.1 mutation/idempotency tests below
# (mirrors the pattern in t/09-locking.t). When $kill_mock is set, all
# kill() calls in code compiled after this BEGIN (notably
# Async::Event::Interval) route through the mock; otherwise pass
# through to the real CORE::kill.

our $kill_mock;
BEGIN {
    *CORE::GLOBAL::kill = sub {
        return $kill_mock->(@_) if $kill_mock;
        return CORE::kill(@_);
    };
}

use Async::Event::Interval;

# Spawn a one-shot event whose callback SIGKILLs the child, then wait
# for the child to be reaped (via $SIG{CHLD}=IGNORE). Caller decides
# when to invoke a detection method (error/status/waiting).

sub _spawn_then_crash {
    my $e = Async::Event::Interval->new(0, sub { kill 9, $$ });
    $e->start;
    select(undef, undef, undef, 0.2);
    return $e;
}

# Existing test — preserved verbatim. Verifies the user-facing crash /
# restart cycle still works after the §3.1 refactor.

{
    my $event = Async::Event::Interval->new(
        0.3,
        sub {
            kill 9, $$;
        },
    );

    $event->start;

    is $event->status > 0, 1, "status ok at start";

    select(undef, undef, undef, 0.6);

    is $event->status, 0, "upon crash, status return ok";
    is $event->error, 1, "upon crash, error return ok";

    if ($event->error){
        $event->restart;
        is $event->status > 0, 1, "after restart, status ok again";
        is $event->error, 0, "...so is error";
    }

    $event->stop;
}

# --- New blocks per PLAN-3.1.md §6 ---

# 1. error() alone detects a crash without a prior status() call.

{
    my $e = _spawn_then_crash();
    is $e->error, 1, "error() alone detects crash on first call";
    is $e->_crashed, 1, "...and the _crashed flag is set";
}

# 2. status() alone detects a crash; subsequent error() returns 1.

{
    my $e = _spawn_then_crash();
    is $e->status, 0, "status() alone returns 0 on crashed event";
    is $e->_crashed, 1, "status() set the _crashed flag";
    is $e->error, 1, "subsequent error() returns 1";
}

# 3. error() on a never-started event returns 0 with no mutation.

{
    my $e = Async::Event::Interval->new(0.3, sub { 1 });
    is $e->error, 0, "error() on never-started event is 0";
    is $e->_crashed, 0, "_crashed stays 0";
    is $e->_started, 0, "_started stays 0";
    is $e->pid, undef, "pid stays undef";
}

# 4. error() on a healthy running event returns 0; no state mutation.

{
    my $e = Async::Event::Interval->new(5, sub { 1 });   # long interval
    $e->start;
    my $pid_before = $e->pid;
    cmp_ok $pid_before, '>', 0,
        "captured running child pid ($pid_before)";

    is $e->error, 0, "error() on healthy event returns 0";
    is $e->_crashed, 0, "_crashed stays 0 on healthy event";
    is $e->pid, $pid_before, "pid unchanged after error() probe";
    is $e->_started, 1, "_started stays 1 after error() probe";

    $e->stop;
}

# 5. No mutual recursion: status() does not call error().

{
    my $error_calls = 0;
    my $orig = \&Async::Event::Interval::error;
    no warnings 'redefine';
    local *Async::Event::Interval::error = sub {
        $error_calls++;
        $orig->(@_);
    };

    my $e = _spawn_then_crash();
    $error_calls = 0;
    $e->status;
    is $error_calls, 0, "status() does not call error()";
}

# 6. No mutual recursion: error() does not call status().

{
    my $status_calls = 0;
    my $orig = \&Async::Event::Interval::status;
    no warnings 'redefine';
    local *Async::Event::Interval::status = sub {
        $status_calls++;
        $orig->(@_);
    };

    my $e = _spawn_then_crash();
    $status_calls = 0;
    $e->error;
    is $status_calls, 0, "error() does not call status()";
}

# 7. Idempotency: after one crash detection, repeated error()/status()
#    calls do not re-probe with kill(0). Verified via the kill_mock
#    hook counting kill 0 invocations.

{
    my $e = _spawn_then_crash();

    my @kill_zero_pids;
    local $kill_mock = sub {
        my ($sig, @pids) = @_;
        push @kill_zero_pids, [@pids] if $sig eq '0';
        return CORE::kill($sig, @pids);
    };

    is $e->error, 1, "idempotency: first error() returns 1";
    my $first_count = scalar @kill_zero_pids;

    $e->error  for 1..3;
    $e->status for 1..3;

    is scalar @kill_zero_pids, $first_count,
        "subsequent error()/status() calls did not re-probe with kill(0)";
}

# 8. $e->pid after crash returns undef (not -99, not the dead PID).
#    events()/info() snapshot shows pid=0 (the _pid(0) write-through —
#    distinguishable from any real PID).

{
    my $e = Async::Event::Interval->new(0, sub { kill 9, $$ });
    $e->start;
    my $captured = $e->pid;
    cmp_ok $captured, '>', 0,
        "captured a positive PID before crash ($captured)";

    select(undef, undef, undef, 0.2);
    $e->error;                                  # trigger detection

    is $e->pid,  undef, "after crash, public pid() returns undef";
    is $e->_pid, undef, "...and _pid getter returns undef";
    isnt $e->pid, -99,  "pid is NOT the legacy -99 sentinel";

    my $snap = $e->info;
    is $snap->{pid}, 0,
        "info() snapshot exposes pid=0 (the _pid(0) write-through)";
}

# 9. stop() is a no-op when _crashed: no kill 9 is invoked. Belt-and-
#    suspenders: this exercises the explicit _crashed early-return
#    even though the cleared _pid would also short-circuit the
#    if ($self->pid) guard.

{
    my $e = _spawn_then_crash();
    is $e->error, 1, "event detected as crashed before stop()";

    my @kill_nine_pids;
    local $kill_mock = sub {
        my ($sig, @pids) = @_;
        push @kill_nine_pids, [@pids] if $sig eq '9';
        return CORE::kill($sig, @pids);
    };

    $e->stop;

    is scalar @kill_nine_pids, 0,
        "stop() on crashed event does not invoke kill 9";
    is $e->_crashed, 1, "_crashed flag preserved after stop() no-op";
}

# 10. DESTROY is a no-op when _crashed: no kill 9 during destruction.

{
    my @kill_nine_pids;

    {
        my $e = _spawn_then_crash();
        is $e->error, 1, "event detected as crashed before DESTROY";

        local $kill_mock = sub {
            my ($sig, @pids) = @_;
            push @kill_nine_pids, [@pids] if $sig eq '9';
            return CORE::kill($sig, @pids);
        };
        # $e goes out of scope at end of this block; DESTROY runs
        # while $kill_mock is still installed.
    }

    is scalar @kill_nine_pids, 0,
        "DESTROY of crashed event does not invoke kill 9";
}

# 11. restart() after crash clears _crashed.

{
    my $e = _spawn_then_crash();
    is $e->error, 1, "event detected as crashed";
    is $e->_crashed, 1, "_crashed set";

    $e->restart;
    is $e->_crashed, 0, "restart() cleared _crashed";

    $e->stop;
}

# 12. Croak guard preserved: _started=1 with no pid -> status() croaks
#     with the existing "no PID can be found" message.

{
    my $e = Async::Event::Interval->new(0.3, sub { 1 });
    $e->_started(1);
    $e->_pid(0);                                # clears via getter coercion

    my $ok = eval { $e->status; 1 };
    my $err = $@;
    is $ok, undef, "status() with _started=1 and no pid croaks";
    like $err, qr/no PID can be found/,
        "...with the existing 'no PID can be found' message";

    $e->_started(0);                            # reset for clean teardown
}

# 13. waiting() regression: 1 on never-started AND crashed events;
#     0 on a healthy running event.

{
    my $never = Async::Event::Interval->new(0.3, sub { 1 });
    is $never->waiting, 1, "waiting() == 1 on never-started event";

    my $running = Async::Event::Interval->new(5, sub { 1 });
    $running->start;
    is $running->waiting, 0, "waiting() == 0 on healthy running event";
    $running->stop;

    my $crashed = _spawn_then_crash();
    is $crashed->waiting, 1, "waiting() == 1 on crashed event";
}