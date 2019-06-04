#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::TZ;
$obj->config("forcedate","now,America/New_York");

sub test {
   my($alias,$zone)=@_;
   $obj->define_alias("reset");
   $obj->define_alias($alias,$zone);
   return $obj->zone($alias);
}

my $tests="

AAAmerica/New_York America/New_York => America/New_York

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
