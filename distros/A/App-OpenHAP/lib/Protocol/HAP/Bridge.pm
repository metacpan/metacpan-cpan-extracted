use v5.36;

package Protocol::HAP::Bridge;
our $VERSION = '0.1.0';

use Protocol::HAP::Accessory;
use Protocol::HAP::Service;
use Protocol::HAP::Characteristic;
our @ISA = qw(Protocol::HAP::Accessory);

sub new ( $class, %args )
{
	my $self = $class->SUPER::new(
		aid               => 1,    # The bridge is always accessory 1
		name              => $args{name}         // 'OpenHAP Bridge',
		manufacturer      => $args{manufacturer} // 'OpenBSD',
		model             => $args{model}        // 'OpenHAP',
		serial            => $args{serial}       // 'BRIDGE-001',
		firmware_revision => $args{firmware_revision} // '1.0.0',
		logger            => $args{logger},
	);

	$self->{bridged_accessories} = [];

	# The bridge accessory object itself must have the
	# ProtocolInformation service. Bridged accessories do not
	# carry it (HAP-Services.md §3).
	$self->_add_protocol_info_service;

	return $self;
}

sub _add_protocol_info_service ($self)
{
	my $protocol = Protocol::HAP::Service->new(
		type   => 'ProtocolInformation',
		iid    => 8,
		logger => $self->{logger},
	);

	$protocol->add_characteristic(
		Protocol::HAP::Characteristic->new(
			type   => 'Version',
			iid    => 9,
			format => 'string',
			perms  => ['pr'],
			logger => $self->{logger},
			value  => '1.1.0',
		) );

	$self->add_service($protocol);
}

sub add_bridged_accessory ( $self, $accessory )
{
	$self->{logger}->debug( 'Adding bridged accessory: AID=%d, name=%s',
		$accessory->{aid}, $accessory->{name} );
	push @{ $self->{bridged_accessories} }, $accessory;

	# Forward the event callbacks. Keep the device aid unchanged.
	$accessory->add_event_callback(
		sub ( $aid, $iid ) {
			for my $callback ( @{ $self->{event_callbacks} } ) {
				$callback->( $aid, $iid );
			}
		} );
}

sub get_bridged_accessories ($self)
{
	return @{ $self->{bridged_accessories} };
}

sub get_all_accessories ($self)
{
	return ( $self, @{ $self->{bridged_accessories} } );
}

sub get_accessory ( $self, $aid )
{
	return $self if $self->{aid} == $aid;

	for my $acc ( @{ $self->{bridged_accessories} } ) {
		return $acc if $acc->{aid} == $aid;
	}

	return;
}

sub to_json ($self)
{
	my @accessories;

	# Add the bridge itself
	push @accessories, $self->SUPER::to_json();

	# Add the bridged accessories
	for my $acc ( @{ $self->{bridged_accessories} } ) {
		push @accessories, $acc->to_json;
	}

	return { accessories => \@accessories };
}

1;
