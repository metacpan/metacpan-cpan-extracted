#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-01-00:00:00,America/New_York");
$obj->config("ConfigFile","Holidays.3.cnf");

sub test {
   my(@test)=@_;
   my @date = $obj->list_holidays(@test);
   my @ret  = ();
   foreach my $date (@date) {
      my $d = $date->value();
      my @h = $date->holiday();
      foreach my $h (@h) {
         push(@ret,"$d = $h");
      }
   }
   return @ret;
}

my $tests="

2010
   =>
   '2010010100:00:00 = New Years Day (observed)'
   '2010010100:00:00 = New Years Day'
   '2010061700:00:00 = Bunker Hill Day'
   '2010062000:00:00 = Father's Day'
   '2010110200:00:00 = Election Day'
   '2010110200:00:00 = Day of the Dead'
   '2010123100:00:00 = New Years Day (observed)'

2012
   =>
   '2012010100:00:00 = New Years Day'
   '2012010200:00:00 = New Years Day (observed)'
   '2012061700:00:00 = Father's Day'
   '2012061700:00:00 = Bunker Hill Day'
   '2012110200:00:00 = Day of the Dead'
   '2012110600:00:00 = Election Day'

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
