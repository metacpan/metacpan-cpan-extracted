package Biblio::ILL::ISO::SupplyMediumInfoTypeSequence;

=head1 NAME

Biblio::ILL::ISO::SupplyMediumInfoTypeSequence

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::SEQUENCE_OF;
use Biblio::ILL::ISO::SupplyMediumInfoType;

use Carp;

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';
#---------------------------------------------------------------------------
# Mods
# 0.02 - 2003.09.07 - fixed the POD
# 0.01 - 2003.07.15 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::SupplyMediumInfoTypeSequence is a derivation of Biblio::ILL::ISO::SEQUENCE_OF.

=head1 USES

 Biblio::ILL::ISO::SupplyMediumInfoType

=head1 USED IN

 Biblio::ILL::ISO::Request

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::SEQUENCE_OF 
		  Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 (part of ILL-Request)

 supply-medium-info-type  [13]	IMPLICIT SEQUENCE OF Supply-Medium-Info-Type OPTIONAL, -- SIZE (1..7)
	-- this sequence is a list, in order of preference,
	-- with a maximum number of 7 entries

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 from_asn($href)

Given a properly formatted hash, builds the object.

=cut
sub from_asn {
    my $self = shift;
    my $aref = shift;

    foreach my $elem (@$aref) {
	print ref($self) . "...$k\n";

	my $objref = new Biblio::ILL::ISO::SupplyMediumInfoType();
	$objref->from_asn( $aref[$elem] );
	push @{ $self->{"SEQUENCE"} }, $objref;

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
