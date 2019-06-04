#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-12:30:00,America/New_York");

sub test {
   my(@test)=@_;
   if ($test[0] eq "config") {
      shift(@test);
      $obj->config(@test);
      return ();
   }

   my $err = $obj->parse(@test);
   if ($err) {
      return $obj->err();
   } else {
      my $d1 = $obj->value();
      my $d2 = $obj->value("gmt");
      return($d1,$d2);
   }
}

my $tests="

'in 3 days' => 2000012412:30:00 2000012417:30:00

'in 3 days at 13:45:00' => 2000012413:45:00 2000012418:45:00

'in 3 days 15 minutes' => 2000012412:45:00 2000012417:45:00

'in 3 days 15 minutes at 13:50' => '[parse] Two times entered or implied'

'in 3 weeks on Monday' => 2000020712:30:00 2000020717:30:00

'in 3 weeks, Monday' => 2000020712:30:00 2000020717:30:00

'in 3 weeks, Sunday' => 2000021312:30:00 2000021317:30:00

'in 3 weeks, Sunday' => 2000021312:30:00 2000021317:30:00

'2 weeks ago, Monday' => 2000010312:30:00 2000010317:30:00

'2 weeks ago, Sunday' => 2000010912:30:00 2000010917:30:00

'2 weeks ago, Sunday at 13:45' => 2000010913:45:00 2000010918:45:00

'in one week' => 2000012812:30:00 2000012817:30:00

'in 3 days PST' => 2000012412:30:00 2000012420:30:00

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
