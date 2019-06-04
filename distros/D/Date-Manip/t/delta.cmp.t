#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj1 = new Date::Manip::Delta;
our $obj2 = $obj1->new_delta();

sub test {
   my(@test)=@_;
   $obj1->parse($test[0]);
   $obj2->parse($test[1]);
   return $obj1->cmp($obj2);
}

my $tests="

0:0:0:0:-1:0:0   0:0:0:0:1:0:0   => -1

0:0:0:0:1:0:0    0:0:0:0:-1:0:0  => 1

0:0:0:0:1:0:0    0:0:0:0:0:60:0  => 0

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
