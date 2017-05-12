package Biblio::ILL::ISO::AmountString;

=head1 NAME

Biblio::ILL::ISO::AmountString

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

Biblio::ILL::ISO::AmountString is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 None.

=head1 USED IN

 Biblio::ILL::ISO::Amount

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 AmountString ::= PrintableString -- (FROM ("1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"0"|" "|"."|","))

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [$string] )

Creates a new AmountString object. Expects either no parameters, or
a text string.  Currently does not implement the character restrictions.

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	$self->{"PrintableString"} = shift;
    }
    bless($self, ref($class) || $class);
    return ($self);
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set($string)

Sets the object's PrintableString.  Currently does not implement the
ASN.1 AmountString character restrictions.

=cut
sub set {
    my $self = shift;

    $self->{"PrintableString"} = shift;
    return;
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

    return $self->{"PrintableString"};
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

    return $self->{"PrintableString"} . "\n";
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

    return $self->{"PrintableString"};
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
    my $val = shift;

    $self->{"PrintableString"} = $val;

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
