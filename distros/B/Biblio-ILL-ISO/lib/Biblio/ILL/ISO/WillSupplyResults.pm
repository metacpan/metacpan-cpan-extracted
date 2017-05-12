package Biblio::ILL::ISO::WillSupplyResults;

=head1 NAME

Biblio::ILL::ISO::WillSupplyResults

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ReasonWillSupply;
use Biblio::ILL::ISO::ISODate;
use Biblio::ILL::ISO::PostalAddress;
use Biblio::ILL::ISO::LocationInfoSequence;
use Biblio::ILL::ISO::ElectronicDeliveryService;

use Carp;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.07.26 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::WillSupplyResults is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ReasonWillSupply
 Biblio::ILL::ISO::ISODate
 Biblio::ILL::ISO::PostalAddress
 Biblio::ILL::ISO::LocationInfoSequence
 Biblio::ILL::ISO::ElectronicDeliveryService

=head1 USED IN

 Biblio::ILL::ISO::ResultsExplanation

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Will-Supply-Results ::= EXPLICIT SEQUENCE {
	reason-will-supply 	        [0]	ReasonWillSupply,
	supply-date	                [1]	ISO-Date OPTIONAL,
	return-to-address	        [2]	Postal-Address OPTIONAL,
	locations	                [3]	IMPLICIT SEQUENCE OF Location-Info OPTIONAL,
	electronic-delivery-service	[4]     Electronic-Delivery-Service OPTIONAL
		-- if present, this must be one of the services proposed by 
		-- the requester
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $reason, [$supplydate [,$returnto [,$locations [,$electronic_delivery_service]]]] )

 Creates a new WillSupplyResults object. 
 Expects either no paramaters, or
 a reason (Biblio::ILL::ISO::ReasonWillSupply),
 (optionally) a supply-date (Biblio::ILL::ISO::ISODate), 
 (optionally) a return-to address (Biblio::ILL::ISO::PostalAddress),
 (optionally) a locations sequence (Biblio::ILL::ISO::LocationInfoSequence), and
 (optionally) an electronic delivery address (Biblio::ILL::ISO::ElectronicDeliveryService).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($reason, $supplydate, $returnto, $locations, $electronic_delivery_service) = @_;

	croak "missing will-supply-result reason-will-supply" unless ($reason);
	croak "invalid will-supply-result reason-will-supply" unless (ref($reason) eq "Biblio::ILL::ISO::ReasonWillSupply");

	if ($supplydate) {
	    croak "invalid supply-date" unless (ref($supplydate) eq "Biblio::ILL::ISO::ISODate");
	}
	if ($returnto) {
	    croak "invalid return-to-address" unless (ref($returnto) eq "Biblio::ILL::ISO::PostalAddress");
	}
	if ($locations) {
	    croak "invalid locations" unless (ref($locations) eq "Biblio::ILL::ISO::LocationInfoSequence");
	}
	if ($electronic_delivery_service) {
	    croak "invalid electronic-delivery-service" unless (ref($electronic_delivery_service) eq "Biblio::ILL::ISO::ElectronicDeliveryService");
	}
	
	$self->{"reason-will-supply"} = $reason;
	$self->{"supply-date"} = $supplydate if ($supplydate);
	$self->{"return-to-address"} = $returnto if ($returnto);
	$self->{"locations"} = $locations if ($locations);
	$self->{"electronic-delivery-address"} = $electronic_delivery_address if ($electronic_delivery_address);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $reason, [$supplydate [,$returnto [,$locations [,$electronic_delivery_service]]]] )

 Sets the object's reason-will-supply (Biblio::ILL::ISO::ReasonWillSupply),
 (optionally) supply-date (Biblio::ILL::ISO::ISODate), 
 (optionally) return-to-address (Biblio::ILL::ISO::PostalAddress),
 (optionally) locations (Biblio::ILL::ISO::LocationInfoSequence), and
 (optionally) electronic-delivery-address (Biblio::ILL::ISO::ElectronicDeliveryService).

=cut
sub set {
    my $self = shift;

    my ($reason, $supplydate, $returnto, $locations, $electronic_delivery_service) = @_;

    croak "missing will-supply-result reason-will-supply" unless ($reason);
    croak "invalid will-supply-result reason-will-supply" unless (ref($reason) eq "Biblio::ILL::ISO::ReasonWillSupply");

    if ($supplydate) {
	croak "invalid supply-date" unless (ref($supplydate) eq "Biblio::ILL::ISO::ISODate");
    }
    if ($returnto) {
	croak "invalid return-to-address" unless (ref($returnto) eq "Biblio::ILL::ISO::PostalAddress");
    }
    if ($locations) {
	croak "invalid locations" unless (ref($locations) eq "Biblio::ILL::ISO::LocationInfoSequence");
    }
    if ($electronic_delivery_service) {
	croak "invalid electronic-delivery-service" unless (ref($electronic_delivery_service) eq "Biblio::ILL::ISO::ElectronicDeliveryService");
    }
    
    $self->{"reason-will-supply"} = $reason;
    $self->{"supply-date"} = $supplydate if ($supplydate);
    $self->{"return-to-address"} = $returnto if ($returnto);
    $self->{"locations"} = $locations if ($locations);
    $self->{"electronic-delivery-address"} = $electronic_delivery_address if ($electronic_delivery_address);
    
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

	if ($k =~ /^reason-will-supply$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ReasonWillSupply();
	    $self->{$k}->from_asn($href->{$k});
	
	} elsif ($k =~ /^supply-date$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ISODate();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^return-to-address$/) {
	    $self->{$k} = new Biblio::ILL::ISO::PostalAddress();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^locations$/) {
	    $self->{$k} = new Biblio::ILL::ISO::LocationInfoSequence();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^electronic-delivery-address$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ElectronicDeliveryAddress();
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
