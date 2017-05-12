package Biblio::ILL::ISO::UnitsPerMediumType;

=head1 NAME

Biblio::ILL::ISO::UnitsPerMediumType

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::SupplyMediumType;

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

Biblio::ILL::ISO::UnitsPerMediumType is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::SupplyMediumType

=head1 USED IN

 Biblio::ILL::ISO::UnitsPerMediumTypeSequence

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Units-Per-Medium-Type ::= EXPLICIT SEQUENCE {
	medium	        [0]	Supply-Medium-Type,
	no-of-units	[1]	INTEGER -- (1..9999)
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $medium, $no_of_units )

 Creates a new UnitsPerMediumType object. 
 Expects a medium (Biblio::ILL::ISO::SupplyMediumType), and
 a number of units (integer, 1-9999).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($medium, $no_of_units) = @_;

	croak "missing units-per-medium-type medium" unless ($medium);
	croak "invalid units-per-medium-type medium" unless (ref($medium) eq "Biblio::ILL::ISO::SupplyMediumType");

	croak "missing units-per-medium-type no-of-units" unless ($no_of_units);
	croak "invalid units-per-medium-type no-of-units" unless (($no_of_units > 0) && ($no_of_units <= 9999));
	
	$self->{"medium"} = $medium;
	$self->{"no-of-units"} = $no_of_units;
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $medium, $no_of_units )

 Sets the object's medium (Biblio::ILL::ISO::SupplyMediumType), and
 no-of-units (integer, 1-9999).

=cut
sub set {
    my $self = shift;

    my ($medium, $no_of_units) = @_;
    
    croak "missing units-per-medium-type medium" unless ($medium);
    croak "invalid units-per-medium-type medium" unless (ref($medium) eq "Biblio::ILL::ISO::SupplyMediumType");
    
    croak "missing units-per-medium-type no-of-units" unless ($no_of_units);
    croak "invalid units-per-medium-type no-of-units" unless (($no_of_units > 0) && ($no_of_units <= 9999));
    
    $self->{"medium"} = $medium;
    $self->{"no-of-units"} = $no_of_units;
    
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

	if ($k =~ /^medium$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SupplyMediumType();
	    $self->{$k}->from_asn($href->{$k});
	
	} elsif ($k =~ /^no-of-units$/) {
	    $self->{$k} = $href->{$k};

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
