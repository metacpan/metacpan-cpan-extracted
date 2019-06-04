#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

$::ti->use_ok('Date::Manip::TZdata');

my $obj;
my $moddir = $::ti->testdir('mod');
if ( -d "$moddir/tzdata" ) {
   $obj = new Date::Manip::TZdata($moddir);
} else {
   $::ti->skip_all('No tzdata directory');
}

sub test {
   my(@test)=@_;
   return $obj->_zoneInfo(@test);
}

my $tests="

America/Chicago rules 1800 => - 1

America/Chicago rules 1883 => - 1 US 2

America/Chicago rules 1919 => US 2

America/Chicago rules 1920 => Chicago 2

America/Chicago rules 1936 => Chicago 2 - 1 Chicago 2

Atlantic/Cape_Verde rules 1975 => - 1 - 1

Asia/Tbilisi rules 1996 => E-EurAsia 2 01:00:00 3

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
