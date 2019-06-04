#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests-dm5.pl";

Date_Init("TZ=EST");

my $tests="

'Jan 1, 1996 at 10:30' 12:40 => 1996010112:40:00

1996010110:30:40 12:40:50 => 1996010112:40:50

1996010110:30:40 12:40 => 1996010112:40:00

1996010110:30:40 12 40 => 1996010112:40:00

1996010110:30:40 12 40 50 => 1996010112:40:50

";

$::ti->tests(func  => \&Date_SetTime,
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
