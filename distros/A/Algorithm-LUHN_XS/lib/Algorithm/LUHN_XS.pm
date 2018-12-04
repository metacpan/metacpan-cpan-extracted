package Algorithm::LUHN_XS;
$Algorithm::LUHN_XS::VERSION = '1.03';
require XSLoader;
XSLoader::load('Algorithm::LUHN_XS', $VERSION);
use 5.006;
use strict;
use warnings;
use Exporter;

our @ISA       = qw/Exporter/;
our @EXPORT    = qw//;
our @EXPORT_OK = qw/check_digit is_valid valid_chars/;
our $ERROR;

# The hash of valid characters.
my %map = map { $_ => $_ } 0..9;
valid_chars(%map);
_al_init_vc(\%map);

=pod

=head1 NAME

Algorithm::LUHN_XS - XS Version of the original Algorithm::LUHN

=head1 SYNOPSIS

  use Algorithm::LUHN_XS qw/check_digit is_valid/;

  $c = check_digit("43881234567");
  print "It works\n" if is_valid("43881234567$c");

  $c = check_digit("A2C4E6G8"); # this will cause an error

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
faster.

The rest of the documentation is a copy of the original docs.

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

sub is_valid {
  my $N = shift;
  my $c = check_digit(substr($N, 0,length($N)-1));
  if (defined $c) {
    if (substr($N,length($N)-1, 1) eq $c) {
      return 1;
    } else {
      $ERROR = "Check digit incorrect. Expected $c";
      return '';
    }
  } else {
    # $ERROR will have been set by check_digit
    return '';
  }
}

=item check_digit NUM

This function returns the checksum of the given number. If it cannot calculate
the check_digit it will return undef and set $Algorithm::LUHN_XS::ERROR to contain
the reason why.

=cut

sub check_digit {
  my $rv=_al_check_digit(shift);
  if ($rv == -1) {
      $ERROR = _al_get_lasterr();
      return;
  } 
  return $rv;
  
}

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
}

=back

=cut

__END__

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

Tim Ayers has also written a
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

Tim Ayers, for the original pure perl version of Algorithm::LUHN

The inspiration for this module was a PerlMonks post I made here:
L<https://perlmonks.org/?node_id=1226543>, and I received help 
from several PerlMonks members:
 
S<    >L<AnomalousMonk|https://perlmonks.org/?node_id=634253>

S<    >L<BrowserUK|https://perlmonks.org/?node_id=171588>

S<    >L<Corion|https://perlmonks.org/?node_id=5348>

S<    >L<LanX|https://perlmonks.org/?node_id=708738>

S<    >L<tybalt89|https://perlmonks.org/?node_id=1172229>

=cut
