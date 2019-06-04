#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $dmt = new Date::Manip::TZ;
our $obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

sub test {
   my(@test)=@_;
   my @ret = $obj->days_in_month(@test);
   return @ret;
}

my $tests="

1999 10 => 31

1999 2  => 28

2000 2  => 29

1999 0  => 31 28 31 30 31 30 31 31 30 31 30 31

2000 0  => 31 29 31 30 31 30 31 31 30 31 30 31

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
