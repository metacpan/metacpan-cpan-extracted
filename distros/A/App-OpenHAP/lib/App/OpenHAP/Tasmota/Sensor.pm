use v5.36;

package App::OpenHAP::Tasmota::Sensor;
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
		model        => 'Tasmota Sensor',
		manufacturer => 'OpenHAP',
		serial       => $args{serial} // 'SENS-001',
	);

	$self->{sensor_type}      = $args{sensor_type};    # undef = auto-detect
	$self->{sensor_index}     = $args{sensor_index};   # For indexed sensors
	$self->{current_temp}     = 20.0;
	$self->{current_humidity} = undef;
	$self->{has_humidity}     = $args{has_humidity} // 0;

	# Add the Temperature Sensor service
	my $temp_sensor = Protocol::HAP::Service->new(
		logger  => $self->{logger},
		type    => 'TemperatureSensor',
		iid     => 10,
		primary => 1,
	);

	$temp_sensor->add_characteristic(
		Protocol::HAP::Characteristic->new(
			logger => $self->{logger},
			type   => 'CurrentTemperature',
			iid    => 11,
			format => 'float',
			perms  => [ 'pr', 'ev' ],
			unit   => 'celsius',
			value  => \$self->{current_temp},
			min    => -40,
			max    => 100,
		) );

	$self->add_service($temp_sensor);

	# Add the optional Humidity Sensor service (H5)
	if ( $self->{has_humidity} ) {
		$self->{current_humidity} = 50.0;

		my $humidity_sensor = Protocol::HAP::Service->new(
			logger => $self->{logger},
			type   => 'HumiditySensor',
			iid    => 20,
		);

		$humidity_sensor->add_characteristic(
			Protocol::HAP::Characteristic->new(
				logger => $self->{logger},
				type   => 'CurrentRelativeHumidity',
				iid    => 21,
				format => 'float',
				perms  => [ 'pr', 'ev' ],
				unit   => 'percentage',
				value  => \$self->{current_humidity},
				min    => 0,
				max    => 100,
			) );

		$self->add_service($humidity_sensor);
	}

	return $self;
}

sub subscribe_mqtt ($self)
{
	# Call the base class to set up the standard subscriptions
	# (C1, C2, C3)
	$self->SUPER::subscribe_mqtt();

	return unless $self->{mqtt_client}->is_connected();

	Fugu::Log->default->debug(
		'Sensor %s subscribing to additional MQTT topics',
		$self->{name} );

	# STATUS8 answers an active query; the spec recommends STATUS10
	$self->_subscribe_status_sns($_) for qw(STATUS8 STATUS10);
}

# Override the base method to process the sensor data from
# SENSOR messages
sub _process_sensor_data ( $self, $data )
{
	my ( $temp, $humidity ) = $self->_find_sensor_values($data);

	if ( defined $temp ) {

		# Convert the value to Celsius if necessary (H4)
		$temp = $self->convert_temperature($temp);

		Fugu::Log->default->debug(
			'Sensor %s temperature updated: %.1f°C',
			$self->{name}, $temp );
		$self->{current_temp} = $temp;
		$self->notify_change(11);
	}

	if ( defined $humidity && $self->{has_humidity} ) {
		Fugu::Log->default->debug( 'Sensor %s humidity updated: %.1f%%',
			$self->{name}, $humidity );
		$self->{current_humidity} = $humidity;
		$self->notify_change(21);
	}
}

1;
