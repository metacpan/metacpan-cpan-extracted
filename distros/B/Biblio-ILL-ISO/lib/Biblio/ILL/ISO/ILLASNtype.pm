package Biblio::ILL::ISO::ILLASNtype;

use Carp;

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.07.15 - original version
#---------------------------------------------------------------------------

# From the ASN
#
#


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub new {
    my $class = shift;
    my $self = {};

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub as_string {
    my $self = shift;

    return "ILLASNtype as_string().... should be virtual!";
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub as_pretty_string {
    my $self = shift;

    return _debug_print($self,4);
}

#---------------------------------------------------------------
# This will return a structure usable by Convert::ASN1
#---------------------------------------------------------------
sub as_asn {
    my $self = shift;

    my %h = ();

    foreach my $key (sort keys %$self) {
	#print "  [$key]\n";
	if ( not ref($self->{$key}) ) {
	    $h{$key} = $self->{$key};
	    #print "    " . $h{$key} . "\n";
	} else {
	    $h{$key} = $self->{$key}->as_asn();
	}
    }

    return \%h;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub from_asn {
    my $self = shift;
    my $href = shift;

    # does nothing

    return $self;
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub _debug_print {
#    my $self = shift;
    my ($ref, $indent) = @_;
    my $s = "";
    $indent = 0 if (not defined($indent));

#    return _debug_print_hash($self) if (not defined $ref);

#    print ">>>" . ref($ref) . "<<<\n";

    return _debug_print_hash($ref, $indent) if (ref($ref) eq "HASH");
    return _debug_print_array($ref, $indent) if (ref($ref) eq "ARRAY");

    for ($i=0; $i < $indent; $i++) {
	$s .= " ";
	#print "."; # DC - debugging
    }
    #print "\n"; # DC - debugging

    return ("$s$ref\n") if (not ref($ref));

    # If it's not any of the above, it is (should be?) an object,
    # which we treat as a hash.  Cheezy, I know - I can't think
    # of a better way.
    return _debug_print_hash($ref, $indent);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub _debug_print_hash {
    my ($href, $indent) = @_;
    my $s = "";
    $indent = 0 if (not defined($indent));

    foreach $key (sort keys %$href) {
	# There's got to be a better way :-)
	for ($i=0; $i < $indent; $i++) {
	    $s .= " ";
	    #print "."; # DC - debugging
	}
	#print "\n"; # DC - debugging

	$s .= "$key ";
	$s .= "=>\n" unless (ref($href->{$key}) eq "HASH");
	$s .= "\n" if (ref($href->{$key}) eq "HASH");
	$s .= "\n" if (ref($href->{$key}) eq "ARRAY");
	$s .= _debug_print($href->{$key}, $indent+4);
    }
    return $s;
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
sub _debug_print_array {
    my ($aref, $indent) = @_;
    my $s = "";
    $indent = 0 if (not defined($indent));

    foreach $elm (@$aref) {
	# There's got to be a better way :-)
	for ($i=0; $i < $indent; $i++) {
	    $s .= " ";
	    #print "."; # DC - debugging
	}
	#print "\n"; # DC - debugging
	$s .= _debug_print($elm, $indent+4);
    }
    return $s;
}

1;



