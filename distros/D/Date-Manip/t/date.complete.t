#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-00:00:00,America/New_York");

sub test {
   my($date,@arg)=@_;

   my $err = $obj->parse($date);
   if ($err) {
      $err = $obj->err();
      return ($obj->value(),$err);
   } else {
      my $d = $obj->value();
      my $c = $obj->complete(@arg);
      return($d,$c);
   }
}

my $tests="

2000-06                  => 2000060100:00:00  0

2000-06-01               => 2000060100:00:00  0

2000-06-01-00:00         => 2000060100:00:00  0

2000-06-01-00:00:00      => 2000060100:00:00  1

2000-06-01-00:00     h   => 2000060100:00:00  1

2000-06-01-00:00     m   => 2000060100:00:00  1

2000-06-01-00:00     s   => 2000060100:00:00  0

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
