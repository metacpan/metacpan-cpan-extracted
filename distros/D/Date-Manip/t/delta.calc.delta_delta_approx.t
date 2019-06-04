#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj1 = new Date::Manip::Delta;
$obj1->config("forcedate","now,America/New_York");
our $obj2 = $obj1->new_delta();

sub test {
   my (@test)=@_;

   my $err = $obj1->parse(shift(@test));
   if ($err) {
      return $obj1->err();
   }

   $err = $obj2->parse(shift(@test));
   if ($err) {
      return $obj2->err();
   }

   my $obj3 = $obj1->calc($obj2,@test);
   my $ret  = $obj3->value();
   return $ret;
}

my $tests="

1:1:1:1:1:1:1   2:12:5:2:48:120:120  => 4:1:6:5:3:3:1

1:1:1:1:1:1:1   2:12:-1:2:48:120:120 => 4:1:0:-3:1:0:59

2:3:4:5:6:7:8   1:2:3:4:5:6:7        => 3:5:8:2:11:13:15

2:3:4:5:6:7:8   1:2:3:4:5:6:7 1      => 1:1:1:1:1:1:1

1:1:0:1:1:1:1   2:12:1:2:48:120:120  => 4:1:1:5:3:3:1

1:1:0:1:1:1:1   2:12:0:-2:48:120:120 => 4:1:0:-3:1:0:59

2:3:4:5:6:7:8   1:2:3:4:5:6:7        => 3:5:8:2:11:13:15

2:3:4:5:6:7:8   1:2:3:4:5:6:7 1      => 1:1:1:1:1:1:1

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
