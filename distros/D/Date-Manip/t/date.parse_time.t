#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-01:02:03, America/New_York");

sub test {
   my(@test)=@_;
   if ($test[0] eq "config") {
      shift(@test);
      $obj->config(@test);
      return ();
   }

   $obj->_init();
   my $err = $obj->parse_time(@test);
   if ($err) {
      return $obj->err();
   } else {
      my $d1 = $obj->value();
      return $d1;
   }
}

my $tests="

# Times

17:30:15 => 2000012117:30:15

'17:30:15 AM' => '[parse_time] Invalid time string'

'5:30:15 PM' => 2000012117:30:15

5:30:15 => 2000012105:30:15

17:30:15.25 => 2000012117:30:15

17:30:15,25 => 2000012117:30:15

'17:30:15.25 AM' => '[parse_time] Invalid time string'

'5:30:15.25 PM' => 2000012117:30:15

'5:30:15,25 PM' => 2000012117:30:15

5:30:15.25 => 2000012105:30:15

17:30.25 => 2000012117:30:15

'17:30.25 AM' => '[parse_time] Invalid time string'

'5:30.25 PM' => 2000012117:30:15

5:30.25 => 2000012105:30:15

17.5 => 2000012117:30:00

17,5 => 2000012117:30:00

'17.5 AM' => '[parse_time] Invalid time string'

'5.5 PM' => 2000012117:30:00

5.5 => 2000012105:30:00

17:30 => 2000012117:30:00

'17:30 AM' => '[parse_time] Invalid time string'

'5:30 PM' => 2000012117:30:00

5:30 => 2000012105:30:00

midnight => 2000012100:00:00

5:30 => 2000012105:30:00

5:30:02 => 2000012105:30:02

15:30:00 => 2000012115:30:00

5pm => 2000012117:00:00

123015 => 2000012112:30:15

'24:00' => 2000012100:00:00

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
