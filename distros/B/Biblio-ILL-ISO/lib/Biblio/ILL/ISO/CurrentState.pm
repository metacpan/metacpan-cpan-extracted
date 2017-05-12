package Biblio::ILL::ISO::CurrentState;

=head1 NAME

Biblio::ILL::ISO::CurrentState

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
# 0.01 - 2003.08.11 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::CurrentState is a derivation of Biblio::ILL::ISO::ENUMERATED.

=head1 USES

 None.

=head1 USED IN

 Biblio::ILL::ISO::StateTransitionProhibited
 Biblio::ILL::ISO::StatusReport

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ENUMERATED 
		  Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Current-State ::= ENUMERATED {
	nOT-SUPPLIED 	(1),
	pENDING	        (2),
	iN-PROCESS	(3),
	fORWARD	        (4),
	cONDITIONAL	(5),
	cANCEL-PENDING 	(6),
	cANCELLED	(7),
	sHIPPED 	(8),
	rECEIVED 	(9),
	rENEW-PENDING 	(10),
	nOT-RECEIVED-OVERDUE	(11),
	rENEW-OVERDUE 	(12),
	oVERDUE 	(13),
	rETURNED 	(14),
	cHECKED-IN	(15),
	rECALL 	        (16),
	lOST 	        (17),
	uNKNOWN 	(18)
	}

=cut

=head1 METHODS

=cut


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $condition )

 Creates a new ConditionalResultsCondition object. 
 Valid paramaters are listed in the FROM THE ASN DEFINITION section
 (e.g. "nOT-SUPPLIED").

=cut
sub new {
    my $class = shift;
    my $self = {};

    $self->{"ENUM_LIST"} = {"nOT-SUPPLIED" => 1,
			    "pENDING" => 2,
			    "iN-PROCESS" => 3,
			    "fORWARD" => 4,
			    "cONDITIONAL" => 5,
			    "cANCEL-PENDING" => 6,
			    "cANCELLED" => 7,
			    "sHIPPED" => 8,
			    "rECEIVED" => 9,
			    "rENEW-PENDING" => 10,
			    "nOT-RECEIVED-OVERDUE" => 11,
			    "rENEW-OVERDUE" => 12,
			    "oVERDUE" => 13,
			    "rETURNED" => 14,
			    "cHECKED-IN" => 15,
			    "rECALL" => 16,
			    "lOST" => 17,
			    "uNKNOWN" => 18
			    };

    if (@_) {
	my $s = shift;
	
	if ( exists $self->{"ENUM_LIST"}->{$s} ) {
	    $self->{"ENUMERATED"} = $self->{"ENUM_LIST"}->{$s};
	} else {
	    croak "invalid CurrentState type: [$s]";
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
