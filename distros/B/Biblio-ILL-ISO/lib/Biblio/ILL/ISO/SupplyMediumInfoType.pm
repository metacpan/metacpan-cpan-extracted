package Biblio::ILL::ISO::SupplyMediumInfoType;

=head1 NAME

Biblio::ILL::ISO::SupplyMediumInfoType

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::SupplyMediumType;
use Biblio::ILL::ISO::ILLString;

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

Biblio::ILL::ISO::SupplyMediumInfoType is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::SupplyMediumType
 Biblio::ILL::ISO::ILLString

=head1 USED IN

 Biblio::ILL::ISO::SupplyMediumInfoTypeSequence

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Supply-Medium-Info-Type ::= EXPLICIT SEQUENCE {
	supply-medium-type  	[0]	IMPLICIT Supply-Medium-Type,
	medium-characteristics 	[1]	ILL-String OPTIONAL
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $supply_medium_type [, $medium_characteristics] )

 Creates a new SupplyMediumInfoType object. 
 Expects a supply-medium-type (Biblio::ILL::ISO::SupplyMediumType), and
 (optionally) the medium-characteristics (Biblio::ILL::ISO::ILLString).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($stype, $s) = @_;
	
	croak "missing SupplyMediumType" unless ($stype);

	$self->{"supply-medium-type"} = new Biblio::ILL::ISO::SupplyMediumType($stype);
	$self->{"medium-characteristics"} = new Biblio::ILL::ISO::ILLString($s) if ($s);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $supply_medium_type [, $medium_characteristics] )

 Sets the object's supply-medium-type (Biblio::ILL::ISO::SupplyMediumType), and
 (optionally) medium-characteristics (Biblio::ILL::ISO::ILLString).

=cut
sub set {
    my $self = shift;
    my ($stype, $s) = @_;
	
    croak "missing SupplyMediumType" unless ($stype);

    $self->{"supply-medium-type"} = new Biblio::ILL::ISO::SupplyMediumType($stype);
    $self->{"medium-characteristics"} = new Biblio::ILL::ISO::ILLString($s) if ($s);
    
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

	if ($k =~ /^supply-medium-type$/) {
	    $self->{$k} = new Biblio::ILL::ISO::SupplyMediumType();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^medium-characteristics$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString();
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
