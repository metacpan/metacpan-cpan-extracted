use v5.36;

package App::OpenHAP::Tasmota::Thermostat;
our $VERSION = '0.1.0';

use Fugu::Log;
require App::OpenHAP::Tasmota::Device;
our @ISA = qw(App::OpenHAP::Tasmota::Device);
use Protocol::HAP::Service;
use Protocol::HAP::Characteristic;

sub new ( $class, %args )
{

	my $self = $class->SUPER::new(
		%args,
		model        => 'Tasmota Thermostat',
		manufacturer => 'OpenHAP',
		serial       => $args{serial} // 'TSTAT-001',
	);

	# Sensor configuration (H5)
	$self->{sensor_type}  = $args{sensor_type};     # undef = auto-detect
	$self->{sensor_index} = $args{sensor_index};    # For indexed sensors

	# Current state
	$self->{current_temp}         = 20.0;
	$self->{target_temp}          = 20.0;
	$self->{heating_state}        = 0;              # 0=Off, 1=Heat, 2=Cool
	$self->{target_heating_state} = 0;

	# Add the Thermostat service. One row per characteristic:
	# type, iid, format, perms, and the extra arguments.
	my $thermostat = Protocol::HAP::Service->new(
		logger => $self->{logger},
		type   => 'Thermostat',
		iid    => 10,
	);

	my @rows = ( [
			'CurrentHeatingCoolingState', 11,
			'uint8',                      [ 'pr', 'ev' ],
			{ value => \$self->{heating_state} },
		],
		[
			'TargetHeatingCoolingState',
			12, 'uint8',
			[ 'pr', 'pw', 'ev' ],
			{
				value  => \$self->{target_heating_state},
				on_set => sub { $self->_set_target_state(@_) },
			},
		],
		[
			'CurrentTemperature',
			13, 'float',
			[ 'pr', 'ev' ],
			{
				unit  => 'celsius',
				value => \$self->{current_temp},
				min   => -40,
				max   => 100,
			},
		],
		[
			'TargetTemperature',
			14, 'float',
			[ 'pr', 'pw', 'ev' ],
			{
				unit   => 'celsius',
				value  => \$self->{target_temp},
				min    => 10,
				max    => 38,
				step   => 0.5,
				on_set => sub { $self->_set_target_temp(@_) },
			},
		],
		[
			'TemperatureDisplayUnits', 15, 'uint8',
			[ 'pr', 'pw', 'ev' ],
			{ value => 0 },    # 0=Celsius, 1=Fahrenheit
		],
	);

	for my $row (@rows) {
		my ( $type, $iid, $format, $perms, $extra ) = @$row;
		$thermostat->add_characteristic(
			Protocol::HAP::Characteristic->new(
				logger => $self->{logger},
				type   => $type,
				iid    => $iid,
				format => $format,
				perms  => $perms,
				%$extra,
			) );
	}

	$self->add_service($thermostat);

	return $self;
}

sub subscribe_mqtt ($self)
{
	# Call the base class to set up the standard subscriptions
	# (C1, C2, C3)
	$self->SUPER::subscribe_mqtt();

	return unless $self->{mqtt_client}->is_connected();

	Fugu::Log->default->debug(
		'Thermostat %s subscribing to additional MQTT topics',
		$self->{name} );

	# M2: The plain-text POWER response (SetOption4 support)
	$self->_subscribe_plain_power( heating_state => 11 );

	# STATUS8 answers an active query; the spec recommends STATUS10
	$self->_subscribe_status_sns($_) for qw(STATUS8 STATUS10);

	# Query the sensor status immediately
	$self->query_status(10);
}

# Override the base method to process the sensor data from
# SENSOR messages and the STATUS8/STATUS10 responses (H4, H5)
sub _process_sensor_data ( $self, $data )
{
	my ($temp) = $self->_find_sensor_values($data);
	return unless defined $temp;

	# Convert the value to Celsius if necessary (H4)
	$temp = $self->convert_temperature($temp);

	Fugu::Log->default->debug( 'Thermostat %s temperature updated: %.1f°C',
		$self->{name}, $temp );
	$self->{current_temp} = $temp;
	$self->notify_change(13);
	$self->_check_thermostat_logic();
}

# Override the base method to process the power state updates
sub _on_power_update ( $self, $state )
{
	if ( $self->{heating_state} != $state ) {
		$self->{heating_state} = $state;
		Fugu::Log->default->debug( 'Thermostat %s heating updated: %s',
			$self->{name}, $state ? 'ON' : 'OFF' );
		$self->notify_change(11);
	}
}

sub _set_target_temp ( $self, $temp )
{
	Fugu::Log->default->debug(
		'Thermostat %s target temperature set to %.1f°C',
		$self->{name}, $temp );
	$self->{target_temp} = $temp;
	$self->_check_thermostat_logic();
}

sub _set_target_state ( $self, $state )
{
	Fugu::Log->default->debug(
		'Thermostat %s target heating state set to %d',
		$self->{name}, $state );
	$self->{target_heating_state} = $state;
	$self->_check_thermostat_logic();
}

sub _check_thermostat_logic ($self)
{
	# Simple bang-bang controller with 0.5°C hysteresis
	my $hysteresis = 0.5;
	my $current    = $self->{current_temp};
	my $target     = $self->{target_temp};

	if ( $self->{target_heating_state} == 0 ) {

		# The target is OFF
		$self->set_power(0) if $self->{heating_state};
	}
	elsif ( $self->{target_heating_state} == 1 ) {

		# The target is HEAT
		if ( $current < $target - $hysteresis ) {
			$self->set_power(1);
		}
		elsif ( $current > $target + $hysteresis ) {
			$self->set_power(0);
		}
	}
}

1;
