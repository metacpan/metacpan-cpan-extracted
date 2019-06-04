#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests-dm5.pl";

Date_Init("TZ=EST");

my $tests="

2001020304:05:06 '+ 2 hours' => 2001020306:05:06

2001020304:05:06 '- 2 hours' => 2001020302:05:06

2001020304:05:06 '+ -2 hours' => 2001020302:05:06

2001020304:05:06 '- -2 hours' => 2001020306:05:06

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
