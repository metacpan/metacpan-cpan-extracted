package Biblio::ILL::ISO::ResultsExplanation;

=head1 NAME

Biblio::ILL::ISO::ResultsExplanation

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ConditionalResults;
use Biblio::ILL::ISO::RetryResults;
use Biblio::ILL::ISO::UnfilledResults;
use Biblio::ILL::ISO::LocationsResults;
use Biblio::ILL::ISO::WillSupplyResults;
use Biblio::ILL::ISO::HoldPlacedResults;
use Biblio::ILL::ISO::EstimateResults;
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

Biblio::ILL::ISO::RessultsExplanation is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ConditionalResults;
 Biblio::ILL::ISO::RetryResults;
 Biblio::ILL::ISO::UnfilledResults;
 Biblio::ILL::ISO::LocationsResults;
 Biblio::ILL::ISO::WillSupplyResults;
 Biblio::ILL::ISO::HoldPlacedResults;
 Biblio::ILL::ISO::EstimateResults;

=head1 USED IN

 Biblio::ILL::ISO::Answer

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Results-Explanation ::= CHOICE {
	conditional-results	[1] Conditional-Results,
	  -- chosen if transaction-results=CONDITIONAL
	retry-results		[2] Retry-Results,
	  -- chosen if transaction-results=RETRY
	unfilled-results	[3] Unfilled-Results,
	  --chosen if transaction-results=UNFILLED
	locations-results	[4] Locations-Results,
	  -- chosen if transaction-results=LOCATIONS-PROVIDED
	will-supply-results	[5] Will-Supply-Results,
	  -- chosen if transaction-results=WILL-SUPPLY
	hold-placed-results	[6] Hold-Placed-Results,
	  -- chosen if transaction-results=HOLD-PLACED
	estimate-results	[7] Estimate-Results
	  -- chosen if transaction-results=ESTIMATE
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [$resex] )

 Creates a new ResultsExplanation object. 
 Expects either no parameters or one of:
 conditional-results (Biblio::ILL::ISO::ConditionalResults),
 retry-results (Biblio::ILL::ISO::RetryResults), 
 unfilled-results (Biblio::ILL::ISO::UnfilledResults), 
 locations-results (Biblio::ILL::ISO::LocationsResults),
 will-supply-results (Biblio::ILL::ISO::WillSupplyResults),
 hold-placed-results (Biblio::ILL::ISO::HoldPlacedResults), or
 estimate-results (Biblio::ILL::ISO::EstimateResults).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my $resex = shift;
	if (ref($resex) eq "Biblio::ILL::ISO::ConditionalResults") {
	    $self->{"conditional-results"} = $resex;
	} elsif (ref($resex) eq "Biblio::ILL::ISO::RetryResults") {
	    $self->{"retry-results"} = $resex;
	} elsif (ref($resex) eq "Biblio::ILL::ISO::UnfilledResults") {
	    $self->{"unfilled-results"} = $resex;
	} elsif (ref($resex) eq "Biblio::ILL::ISO::LocationsResults") {
	    $self->{"locations-results"} = $resex;
	} elsif (ref($resex) eq "Biblio::ILL::ISO::WillSupplyResults") {
	    $self->{"will-supply-results"} = $resex;
	} elsif (ref($resex) eq "Biblio::ILL::ISO::HoldPlacedResults") {
	    $self->{"hold-placed-results"} = $resex;
	} elsif (ref($resex) eq "Biblio::ILL::ISO::EstimateResults") {
	    $self->{"estimate-results"} = $resex;
	} else {
	}
    }
    bless($self, ref($class) || $class);
    return ($self);
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( [$resex] )

 Sets the object's conditional-results (Biblio::ILL::ISO::ConditionalResults),
 retry-results (Biblio::ILL::ISO::RetryResults), 
 unfilled-results (Biblio::ILL::ISO::UnfilledResults), 
 locations-results (Biblio::ILL::ISO::LocationsResults),
 will-supply-results (Biblio::ILL::ISO::WillSupplyResults),
 hold-placed-results (Biblio::ILL::ISO::HoldPlacedResults), or
 estimate-results (Biblio::ILL::ISO::EstimateResults).

=cut
sub set {
    my $self = shift;

    my $resex = shift;
    if (ref($resex) eq "Biblio::ILL::ISO::ConditionalResults") {
	$self->{"conditional-results"} = $resex;
    } elsif (ref($resex) eq "Biblio::ILL::ISO::RetryResults") {
	$self->{"retry-results"} = $resex;
    } elsif (ref($resex) eq "Biblio::ILL::ISO::UnfilledResults") {
	$self->{"unfilled-results"} = $resex;
    } elsif (ref($resex) eq "Biblio::ILL::ISO::LocationsResults") {
	$self->{"locations-results"} = $resex;
    } elsif (ref($resex) eq "Biblio::ILL::ISO::WillSupplyResults") {
	$self->{"will-supply-results"} = $resex;
    } elsif (ref($resex) eq "Biblio::ILL::ISO::HoldPlacedResults") {
	$self->{"hold-placed-results"} = $resex;
    } elsif (ref($resex) eq "Biblio::ILL::ISO::EstimateResults") {
	$self->{"estimate-results"} = $resex;
    } else {
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

	if ($k =~ /^conditional-results$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ConditionalResults();
	    $self->{$k}->from_asn($href->{$k});
	} elsif ($k =~ /^retry-results$/) {
	    $self->{$k} = new Biblio::ILL::ISO::RetryResults();
	    $self->{$k}->from_asn($href->{$k});
	} elsif ($k =~ /^unfilled-results$/) {
	    $self->{$k} = new Biblio::ILL::ISO::UnfilledResults();
	    $self->{$k}->from_asn($href->{$k});
	} elsif ($k =~ /^locations-results$/) {
	    $self->{$k} = new Biblio::ILL::ISO::LocationsResults();
	    $self->{$k}->from_asn($href->{$k});
	} elsif ($k =~ /^will-supply-results$/) {
	    $self->{$k} = new Biblio::ILL::ISO::WillSupplyResults();
	    $self->{$k}->from_asn($href->{$k});
	} elsif ($k =~ /^hold-placed-results$/) {
	    $self->{$k} = new Biblio::ILL::ISO::HoldPlacedResults();
	    $self->{$k}->from_asn($href->{$k});
	} elsif ($k =~ /^estimate-results$/) {
	    $self->{$k} = new Biblio::ILL::ISO::EstimateResults();
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
=head1

=head2 from_asn($href)

Given a properly formatted hash, builds the object.

=cut

1;
