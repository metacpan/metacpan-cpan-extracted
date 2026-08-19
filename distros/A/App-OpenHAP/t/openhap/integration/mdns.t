#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: mDNS service advertisement

use v5.36;
use Test::More tests => 12;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use App::OpenHAP::Test::Integration;
use IO::Socket::INET;
use Time::HiRes qw(sleep);

my $env = App::OpenHAP::Test::Integration->new;
$env->setup;
$env->ensure_unpaired or die "Cannot reset pairing state\n";

# Test 1: mdnsd daemon is running and stays running. The helper
# starts mdnsd if necessary and emits captured diagnostics on
# failure. The daemon speaks the mdnsd control protocol directly.
# Thus a running mdnsd is the precondition, not the mdnsctl binary.
# openhapd never invokes mdnsctl.
my $mdnsd_available = $env->ensure_mdnsd_running;
ok($mdnsd_available, 'mdnsd daemon is running');

die "mdnsd required for mDNS integration tests\n" unless $mdnsd_available;

# Test 2: OpenHAP daemon is running
my $daemon_running = system('rcctl check openhapd >/dev/null 2>&1') == 0;
ok($daemon_running, 'OpenHAP daemon is running');

# Test 3: mdnsctl is available as the browse tool. These tests
# observe advertisements with it.
my $mdnsctl_available = -x '/usr/sbin/mdnsctl' || -x '/usr/local/bin/mdnsctl';
ok($mdnsctl_available, 'mdnsctl browse tool available');

die "mdnsctl required to observe advertisements\n" unless $mdnsctl_available;

# Restart openhapd so that it re-registers with the running mdnsd.
# The listener opens after the publish conversation. Thus a daemon
# that serves has published the service.
$env->restart_daemon or die "daemon not serving after restart\n";

# Test 4: mdnsctl browse works
my $mdns_output = $env->browse;
ok(length($mdns_output) > 0, 'mdnsctl browse produces output');

# Test 5: The daemon advertises the HAP service ([HAP-mDNS §1] _hap._tcp)
sleep 1;    # Give time for the registration
$mdns_output = $env->browse;
my $hap_found = $mdns_output =~ /hap.*tcp/i;
ok($hap_found, '[HAP-mDNS §1] HAP service advertised via mDNS');

# Test 6: Advertised service name matches the configured bridge name
my $hap_name = $env->get_config_value('hap_name') // 'OpenHAP';
ok($mdns_output =~ /\Q$hap_name\E/i,
   '[HAP-mDNS §4] service instance name matches configured name');

# Test 7: Daemon restart re-advertises service
ok($env->restart_daemon, 'daemon serves again after restart');

# Test 8: Service still browsable after restart ([HAP-mDNS §8])
$mdns_output = $env->browse;
ok($mdns_output =~ /hap.*tcp/i,
   '[HAP-mDNS §8] service re-advertised after daemon restart');

# Test 9: The port that the daemon advertises matches the configuration
my $hap_port = $env->get_config_value('hap_port')
    // App::OpenHAP::Test::Integration::DEFAULT_HAP_PORT;
my $lookup_output = $env->browse;
if ($lookup_output =~ /(\d{4,5})/) {
	ok($lookup_output =~ /\b\Q$hap_port\E\b/,
	   '[HAP-mDNS §6] advertised port matches configured hap_port');
} else {
	# The browse output carries no port. Make sure that the daemon
	# listens on the configured port.
	my $listening = IO::Socket::INET->new(
		PeerAddr => '127.0.0.1',
		PeerPort => $hap_port,
		Proto    => 'tcp',
		Timeout  => 2,
	);
	ok(defined $listening,
	   '[HAP-mDNS §6] daemon listens on the configured HAP port');
	$listening->close if defined $listening;
}

# Test 10: sf=1 advertised while unpaired
my $txt_output = $env->browse_txt;
like($txt_output, qr/sf=1/,
   '[HAP-mDNS §3.7] sf=1 advertised while unpaired');

# Test 11: after pairing, sf flips to 0 in the browsed TXT record.
# The daemon withdraws and republishes on the state change. Thus
# poll the browsed TXT. Do not sleep for a fixed interval.
my $controller = $env->get_controller;
$controller->pair_setup
    or die 'pair-setup failed: ' . ( $controller->last_error // '?' ) . "\n";

my $deadline = time + 30;
$txt_output = $env->browse_txt;
while ($txt_output !~ /sf=0/ && time < $deadline) {
	sleep 1;
	$txt_output = $env->browse_txt;
}
like($txt_output, qr/sf=0/,
   '[HAP-mDNS §8] sf flips to 0 in the browsed TXT after pairing');

# Test 12: c# persists across a daemon restart
my ($config_number) = $txt_output =~ /c#=(\d+)/;
$env->restart_daemon;
$txt_output = $env->browse_txt;
my ($config_number_after) = $txt_output =~ /c#=(\d+)/;
is($config_number_after, $config_number,
   '[HAP-mDNS §3.1] c# persisted across daemon restart');

# Teardown: unpair with a state wipe. The pairing survived the restart.
$env->ensure_unpaired or die "Cannot reset pairing state\n";
$env->teardown;
