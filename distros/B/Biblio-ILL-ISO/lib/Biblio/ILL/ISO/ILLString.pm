package Biblio::ILL::ISO::ILLString;

use Biblio::ILL::ISO::ILLASNtype;
use Carp;

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.07.15 - original version
#---------------------------------------------------------------------------

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

# From the ASN
#
#ILL-String ::= CHOICE {
#	generalstring	GeneralString,
#	-- may contain any ISO registered G (graphic) and C
#	-- (control) character set
#	edifactstring	EDIFACTString
#	}
#	-- may not include leading or trailing spaces
#	-- may not consist only of space (" ") or non-printing 
#	-- characters


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	$self->{"generalstring"} = shift;
    }
    bless($self, ref($class) || $class);
    return ($self);
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub set {
    my $self = shift;
    my ($s) = @_;

    $self->{generalstring} = $s;
    return;
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub set_general {
    my $self = shift;
    my ($s) = @_;

    $self->{generalstring} = $s;
    return;
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub set_edifact {
    my $self = shift;
    my ($s) = @_;

    $self->{EDIFACTstring} = $s;
    return;
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub as_string {
    my $self = shift;

    return $self->{generalstring} if ($self->{generalstring});
    return $self->{EDIFACTstring} if ($self->{EDIFACTstring});
    return "";
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub from_asn {
    my $self = shift;
    my $href = shift;

    foreach my $k (keys %$href) {
	#print ref($self) . "...$k\n";

	if (($k =~ /^generalstring$/)
	    || ($k =~ /^edifactstring$/)
	    ) {
	    #print "  $href->{$k}\n";
	    $self->{$k} = $href->{$k};

	} else {
	    croak "invalid " . ref($self) . " element: [$k]";
	}

    }
    return $self;
}

1;
