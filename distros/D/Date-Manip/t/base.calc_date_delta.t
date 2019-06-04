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
   my @ret = $obj->calc_date_delta(@test);
   return @ret;
}

my $tests="

[ 2009 08 15 12 00 00 ] [ 0 0 0 5 1 0 0 ] 0 => [ 2009 8 20 13 0 0 ]

[ 2009 08 15 12 00 00 ] [ 0 0 0 5 1 0 0 ] 1 => [ 2009 8 10 11 0 0 ]

[ 2009 08 15 12 00 00 ] [ 0 0 1 5 1 0 0 ] 0 => [ 2009 8 27 13 0 0 ]

[ 2009 08 15 12 00 00 ] [ 0 0 1 5 1 0 0 ] 1 => [ 2009 8 3 11 0 0 ]

[ 2009 08 15 12 00 00 ] [ 0 3 1 5 1 0 0 ] 0 => [ 2009 11 27 13 0 0 ]

[ 2009 08 15 12 00 00 ] [ 0 3 1 5 1 0 0 ] 1 => [ 2009 5 3 11 0 0 ]

[ 2009 08 15 12 00 00 ] [ 2 3 1 5 1 0 0 ] 0 => [ 2011 11 27 13 0 0 ]

[ 2009 08 15 12 00 00 ] [ 2 3 1 5 1 0 0 ] 1 => [ 2007 5 3 11 0 0 ]

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
