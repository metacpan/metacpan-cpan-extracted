#!/usr/bin/perl -w

use strict;
use Test;
use Algorithm::LUHN_XS qw/check_digit check_digit_fast is_valid/;

BEGIN { plan tests => 21 }

# Check some straight-forward, numeric only values
my @values = qw/83764912 8 123456781234567 0 4992739871 6/;
while (@values) {
  my ($v, $expected) = splice @values, 0, 2;
  my $c = check_digit($v);
  ok($c, $expected, "check_digit($v): expected $expected; got $c\n");
  $c = check_digit_fast($v);
  ok($c, $expected, "check_digit_fast($v): expected $expected; got $c\n");
  ok(is_valid("$v$c"));
  ok(!is_valid("$v".(9-$c)));
  ok($Algorithm::LUHN_XS::ERROR, qr/^Check digit/,
   "  Did not get the expected error. Got $Algorithm::LUHN_XS::ERROR\n");

}

# Check a value including alphas (should fail).
my ($v, $c);
$v = 'A2';
ok(!defined($c=check_digit($v)));
$c ||= ''; # make sure $c is defined or we get an "uninit val" warning
ok($Algorithm::LUHN_XS::ERROR, qr/\S/,
   "  Expected an error, but got a check_digit instead: $v => $c\n");
ok($Algorithm::LUHN_XS::ERROR, qr/^Invalid/,
   "  Did not get the expected error. Got $Algorithm::LUHN_XS::ERROR\n");
ok(($c=check_digit_fast($v))==-1);
ok($Algorithm::LUHN_XS::ERROR, qr/\S/,
   "  Expected an error, but got a check_digit instead: $v => $c\n");
ok($Algorithm::LUHN_XS::ERROR, qr/^Invalid/,
   "  Did not get the expected error. Got $Algorithm::LUHN_XS::ERROR\n");

__END__
