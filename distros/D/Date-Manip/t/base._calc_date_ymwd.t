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
   my @ret = $obj->_calc_date_ymwd(@test);
   return @ret;
}

my $tests="

[ 2009 08 15 ]          [ 0 0 0 5 ]   0 => [ 2009 8 20 ]

[ 2009 08 15 ]          [ 0 0 0 5 ]   1 => [ 2009 8 10 ]

[ 2009 08 15 ]          [ 0 0 1 5 ]   0 => [ 2009 8 27 ]

[ 2009 08 15 ]          [ 0 0 1 5 ]   1 => [ 2009 8 3 ]

[ 2009 08 15 ]          [ 0 3 1 5 ]   0 => [ 2009 11 27 ]

[ 2009 08 15 ]          [ 0 3 1 5 ]   1 => [ 2009 5 3 ]

[ 2009 08 15 ]          [ 2 3 1 5 ]   0 => [ 2011 11 27 ]

[ 2009 08 15 ]          [ 2 3 1 5 ]   1 => [ 2007 5 3 ]

[ 2009 08 15 12 00 00 ] [ 2 3 1 5 ]   0 => [ 2011 11 27 12 00 00 ]

[ 2009 08 15 12 00 00 ] [ 2 3 1 5 ]   1 => [ 2007 5 3 12 00 00 ]

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
