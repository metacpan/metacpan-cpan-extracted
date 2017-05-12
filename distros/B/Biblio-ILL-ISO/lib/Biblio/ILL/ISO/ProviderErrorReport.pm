package Biblio::ILL::ISO::ProviderErrorReport;

=head1 NAME

Biblio::ILL::ISO::ProviderErrorReport

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::GeneralProblem;
use Biblio::ILL::ISO::TransactionIdProblem;
use Biblio::ILL::ISO::StateTransitionProhibited;

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

Biblio::ILL::ISO::ProviderErrorReport is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ILLASNtype;
 Biblio::ILL::ISO::GeneralProblem;
 Biblio::ILL::ISO::TransactionIdProblem;
 Biblio::ILL::ISO::StateTransitionProhibited;

=head1 USED IN

 Biblio::ILL::ISO::ErrorReport

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Provider-Error-Report ::= CHOICE {
	general-problem	                [0]	IMPLICIT General-Problem,
	transaction-id-problem 	        [1]	IMPLICIT Transaction-Id-Problem,
	state-transition-prohibited	[2]	IMPLICIT State-Transition-Prohibited
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [$general_problem | $transaction_id_problem | $state_transition_prohibited] )

Creates a new ProviderErrorReport object. 
 Expects one of
 a general-problem (Biblio::ILL::ISO::GeneralProblem),
 a transaction-id-problem (Biblio::ILL::ISO::TransactionIdProblem), or
 a state-transition-prohibited (Biblio::ILL::ISO::StateTransitionProhibited).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($objref) = @_;
	
	if (ref($objref) eq "Biblio::ILL::ISO::GeneralProblem") {
	    $self->{"general-problem"} = $objref;
	} elsif (ref($objref) eq "Biblio::ILL::ISO::TransactionIdProblem") {
	    $self->{"transaction-id-problem"} = $objref;
	} elsif (ref($objref) eq "Biblio::ILL::ISO::StateTransitionProhibited") {
	    $self->{"state-transition-prohibited"} = $objref;
	} else {
	    croak "Invalid ProviderErrorReport";
	}
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( [$general_problem | $transaction_id_problem | $state_transition_prohibited] )

 Sets the object's "problem" type.
 Expects one of:
 general-problem (Biblio::ILL::ISO::GeneralProblem),
 transaction-id-problem (Biblio::ILL::ISO::TransactionIdProblem), or
 state-transition-prohibited (Biblio::ILL::ISO::StateTransitionProhibited).

=cut
sub set {
    my $self = shift;
    my ($objref) = @_;
    
    if (ref($objref) eq "Biblio::ILL::ISO::GeneralProblem") {
	$self->{"general-problem"} = $objref;
    } elsif (ref($objref) eq "Biblio::ILL::ISO::TransactionIdProblem") {
	$self->{"transaction-id-problem"} = $objref;
    } elsif (ref($objref) eq "Biblio::ILL::ISO::StateTransitionProhibited") {
	$self->{"state-transition-prohibited"} = $objref;
    } else {
	croak "Invalid ProviderErrorReport";
    }
    
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

	if ($k =~ /^general-problem$/) {
	    $self->{$k} = new Biblio::ILL::ISO::GeneralProblem();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^transaction-id-problem$/) {
	    $self->{$k} = new Biblio::ILL::ISO::TransactionIdProblem();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^state-transition-prohibited$/) {
	    $self->{$k} = new Biblio::ILL::ISO::StateTransitionProhibited();
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
