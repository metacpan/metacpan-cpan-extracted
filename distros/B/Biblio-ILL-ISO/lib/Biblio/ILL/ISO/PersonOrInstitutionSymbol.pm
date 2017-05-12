package Biblio::ILL::ISO::PersonOrInstitutionSymbol;

=head1 NAME

Biblio::ILL::ISO::PersonOrInstitutionSymbol

=cut

use Biblio::ILL::ISO::ILLASNtype;
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

Biblio::ILL::ISO::PersonOrInstitutionSymbol is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ILLString

=head1 USED IN

 Biblio::ILL::ISO::SystemId

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Person-Or-Institution-Symbol ::= CHOICE {
	person-symbol	        [0]	ILL-String,
	institution-symbol	[1]	ILL-String
	}

=cut

=head1 METHODS

=cut
#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [$institution_symbol] )

Creates a new PersonOrInstitutionSymbol object. 
 Expects either no paramaters, or
 an institution-symbol (text string).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) { 
	$self->{"institution-symbol"} = new Biblio::ILL::ISO::ILLString(shift); 
    }
    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 as_string( )

Returns a stringified representation of the object.

=cut
sub as_string {
    my $self = shift;

    return $self->{"person-symbol"}->as_string() if ($self->{"person-symbol"});
    return $self->{"institution-symbol"}->as_string() if ($self->{"institution-symbol"});
    return "";
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

	if ($k =~ /^person-symbol$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^institution-symbol$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString();
	    $self->{$k}->from_asn($href->{$k});

	} else {
	    croak "invalid " . ref($self) . " element: [$k]";
	}

    }
    return $self;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_person_symbol( $s )

 Sets the object's person-symbol.
 Expects a text string.

=cut
sub set_person_symbol {
    my $self = shift;
    my ($s) = @_;

    $self->{"person-symbol"} = new Biblio::ILL::ISO::ILLString($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_institution_symbol( $s )

 Sets the object's institution-symbol.
 Expects a text string.

=cut
sub set_institution_symbol {
    my $self = shift;
    my ($s) = @_;

    $self->{"institution-symbol"} = new Biblio::ILL::ISO::ILLString($s);

    return;
}


1;
