package Biblio::ILL::ISO::HoldPlacedResults;

=head1 NAME

Biblio::ILL::ISO::HoldPlacedResults

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ISODate;
use Biblio::ILL::ISO::MediumType;
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

Biblio::ILL::ISO::HoldPlacedResults is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ISODate;
 Biblio::ILL::ISO::MediumType;
 Biblio::ILL::ISO::LocationInfoSequence;

=head1 USED IN

 Biblio::ILL::ISO::ResultsExplanation

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Hold-Placed-Results ::= EXPLICIT SEQUENCE {
	estimated-date-available	[0]	IMPLICIT ISO-Date,
	hold-placed-medium-type	        [1]	IMPLICIT Medium-Type OPTIONAL,
	locations	                [2]	IMPLICIT SEQUENCE OF Location-Info OPTIONAL
	}

=cut

=head1 METHODS

=cut
#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $estimated_date_available [,$medium] [,$locations] )

Creates a new HoldPlacedResults object. 
 Expects an estimated-date-available (Biblio::ILL::ISO::ISODate),
 (optionally) a hold-placed-medium-type (Biblio::ILL::ISO::MediumType), and
 (optionally) a locations sequence (Biblio::ILL::ISO::LocationInfoSequence).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($date, $medium, $locations) = @_;

	croak "missing hold-placed-results estimated-date-available" unless ($date);
	croak "invalid hold-placed-results estimated-date-available" unless (ref($date) eq "Biblio::ILL::ISO::ISODate");

	if ($medium) {
	    croak "invalid hold-placed-medium-type" unless (ref($medium) eq "Biblio::ILL::ISO::MediumType");
	}
	if ($locations) {
	    croak "invalid locations" unless (ref($locations) eq "Biblio::ILL::ISO::LocationInfoSequence");
	}
	
	$self->{"estimated-date-available"} = $date;
	$self->{"hold-placed-medium-type"} = $medium if ($medium);
	$self->{"locations"} = $locations if ($locations);;
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $estimated_date_available [,$medium] [,$locations] )

Sets the object's estimated-date-available (Biblio::ILL::ISO::ISODate),
 (optionally) hold-placed-medium-type (Biblio::ILL::ISO::MediumType), and
 (optionally) locations (Biblio::ILL::ISO::LocationInfoSequence).

=cut
sub set {
    my $self = shift;

    my ($date, $medium, $locations) = @_;

    croak "missing hold-placed-results estimated-date-available" unless ($date);
    croak "invalid hold-placed-results estimated-date-available" unless (ref($date) eq "Biblio::ILL::ISO::ISODate");

    if ($medium) {
	croak "invalid hold-placed-medium-type" unless (ref($medium) eq "Biblio::ILL::ISO::MediumType");
    }
    if ($locations) {
	croak "invalid locations" unless (ref($locations) eq "Biblio::ILL::ISO::LocationInfoSequence");
    }
	
    $self->{"estimated-date-available"} = $date;
    $self->{"hold-placed-medium-type"} = $medium if ($medium);
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

	if ($k =~ /^estimated-date-available$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ISODate();
	    $self->{$k}->from_asn($href->{$k});
	
	} elsif ($k =~ /^hold-placed-medium-type$/) {
	    $self->{$k} = new Biblio::ILL::ISO::MediumType();
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
