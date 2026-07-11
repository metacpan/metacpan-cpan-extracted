use strict;
use warnings;

use Test2::V0;
use POSIX ();
use File::Temp qw/tempdir/;
use Time::HiRes qw/time sleep/;

use DBIx::QuickDB::Watcher;
use DBIx::QuickDB::Driver;
use DBIx::QuickDB::Driver::PostgreSQL;

# _watcher_kill_fast() backs the fast/disposable teardown. It must:
#  - send the requested signal (not always SIGKILL) so a driver can pick a
#    clean immediate-shutdown signal that releases OS resources, and
#  - escalate to SIGKILL if that signal does not stop the server promptly,
#    so teardown always completes.
# These need fork() and real signals; skip where that does not apply.
skip_all "fork/POSIX signals not supported on $^O" if $^O eq 'MSWin32';

my $tmp = tempdir(CLEANUP => 1);

sub pid_alive { my $p = shift; return kill(0, $p) ? 1 : 0 }

# Fork a child that installs the given %SIG dispositions, announces readiness
# down a pipe, and otherwise sleeps forever (it exists to be killed). The pipe
# is exact synchronization: the parent's sysread blocks until the handlers are
# installed, with no polling and no arbitrary deadline for a loaded host to
# blow. If the child dies before becoming ready the parent sees EOF and dies.
sub spawn_child {
    my (%sigs) = @_;

    pipe(my $r, my $w) or die "pipe failed: $!";

    my $pid = fork;
    die "fork failed: $!" unless defined $pid;

    if (!$pid) {
        close($r);
        $SIG{$_} = $sigs{$_} for keys %sigs;
        syswrite($w, "1") or POSIX::_exit(1);
        close($w);
        sleep 0.05 while 1;
        POSIX::_exit(0);
    }

    close($w);
    my $got = sysread($r, my $buf, 1);    # blocks until the child is ready
    close($r);
    die "child never became ready" unless $got;

    return $pid;
}

subtest custom_signal_used => sub {
    # A child that exits cleanly on SIGQUIT must be stopped by SIGQUIT itself
    # (not a SIGKILL), proving the requested signal is what gets sent.
    my $pid = spawn_child(
        QUIT => sub { open(my $f, '>', "$tmp/got-quit"); close($f); POSIX::_exit(0) },
    );

    DBIx::QuickDB::Watcher->_watcher_kill_fast($pid, 'QUIT');

    ok(-e "$tmp/got-quit", "child handled SIGQUIT (requested signal was sent, not SIGKILL)");
    ok(!pid_alive($pid),   "child was reaped");
};

subtest escalates_to_sigkill => sub {
    # A child that ignores SIGQUIT must still be reaped: _watcher_kill_fast
    # escalates to SIGKILL after its grace window.
    my $pid = spawn_child(QUIT => 'IGNORE');

    my $start = time;
    ok(lives { DBIx::QuickDB::Watcher->_watcher_kill_fast($pid, 'QUIT') },
        "_watcher_kill_fast reaped a process that ignores the requested signal")
        or diag($@);
    my $elapsed = time - $start;

    ok(!pid_alive($pid), "child gone after escalation to SIGKILL");
    ok($elapsed < 5, "escalation happened within the grace window (${elapsed}s)");
};

subtest default_is_sigkill => sub {
    # No signal argument: defaults to SIGKILL, which cannot be caught.
    my $pid = spawn_child(QUIT => 'IGNORE');
    DBIx::QuickDB::Watcher->_watcher_kill_fast($pid);
    ok(!pid_alive($pid), "default SIGKILL reaped the child");
};

subtest driver_fast_stop_sig => sub {
    is(DBIx::QuickDB::Driver->fast_stop_sig, 'KILL',
        "base driver fast_stop_sig defaults to SIGKILL");
    is(DBIx::QuickDB::Driver::PostgreSQL->fast_stop_sig, 'QUIT',
        "PostgreSQL fast_stop_sig is SIGQUIT (immediate shutdown releases SysV semaphores)");
};

# The GRACEFUL teardown path (_watcher_kill, used by stop()/eliminate()) must
# also escalate through the driver's fast_stop_sig BEFORE SIGKILL, so a server
# that ignores the polite stop signal is still given its clean immediate-stop
# signal (which releases SysV semaphores) instead of being SIGKILLed outright
# and leaking them.
subtest graceful_kill_escalates_via_fast_sig => sub {
    # Grace 4 -> fast_at=4s, kill_at=6s. The 2s gap between SIGQUIT and
    # SIGKILL matters: with grace 1 the gap was only 1s, and on a slow loaded
    # smoker the child was not scheduled in time to run its QUIT handler
    # (which writes the marker file asserted below) before SIGKILL landed --
    # observed as a spurious CPAN Testers failure of the marker assertion.
    local $ENV{QDB_STOP_GRACE} = 4;
    local $SIG{__WARN__} = sub { };    # silence the expected escalation warnings

    # Child ignores SIGTERM (the polite stop) but exits cleanly on SIGQUIT, the
    # way PostgreSQL's immediate-shutdown lets the postmaster release its
    # semaphores. It must be stopped by SIGQUIT, never reaching SIGKILL.
    my $pid = spawn_child(
        TERM => 'IGNORE',
        QUIT => sub { open(my $f, '>', "$tmp/grace-quit"); close($f); POSIX::_exit(0) },
    );

    my $start = time;
    ok(lives { DBIx::QuickDB::Watcher->_watcher_kill('TERM', $pid, 'QUIT') },
        "_watcher_kill reaped a server that ignores the polite stop signal") or diag($@);
    my $elapsed = time - $start;

    ok(-e "$tmp/grace-quit", "graceful escalation sent the fast_stop_sig (SIGQUIT), not a bare SIGKILL");
    ok(!pid_alive($pid),     "child reaped");
    ok($elapsed < 10,        "escalation happened within the grace window (${elapsed}s)");
};

# If even the fast_stop_sig is ignored, _watcher_kill must still escalate to
# SIGKILL so teardown always completes.
subtest graceful_kill_escalates_to_sigkill => sub {
    local $ENV{QDB_STOP_GRACE} = 1;
    local $SIG{__WARN__} = sub { };

    my $pid = spawn_child(TERM => 'IGNORE', QUIT => 'IGNORE');

    ok(lives { DBIx::QuickDB::Watcher->_watcher_kill('TERM', $pid, 'QUIT') },
        "_watcher_kill reaped a server that ignores both stop and fast_stop signals") or diag($@);
    ok(!pid_alive($pid), "child gone after escalation to SIGKILL");
};

done_testing;
