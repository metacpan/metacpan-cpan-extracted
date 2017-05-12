package Biblio::ILL::ISO::ElectronicDeliveryServiceSequence;

=head1 NAME

Biblio::ILL::ISO::ElectronicDeliveryServiceSequence

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::SEQUENCE_OF;
use Biblio::ILL::ISO::ElectronicDeliveryService;

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

Biblio::ILL::ISO::ElectronicDeliveryServiceSequence is a derivation of Biblio::ILL::ISO::SEQUENCE_OF.

=head1 USES

 Biblio::ILL::ISO::ElectronicDeliveryService

=head1 USED IN

 Biblio::ILL::ISO::DeliveryService

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::SEQUENCE_OF 
		  Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
  (part of Delivery-Service)
 
  electronic-delivery	[50]	IMPLICIT SEQUENCE OF Electronic-Delivery-Service
	-- electronic-delivery may only be present in APDUs
	-- with a protocol-version-num value of 2 or greater
 
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

	my $objref = new Biblio::ILL::ISO::ElectronicDeliveryService();
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



