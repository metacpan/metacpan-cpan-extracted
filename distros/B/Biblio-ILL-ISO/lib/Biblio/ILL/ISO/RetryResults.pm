package Biblio::ILL::ISO::RetryResults;

=head1 NAME

Biblio::ILL::ISO::RetryResults

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ReasonNotAvailable;
use Biblio::ILL::ISO::ISODate;
use Biblio::ILL::ISO::LocationInfoSequence;

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

Biblio::ILL::ISO::RetryResults is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ReasonNotAvailable;
 Biblio::ILL::ISO::ISODate;
 Biblio::ILL::ISO::LocationInfoSequence;

=head1 USED IN

 Biblio::ILL::ISO::ResultsExplanation

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Retry-Results ::= EXPLICIT SEQUENCE {
	reason-not-available	[0]	IMPLICIT Reason-Not-Available OPTIONAL,
	retry-date	[1]	IMPLICIT ISO-Date OPTIONAL,
	locations	[2]	IMPLICIT SEQUENCE OF Location-Info OPTIONAL
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $reason [,$replydate] [,$locations] )

Creates a new RetryResults object. 
 Expects a reason-not-available (Biblio::ILL::ISO::ReasonNotAvailable),
 (optionally) a date for reply (Biblio::ILL::ISO::ISODate), and
 (optionally) a location sequence (Biblio::ILL::ISO::LocationInfoSequence).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($reason, $replydate, $locations) = @_;

	croak "missing retry-result reason-not-available" unless ($reason);
	croak "invalid retry-result reason-not-available" unless (ref($reason) eq "Biblio::ILL::ISO::ReasonNotAvailable");

	if ($replydate) {
	    croak "invalid retry-date" unless (ref($replydate) eq "Biblio::ILL::ISO::ISODate");
	}
	if ($locations) {
	    croak "invalid locations" unless (ref($locations) eq "Biblio::ILL::ISO::LocationInfoSequence");
	}
	
	$self->{"reason-not-available"} = $reason;
	$self->{"retry-date"} = $replydate if ($replydate);
	$self->{"locations"} = $locations if ($locations);;
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $reason [,$replydate] [,$locations] [,proposed_delivery_service] )

Sets the object's reason-not-available (Biblio::ILL::ISO::ReasonNotAvailable),
 (optionally) date-for-reply (Biblio::ILL::ISO::ISODate), and
 (optionally) locations (Biblio::ILL::ISO::LocationInfoSequence).

=cut
sub set {
    my $self = shift;

    my ($reason, $replydate, $locations) = @_;
    
    croak "missing retry-result reason-not-available" unless ($reason);
    croak "invalid retry-result reason-not-available" unless (ref($reason) eq "Biblio::ILL::ISO::ReasonNotAvailable");
    
    if ($replydate) {
	croak "invalid retry-date" unless (ref($replydate) eq "Biblio::ILL::ISO::ISODate");
    }
    if ($locations) {
	croak "invalid locations" unless (ref($locations) eq "Biblio::ILL::ISO::LocationInfoSequence");
    }
    
    $self->{"reason-not-available"} = $reason;
    $self->{"retry-date"} = $replydate if ($replydate);
    $self->{"locations"} = $locations if ($locations);;
    
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

	if ($k =~ /^reason-not-available$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ReasonNotAvailable();
	    $self->{$k}->from_asn($href->{$k});
	
	} elsif ($k =~ /^retry-date$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ISODate();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^locations$/) {
	    $self->{$k} = new Biblio::ILL::ISO::LocationInfoSequence();
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
