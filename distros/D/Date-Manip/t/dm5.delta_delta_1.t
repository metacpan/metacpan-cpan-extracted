#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests-dm5.pl";

Date_Init("TZ=EST");

my $tests="
1:1:1:1 2:2:2:2 1 => +0:0:0:3:3:3:3

1:1:1:1 2:-1:1:1 1 => +0:0:0:3:0:0:0

1:1:1:1 0:-11:5:6 1 => +0:0:0:0:13:55:55

1:1:1:1 0:-25:5:6 1 => -0:0:0:0:0:4:5

1:1:1:1:1:1:1 2:12:5:2:48:120:120 1 => +4:1:6:5:3:3:1

1:1:1:1:1:1:1 2:12:-1:2:48:120:120 1 => +4:1:-0:3:1:0:59

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
