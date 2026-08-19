#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: what the daemon does with a signal.
#
# TERM ends the event loop, run returns, and the shutdown happens in
# the daemon. HUP means reload: the daemon reopens its log and keeps
# serving. Before the event loop, one graceful-exit handler took all
# three signals and called exit itself, so HUP killed the daemon that
# an operator asked to reload.
#
# The assertions are observable state, not log lines: the process, the
# HAP port, and the mDNS advertisement.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use Fugu::Pidfile;
use IO::Socket::INET;
use App::OpenHAP::Test::Integration;
use Time::HiRes qw(sleep);

my $env = App::OpenHAP::Test::Integration->new;
$env->setup;

my $pidfile  = Fugu::Pidfile->new( path => '/var/run/openhapd.pid' );
my $hap_port = $env->get_config_value('hap_port') // 51827;
my $hap_name = $env->get_config_value('hap_name') // 'OpenHAP';

# port_open(): can anything connect to the HAP port right now
sub port_open ()
{
	my $sock = IO::Socket::INET->new(
		PeerAddr => '127.0.0.1',
		PeerPort => $hap_port,
		Proto    => 'tcp',
		Timeout  => 2,
	);
	return 0 unless $sock;
	$sock->close;

	return 1;
}

die "mdnsd required for the withdraw assertion\n"
    unless $env->ensure_mdnsd_running;

# ------------------------------------------------------------------
# HUP: the daemon reloads and keeps serving
# ------------------------------------------------------------------

$env->ensure_daemon_running or die "cannot start openhapd\n";
ok( $env->wait_for_hap_port, 'daemon serves before the reload' );

my $before = $pidfile->read_pid;
ok( defined $before && $before =~ /^\d+$/, 'the PID file names a daemon' );

system('rcctl reload openhapd >/dev/null 2>&1');

# Give the daemon time to act on the signal. A daemon that exits on
# HUP is gone within a second; the loop notices the flag on its next
# pass, which is at most one second away.
sleep 3;

ok( $pidfile->is_running, 'the daemon survived SIGHUP' );
is( $pidfile->read_pid, $before,
	'and it is the same process, not a restart' );
ok( port_open(), 'it still serves HAP after the reload' );

# A reload leaves the daemon able to answer, not merely alive
my $response = $env->http_request( 'GET', '/accessories' );
ok( defined $response, 'the reloaded daemon answers a request' );
$env->close_sockets;

# A second reload is the same. An operator reloads on every
# configuration edit, so once is not the interesting case.
system('rcctl reload openhapd >/dev/null 2>&1');
sleep 3;
ok( $pidfile->is_running, 'a second SIGHUP is also survivable' );
is( $pidfile->read_pid, $before, 'still the same process' );

# ------------------------------------------------------------------
# TERM: the daemon ends the loop and shuts down
# ------------------------------------------------------------------

my $pid = $pidfile->read_pid;
kill 'TERM', $pid or die "cannot signal $pid: $!\n";

ok( $env->wait_value( sub { !$pidfile->is_running }, 1, 30 ),
	'the daemon exits on SIGTERM' );
ok( $env->wait_value( sub { !port_open() }, 1, 30 ),
	'and the HAP port closes' );

# The shutdown runs the withdraw before it returns. A daemon that
# died inside a signal handler would leave the advertisement to the
# kernel closing its socket, which is slower and less certain.
ok( $env->wait_value( sub { $env->browse !~ /\Q$hap_name\E/i }, 1, 30 ),
	'the mDNS advertisement is withdrawn' );

# The PID file stays. An unlink in root-owned /var/run needs a
# directory permission that the daemon gives up at the privilege
# drop. See phase 1.
ok( -e '/var/run/openhapd.pid', 'the PID file remains' );
ok( $pidfile->is_stale,         'and a reader can tell it is stale' );

# Restore the daemon for the files that run after this one
system('rcctl start openhapd >/dev/null 2>&1');
$env->wait_for_hap_port or die "daemon not serving after restore\n";

$env->teardown;
done_testing();
