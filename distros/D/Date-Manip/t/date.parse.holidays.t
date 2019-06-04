#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-12:00:00,America/New_York");
$obj->config("ConfigFile","Manip.cnf");

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

'Christmas'               => 2000122500:00:00 2000122505:00:00

'Christmas 2010'          => 2010122400:00:00 2010122405:00:00

'2010 Christmas'          => 2010122400:00:00 2010122405:00:00

'Christmas at noon'       => 2000122512:00:00 2000122517:00:00

'Christmas 2010 at noon'  => 2010122412:00:00 2010122417:00:00

'2010 Christmas at noon'  => 2010122412:00:00 2010122417:00:00

'Mon Christmas'           => 2000122500:00:00 2000122505:00:00

'Tue Christmas'           => '[parse] Day of week invalid'

'Christmas at noon PST'   => 2000122512:00:00 2000122520:00:00

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
