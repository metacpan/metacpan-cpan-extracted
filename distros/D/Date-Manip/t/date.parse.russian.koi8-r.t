#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","1997-03-08-12:30:00,America/New_York");
$obj->config("language","Russian","dateformat","nonUS");

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
'\xf3\xe5\xe7\xef\xe4\xee\xf1' => '1997030800:00:00'

'\xda\xc1\xd7\xd4\xd2\xc1' => '1997030900:00:00'

'2 \xcd\xc1\xd1 2012' => 2012050200:00:00

'2 \xed\xe1\xf1 2012' => 2012050200:00:00

";

$::ti->tests(func  => \&test,
             tests => $tests);
$::ti->done_testing();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
