package Biblio::ILL::ISO::DateTime;

=head1 NAME

Biblio::ILL::ISO::DateTime

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ISODate;
use Biblio::ILL::ISO::ISOTime;

use Carp;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.07.15 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::DateTime is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ISODate
 Biblio::ILL::ISO::ISOTime

=head1 USED IN

 Biblio::ILL::ISO::ServiceDateTime

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Date-Time ::= EXPLICIT SEQUENCE {
	date	[0]	IMPLICIT ISO-Date,
	time	[1]	IMPLICIT ISO-Time OPTIONAL
	}

=cut

=head1 METHODS

=cut


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $date [,$time] )

Creates a new DateTime object. 
 Expects a date string (YYYYMMDD), and
 (optionally) a time string (MMHHSS).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($date, $time) = @_;

	croak "missing date" unless ($date);
	
	$self->{"date"} = new Biblio::ILL::ISO::ISODate($date);
	$self->{"time"} = new Biblio::ILL::ISO::ISOTime($time) if ($time);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $date [,$time] )

Sets the object's date (a date string (YYYYMMDD)), and
 (optionally) time (a time string (MMHHSS)).

=cut
sub set {
    my $self = shift;
    my ($date, $time) = @_;
    
    croak "missing date" unless ($date);
    
    $self->{"date"} = new Biblio::ILL::ISO::ISODate($date);
    $self->{"time"} = new Biblio::ILL::ISO::ISOTime($time) if ($time);

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

	if ($k =~ /^date$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ISODate($href->{$k});

	} elsif ($k =~ /^time$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ISOTime($href->{$k});

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
