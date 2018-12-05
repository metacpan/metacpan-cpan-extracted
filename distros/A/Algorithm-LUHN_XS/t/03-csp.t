#!/usr/bin/perl -w

use strict;
use Test;
use Algorithm::LUHN_XS qw/check_digit check_digit_fast is_valid  valid_chars/;

BEGIN { plan tests => 30 }

# Check some numeric and alphanumeric values

valid_chars(map {$_ => ord($_)-ord('A')+10} 'A'..'Z'); # add a bunch of alphas

my @values = qw/83764912 8 123456781234567 0 4992739871 6
                392690QT 3 035231AH 2 157125AA 3/;
while (@values) {
  my ($v, $expected) = splice @values, 0, 2;
  my $c = check_digit($v);
  ok($c, $expected, "check_digit($v): expected $expected; got $c\n");
  ok(is_valid("$v$c"));
  ok(!is_valid("$v".(9-$c)));
  ok($Algorithm::LUHN_XS::ERROR, qr/^Check digit/,
     "  Did not get the expected error. Got $Algorithm::LUHN_XS::ERROR\n");
}

# Check a value including non-alphanum char (should fail).
my ($v, $c);
$v = '016783A@';
ok(!defined($c=check_digit($v)));
$c ||= ''; # make sure $c is defined or we get an "uninit val" warning
ok($Algorithm::LUHN_XS::ERROR, qr/\S/,
   "  Expected an error, but got a check_digit instead: $v => $c\n");
ok($Algorithm::LUHN_XS::ERROR, qr/^Invalid/,
   "  Did not get the expected error. Got $Algorithm::LUHN_XS::ERROR\n");
ok(($c=check_digit_fast($v))==-1);
$c ||= ''; # make sure $c is defined or we get an "uninit val" warning
ok($Algorithm::LUHN_XS::ERROR, qr/\S/,
   "  Expected an error, but got a check_digit instead: $v => $c\n");
ok($Algorithm::LUHN_XS::ERROR, qr/^Invalid/,
   "  Did not get the expected error. Got $Algorithm::LUHN_XS::ERROR\n");

__END__
