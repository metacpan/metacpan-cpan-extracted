use v5.36;

package App::OpenHAP::Tasmota::Heater;
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
		model        => 'Tasmota Switch',
		manufacturer => 'OpenHAP',
		serial       => $args{serial} // 'HEAT-001',
	);

	$self->{power_state} = 0;

	# Add the Switch/Outlet service
	my $switch = Protocol::HAP::Service->new(
		logger  => $self->{logger},
		type    => 'Switch',
		iid     => 10,
		primary => 1,
	);

	$switch->add_characteristic(
		Protocol::HAP::Characteristic->new(
			logger => $self->{logger},
			type   => 'On',
			iid    => 11,
			format => 'bool',
			perms  => [ 'pr', 'pw', 'ev' ],
			value  => \$self->{power_state},
			on_set => sub { $self->set_power(@_) },
		) );

	$self->add_service($switch);

	return $self;
}

sub subscribe_mqtt ($self)
{
	# Call the base class to set up the standard subscriptions
	# (C1, C2, C3)
	$self->SUPER::subscribe_mqtt();

	return unless $self->{mqtt_client}->is_connected();

	Fugu::Log->default->debug(
		'Heater %s subscribing to additional MQTT topics',
		$self->{name} );

	# M2: The plain-text POWER response (SetOption4 support)
	$self->_subscribe_plain_power( power_state => 11 );
}

# Override _on_power_update to update the power state
sub _on_power_update ( $self, $state )
{
	if ( $self->{power_state} != $state ) {
		$self->{power_state} = $state;
		Fugu::Log->default->debug( 'Heater %s power updated: %s',
			$self->{name}, $state ? 'ON' : 'OFF' );
		$self->notify_change(11);
	}
}

1;
