use v5.36;

package Protocol::HAP::Characteristic;
our $VERSION = '0.1.0';

use Protocol::HAP;

# HAP Characteristic Type UUIDs
our %CHAR_TYPES = (

	# Accessory Information
	'Identify'         => '00000014-0000-1000-8000-0026BB765291',
	'Manufacturer'     => '00000020-0000-1000-8000-0026BB765291',
	'Model'            => '00000021-0000-1000-8000-0026BB765291',
	'Name'             => '00000023-0000-1000-8000-0026BB765291',
	'SerialNumber'     => '00000030-0000-1000-8000-0026BB765291',
	'FirmwareRevision' => '00000052-0000-1000-8000-0026BB765291',

	# Thermostat
	'CurrentHeatingCoolingState' => '0000000F-0000-1000-8000-0026BB765291',
	'TargetHeatingCoolingState'  => '00000033-0000-1000-8000-0026BB765291',
	'CurrentTemperature'         => '00000011-0000-1000-8000-0026BB765291',
	'TargetTemperature'          => '00000035-0000-1000-8000-0026BB765291',
	'TemperatureDisplayUnits'    => '00000036-0000-1000-8000-0026BB765291',

	# Switch/Outlet
	'On'          => '00000025-0000-1000-8000-0026BB765291',
	'OutletInUse' => '00000026-0000-1000-8000-0026BB765291',

	# Lightbulb
	'Brightness'       => '00000008-0000-1000-8000-0026BB765291',
	'Hue'              => '00000013-0000-1000-8000-0026BB765291',
	'Saturation'       => '0000002F-0000-1000-8000-0026BB765291',
	'ColorTemperature' => '000000CE-0000-1000-8000-0026BB765291',

	# Sensors
	'CurrentRelativeHumidity' => '00000010-0000-1000-8000-0026BB765291',

	# Protocol information
	'Version' => '00000037-0000-1000-8000-0026BB765291',
);

sub new ( $class, %args )
{

	my $type = $args{type}        // die "Characteristic type required";
	my $uuid = $CHAR_TYPES{$type} // $type;

	my $self = bless {
		type   => $uuid,
		iid    => $args{iid}    // die('Instance ID required'),
		format => $args{format} // 'string',
		perms  => $args{perms}  // ['pr'],
		logger => $args{logger} // Protocol::HAP->null_logger,

		# Value: a scalar reference makes the value mutable
		value => $args{value},

		# Optional metadata
		unit => $args{unit},
		min  => $args{min},
		max  => $args{max},
		step => $args{step},

		# Callbacks
		on_get => $args{on_get},
		on_set => $args{on_set},

		# Event notifications
		event_enabled => 0,
	}, $class;

	return $self;
}

sub get_value ($self)
{

	# Use the custom getter if the characteristic has one
	if ( $self->{on_get} ) {
		return $self->{on_get}->();
	}

	# If the value is a reference, dereference it
	if ( ref $self->{value} eq 'SCALAR' ) {
		return ${ $self->{value} };
	}

	return $self->{value};
}

sub set_value ( $self, $value )
{
	$self->{logger}->debug( 'Setting characteristic IID=%d to value: %s',
		$self->{iid}, defined $value ? $value : 'undef' );

	# Use the custom setter if the characteristic has one
	if ( $self->{on_set} ) {
		$self->{on_set}->($value);
	}

	# Update the value
	if ( ref $self->{value} eq 'SCALAR' ) {
		${ $self->{value} } = $value;
	}
	else {
		$self->{value} = $value;
	}
}

sub enable_events ( $self, $enabled )
{
	$self->{logger}->debug(
		'Events %s for characteristic IID=%d',
		$enabled ? 'enabled' : 'disabled',
		$self->{iid} );
	$self->{event_enabled} = $enabled;
}

sub events_enabled ($self)
{
	return $self->{event_enabled};
}

sub to_json ($self)
{

	my $json = {
		type   => Protocol::HAP::uuid_to_short( $self->{type} ),
		iid    => $self->{iid},
		format => $self->{format},
		perms  => $self->{perms},
	};

	# Add the optional metadata
	$json->{unit}     = $self->{unit} if defined $self->{unit};
	$json->{minValue} = $self->{min}  if defined $self->{min};
	$json->{maxValue} = $self->{max}  if defined $self->{max};
	$json->{minStep}  = $self->{step} if defined $self->{step};

	# Add the value if the characteristic is readable
	if ( grep { $_ eq 'pr' } @{ $self->{perms} } ) {
		$json->{value} = $self->json_value;
	}

	return $json;
}

# json_value() - Convert the current value to its JSON type. The
# characteristic format selects the type (HAP-HTTP.md §15.1).
sub json_value ($self)
{
	my $value = $self->get_value();

	if ( $self->{format} eq 'bool' ) {
		return $value ? \1 : \0;
	}
	if ( $self->{format} =~ /^(uint|int)/ ) {
		return $value + 0;
	}
	if ( $self->{format} eq 'float' ) {
		return $value + 0.0;
	}
	return $value;
}

1;
