#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/New_York");
$obj->config(qw(Jan1Week1 1));

sub test {
   my($date,$first) = @_;
   $obj->set("date",$date);
   return $obj->week_of_year($first);
}

my $tests="

# Date, FirstDate

[ 2005 01 01 00 00 00 ] 7 => 1

[ 2005 01 06 00 00 00 ] 7 => 2

[ 2005 12 23 00 00 00 ] 7 => 52

[ 2005 12 28 00 00 00 ] 7 => 53

[ 2005 01 01 00 00 00 ] 1 => 1

[ 2005 01 06 00 00 00 ] 1 => 2

[ 2005 12 23 00 00 00 ] 1 => 52

[ 2005 12 28 00 00 00 ] 1 => 53

[ 2005 12 29 00 00 00 ] 1 => 53

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
