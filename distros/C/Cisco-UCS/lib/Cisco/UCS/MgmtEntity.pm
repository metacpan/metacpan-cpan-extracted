package Cisco::UCS::MgmtEntity;

use strict;
use warnings;

use Carp		qw(croak);
use Scalar::Util	qw(weaken);

our $VERSION = '0.51';

our @ATTRIBUTES	= qw(chassis1 chassis2 chassis3 dn id leadership state);

our %ATTRIBUTES = (
	chassis1_device_io_state	=> 'chassisDeviceIoState1',
	chassis2_device_io_state	=> 'chassisDeviceIoState2',
	chassis3_device_io_state	=> 'chassisDeviceIoState3',
	ha_failure_reason		=> 'haFailureReason',
	ha_readiness			=> 'haReadiness',
	ha_ready			=> 'haReady',
	mgmt_services_state		=> 'mgmtServicesState',
	umbilical_state			=> 'umbilicalState',
	version_mismatch		=> 'versionMismatch'
);

sub new {
	my ( $class, %args ) = @_; 

	my $self = {}; 
	bless $self, $class;

	defined $args{dn}
		? $self->{dn} = $args{dn}
		: croak 'dn not defined';

	defined $args{ucs}
		? weaken($self->{ucs} = $args{ucs})
		: croak 'dn not defined';

	my %attr = %{ $self->{ucs}->resolve_dn(
				dn => $self->{dn}
			)->{outConfig}->{mgmtEntity} };

	while ( my ($k, $v) = each %attr ) { $self->{$k} = $v }

	return $self
}

{
        no strict 'refs';

        while ( my ( $pseudo, $attribute ) = each %ATTRIBUTES ) { 
                *{ __PACKAGE__ . '::' . $pseudo } = sub {
                        my $self = shift;
                        return $self->{$attribute}
                }   
        }   

        foreach my $attribute ( @ATTRIBUTES ) {
                *{ __PACKAGE__ . '::' . $attribute } = sub {
                        my $self = shift;
                        return $self->{$attribute}
                }   
        }   
}

1;

__END__

=head1 NAME

Cisco::UCS::MgmtEntity - Class for operations with a Cisco UCSM Management 
Entity

=head1 SYNOPSIS
	
	map {
		print "Management entity " 
			. $_->id . " HA state is " 
			. $_->ha_readiness . "\n"
	} $ucs->get_mgmt_entities;

	# prints...
	# Management entity A HA state is ready
	# Management entity B HA state is ready

	print $ucs->mgmt_entity('B')->umbilical_state;

=head1 DECRIPTION

Cisco::UCS::MgmtEntity is a class providing operations with a Cisco UCSM 
Management Entity.

Note that you are not supposed to call the constructor yourself, rather a 
Cisco::UCS::MgmtEntity object is created automatically by method calls via 
methods in Cisco::UCS.

=head1 METHODS

=head3 chassis1

Returns the serial number of the first chassis selected for hardware HA quorum.

=head3 chassis2

Returns the serial number of the second chassis selected for hardware HA quorum.

=head3 chassis3

Returns the serial number of the third chassis selected for hardware HA quorum.

=head3 chassis1_device_io_state

Returns the IO state of first chassis selected for hardware HA quorum.

=head3 chassis2_device_io_state

Returns the IO state of second chassis selected for hardware HA quorum.

=head3 chassis3_device_io_state

Returns the IO state of third chassis selected for hardware HA quorum.

=head3 dn

Returns the distinguished name of the management entity in the Cisco UCS 
information management heirarchy.

=head3 ha_failure_reason

Returns the HA failure reason (if present) of the specified management entity.

=head3 ha_readiness

Returns the HA readiness state of the specified management entity.

=head3 ha_ready

Returns the HA ready state of the specified management entity.

=head3 id

Returns the ID  of the specified management entity (either A or B).

=head3 leadership

Returns the leadership state  of the specified management entity.

=head3 mgmt_services_state

Returns the management services state of the specified management entity.

=head3 state

Returns the operational state of the specified management entity.

=head3 umbilical_state

Returns the umbilical state of the specified management entity.

=head3 version_mismatch

Returns the version mismatch state of the specified management entity.

=cut

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-cisco-ucs-mgmtentity at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-MgmtEntity>.  I 
will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::MgmtEntity

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-MgmtEntity>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-MgmtEntity>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-MgmtEntity>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-MgmtEntity/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
