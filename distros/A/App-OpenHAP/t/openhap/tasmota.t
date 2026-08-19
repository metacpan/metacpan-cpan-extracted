#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Unit tests for the Tasmota device modules: constructors, initial
# state, and helper math. The spec-cited tests in t/conformance/
# cover the protocol behavior (topics, payloads, message handling).

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../lib";
use Fugu::Log;
use Fugu::TestLog;

use_ok('App::OpenHAP::TestMock::MQTT');
use_ok('App::OpenHAP::Tasmota::Device');
use_ok('App::OpenHAP::Tasmota::Heater');
use_ok('App::OpenHAP::Tasmota::Sensor');
use_ok('App::OpenHAP::Tasmota::Thermostat');
use_ok('App::OpenHAP::Tasmota::Lightbulb');

use constant AVAILABILITY_UNKNOWN => 0;
use constant AVAILABILITY_ONLINE  => 1;
use constant AVAILABILITY_OFFLINE => 2;

my $CAP_DIMMER = App::OpenHAP::Tasmota::Lightbulb::CAP_DIMMER();
my $CAP_COLOR  = App::OpenHAP::Tasmota::Lightbulb::CAP_COLOR();
my $CAP_CT     = App::OpenHAP::Tasmota::Lightbulb::CAP_CT();

# Test Base class construction and availability accessors
{
	my $mqtt = App::OpenHAP::TestMock::MQTT->new;
	my $base = App::OpenHAP::Tasmota::Device->new(
		aid         => 2,
		name        => 'Test Base',
		mqtt_topic  => 'test_device',
		mqtt_client => $mqtt,
	);

	ok( defined $base, 'Base device created' );
	is( $base->{mqtt_topic}, 'test_device', 'MQTT topic set' );
	is( $base->{availability},
		AVAILABILITY_UNKNOWN,
		'Initial availability is unknown' );
	ok( !$base->is_online, 'is_online false while unknown' );

	$base->{availability} = AVAILABILITY_ONLINE;
	ok( $base->is_online, 'is_online true when online' );

	$base->{availability} = AVAILABILITY_OFFLINE;
	ok( !$base->is_online, 'is_online false when offline' );
}

# Test temperature conversion helper
{
	my $mqtt = App::OpenHAP::TestMock::MQTT->new;
	my $base = App::OpenHAP::Tasmota::Device->new(
		aid         => 2,
		name        => 'Test Base',
		mqtt_topic  => 'test_device',
		mqtt_client => $mqtt,
	);

	$base->{temp_unit} = 'C';
	is( $base->convert_temperature(25), 25, 'Celsius passthrough' );

	$base->{temp_unit} = 'F';
	my $celsius = $base->convert_temperature(77);    # 77F = 25C
	ok( abs( $celsius - 25 ) < 0.1, 'Fahrenheit to Celsius conversion' );

	$celsius = $base->convert_temperature(32);
	ok( abs($celsius) < 0.1, '32F = 0C' );
}

# Test Heater construction and initial state
{
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $heater = App::OpenHAP::Tasmota::Heater->new(
		aid         => 2,
		name        => 'Test Heater',
		mqtt_topic  => 'heater',
		mqtt_client => $mqtt,
	);

	ok( defined $heater, 'Heater created' );
	is( $heater->{power_state}, 0, 'Initial power state is off' );
	ok( $heater->can($_), "Heater has $_ method" )
	    for qw(set_power subscribe_mqtt);
}

# Test Sensor construction and initial state
{
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $sensor = App::OpenHAP::Tasmota::Sensor->new(
		aid         => 2,
		name        => 'Test Sensor',
		mqtt_topic  => 'sensor',
		mqtt_client => $mqtt,
	);

	ok( defined $sensor, 'Sensor created' );
	is( $sensor->{current_temp}, 20.0, 'Initial temperature' );
}

# Test Thermostat construction and initial state
{
	my $mqtt       = App::OpenHAP::TestMock::MQTT->new;
	my $thermostat = App::OpenHAP::Tasmota::Thermostat->new(
		aid         => 2,
		name        => 'Test Thermostat',
		mqtt_topic  => 'thermostat',
		mqtt_client => $mqtt,
	);

	ok( defined $thermostat, 'Thermostat created' );
	is( $thermostat->{current_temp},  20.0, 'Initial current temp' );
	is( $thermostat->{target_temp},   20.0, 'Initial target temp' );
	is( $thermostat->{heating_state}, 0, 'Initial heating state off' );
}

# Test Lightbulb construction and initial state
{
	my $mqtt      = App::OpenHAP::TestMock::MQTT->new;
	my $lightbulb = App::OpenHAP::Tasmota::Lightbulb->new(
		aid          => 2,
		name         => 'Test Light',
		mqtt_topic   => 'light',
		mqtt_client  => $mqtt,
		capabilities => $CAP_DIMMER | $CAP_COLOR | $CAP_CT,
	);

	ok( defined $lightbulb, 'Lightbulb created' );
	is( $lightbulb->{power_state}, 0,   'Initial power off' );
	is( $lightbulb->{brightness},  100, 'Initial brightness 100' );
}

# Test RGB to HSB conversion helper math
{
	my $mqtt      = App::OpenHAP::TestMock::MQTT->new;
	my $lightbulb = App::OpenHAP::Tasmota::Lightbulb->new(
		aid          => 2,
		name         => 'RGB Test',
		mqtt_topic   => 'light',
		mqtt_client  => $mqtt,
		capabilities => $CAP_COLOR,
	);

	my ( $h, $s, $b ) = $lightbulb->_rgb_to_hsb( 255, 0, 0 );
	is( $h, 0,   'RGB red: hue=0' );
	is( $s, 100, 'RGB red: saturation=100' );
	is( $b, 100, 'RGB red: brightness=100' );

	( $h, $s, $b ) = $lightbulb->_rgb_to_hsb( 0, 255, 0 );
	is( $h, 120, 'RGB green: hue=120' );

	( $h, $s, $b ) = $lightbulb->_rgb_to_hsb( 0, 0, 255 );
	is( $h, 240, 'RGB blue: hue=240' );

	( $h, $s, $b ) = $lightbulb->_rgb_to_hsb( 255, 255, 255 );
	is( $s, 0,   'RGB white: saturation=0' );
	is( $b, 100, 'RGB white: brightness=100' );

	( $h, $s, $b ) = $lightbulb->_rgb_to_hsb( 128, 128, 128 );
	is( $s, 0,  'RGB gray: saturation=0' );
	is( $b, 50, 'RGB gray: brightness=50' );

	# A red-dominant mixed color. The hue arithmetic is
	# floating-point: an integer modulus would truncate the red
	# sector to hue 0.
	( $h, $s, $b ) = $lightbulb->_rgb_to_hsb( 255, 128, 0 );
	is( $h, 30, 'RGB orange: hue=30' );
}

# A characteristic that a driver creates carries the injected logger.
# Without this, the write and subscription debug lines of the daemon
# would disappear into the null logger.
subtest 'a driver passes its logger to its characteristics' => sub {
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $logger = Fugu::Log->new( mode => Fugu::Log::MODE_QUIET );
	my $heater = App::OpenHAP::Tasmota::Heater->new(
		aid         => 2,
		name        => 'Logger Test',
		mqtt_topic  => 'heater',
		mqtt_client => $mqtt,
		logger      => $logger,
	);

	is( $heater->{logger}, $logger, 'the accessory carries the logger' );

	my ($switch) = grep { $_->get_characteristic_by_type('On') }
	    $heater->get_services;
	ok( defined $switch, 'the heater has its switch service' );
	is( $switch->{logger}, $logger, 'the service carries the logger' );

	my $on = $switch->get_characteristic_by_type('On');
	is( $on->{logger}, $logger,
		'the driver-created characteristic carries the logger' );

	# The accessory-information characteristics come from the model
	# itself, and they carry the same logger
	my $info = $heater->get_service('AccessoryInformation');
	my $name = $info->get_characteristic_by_type('Name');
	is( $name->{logger}, $logger,
		'the model-created characteristic carries the logger' );
};

done_testing();
