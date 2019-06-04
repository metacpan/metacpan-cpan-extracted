#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-12:30:45,America/New_York");
$obj->config("language","Romanian","dateformat","nonUS");

sub test {
   my(@test)=@_;
   if ($test[0] eq "config") {
      shift(@test);
      $obj->config(@test);
      return ();
   }

   my $err = $obj->parse(@test);
   if ($err) {
      return $obj->err();
   } else {
      my $d1 = $obj->value();
      return $d1;
   }
}

my $tests="

'marți iunie 8, 2010'   => 2010060800:00:00

'marti iunie 8, 2010'   => 2010060800:00:00

'marþi iunie 8, 2010'   => 2010060800:00:00

'mar\xFEi iunie 8, 2010'   => 2010060800:00:00

'sâmbătă iunie 12, 2010'   => 2010061200:00:00

'duminică iunie 13, 2010'   => 2010061300:00:00

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
