#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops btw/; # strict, warnings, Carp, etc.
use t_TestCommon ':silent', qw/bug $debug t_ok t_is t_like/; # Test2::V0 etc.

use Data::Dumper::Interp;
$Data::Dumper::Interp::Debug = $debug if $debug;

$Data::Dumper::Interp::Foldwidth = 40;

$Data::Dumper::Interp::Useqq .= ":underscores";

for my $left_digit (1..9) {
  my $val = 0;
  my $exp = "$val";
  foreach (1..12) {
    is(vis($val), $exp, "val=$val exp=$exp");
    if ((length($val) % 3) == 0) { # multiple of 3 digits e.g 123, 123456
      $exp = "_${exp}";
    }
    $val = 0 + "${left_digit}${val}";
    $exp = "${left_digit}${exp}";
  }
}

done_testing();
