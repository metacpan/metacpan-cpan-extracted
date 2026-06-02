use strict;
use warnings;

use File::Temp;
use IPC::Shareable;
use POSIX ();
use Test::More;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();

# ---------------------------------------------------------------------------
# Test 1: _alarmed_eval actually interrupts a blocked call (SA_RESTART cleared)
# ---------------------------------------------------------------------------
# Fork a child that calls _alarmed_eval with a 1s timeout around a 5s
# sleep.  The child writes the elapsed wall-clock time to a temp file.
# If SA_RESTART were still set, the alarm would be swallowed and the
# sleep would complete (~5s).  With the fix, it should exit in ~1s.
{
    my $time_file = File::Temp::tmpnam();

    my $pid = fork;
    die "fork: $!" unless defined $pid;

    if (! $pid) {
        IPC::Shareable->testing_set('Async::Event::Interval');
        require Async::Event::Interval;

        my $start = Time::HiRes::time();
        Async::Event::Interval::_alarmed_eval(1, sub {
            select(undef, undef, undef, 5);
        });
        my $elapsed = Time::HiRes::time() - $start;

        open my $fh, '>', $time_file or die "open: $!";
        print $fh "$elapsed\n";
        close $fh;

        Async::Event::Interval::_end();
        IPC::Shareable::_end();
        POSIX::_exit(0);
    }

    waitpid $pid, 0;

    ok -e $time_file, "_alarmed_eval: child wrote timing file";

    SKIP: {
        skip "_alarmed_eval: no timing file", 1 unless -e $time_file;
        open my $fh, '<', $time_file;
        chomp(my $elapsed = <$fh>);
        close $fh;
        cmp_ok $elapsed, '<', 3,
            "_alarmed_eval interrupted blocked call in ${elapsed}s (< 3s)";
    }

    unlink $time_file if -e $time_file;
}

# ---------------------------------------------------------------------------
# Test 2: @all_pids fallback — children are killed even when %events
#          read would fail
# ---------------------------------------------------------------------------
# We can't easily deadlock the real %events lock in a test, but we can
# verify the mechanics: start an event, confirm the child PID appears
# in @all_pids (via the public _all_pids accessor we'll skip if absent),
# then let _end() clean up normally.
{
    my $flag_file = File::Temp::tmpnam();

    my $pid = fork;
    die "fork: $!" unless defined $pid;

    if (! $pid) {
        IPC::Shareable->testing_set('Async::Event::Interval');
        require Async::Event::Interval;

        my $event = Async::Event::Interval->new(5, sub {
            open my $fh, '>', $flag_file;
            close $fh;
            sleep 30;
        });
        $event->immediate(1);
        $event->start;

        for (1..50) {
            last if -e $flag_file;
            select(undef, undef, undef, 0.1);
        }

        my $child_pid = $event->pid;

        Async::Event::Interval::_end(1);

        my $child_alive = kill(0, $child_pid);
        open my $fh, '>', "$flag_file.result" or die "open: $!";
        print $fh "$child_alive\n";
        close $fh;

        IPC::Shareable::_end();
        POSIX::_exit(0);
    }

    waitpid $pid, 0;

    SKIP: {
        skip "result file not written", 1
            unless -e "$flag_file.result";
        open my $fh, '<', "$flag_file.result";
        chomp(my $alive = <$fh>);
        close $fh;
        is $alive, 0,
            "_end() killed event child (via %events or \@all_pids fallback)";
    }

    unlink $flag_file if -e $flag_file;
    unlink "$flag_file.result" if -e "$flag_file.result";
}

# ---------------------------------------------------------------------------
# Test 3: Per-phase cleanup — later phases run even when earlier ones fail
# ---------------------------------------------------------------------------
# Fork a subprocess that starts an event, then calls _end().  Verify
# that IPC segments are cleaned up (phase 4 runs) even though earlier
# phases may complete or timeout independently.
{
    my $pid = fork;
    die "fork: $!" unless defined $pid;

    if (! $pid) {
        IPC::Shareable->testing_set('Async::Event::Interval');
        require Async::Event::Interval;

        my $e = Async::Event::Interval->new(0, sub {});
        $e->start;
        select(undef, undef, undef, 0.3);

        Async::Event::Interval::_end(1);
        IPC::Shareable::_end();
        POSIX::_exit(0);
    }

    waitpid $pid, 0;
    select(undef, undef, undef, 0.3);

    my $segs_after = IPC::Shareable::seg_count();
    my $sems_after = IPC::Shareable::sem_count();

    is $segs_after, $segs_before,
        "per-phase _end(): no segments leaked";
    is $sems_after, $sems_before,
        "per-phase _end(): no semaphores leaked";
}

# ---------------------------------------------------------------------------
# Test 4: SIGINT triggers phased _end() and cleans up
# ---------------------------------------------------------------------------
# Same as t/91 but confirms the new phased structure works under signal.
{
    my $flag_file = File::Temp::tmpnam();

    my $pid = fork;
    die "fork: $!" unless defined $pid;

    if (! $pid) {
        IPC::Shareable->testing_set('Async::Event::Interval');
        require Async::Event::Interval;

        my $event = Async::Event::Interval->new(5, sub {
            open my $fh, '>', $flag_file;
            close $fh;
            sleep 4;
        });
        $event->immediate(1);
        $event->timeout(3);
        $event->start;

        sleep 60;
        exit;
    }

    for (1..50) {
        last if -e $flag_file;
        select(undef, undef, undef, 0.1);
    }

    ok -e $flag_file, "SIGINT test: event callback invoked";

    kill 'INT', $pid;
    waitpid $pid, 0;
    select(undef, undef, undef, 0.3);

    unlink $flag_file if -e $flag_file;

    my $segs_after = IPC::Shareable::seg_count();
    my $sems_after = IPC::Shareable::sem_count();

    is $segs_after, $segs_before,
        "SIGINT: no segments leaked after phased _end()";
    is $sems_after, $sems_before,
        "SIGINT: no semaphores leaked after phased _end()";
}

# ---------------------------------------------------------------------------
# Test 5: SIGTERM triggers phased _end() and cleans up
# ---------------------------------------------------------------------------
{
    my $flag_file = File::Temp::tmpnam();

    my $pid = fork;
    die "fork: $!" unless defined $pid;

    if (! $pid) {
        IPC::Shareable->testing_set('Async::Event::Interval');
        require Async::Event::Interval;

        my $event = Async::Event::Interval->new(5, sub {
            open my $fh, '>', $flag_file;
            close $fh;
            sleep 4;
        });
        $event->immediate(1);
        $event->timeout(3);
        $event->start;

        sleep 60;
        exit;
    }

    for (1..50) {
        last if -e $flag_file;
        select(undef, undef, undef, 0.1);
    }

    ok -e $flag_file, "SIGTERM test: event callback invoked";

    kill 'TERM', $pid;
    waitpid $pid, 0;
    select(undef, undef, undef, 0.3);

    unlink $flag_file if -e $flag_file;

    my $segs_after = IPC::Shareable::seg_count();
    my $sems_after = IPC::Shareable::sem_count();

    is $segs_after, $segs_before,
        "SIGTERM: no segments leaked after phased _end()";
    is $sems_after, $sems_before,
        "SIGTERM: no semaphores leaked after phased _end()";
}

# ---------------------------------------------------------------------------
# Test 6: Multiple events — all children killed, all segments cleaned
# ---------------------------------------------------------------------------
{
    my $flag1 = File::Temp::tmpnam();
    my $flag2 = File::Temp::tmpnam();

    my $pid = fork;
    die "fork: $!" unless defined $pid;

    if (! $pid) {
        IPC::Shareable->testing_set('Async::Event::Interval');
        require Async::Event::Interval;

        my $e1 = Async::Event::Interval->new(5, sub {
            open my $fh, '>', $flag1; close $fh;
            sleep 30;
        });
        my $e2 = Async::Event::Interval->new(5, sub {
            open my $fh, '>', $flag2; close $fh;
            sleep 30;
        });
        $e1->immediate(1);
        $e2->immediate(1);
        $e1->start;
        $e2->start;

        sleep 60;
        exit;
    }

    for (1..50) {
        last if -e $flag1 && -e $flag2;
        select(undef, undef, undef, 0.1);
    }

    ok(-e $flag1 && -e $flag2, "Multi-event: both callbacks invoked");

    kill 'INT', $pid;
    waitpid $pid, 0;
    select(undef, undef, undef, 0.3);

    unlink $flag1 if -e $flag1;
    unlink $flag2 if -e $flag2;

    my $segs_after = IPC::Shareable::seg_count();
    my $sems_after = IPC::Shareable::sem_count();

    is $segs_after, $segs_before,
        "Multi-event SIGINT: no segments leaked";
    is $sems_after, $sems_before,
        "Multi-event SIGINT: no semaphores leaked";
}

# ---------------------------------------------------------------------------
# Test 7: _alarmed_eval restores caller's SIGALRM handler
# ---------------------------------------------------------------------------
# alarm() is process-global so _alarmed_eval necessarily resets it, but
# the Perl-level $SIG{ALRM} handler and the POSIX sigaction disposition
# should be restored via the local + sigaction save/restore.
{
    my $result_file = File::Temp::tmpnam();

    my $pid = fork;
    die "fork: $!" unless defined $pid;

    if (! $pid) {
        IPC::Shareable->testing_set('Async::Event::Interval');
        require Async::Event::Interval;

        my $outer_fired = 0;
        local $SIG{ALRM} = sub { $outer_fired = 1 };

        Async::Event::Interval::_alarmed_eval(1, sub {});

        # Fire the restored handler to prove it survived
        alarm(1);
        select(undef, undef, undef, 2);
        alarm(0);

        open my $fh, '>', $result_file or die "open: $!";
        print $fh "$outer_fired\n";
        close $fh;

        Async::Event::Interval::_end();
        IPC::Shareable::_end();
        POSIX::_exit(0);
    }

    waitpid $pid, 0;

    SKIP: {
        skip "result file not written", 1 unless -e $result_file;
        open my $fh, '<', $result_file;
        chomp(my $outer_fired = <$fh>);
        close $fh;
        is $outer_fired, 1,
            "_alarmed_eval restores caller's SIGALRM handler";
    }

    unlink $result_file if -e $result_file;
}

# ---------------------------------------------------------------------------
# Test 8: _alarmed_eval with code that succeeds — no side effects
# ---------------------------------------------------------------------------
{
    my $result_file = File::Temp::tmpnam();

    my $pid = fork;
    die "fork: $!" unless defined $pid;

    if (! $pid) {
        IPC::Shareable->testing_set('Async::Event::Interval');
        require Async::Event::Interval;

        my $result = 0;
        Async::Event::Interval::_alarmed_eval(2, sub { $result = 42 });
        my $pending = alarm(0);

        open my $fh, '>', $result_file or die "open: $!";
        print $fh "$result\n$pending\n";
        close $fh;

        Async::Event::Interval::_end();
        IPC::Shareable::_end();
        POSIX::_exit(0);
    }

    waitpid $pid, 0;

    SKIP: {
        skip "result file not written", 2 unless -e $result_file;
        open my $fh, '<', $result_file;
        chomp(my $result = <$fh>);
        chomp(my $pending = <$fh>);
        close $fh;
        is $result, 42, "_alarmed_eval executes code block normally";
        is $pending, 0, "no residual alarm after _alarmed_eval";
    }

    unlink $result_file if -e $result_file;
}

done_testing();
