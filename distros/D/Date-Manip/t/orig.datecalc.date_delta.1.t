#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

sub test {
   my($d1,$d2) = (@_);
   DateCalc($d1,$d2);
}

Date_Init("ForceDate=1997-03-08-12:30:00,America/New_York");
Date_Init("ConfigFile=Manip.cnf");
Date_Init("WorkDayBeg=08:30","WorkDayEnd=17:00");

my $tests="

'Wed Nov 20 1996 noon' '+0:5:0:0 business' => 1996112108:30:00

'Wed Nov 20 1996 noon' '+3:7:0:0 business' => 1996112610:30:00

'Mar 31 1997 16:59:59' '+ 1 sec business'  => 1997040108:30:00

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
