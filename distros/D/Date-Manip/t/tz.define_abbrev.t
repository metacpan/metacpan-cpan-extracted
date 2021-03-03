#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::TZ;
$obj->config("forcedate","now,America/New_York");

sub test {
   my($abbrev,@zone)=@_;
   $obj->define_abbrev("reset");
   $obj->define_abbrev($abbrev,@zone);
   return $obj->zone($abbrev);
}

my $tests="

EWT reset =>
   America/New_York
   America/Detroit
   America/Iqaluit
   America/Nassau
   America/Nipigon
   America/Thunder_Bay
   America/Toronto

EWT
America/New_York
America/Iqaluit
America/Thunder_Bay
   =>
   America/New_York
   America/Iqaluit
   America/Thunder_Bay
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
