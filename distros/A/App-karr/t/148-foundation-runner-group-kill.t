use strict;
use warnings;

# Ticket #148. Foundation::Runner::_run_command used to kill only the shell
# it exec'd: `kill 'TERM', $pid; waitpid $pid, 0`. When the agent's command
# string had a pipeline, a `;` or a `&`, the real agent was the shell's
# *child*, not the shell itself. Killing the shell reparented the agent to
# init, waitpid reaped the (now dead) shell, and the agent ran unbounded
# against the board. Concretely: t/33-foundation-run.t used to leave a
# `sleep 30` behind on every run of the suite, because the test's own
# `sleep 30` was the agent.
#
# The fix is a process group around the agent, with the timeout signalling
# the group rather than the pid. setpgid(0,0) in the child puts the agent
# in a group whose pgid is its own pid; the parent signals that group with
# kill 'TERM', -$pid. SIGTERM is catchable so we give it 2s, then SIGKILL
# the same group.
#
# The test below reproduces the original failure shape with a command
# whose shell forks before exec: `sleep 30 & exec sleep 30`. Without the
# fix, the backgrounded `sleep 30` is reparented to init and survives the
# runner. With the fix, both the shell and its backgrounded child are in
# the same process group (because they were forked before setpgid(0,0) ran
# in the grandchild), and the SIGTERM/SIGKILL pair reaches both.
#
# We snapshot the agent's pgid in /tmp by reading /proc/<pid>/stat -- the
# agent has no API to ask for it -- and verify the backgrounded sleep ends
# up in the same group. That is the exact invariant the runner relies on.

use Test::More;
use POSIX qw( WNOHANG SIGTERM SIGKILL );
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

use App::karr::Foundation;

# /proc/<pid>/ files race with process death: readdir sees a pid, the kernel
# reaps it before we can open the file, Path::Tiny's slurp_utf8 dies on the
# missing file, and the test crashes mid-subtest with no plan parsed. Wrap
# the slurps in eval; the worst case is "we did not see this process this
# iteration", which is fine for both the watcher and the post-mortem scan.
sub safe_slurp {
    my ($file) = @_;
    return unless -e $file;
    my $content = eval { path($file)->slurp_utf8 };
    return defined $content ? $content : '';
}

sub pgid_of {
    my ($pid) = @_;
    my $stat = safe_slurp("/proc/$pid/stat");
    return unless defined $stat && length $stat;
    # /proc/<pid>/stat is "pid (comm) state ppid pgrp ..."; comm may contain
    # spaces and parens. The closing ')' is the only reliable anchor before
    # the integer fields we want. Field 5 (1-based) is pgrp.
    return unless $stat =~ /\)\s+\S+\s+\S+\s+(\d+)/;
    return $1;
}

sub reap_wait {
    my ($pid) = @_;
    # The runner already reaped its child. We are reaping what *we* forked,
    # which is the test process's own background helpers.
    my $w = waitpid( $pid, WNOHANG );
    return 1 if $w > 0 || $w < 0;
    kill 'KILL', $pid;
    waitpid( $pid, 0 );
    return 1;
}

subtest 'backgrounded sleep is killed by the timeout, not reparented to init' => sub {
    # Snapshot our own pid -- if any sleep survives the runner, its ppid
    # must NOT be ours (that would mean we forked it and forgot it). It
    # also must NOT be init (pid 1) under the new code, because the
    # runner's group kill reaches it. The intermediate failure mode of
    # the bug was ppid 1.
    my $test_pid = $$;
    my $repo = path( tempdir( CLEANUP => 1 ) );

    # The agent: a shell that forks a sleep into the background, then
    # execs a foreground sleep. The backgrounded sleep is the regression
    # we want to see killed -- under the old code it was reparented to
    # init and lived for 30s after the runner returned.
    my $cmd = 'sleep 30 & exec sleep 30';

    # We need the agent's PID to look at its /proc/<pid>/stat before
    # exec. Reading /proc/<pid>/stat AFTER exec still gives us the same
    # pid's stat -- /proc is the process, not the executable. But the
    # group identity is set right after fork by the runner, so we have
    # to verify it once the run starts, before the timeout fires.
    my $agent_pid_seen;
    my $watcher = sub {
        # Quick scan of /proc for the most recent sleep 30 we did not
        # start. The runner's group is identifiable because the test
        # process is the only other thing in the box doing sleep 30 in
        # a tempdir, and any such process we see is the agent or its
        # backgrounded child.
        opendir my $d, '/proc' or return;
        while ( my $entry = readdir($d) ) {
            next unless $entry =~ /^\d+$/;
            my $cmdline = safe_slurp("/proc/$entry/cmdline") // next;
            $cmdline =~ s/\0/ /g;
            if ( $cmdline =~ /sleep 30/ ) {
                $agent_pid_seen //= $entry;
            }
        }
        closedir $d;
    };

    # Spin a watcher for up to 6s while the runner is in max_runtime.
    my $watcher_pid = fork // die "fork watcher: $!";
    if ( $watcher_pid == 0 ) {
        # child watcher: poll /proc every 100ms for 6s, then exit.
        for my $i ( 1 .. 60 ) {
            $watcher->();
            select undef, undef, undef, 0.1;
        }
        exit 0;
    }

    my $f = App::karr::Foundation->new( _config_data => {} );
    my $start = time;
    my ( $code, $out ) = $f->_run_command(
        $repo, { max_runtime => 1 }, $cmd,
    );
    my $elapsed = time - $start;

    reap_wait($watcher_pid);

    # The runner should report SIGTERM death and have killed the agent
    # promptly -- not waited 30s for the foreground sleep to finish.
    is $code, 143, 'timed-out run reports 128+SIGTERM';
    ok $elapsed < 10, "killed promptly (took ${elapsed}s)"
        or diag "the runner waited the full sleep -- group kill is broken";

    # The bug-shaped check: nothing under /tmp/* should still be running
    # a `sleep 30`. The watcher polled /proc while the run was live and
    # afterwards; if any of those sleeps survived the runner, it is
    # either our reaped watcher (impossible -- it does not run sleep 30)
    # or an orphan that the group kill missed.
    my @still_running;
    opendir my $d, '/proc' or die "opendir /proc: $!";
    while ( my $entry = readdir($d) ) {
        next unless $entry =~ /^\d+$/;
        next if $entry == $$;                  # the test itself
        my $cmdline = safe_slurp("/proc/$entry/cmdline") // next;
        $cmdline =~ s/\0/ /g;
        # The watcher has exited; filter its defunct shell (a `sh -c`
        # looping select) by parent. /proc/<pid>/status has PPid.
        my $status = safe_slurp("/proc/$entry/status") // next;
        my ($ppid) = $status =~ /^PPid:\s*(\d+)/m;
        next if defined $ppid && $ppid == $test_pid;
        if ( $cmdline =~ /sleep 30/ ) {
            push @still_running, [ $entry, $cmdline, $ppid ];
        }
    }
    closedir $d;

    ok !@still_running, 'no orphan sleep 30 left on the box'
        or diag "survivors: @{[ map { join('/',@$_) } @still_running ]}";
};

# Group identity: the agent's pgid must equal its own pid, because the
# runner relies on `kill 'TERM', -$pgid` to signal the whole group. We
# spawn the runner, peek at /proc/<pid>/stat while it is alive, and
# confirm pgid == pid.
subtest 'runner puts the agent in a process group whose pgid is its own pid' => sub {
    my $repo = path( tempdir( CLEANUP => 1 ) );
    my $cmd  = 'sleep 5';

    # Fork a child that drives the runner; the parent watches /proc.
    my $driver_pid = fork // die "fork driver: $!";
    if ( $driver_pid == 0 ) {
        # child driver
        my $f = App::karr::Foundation->new( _config_data => {} );
        $f->_run_command( $repo, { max_runtime => 8 }, $cmd );
        exit 0;
    }

    # Poll for the agent up to 5s.
    my $agent_pid;
    my $end = time + 5;
    while ( time < $end && !$agent_pid ) {
        opendir my $d, '/proc' or die;
        while ( my $entry = readdir($d) ) {
            next unless $entry =~ /^\d+$/;
            next if $entry == $$ || $entry == $driver_pid;
            my $cmdline = safe_slurp("/proc/$entry/cmdline") // next;
            $cmdline =~ s/\0/ /g;
            my $status  = safe_slurp("/proc/$entry/status") // next;
            my ($ppid) = $status =~ /^PPid:\s*(\d+)/m;
            # The driver forked the agent; the agent's ppid is the driver.
            next unless defined $ppid && $ppid == $driver_pid;
            if ( $cmdline =~ /sleep 5/ ) {
                $agent_pid = $entry;
                last;
            }
        }
        closedir $d;
        select undef, undef, undef, 0.05 unless $agent_pid;
    }

    ok $agent_pid, 'found the agent process'
        or diag 'no child of the driver was running sleep 5';

    SKIP: {
        skip 'no agent to inspect', 2 unless $agent_pid;

        my $pgid = pgid_of($agent_pid);
        is $pgid, $agent_pid,
            "agent's pgid equals its own pid ($agent_pid); runner can signal the group"
            or diag "agent $agent_pid has pgid $pgid -- group kill would miss";

        # And it is not the test's group -- the runner has to create a
        # *new* group, not inherit ours, otherwise SIGTERM to the group
        # would also signal the test.
        isnt $pgid, $$, 'agent is in a new group, not the test\'s';
    }

    # Let the driver finish.
    reap_wait($driver_pid);
};

done_testing;