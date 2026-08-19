#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: mDNS advertisement lifetime and process hygiene.
# The daemon speaks the mdnsd control protocol over a held socket.
# There is no child process and no mdnsctl.log. When the daemon
# exits, the socket closes, and this withdraws the advertisement.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use App::OpenHAP::Test::Integration;
use Time::HiRes qw(sleep);

my $env = App::OpenHAP::Test::Integration->new;
$env->setup;

die "mdnsd required for mDNS lifetime tests\n"
    unless $env->ensure_mdnsd_running;

my $db_path = $env->get_config_value('db_path') // '/var/db/openhapd';
my $hap_name = $env->get_config_value('hap_name') // 'OpenHAP';

# Remove any mdnsctl.log that a pre-rewrite daemon left behind. Then
# the assertion below fails only if the running daemon creates one.
unlink "$db_path/mdnsctl.log";

# Restart openhapd so it publishes against the running mdnsd
$env->restart_daemon or die "daemon not serving after restart\n";

ok(system('rcctl check openhapd >/dev/null 2>&1') == 0,
   'daemon is running');

# The advertisement is visible while the daemon holds its socket
my $deadline = time + 30;
my $output   = $env->browse;
while ($output !~ /\Q$hap_name\E/i && time < $deadline) {
	sleep 1;
	$output = $env->browse;
}
like($output, qr/\Q$hap_name\E/i,
     'service advertised while the daemon runs');

# No child processes: the daemon publishes over a socket. It does
# not spawn a helper. pgrep -P lists children of the daemon's pid.
chomp( my $daemon_pid = `pgrep -f 'perl.*openhapd' | head -1` );
like($daemon_pid, qr/^\d+$/, 'daemon pid known');

my $children = `pgrep -P $daemon_pid 2>/dev/null`;
is($children, '', 'daemon has no child processes at all');

# No mdnsctl.log: the log file existed only for the mdnsctl child
ok(!-e "$db_path/mdnsctl.log", 'no mdnsctl.log is created');

# When the daemon stops, the control socket closes. The closed
# socket withdraws the advertisement within a few seconds. This
# needs no signal, no kill, and no child.
system('rcctl stop openhapd >/dev/null 2>&1');
sleep 2;
ok(system('rcctl check openhapd >/dev/null 2>&1') != 0,
   'daemon stopped');

$deadline = time + 30;
$output   = $env->browse;
while ($output =~ /\Q$hap_name\E/i && time < $deadline) {
	sleep 1;
	$output = $env->browse;
}
unlike($output, qr/\Q$hap_name\E/i,
       'advertisement withdrawn after the daemon exits');

# The daemon starts and serves with mdnsd stopped. Discovery
# degrades, but the HAP service does not.
system('rcctl stop mdnsd >/dev/null 2>&1');
sleep 1;
system('rcctl start openhapd >/dev/null 2>&1');
ok($env->wait_for_hap_port, 'daemon serves HAP with mdnsd stopped');

# Restore the environment for the files that run after this one
system('rcctl stop openhapd >/dev/null 2>&1');
die "cannot restart mdnsd\n" unless $env->ensure_mdnsd_running;
system('rcctl start openhapd >/dev/null 2>&1');
$env->wait_for_hap_port or die "daemon not serving after restore\n";

$env->teardown;
done_testing();
