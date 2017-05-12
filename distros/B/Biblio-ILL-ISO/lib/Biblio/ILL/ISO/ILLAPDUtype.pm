package Biblio::ILL::ISO::ILLAPDUtype;

=head1 NAME

Biblio::ILL::ISO::ILLAPDUtype

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ENUMERATED;
use Carp;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.08.12 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::ILLAPDUtype is a derivation of Biblio::ILL::ISO::ENUMERATED.

=head1 USES

 None.

=head1 USED IN

 Biblio::ILL::ISO::StateTransitionProhibited

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ENUMERATED 
		  Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 ILL-APDU-Type ::= ENUMERATED {
	iLL-REQUEST 	        (1),
	fORWARD-NOTIFICATION 	(2),
	sHIPPED 	        (3),
	iLL-ANSWER 	        (4),
	cONDITIONAL-REPLY 	(5),
	cANCEL 	                (6),
	cANCEL-REPLY 	        (7),
	rECEIVED 	        (8),
	rECALL 	                (9),
	rETURNED 	        (10),
	cHECKED-IN 	        (11),
	oVERDUE 	        (12),
	rENEW 	                (13),
        rENEW-ANSWER 	        (14),
	lOST 	                (15),
	dAMAGED 	        (16),
	mESSAGE 	        (17),
	sTATUS-QUERY 	        (18),
	sTATUS-OR-ERROR-REPORT	(19),
	eXPIRED 	        (20)
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $type )

 Creates a new ILLAPDUtype object. 
 Valid paramaters are listed in the FROM THE ASN DEFINITION section
 (e.g. "iLL-REQUEST").

=cut
sub new {
    my $class = shift;
    my $self = {};

    $self->{"ENUM_LIST"} = {"iLL-REQUEST" => 1,
			    "fORWARD-NOTIFICATION" => 2,
			    "sHIPPED" => 3,
			    "iLL-ANSWER" => 4,
			    "cONDITIONAL-REPLY" => 5,
			    "cANCEL" => 6,
			    "cANCEL-REPLY" => 7,
			    "rECEIVED" => 8,
			    "rECALL" => 9,
			    "rETURNED" => 10,
			    "cHECKED-IN" => 11,
			    "oVERDUE" => 12,
			    "rENEW" => 13,
			    "rENEW-ANSWER" => 14,
			    "lOST" => 15,
			    "dAMAGED" => 16,
			    "mESSAGE" => 17,
			    "sTATUS-QUERY" => 18,
			    "sTATUS-OR-ERROR-REPORT" => 19,
			    "eXPIRED" => 20
			    };

    if (@_) {
	my $s = shift;
	
	if ( exists $self->{"ENUM_LIST"}->{$s} ) {
	    $self->{"ENUMERATED"} = $self->{"ENUM_LIST"}->{$s};
	} else {
	    croak "invalid ILLAPDUtype: [$s]";
	}
    }

    bless($self, ref($class) || $class);
    return ($self);
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
