package Biblio::ILL::ISO::SearchType;

=head1 NAME

Biblio::ILL::ISO::SearchType

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ILLString;
use Biblio::ILL::ISO::ISODate;
use Biblio::ILL::ISO::ExpiryFlag;

use Carp;

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';
#---------------------------------------------------------------------------
# Mods
# 0.02 - 2003.07.17 - new and set were setting dates as ILLStrings, not
#                     ISODates.  Fixed.
# 0.01 - 2003.07.15 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::SearchType is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ILLString;
 Biblio::ILL::ISO::ISODate;
 Biblio::ILL::ISO::ExpiryFlag;

=head1 USED IN

 Biblio::ILL::ISO::Request

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Search-Type ::= SEQUENCE {
	level-of-service	[0]	ILL-String OPTIONAL, -- (SIZE (1))
	need-before-date	[1]	IMPLICIT ISO-Date OPTIONAL,
	expiry-flag	[2]	IMPLICIT ENUMERATED {
				need-Before-Date	(1),
				other-Date 		(2),
				no-Expiry 		(3)
				} -- DEFAULT 3,
				-- value of "need-Before-Date" indicates that
				-- need-before-date also specifies transaction expiry
				-- date
	expiry-date	[3]	IMPLICIT ISO-Date OPTIONAL
		-- alternative expiry date can be used only when expiry-flag
		-- is set to "Other-Date"
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $expiry [,$service_level] [,$need_before] [,$expiry_date] )

Creates a new SearchType object. 
 Expects an expiry-flag string (text string, valid Biblio::ILL::ISO::ExpiryFlag enumerated value),
 (optionally) a service-level (text string),
 (optionally) a need-before-date (Biblio::ILL::ISO::ISODate), and
 (optionally) an expiry-date (Biblio::ILL::ISO::ISODate).

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($expiry, $servicelevel, $needbefore, $expirydate) = @_;

	croak "missing expiry-flag" unless ($expiry);
	if ($servicelevel) {
	    croak "invalid service-level length" unless ((length $servicelevel) == 1);
	}

	$self->{"expiry-flag"} = new Biblio::ILL::ISO::ExpiryFlag($expiry);
	$self->{"level-of-service"} = new Biblio::ILL::ISO::ILLString($servicelevel) if ($servicelevel);
	$self->{"need-before-date"} = new Biblio::ILL::ISO::ISODate($needbefore) if ($needbefore);
	$self->{"expiry-date"} = new Biblio::ILL::ISO::ISODate($expirydate) if ($expirydate);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $expiry [,$service_level] [,$need_before] [,$expiry_date] )

Sets the object's expiry-flag (text string, valid Biblio::ILL::ISO::ExpiryFlag enumerated value),
 (optionally) service-level (text string),
 (optionally) need-before-date (Biblio::ILL::ISO::ISODate), and
 (optionally) expiry-date (Biblio::ILL::ISO::ISODate).

=cut
sub set {
    my $self = shift;
    my ($expiry, $servicelevel, $needbefore, $expirydate) = @_;

    croak "missing expiry-flag" unless ($expiry);
    if ($servicelevel) {
	croak "invalid service-level length" unless ((length $servicelevel) == 1);
    }
    
    $self->{"expiry-flag"} = new Biblio::ILL::ISO::ExpiryFlag($expiry);
    $self->{"level-of-service"} = new Biblio::ILL::ISO::ILLString($servicelevel) if ($servicelevel);
    $self->{"need-before-date"} = new Biblio::ILL::ISO::ISODate($needbefore) if ($needbefore);
    $self->{"expiry-date"} = new Biblio::ILL::ISO::ISODate($expirydate) if ($expirydate);

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

	if ($k =~ /^level-of-service$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString();
	    $self->{$k}->from_asn($href->{$k});

	} elsif (($k =~ /^need-before-date$/)
		 || ($k =~ /^expiry-date$/)
		 ) {
	    print "$k: $href->{$k}\n";
	    $self->{$k} = new Biblio::ILL::ISO::ISODate();
	    $self->{$k}->from_asn($href->{$k});
	    print $self->{$k}->as_string();

	} elsif ($k =~ /^expiry-flag$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ExpiryFlag();
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
=head1

=head2 from_asn($href)

Given a properly formatted hash, builds the object.

=cut

1;
