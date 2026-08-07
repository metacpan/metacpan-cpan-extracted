use strict;
use warnings;

use Test2::V0;
use POSIX qw/:sys_wait_h/;
use File::Temp qw/tempdir tempfile/;

# Without this "sleep 0.05" is CORE::sleep(0), collapsing the poll budgets below
# from 5 seconds to 5 milliseconds and flaking under -j16.
use Time::HiRes qw/sleep time/;
use File::Path qw/remove_tree/;

# POSIX process semantics throughout: zombies, ECHILD, and a signal in the low 7
# bits of the wait status. MSWin32 has none of it, and never builds a watcher.
skip_all "POSIX wait-status and zombie semantics do not exist on $^O"
    if $^O eq 'MSWin32';

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use DBIx::QuickDB::Watcher;
use QDB::FakeDriver;

# The watcher's server is its own child and nothing else reaped it, so a crashed
# server lingered as a zombie -- and kill(0) succeeds on a zombie, so start()
# called it alive and waited out the whole timeout. The watcher now reaps it and
# records the wait status where the owner, which cannot waitpid, can read it.

my $dir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);

# Returns -1 rather than dying, so an exhausted poll budget fails one assertion
# instead of aborting the file.
sub read_status {
    my ($file) = @_;

    open(my $fh, '<', $file) or do {
        diag("Could not open '$file': $!");
        return -1;
    };
    chomp(my $status = <$fh> // '');
    close($fh);

    return length($status) ? $status : -1;
}

subtest zombie_defeats_kill_0 => sub {
    my $pid = fork();
    die "Could not fork: $!" unless defined $pid;
    if (!$pid) { POSIX::_exit(0) }

    # Give it a moment to exit without reaping it.
    sleep 1;

    ok(kill(0, $pid), "kill(0) still succeeds on the unreaped (zombie) child")
        or diag("This premise is what made the old 'alive' probe wrong");

    waitpid($pid, 0);
};

subtest reap_records_status => sub {
    my $sdir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $file = DBIx::QuickDB::Watcher->server_exit_status_file($sdir);

    my $pid = fork();
    die "Could not fork: $!" unless defined $pid;
    if (!$pid) { POSIX::_exit(42) }

    ok(!-f $file, "No status file before the reap");

    # Poll exactly as the watch loop does.
    my $reaped = 0;
    for (1 .. 100) {
        $reaped = DBIx::QuickDB::Watcher->_reap_server($pid, $sdir);
        last if $reaped;
        sleep 0.05;
    }

    ok($reaped, "Reaped the exited child");
    ok(-f $file, "Status file was written");

    my $status = read_status($file);

    is($status >> 8, 42, "Recorded the child's exit value");
    is($status & 127, 0, "No terminating signal recorded");

    # A second call cannot reap again, so it reports not-collected. Harmless:
    # the watch loop latches the first true result and stops calling.
    ok(!DBIx::QuickDB::Watcher->_reap_server($pid, $sdir), "Re-reap reports not-collected and does not die");
    ok(-f $file, "Re-reap left the recorded status in place");
};

subtest reap_records_signal => sub {
    my $sdir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $file = DBIx::QuickDB::Watcher->server_exit_status_file($sdir);

    my $pid = fork();
    die "Could not fork: $!" unless defined $pid;
    if (!$pid) { sleep 30; POSIX::_exit(0) }

    kill('KILL', $pid);

    my $reaped = 0;
    for (1 .. 100) {
        $reaped = DBIx::QuickDB::Watcher->_reap_server($pid, $sdir);
        last if $reaped;
        sleep 0.05;
    }

    ok($reaped, "Reaped the killed child");

    is(read_status($file) & 127, 9, "Recorded SIGKILL as the terminating signal");
};

subtest running_server_is_not_reaped => sub {
    my $sdir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $file = DBIx::QuickDB::Watcher->server_exit_status_file($sdir);

    my $pid = fork();
    die "Could not fork: $!" unless defined $pid;
    if (!$pid) { sleep 30; POSIX::_exit(0) }

    ok(!DBIx::QuickDB::Watcher->_reap_server($pid, $sdir), "Live child is not reported reaped");
    ok(!-f $file, "No status file written for a live server");

    kill('KILL', $pid);
    waitpid($pid, 0);
};

subtest missing_child_is_not_reported_collected => sub {
    my $sdir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $file = DBIx::QuickDB::Watcher->server_exit_status_file($sdir);

    # waitpid returning -1 does not prove the server is dead. Claiming collected
    # would make teardown skip the kill and orphan a live server.
    ok(!DBIx::QuickDB::Watcher->_reap_server($$, $sdir), "Non-child pid is NOT reported collected");
    ok(!-f $file, "No status invented for a pid whose status we cannot read");
};

subtest sigchld_ignore_auto_reap => sub {
    my $sdir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $file = DBIx::QuickDB::Watcher->server_exit_status_file($sdir);

    # With SIGCHLD ignored the kernel reaps the child, and waitpid then returns
    # -1 with the status gone. The one route by which a server can vanish
    # without _reap_server seeing a real reap.
    my $pid;
    {
        local $SIG{CHLD} = 'IGNORE';

        $pid = fork();
        die "Could not fork: $!" unless defined $pid;
        if (!$pid) { POSIX::_exit(7) }

        is(DBIx::QuickDB::Watcher->_reap_server($pid, $sdir), 0, "A live child reports not-collected (waitpid gave 0)");

        # Wait for the kernel to auto-reap, which is what makes waitpid return -1.
        my $gone = 0;
        for (1 .. 100) {
            $gone = (waitpid($pid, WNOHANG) < 0) ? 1 : 0;
            last if $gone;
            sleep 0.05;
        }

        ok($gone, "Kernel auto-reaped the child, so waitpid now returns -1");

        is(
            DBIx::QuickDB::Watcher->_reap_server($pid, $sdir),
            0,
            "An auto-reaped child still reports not-collected, so teardown keeps its kill path"
        );
    }

    ok(!-f $file, "No status invented for a child whose status the kernel consumed");
};

subtest reap_survives_unwritable_dir => sub {
    my $pid = fork();
    die "Could not fork: $!" unless defined $pid;
    if (!$pid) { POSIX::_exit(0) }

    my $reaped = 0;
    for (1 .. 100) {
        # Recording must never die -- that would take the watcher down and
        # orphan a live server.
        $reaped = DBIx::QuickDB::Watcher->_reap_server($pid, "$dir/does/not/exist");
        last if $reaped;
        sleep 0.05;
    }

    ok($reaped, "Reaped even though the status file could not be written");
};

# Integration: the subtests above prove _reap_server works, not that anything
# calls it -- deleting the call left the whole suite green. These drive a real
# watcher and a real Driver::start via QDB::FakeDriver.

subtest watch_loop_records_status_and_start_fails_fast => sub {
    my $dir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);

    local $ENV{QDB_START_TIMEOUT} = 30;

    my $db = QDB::FakeDriver->new(
        dir       => $dir,
        exit_code => 7,
        cleanup   => 0,
        autostart => 0,
    );

    my $start = time;
    my $ok    = eval { $db->start; 1 };
    my $err   = $@;
    my $took  = time - $start;

    ok(!$ok, "start() failed for a server that exited during startup");

    # Timeout is 30s and the server dies in milliseconds; anything near it means
    # the loop is not reaping.
    ok($took < 10, "Failed fast (${\ sprintf('%.2f', $took)}s) rather than waiting out the 30s timeout");

    like($err, qr/exited during startup/, "Reported a startup exit, not a timeout");
    like($err, qr/exit value 7/, "Carried the server's decoded exit value end to end");
};

subtest watch_loop_records_a_signalled_server => sub {
    my $dir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);

    local $ENV{QDB_START_TIMEOUT} = 30;

    # Aborts itself; the wait status carries a signal rather than an exit code.
    my $db = QDB::FakeDriver->new(
        dir          => $dir,
        start_script => 'kill("ABRT", $$); sleep 30',
        cleanup      => 0,
        autostart    => 0,
    );

    my $ok  = eval { $db->start; 1 };
    my $err = $@;

    ok(!$ok, "start() failed for a server killed by a signal");
    like($err, qr/killed by signal 6/, "Decoded the terminating signal rather than an exit value");
};

subtest watcher_owns_child_reaping_regardless_of_the_caller => sub {
    # Pins watch()'s SIGCHLD reset, whose deletion left the suite green. Reads
    # the disposition the server was handed, which is the watcher's at fork
    # time; needs a /bin/sh server because perl resets SIGCHLD at startup.
    # Linux specifically, not merely "a readable /proc/self/status": other
    # procfs implementations (FreeBSD, NetBSD, Solaris) expose that path in a
    # different format with no SigIgn: line, where the grep below would write an
    # empty file and the parse would fail instead of skipping.
    skip_all "Needs Linux /proc/self/status to read the inherited signal mask"
        unless $^O eq 'linux' && -r '/proc/self/status';

    my $dir  = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $out  = "$dir/siginfo";

    local $ENV{QDB_START_TIMEOUT} = 5;
    local $ENV{QDB_SIGINFO}       = $out;
    local $SIG{CHLD} = 'IGNORE';    # the hostile disposition to inherit

    my $db = QDB::FakeDriver->new(
        dir          => $dir,
        # Path via the environment, never interpolated into the program text: a
        # TMPDIR containing a quote would otherwise corrupt the shell program.
        shell_script => 'grep ^SigIgn: /proc/self/status > "$QDB_SIGINFO"; exit 0',
        cleanup      => 0,
        autostart    => 0,
    );

    eval { $db->start; 1 };    # fails: no socket is ever created

    ok(-f $out, "The server recorded the signal mask it was handed") or return;

    open(my $fh, '<', $out) or die "Could not read '$out': $!";
    chomp(my $line = <$fh> // '');
    close($fh);

    my ($hex) = $line =~ m/SigIgn:\s*([0-9a-fA-F]+)/;
    ok(defined $hex, "Parsed SigIgn from '$line'") or return;

    # SIGCHLD is 17 on Linux, so bit 16 of the ignored-signal mask.
    my $chld_bit = hex($hex) & (1 << 16);

    is($chld_bit, 0, "The server was spawned with SIGCHLD NOT ignored, so the watcher can reap it")
        or diag("SigIgn=$hex -- the watcher passed on the caller's ignored SIGCHLD, so the kernel will reap the server and no exit status can ever be recorded");
};

# Removing a disposable data dir is a goal in its own right, not a reward for a
# successful kill: a dir that outlives the process that asked for it is the
# failure the watcher exists to prevent. A server that cannot be signalled at
# all is already pathological, and its dir must still go.
#
# The eliminate case pins a leak the TERM path really had. The fast_eliminate
# case pins policy rather than a past leak -- master already removed the dir
# there on a kill failure -- so it guards against the gate being reintroduced.
for my $case (
    {name => 'eliminate',      method => 'eliminate',      args => {stop_signal      => 999}},
    {name => 'fast_eliminate', method => 'fast_eliminate', args => {fast_stop_signal => 999, fast_destroy => 1}},
) {
    subtest "unstoppable_server_still_loses_its_data_dir_via_$case->{name}" => sub {
        my $dir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);

        local $ENV{QDB_START_TIMEOUT} = 3;
        local $ENV{QDB_STOP_GRACE}    = 1;

        my $db = QDB::FakeDriver->new(
            dir         => $dir,
            serve       => 1,
            run_seconds => 30,
            cleanup     => 1,
            autostart   => 0,
            %{$case->{args}},
        );

        # The watcher warns about the undeliverable signal from its own process,
        # where warnings{} cannot reach it. Its STDERR is whatever fd 2 was when
        # start() forked, so redirect across the fork and restore straight after
        # -- the watcher keeps the file, this process keeps the harness.
        my ($errfh, $errfile) = tempfile("QDB-TEST-$$-XXXXXX", TMPDIR => 1, UNLINK => 1);
        open(my $saved_stderr, '>&', \*STDERR) or die "Could not save STDERR: $!";
        open(STDERR, '>&', $errfh) or die "Could not redirect STDERR: $!";

        my $started = eval { $db->start; 1 };
        my $start_err = $@;

        open(STDERR, '>&', $saved_stderr) or die "Could not restore STDERR: $!";
        close($saved_stderr);
        die $start_err unless $started;

        my $watcher = $db->watcher;
        my $spid    = $watcher ? $watcher->server_pid : 0;
        ok($spid, "Got a server pid") or return;

        # Checked at the WATCHER, before the driver is destroyed: the driver
        # calls cleanup() as its own fallback, so asserting after DESTROY
        # passes even with the watcher's removal gated off. When an owner
        # exits without running destructors the watcher is the only cleanup.
        my $method = $case->{method};
        $watcher->$method;

        # Captured rather than left to leak into the harness, and asserted: a
        # server this pathological is exactly what the probe exists to report,
        # so losing the warning is a regression.
        my $warnings = warnings { $watcher->wait };
        like(
            join("\n", @$warnings),
            qr/still appears to be alive/,
            "wait() reported the server that outlived its watcher",
        );

        my $watcher_stderr = do {
            open(my $fh, '<', $errfile) or die "Could not read '$errfile': $!";
            local $/;
            <$fh> // '';
        };
        like(
            $watcher_stderr,
            qr/Could not signal server pid \Q$spid\E with SIG999: /,
            "The watcher reported the signal it could not deliver",
        );

        ok(kill(0, $spid), "Server survived, as an invalid signal guarantees");
        ok(!-d $dir, "The watcher removed its disposable data dir anyway");

        kill('KILL', $spid);
        waitpid($spid, 0);
    };
}

# Both signals that lead to the removal. eliminate() alone left the latch on
# fast_eliminate() -- the path destroy_quietly takes -- free to be deleted with
# the whole suite still green.
for my $method (qw/eliminate fast_eliminate/) {
    subtest "reap_proof_survives_the_dir_it_was_written_in_via_$method" => sub {
        # The watch loop records its reap inside the data dir, and disposable
        # teardown then deletes that dir. The result has to be latched before
        # the signal that triggers that teardown, or wait() loses the proof and
        # probes the stored pid instead -- which, for a server reaped long
        # before its owner was destroyed, may name an unrelated live process by
        # then. That costs the full stop timeout and warns about a server
        # reaped ages ago.
        #
        # Driven through the public signal, not the latch helper: calling the
        # helper would pass with nothing wired to it.
        local $ENV{QDB_STOP_GRACE} = 1;

        my $sdir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);

        open(my $sfh, '>', DBIx::QuickDB::Watcher->server_exit_status_file($sdir))
            or die "Could not write status: $!";
        print $sfh "0\n";
        close($sfh);

        # Stands in for a watcher that has not exited yet, and for a server pid
        # since recycled to something unrelated and alive.
        my $fake_watcher = fork();
        die "Could not fork: $!" unless defined $fake_watcher;
        if (!$fake_watcher) { $SIG{TERM} = 'IGNORE'; $SIG{USR1} = 'IGNORE'; sleep 60; POSIX::_exit(0) }

        my $decoy_server = fork();
        die "Could not fork: $!" unless defined $decoy_server;
        if (!$decoy_server) { sleep 60; POSIX::_exit(0) }

        my $watcher = bless {
            DBIx::QuickDB::Watcher::DATA_DIR()    => $sdir,
            DBIx::QuickDB::Watcher::MASTER_PID()  => $$,
            DBIx::QuickDB::Watcher::SERVER_PID()  => $decoy_server,
            DBIx::QuickDB::Watcher::WATCHER_PID() => $fake_watcher,
        }, 'DBIx::QuickDB::Watcher';

        $watcher->$method;

        ok($watcher->server_reaped, "$method() latched the reap before the dir could be removed");

        remove_tree($sdir);    # disposable cleanup takes the proof with it

        kill('KILL', $fake_watcher);
        waitpid($fake_watcher, 0);

        my $start = time;
        $watcher->wait();
        my $took = time - $start;

        ok($took < 1, "wait() returned at once rather than probing a recycled pid");

        kill('KILL', $decoy_server);
        waitpid($decoy_server, 0);
    };
}

subtest reusable_data_dir_is_never_removed => sub {
    # The other side of the boundary. A cleanup => 0 dir is somebody's template
    # -- Pool builds its cache this way -- and clones are made from it long after
    # this process is gone. "Remove it anyway" applies only to disposable dirs.
    my $dir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);

    local $ENV{QDB_START_TIMEOUT} = 3;

    my $db = QDB::FakeDriver->new(dir => $dir, serve => 1, run_seconds => 30, cleanup => 0, autostart => 0);

    $db->start;
    undef $db;

    ok(-d $dir, "A reusable data dir survives teardown");
};

subtest teardown_still_cleans_up_normally => sub {
    # The guard above must not cost the ordinary case its cleanup.
    my $dir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);

    local $ENV{QDB_START_TIMEOUT} = 3;

    my $db = QDB::FakeDriver->new(dir => $dir, serve => 1, run_seconds => 30, cleanup => 1, autostart => 0);

    $db->start;

    my $spid = $db->watcher ? $db->watcher->server_pid : 0;
    undef $db;

    ok(!-d $dir, "Data dir removed when the server really did stop");
    ok(!($spid && kill(0, $spid)), "Server is gone");
};

subtest vanished_server_does_not_block_data_dir_cleanup => sub {
    my $dir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);

    # A pid that is gone: kill() fails with ESRCH. _watcher_kill used to die
    # there ("Could not send kill signal"), and that die propagates out of
    # _do_watch, which exits WITHOUT reaching the remove_tree below it -- so the
    # disposable data dir leaked. Reachable whenever something outside the
    # watcher collected the server.
    my $pid = fork();
    die "Could not fork: $!" unless defined $pid;
    if (!$pid) { POSIX::_exit(0) }
    waitpid($pid, 0);

    my $ok = eval { DBIx::QuickDB::Watcher->_watcher_kill('TERM', $pid, 'KILL'); 1 };

    ok($ok, "_watcher_kill returns instead of dying when the server is already gone")
        or diag("died: $@");

    # And the whole teardown completes, including the removal it guards.
    my $ddir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    open(my $fh, '>', "$ddir/payload") or die "Could not write payload: $!";
    close($fh);

    my $done = eval {
        DBIx::QuickDB::Watcher->_watcher_terminate(
            send_sig    => 'TERM',
            got_sig     => 'TERM',
            pid         => $pid,
            dir         => $ddir,
            delete_data => 1,
        );
        1;
    };

    ok($done, "_watcher_terminate completed for an already-collected server") or diag("died: $@");
    ok(!-d $ddir, "The disposable data dir was removed rather than leaked");
};

done_testing;
