use strict;
use warnings;

use Test2::V0;
use Test2::Tools::QuickDB;
use Time::HiRes qw/time/;
use File::Path qw/remove_tree/;

# Fast destroy for disposable clones: instead of a graceful shutdown that can
# block for up to 2*QDB_STOP_GRACE+2 seconds, destroy_quietly() asks the watcher
# to SIGKILL the server immediately, reap it, and remove the data dir. The
# watcher (the server's parent) still owns/kills/reaps the server -- the Driver
# never signals the stored server pid directly.

# The whole feature relies on the Unix-only watcher (fork + setsid + setpgrp +
# SIGUSR1/sigprocmask). On Win32 the watcher cannot run and only the watcherless
# SQLite driver is viable, so there is nothing to exercise here. The PostgreSQL
# requirement below would skip anyway; this is an explicit, faster guard.
skip_all "fast destroy relies on the Unix-only watcher (no POSIX signals on $^O)"
    if $^O eq 'MSWin32';

my $db = get_db_or_skipall({driver => 'PostgreSQL'});

# clone() requires a stopped source.
$db->stop if $db->started;

sub pid_alive { my $pid = shift; return 0 unless $pid; return kill(0, $pid) ? 1 : 0 }

subtest destroy_quietly_basic => sub {
    my $clone = $db->clone(autostart => 1, cleanup => 1);

    my $dir     = $clone->dir;
    my $watcher = $clone->watcher;
    my $spid    = $watcher->server_pid;
    my $wpid    = $watcher->watcher_pid;

    ok(pid_alive($spid), "server is alive before destroy_quietly");
    ok(-d $dir,          "data dir exists before destroy_quietly");

    # Big grace: if destroy_quietly used the graceful path this would block for
    # tens of seconds. It must not.
    local $ENV{QDB_STOP_GRACE} = 30;

    my $start = time;
    $clone->destroy_quietly;
    my $elapsed = time - $start;

    # Threshold is generous (grace=30 means the graceful path would block up to
    # 2*30+2=62s) so a loaded host running this suite under prove -j8 does not
    # flake; it still proves the grace wait was skipped entirely.
    ok($elapsed < 15, "destroy_quietly did not wait for QDB_STOP_GRACE (${elapsed}s)");

    # Watcher reaps the server before exiting; once the watcher is gone the
    # server is gone too.
    my $gone_start = time;
    while (pid_alive($wpid) || pid_alive($spid)) {
        last if time - $gone_start > 15;
        select(undef, undef, undef, 0.02);
    }

    ok(!pid_alive($spid), "server process is gone after destroy_quietly");
    ok(!pid_alive($wpid), "watcher process is gone after destroy_quietly");
    ok(!-d $dir,          "data dir removed after destroy_quietly");
};

subtest no_checkpoint_no_stop => sub {
    my $clone = $db->clone(autostart => 1, cleanup => 1);

    our ($checkpoint_called, $stop_called) = (0, 0);
    {
        no warnings 'once';
        package Spy::FastDestroy;
        our @ISA = (ref($db));
        sub checkpoint { $checkpoint_called++; return }
        sub stop       { $stop_called++; my $s = shift; $s->SUPER::stop(@_) }
    }
    bless $clone, 'Spy::FastDestroy';

    $clone->destroy_quietly;

    is($checkpoint_called, 0, "destroy_quietly did not call checkpoint()");
    is($stop_called,       0, "destroy_quietly did not call stop()");
};

subtest idempotent => sub {
    my $clone = $db->clone(autostart => 1, cleanup => 1);
    my $dir   = $clone->dir;
    my $wpid  = $clone->watcher->watcher_pid;

    ok(lives { $clone->destroy_quietly }, "first destroy_quietly lives") or diag($@);

    # Second call is a no-op: the watcher is already gone, so it must not throw
    # or try to signal a (possibly recycled) pid again.
    ok(lives { $clone->destroy_quietly }, "second destroy_quietly is a safe no-op") or diag($@);

    # Dropping the object after destroy_quietly must not signal again either.
    ok(lives { undef $clone }, "dropping after destroy_quietly does not re-signal") or diag($@);

    ok(!-d $dir, "data dir stayed removed");
};

subtest fast_destroy_attr_cleanup => sub {
    # fast_destroy => 1 with cleanup => 1: dropping the clone must use the fast
    # path (no QDB_STOP_GRACE wait) and remove the data dir.
    my $clone = $db->clone(autostart => 1, cleanup => 1, fast_destroy => 1);

    ok($clone->fast_destroy, "clone carries the fast_destroy attribute");

    my $dir  = $clone->dir;
    my $wpid = $clone->watcher->watcher_pid;
    my $spid = $clone->watcher->server_pid;

    local $ENV{QDB_STOP_GRACE} = 30;

    my $start = time;
    undef $clone;
    my $elapsed = time - $start;

    # Generous threshold (vs grace=30 -> up to 62s graceful) to stay robust
    # under prove -j8 load while still proving the fast path was taken.
    ok($elapsed < 15, "DESTROY used fast path, no QDB_STOP_GRACE wait (${elapsed}s)");

    my $gone = time;
    while (pid_alive($wpid) || pid_alive($spid)) {
        last if time - $gone > 15;
        select(undef, undef, undef, 0.02);
    }
    ok(!pid_alive($spid), "server gone after fast DESTROY");
    ok(!pid_alive($wpid), "watcher gone after fast DESTROY");
    ok(!-d $dir,          "data dir removed after fast DESTROY");
};

subtest fast_destroy_attr_inherited_by_clone => sub {
    # The attribute must propagate through clone_data() so a clone of a
    # fast_destroy source is itself fast_destroy.
    my $clone = $db->clone(cleanup => 1, fast_destroy => 1);
    ok($clone->fast_destroy, "clone carries fast_destroy");

    my %data = $clone->clone_data;
    ok($data{DBIx::QuickDB::Driver::FAST_DESTROY()}, "clone_data propagates fast_destroy to further clones");

    $clone->destroy_quietly;
};

subtest fast_destroy_attr_no_cleanup => sub {
    # fast_destroy => 1 but cleanup => 0: the _CLEANUP guard means DESTROY must
    # NOT take the fast path. The data dir must survive (cleanup => 0).
    my $clone = $db->clone(autostart => 1, cleanup => 0, fast_destroy => 1);
    my $dir = $clone->dir;

    $clone->stop;
    undef $clone;

    ok(-d $dir, "cleanup => 0 data dir preserved (fast path not taken)");

    # Clean up the preserved dir ourselves.
    File::Path::remove_tree($dir) if -d $dir;
};

subtest dbi_handles_disconnected => sub {
    # destroy_quietly() disconnects this process's DBI handles before the server
    # is killed, so we do not retain a live-but-broken handle that would later
    # report "server has gone away".
    my $clone = $db->clone(autostart => 1, cleanup => 1);
    my $dbh   = $clone->connect('quickdb');

    ok($dbh->{Active}, "handle is active before destroy_quietly");

    $clone->destroy_quietly;

    ok(!$dbh->{Active}, "handle was disconnected by destroy_quietly");
};

done_testing;
