#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Conformance tests for spec/MQTT-Sensors.md

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../lib";
use lib "$RealBin/../lib";
use Fugu::TestLog;

use_ok('App::OpenHAP::TestMock::MQTT');
use_ok('App::OpenHAP::Tasmota::Sensor');
use_ok('App::OpenHAP::Tasmota::Device');

sub make_sensor ( $mqtt, %extra )
{
	my $sensor = App::OpenHAP::Tasmota::Sensor->new(
		aid         => 2,
		name        => 'Sensor',
		mqtt_topic  => 'sensor',
		mqtt_client => $mqtt,
		%extra,
	);
	$sensor->subscribe_mqtt;
	return $sensor;
}

subtest '[MQTT-Sensors §1] SENSOR message structure' => sub {
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $sensor = make_sensor($mqtt);

	ok( ( grep { $_ eq 'tele/sensor/SENSOR' }
		    $mqtt->get_subscriptions ),
		'[MQTT-Sensors §5.2] subscribed to tele/+/SENSOR' );

	$mqtt->simulate_message( 'tele/sensor/SENSOR',
		'{"Time":"2024-01-01T00:00:00",'
		    . '"DS18B20":{"Temperature":25.5},"TempUnit":"C"}' );
	is( $sensor->{current_temp}, 25.5,
		'per-sensor object parsed from SENSOR message' );
};

subtest '[MQTT-Sensors §2] common sensor types' => sub {
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $sensor = make_sensor($mqtt);

	$mqtt->simulate_message( 'tele/sensor/SENSOR',
		'{"DS18B20":{"Temperature":21},"TempUnit":"C"}' );
	is( $sensor->{sensor_type}, 'DS18B20',
		'[MQTT-Sensors §2/DS18B20] type auto-detected' );

	my $dht = make_sensor(
		App::OpenHAP::TestMock::MQTT->new,
		aid          => 3,
		name         => 'DHT',
		has_humidity => 1,
	);
	$dht->{mqtt_client}->simulate_message( 'tele/sensor/SENSOR',
		'{"DHT22":{"Temperature":22.5,"Humidity":65},"TempUnit":"C"}'
	);
	is( $dht->{sensor_type}, 'DHT22',
		'[MQTT-Sensors §2/DHT11] DHT-family type auto-detected' );
};

subtest '[MQTT-Sensors §3] temperature sensors' => sub {
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $sensor = make_sensor($mqtt);

	# The sensor passes TempUnit C readings through
	$mqtt->simulate_message( 'tele/sensor/SENSOR',
		'{"DS18B20":{"Temperature":25},"TempUnit":"C"}' );
	is( $sensor->{current_temp}, 25, 'Celsius reading passed through' );

	# The sensor converts TempUnit F readings before use in HomeKit
	$mqtt->simulate_message( 'tele/sensor/SENSOR',
		'{"DS18B20":{"Temperature":77},"TempUnit":"F"}' );
	ok( abs( $sensor->{current_temp} - 25 ) < 0.1,
		'TempUnit F converted to Celsius (77F = 25C)' );

	# The conversion helper converts the boundary case correctly
	my $base = App::OpenHAP::Tasmota::Device->new(
		aid         => 9,
		name        => 'Conv',
		mqtt_topic  => 'conv',
		mqtt_client => $mqtt,
	);
	$base->{temp_unit} = 'F';
	ok( abs( $base->convert_temperature(32) ) < 0.1, '32F = 0C' );

	# Multiple sensors report under indexed keys
	my $indexed = make_sensor(
		App::OpenHAP::TestMock::MQTT->new,
		aid          => 4,
		name         => 'Indexed',
		sensor_type  => 'DS18B20',
		sensor_index => 2,
	);
	$indexed->{mqtt_client}->simulate_message( 'tele/sensor/SENSOR',
		'{"DS18B20-1":{"Temperature":20},'
		    . '"DS18B20-2":{"Temperature":25},"TempUnit":"C"}' );
	is( $indexed->{current_temp}, 25,
		'indexed sensor DS18B20-2 selected' );
};

subtest '[MQTT-Sensors §4] humidity sensors' => sub {
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $sensor = make_sensor( $mqtt, has_humidity => 1 );

	$mqtt->simulate_message( 'tele/sensor/SENSOR',
		'{"DHT22":{"Temperature":22.5,"Humidity":65},"TempUnit":"C"}'
	);
	is( $sensor->{current_temp},     22.5, 'temperature from DHT22' );
	is( $sensor->{current_humidity}, 65,   'humidity from DHT22' );
};

# The has_humidity key must reach the sensor through the same path
# the daemon uses: a device block in the configuration file, read by
# the device loader.
subtest '[MQTT-Sensors §4] has_humidity through the configuration' => sub {
	require File::Temp;
	require Fugu::Config;
	require App::OpenHAP::Devices;

	my ( $fh, $file ) = File::Temp::tempfile( UNLINK => 1 );
	print {$fh} <<'CONF';
device tasmota sensor s1 {
    name = "Humid Sensor"
    topic = tas_humid
    has_humidity = 1
}
CONF
	close $fh;

	my $config = Fugu::Config->new( file => $file );
	ok( $config->load, 'the configuration parses' )
	    or diag( $config->error );

	my $loader = App::OpenHAP::Devices->new;
	my ($record) = App::OpenHAP::Devices->devices($config);
	my $accessory =
	    $loader->_create_device( $record,
		App::OpenHAP::TestMock::MQTT->new, 0 );

	ok( $accessory, 'the sensor built from the device block' );
	ok( $accessory->get_service('HumiditySensor'),
		'has_humidity 1 builds a HumiditySensor service' );

	my $char = $accessory->get_service('HumiditySensor')
	    ->get_characteristic_by_type('CurrentRelativeHumidity');
	ok( $char, 'with the CurrentRelativeHumidity characteristic' );
};

done_testing();
