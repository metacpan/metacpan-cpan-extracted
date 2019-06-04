#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests-dm5.pl";

Date_Init("TZ=EST");
Date_Init("DeltaSigns=1");

my $tests="

1:2:3:4:5:6:7  => +1:+2:+3:+4:+5:+6:+7

-1:2:3:4:5:6:7 => -1:-2:-3:-4:-5:-6:-7

35x            => ''

+0             => +0:+0:+0:+0:+0:+0:+0

";

$::ti->tests(func  => \&ParseDateDelta,
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
