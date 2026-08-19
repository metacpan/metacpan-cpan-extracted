#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Conformance tests for spec/MQTT-Control.md

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../lib";
use lib "$RealBin/../lib";
use Fugu::TestLog;

use_ok('App::OpenHAP::TestMock::MQTT');
use_ok('App::OpenHAP::Tasmota::Heater');
use_ok('App::OpenHAP::Tasmota::Thermostat');
use_ok('App::OpenHAP::Tasmota::Sensor');
use_ok('App::OpenHAP::Tasmota::Lightbulb');

sub make_heater ( $mqtt, %extra )
{
	return App::OpenHAP::Tasmota::Heater->new(
		aid         => 2,
		name        => 'Heater',
		mqtt_topic  => 'device',
		mqtt_client => $mqtt,
		%extra,
	);
}

sub make_light ( $mqtt, $capabilities )
{
	return App::OpenHAP::Tasmota::Lightbulb->new(
		aid          => 2,
		name         => 'Light',
		mqtt_topic   => 'light',
		mqtt_client  => $mqtt,
		capabilities => $capabilities,
	);
}

my $CAP_DIMMER = App::OpenHAP::Tasmota::Lightbulb::CAP_DIMMER();
my $CAP_COLOR  = App::OpenHAP::Tasmota::Lightbulb::CAP_COLOR();
my $CAP_CT     = App::OpenHAP::Tasmota::Lightbulb::CAP_CT();

sub last_published ($mqtt)
{
	my @published = $mqtt->get_published;
	return $published[-1];
}

subtest '[MQTT-Control §1] power control payloads' => sub {
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $heater = make_heater($mqtt);

	$mqtt->clear_published;
	$heater->set_power(1);
	is( last_published($mqtt)->{topic},
		'cmnd/device/Power', 'Power command topic' );
	is( last_published($mqtt)->{payload}, 'ON', 'ON turns relay on' );

	$mqtt->clear_published;
	$heater->set_power(0);
	is( last_published($mqtt)->{payload}, 'OFF', 'OFF turns relay off' );

};

subtest '[MQTT-Control §1] multi-relay and SetOption26' => sub {
	my $mqtt = App::OpenHAP::TestMock::MQTT->new;

	my $plain = make_heater($mqtt);
	is( $plain->_get_power_key,   'POWER', 'single relay uses POWER' );
	is( $plain->_get_power_topic, 'cmnd/device/Power',
		'single relay topic has no index' );

	my $relay2 = make_heater( $mqtt, aid => 3, relay_index => 2 );
	is( $relay2->_get_power_key, 'POWER2',
		'relay 2 uses POWER2 state key' );
	is( $relay2->_get_power_topic, 'cmnd/device/Power2',
		'relay 2 commands Power2' );

};

subtest '[MQTT-Control §2] dimmer control' => sub {
	my $mqtt  = App::OpenHAP::TestMock::MQTT->new;
	my $light = make_light( $mqtt, $CAP_DIMMER );
	$light->subscribe_mqtt;

	$mqtt->clear_published;
	$light->_set_brightness(75);
	is( last_published($mqtt)->{topic},
		'cmnd/light/Dimmer', 'Dimmer command topic' );
	is( last_published($mqtt)->{payload},
		'75', 'brightness percentage 0..100' );
};

subtest '[MQTT-Control §3][MQTT-Control §3.1] HSBColor control' => sub {
	my $mqtt  = App::OpenHAP::TestMock::MQTT->new;
	my $light = make_light( $mqtt, $CAP_DIMMER | $CAP_COLOR );
	$light->subscribe_mqtt;

	$mqtt->clear_published;
	$light->_set_hue(240);
	is( last_published($mqtt)->{topic},
		'cmnd/light/HSBColor1', 'HSBColor1 sets hue only' );
	is( last_published($mqtt)->{payload}, '240', 'hue 0..360' );

	$mqtt->clear_published;
	$light->_set_saturation(80);
	is( last_published($mqtt)->{topic},
		'cmnd/light/HSBColor2', 'HSBColor2 sets saturation only' );
	is( last_published($mqtt)->{payload}, '80', 'saturation 0..100' );
};

subtest '[MQTT-Control §3.2] Color RGB formats' => sub {
	my $mqtt  = App::OpenHAP::TestMock::MQTT->new;
	my $light = make_light( $mqtt, $CAP_COLOR );
	$light->subscribe_mqtt;

	# Hex color format (SetOption17 0, default)
	$mqtt->simulate_message( 'stat/light/RESULT', '{"Color":"FF0000"}' );
	is( $light->{hue}, 0, 'hex color red parsed (hue 0)' );

	# Decimal color format (SetOption17 1)
	$mqtt->simulate_message( 'stat/light/RESULT', '{"Color":"0,255,0"}' );
	is( $light->{hue}, 120, 'decimal color green parsed (hue 120)' );

	$mqtt->simulate_message( 'stat/light/RESULT', '{"Color":"0,0,255"}' );
	is( $light->{hue}, 240, 'decimal color blue parsed (hue 240)' );

	# RGB -> HSB conversion follows the spec value ranges
	my ( $h, $s, $b ) = $light->_rgb_to_hsb( 255, 0, 0 );
	is_deeply( [ $h, $s, $b ], [ 0, 100, 100 ],
		'pure red is 0,100,100' );
	( $h, $s, $b ) = $light->_rgb_to_hsb( 255, 255, 255 );
	is_deeply( [ $s, $b ], [ 0, 100 ], 'white has no saturation' );
	( $h, $s, $b ) = $light->_rgb_to_hsb( 128, 128, 128 );
	is_deeply( [ $s, $b ], [ 0, 50 ], '50% gray at half brightness' );
};

subtest '[MQTT-Control §4] color temperature range' => sub {
	my $mqtt  = App::OpenHAP::TestMock::MQTT->new;
	my $light = make_light( $mqtt, $CAP_CT );
	$light->subscribe_mqtt;

	$mqtt->clear_published;
	$light->_set_ct(300);
	is( last_published($mqtt)->{topic}, 'cmnd/light/CT',
		'CT command topic' );
	is( last_published($mqtt)->{payload}, '300', 'CT in mireds' );

	# The range is 153..500 mireds
	$mqtt->clear_published;
	$light->_set_ct(100);
	is( last_published($mqtt)->{payload},
		'153', 'CT clamped to 153 (cold end)' );

	$mqtt->simulate_message( 'stat/light/RESULT', '{"CT":600}' );
	is( $light->{ct}, 500, 'reported CT clamped to 500 (warm end)' );
};

subtest '[MQTT-Control §5] status queries' => sub {
	my $mqtt = App::OpenHAP::TestMock::MQTT->new;

	# Thermostats query sensor information (Status 10) on subscribe
	my $thermostat = App::OpenHAP::Tasmota::Thermostat->new(
		aid         => 2,
		name        => 'Thermostat',
		mqtt_topic  => 'thermostat',
		mqtt_client => $mqtt,
	);
	$thermostat->subscribe_mqtt;
	ok(
		( grep {
			$_->{topic} eq 'cmnd/thermostat/Status'
			    && $_->{payload} eq '10'
		} $mqtt->get_published ),
		'Status 10 (sensor information) queried on subscribe'
	);

	# The thermostat parses STATUS8 (legacy sensor) responses
	$mqtt->simulate_message( 'stat/thermostat/STATUS8',
		'{"StatusSNS":{"DS18B20":{"Temperature":23},"TempUnit":"C"}}'
	);
	is( $thermostat->{current_temp}, 23,
		'STATUS8 response updates temperature' );

	# The sensor parses STATUS10 responses
	my $sensor = App::OpenHAP::Tasmota::Sensor->new(
		aid         => 3,
		name        => 'Sensor',
		mqtt_topic  => 'sensor',
		mqtt_client => $mqtt,
	);
	$sensor->subscribe_mqtt;
	ok( ( grep { $_ eq 'stat/sensor/STATUS10' }
		    $mqtt->get_subscriptions ),
		'subscribed to STATUS10 responses' );
	$mqtt->simulate_message( 'stat/sensor/STATUS10',
		'{"StatusSNS":{"DS18B20":{"Temperature":26},"TempUnit":"C"}}'
	);
	is( $sensor->{current_temp}, 26,
		'STATUS10 response updates temperature' );

	# The heater parses STATUS11 (full state) responses
	my $heater = make_heater($mqtt);
	$heater->subscribe_mqtt;
	ok( ( grep { $_ eq 'stat/device/STATUS11' }
		    $mqtt->get_subscriptions ),
		'subscribed to STATUS11 responses' );
	$mqtt->simulate_message( 'stat/device/STATUS11',
		'{"StatusSTS":{"POWER":"ON","Uptime":"1T00:00:00"}}' );
	is( $heater->{power_state}, 1,
		'STATUS11 response updates power state' );
};

done_testing();
