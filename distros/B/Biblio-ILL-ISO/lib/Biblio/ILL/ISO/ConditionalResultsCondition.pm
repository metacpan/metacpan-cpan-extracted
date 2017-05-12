package Biblio::ILL::ISO::ConditionalResultsCondition;

=head1 NAME

Biblio::ILL::ISO::ConditionalResultsCondition

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
# 0.01 - 2003.07.26 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::ConditionalResultsCondition is a derivation of Biblio::ILL::ISO::ENUMERATED.

=head1 USES

 None.

=head1 USED IN

 Biblio::ILL::ISO::ConditionalResults

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ENUMERATED 
		  Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 (part of Conditional-Results)

	conditions	[0]	IMPLICIT ENUMERATED {
                                    cost-exceeds-limit 				(13),
				    charges 					(14),
				    prepayment-required 			(15),
				    lacks-copyright-compliance 			(16),
				    library-use-only 				(22),
				    no-reproduction 				(23),
				    client-signature-required 			(24),
				    special-collections-supervision-required	(25),
				    other 					(27),
				    responder-specific 				(28),
				    proposed-delivery-service 			(30) 
				    },

=cut

=head1 METHODS

=cut
#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $s )

 Creates a new ConditionalResultsCondition object. 
 Valid paramaters are listed in the FROM THE ASN DEFINITION section
 (e.g. "cost-exceeds-limit").

=cut
sub new {
    my $class = shift;
    my $self = {};

    $self->{"ENUM_LIST"} = {"cost-exceeds-limit" => 13,
			    "charges" => 14,
			    "prepayment-required" => 15,
			    "lacks-copyright-compliance" => 16,
			    "library-use-only" => 22,
			    "no-reproduction" => 23,
			    "client-signature-required" => 24,
			    "special-collections-supervision-required" => 25,
			    "other" => 27,
			    "responder-specific" => 28,
			    "proposed-delivery-service" => 30
			    };

    if (@_) {
	my $s = shift;
	
	if ( exists $self->{"ENUM_LIST"}->{$s} ) {
	    $self->{"ENUMERATED"} = $self->{"ENUM_LIST"}->{$s};
	} else {
	    croak "invalid ConditionalResultsCondition type: [$s]";
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
