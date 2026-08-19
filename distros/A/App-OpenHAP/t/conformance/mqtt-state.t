#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Conformance tests for spec/MQTT-State.md

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../lib";
use lib "$RealBin/../lib";
use Fugu::TestLog;

use_ok('App::OpenHAP::TestMock::MQTT');
use_ok('App::OpenHAP::Tasmota::Heater');
use_ok('App::OpenHAP::Tasmota::Lightbulb');

sub make_heater ($mqtt)
{
	my $heater = App::OpenHAP::Tasmota::Heater->new(
		aid         => 2,
		name        => 'Heater',
		mqtt_topic  => 'device',
		mqtt_client => $mqtt,
	);
	$heater->subscribe_mqtt;
	return $heater;
}

sub make_light ($mqtt)
{
	my $light = App::OpenHAP::Tasmota::Lightbulb->new(
		aid          => 2,
		name         => 'Light',
		mqtt_topic   => 'light',
		mqtt_client  => $mqtt,
		capabilities => App::OpenHAP::Tasmota::Lightbulb::CAP_DIMMER()
		    | App::OpenHAP::Tasmota::Lightbulb::CAP_COLOR()
		    | App::OpenHAP::Tasmota::Lightbulb::CAP_CT(),
	);
	$light->subscribe_mqtt;
	return $light;
}

subtest '[MQTT-State §1] immediate state on stat/' => sub {
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $heater = make_heater($mqtt);

	ok( ( grep { $_ eq 'stat/device/RESULT' }
		    $mqtt->get_subscriptions ),
		'subscribed to stat/+/RESULT' );

	# Plain text POWER response on its own stat topic
	$mqtt->simulate_message( 'stat/device/POWER', 'ON' );
	is( $heater->{power_state}, 1, 'plain POWER ON parsed' );

	$mqtt->simulate_message( 'stat/device/POWER', 'OFF' );
	is( $heater->{power_state}, 0, 'plain POWER OFF parsed' );
};

subtest '[MQTT-State §2] periodic telemetry on tele/' => sub {
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $heater = make_heater($mqtt);

	ok( ( grep { $_ eq 'tele/device/STATE' }
		    $mqtt->get_subscriptions ),
		'subscribed to tele/+/STATE' );
};

subtest '[MQTT-State §3] STATE message structure' => sub {
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $heater = make_heater($mqtt);

	# STATE carries POWER plus device fields
	$mqtt->simulate_message( 'tele/device/STATE',
		'{"Time":"2024-01-01T00:00:00","Uptime":"1T00:00:00",'
		    . '"POWER":"ON","Wifi":{"RSSI":70}}' );
	is( $heater->{power_state}, 1, 'STATE POWER field parsed' );

	# Lightbulb STATE carries Dimmer/HSBColor/CT
	my $light = make_light($mqtt);
	$mqtt->simulate_message( 'tele/light/STATE',
		'{"POWER":"ON","Dimmer":60,"HSBColor":"90,100,60","CT":400}'
	);
	is( $light->{power_state}, 1,  'STATE POWER for light' );
	is( $light->{brightness},  60, 'STATE Dimmer field parsed' );
};

subtest '[MQTT-State §4] RESULT message structure' => sub {
	my $mqtt  = App::OpenHAP::TestMock::MQTT->new;
	my $light = make_light($mqtt);

	$mqtt->simulate_message( 'stat/light/RESULT', '{"POWER":"ON"}' );
	is( $light->{power_state}, 1, 'RESULT POWER parsed' );

	$mqtt->simulate_message( 'stat/light/RESULT', '{"Dimmer":75}' );
	is( $light->{brightness}, 75, 'RESULT Dimmer parsed' );

	$mqtt->simulate_message( 'stat/light/RESULT',
		'{"HSBColor":"180,50,80"}' );
	is( $light->{hue},        180, 'RESULT HSBColor hue parsed' );
	is( $light->{saturation}, 50,  'RESULT HSBColor saturation parsed' );
	is( $light->{brightness}, 80,  'RESULT HSBColor brightness parsed' );

	$mqtt->simulate_message( 'stat/light/RESULT', '{"CT":250}' );
	is( $light->{ct}, 250, 'RESULT CT parsed' );

	# Indexed POWER key for multi-relay devices
	my $relay2 = App::OpenHAP::Tasmota::Heater->new(
		aid         => 3,
		name        => 'Relay 2',
		mqtt_topic  => 'device',
		mqtt_client => $mqtt,
		relay_index => 2,
	);
	$relay2->subscribe_mqtt;
	$mqtt->simulate_message( 'stat/device/RESULT', '{"POWER2":"ON"}' );
	is( $relay2->{power_state}, 1, 'RESULT POWER2 routed to relay 2' );
};

subtest '[MQTT-State §5][MQTT-State §5.1] status command reconciliation' => sub {
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $heater = make_heater($mqtt);

	# Status 11 responses reconcile the device state
	$mqtt->simulate_message( 'stat/device/STATUS11',
		'{"StatusSTS":{"POWER":"ON"}}' );
	is( $heater->{power_state}, 1,
		'STATUS11 reconciles power state' );
};

subtest '[MQTT-State §5.2] reconnection strategy' => sub {
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $heater = make_heater($mqtt);

	# On LWT Online, the subscriptions exist. The accessory queries
	# the state again.
	$mqtt->clear_published;
	$mqtt->simulate_message( 'tele/device/LWT', 'Online' );
	ok(
		( grep {
			$_->{topic} eq 'cmnd/device/Status'
			    && $_->{payload} eq '11'
		} $mqtt->get_published ),
		'Status 11 queried when device comes online'
	);
};

done_testing();
