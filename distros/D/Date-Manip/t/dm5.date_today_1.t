#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests-dm5.pl";

Date_Init("TZ=EST");
Date_Init("ForceDate=1997-03-08-12:30:00");
Date_Init("TodayIsMidnight=0","Internal=0");

my $tests="

today => 1997030812:30:00

now => 1997030812:30:00

'today at 4:00' => 1997030804:00:00

'now at 4:00' => 1997030804:00:00

'today week' => 1997031512:30:00

'now week' => 1997031512:30:00

'today week at 4:00' => 1997031504:00:00

'now week at 4:00' => 1997031504:00:00
";

$::ti->tests(func  => \&ParseDate,
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
