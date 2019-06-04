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
   my @ret = $obj->calc_date_date(@test);
   return @ret;
}

my $tests="

[ 2007 01 15 10 00 00 ] [ 2007 01 15 12 00 00 ] => [ 2 0 0 ]

[ 2007 01 15 12 00 00 ] [ 2007 01 15 10 00 00 ] => [ -2 0 0 ]

[ 2007 01 15 10 30 00 ] [ 2007 01 15 12 15 00 ] => [ 1 45 0 ]

[ 2007 01 15 12 15 00 ] [ 2007 01 15 10 30 00 ] => [ -1 -45 0 ]

[ 2007 01 31 10 00 00 ] [ 2007 02 01 12 00 00 ] => [ 26 0 0 ]

[ 2007 02 01 12 00 00 ] [ 2007 01 31 10 00 00 ] => [ -26 0 0 ]

[ 2007 12 31 10 00 00 ] [ 2008 01 01 12 00 00 ] => [ 26 0 0 ]

[ 2008 01 01 12 00 00 ] [ 2007 12 31 10 00 00 ] => [ -26 0 0 ]

[ 2007 01 15 10 00 00 ] [ 2007 01 17 12 00 00 ] => [ 50 0 0 ]

[ 2007 01 17 12 00 00 ] [ 2007 01 15 10 00 00 ] => [ -50 0 0 ]

[ 2007 01 15 10 30 00 ] [ 2007 01 17 12 15 00 ] => [ 49 45 0 ]

[ 2007 01 17 12 15 00 ] [ 2007 01 15 10 30 00 ] => [ -49 -45 0 ]

[ 2007 01 30 10 00 00 ] [ 2007 02 02 12 00 00 ] => [ 74 0 0 ]

[ 2007 02 02 12 00 00 ] [ 2007 01 30 10 00 00 ] => [ -74 0 0 ]

";

$::ti->tests(func  => \&test,
             tests => $tests);
$::ti->done_testing();

1;

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
