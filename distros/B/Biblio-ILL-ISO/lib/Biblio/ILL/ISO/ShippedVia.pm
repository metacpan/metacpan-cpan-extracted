package Biblio::ILL::ISO::ShippedVia;

=head1 NAME

Biblio::ILL::ISO::ShippedVia

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::TransportationMode;
use Biblio::ILL::ISO::ElectronicDeliveryService;

use Carp;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.08.11 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::ShippedVia is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::TransportationMode
 Biblio::ILL::ISO::ElectronicDeliveryService

=head1 USED IN

 Biblio::ILL::ISO::SupplyDetails

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Shipped-Via ::= CHOICE {
	physical-delivery	[5]	Transportation-Mode,
	electronic-delivery	[50]	IMPLICIT Electronic-Delivery-Service
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $transportation_mode | $electronic_delivery_service )

Creates a new ShippedVia object. 
 Expects either a transportation mode (Biblio::ILL::ISO::TransportationMode), or
 an electronic delivery service (Biblio::ILL::ISO::ElectronicDeliveryService).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($objref) = @_;
	
	if (ref($objref) eq "Biblio::ILL::ISO::TransportationMode") {
	    $self->{"physical-delivery"} = $objref;
	} elsif (ref($objref) eq "Biblio::ILL::ISO::ElectronicDeliveryService") {
	    $self->{"electronic-delivery"} = $objref;
	} else {
	    croak "Invalid ElectronicDeliveryService";
	}
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $transportation_mode | $electronic_delivery_service )

 Sets the object's physical-delivery (transportation mode) (Biblio::ILL::ISO::TransportationMode), or
 electronic-delivery (Biblio::ILL::ISO::ElectronicDeliveryService).

=cut
sub set {
    my $self = shift;
    my ($objref) = @_;
    
    if (ref($objref) eq "Biblio::ILL::ISO::TransportationMode") {
	$self->{"physical-delivery"} = $objref;
    } elsif (ref($objref) eq "Biblio::ILL::ISO::ElectronicDeliveryService") {
	$self->{"electronic-delivery"} = $objref;
    } else {
	croak "Invalid ElectronicDeliveryService";
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
	    $self->{$k} = new Biblio::ILL::ISO::ElectronicDeliveryService();
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
