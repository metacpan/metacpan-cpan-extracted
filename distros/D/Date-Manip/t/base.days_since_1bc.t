#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $dmt = new Date::Manip::TZ;
our $obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

sub test {
   my(@test)=@_;
   my @ret = $obj->days_since_1BC(@test);
   return @ret;
}

my $tests="

[ 1 1 1 ]      => 1

[ 2 1 1 ]      => 366

[ 1997 12 10 ] => 729368

[ 1998 12 10 ] => 729733


729368 => [ 1997 12 10 ]

729733 => [ 1998 12 10 ]

1      => [ 1 1 1 ]

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
