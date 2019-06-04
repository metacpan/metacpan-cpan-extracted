#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests-dm5.pl";

Date_Init("TZ=EST");
Date_Init("WorkDayBeg=08:30","WorkDayEnd=17:00");

my $tests="

+1:6:30:30 +1:3:45:45 2 => +0:0:0:3:1:46:15

";

$::ti->tests(func  => \&DateCalc,
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
