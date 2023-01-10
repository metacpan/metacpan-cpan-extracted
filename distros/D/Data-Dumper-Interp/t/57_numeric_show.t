#!/usr/bin/perl
use strict; use warnings  FATAL => 'all'; use feature qw(state say); use utf8;
#use open IO => ':locale';
use open ':std', ':encoding(UTF-8)';
STDOUT->autoflush();
STDERR->autoflush();
select STDERR;

#
# Verify that internal function _show_as_number() distinguishes numerics
# from strings which look like numbers, e.g. "0", and various corner cases.
#

use Test::More;
use Data::Dumper::Interp;
use Scalar::Util qw(blessed);
use Carp;

require Math::BigInt;
require Math::BigFloat;
require Math::BigRat;

my $inf = 9**9**9;
my $nan = -sin($inf);
my $minf = -$inf;

sub fmt($) {
  my $value = shift;
  return "undef" unless defined($value);
  my $pfx = blessed($value) ? "(".blessed($value).")" : "";
  if (defined($value) && $value eq "") {
    return $pfx . "«${value}»";
  } else {
    return $pfx . u($value)
  }
}

my $n_count = 0;
my $s_count = 0;
sub check_numeric($$) {
  my ($value, $expected) = @_;
  my $san = Data::Dumper::Interp::_show_as_number($value);
  my $desc = ($expected ? "numeric ".fmt($value) : "non-number ".Data::Dumper::Interp::_dbvis($value));
  ok( (!!$san == !!$expected), $desc );
}

diag "=== prelim checks ===";

check_numeric("mumble", 0);
check_numeric("-1",     0);

diag "=== numerics ===";
for my $v (-1, 0, 1, 42, $nan, $inf, $minf) {
  for my $value ($v,
                 Math::BigInt->new("$v"),
                 Math::BigFloat->new("$v"),
                 Math::BigRat->new("$v")) {
    check_numeric($value, 1);
  }
}
check_numeric(Math::BigRat->new("17/27"), 1);
check_numeric(Math::BigRat->new("-17/27"), 1);

diag "=== undef ===";
check_numeric(undef, 0);

diag "=== strings ===";
for my $value ("", "-1", "0", "00", "001", "1", "42", "19/37",
               (map{ chr($_) } (0..260)),
               (map{ "0".chr($_) } (0..260)),
               (map{ "-1".chr($_) } (0..260)),
              ) {
  check_numeric($value, 0);
}

done_testing();

#say "Checked $n_count numerics and $s_count strings";

exit 0;
