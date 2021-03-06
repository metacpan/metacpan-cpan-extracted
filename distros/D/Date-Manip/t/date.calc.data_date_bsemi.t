#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj1 = new Date::Manip::Date;
$obj1->config("forcedate","now,America/New_York");
$obj1->config("ConfigFile","Manip.cnf");
our $obj2 = $obj1->new_date();

sub test {
   my(@test)=@_;

   my $err = $obj1->parse(shift(@test));
   return $$obj1{"err"}  if ($err);
   $err = $obj2->parse(shift(@test));
   return $$obj2{"err"}  if ($err);
   push(@test,"bsemi");

   my $obj3 = $obj1->calc($obj2,@test);
   return   if (! defined $obj3);
   my $ret = $obj3->value();
   return $ret;
}

my $tests="

'Jun 1 1999'                'Jun 4 1999'                  =>  0:0:0:2:0:0:0

'Jun 1 1999'                'Jun 4 1999'               1  =>  0:0:0:-2:0:0:0

'Jun 4 1999'                'Jun 1 1999'                  =>  0:0:0:-2:0:0:0

'Jun 3 1999'                'Jun 8 1999'                  =>  0:0:0:3:0:0:0

'Jun 3 1999'                'Jun 8 1999'               1  =>  0:0:0:-3:0:0:0

'Jun 8 1999'                'Jun 3 1999'                  =>  0:0:0:-3:0:0:0

'Wed Jan 10 1996 noon'      'Wed Feb  7 1996 noon'        =>  0:0:4:0:0:0:0

'Wed Jan 10 1996 noon'      'Wed Feb  7 1996 noon'     1  =>  0:0:-4:0:0:0:0

'Wed Feb  7 1996 noon'      'Wed Jan 10 1996 noon'        =>  0:0:-4:0:0:0:0

'Tue Jan  9 1996 12:00:00'  'Tue Jan  9 1996 14:30:30'     =>  0:0:0:0:2:30:30

'Tue Jan  9 1996 12:00:00'  'Tue Jan  9 1996 14:30:30' 1  =>  0:0:0:0:-2:30:30

'Tue Jan  9 1996 14:30:30'  'Tue Jan  9 1996 12:00:00'    =>  0:0:0:0:-2:30:30

'Tue Jan  9 1996 12:00:00'  'Wed Jan 10 1996 14:30:30'    =>  0:0:0:1:2:30:30

'Tue Jan  9 1996 12:00:00'  'Wed Jan 10 1996 14:30:30' 1  =>  0:0:0:-1:2:30:30

'Wed Jan 10 1996 14:30:30'  'Tue Jan  9 1996 12:00:00'    =>  0:0:0:-1:2:30:30

'Mon Dec 30 1996 noon'      'Mon Jan  6 1997 noon'        =>  0:0:1:0:0:0:0

'Mon Dec 30 1996 noon'      'Mon Jan  6 1997 noon'     1  =>  0:0:-1:0:0:0:0

'Mon Jan  6 1997 noon'      'Mon Dec 30 1996 noon'        =>  0:0:-1:0:0:0:0

'Tue Jan  9 1996 12:00:00'  'Wed Jan 10 1996 10:30:30'    =>  0:0:0:0:7:30:30

'Tue Jan  9 1996 12:00:00'  'Wed Jan 10 1996 10:30:30' 1  =>  0:0:0:0:-7:30:30

'Wed Jan 10 1996 10:30:30'  'Tue Jan  9 1996 12:00:00'    =>  0:0:0:0:-7:30:30

'Wed Jan 10 1996 05:00:00'  'Wed Jan 10 1996 05:00:00'    =>  0:0:0:0:0:0:0

'Wed Jan 10 1996 05:00:00'  'Wed Jan 10 1996 05:00:00' 1  =>  0:0:0:0:0:0:0

'Wed Jan 10 1996 05:00:00'  'Wed Jan 10 1996 10:00:00'    =>  0:0:0:0:2:0:0

'Wed Jan 10 1996 05:00:00'  'Wed Jan 10 1996 20:00:00'    =>  0:0:0:1:0:0:0

'Wed Jan 10 1996 05:00:00'  'Fri Jan 12 1996 05:00:00'    =>  0:0:0:2:0:0:0

'Wed Jan 10 1996 05:00:00'  'Fri Jan 12 1996 10:00:00'    =>  0:0:0:2:2:0:0

'Wed Jan 10 1996 05:00:00'  'Fri Jan 12 1996 20:00:00'    =>  0:0:0:3:0:0:0

'Wed Jan 10 1996 05:00:00'  'Sat Jan 13 1996 12:00:00'    =>  0:0:0:3:0:0:0

'Wed Jan 10 1996 10:00:00'  'Wed Jan 10 1996 10:00:00'    =>  0:0:0:0:0:0:0

'Wed Jan 10 1996 10:00:00'  'Wed Jan 10 1996 20:00:00'    =>  0:0:0:0:7:0:0

'Wed Jan 10 1996 10:00:00'  'Fri Jan 12 1996 05:00:00'    =>  0:0:0:1:7:0:0

'Wed Jan 10 1996 10:00:00'  'Fri Jan 12 1996 10:00:00'    =>  0:0:0:2:0:0:0

'Wed Jan 10 1996 10:00:00'  'Fri Jan 12 1996 20:00:00'    =>  0:0:0:2:7:0:0

'Wed Jan 10 1996 10:00:00'  'Sat Jan 13 1996 12:00:00'    =>  0:0:0:2:7:0:0

'Wed Jan 10 1996 20:00:00'  'Wed Jan 10 1996 20:00:00'    =>  0:0:0:0:0:0:0

'Wed Jan 10 1996 20:00:00'  'Fri Jan 12 1996 05:00:00'    =>  0:0:0:1:0:0:0

'Wed Jan 10 1996 20:00:00'  'Fri Jan 12 1996 10:00:00'    =>  0:0:0:1:2:0:0

'Wed Jan 10 1996 20:00:00'  'Fri Jan 12 1996 20:00:00'    =>  0:0:0:2:0:0:0

'Wed Jan 10 1996 20:00:00'  'Sat Jan 13 1996 12:00:00'    =>  0:0:0:2:0:0:0

'Fri Jan 12 1996 05:00:00'  'Fri Jan 12 1996 05:00:00'    =>  0:0:0:0:0:0:0

'Fri Jan 12 1996 05:00:00'  'Fri Jan 12 1996 10:00:00'    =>  0:0:0:0:2:0:0

'Fri Jan 12 1996 05:00:00'  'Fri Jan 12 1996 20:00:00'    =>  0:0:0:1:0:0:0

'Fri Jan 12 1996 05:00:00'  'Sat Jan 13 1996 12:00:00'    =>  0:0:0:1:0:0:0

'Fri Jan 12 1996 10:00:00'  'Fri Jan 12 1996 10:00:00'    =>  0:0:0:0:0:0:0

'Fri Jan 12 1996 10:00:00'  'Fri Jan 12 1996 20:00:00'    =>  0:0:0:0:7:0:0

'Fri Jan 12 1996 10:00:00'  'Sat Jan 13 1996 12:00:00'    =>  0:0:0:0:7:0:0

'Fri Jan 12 1996 20:00:00'  'Fri Jan 12 1996 20:00:00'    =>  0:0:0:0:0:0:0

'Fri Jan 12 1996 20:00:00'  'Sat Jan 13 1996 12:00:00'    =>  0:0:0:0:0:0:0

'Sat Jan 13 1996 12:00:00'  'Sat Jan 13 1996 12:00:00'    =>  0:0:0:0:0:0:0

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
