#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

my $obj = new Date::Manip::Delta;
$obj->config("forcedate","now,America/New_York");

sub test {
   my(@args) = @_;
   if (@args == 1) {
      my($type) = @args;
      return $obj->type($type);
   } else {
      my($op,$val) = @args;
      $obj->set($op,$val);
      return 0
   }
}

my $tests="

standard [ 0 0 0 0 1 2 3 ] => 0

business                   => 0

standard                   => 1

exact                      => 1

semi                       => 0

approx                     => 0

###

standard [ 0 0 1 2 1 2 3 ] => 0

business                   => 0

standard                   => 1

exact                      => 0

semi                       => 1

approx                     => 0

###

delta [ 1 0 0 0 1 2 3 ]    => 0

business                   => 0

standard                   => 1

exact                      => 0

semi                       => 0

approx                     => 1

###

business [ 0 0 0 0 1 2 3 ] => 0

business                   => 1

standard                   => 0

exact                      => 1

semi                       => 0

approx                     => 0

###

business [ 0 0 0 1 1 2 3 ] => 0

business                   => 1

standard                   => 0

exact                      => 1

semi                       => 0

approx                     => 0

###

business [ 0 0 1 2 1 2 3 ] => 0

business                   => 1

standard                   => 0

exact                      => 0

semi                       => 1

approx                     => 0

###

delta [ 1 0 0 0 10 20 30 ] => 0

business                   => 0

standard                   => 1

exact                      => 0

semi                       => 0

approx                     => 1

###

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
