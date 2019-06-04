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
   if ($test[0] eq "config") {
      $dmt->config("jan1week1",$test[1]);
      $dmt->config("firstday",$test[2]);
      return 0;
   }
   my @ret = $obj->weeks_in_year(@test);
   return @ret;
}

my $tests="
config 0 1 => 0

2006 => 52

2007 => 52

2002 => 52

2003 => 52

2004 => 53

2010 => 52

2000 => 52


config 0 7 => 0

2006 => 52

2007 => 52

2002 => 52

2003 => 53

2004 => 52

2010 => 52

2000 => 52


config 1 1 => 0

2006 => 53

2007 => 52

2002 => 52

2003 => 52

2004 => 52

2010 => 52

2000 => 53


config 1 7 => 0

2006 => 52

2007 => 52

2002 => 52

2003 => 52

2004 => 52

2010 => 52

2000 => 53

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
