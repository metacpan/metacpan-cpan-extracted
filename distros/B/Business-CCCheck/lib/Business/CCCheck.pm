package Business::CCCheck;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.10';

use Business::CCCheck::CardID;

use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS @CC_months);
require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
                    @CC_months
                    CC_clean
                    CC_digits
                    CC_format
                    CC_year
                    CC_gen_date
                    CC_is_name
                    CC_is_addr
                    CC_is_zip
                    CC_expired
                    CC_oldtype
                    CC_parity
                    CC_typGeneric
                    CC_typDetail
                    CC_luhn_valid
                   );

our %EXPORT_TAGS = (
                    all	=> [@EXPORT_OK],
                   );

@CC_months = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');

my $n = 3;		# minimum length for a text string or word list

sub CC_expired {
  my ($mon,$yr) = @_;
  return 1 unless $mon && $yr;
  return 1 if
	$mon =~ /\D/ ||
	$yr =~ /\D/;
  return 1 if
	$mon < 1 ||
	$mon > 12;
  my $curyr = &CC_year;
  return 1 if $yr < $curyr;
  if ( $yr == $curyr ) {
    my $curmon = (localtime)[4];
    return ($mon > $curmon) ? undef : 1;
  }
  return undef;
}

sub CC_is_zip {
  my ($zip) = @_;
  return '' unless $zip;
  $zip = sprintf ( "%05d", $zip )
	if (	$zip &&
		$zip =~ /^\d*\.*\d*$/ &&
		$zip ne '.' );
  return ( length($zip) < 5 || $zip =~ /[^0-9a-zA-Z\ \-\.]/o )
	? '' : $zip;
}

sub CC_is_name {
  return '' unless $_[0];
  return ( length($_[0]) < $n ) ? '' : $_[0];
}

sub CC_is_addr {
  my ($addr) = @_;
  return '' unless $addr;
  my $i = 0;
  while ( $addr =~ /\w+/g ) { ++$i; }	# count words
  return ( $i < $n || $addr !~ /\n/ )
	? '' : $addr;
}

sub CC_format {
  my ($ccn) = @_;
  return '' unless $ccn;
  # reformat cc number
  $ccn =~ tr/0-9//cd;
  my @cchars = split(//, $ccn);
  my $i = 0;
  $ccn = '';
  foreach ( 0..$#cchars ) {
    $ccn .= $cchars[$_];
    ++$i;
    if ( $i >= 4 ) {
      $ccn .= ' ';
      $i = 0;
    }
  }  
  return $ccn;
}

sub CC_year {
  return (1900 + (localtime)[5]);
}

sub CC_clean {
  my ($ccn) = @_;
  return '' unless $ccn;
  $ccn =~ tr/\- //d;		# remove blanks and dashes
  return ( $ccn =~ /\D/ ) ? '' : $ccn;
}

#sub CC_id {
#  my ($ccn) = @_;

sub CC_digits {
  my ($ccn) = @_;
  my $type = &CC_oldtype;
  return $type unless $type;
  return (CC_parity($ccn)) ? $type : '';
}  

sub _is_enRoute {
  my ($ccn) = @_;
  return ( grep { $ccn =~ /^$_/ } keys %enRoute ) ?
	'enRoute' : '';
}

sub CC_oldtype {
  my ($ccn) = @_;
  return '' unless $ccn;
  my $i = length($ccn);
  my $type = '';
# determine the card type
  if ( 	$ccn =~ /^51/ ||
	$ccn =~ /^52/ ||
	$ccn =~ /^53/ ||
	$ccn =~ /^54/ ||
	$ccn =~ /^55/ ) {
    $type = 'MasterCard' if $i == 16;
  } elsif 
    (	$ccn =~ /^4/ ) {
    $type = 'VISA' if $i == 13 || $i == 16;
  } elsif 
    (	$ccn =~ /^34/ ||
	$ccn =~ /^37/ ) {
    $type = 'AmericanExpress' if $i == 15;
  } elsif
    (	$ccn =~ /^300/ ||
	$ccn =~ /^301/ ||
	$ccn =~ /^302/ ||
	$ccn =~ /^303/ ||
	$ccn =~ /^304/ ||
	$ccn =~ /^305/ ||
	$ccn =~ /^36/ ||
	$ccn =~ /^38/ ) {
    $type = 'DinersClub/Carteblanche' if $i eq 14;
  } elsif
    (	$ccn =~ /^6011/ ) {
    $type = 'Discover' if $i == 16;
  } elsif
    (_is_enRoute($ccn)) {
    return 'enRoute';		# early exit, type = 'enRoute'
  } elsif
    (	$ccn =~ /^3/ ) {
    $type = 'JCB' if $i == 16;
  } elsif
    (	$ccn =~ /^2131/ ||
	$ccn =~ /^1800/ ) {
    $type = 'JCB' if $i == 15;
  }
  return $type;
}

sub CC_parity {
  my ($ccn) = @_;
  return '' unless $ccn;

  # no parity check for enRoute
  return 1 if _is_enRoute($ccn);

  return CC_luhn_valid($ccn);
}

sub CC_luhn_valid
{
    my $ccn = shift;
    my @ccn = split('', $ccn);
    my $even = 0;

    $ccn = 0;
    for (my $i=$#ccn; $i >=0; --$i) {
        $ccn[$i] *= 2 if $even;
        $ccn -= 9 if $ccn[$i] > 9;
        $ccn += $ccn[$i];
        $even = ! $even;
    }
    return ($ccn % 10) == 0;
}

=head1 NAME

Business::CCCheck - collection of functions for checking credit card numbers

=head1 SYNOPSIS

  use Business::CCCheck qw(
	@CC_months
	CC_year
	CC_expired
	CC_is_zip
	CC_is_name
	CC_is_addr
	CC_clean
	CC_digits
	CC_oldtype
	CC_parity
	CC_typGeneric
	CC_typDetail
	CC_format
  );

=head1 DESCRIPTION

This module checks the validity of the numbers and dates for a credit card
entry, including the parity of the CC number itself.

=over 2

=item @CC_months

An array of 3 character text months. i.e. Jan, Feb....

=item $scalar = CC_year

Returns the localtime calendar year.

=item $scalar = CC_expired(numeric_month,20xx)

Returns true if card is expired or 
month year has bad fromat else false

=item $scalar = CC_is_zip(zipcode);

Check for valid zip code, returns B<false> or the B<zipcode>.

=item $scalar = CC_is_name(name);

Check for a name string greater than three characters.
Return B<false> if short, otherwise return the B<name>.

=item $scalar = CC_is_addr(address);

Check for a string containing at least 3 words and one endline.
Return B<false> if short, otherwise return the B<address>.

=item $scalar = CC_clean(credit_card_number);

Remove blanks and dashes, verify numeric content. Returns B<false> if
invalid characters are present, otherwise the cleaned credit card number.

=item $scalar = CC_digits(credit_card_number);

Pre-process with CC_clean.  

Returns B<false> if the card number fails the check digit match (except for
enRoute which does not require a check digit) otherwise returns exact text
identifying the card issuer that is one of:

    MasterCard
    VISA
    AmericanExpress
    DinersClub/Carteblanche
    Discover
    enRoute
    JCB

Checks number of digits in card number.

=item $scalar = CC_oldtype($credit_card_number);

Performs the number -> name conversion for CC_digits and checks number of
digits in card number.

returns false if it can not convert.

=item $scalar = CC_parity($credit_card_number);

Performs a credit card number parity check for CC_digits.
This is the same as C<CC_luhn_valid()>, apart from for 'enRoute' cards,
which do not have a check digit. For 'enRoute' cards C<CC_parity()>
always returns true.

=item $scalar = CC_luhn_valid($credit_card_number);

Performs a strict LUHN check on a credit card number,
and returns true if the number has a valid check digit,
false otherwise.

=cut

# generic id of credit card number
#
# input:	credit card number,
#		pointer to hash of card prefix's => description
# returns:	description or 'false'
#
sub _typeCheck {
  my ($ccn,$hp) = @_;
#  return '' unless CC_parity($ccn);
  foreach my $key ( sort { $b cmp $a } keys %{$hp} ) {
#print "$key\t=> $hp->{$key}\n";
    if ($ccn =~ /^$key/) {
      return $hp->{$key};
    }
  }
  return '';
}

sub CC_typGeneric {
  my($ccn) = @_;
  return '' unless $ccn;
  my %generic = (%enRoute,%CCprimary);
  return _typeCheck($ccn,\%generic);
}

sub CC_typDetail {
  my ($ccn) = @_;
  return '' unless $ccn;
  my %detail = (%enRoute,%CCprimary,%CCsecondary);
  return _typeCheck($ccn,\%detail);
}

=item $scalar = CC_typGeneric(credit_card_number);

Returns a text string describing the type of credit card or 'false' if no
indentification can be made. Checks if type is in '%enRoute' or
'%CCprimary', similar to B<Card Types> below.

Does NOT check the number of digits in the card number.

=item $scalar = CC_typDetail(credit_card_number);

Returns detailed description of card type as it appears in %CCsecondary,
%CCprimary, %enRoute... or 'false' if the card number can not be identified.

=item $scalar = CC_format(credit_card_number);

Pre-process with CC_clean, CC_digits.

Returns the credit card number as a group of quadruples separated by spaces.
The trailing (right hand) group will contain any remaining non-quad number set.

=back

=head1 HOW IT WORKS

MOD10 Check Digit calculation

Credit Card Validation - Check Digits 

This document outlines procedures and algorithms for Verifying the 
accuracy and validity of credit card numbers. Most credit card numbers 
are encoded with a "Check Digit". A check digit is a digit added to a 
number (either at the end or the beginning) that validates the 
authenticity of the number. A simple algorithm is applied to the other 
digits of the number which yields the check digit. By running the 
algorithm, and comparing the check digit you get from the algorithm 
with the check digit encoded with the credit card number, you can verify 
that you have correctly read all of the digits and that they make a 
valid combination. 

Possible uses for this information: 

	When a user has keyed in a credit card number (or scanned it) 
	and you want to validate it before sending it our for debit 
	authorization. When issuing cards, say an affinity card, you 
	might want to add a check digit using the MOD 10 method. 

LUHN Formula (Mod 10) for Validation of Primary Account Number 

The following steps are required to validate the primary account number:

=over 4

=item Step 1: 

Double the value of alternate digits of the primary account 
number beginning with the second digit from the right (the 
first right--hand digit is the check digit.) 

=item Step 2: 

Add the individual digits comprising the products obtained in 
Step 1 to each of the unaffected digits in the original number. 

=item Step 3: 

The total obtained in Step 2 must be a number ending in zero 
(30, 40, 50, etc.) for the account number to be validated. 

For example, to validate the primary account number 49927398716: 

=over 2

=item Step 1: 

        4 9 9 2 7 3 9 8 7 1 6
         x2  x2  x2  x2  x2 
------------------------------
         18   4   6  16   2


=item Step 2: 

  4 +(1+8)+ 9 + (4) + 7 + (6) + 9 +(1+6) + 7 + (2) + 6 

=item Step 3:

  Sum = 70 : Card number is validated 

=back

=back

Note: Card is valid because the 70/10 yields no remainder.

The validation applied (last known date  3/96)  is the so called
LUHN Formula (Mod 10) for Validation of Primary Account Number
Validation criteria are:

      1. number prefix
      2. number of digits
      3. mod10  (for all but enRoute which uses only 1 & 2)

 ... according to the following list of example criteria:

    Card Type		Prefix		 Length  Check-Digit Algoritm

	MC		51 - 55		   16	   mod 10

	VISA		4		 13, 16	   mod 10

	AMX		34, 37		   15	   mod 10

	Diners Club /	300-305, 36, 38	   14	   mod 10
	Carte Blanche

	Discover	6011		   16	   mod 10

	enRoute		2014, 2149	   16	   - any -

	JCB		3		   16	   mod 10
	JCB		2131, 1800	   15	   mod 10

=head1 COPYRIGHT AND LICENSE

Copyright 2001 - 2011, Michael Robinton E<lt>michael@bizsystems.comE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=head1 AUTHOR

Michael Robinton, E<lt>michael@bizsystems.comE<gt>

=cut

1;
