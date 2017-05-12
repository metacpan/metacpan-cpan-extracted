package Biblio::ILL::ISO::ENUMERATED;

=head1 NAME

Biblio::ILL::ISO::ENUMERATED

=cut

use Biblio::ILL::ISO::ILLASNtype;
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

 Biblio::ILL::ISO::ENUMERATED is a derivation of Biblio::ILL::ISO::ILLASNtype.
 It functions as a base class for any class that needs to handle enumerated types.
 Any derived class must define it's own new() method, in which the list of possible/acceptable
values is defined.

=head1 USES

 None.

=head1 USED IN

 Biblio::ILL::ISO::ConditionalResultsCondition
 Biblio::ILL::ISO::CurrentState
 Biblio::ILL::ISO::ExpiryFlag
 Biblio::ILL::ISO::Flag
 Biblio::ILL::ISO::GeneralProblem
 Biblio::ILL::ISO::ILLAPDUtype
 Biblio::ILL::ISO::ILLServiceType
 Biblio::ILL::ISO::IntermediaryProblem
 Biblio::ILL::ISO::ItemType
 Biblio::ILL::ISO::MediumType
 Biblio::ILL::ISO::MostRecentService
 Biblio::ILL::ISO::PlaceOnHoldType
 Biblio::ILL::ISO::Preference
 Biblio::ILL::ISO::ProtocolVersionNum
 Biblio::ILL::ISO::ReasonLocsProvided
 Biblio::ILL::ISO::ReasonNoReport
 Biblio::ILL::ISO::ReasonNotAvailable
 Biblio::ILL::ISO::ReasonUnfilled
 Biblio::ILL::ISO::ReasonWillSupply
 Biblio::ILL::ISO::ReportSource
 Biblio::ILL::ISO::RequesterCHECKEDIN
 Biblio::ILL::ISO::RequesterSHIPPED
 Biblio::ILL::ISO::ResponderRECEIVED
 Biblio::ILL::ISO::ResponderRETURNED
 Biblio::ILL::ISO::ShippedConditions
 Biblio::ILL::ISO::ShippedServiceType
 Biblio::ILL::ISO::SupplyMediumType
 Biblio::ILL::ISO::TransactionIdProblem
 Biblio::ILL::ISO::TransactionResults
 Biblio::ILL::ISO::TransactionType
 Biblio::ILL::ISO::UnableToPerform

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION

 (as an example of an enumeration) 

 ILL-Service-Type ::= ENUMERATED  {
	loan 	                (1),
	copy-non-returnable 	(2),
	locations 	        (3),
	estimate 	        (4),
	responder-specific 	(5)
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
# Copy this into any derived class, changing the ENUM_LIST....
#---------------------------------------------------------------
=head1

=head2 new( [$enumeration_value] )

This will be overridden in any derived class.

=cut
sub new {
    my $class = shift;
    my $self = {};

    my %ENUM_LIST = ("this" => 1,
		     "is" => 2,
		     "a base" => 3,
		     "class" => 4
		     );
    $self->{"ENUM_LIST"} = %ENUM_LIST;

    if (@_) {
	my $s = shift;
	
	if ( exists $self->{"ENUM_LIST"}->{$s} ) {
	    $self->{"ENUMERATED"} = $self->{"ENUM_LIST"}->{$s};
	} else {
	    croak "invalid enumerated type: [$s]";
	}
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $enumeration_value )

Sets the object's "ENUMERATED" value by doing a lookup of the parameter
in the object's list of valid values.  Croaks on invalid parameter values.

=cut
sub set {
    my $self = shift;
    my $s = shift;

    if ( exists $self->{"ENUM_LIST"}->{$s} ) {
	$self->{"ENUMERATED"} = $self->{"ENUM_LIST"}->{$s};
    } else {
	croak "invalid enumerated type: [$s]";
    }

    return;
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

    return $self->{"ENUMERATED"};
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 as_pretty_string( )

Returns a more-formatted stringified representation of the object.

=cut
sub as_pretty_string {
    my $self = shift;

    return _debug_print($self->{"ENUMERATED"},4);
}

#---------------------------------------------------------------
# This will return a structure usable by Convert::ASN1
#---------------------------------------------------------------
=head1

=head2 as_asn( )

Returns a structure usable by Convert::ASN1.  Generally only called
from the parent's as_asn() method (or encode() method for top-level
message-type objects).

=cut
sub as_asn {
    my $self = shift;

    return $self->{"ENUMERATED"};
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
    my $val = shift;

    my $href = $self->{"ENUM_LIST"};
    my %index = reverse %$href;

    if ( exists $index{$val} ) {
	#print ref($self) . "...$val ($index{$val})\n";
	$self->{"ENUMERATED"} = $val;
    } else {
	croak "from_asn error - invalid " . ref($self) . ": [$val]";
    }
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

=head1 SEE ALSO

See the README for system design notes.
See the parent class(es) for other available methods.
See the derived classes for examples of use.

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
