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
   my @ret = $obj->day_of_week(@test);
   return @ret;
}

my $tests="

[ 1999 1 1 12 30 0 ] => 5

[ 1999 1 1 ]  => 5

[ 1999 1 21 ] => 4

[ 1999 3 1 ]  => 1

[ 2004 1 1 ]  => 4

[ 2004 2 2 ]  => 1

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
