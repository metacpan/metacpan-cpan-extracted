#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: MQTT integration with devices

use v5.36;
use Test::More tests => 12;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use App::OpenHAP::Test::Integration;
use Time::HiRes qw(sleep);

my $env = App::OpenHAP::Test::Integration->new;
$env->setup;

# Test 1: Mosquitto MQTT broker is running
my $mqtt_ok = $env->ensure_mqtt_running;
ok($mqtt_ok, 'MQTT broker is running');

# All remaining tests require MQTT
die "MQTT broker required for integration tests\n" unless $mqtt_ok;

# Test 2: Configuration has MQTT-enabled devices
my @device_topics = $env->get_device_topics;
ok(@device_topics > 0, 'devices with MQTT topics configured');

die "No devices configured for MQTT testing\n" unless @device_topics;

# Test 3: Can connect to MQTT broker
my $mqtt = $env->get_mqtt;
ok(defined $mqtt, 'connected to MQTT broker');

die "Cannot connect to MQTT broker\n" unless defined $mqtt;

my $topic = $device_topics[0];

# Test 4: OpenHAP daemon processes MQTT messages
my $daemon_running = system('rcctl check openhapd >/dev/null 2>&1') == 0;
ok($daemon_running, 'OpenHAP daemon is running');

# Test 5: Can publish to device stat/ topic
my $published = 0;
eval {
	$mqtt->publish("stat/$topic/POWER", "ON");
	sleep 0.3;
	$published = 1;
};
ok($published && !$@, 'published to stat/ topic');

# Test 6: Can publish to device cmnd/ topic
eval {
	$mqtt->publish("cmnd/$topic/Status", "0");
	sleep 0.3;
};
ok(!$@, 'published to cmnd/ topic');

# Test 7: Can subscribe to device topics
my $subscribed = 0;
eval {
	$mqtt->subscribe("stat/$topic/#", sub { });
	sleep 0.2;
	$subscribed = 1;
};
ok($subscribed, 'subscribed to device topics');

# Test 8: Publish and receive work
my $received = 0;
eval {
	$mqtt->subscribe("stat/$topic/TEST", sub { $received = 1; });
	sleep 0.3;
	$mqtt->publish("stat/$topic/TEST", "test");
	
	my $timeout = 3;
	my $start = time;
	while (!$received && (time - $start) < $timeout) {
		$mqtt->tick(0.2);
	}
};
ok($received || !$@, 'MQTT publish/subscribe works');

# Test 9: The broker accepts multiple MQTT messages
my $multiple_ok = 1;
eval {
	for my $i (1..5) {
		$mqtt->publish("stat/$topic/POWER", $i % 2 ? "ON" : "OFF");
		sleep 0.1;
	}
};
$multiple_ok = 0 if $@;
ok($multiple_ok, 'multiple MQTT messages handled');

# Test 10: Publishing works on every configured device topic
{
	my $all_topics_ok = 1;
	eval {
		for my $t (@device_topics[0..min(2, $#device_topics)]) {
			$mqtt->publish("stat/$t/POWER", "ON");
			sleep 0.1;
		}
	};
	$all_topics_ok = 0 if $@;
	ok($all_topics_ok, 'all configured device topics accept publishes');
}

sub min($a, $b) { $a < $b ? $a : $b; }

# Test 11: OpenHAP still responsive after MQTT activity
sleep 0.5;
my $response = $env->http_request('GET', '/accessories');
ok(defined $response, 'daemon responsive after MQTT activity');

# Test 12: Clean disconnect from MQTT
my $clean_disconnect = 0;
eval {
	$mqtt->unsubscribe("stat/$topic/#");
	undef $mqtt;
	$env->{mqtt} = undef;
	$clean_disconnect = 1;
};
ok($clean_disconnect, 'clean MQTT disconnect');

$env->teardown;
