package Biblio::ILL::ISO::SEQUENCE_OF;

=head1 NAME

Biblio::ILL::ISO::SEQUENCE_OF

=cut

use Biblio::ILL::ISO::ILLASNtype;

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

 Biblio::ILL::ISO::SEQUENCE_OF is a derivation of Biblio::ILL::ISO::ILLASNtype.
 It functions as a base class for any class that needs to handle sequence types.

=head1 USES

 None.

=head1 USED IN

 Biblio::ILL::ISO::AlreadyTriedListType
 Biblio::ILL::ISO::ElectronicDeliveryServiceSequence
 Biblio::ILL::ISO::ILLServiceTypeSequence
 Biblio::ILL::ISO::LocationInfoSequence
 Biblio::ILL::ISO::SendToListTypeSequence
 Biblio::ILL::ISO::SupplyMediumInfoTypeSequence
 Biblio::ILL::ISO::UnitsPerMediumTypeSequence

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION

There is no ASN DEFINITION for SEQUENCE_OF.  An ASN.1 element can be defined
as a SEQUENCE OF another element - it is simply a list.

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [ @objrefs ] )

 Creates a new SEQUENCE_OF object.
 Expects either no paramaters, or a list of objects to be added to the list.

=cut
sub new {
    my $class = shift;
    my $self = {};

    $self->{"SEQUENCE"} = [ ];

    if (@_) { 
	while ($objref = shift) {
	    push @{ $self->{"SEQUENCE"} }, $objref;
	}
    }
    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 as_string( )

Returns a stringified representation of the object.

=cut
sub as_string {
    my $self = shift;

    my $s = "SEQUENCE\n";
    foreach $elem (@{ $self->{"SEQUENCE"} }) {
	$s .= $elem->as_string();
    }
    return $s;
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 as_pretty_string( )

Returns a more-formatted stringified representation of the object.

=cut
sub as_pretty_string {
    my $self = shift;

    my $s = "SEQUENCE\n";
    foreach $elem (@{ $self->{"SEQUENCE"} }) {
	$s .= "\n" . $elem->as_pretty_string();
    }
    return $s;
}


#---------------------------------------------------------------
# This will return a structure usable by Convert::ASN1
#---------------------------------------------------------------
=head1

=head2 as_asn( )

Returns a structure usable by Convert::ASN1.  Generally only called
from the parent's as_asn() method (or encode() method for top-level
message-type objects).

=cut
sub as_asn {
    my $self = shift;

    #print "Constructing array for SEQUENCE OF " . ref( $self->{"SEQUENCE"}[0] ) . "\n";

    my @a = ();

    foreach my $elem ( @{ $self->{"SEQUENCE"} }) {
	#print "  pushing " . ref($elem) . "\n";
	push @a, $elem->as_asn();
    }
    return \@a;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 add( $objref )

 Adds an element to the list.
 Expects an object (presumably of the correct type - does no error checking!)

=cut
sub add {
    my $self = shift;
    my ($objref) = @_;

    push @{ $self->{"SEQUENCE"} }, $objref;
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 count()

 Returns a count of the elements in the list.

=cut
sub count {
    my $self = shift;

    return scalar( @{ $self->{"SEQUENCE"} });
}

=head1 SEE ALSO

See the README for system design notes.
See the parent class(es) for other available methods.
See the derived classes for examples of use.

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
