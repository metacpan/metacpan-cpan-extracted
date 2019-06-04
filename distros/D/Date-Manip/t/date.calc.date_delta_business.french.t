#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj1 = new Date::Manip::Date;
$obj1->config("forcedate","now,America/New_York",
              "language","french");
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

'Mer Nov 20 1996 12h00' 'il y a 3 jour 2 heures professionel' => 1996111510:00:00

'Mer Nov 20 1996 12:00' '5 heure professionel' => 1996112108:00:00

'Mer Nov 20 1996 12:00' '+0:2:0:0 professionel' => 1996112014:00:00

'Mer Nov 20 1996 12:00' '3 jour 2 h professionel' => 1996112514:00:00

";

$::ti->tests(func  => \&test,
             tests => $tests);
$::ti->done_testing();

1;

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
