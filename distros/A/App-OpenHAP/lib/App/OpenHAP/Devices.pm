# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2025 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package App::OpenHAP::Devices;
our $VERSION = '0.1.0';

use Fugu::Log;

# App::OpenHAP::Devices - turn the device blocks of the configuration
# into accessories on the bridge.
#
# One table describes every device type. Each entry says what the type
# is called in a log line, which class builds it, and what that class
# needs beyond the fields every device has. Adding a type is one
# entry, and no second place to keep true.
#
# The class of the entry does the work of building. The loader only
# decides which one, validates the fields the configuration must
# carry, and subscribes the result to MQTT.
#
# A device class loads when the configuration asks for it, not at
# compile time. The classes drag JSON::XS and the whole accessory
# model behind them, and a tool that only reads the device blocks
# needs none of it. The daemon builds its devices before it pledges,
# thus the late load costs it nothing.
# The lightbulb family differs only in its capability mask, so those
# entries carry a caps field instead of one closure each. The mask
# values are the CAP_* constants of the class, spelled as numbers
# here because the class loads only when the configuration asks for
# it: dimmer 1, color 2, ct 4.
my %DEVICE = (
	'tasmota/thermostat' => {
		name  => 'thermostat',
		class => 'App::OpenHAP::Tasmota::Thermostat',
		args  => sub ($device) {
			return (
				sensor_type  => $device->{sensor_type},
				sensor_index => $device->{sensor_index},
			);
		},
	},
	'tasmota/heater' => {
		name  => 'switch',
		class => 'App::OpenHAP::Tasmota::Heater',
	},
	'tasmota/sensor' => {
		name  => 'sensor',
		class => 'App::OpenHAP::Tasmota::Sensor',
		args  => sub ($device) {
			return (
				sensor_type  => $device->{sensor_type},
				sensor_index => $device->{sensor_index},
				has_humidity => $device->{has_humidity} // 0,
			);
		},
	},
	'tasmota/lightbulb' => {
		name  => 'lightbulb',
		class => 'App::OpenHAP::Tasmota::Lightbulb',
		caps  => 1,
	},
	'tasmota/rgblight' => {
		name  => 'rgb light',
		class => 'App::OpenHAP::Tasmota::Lightbulb',
		caps  => 1 | 2,
	},
	'tasmota/ctlight' => {
		name  => 'ct light',
		class => 'App::OpenHAP::Tasmota::Lightbulb',
		caps  => 1 | 4,
	},
);

# Two names for existing entries
$DEVICE{'tasmota/switch'} = $DEVICE{'tasmota/heater'};
$DEVICE{'tasmota/dimmer'} = $DEVICE{'tasmota/lightbulb'};

# $class->new():
#	Create a new device loader instance.
sub new ($class)
{
	bless {
		next_aid => 2,    # AID 1 is the bridge
		devices  => [],
	}, $class;
}

# $self->load_devices($config, $hap, $mqtt):
#	Load the devices from the configuration. Add them to the
#	HAP bridge. The method returns the number of loaded devices.
sub load_devices ( $self, $config, $hap, $mqtt )
{
	my @devices = $self->devices($config);
	Fugu::Log->default->debug( 'Loading %d device(s) from configuration',
		scalar @devices );

	my $loaded_count   = 0;
	my $mqtt_connected = $mqtt->is_connected();

	for my $device (@devices) {
		my $accessory =
		    $self->_create_device( $device, $mqtt, $mqtt_connected );
		next unless defined $accessory;

		$hap->add_accessory($accessory);
		push @{ $self->{devices} }, $accessory;
		$loaded_count++;

		Fugu::Log->default->info(
			'Added %s: %s (AID=%d)',
			$self->_device_type_name($device),
			$device->{name}, $accessory->{aid} );
	}

	Fugu::Log->default->info( 'Loaded %d device(s), %d skipped',
		$loaded_count, scalar(@devices) - $loaded_count );

	return $loaded_count;
}

# $self->get_devices():
#	Return the list of loaded device accessory objects.
sub get_devices ($self)
{
	return @{ $self->{devices} };
}

# $self->_create_device($device, $mqtt, $mqtt_connected):
#	Create an accessory from the device configuration.
#	The method returns the accessory object, or undef on error.
sub _create_device ( $self, $device, $mqtt, $mqtt_connected )
{
	my $dev_type    = $device->{type}    // 'unknown';
	my $dev_subtype = $device->{subtype} // 'unknown';

	Fugu::Log->default->debug(
		'Processing device: type=%s, subtype=%s, name=%s',
		$dev_type, $dev_subtype, $device->{name} // '<unnamed>' );

	# Validate the device type. The one lookup serves the check,
	# the build, and the log name.
	my $entry = $DEVICE{"$dev_type/$dev_subtype"};
	unless ($entry) {
		Fugu::Log->default->debug(
			'Skipping unsupported device type: %s/%s',
			$dev_type, $dev_subtype );
		return;
	}

	# Validate the required fields
	return unless $self->_validate_device($device);

	# Create the device and catch errors
	my $accessory;
	eval {
		$accessory =
		    $self->_instantiate_device( $device, $mqtt, $entry );
	};
	if ($@) {
		Fugu::Log->default->error( 'Failed to create %s "%s": %s',
			$entry->{name}, $device->{name}, $@ );
		return;
	}

	# Subscribe to MQTT if the client is connected
	if ($mqtt_connected) {
		$self->_subscribe_mqtt( $accessory, $device );
	}
	else {
		Fugu::Log->default->debug(
			'MQTT not connected, deferring subscription for "%s"',
			$device->{name} );
	}

	return $accessory;
}

# $class->devices($config):
#	Return the device blocks of a Fugu::Config as records with
#	type, subtype, id and the settings of the block.
sub devices ( $, $config )
{
	my @devices;
	for my $block ( $config->blocks('device') ) {
		my ( $type, $subtype, $id ) = @{ $block->{args} };
		push @devices,
		    {
			%{ $block->{settings} },
			type    => $type,
			subtype => $subtype,
			id      => $id,
		    };
	}

	return @devices;
}

# $self->_validate_device($device):
#	Validate the required device fields. The method returns true
#	if the device is valid.
sub _validate_device ( $self, $device )
{
	unless ( defined $device->{name} && $device->{name} ne '' ) {
		Fugu::Log->default->error(
			'Device missing required field: name');
		return;
	}

	unless ( defined $device->{topic} && $device->{topic} ne '' ) {
		Fugu::Log->default->error(
			'Device "%s" missing required field: topic',
			$device->{name} );
		return;
	}

	unless ( defined $device->{id} && $device->{id} ne '' ) {
		Fugu::Log->default->warning(
			'Device "%s" missing id field, using topic as serial',
			$device->{name} );
		$device->{id} = $device->{topic};
	}

	return 1;
}

# $self->_instantiate_device($device, $mqtt, $entry):
#	Create the device object for a %DEVICE entry.
sub _instantiate_device ( $self, $device, $mqtt, $entry )
{
	# The class loads here, not at compile time. require needs the
	# path form of the name.
	my $module = $entry->{class} =~ s{::}{/}gr;
	require "$module.pm";

	my %args = (
		aid         => $self->{next_aid}++,
		name        => $device->{name},
		mqtt_topic  => $device->{topic},
		mqtt_client => $mqtt,
		serial      => $device->{id},
		relay_index => $device->{relay_index} // 0,

		# The model logs through the injected logger. The device
		# passes it on to every service and characteristic it
		# builds, so the write and subscription debug lines keep
		# reaching the daemon log.
		logger => Fugu::Log->default,
	);
	$args{capabilities} = $entry->{caps}         if defined $entry->{caps};
	%args = ( %args, $entry->{args}->($device) ) if $entry->{args};

	return $entry->{class}->new(%args);
}

# $self->_subscribe_mqtt($accessory, $device):
#	Subscribe the device to its MQTT topics.
sub _subscribe_mqtt ( $self, $accessory, $device )
{
	eval { $accessory->subscribe_mqtt(); };
	if ($@) {
		Fugu::Log->default->error(
			'Failed to subscribe MQTT for "%s": %s',
			$device->{name}, $@ );
	}
	else {
		Fugu::Log->default->info( 'Subscribed to MQTT topic: %s',
			$device->{topic} );
	}
}

# $self->_device_type_name($device):
#	Return the human-readable device type name. Every caller has
#	already passed the %DEVICE lookup, so the entry is there.
sub _device_type_name ( $self, $device )
{
	return $DEVICE{"$device->{type}/$device->{subtype}"}{name};
}

1;
