package Cisco::UCS::Common::SwitchCard;

use warnings;
use strict;

use Cisco::UCS::Common::EthernetPort;
use Scalar::Util qw(weaken);
use Carp qw(croak);

our $VERSION = '0.51';

our @ATTRIBUTES = qw(dn id model operability power presence revision serial 
state thermal vendor voltage);

our %ATTRIBUTES	= (
	description	=> 'descr',
	num_ports	=> 'numPorts',
	performance	=> 'perf',
	slot		=> 'id'
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
		: croak 'ucs not defined';

        my %attr = %{ $self->{ucs}->resolve_dn(
				dn => $self->{dn}
			)->{outConfig}->{equipmentSwitchCard} };
    
        while ( my ( $k, $v ) = each %attr ) { $self->{$k} = $v }
    
        return $self;
}

sub eth_port {
	my ( $self,$id ) = @_;

	return ( defined $self->{eth_port}->{$id}
			? $self->{eth_port}->{$id}
			: $self->get_eth_port($id) 
	)
}

sub get_eth_port {
	my ( $self, $id ) = @_;

	return ( $id 
		? $self->get_eth_ports($id) 
		: undef 
	)
}

sub get_eth_ports {
        my ( $self, $id ) = @_;

        return $self->{ucs}->_get_child_objects(
			id	=> $id,
			type	=> 'etherPIo',
			class	=> 'Cisco::UCS::Common::EthernetPort',
			attr	=> 'eth_port',
			self	=> $self,
			uid	=> 'portId',
			class_filter => { 
				classId		=> 'etherPIo',
				slotId		=> $self->{id},
				switchId	=> $self->{interconnect_id} 
			}
	)
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

Cisco::UCS::Common::SwitchCard - Class for operations with a Cisco UCS 
switch card.

=cut

=head1 SYNOPSIS

	print $ucs->interconnect(A)->card(1)->operability;
	print $ucs->interconnect(A)->card(1)->serial;

	my $switchcard = $ucs->interconnect(A)->card(1);

	print $switchcard->num_ports;
	print $switchcard->description;

Cisco::UCS::Common::SwitchCard is a class used to represent a single Ethernet 
port in a Cisco::UCS system.  This class provides functionality to retrieve 
information and statistics for Ethernet ports.

Please note that you should not need to call the constructor directly as 
Cisco::UCS::Common::SwitchCard objects are created for you by the methods in 
other Cisco::UCS packages like Cisco::UCS::Interconnect.

Dependent on UCSM version, some attributes of the Ethernet port may not be 
provided and hence the accessor methods may return an empty string.

=head1 METHODS

=head2 description

Returns the vendor description of the switchcard. 

=head2 dn

Returns the distinguished name of the switchcard object in the UCSM management 
information model.

=head2 eth_port ( $id )

Returns a Cisco::UCS::Common::EthernetPort object representing the requested 
Ethernet port (given by the value of $id) on the switchcard.

Note that this is a caching method and a previously retrieved Ethernet port 
object will be returned if present.  Should you require a fresh object, use 
the B<get_eth_port> method described below.

=head2 get_eth_port ( $id )

Returns a Cisco::UCS::Common::EthernetPort object representing the requested 
Ethernet port (given by the value of $id) on the switchcard.

Note that this is a non-caching method and the UCSM will always be queried 
when this method is invoked. Subsequently, this method may be more expensive 
than the caching method B<eth_port> described above.

=head2 get_eth_ports

Returns an array of Cisco::UCS::Common::EthernetPort objects representing all 
Etehrnet ports present on the specified card.

=head2 id

Returns the numerical identifier of the switchcard within the fabric 
interconnect.

=head2 model

Returns the model identifier of the switchcard.

=head2 num_ports

Returns the number of ports present on the switchcard.

=head2 operability

Returns the operability status of the switchcard.

=head2 performance

Returns the performance status of teh switchcard.

=head2 power

Returns the power status of the switchcard.

=head2 presence

Returns the presence status of the switchcard.

=head2 revision

Returns the hardware revision number of the switchcard.

=head2 serial

Returns the serial number of the switchcard.

=head2 state

Returns the operational state of the switchcard.

=head2 slot

returns the slot number of the switchcard.

=head2 thermal

Returns the thermal status of the switchcard.

=head2 vendor

Returns the vendor identification string of the switchcard.

=head2 voltage

Returns the voltage status of the siwtchcard.

=cut

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-cisco-ucs-common-switchcard at rt.cpan.org>, or through the web 
interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-Common-SwitchCard>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::Common::SwitchCard

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-Common-SwitchCard>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-Common-SwitchCard>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-Common-SwitchCard>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-Common-SwitchCard/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
