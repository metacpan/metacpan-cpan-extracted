#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Conformance tests for spec/HAP-Characteristics.md
#
# The tests are data-driven over the characteristics that OpenHAP
# implements. The tests cite catalog rows as
# [HAP-Characteristics §5/<Name>] and UUID table entries as §6 rows.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../lib";
use lib "$RealBin/../lib";
use Fugu::TestLog;

use_ok('Protocol::HAP::Characteristic');
use_ok('Protocol::HAP::Bridge');
use_ok('App::OpenHAP::TestMock::MQTT');
use_ok('App::OpenHAP::Tasmota::Heater');
use_ok('App::OpenHAP::Tasmota::Sensor');
use_ok('App::OpenHAP::Tasmota::Thermostat');
use_ok('App::OpenHAP::Tasmota::Lightbulb');

# [HAP-Characteristics §5] catalog rows for the characteristics that
# OpenHAP implements: short UUID, format, spec permissions, spec
# range, unit
my %catalog = (
	Identify => {
		short  => '14',
		format => 'bool',
		perms  => [qw(pw)],
	},
	Manufacturer     => { short => '20', format => 'string',
		perms => [qw(pr)] },
	Model            => { short => '21', format => 'string',
		perms => [qw(pr)] },
	Name             => { short => '23', format => 'string',
		perms => [qw(pr)] },
	SerialNumber     => { short => '30', format => 'string',
		perms => [qw(pr)] },
	FirmwareRevision => { short => '52', format => 'string',
		perms => [qw(pr)] },
	Version          => { short => '37', format => 'string',
		perms => [qw(pr)] },
	On => {
		short  => '25',
		format => 'bool',
		perms  => [qw(pr pw ev)],
	},
	Brightness => {
		short  => '8',
		format => 'int',
		perms  => [qw(pr pw ev)],
		range  => [ 0, 100 ],
		unit   => 'percentage',
	},
	Hue => {
		short  => '13',
		format => 'float',
		perms  => [qw(pr pw ev)],
		range  => [ 0, 360 ],
		unit   => 'arcdegrees',
	},
	Saturation => {
		short  => '2F',
		format => 'float',
		perms  => [qw(pr pw ev)],
		range  => [ 0, 100 ],
		unit   => 'percentage',
	},
	ColorTemperature => {
		short  => 'CE',
		format => 'uint32',
		perms  => [qw(pr pw ev)],
		range  => [ 140, 500 ],
	},
	CurrentTemperature => {
		short  => '11',
		format => 'float',
		perms  => [qw(pr ev)],
		range  => [ -273.1, 1000 ],
		unit   => 'celsius',
	},
	TargetTemperature => {
		short  => '35',
		format => 'float',
		perms  => [qw(pr pw ev)],
		range  => [ 10, 38 ],
		unit   => 'celsius',
	},
	TemperatureDisplayUnits => {
		short  => '36',
		format => 'uint8',
		perms  => [qw(pr pw ev)],
		range  => [ 0, 1 ],
	},
	CurrentHeatingCoolingState => {
		short  => 'F',
		format => 'uint8',
		perms  => [qw(pr ev)],
		range  => [ 0, 2 ],
	},
	TargetHeatingCoolingState => {
		short  => '33',
		format => 'uint8',
		perms  => [qw(pr pw ev)],
		range  => [ 0, 3 ],
	},
	CurrentRelativeHumidity => {
		short  => '10',
		format => 'float',
		perms  => [qw(pr ev)],
		range  => [ 0, 100 ],
		unit   => 'percentage',
	},
	OutletInUse => {
		short  => '26',
		format => 'bool',
		perms  => [qw(pr ev)],
	},
);

subtest '[HAP-Characteristics §6] characteristic UUID table' => sub {
	for my $name ( sort keys %Protocol::HAP::Characteristic::CHAR_TYPES ) {
		my $row = $catalog{$name};
		ok( $row, "catalog covers implemented type $name" ) or next;
		my $short = $row->{short};
		my $full  = sprintf '%08s-0000-1000-8000-0026BB765291',
		    '0' x ( 8 - length $short ) . $short;
		is( $Protocol::HAP::Characteristic::CHAR_TYPES{$name},
			$full,
			"[HAP-Characteristics §6/$name] UUID is $full" );
	}
};

# Every catalog row must draw its format from the §2 table and its
# permissions from the §3 table. The device subtest below then holds
# every characteristic instance to its catalog row, so the two spec
# vocabularies bound what the implementation can emit.
subtest '[HAP-Characteristics §2][HAP-Characteristics §3] catalog rows'
    => sub {
	my %spec_formats = map { $_ => 1 }
	    qw(bool uint8 uint16 uint32 uint64 int float string tlv8 data);
	my %spec_perms = map { $_ => 1 } qw(pr pw ev aa tw hd wr);

	for my $name ( sort keys %catalog ) {
		ok( $spec_formats{ $catalog{$name}{format} },
			"[HAP-Characteristics §2] $name format is a"
			    . ' spec format' );
		my @bad =
		    grep { !$spec_perms{$_} } @{ $catalog{$name}{perms} };
		is( "@bad", '',
			"[HAP-Characteristics §3] $name permissions are"
			    . ' spec permissions' );
	}
};

subtest '[HAP-Characteristics §1][HAP-Characteristics §7] JSON shape' =>
    sub {
	my $value = 75;
	my $char  = Protocol::HAP::Characteristic->new(
		type   => 'Brightness',
		iid    => 10,
		format => 'int',
		perms  => [ 'pr', 'pw', 'ev' ],
		unit   => 'percentage',
		value  => \$value,
		min    => 0,
		max    => 100,
		step   => 1,
	);

	my $json = $char->to_json;
	is( $json->{iid},      10,           'iid encoded' );
	is( $json->{type},     '8',          'short type encoded' );
	is( $json->{format},   'int',        'format encoded' );
	is( $json->{value},    75,           'value encoded' );
	is( $json->{minValue}, 0,            'minValue encoded' );
	is( $json->{maxValue}, 100,          'maxValue encoded' );
	is( $json->{minStep},  1,            'minStep encoded' );
	is( $json->{unit},     'percentage', 'unit encoded' );
	is_deeply( $json->{perms}, [ 'pr', 'pw', 'ev' ], 'perms encoded' );

	# [HAP-Characteristics §8] a write-only characteristic omits the
	# value
	my $write_only = Protocol::HAP::Characteristic->new(
		type   => 'Identify',
		iid    => 2,
		format => 'bool',
		perms  => ['pw'],
	);
	ok( !exists $write_only->to_json->{value},
		'[HAP-Characteristics §8] non-readable value omitted' );
};

# Instantiate every device type. Check each characteristic instance
# against its catalog row.
subtest '[HAP-Characteristics §5] device characteristics match rows' =>
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
		App::OpenHAP::Tasmota::Sensor->new(
			aid          => 3,
			name         => 'Sensor',
			mqtt_topic   => 's',
			mqtt_client  => $mqtt,
			has_humidity => 1,
		),
		App::OpenHAP::Tasmota::Thermostat->new(
			aid         => 4,
			name        => 'Thermostat',
			mqtt_topic  => 't',
			mqtt_client => $mqtt,
		),
		App::OpenHAP::Tasmota::Lightbulb->new(
			aid          => 5,
			name         => 'Light',
			mqtt_topic   => 'l',
			mqtt_client  => $mqtt,
			capabilities =>
			    App::OpenHAP::Tasmota::Lightbulb::CAP_DIMMER() |
			    App::OpenHAP::Tasmota::Lightbulb::CAP_COLOR() |
			    App::OpenHAP::Tasmota::Lightbulb::CAP_CT(),
		),
	);

	my %short_to_name =
	    map { $catalog{$_}{short} => $_ } keys %catalog;

	for my $accessory (@accessories) {
		for my $service ( $accessory->get_services ) {
			for my $char ( $service->get_characteristics ) {
				my $short = $char->to_json->{type};
				my $name  = $short_to_name{$short};
				ok( $name,
					"$accessory->{name}: type $short is "
					    . 'in the spec catalog' )
				    or next;
				check_row( $accessory->{name}, $name,
					$char );
			}
		}
	}
};

# check_row($where, $name, $char): assert one characteristic instance
# against its spec catalog row
sub check_row ( $where, $name, $char )
{
	my $row   = $catalog{$name};
	my $label = "[HAP-Characteristics §5/$name] $where";

	is( $char->{format}, $row->{format},
		"$label: format is $row->{format}" );

	my %allowed = map { $_ => 1 } @{ $row->{perms} };
	my @extra   = grep { !$allowed{$_} } @{ $char->{perms} };
	is( "@extra", '', "$label: permissions within spec set" );

	if ( $row->{range} ) {
		my ( $spec_min, $spec_max ) = @{ $row->{range} };
		if ( defined $char->{min} ) {
			ok( $char->{min} >= $spec_min,
				"$label: min within spec range" );
		}
		if ( defined $char->{max} ) {
			ok( $char->{max} <= $spec_max,
				"$label: max within spec range" );
		}
	}

	if ( $row->{unit} && defined $char->{unit} ) {
		is( $char->{unit}, $row->{unit},
			"$label: unit is $row->{unit}" );
	}

	# [HAP-Characteristics §4] each unit in use must be a spec unit
	if ( defined $char->{unit} ) {
		my %spec_units =
		    map { $_ => 1 } qw(celsius percentage arcdegrees
		    lux seconds);
		ok( $spec_units{ $char->{unit} },
			"$label: unit is a defined HAP unit" );
	}
}

done_testing();
