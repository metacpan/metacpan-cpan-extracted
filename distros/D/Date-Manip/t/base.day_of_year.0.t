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
   my @ret = $obj->day_of_year(@test);
   return @ret;
}

my $tests="

[ 1999 1 1 ]  => 1

[ 1999 1 21 ] => 21

[ 1999 3 1 ]  => 60

[ 2000 3 1 ]  => 61

[ 1980 2 29 ] => 60

[ 1980 3 1 ]  => 61


1999 1  => [ 1999 1 1 ]

1999 21 => [ 1999 1 21 ]

1999 60 => [ 1999 3 1 ]

2000 61 => [ 2000 3 1 ]

1980 60 => [ 1980 2 29 ]

1980 61 => [ 1980 3 1 ]

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
