use strict;
use warnings;

use Test2::V0;
use Test2::Tools::QuickDB;
use Time::HiRes qw/time/;

# Regression for GH #10: a clone that goes out of scope must clean up after
# itself -- both its DB-QUICK-CLONE-* data dir AND the server daemon it started.
# The report was "two DB-QUICK-CLONE-* directories left after finishing tests"
# each still running a postgres daemon. Unlike t/fast_destroy.t (which exercises
# the SIGKILL destroy_quietly path), this drives the ORDINARY graceful DESTROY
# that fires when the last reference to a clone is dropped.

# The watcher that owns teardown is Unix-only (fork + setsid + POSIX signals).
skip_all "clone teardown relies on the Unix-only watcher (no POSIX signals on $^O)"
    if $^O eq 'MSWin32';

my $db = get_db_or_skipall({driver => 'PostgreSQL'});

# clone() requires a stopped source.
$db->stop if $db->started;

sub pid_alive { my $pid = shift; return 0 unless $pid; return kill(0, $pid) ? 1 : 0 }

my ($dir, $spid, $wpid);
{
    my $clone = $db->clone(autostart => 1);

    # An open handle used to stall the graceful shutdown -- keep one open so this
    # exercises the disconnect-then-stop path a real caller hits.
    my $dbh = $clone->connect('quickdb');
    ok($dbh->{Active}, "connected to the clone");

    $dir  = $clone->dir;
    $spid = $clone->watcher->server_pid;
    $wpid = $clone->watcher->watcher_pid;

    ok(-d $dir,          "clone data dir exists while clone is in scope");
    ok(pid_alive($spid), "clone server is alive while clone is in scope");
    like($dir, qr/DB-QUICK-CLONE-/, "clone lives in a DB-QUICK-CLONE-* dir");

    # Drop the last reference -> graceful DESTROY.
}

# DESTROY -> eliminate + wait: the watcher stops the server, reaps it, removes
# the data dir, then exits. Give it a generous window for a loaded host.
my $start = time;
while (pid_alive($spid) || pid_alive($wpid) || -d $dir) {
    last if time - $start > 30;
    select(undef, undef, undef, 0.05);
}

ok(!pid_alive($spid), "clone server daemon gone after the clone dropped (GH #10)");
ok(!pid_alive($wpid), "clone watcher gone after the clone dropped");
ok(!-d $dir,          "clone data dir removed after the clone dropped (GH #10)");

done_testing;
