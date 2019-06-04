#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests-dm5.pl";

Date_Init("TZ=EST");

sub Test_Normalize {
  my(@args)=@_;
  my($tmp,$err);
  $tmp=ParseDateDelta(@args);
  $tmp=DateCalc("today","+ 1 business days",\$err);
  $tmp=ParseDateDelta(@args);
  return $tmp;
}

my $tests="

+0:0:0:0:9:9:1 => +0:0:0:0:9:9:1

";

$::ti->tests(func  => \&Test_Normalize,
             tests => $tests);
$::ti->done_testing();

#Local Variables:
#mode: cperl
#indent-tabs-mode: nil
#cperl-indent-level: 3
#cperl-continued-statement-offset: 2
#cperl-continued-brace-offset: 0
#cperl-brace-offset: 0
#cperl-brace-imaginary-offset: 0
#cperl-label-offset: 0
#End:
