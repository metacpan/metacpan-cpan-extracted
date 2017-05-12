package Biblio::ILL::ISO::LocationsResults;

=head1 NAME

Biblio::ILL::ISO::LocationsResults

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ReasonLocsProvided;
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

Biblio::ILL::ISO::LocationResults is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ReasonLocsProvided
 Biblio::ILL::ISO::LocationInfoSequence

=head1 USED IN

 Biblio::ILL::ISO::ResultsExplanation

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Locations-Results ::= EXPLICIT SEQUENCE {
	reason-locs-provided	[0]	IMPLICIT Reason-Locs-Provided OPTIONAL,
	locations	[1]	IMPLICIT SEQUENCE OF Location-Info
	}

=cut

=head1 METHODS

=cut
#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $reason [,$locations] )

Creates a new LocationsResults object. 
 Expects a reason-locs-provided (Biblio::ILL::ISO::ReasonLocsProvided), and
 (optionally) a location sequence (Biblio::ILL::ISO::LocationInfoSequence).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($reason, $locations) = @_;

	croak "missing locations-results reason-locs-provided" unless ($reason);
	croak "invalid locations-results reason-locs-provided" unless (ref($reason) eq "Biblio::ILL::ISO::ReasonLocsProvided");

	if ($locations) {
	    croak "invalid locations" unless (ref($locations) eq "Biblio::ILL::ISO::LocationInfoSequence");
	}
	
	$self->{"reason-locs-provided"} = $reason;
	$self->{"locations"} = $locations if ($locations);;
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $reason [,$locations] )

Sets the object's 
 reason-locs-provided (Biblio::ILL::ISO::ReasonLocsProvided), and
 (optionally) locations (Biblio::ILL::ISO::LocationInfoSequence).

=cut
sub set {
    my $self = shift;

    my ($reason, $locations) = @_;
    
    croak "missing locations-results reason-locs-provided" unless ($reason);
    croak "invalid locations-results reason-locs-provided" unless (ref($reason) eq "Biblio::ILL::ISO::ReasonLocsProvided");
    
    if ($locations) {
	croak "invalid locations" unless (ref($locations) eq "Biblio::ILL::ISO::LocationInfoSequence");
    }
    
    $self->{"reason-locs-provided"} = $reason;
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

	if ($k =~ /^reason-locs-provided$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ReasonLocsProvided();
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

1;
