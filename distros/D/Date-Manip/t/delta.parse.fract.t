#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

my $obj = new Date::Manip::Delta;
$obj->config("forcedate","now,America/New_York");

sub test {
   my(@test)=@_;
   my $err = $obj->parse(@test);
   if ($err) {
      return $obj->err();
   } else {
      my @val = $obj->value();
      return @val;
   }
}

my $tests="

'1.5 days'                => 0 0 0 1 12 0 0

'1.1 years'               => 1 1 0 6 2 5 49

'1.1 years business'      => 1 1 0 4 3 7 59

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
