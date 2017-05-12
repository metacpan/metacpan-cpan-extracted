package Biblio::ILL::ISO::DeliveryService;

=head1 NAME

Biblio::ILL::ISO::DeliveryService

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::TransportationMode;
use Biblio::ILL::ISO::ElectronicDeliveryServiceSequence;

use Carp;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';
#---------------------------------------------------------------------------
# Mods
# 0.02 - 2003.09.07 - fixed the POD
# 0.01 - 2003.07.15 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::DeliveryService is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::TransportationMode
 Biblio::ILL::ISO::ElectronicDeliveryServiceSequence

=head1 USED IN

 Biblio::ILL::ISO::ConditionalResults

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Delivery-Service ::= CHOICE {
	physical-delivery	[7]	Transportation-Mode,
	electronic-delivery	[50]	IMPLICIT SEQUENCE OF Electronic-Delivery-Service
		-- electronic-delivery may only be present in APDUs
		-- with a protocol-version-num value of 2 or greater
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [$transportation_mode | $e_delivery_service_seq] )

Creates a new DeliveryService object. 
 Expects either no paramaters, or one of:
 physical-delivery (Biblio::ILL::ISO::TransportationMode), or
 electronic-delivery (Biblio::ILL::ISO::ElectronicDeliveryServiceSequence).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($objref) = @_;
	
	if (ref($objref) eq "Biblio::ILL::ISO::TransportationMode") {
	    $self->{"physical-delivery"} = $objref;
	} elsif (ref($objref) eq "Biblio::ILL::ISO::ElectronicDeliveryServiceSequence") {
	    $self->{"electronic-delivery"} = $objref;
	} else {
	    croak "Invalid ElectronicDeliveryServiceSequence";
	}
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( [$transportation_mode | $e_delivery_service_seq] )

Sets the object's physical-delivery or electronic-delivery. 
 Expects one of:
 physical-delivery (Biblio::ILL::ISO::TransportationMode), or
 electronic-delivery (Biblio::ILL::ISO::ElectronicDeliveryServiceSequence).

=cut
sub set {
    my $self = shift;
    my ($objref) = @_;
    
    if (ref($objref) eq "Biblio::ILL::ISO::TransportationMode") {
	$self->{"physical-delivery"} = $objref;
    } elsif (ref($objref) eq "Biblio::ILL::ISO::ElectronicDeliveryServiceSequence") {
	$self->{"electronic-delivery"} = $objref;
    } else {
	croak "Invalid ElectronicDeliveryServiceSequence";
    }
    
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 from_asn($href)

Given a properly formatted hash, builds the object.

=cut
sub from_asn {
    my $self = shift;
    my $href = shift;

    foreach my $k (keys %$href) {
	#print ref($self) . "...$k\n";

	if ($k =~ /^physical-delivery$/) {
	    $self->{$k} = new Biblio::ILL::ISO::TransportationMode();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^electronic-delivery$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ElectronicDeliveryServiceSequence();
	    $self->{$k}->from_asn($href->{$k});

	} else {
	    croak "invalid " . ref($self) . " element: [$k]";
	}

    }
    return $self;
}

=head1 SEE ALSO

See the README for system design notes.
See the parent class(es) for other available methods.

For more information on Interlibrary Loan standards (ISO 10160/10161),
a good place to start is:

http://www.nlc-bnc.ca/iso/ill/main.htm

=cut

=head1 AUTHOR

David Christensen, <DChristensenSPAMLESS@westman.wave.ca>

=cut


=head1 COPYRIGHT AND LICENSE

Copyright 2003 by David Christensen

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
