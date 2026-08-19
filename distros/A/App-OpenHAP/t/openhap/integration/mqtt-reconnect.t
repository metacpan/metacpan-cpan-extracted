#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: MQTT reconnection under the pledge. The reconnect
# path is the one code path that opens new sockets and resolves names
# after the pledge point. Thus it exercises the inet and dns promises
# and the resolver files in the unveil view. The steady-state suite
# touches none of these, because the stock config's numeric mqtt_host
# never resolves anything. Here the daemon runs with
# mqtt_host = localhost. The test restarts the broker underneath it
# and observes recovery through the paired HAP data plane.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use App::OpenHAP::Test::Integration;
use JSON::PP qw(decode_json);
use Time::HiRes qw(sleep time);

my $env = App::OpenHAP::Test::Integration->new;
$env->setup;
$env->ensure_unpaired or die "Cannot reset pairing state\n";

die "MQTT broker required for reconnect tests\n"
    unless $env->ensure_mqtt_running;

my ($light) = grep { $_->{subtype} eq 'lightbulb' } $env->get_devices;
die "No lightbulb device configured for testing\n" unless $light;

my $config_file = '/etc/openhapd.conf';
my $saved       = "/tmp/openhapd.conf.saved-$$";
system("cp $config_file $saved") == 0 or die "cannot save config\n";

# restore(): put the original configuration back and restart
sub restore ($config_file, $saved)
{
	system("cp $saved $config_file");
	unlink $saved;
	$env->restart_daemon;
	return;
}

# Point mqtt_host at a name instead of an address. Then every broker
# (re)connect resolves through the unveiled /etc/hosts under the dns
# promise.
system($^X, '-pi', '-e',
	's/^\s*mqtt_host\s*=.*/mqtt_host = localhost/', $config_file);
my $switched = do {
	open my $fh, '<', $config_file or die "read $config_file: $!";
	grep { /^\s*mqtt_host\s*=\s*localhost/ } <$fh>;
};
ok($switched, 'mqtt_host switched to a resolvable name');

unless ($env->restart_daemon) {
	restore($config_file, $saved);
	die "daemon not serving with mqtt_host = localhost\n";
}
ok(1, 'daemon serves with mqtt_host = localhost');

# Pair and locate the light's On characteristic. Then MQTT delivery
# is observable through the paired data plane, not the daemon logs.
my $controller = $env->get_controller;
$controller->pair_setup
    or die 'pair-setup failed: ' . ($controller->last_error // '?') . "\n";
$controller->pair_verify
    or die 'pair-verify failed: ' . ($controller->last_error // '?') . "\n";

my $database =
    decode_json($controller->request('GET', '/accessories')->{body});

my ($aid, $iid) = $env->find_char($database, '25', name => $light->{name});
ok(defined $iid, 'light On characteristic located') or do {
	restore($config_file, $saved);
	die "cannot locate the On characteristic\n";
};

# on_value(): the current On value through the paired session, or
# undef when the daemon stopped answering. The poll loops then run
# to their deadline. They fail with the rcctl diagnosis instead of a
# JSON parse error.
sub on_value ($controller, $aid, $iid)
{
	my $value = eval {
		my $res = $controller->request('GET',
			"/characteristics?id=$aid.$iid");
		decode_json($res->{body})->{characteristics}[0]{value};
	};
	return unless defined $value;
	return JSON::PP::is_bool($value) ? ($value ? 1 : 0) : $value;
}

# Baseline: the test publishes a device state on the broker. The
# state reaches HAP while the daemon connection uses the resolved
# hostname.
my $mqtt = $env->get_mqtt or die "cannot connect test MQTT client\n";
$mqtt->publish("stat/$light->{topic}/POWER", 'ON');
$env->wait_value(sub { on_value($controller, $aid, $iid) }, 1, 15);
is(on_value($controller, $aid, $iid), 1,
   'baseline round trip: POWER ON visible via HAP');

# Restart the broker underneath the pledged daemon. The daemon's
# reconnect resolves localhost and opens a fresh socket after the
# pledge point. A missing promise or unveil row on that path aborts
# the daemon or strands MQTT. Either failure fails the poll below.
system('rcctl restart mosquitto >/dev/null 2>&1');
die "mosquitto did not come back\n" unless $env->ensure_mqtt_running;
$env->{mqtt} = undef;    # the cached test client died with the broker

# The daemon retries every 30 seconds. Publish OFF repeatedly on a
# fresh client until the flip is visible through HAP. The loop waits
# well past one retry interval before it gives up.
my $deadline = time + 120;
my $recovered = 0;
while (time < $deadline) {
	my $fresh = $env->get_mqtt;
	$fresh->publish("stat/$light->{topic}/POWER", 'OFF') if $fresh;
	if ((on_value($controller, $aid, $iid) // -1) eq '0') {
		$recovered = 1;
		last;
	}
	sleep 3;
}
ok($recovered,
   'daemon reconnected, resolved the broker by name and resubscribed');

ok(system('rcctl check openhapd >/dev/null 2>&1') == 0,
   'daemon survived the broker restart (no pledge violation)');

# Put the numeric-host configuration back for the files that follow
restore($config_file, $saved);
$env->wait_for_hap_port or die "daemon not serving after restore\n";
$env->ensure_unpaired   or die "Cannot reset pairing state\n";

$env->teardown;
done_testing();
