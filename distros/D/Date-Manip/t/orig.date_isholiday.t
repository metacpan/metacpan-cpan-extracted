#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

sub test {
   my($type,$date) = @_;
   if ($type eq 'scalar') {
      my $ret = Date_IsHoliday($date);
      return $ret;
   } else {
      my @ret = Date_IsHoliday($date);
      return @ret;
   }
}

Date_Init("ForceDate=1997-03-08-12:30:00,America/New_York");
Date_Init("ConfigFile=Holidays.3.cnf");

my $tests ="

scalar 2010-01-01 =>
   'New Years Day (observed)'

list   2010-01-01 =>
   'New Years Day (observed)'
   'New Years Day'

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
