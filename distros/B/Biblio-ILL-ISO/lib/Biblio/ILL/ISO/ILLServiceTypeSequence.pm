package Biblio::ILL::ISO::ILLServiceTypeSequence;

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::SEQUENCE_OF;

use Carp;

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.07.15 - original version
#---------------------------------------------------------------------------

BEGIN{@ISA = qw ( Biblio::ILL::ISO::SEQUENCE_OF 
		  Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

# From the ASN
# (part of ILL-Request)
#
#   iLL-service-type [9] IMPLICIT SEQUENCE OF ILL-Service-Type, --  SIZE (1..5)
#	-- this sequence is a list, in order of preference
#
#

#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub from_asn {
    my $self = shift;
    my $aref = shift;

    foreach my $elem (@$aref) {
	#print ref($self) . "...$k\n";

	my $objref = new Biblio::ILL::ISO::ILLServiceType();
	#$objref->from_asn( $aref[$elem] );
	$objref->from_asn( $elem );
	push @{ $self->{"SEQUENCE"} }, $objref;

    }
    return $self;
}


1;
