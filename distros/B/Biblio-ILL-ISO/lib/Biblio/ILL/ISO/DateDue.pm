package Biblio::ILL::ISO::DateDue;

=head1 NAME

Biblio::ILL::ISO::DateDue

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ISODate;
use Biblio::ILL::ISO::Flag;

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

Biblio::ILL::ISO::DateDue is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ISODate
 Biblio::ILL::ISO::Flag

=head1 USED IN

 Biblio::ILL::ISO::Overdue
 Biblio::ILL::ISO::RenewAnswer
 Biblio::ILL::ISO::ResultsExplanation
 Biblio::ILL::ISO::SupplyDetails

=cut

=head1 METHODS

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Date-Due ::= EXPLICIT SEQUENCE {
	date-due-field	[0]	IMPLICIT ISO-Date,
	renewable	[1]	IMPLICIT BOOLEAN -- DEFAULT TRUE
	}

=cut

=head1 METHODS

=cut


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $date [, $renewable] )

Creates a new DateDue object. 
 Expects a date string (YYYYMMDD), and
 (optionally) a "renewable" flag string ("true"/"false"). 

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($date, $renewable) = @_;

	croak "missing date" unless ($date);
	$renewable = "true" unless (defined $renewable);
	
	$self->{"date-due-field"} = new Biblio::ILL::ISO::ISODate($date);
	$self->{"renewable"} = new Biblio::ILL::ISO::Flag($renewable);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $date [, $renewable] )

Sets the object's date-due-field (a date string (YYYYMMDD)), and
 (optionally) a "renewable" flag (a string ("true"/"false")). 

=cut
sub set {
    my $self = shift;
    my ($date, $renewable) = @_;
    
    croak "missing date" unless ($date);
    $renewable = "true" unless (defined $renewable);
    
    $self->{"date-due-field"} = new Biblio::ILL::ISO::ISODate($date);
    $self->{"renewable"} = new Biblio::ILL::ISO::Flag($renewable);

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

	if ($k =~ /^date-due-field$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ISODate($href->{$k});

	} elsif ($k =~ /^renewable$/) {
	    $self->{$k} = new Biblio::ILL::ISO::Flag($href->{$k});

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
