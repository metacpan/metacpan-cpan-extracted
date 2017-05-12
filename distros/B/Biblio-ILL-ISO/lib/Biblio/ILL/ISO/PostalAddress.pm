package Biblio::ILL::ISO::PostalAddress;

=head1 NAME

Biblio::ILL::ISO::PostalAddress

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ILLString;
use Biblio::ILL::ISO::NameOfPersonOrInstitution;

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

Biblio::ILL::ISO::PostalAddress is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ILLString
 Biblio::ILL::ISO::NameOfPersonOrInstitution

=head1 USED IN

 Biblio::ILL::ISO::DeliveryAddress
 Biblio::ILL::ISO::WillSupplyResults

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Postal-Address ::= SEQUENCE {
	name-of-person-or-institution	 [0]	Name-Of-Person-Or-Institution OPTIONAL,
	extended-postal-delivery-address [1]	ILL-String OPTIONAL,
	street-and-number	         [2]	ILL-String OPTIONAL,
	post-office-box	                 [3]	ILL-String OPTIONAL,
	city	                         [4]	ILL-String OPTIONAL,
	region	                         [5]	ILL-String OPTIONAL,
	country	                         [6]	ILL-String OPTIONAL,
	postal-code	                 [7]	ILL-String OPTIONAL
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [$iname] [,[$pname] [,[$extended] [,[$street] [,[$box] [,[$city] [,[$region] [,[$country] [,$postcode]]]]]]]] )

Creates a new PostalAddress object. 
 Expects either no paramaters, or any of the following:
 an institution name (text string),
 a person name (text string),
 an extended-postal-delivery-address (text string),
 a street-and-number (text string),
 a post-office-box (text string),
 a city (text string),
 a region (text string),
 a country (text string), and/or
 a postal-code (text string).

 Pass empty strings ("") as placeholders.

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($iname, $pname, $extended, $street, $box, 
	    $city, $region, $country, $postcode) = @_;
	
	if (($pname) or ($iname)) {
	    $self->{"name-of-person-or-institution"} = new Biblio::ILL::ISO::NameOfPersonOrInstitution();
	    $self->{"name-of-person-or-institution"}->set_institution_name($iname) if ($iname);
	    $self->{"name-of-person-or-institution"}->set_person_name($pname) if ($pname);
	}
	$self->{"extended-postal-delivery-address"} = new Biblio::ILL::ISO::ILLString($extended) if ($extended);
	$self->{"street-and-number"} = new Biblio::ILL::ISO::ILLString($street) if ($street);
	$self->{"post-office-box"} = new Biblio::ILL::ISO::ILLString($box) if ($box);
	$self->{"city"} = new Biblio::ILL::ISO::ILLString($city) if ($city);
	$self->{"region"} = new Biblio::ILL::ISO::ILLString($region) if ($region);
	$self->{"country"} = new Biblio::ILL::ISO::ILLString($country) if ($country);
	$self->{"postal-code"} = new Biblio::ILL::ISO::ILLString($postcode) if ($postcode);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( [$iname] [,[$pname] [,[$extended] [,[$street] [,[$box] [,[$city] [,[$region] [,[$country] [,$postcode]]]]]]]] )

Sets the object's institution name (text string) or person name (text string),
 extended-postal-delivery-address (text string),
 street-and-number (text string),
 post-office-box (text string),
 city (text string),
 region (text string),
 country (text string), and/or
 postal-code (text string).

 Pass empty strings ("") as placeholders.

=cut
sub set {
    my $self = shift;
    my ($iname, $pname, $extended, $street, $box, 
	$city, $region, $country, $postcode) = @_;

    if (($pname) or ($iname)) {
	$self->{"name-of-person-or-institution"} = new Biblio::ILL::ISO::NameOfPersonOrInstitution();
	$self->{"name-of-person-or-institution"}->set_institution_name($iname) if ($iname);
	$self->{"name-of-person-or-institution"}->set_person_name($pname) if ($pname);
    }
    $self->{"extended-postal-delivery-address"} = new Biblio::ILL::ISO::ILLString($extended) if ($extended);
    $self->{"street-and-number"} = new Biblio::ILL::ISO::ILLString($street) if ($street);
    $self->{"post-office-box"} = new Biblio::ILL::ISO::ILLString($box) if ($box);
    $self->{"city"} = new Biblio::ILL::ISO::ILLString($city) if ($city);
    $self->{"region"} = new Biblio::ILL::ISO::ILLString($region) if ($region);
    $self->{"country"} = new Biblio::ILL::ISO::ILLString($country) if ($country);
    $self->{"postal-code"} = new Biblio::ILL::ISO::ILLString($postcode) if ($postcode);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_person_name( $s )

 Sets the object's name-of-person-or-institution.
 Expects a text string.

=cut
sub set_person_name {
    my $self = shift;
    my ($s) = @_;

    $self->{"name-of-person-or-institution"} = new Biblio::ILL::ISO::NameOfPersonOrInstitution();
    $self->{"name-of-person-or-institution"}->set_person_name($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_institution_name( $s )

 Sets the object's name-of-person-or-institution.
 Expects a text string.

=cut
sub set_institution_name {
    my $self = shift;
    my ($s) = @_;

    $self->{"name-of-person-or-institution"} = new Biblio::ILL::ISO::NameOfPersonOrInstitution();
    $self->{"name-of-person-or-institution"}->set_institution_name($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_extended_address( $s )

 Sets the object's extended-postal-delivery-address.
 Expects a text string.

=cut
sub set_extended_address {
    my $self = shift;
    my ($s) = @_;

    $self->{"extended-postal-delivery-address"} = new Biblio::ILL::ISO::ILLString($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_street( $s )

 Sets the object's street-and-number.
 Expects a text string.

=cut
sub set_street {
    my $self = shift;
    my ($s) = @_;

    $self->{"street-and-number"} = new Biblio::ILL::ISO::ILLString($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_pobox( $s )

 Sets the object's post-office-box.
 Expects a text string.

=cut
sub set_pobox {
    my $self = shift;
    my ($s) = @_;

    $self->{"post-office-box"} = new Biblio::ILL::ISO::ILLString($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_city( $s )

 Sets the object's city.
 Expects a text string.

=cut
sub set_city {
    my $self = shift;
    my ($s) = @_;

    $self->{"city"} = new Biblio::ILL::ISO::ILLString($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_region( $s )

 Sets the object's region.
 Expects a text string.

=cut
sub set_region {
    my $self = shift;
    my ($s) = @_;

    $self->{"region"} = new Biblio::ILL::ISO::ILLString($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_country( $s )

 Sets the object's country.
 Expects a text string.

=cut
sub set_country {
    my $self = shift;
    my ($s) = @_;

    $self->{"country"} = new Biblio::ILL::ISO::ILLString($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_postal_code( $s )

 Sets the object's postal-code.
 Expects a text string.

=cut
sub set_postal_code {
    my $self = shift;
    my ($s) = @_;

    $self->{"postal-code"} = new Biblio::ILL::ISO::ILLString($s);

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

	if ($k =~ /^name-of-person-or-institution$/) {
	    $self->{$k} = new Biblio::ILL::ISO::NameOfPersonOrInstitution();
	    $self->{$k}->from_asn($href->{$k});

	} elsif (($k =~ /^extended-postal-delivery-address$/)
		 || ($k =~ /^street-and-number$/)
		 || ($k =~ /^post-office-box$/)
		 || ($k =~ /^city$/)
		 || ($k =~ /^region$/)
		 || ($k =~ /^country$/)
		 || ($k =~ /^postal-code$/)
		 ) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString();
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
