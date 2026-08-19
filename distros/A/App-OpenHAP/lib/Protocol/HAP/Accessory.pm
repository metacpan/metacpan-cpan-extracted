use v5.36;

package Protocol::HAP::Accessory;
our $VERSION = '0.1.0';

use Protocol::HAP;
use Protocol::HAP::Service;
use Protocol::HAP::Characteristic;

sub new ( $class, %args )
{
	my $self = bless {
		aid               => $args{aid},
		name              => $args{name}         // 'Accessory',
		manufacturer      => $args{manufacturer} // 'OpenHAP',
		model             => $args{model}        // 'HAP Accessory',
		serial            => $args{serial}       // 'ACC-001',
		firmware_revision => $args{firmware_revision} // '1.0.0',
		logger          => $args{logger} // Protocol::HAP->null_logger,
		services        => [],
		event_callbacks => [],
	}, $class;

	# Add the required Accessory Information service
	$self->_add_accessory_info_service();

	return $self;
}

sub _add_accessory_info_service ($self)
{
	my $info = Protocol::HAP::Service->new(
		type   => 'AccessoryInformation',
		iid    => 1,
		logger => $self->{logger},
	);

	# One row per characteristic: type, iid, format, perms, value.
	# Identify is write-only and carries no value.
	my @rows = (
		[ 'Identify',     2, 'bool',   ['pw'], undef ],
		[ 'Manufacturer', 3, 'string', ['pr'], $self->{manufacturer} ],
		[ 'Model',        4, 'string', ['pr'], $self->{model} ],
		[ 'Name',         5, 'string', ['pr'], $self->{name} ],
		[ 'SerialNumber', 6, 'string', ['pr'], $self->{serial} ],
		[
			'FirmwareRevision', 7,
			'string',           ['pr'],
			$self->{firmware_revision}
		],
	);

	for my $row (@rows) {
		my ( $type, $iid, $format, $perms, $value ) = @$row;
		$info->add_characteristic(
			Protocol::HAP::Characteristic->new(
				type   => $type,
				iid    => $iid,
				format => $format,
				perms  => $perms,
				logger => $self->{logger},
				value  => $value,
			) );
	}

	push @{ $self->{services} }, $info;
}

sub add_service ( $self, $service )
{
	push @{ $self->{services} }, $service;
}

sub get_services ($self)
{
	return @{ $self->{services} };
}

sub get_service ( $self, $type )
{
	# Look up the full UUID when the caller gives a short name
	my $target_uuid = $Protocol::HAP::Service::SERVICE_TYPES{$type}
	    // $type;

	for my $service ( @{ $self->{services} } ) {
		return $service if $service->{type} eq $target_uuid;
	}

	return;
}

sub get_characteristic ( $self, $iid )
{
	for my $service ( @{ $self->{services} } ) {
		my $char = $service->get_characteristic($iid);
		return $char if $char;
	}

	return;
}

sub to_json ($self)
{
	my @services;
	for my $service ( @{ $self->{services} } ) {
		push @services, $service->to_json();
	}

	return {
		aid      => $self->{aid},
		services => \@services,
	};
}

sub add_event_callback ( $self, $callback )
{
	push @{ $self->{event_callbacks} }, $callback;
}

sub notify_change ( $self, $iid )
{
	# Tell all registered callbacks about the characteristic change
	for my $callback ( @{ $self->{event_callbacks} } ) {
		$callback->( $self->{aid}, $iid );
	}
}

1;
