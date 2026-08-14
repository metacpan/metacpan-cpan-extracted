use strict;
use warnings;

# Ticket #163. Foundation installed no SIGTERM handler. Stop it
# mid-drain -- systemd TimeoutStopSec, a deploy, an operator's kill --
# and the agent survived, reparented to init, while .karr.lock named the
# foundation's now-dead pid and the next tick started a second agent.
#
# The fix has two halves:
#   - Foundation::run installs SIGTERM/INT/HUP handlers that kill the
#     live agent's process group and force-release the lock.
#   - the lock now records the work (an open fd, plus pid/pgid as
#     evidence), so the handler can find and clean it up.
#
# This test exercises the handler end-to-end. We fork a driver child
# that imports Foundation, installs the SIGTERM handler, drives an
# agent through _run_command (so the agent is in its own process
# group, the same shape production leaves), then sends SIGTERM to
# itself. We then check from the parent:
#   1. the agent is gone (it would have been reparented to init without
#      the handler, and would still be running);
#   2. .karr.lock is gone (the handler force-released it);
#   3. a fresh foundation instance reports the lock free.

use Test::More;
use POSIX qw( WNOHANG SIGTERM );
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

sub reap_or_kill {
    my ($pid) = @_;
    # waitpid(2) with WNOHANG: if the child has exited, $w is the pid
    # (or 0 if still alive, -1 on error). A handler that called
    # POSIX::_exit has already produced a status for us; we just want
    # to collect it without the WNOHANG-vs-blocking race that would
    # otherwise be the test's own failure mode.
    my $w = waitpid( $pid, WNOHANG );
    return 1 if $w > 0 || $w < 0;
    kill 'KILL', $pid;
    waitpid( $pid, 0 );
    return 1;
}

sub cmdline_of {
    my ($pid) = @_;
    my $cmdline = path("/proc/$pid/cmdline")->slurp_utf8 // return '';
    $cmdline =~ s/\0/ /g;
    return $cmdline;
}

# A script the driver child runs. We write it to a tempdir and exec it
# so that the test process itself is not exposed to the SIGTERM -- the
# handler runs in the driver only, and the test process just observes.
sub write_driver_script {
    my ( $dir, $repo_str ) = @_;
    my $lib = path('lib')->absolute->stringify;
    my $script = path($dir)->child('driver.pl');
    $script->spew_utf8(<<PERL);
use strict;
use warnings;
use lib '$lib';
use App::karr::Foundation;
use Path::Tiny qw( path );
my \$repo = path("$repo_str");
my \$f    = App::karr::Foundation->new( _config_data => {} );
\$f->_install_signal_handlers;
\$f->_acquire_lock( \$repo );
# _run_command is what production uses; it sets _live_agent on the
# foundation and gives the agent its own process group, which is the
# invariant the handler relies on. We call it inline here, not from
# _drain_repo, so the only thing that can stop this driver is SIGTERM.
my \$start = time;
my ( \$code, \$out ) = \$f->_run_command( \$repo, { max_runtime => 60 },
    'sleep 30' );
my \$elapsed = time - \$start;
# This line is only printed if SIGTERM did NOT fire -- if it did, the
# handler's POSIX::_exit(143) replaces the run before we get here.
print "DRAIN_FINISHED code=\$code elapsed=\$elapsed\\n";
exit 0;
PERL
    return $script;
}

subtest 'SIGTERM to the foundation kills its agent and releases the lock' => sub {
    my $scratch = path( tempdir( CLEANUP => 1 ) );
    my $repo    = path( tempdir( CLEANUP => 1 ) );

    my $script = write_driver_script( $scratch, "$repo" );

    # The driver reads from /tmp/sentinel so the parent can know when it
    # has reached the agent-running state.
    my $sentinel = $scratch->child('sentinel');
    my $driver_out = $scratch->child('driver.out');
    open( my $sentinel_fh, '>', "$sentinel" ) or die "open sentinel: $!";

    my $driver_pid = fork // die "fork driver: $!";
    if ( $driver_pid == 0 ) {
        # child driver
        open( STDOUT, '>', "$driver_out" ) or die "open stdout: $!";
        $| = 1;
        # Touch the sentinel so the parent knows we are past module
        # import. The parent polls the sentinel's existence + mtime.
        close $sentinel_fh;
        exec { $^X } ( $^X, "$script" ) or die "exec: $!";
    }
    close $sentinel_fh;

    # Wait for the driver to actually be running the agent.
    my $deadline = time + 15;
    while ( time < $deadline ) {
        last if -e $sentinel && -M $sentinel < -M $script;
        select undef, undef, undef, 0.05;
    }
    ok -e $sentinel, 'driver reached its post-import state';

    # Find the agent: a child of the driver running "sleep 30".
    my $agent_pid;
    $deadline = time + 5;
    while ( time < $deadline && !$agent_pid ) {
        opendir my $d, '/proc' or die;
        while ( my $entry = readdir($d) ) {
            next unless $entry =~ /^\d+$/;
            next if $entry == $$ || $entry == $driver_pid;
            my $cmdline = path("/proc/$entry/cmdline")->slurp_utf8 // next;
            $cmdline =~ s/\0/ /g;
            my $status  = path("/proc/$entry/status")->slurp_utf8 // next;
            my ($ppid) = $status =~ /^PPid:\s*(\d+)/m;
            next unless defined $ppid && $ppid == $driver_pid;
            if ( $cmdline =~ /sleep 30/ ) {
                $agent_pid = $entry;
                last;
            }
        }
        closedir $d;
        select undef, undef, undef, 0.05 unless $agent_pid;
    }

    ok $agent_pid, 'found the agent process running under the driver'
        or BAIL_OUT 'driver did not fork the agent -- cannot exercise handler';

    ok kill( 0, $agent_pid ), 'agent is alive before SIGTERM';

    # SIGTERM the driver -- the handler should run, kill the agent's
    # group, force-release the lock, and exit 143.
    kill 'TERM', $driver_pid;

    # Wait for the driver to actually exit (handler runs synchronously
    # in the signal delivery, then POSIX::_exit). Give it a moment.
    my $w = 0;
    $deadline = time + 5;
    while ( time < $deadline ) {
        $w = waitpid( $driver_pid, WNOHANG );
        last if $w > 0;
        select undef, undef, undef, 0.05;
    }
    if ( !$w ) {
        diag 'driver did not exit within 5s of SIGTERM -- signal handler stalled';
        kill 'KILL', $driver_pid;
        waitpid( $driver_pid, 0 );
    }

    my $driver_status = $? >> 8;
    is $driver_status, 143,
        'driver exited 128+SIGTERM (the conventional signal-death code)'
        or diag "driver exited with status $driver_status -- handler did not run";

    # Give the kernel a moment to actually reap the agent.
    my $end = time + 3;
    my $still_alive = 0;
    while ( time < $end ) {
        $still_alive = kill( 0, $agent_pid ) ? 1 : 0;
        last unless $still_alive;
        select undef, undef, undef, 0.05;
    }
    ok !$still_alive, 'the agent was killed by the SIGTERM handler'
        or diag "agent $agent_pid survived SIGTERM to the foundation";

    # And .karr.lock is gone -- the handler called _force_release_lock.
    ok !$repo->child('.karr.lock')->exists,
        '.karr.lock is unlinked by the handler, not left for the next tick'
        or diag '.karr.lock was left behind -- the next tick would skip the board';

    # A fresh foundation instance reports the board free.
    require App::karr::Foundation;
    my $f_fresh = App::karr::Foundation->new( _config_data => {} );
    ok !$f_fresh->_lock_held( $repo ),
        'a fresh tick sees the lock free -- the next drain will run';

    # Cleanup in case the agent is still in the process of dying.
    kill 'KILL', $agent_pid if kill( 0, $agent_pid );
};

done_testing;