package Biblio::ILL::ISO::Amount;

=head1 NAME

Biblio::ILL::ISO::Amount

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::AmountString;

use Carp;

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';
#---------------------------------------------------------------------------
# Mods
# 0.02 - 2003.09.07 - fixed the POD
# 0.01 - 2003.07.15 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::Amount is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::AmountString

=head1 USED IN

 Biblio::ILL::ISO::CostInfoType
 Biblio::ILL::ISO::SupplyDetails

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Amount ::= SEQUENCE {
	currency-code	[0]	IMPLICIT PrintableString OPTIONAL, --(SIZE (3))
		-- values defined in ISO 4217-1981
	monetary-value	[1]	IMPLICIT AmountString -- (SIZE (1..10))
	}

=cut

=head1 METHODS

=cut
#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new([$amount_string [, $currency_code] ])

Creates a new Amount object. Expects either no parameters, or
a valid Biblio::ILL::ISO::AmountString and (optionally) a 3-character
string indicating the currency code.

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($monetary_value, $currency_code) = @_;
	
	croak "Missing monetary value" unless ($monetary_value);
	$self->{"monetary-value"} = new Biblio::ILL::ISO::AmountString($monetary_value);
	
	if ($currency_code) {
	    # currency code is optional
	    croak "Invalid currency code" unless ((length $currency_code) == 3);
	    $self->{"currency-code"} = $currency_code if ($currency_code);
	}
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set($amount_string [, $currence_code])

Sets the object's monetary-value (a Biblio::ILL::ISO::AmountString) and (optionally)
currency-code (a 3-character text string).

=cut
sub set {
    my $self = shift;
    my ($monetary_value, $currency_code) = @_;

    croak "Missing monetary value" unless ($monetary_value);
    $self->{"monetary-value"} = new Biblio::ILL::ISO::AmountString($monetary_value);

    if ($currency_code) {
	# currency code is optional
	croak "Invalid currency code" unless ((length $currency_code) == 3);
	$self->{"currency-code"} = $currency_code if ($currency_code);
    }

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

	if ($k =~ /^monetary-value$/) {
	    $self->{$k} = new Biblio::ILL::ISO::AmountString();
	    $self->{$k}->from_asn($href->{$k});
	    
	} elsif ($k =~ /^currency-code$/) {
	    $self->{$k} = $href->{$k};
	    
	} else {
	    croak "invalid " . ref($self) . " element: [$k]";
	}

    }
    return $self;
}

=head1 SEE ALSO

See the README for system design notes.

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
