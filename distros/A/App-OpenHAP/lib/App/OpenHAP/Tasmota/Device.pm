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

package App::OpenHAP::Tasmota::Device;
our $VERSION = '0.1.0';

use Fugu::Log;
require Protocol::HAP::Accessory;
our @ISA = qw(Protocol::HAP::Accessory);

use JSON::XS;

use constant {

	# Device availability states
	AVAILABILITY_UNKNOWN => 0,
	AVAILABILITY_ONLINE  => 1,
	AVAILABILITY_OFFLINE => 2,
};

# The sensor types the walk below knows (H5). Thermostat and Sensor
# share this one list.
use constant SENSOR_TYPES =>
    qw(DS18B20 DHT11 DHT22 AM2301 BME280 BMP280 SHT3X SI7021);

sub new ( $class, %args )
{
	my $self = $class->SUPER::new(%args);

	$self->{mqtt_topic}   = $args{mqtt_topic};
	$self->{mqtt_client}  = $args{mqtt_client};
	$self->{relay_index}  = $args{relay_index} // 0;    # 0 = no index
	$self->{availability} = AVAILABILITY_UNKNOWN;
	$self->{temp_unit}    = 'C';                        # Default to Celsius

	return $self;
}

# $self->subscribe_mqtt():
#	Subscribe to all standard Tasmota topics.
#	Subclasses must call SUPER::subscribe_mqtt() first.
sub subscribe_mqtt ($self)
{
	return unless $self->{mqtt_client}->is_connected();

	Fugu::Log->default->debug(
		'Tasmota %s subscribing to MQTT topics for %s',
		ref($self), $self->{name} );

	# C1: Subscribe to LWT for device availability
	$self->{mqtt_client}->subscribe(
		$self->_build_topic( 'tele', 'LWT' ),
		sub ( $recv_topic, $payload ) {
			$self->_handle_lwt($payload);
		} );

	# C2: Subscribe to tele/STATE for periodic state updates
	$self->{mqtt_client}->subscribe(
		$self->_build_topic( 'tele', 'STATE' ),
		sub ( $recv_topic, $payload ) {
			my $data = $self->_decode( $payload, 'STATE' )
			    or return;
			$self->_process_state_data($data);
		} );

	# C3: Subscribe to stat/RESULT for command responses
	$self->{mqtt_client}->subscribe(
		$self->_build_topic( 'stat', 'RESULT' ),
		sub ( $recv_topic, $payload ) {
			my $data = $self->_decode( $payload, 'RESULT' )
			    or return;
			$self->_process_result_data($data);
		} );

	# Subscribe to tele/SENSOR for sensor data
	$self->{mqtt_client}->subscribe(
		$self->_build_topic( 'tele', 'SENSOR' ),
		sub ( $recv_topic, $payload ) {
			my $data = $self->_decode( $payload, 'SENSOR' )
			    or return;

			# Extract the temperature unit if it is present (H4)
			if ( exists $data->{TempUnit} ) {
				$self->{temp_unit} = $data->{TempUnit};
			}

			$self->_process_sensor_data($data);
		} );

	# C1/H1: Subscribe to STATUS11 for full state reconciliation
	$self->{mqtt_client}->subscribe(
		$self->_build_topic( 'stat', 'STATUS11' ),
		sub ( $recv_topic, $payload ) {
			$self->_handle_status11($payload);
		} );
}

# $self->_subscribe_status_sns($status):
#	Subscribe to one STATUS8/STATUS10 sensor response (H5). The
#	device sends STATUS8 after an active query, and the spec
#	recommends STATUS10. Both wrap the sensor data in StatusSNS.
sub _subscribe_status_sns ( $self, $status )
{
	$self->{mqtt_client}->subscribe(
		$self->_build_topic( 'stat', $status ),
		sub ( $recv_topic, $payload ) {
			$self->_handle_status_sns( $payload, $status );
		} );
}

# $self->_handle_status_sns($payload, $label):
#	Process one STATUS8/STATUS10 response: unwrap StatusSNS, track
#	the temperature unit (H4), and hand the data to the sensor
#	extractor of the subclass.
sub _handle_status_sns ( $self, $payload, $label )
{
	my $data = $self->_decode( $payload, $label ) or return;
	my $sns  = $data->{StatusSNS}                 or return;

	if ( exists $sns->{TempUnit} ) {
		$self->{temp_unit} = $sns->{TempUnit};
	}

	$self->_process_sensor_data($sns);
}

# $self->query_initial_state():
#	Query the device for the current state after a connect or
#	an LWT Online. The method uses Status 11 for full state
#	reconciliation (C1/H1).
sub query_initial_state ($self)
{
	return unless $self->{mqtt_client}->is_connected();

	Fugu::Log->default->debug( 'Querying initial state for %s',
		$self->{name} );

	# Request the full status (Status 11). Spec §6.1 recommends
	# this query.
	$self->query_status(11);
}

# $self->is_online():
#	Check if the device is online.
sub is_online ($self)
{
	return $self->{availability} == AVAILABILITY_ONLINE;
}

# $self->_handle_lwt($payload):
#	Process the LWT (Last Will and Testament) message (C1).
sub _handle_lwt ( $self, $payload )
{
	if ( $payload eq 'Online' ) {
		$self->{availability} = AVAILABILITY_ONLINE;
		Fugu::Log->default->info( 'Device %s is online',
			$self->{name} );

		# Query the initial state when the device comes online (H3)
		$self->query_initial_state();
	}
	elsif ( $payload eq 'Offline' ) {
		$self->{availability} = AVAILABILITY_OFFLINE;
		Fugu::Log->default->warning( 'Device %s is offline',
			$self->{name} );
	}
	else {
		Fugu::Log->default->debug( 'Unknown LWT payload for %s: %s',
			$self->{name}, $payload );
	}
}

# $self->_decode($payload, $label):
#	Decode one JSON payload from the device. The method returns
#	the decoded data, or undef with the parse error in the log.
#	Everything from the broker is external input, so a payload
#	that does not parse is logged and dropped, never fatal.
sub _decode ( $self, $payload, $label )
{
	my $data = eval { decode_json($payload) };
	if ($@) {
		Fugu::Log->default->error( 'Error parsing %s for %s: %s',
			$label, $self->{name}, $@ );
		return;
	}

	return $data;
}

# $self->_handle_status11($payload):
#	Process the STATUS11 response for state reconciliation (C1/H1).
sub _handle_status11 ( $self, $payload )
{
	my $data = $self->_decode( $payload, 'STATUS11' ) or return;

	# STATUS11 wraps the data in StatusSTS. The format is the
	# same as the periodic STATE.
	if ( exists $data->{StatusSTS} ) {
		Fugu::Log->default->debug( 'STATUS11 received for %s',
			$self->{name} );
		$self->_process_state_data( $data->{StatusSTS} );
	}
}

# $self->_process_state_data($data):
#	Process the parsed STATE data. Subclasses can override
#	this method.
sub _process_state_data ( $self, $data )
{
	# The default implementation checks for the POWER state
	$self->_extract_power_state($data);
}

# $self->_process_result_data($data):
#	Process the parsed RESULT data. Subclasses can override
#	this method.
sub _process_result_data ( $self, $data )
{
	# The default implementation checks for the POWER state
	$self->_extract_power_state($data);
}

# $self->_process_sensor_data($data):
#	Process the parsed SENSOR data. Subclasses can override
#	this method.
sub _process_sensor_data ( $self, $data )
{
	# The default does nothing. Subclasses can override this
	# method.
}

# $self->_extract_power_state($data):
#	Extract the power state from the JSON data. The method
#	supports multi-relay devices (H1).
sub _extract_power_state ( $self, $data )
{
	my $power_key = $self->_get_power_key();

	if ( exists $data->{$power_key} ) {
		my $power = $data->{$power_key};
		$self->_on_power_update( $power eq 'ON' ? 1 : 0 );
	}
}

# $self->_get_power_key():
#	Get the power key name for this device (H1 multi-relay
#	support).
sub _get_power_key ($self)
{
	if ( $self->{relay_index} && $self->{relay_index} > 0 ) {
		return 'POWER' . $self->{relay_index};
	}

	return 'POWER';
}

# $self->_get_power_topic():
#	Get the power topic for commands (H1 multi-relay support).
sub _get_power_topic ($self)
{
	if ( $self->{relay_index} && $self->{relay_index} > 0 ) {
		return $self->_build_topic( 'cmnd',
			'Power' . $self->{relay_index} );
	}

	return $self->_build_topic( 'cmnd', 'Power' );
}

# $self->_build_topic($prefix, $command):
#	Build a topic with the default Tasmota FullTopic pattern,
#	%prefix%/%topic%/ (H2).
#	$prefix: 'cmnd', 'stat', or 'tele'
#	$command: The command/topic suffix
sub _build_topic ( $self, $prefix, $command )
{
	return "$prefix/$self->{mqtt_topic}/$command";
}

# $self->_subscribe_plain_power($field, $iid):
#	Subscribe to the plain-text POWER response (M2, SetOption4
#	support). The payload updates $self->{$field} and notifies
#	the characteristic $iid on a change.
sub _subscribe_plain_power ( $self, $field, $iid )
{
	$self->{mqtt_client}->subscribe(
		$self->_build_topic( 'stat', $self->_get_power_key() ),
		sub ( $recv_topic, $payload ) {
			my $state = ( $payload eq 'ON' ) ? 1 : 0;
			return if $self->{$field} == $state;

			$self->{$field} = $state;
			Fugu::Log->default->debug( '%s power state: %s',
				$self->{name}, $payload );
			$self->notify_change($iid);
		} );
}

# $self->_on_power_update($state):
#	The base class calls this method when the power state
#	updates. Subclasses can override it.
sub _on_power_update ( $self, $state )
{
	# Default: no-op
}

# $self->convert_temperature($temp):
#	Convert the temperature to Celsius if necessary (H4).
sub convert_temperature ( $self, $temp )
{
	return $temp unless defined $temp;

	if ( $self->{temp_unit} eq 'F' ) {

		# Convert Fahrenheit to Celsius
		return ( $temp - 32 ) * 5 / 9;
	}

	return $temp;
}

# $self->_find_sensor_values($data):
#	Find the temperature and the humidity in the sensor data
#	(H5). The method supports multiple sensor types and indexed
#	sensors, and remembers the type it detected.
sub _find_sensor_values ( $self, $data )
{
	# If the configuration sets a sensor type, look for that sensor
	if ( defined $self->{sensor_type} ) {
		my $key = $self->{sensor_type};

		# Add the index for indexed sensors, for example DS18B20-1
		if ( defined $self->{sensor_index} ) {
			$key .= '-' . $self->{sensor_index};
		}

		return unless exists $data->{$key};
		return ( $data->{$key}{Temperature}, $data->{$key}{Humidity} );
	}

	# Auto-detect: try each known sensor type (H5)
	for my $type (SENSOR_TYPES) {
		if ( exists $data->{$type} ) {
			$self->{sensor_type} = $type;
			return (
				$data->{$type}{Temperature},
				$data->{$type}{Humidity} );
		}

		# Check for indexed sensors, for example DS18B20-1
		for my $i ( 1 .. 8 ) {
			my $indexed = "$type-$i";
			next unless exists $data->{$indexed};

			$self->{sensor_type}  = $type;
			$self->{sensor_index} = $i;
			return (
				$data->{$indexed}{Temperature},
				$data->{$indexed}{Humidity} );
		}
	}

	return;
}

# $self->set_power($state):
#	Set the power state (0=OFF, 1=ON).
sub set_power ( $self, $state )
{
	my $command = $state ? 'ON' : 'OFF';
	my $topic   = $self->_get_power_topic();

	Fugu::Log->default->debug( '%s power set to %s',
		$self->{name}, $command );
	$self->{mqtt_client}->publish( $topic, $command );
}

# $self->query_status($type):
#	Query the device status.
#	$type: 0 = all, 8 = sensors, 11 = full state, and other STATUS codes
sub query_status ( $self, $type = 11 )
{
	$self->{mqtt_client}
	    ->publish( $self->_build_topic( 'cmnd', 'Status' ), "$type" );
}

1;
