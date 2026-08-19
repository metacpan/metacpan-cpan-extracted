#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Conformance tests for spec/HAP-Services.md
#
# The tests are data-driven over the services that OpenHAP
# implements. The tests cite catalog rows as [HAP-Services §4/<Name>]
# and UUID table entries as §6 rows.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../lib";
use lib "$RealBin/../lib";
use Fugu::TestLog;

use_ok('Protocol::HAP::Service');
use_ok('Protocol::HAP::Characteristic');
use_ok('Protocol::HAP::Bridge');
use_ok('App::OpenHAP::TestMock::MQTT');
use_ok('App::OpenHAP::Tasmota::Heater');
use_ok('App::OpenHAP::Tasmota::Sensor');
use_ok('App::OpenHAP::Tasmota::Thermostat');
use_ok('App::OpenHAP::Tasmota::Lightbulb');

# [HAP-Services §6] UUID table rows for every service that OpenHAP
# defines
my %uuid_table = (
	AccessoryInformation => '3E',
	ProtocolInformation  => 'A2',
	Thermostat           => '4A',
	Switch               => '49',
	TemperatureSensor    => '8A',
	HumiditySensor       => '82',
	Outlet               => '47',
	Lightbulb            => '43',
);

subtest '[HAP-Services §6] service UUID table' => sub {
	for my $name ( sort keys %uuid_table ) {
		my $short = $uuid_table{$name};
		my $full  = sprintf '%08s-0000-1000-8000-0026BB765291',
		    '0' x ( 8 - length $short ) . $short;
		is( $Protocol::HAP::Service::SERVICE_TYPES{$name},
			$full, "[HAP-Services §6/$name] UUID is $full" );
	}
};

subtest '[HAP-Services §2] UUID short form in JSON' => sub {
	my $service = Protocol::HAP::Service->new( type => 'Lightbulb', iid => 10 );
	is( $service->to_json->{type}, '43',
		'Apple service UUID shortened to hex prefix' );

	my $custom = Protocol::HAP::Service->new(
		type => '12345678-1234-1234-1234-123456789012',
		iid  => 11,
	);
	is( $custom->to_json->{type},
		'12345678-1234-1234-1234-123456789012',
		'custom UUID preserved in full' );
};

# Collect the short types of the characteristics present on a service
sub service_char_types ($service)
{
	my %types;
	for my $char ( $service->get_characteristics ) {
		$types{ $char->to_json->{type} } = 1;
	}
	return \%types;
}

sub find_service ( $accessory, $short_type )
{
	for my $service ( $accessory->get_services ) {
		return $service
		    if $service->to_json->{type} eq $short_type;
	}
	return;
}

subtest '[HAP-Services §3] AccessoryInformation on every accessory' =>
    sub {
	my $mqtt        = App::OpenHAP::TestMock::MQTT->new;
	my @accessories = (
		Protocol::HAP::Bridge->new( name => 'Bridge' ),
		App::OpenHAP::Tasmota::Heater->new(
			aid         => 2,
			name        => 'Heater',
			mqtt_topic  => 'h',
			mqtt_client => $mqtt,
		),
	);

	for my $accessory (@accessories) {
		my $info = find_service( $accessory, '3E' );
		ok( $info, "$accessory->{name} has AccessoryInformation" );
		is( ( $accessory->get_services )[0], $info,
			'AccessoryInformation is the first service' );

		my $types = service_char_types($info);
		for my $required (
			[ Identify         => '14' ],
			[ Manufacturer     => '20' ],
			[ Model            => '21' ],
			[ Name             => '23' ],
			[ SerialNumber     => '30' ],
			[ FirmwareRevision => '52' ],
		    )
		{
			my ( $name, $short ) = @$required;
			ok( $types->{$short},
				"required characteristic $name ($short)" );
		}
	}
};

subtest '[HAP-Services §3] ProtocolInformation on the bridge only' => sub {
	my $bridge = Protocol::HAP::Bridge->new( name => 'Bridge' );
	my $protocol = find_service( $bridge, 'A2' );
	ok( $protocol, 'bridge carries ProtocolInformation' );

	my $types = service_char_types($protocol);
	ok( $types->{'37'}, 'required characteristic Version (37)' );

	my $version =
	    $protocol->get_characteristic_by_type('Version');
	is( $version->get_value, '1.1.0', 'Version reports HAP 1.1.0' );

	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $heater = App::OpenHAP::Tasmota::Heater->new(
		aid         => 2,
		name        => 'Heater',
		mqtt_topic  => 'h',
		mqtt_client => $mqtt,
	);
	ok( !find_service( $heater, 'A2' ),
		'bridged accessories do not carry ProtocolInformation' );
};

subtest '[HAP-Services §4] required characteristics per service' => sub {
	my $mqtt = App::OpenHAP::TestMock::MQTT->new;

	# [HAP-Services §4/Switch] required: On
	my $heater = App::OpenHAP::Tasmota::Heater->new(
		aid         => 2,
		name        => 'Heater',
		mqtt_topic  => 'h',
		mqtt_client => $mqtt,
	);
	my $switch = find_service( $heater, '49' );
	ok( $switch, 'Heater exposes a Switch service' );
	ok( service_char_types($switch)->{'25'},
		'[HAP-Services §4/Switch] required characteristic On' );

	# [HAP-Services §4/TemperatureSensor] required: CurrentTemperature
	my $sensor = App::OpenHAP::Tasmota::Sensor->new(
		aid         => 3,
		name        => 'Sensor',
		mqtt_topic  => 's',
		mqtt_client => $mqtt,
	);
	my $temp = find_service( $sensor, '8A' );
	ok( $temp, 'Sensor exposes a TemperatureSensor service' );
	ok( service_char_types($temp)->{'11'},
		'[HAP-Services §4/TemperatureSensor] CurrentTemperature' );

	# [HAP-Services §4/HumiditySensor] required: CurrentRelativeHumidity
	my $humidity_sensor = App::OpenHAP::Tasmota::Sensor->new(
		aid          => 4,
		name         => 'Humidity',
		mqtt_topic   => 'hs',
		mqtt_client  => $mqtt,
		has_humidity => 1,
	);
	my $humidity = find_service( $humidity_sensor, '82' );
	ok( $humidity, 'humidity Sensor exposes a HumiditySensor service' );
	ok( service_char_types($humidity)->{'10'},
		'[HAP-Services §4/HumiditySensor] CurrentRelativeHumidity' );

	# [HAP-Services §4/Thermostat] five required characteristics
	my $thermostat_dev = App::OpenHAP::Tasmota::Thermostat->new(
		aid         => 5,
		name        => 'Thermostat',
		mqtt_topic  => 't',
		mqtt_client => $mqtt,
	);
	my $thermostat = find_service( $thermostat_dev, '4A' );
	ok( $thermostat, 'Thermostat exposes a Thermostat service' );
	my $types = service_char_types($thermostat);
	for my $required (
		[ CurrentHeatingCoolingState => 'F' ],
		[ TargetHeatingCoolingState  => '33' ],
		[ CurrentTemperature         => '11' ],
		[ TargetTemperature          => '35' ],
		[ TemperatureDisplayUnits    => '36' ],
	    )
	{
		my ( $name, $short ) = @$required;
		ok( $types->{$short},
			"[HAP-Services §4/Thermostat] required $name" );
	}

	# [HAP-Services §4/LightBulb] required: On
	my $light_dev = App::OpenHAP::Tasmota::Lightbulb->new(
		aid          => 6,
		name         => 'Light',
		mqtt_topic   => 'l',
		mqtt_client  => $mqtt,
		capabilities => App::OpenHAP::Tasmota::Lightbulb::CAP_DIMMER(),
	);
	my $light = find_service( $light_dev, '43' );
	ok( $light, 'Lightbulb exposes a LightBulb service' );
	ok( service_char_types($light)->{'25'},
		'[HAP-Services §4/LightBulb] required characteristic On' );
	ok( service_char_types($light)->{'8'},
		'[HAP-Services §4/LightBulb] optional Brightness present '
		    . 'for dimmer' );
};

subtest '[HAP-Services §1][HAP-Services §7] service JSON structure' =>
    sub {
	my $service = Protocol::HAP::Service->new(
		type    => 'Switch',
		iid     => 10,
		hidden  => 1,
		primary => 1,
	);
	$service->add_characteristic(
		Protocol::HAP::Characteristic->new(
			type   => 'On',
			iid    => 11,
			format => 'bool',
			perms  => [ 'pr', 'pw' ],
			value  => 0,
		) );

	my $json = $service->to_json;
	is( $json->{iid},  10,   'service has instance ID' );
	is( $json->{type}, '49', 'service has type UUID' );
	is( ref $json->{characteristics},
		'ARRAY', 'service carries characteristic objects' );
	is( scalar @{ $json->{characteristics} },
		1, 'characteristics array populated' );
	is( ${ $json->{primary} }, 1, 'primary flag encoded' );
	is( ${ $json->{hidden} },  1, 'hidden flag encoded' );
};

subtest '[HAP-Services §5] primary service marking' => sub {
	my $service = Protocol::HAP::Service->new(
		type    => 'Switch',
		iid     => 10,
		primary => 1,
	);
	my $json = $service->to_json;
	is( ${ $json->{primary} }, 1, 'primary service marked in JSON' );

	my $plain = Protocol::HAP::Service->new( type => 'Switch', iid => 11 );
	ok( !exists $plain->to_json->{primary},
		'non-primary service omits the flag' );
};

done_testing();
