#!/usr/bin/perl -w
use strict;
use Test;
use Algorithm::LUHN_XS qw/check_digit check_digit_fast check_digit_rff
                          is_valid is_valid_fast is_valid_rff/;

BEGIN { plan tests => 69 }

# Check some straight-forward, numeric only values
my @values = qw/424242424242424 2 83764912 8 123456781234567 0 4992739871 6/;
while (@values) {
  my ($v, $expected) = splice @values, 0, 2;
  my $c = check_digit($v);
  ok($c, $expected, "check_digit($v): expected $expected; got $c\n");
  $c = check_digit_fast($v);
  ok($c, $expected, "check_digit_fast($v): expected $expected; got $c\n");
  $c = check_digit_rff($v);
  ok($c, $expected, "check_digit_rff($v): expected $expected; got $c\n");

  ok(is_valid("$v$expected"));
  ok(!is_valid($v.9-$expected));
  ok($Algorithm::LUHN_XS::ERROR, qr/^Check digit/,
   "  Did not get the expected error. Got $Algorithm::LUHN_XS::ERROR\n");

  ok(is_valid_fast("$v$expected"));
  ok(!is_valid_fast($v.9-$expected));
   
  ok(is_valid_rff("$v$expected"));
  ok(!is_valid_rff($v.9-$expected));
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

# check passing an empty string...should fail
ok( (!defined($c=check_digit(''))));
ok(($c=check_digit_fast(''))==-1);
ok(($c=check_digit_rff(''))==-1);
ok((!is_valid('')));
ok((!is_valid_fast('')));
ok((!is_valid_rff('')));

# check passing one character to is_valid...should fail
ok((!is_valid('1')));
ok((!is_valid_fast('1')));
ok((!is_valid_rff('1')));

# check sending a bunch of nulls
my $nulls="\0\0\0\0\0\0\0";
ok( (!defined($c=check_digit($nulls))));
ok(($c=check_digit_fast($nulls))==-1);
ok(($c=check_digit_rff($nulls))==-1);
ok((!is_valid($nulls)));
ok((!is_valid_fast($nulls)));
ok((!is_valid_rff($nulls)));
# test non-numeric
ok((check_digit_rff("zyx") == -1));
ok((check_digit_rff("\n\n") == -1));
ok((check_digit_fast("\n\n") == -1));
ok(!defined(check_digit("\n\n")));
ok(!is_valid("\n\nzzz"));
ok(!is_valid_fast("\n\nzzz"));
ok(!is_valid_rff("\n\nzzz"));
# Needed for coverage in Devel::Cover
ok(!eval{Algorithm::LUHN_XS::_al_test_croak()});

__END__
