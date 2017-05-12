package Biblio::ILL::ISO::DeliveryAddress;

=head1 NAME

Biblio::ILL::ISO::DeliveryAddress

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::PostalAddress;
use Biblio::ILL::ISO::SystemAddress;

use Carp;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.07.15 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::DeliveryAddress is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::PostalAddress
 Biblio::ILL::ISO::SystemAddress

=head1 USED IN

 Biblio::ILL::ISO::Request

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Delivery-Address ::= SEQUENCE {
	postal-address	        [0]	IMPLICIT Postal-Address OPTIONAL,
	electronic-address	[1]	IMPLICIT System-Address OPTIONAL
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $address [, $another_address] )

Creates a new DeliveryAddress object. 
 Expects an address (either a Biblio::ILL::ISO::PostalAddress or a Biblio::ILL::ISO::SystemAddress), and
 (optionally) another address (either a Biblio::ILL::ISO::PostalAddress or a Biblio::ILL::ISO::SystemAddress).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($ref1, $ref2) = @_;
	
	$self->{"postal-address"} = $ref1 if (ref($ref1) eq "Biblio::ILL::ISO::PostalAddress");
	$self->{"postal-address"} = $ref2 if (ref($ref2) eq "Biblio::ILL::ISO::PostalAddress");
	$self->{"electronic-address"} = $ref1 if (ref($ref1) eq "Biblio::ILL::ISO::SystemAddress");
	$self->{"electronic-address"} = $ref2 if (ref($ref2) eq "Biblio::ILL::ISO::SystemAddress");
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_postal_address($iname,$pname,$extended,$street,$box,$city,$region,$country,$postcode)

Sets the object's postal-address.
 Expects an institution name (text string),
 a person name (text string),
 an "extended address" (text string),
 a street-and-number (text string),
 a post office box (text string),
 a city (text string),
 a region (text string),
 a country (text string), and
 a postal code (text string).

Strangely, *all* parameters are optional.  Pass empty strings ("") for NULL values.

=cut
sub set_postal_address {
    my $self = shift;
    my ($iname, $pname, $extended, $street, $box, 
	$city, $region, $country, $postcode) = @_;
    
    $self->{"postal-address"} = new Biblio::ILL::ISO::PostalAddress($iname, 
						  $pname, 
						  $extended, 
						  $street, 
						  $box, 
						  $city, 
						  $region, 
						  $country, 
						  $postcode);
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_postal_address_by_obj($postal_address)

 Sets the object's postal-address.
 Expects a valid Biblio::ILL::ISO::PostalAddress.

=cut
sub set_postal_address_by_obj {
    my $self = shift;
    my ($objref) = @_;

    if (ref($objref) eq "Biblio::ILL::ISO::PostalAddress") {
	$self->{"postal-address"} = $objref;
    } else {
	croak "Not a PostalAddress";
    }
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_electronic_address($id, $addr)

 Sets the objects electronic-address (a Biblio::ILL::ISO::SystemAddress).
 Expects an ID (text string), and
 an address (text string).

=cut
sub set_electronic_address {
    my $self = shift;
    my ($id, $addr) = @_;
    
    $self->{"electronic-address"} = new Biblio::ILL::ISO::SystemAddress($id, $addr);
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_electronic_address_by_obj($system_address)

 Sets the object's electronic-address.
 Expects a valid Biblio::ILL::ISO::SystemAddress.

=cut
sub set_electronic_address_by_obj {
    my $self = shift;
    my ($objref) = @_;

    if (ref($objref) eq "Biblio::ILL::ISO::SystemAddress") {
	$self->{"electronic-address"} = $objref;
    } else {
	croak "Not a SystemAddress";
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

	if ($k =~ /^electronic-address$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SystemAddress();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^postal-address$/) {
	    $self->{$k} = new Biblio::ILL::ISO::PostalAddress();
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
