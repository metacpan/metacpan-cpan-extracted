#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $dmt = new Date::Manip::TZ;
our $obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");
$obj->_method("c1890");

sub test {
   my(@test)=@_;
   my @ret = $obj->_fix_year(@test);
   return @ret;
}

my $tests="

99   => 1899

89   => 1989

2000 => 2000

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
