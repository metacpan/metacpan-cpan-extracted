#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj1 = new Date::Manip::Date;
$obj1->config("forcedate","now,America/New_York");
$obj1->config(qw(workdaybeg 09:00:00));
$obj1->config(qw(workdayend 17:30:00));
our $obj2 = $obj1->new_delta();

sub test {
   my(@test)=@_;

   my $err = $obj1->parse(shift(@test));
   return $$obj1{"err"}  if ($err);
   $err = $obj2->parse(shift(@test));
   return $$obj2{"err"}  if ($err);

   my $obj3 = $obj1->calc($obj2,@test);
   return   if (! defined $obj3);
   $err = $obj3->err();
   return $err  if ($err);
   my $ret = $obj3->value();
   return $ret;
}

my $tests="

'Wed Nov 20 1996 noon' 'business +0:5:0:0' => 1996112017:00:00

'Wed Nov 20 1996 noon' 'business +3:7:0:0' => 1996112610:30:00

'Mar 31 1997 16:59:59' 'business + 1 sec' => 1997033117:00:00

'Apr 15 2010 17:12:00' 'business + 2 days' => 2010041917:12:00

'Apr 6 2012 17:25:00' 'business +0:8:15:0' => 2012040917:10:00

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
