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
   my @ret = $obj->nth_day_of_week(@test);
   return @ret;
}

my $tests="

1999 1 5    => [ 1999 1 1 ]

1999 7 7    => [ 1999 2 14 ]

1999 -1 6 1 => [ 1999 1 30 ]

1999 -2 6 1 => [ 1999 1 23 ]

1999 3 6 12 => [ 1999 12 18 ]

2029 -1 7 3 => [ 2029 3 25 ]

2029 -3 7 3 => [ 2029 3 11 ]

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
