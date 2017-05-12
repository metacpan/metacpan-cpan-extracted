package Biblio::ILL::ISO::UnfilledResults;

=head1 NAME

Biblio::ILL::ISO::UnfilledResults

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ReasonUnfilled;
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

Biblio::ILL::ISO::UnfilledResults is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ReasonUnfilled
 Biblio::ILL::ISO::LocationInfoSequence

=head1 USED IN

 Biblio::ILL::ISO::ResultsExplanation

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Unfilled-Results ::= EXPLICIT SEQUENCE {
	reason-unfilled	[0]	IMPLICIT Reason-Unfilled,
	locations	[1]	IMPLICIT SEQUENCE OF Location-Info OPTIONAL
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $reason [,$locations] )

 Creates a new UnfilledResults object. 
 Expects a reason (Biblio::ILL::ISO::ReasonUnfilled), and
 (optionally) a location sequence (Biblio::ILL::ISO::LocationInfoSequence).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($reason, $replydate, $locations) = @_;

	croak "missing unfilled-result reason-unfilled" unless ($reason);
	croak "invalid unfilled-result reason-unfilled" unless (ref($reason) eq "Biblio::ILL::ISO::ReasonUnfilled");

	if ($locations) {
	    croak "invalid locations" unless (ref($locations) eq "Biblio::ILL::ISO::LocationInfoSequence");
	}
	
	$self->{"reason-unfilled"} = $reason;
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

Sets the object's unfilled-result (Biblio::ILL::ISO::ReasonUnfilled), and
 (optionally) locations (Biblio::ILL::ISO::LocationInfoSequence).

=cut
sub set {
    my $self = shift;

    my ($reason, $replydate, $locations) = @_;

    croak "missing unfilled-result reason-unfilled" unless ($reason);
    croak "invalid unfilled-result reason-unfilled" unless (ref($reason) eq "Biblio::ILL::ISO::ReasonUnfilled");

    if ($locations) {
	croak "invalid locations" unless (ref($locations) eq "Biblio::ILL::ISO::LocationInfoSequence");
    }
	
    $self->{"reason-unfilled"} = $reason;
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

	if ($k =~ /^reason-unfilled$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ReasonUnfilled();
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
