package Algorithm::LUHN_XS;
$Algorithm::LUHN_XS::VERSION = '1.06';
require XSLoader; # uncoverable statement
XSLoader::load('Algorithm::LUHN_XS', $VERSION);
use 5.006;
use strict;
use warnings;
use Exporter;

our @ISA       = qw/Exporter/;
our @EXPORT    = qw//;
our @EXPORT_OK = qw/check_digit check_digit_fast check_digit_rff
                    is_valid  is_valid_fast is_valid_rff
                    valid_chars/;
our $ERROR;

# The hash of valid characters.
my %map = map { $_ => $_ } 0..9;
valid_chars(%map);
_al_init_vc(\%map);

=pod

=head1 NAME

Algorithm::LUHN_XS - Very Fast XS Version of the original Algorithm::LUHN

=head1 SYNOPSIS

  use Algorithm::LUHN_XS qw/check_digit is_valid/;

  my $c;
  $c = check_digit("43881234567");
  print "It works\n" if is_valid("43881234567$c");

  $c = check_digit("A2C4E6G8"); # this will return undef
  if (!defined($c)) {
      # couldn't create a check digit
  }

  print "Valid LUHN characters are:\n";
  my %vc = Algorithm::LUHN_XS::valid_chars();
  for (sort keys %vc) {
    print "$_ => $vc{$_}\n";
  }

  Algorithm::LUHN_XS::valid_chars(map {$_ => ord($_)-ord('A')+10} A..Z);
  $c = check_digit("A2C4E6G8");
  print "It worked again\n" if is_valid("A2C4E6G8$c");

=head1 DESCRIPTION

This module is an XS version of the original Perl Module Algorithm::LUHN, which
was written by Tim Ayers.  It should work exactly the same, only substantially
 faster. The supplied check_digit() routine is 100% compatible with the pure
Perl Algorithm::LUHN module, while the faster check_digit_fast() and really fast
check_digit_rff() are not. 

How much faster? Here's a benchmark, running on a 3.4GHz i7-2600:

C<Benchmark: timing 100 iterations>

C<Algorithm::LUHN: 69 secs (69.37 usr 0.00 sys)  1.44/s>

C<check_digit:      2 secs ( 1.98 usr 0.00 sys) 50.51/s>

C<check_digit_fast: 2 secs ( 1.68 usr 0.00 sys) 59.52/s>

C<check_digit_rff:  1 secs ( 1.29 usr 0.00 sys) 77.52/s>

So, it's 35x to 53x faster than the original pure Perl module, depending on
how much compatibility with the original module you need.  

The rest of the documentation is mostly a copy of the original docs, with some
additions for functions that are new.

This module calculates the Modulus 10 Double Add Double checksum, also known as
the LUHN Formula. This algorithm is used to verify credit card numbers and
Standard & Poor's security identifiers such as CUSIP's and CSIN's.

You can find plenty of information about the algorithm by searching the web for
"modulus 10 double add double".

=head1 FUNCTION

=over 4

=cut

=item is_valid CHECKSUMMED_NUM

This function takes a credit-card number and returns true if
the number passes the LUHN check.

Ie it returns true if the final character of CHECKSUMMED_NUM is the
correct checksum for the rest of the number and false if not. Obviously the
final character does not factor into the checksum calculation. False will also
be returned if NUM contains in an invalid character as defined by
valid_chars(). If NUM is not valid, $Algorithm::LUHN_XS::ERROR will contain the
reason.

This function is equivalent to

  substr $N,length($N)-1 eq check_digit(substr $N,0,length($N)-1)

For example, C<4242 4242 4242 4242> is a valid Visa card number,
that is provided for test purposes. The final digit is '2',
which is the right check digit. If you change it to a '3', it's not
a valid card number. Ie:

    is_valid('4242424242424242');   # true
    is_valid('4242424242424243');   # false

=cut

=item is_valid_fast CHECKSUMMED_NUM
=cut
=item is_valid_rff CHECKSUMMED_NUM

As with check_digit(), we have 3 versions of is_valid(), each one progressively
faster than the check_digit() that comes in the original pure Perl 
Algorithm::LUHN module.  Here's a benchmark of 1M total calls to is_valid():

C<Benchmark: timing 100 iterations>

C<Algorithm::LUHN: 100 secs (100.29 usr 0.01 sys)  1.00/s>

C<is_valid:          3 secs (  2.46 usr 0.11 sys) 38.91/s>

C<is_valid_fast:     2 secs (  2.38 usr 0.05 sys) 41.15/s> 

C<is_valid_rff:      2 secs (  1.97 usr 0.08 sys) 48.78/s>

Algorithm::LUHN_XS varies from 38x to 48x times faster than the original
pure perl Algorithm::LUHN module. The is_valid() routine is 100% compatible
with the original, returning either '1' for success or the empty string ''
for failure.   The is_valid_fast() routine returns 1 for success and 0 for 
failure.  Finally, the is_valid_rff() function also returns 1 for success 
and 0 for failure, but only works with numeric input.  If you supply any 
alpha characters, it will return 0.

=cut

# is_valid is an XS function

=item check_digit NUM

This function returns the checksum of the given number. If it cannot calculate
the check_digit it will return undef and set $Algorithm::LUHN_XS::ERROR to 
contain the reason why.  This is much faster than the check_digit routine
in the pure perl Algorithm::LUHN module, but only about half as fast as
the check_digit_fast() function in this module, due to the need to return both
integers and undef, which isn't fast with XS.

=cut

=item check_digit_fast NUM

This function returns the checksum of the given number. If it cannot calculate
the check digit it will return -1 and set $Algorithm::LUHN_XS::ERROR to 
contain the reason why. It's about 20% faster than check_digit() because the XS
code in this case only has to return integers.

=cut

=item check_digit_rff NUM

This function returns the checksum of the given number. 

It's about 50% faster than check_digit() because it doesn't support the valid_chars() function, and only produces a valid output for numeric input.  If you pass 
it input with alpha characters, it will return -1. Works great for Credit 
Cards, but not for things like L<CUSIP identifiers|https://en.wikipedia.org/wiki/CUSIP>.

=cut

# check_digit, check_digit_fast, and check_digit_rff are XS defined functions

=item valid_chars LIST

By default this module only recognizes 0..9 as valid characters, but sometimes
you want to consider other characters as valid, e.g. Standard & Poor's
identifers may contain 0..9, A..Z, @, #, *. This function allows you to add
additional characters to the accepted list.

LIST is a mapping of C<character> =E<gt> C<value>.
For example, Standard & Poor's maps A..Z to 10..35
so the LIST to add these valid characters would be (A, 10, B, 11, C, 12, ...)

Please note that this I<adds> or I<re-maps> characters, so any characters
already considered valid but not in LIST will remain valid.

If you do not provide LIST,
this function returns the current valid character map.

Note that the check_digit_rff() and is_valid_rff() functions do not support
the valid_chars() function.  Both only support numeric inputs, and map them
to their literal values.

=cut

sub valid_chars {
  return %map unless @_;
  while (@_) {
    my ($k, $v) = splice @_, 0, 2;
    $map{$k} = $v;
  }
  _al_init_vc(\%map);
}


sub _dump_map {
  my %foo = valid_chars();
  my ($k,$v);
  print "$k => $v\n" while (($k, $v) = each %foo);
  return 1;
}

=back

=cut

__END__

=head1 CAVEATS

This module, because of how valid_chars() stores data in the XS portion,
is NOT thread safe.

The _fast and _rff versions of is_valid() and check_digit() don't have the 
same return values for failure as the original Algorithm::LUHN module.
Specifically: 

=over 4

=item * is_valid_fast() and is_valid_rff() return 0 on failure, but
        is_valid() returns the empty string.

=item * check_digit_fast() and check_digit_rff() return -1 on failure, but
        check_digit() returns undef.

=back


=head1 SEE ALSO

L<Algorithm::LUHN> is the original pure perl module this is based on.

L<Algorithm::CheckDigits> provides a front-end to a large collection
of modules for working with check digits.

L<Business::CreditCard> provides three functions for checking credit
card numbers. L<Business::CreditCard::Object> provides an OO interface
to those functions.

L<Business::CardInfo> provides a class for holding credit card details,
and has a type constraint on the card number, to ensure it passes the
LUHN check.

L<Business::CCCheck> provides a number of functions for checking
credit card numbers.

L<Regexp::Common> supports combined LUHN and issuer checking
against a card number.

L<Algorithm::Damm> implements a different kind of check digit algorithm,
the L<Damm algorithm|https://en.wikipedia.org/wiki/Damm_algorithm>
(Damm, not Damn).

L<Math::CheckDigits> implements yet another approach to check digits.

Neil Bowers has also written a
L<review of LUHN modules|http://neilb.org/reviews/luhn.html>,
which covers them in more detail than this section.

=head1 REPOSITORY

L<https://github.com/krschwab/Algorithm-LUHN_XS>

=head1 AUTHOR

This module was written by
Kerry Schwab (http://search.cpan.org/search?author=KSCHWAB).

=head1 COPYRIGHT

Copyright (c) 2018 Kerry Schwab. All rights reserved.
Derived from Algorithm::LUHN, which is (c) 2001 by Tim Ayers.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 CREDITS

Tim Ayers, for the original pure perl version of Algorithm::LUHN.

Neil Bowers, the current maintainer of Algorithm::LUHN.

The inspiration for this module was a PerlMonks post I made here:
L<https://perlmonks.org/?node_id=1226543>, and I received help 
from several PerlMonks members:
 
S<    >L<AnomalousMonk|https://perlmonks.org/?node_id=634253>

S<    >L<BrowserUK|https://perlmonks.org/?node_id=171588>

S<    >L<Corion|https://perlmonks.org/?node_id=5348>

S<    >L<LanX|https://perlmonks.org/?node_id=708738>

S<    >L<tybalt89|https://perlmonks.org/?node_id=1172229>

=cut
