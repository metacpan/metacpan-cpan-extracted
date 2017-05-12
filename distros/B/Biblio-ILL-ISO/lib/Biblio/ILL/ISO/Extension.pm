package Biblio::ILL::ISO::Extension;

use Biblio::ILL::ISO::ILLASNtype;

use Carp;

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.08.11 - original version
#---------------------------------------------------------------------------

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

# From the ASN
#
#Extension ::= SEQUENCE {
#	--identifier	[0]	IMPLICIT INTEGER,
#	identifier	[0]	OBJECT IDENTIFIER,
#	critical	[1]	IMPLICIT BOOLEAN, -- DEFAULT FALSE,
#	item		[2]	ANY DEFINED BY identifier
#	--item		[2]	APDU-Delivery-Info
#	}
#
#

#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($identifier, $critical, $item) = @_;

	croak "missing identifier" unless ($identifier);
	croak "missing critical" unless ($critical);
	croak "missing item" unless ($item);

	$self->{"identifier"} = $identifier;
	$self->{"critical"} = $critical;
	$self->{"item"} = $item;
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub set {
    my $self = shift;
    my ($identifier, $critical, $item) = @_;
    
    croak "missing identifier" unless ($identifier);
    croak "missing critical" unless ($critical);
    croak "missing item" unless ($item);
    
    $self->{"identifier"} = $identifier;
    $self->{"critical"} = $critical;
    $self->{"item"} = $item;

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub from_asn {
    my $self = shift;
    my $href = shift;

    foreach my $k (keys %$href) {
	#print ref($self) . "...$k\n";

	if ($k =~ /^identifier$/) {
	    $self->{$k} = $href->{$k};

	} elsif ($k =~ /^critical$/) {
	    $self->{$k} = $href->{$k};

	} elsif ($k =~ /^item$/) {
	    croak "need identifier!" unless ($self->{identifier});
	    $self->{$k} = SelectExtensionType($self->{identifier});

	} else {
	    croak "invalid " . ref($self) . " element: [$k]";
	}

    }
    return $self;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub SelectExtensionType {
    my $id = shift;

    print "+----------------------\n";
    print "| id: $id\n";
    print "+----------------------\n";

    # depending on the $id, create the appropriate type
    # and return it.

    return 1;
}


1;
