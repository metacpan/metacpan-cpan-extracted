package Biblio::ILL::ISO::ReasonNotAvailable;

=head1 NAME

Biblio::ILL::ISO::ReasonNotAvailable

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

Biblio::ILL::ISO::ReasonNotAvailable is a derivation of Biblio::ILL::ISO::ENUMERATED.

=head1 USES

 None.

=head1 USED IN

 Biblio::ILL::ISO::RetryResults

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ENUMERATED 
		  Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Reason-Not-Available ::= ENUMERATED {
	in-use-on-loan 			(1),
	in-process 			(2),
	on-order 			(6),
	volume-issue-not-yet-available	(7),
	at-bindery 			(8),
	cost-exceeds-limit 		(13),
	charges 			(14),
	prepayment-required 		(15),
	lacks-copyright-compliance	(16),
	not-found-as-cited 		(17),
	on-hold 			(19),
	other 				(27),
	responder-specific 		(28)
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $s )

 Creates a new ReasonNotAvailable object. 
 Valid paramaters are listed in the FROM THE ASN DEFINITION section
 (e.g. "in-use-on-loan").

=cut
sub new {
    my $class = shift;
    my $self = {};

    $self->{"ENUM_LIST"} = {"in-use-on-loan" => 1,
			    "in-process" => 2,
			    "on-order" => 6,
			    "volume-issue-not-yet-available" =>	7,
			    "at-bindery" => 8,
			    "cost-exceeds-limit" => 13,
			    "charges" => 14,
			    "prepayment-required" => 15,
			    "lacks-copyright-compliance" => 16,
			    "not-found-as-cited" => 17,
			    "on-hold" => 19,
			    "other" => 27,
			    "responder-specific" => 28
			    };

    if (@_) {
	my $s = shift;
	
	if ( exists $self->{"ENUM_LIST"}->{$s} ) {
	    $self->{"ENUMERATED"} = $self->{"ENUM_LIST"}->{$s};
	} else {
	    croak "invalid ReasonNotAvailable type: [$s]";
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
