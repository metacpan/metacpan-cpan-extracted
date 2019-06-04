#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

my $obj = new Date::Manip::Delta;
$obj->config("forcedate","now,America/New_York");

sub test {
   my (@test)=@_;
   if ($test[0] eq 'reset') {
      $obj->_init();
      return;
   }

   my $err = $obj->set({ @test });
   if ($err) {
      my $val = $obj->err();
      $obj->_init();
      return $val;
   } else {
      my @val = $obj->value();
      return @val;
   }
}

my $tests="

delta
[ 1 2 3 4 5 6 7 ]
Delta
[ 2 3 4 5 6 7 8 ]
   =>
   '[set] Invalid option: delta entered twice'

foo
x
   =>
   '[set] Unknown option: foo'

delta
[ 1 2 3 4 5 6 7 ]
y
1900
   =>
   '[set] Fields set multiple times'

delta
[ 1 2 3 4 5 6 7 ]
standard
[ 2 3 4 5 6 7 8 ]
   =>
   '[set] Fields set multiple times'

standard
[ 2 3 4 5 6 7 8 ]
mode
standard
   =>
   '[set] Mode set multiple times'

standard
8
   =>
   '[set] Option delta requires an array value'

standard
[ 2 3 4 5 6 7 8 9 ]
   =>
   '[set] Delta may contain only 7 fields'

y
[ 1 2 3 4 5 6 7 ]
   =>
   '[set] Option y requires a scalar value'

delta
[ a 2 3 4 5 6 7 ]
   =>
   '[set] Non-numerical field'

y
foo
   =>
   '[set] Option y requires a numerical value'

mode
foo
   =>
   '[set] Unknown value for mode: foo'

type
foo
   =>
   '[set] Unknown value for type: foo'

delta
[ 1.1 2 3 4 5 6 7 ]
type
approx
   =>
   '[set] Type must be estimated for non-integers'

delta
[ 1 2 3 4 5 6 7 ]
type
semi
   =>
   '[set] Type must be approx/estimated'

delta
[ 0 0 3 4 5 6 7 ]
type
exact
   =>
   '[set] Type must be semi/approx/estimated'

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
