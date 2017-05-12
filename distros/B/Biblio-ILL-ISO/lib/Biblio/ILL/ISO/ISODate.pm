package Biblio::ILL::ISO::ISODate;

=head1 NAME

Biblio::ILL::ISO::ISODate

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

Biblio::ILL::ISO::ISODate is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ILLString

=head1 USED IN

 Biblio::ILL::ISO::ConditionalResults
 Biblio::ILL::ISO::DateDue
 Biblio::ILL::ISO::DateTime
 Biblio::ILL::ISO::HistoryReport
 Biblio::ILL::ISO::HoldPlacedResults
 Biblio::ILL::ISO::RetryResults
 Biblio::ILL::ISO::SearchType
 Biblio::ILL::ISO::WillSupplyResults

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLString 
		  Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 ISO-Date ::= VisibleString
	-- conforms to ISO 8601
	-- length = 8
	-- fixed
	-- YYYYMMDD

=cut

#
# NOTE that an ISO-Date _is_not_ an ILL-String!
# ...but I've already got ILLString built, so we'll just
# inherit and tweak...
#

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $datestring )

Creates a new ISODate object. 
 Expects a properly formatted date string (YYYYMMDD).

=cut
sub new {
    my $class = shift;
    my $self = {};

    bless($self, ref($class) || $class);

    if (@_) {
	my $s = shift;
	
	# could use more error checking
	croak "Invalid ISODate length: [$s]" if ((length $s) > 8);
	croak "Invalid ISODate: [$s]" if ($s =~ /\D/);
	$self->SUPER::set($s);  #invoke parent (ie ILLString) 'set'
    }

    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $datestring )

Sets the object's value.
 Expects a properly formatted date string (YYYYMMDD).

=cut
sub set {
    my $self = shift;
    my $s = shift;

    # could use more error checking
    croak "Invalid ISODate length: [$s]" if ((length $s) > 8);
    croak "Invalid ISODate: [$s]" if ($s =~ /\D/);
    $self->SUPER::set($s);  #invoke parent (ie ILLString) 'set'
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

    return $self->{"generalstring"};
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

    print STDERR "##### ISODate as_pretty_string: " . $self->{"generalstring"} . "\n";

    return $self->{"generalstring"};
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

    # DC - debug
    #print "    " . $self->{"generalstring"} . "\n";

    return $self->{"generalstring"};
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
