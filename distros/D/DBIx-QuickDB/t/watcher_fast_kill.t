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

# Fork a child that installs $disposition for SIGQUIT, announces readiness by
# creating $tmp/ready-$$, and otherwise sleeps forever.
sub spawn_child {
    my ($disposition) = @_;

    my $pid = fork;
    die "fork failed: $!" unless defined $pid;

    if (!$pid) {
        $SIG{QUIT} = $disposition;
        open(my $fh, '>', "$tmp/ready-$$") or POSIX::_exit(1);
        close($fh);
        sleep 0.05 while 1;
        POSIX::_exit(0);
    }

    # Parent: wait until the child has installed its handler.
    my $start = time;
    until (-e "$tmp/ready-$pid") {
        die "child never became ready" if time - $start > 5;
        sleep 0.01;
    }

    return $pid;
}

subtest custom_signal_used => sub {
    # A child that exits cleanly on SIGQUIT must be stopped by SIGQUIT itself
    # (not a SIGKILL), proving the requested signal is what gets sent.
    my $pid = fork;
    die "fork failed: $!" unless defined $pid;
    if (!$pid) {
        $SIG{QUIT} = sub { open(my $f, '>', "$tmp/got-quit"); close($f); POSIX::_exit(0) };
        open(my $fh, '>', "$tmp/ready-$$") or POSIX::_exit(1);
        close($fh);
        sleep 0.05 while 1;
        POSIX::_exit(0);
    }
    my $start = time;
    until (-e "$tmp/ready-$pid") { die "not ready" if time - $start > 5; sleep 0.01 }

    DBIx::QuickDB::Watcher->_watcher_kill_fast($pid, 'QUIT');

    ok(-e "$tmp/got-quit", "child handled SIGQUIT (requested signal was sent, not SIGKILL)");
    ok(!pid_alive($pid),   "child was reaped");
};

subtest escalates_to_sigkill => sub {
    # A child that ignores SIGQUIT must still be reaped: _watcher_kill_fast
    # escalates to SIGKILL after its grace window.
    my $pid = spawn_child('IGNORE');

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
    my $pid = spawn_child('IGNORE');
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
    local $ENV{QDB_STOP_GRACE} = 1;    # fast_at=1s, kill_at=2s, give_up=2s
    local $SIG{__WARN__} = sub { };    # silence the expected escalation warnings

    # Child ignores SIGTERM (the polite stop) but exits cleanly on SIGQUIT, the
    # way PostgreSQL's immediate-shutdown lets the postmaster release its
    # semaphores. It must be stopped by SIGQUIT, never reaching SIGKILL.
    my $pid = fork;
    die "fork failed: $!" unless defined $pid;
    if (!$pid) {
        $SIG{TERM} = 'IGNORE';
        $SIG{QUIT} = sub { open(my $f, '>', "$tmp/grace-quit"); close($f); POSIX::_exit(0) };
        open(my $fh, '>', "$tmp/ready-$$") or POSIX::_exit(1);
        close($fh);
        sleep 0.05 while 1;
        POSIX::_exit(0);
    }
    my $w = time;
    until (-e "$tmp/ready-$pid") { die "not ready" if time - $w > 5; sleep 0.01 }

    my $start = time;
    ok(lives { DBIx::QuickDB::Watcher->_watcher_kill('TERM', $pid, 'QUIT') },
        "_watcher_kill reaped a server that ignores the polite stop signal") or diag($@);
    my $elapsed = time - $start;

    ok(-e "$tmp/grace-quit", "graceful escalation sent the fast_stop_sig (SIGQUIT), not a bare SIGKILL");
    ok(!pid_alive($pid),     "child reaped");
    ok($elapsed < 5,         "escalation happened within the grace window (${elapsed}s)");
};

# If even the fast_stop_sig is ignored, _watcher_kill must still escalate to
# SIGKILL so teardown always completes.
subtest graceful_kill_escalates_to_sigkill => sub {
    local $ENV{QDB_STOP_GRACE} = 1;
    local $SIG{__WARN__} = sub { };

    my $pid = fork;
    die "fork failed: $!" unless defined $pid;
    if (!$pid) {
        $SIG{TERM} = 'IGNORE';
        $SIG{QUIT} = 'IGNORE';
        open(my $fh, '>', "$tmp/ready-$$") or POSIX::_exit(1);
        close($fh);
        sleep 0.05 while 1;
        POSIX::_exit(0);
    }
    my $w = time;
    until (-e "$tmp/ready-$pid") { die "not ready" if time - $w > 5; sleep 0.01 }

    ok(lives { DBIx::QuickDB::Watcher->_watcher_kill('TERM', $pid, 'QUIT') },
        "_watcher_kill reaped a server that ignores both stop and fast_stop signals") or diag($@);
    ok(!pid_alive($pid), "child gone after escalation to SIGKILL");
};

done_testing;
