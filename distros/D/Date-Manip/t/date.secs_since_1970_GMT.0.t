#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/New_York");

sub test {
   my(@test)=@_;
   $obj->secs_since_1970_GMT(@test);
   my $ret = $obj->value();
   return $ret;
}

my $tests="
881755200  => 1997121007:00:00

944829030  => 1999121007:30:30

1256046697 => 2009102009:51:37

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
