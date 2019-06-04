#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/New_York");
$obj->config("printable",1);

sub test {
   my(@test)=@_;
   my $err = $obj->set(@test);
   if ($err) {
      return $obj->err();
   } else {
      my $ret = $obj->value();
      return $ret;
   }
}

my $tests="

date [ 1996 1 1 12 0 0 ]  => 19960101120000

date [ 1996 13 1 12 0 0 ] => '[set] Invalid date argument'

";

$::ti->tests(func  => \&test,
             tests => $tests);
$::ti->done_testing();

1;
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
