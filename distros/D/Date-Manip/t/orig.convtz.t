#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

sub test {
  return Date_ConvTZ(@_);
}

Date_Init("ForceDate=now,America/New_York");

my $tests="

2001012812:05:00   +0000 BST           => 2001012812:05:00

2001082812:05:00   +0000 BST           => 2001082813:05:00

2001012812:05:00   GMT   +0000         => 2001012812:05:00

2001082812:05:00   GMT   +0000         => 2001082812:05:00

2001012812:05:00   GMT   BST           => 2001012812:05:00

2001082812:05:00   GMT   BST           => 2001082813:05:00

2001012812:05:00   GMT   Europe/London => 2001012812:05:00

2001082812:05:00   GMT   Europe/London => 2001082813:05:00

2007030113:34:34   +0000 +0100         => 2007030114:34:34

2007030113:34:34   +0000 +01:00        => 2007030114:34:34

2007030113:34:34   +0000 +01           => 2007030114:34:34

2007030113:34:34   +0000 -0100         => 2007030112:34:34

2007030113:34:34   +0000 -02:00        => 2007030111:34:34

2007030113:34:34   +0000 -03           => 2007030110:34:34

";

$::ti->tests(func  => \&test,
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
