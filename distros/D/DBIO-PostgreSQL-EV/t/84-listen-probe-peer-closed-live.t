use strict;
use warnings;
use Test::More;

# LIVE, karr k88 (_listen_probe): the live half of
# t/83-listen-probe-peer-closed-mock.t. listen_alive of a LISTEN session the
# server ended (pg_terminate_backend) while the EV loop has NOT run since:
# false at once, not "alive" until the loop has read the close. Measured before
# the fix: is_connected stayed true and listen_alive answered 1.
#
# Then the loop runs: the death is reported and healed as ever (t/39 d).

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use Time::HiRes ();
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use GuardedWait;

alarm 120;

my $h     = DBIO::PostgreSQL::EV::TestHarness->new;
my $async = $h->async;
my $s     = LiveServer->control_dbh(attrs => { AutoInactiveDestroy => 1 });

my (@errors, $reconnects);
$async->on_listen_error(sub { push @errors, $_[1] });
$async->on_listen_reconnect(sub { $reconnects++ });
$async->listen_backoff_initial(0.2);
$async->listen_backoff_max(1);

my $channel = "dbio_k88_probe_$$";
my $f = GuardedWait->until_ready($async->listen($channel => sub { }), 15, 'listen still pending after 15s');
ok $f->is_done, 'listening';
ok $async->listen_alive, 'a healthy listen connection is alive';

my $pg  = $async->{_listen}{conn}{pg};
my $pid = $pg->backend_pid;
my ($ok) = $s->selectrow_array('SELECT pg_terminate_backend(?)', undef, $pid);
ok $ok, 'the listen backend was terminated';

# pg_terminate_backend returns before the backend has exited and its socket is
# closed (5-7 ms); give it room, without running the EV loop.
Time::HiRes::sleep(0.5);

ok $pg->is_connected, 'control: EV::Pg still reports the handle connected -- nothing has read';
ok !$async->listen_alive, 'listen_alive sees the ended session without the loop having run';

# The failed probe started healing: the connection is rebuilt once the loop runs.
GuardedWait->until_ready($async->listen_reconnect, 15, 'listen_reconnect still pending after 15s');
ok $async->listen_alive, 'after the loop ran the listen connection is alive again';
isnt $async->{_listen}{conn}{pg}->backend_pid, $pid, '... on a new backend';

$h->disconnect;
$s->disconnect;
done_testing;
