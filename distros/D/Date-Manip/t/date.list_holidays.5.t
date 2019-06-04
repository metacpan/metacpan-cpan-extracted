#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-01-00:00:00,America/New_York");
$obj->config("ConfigFile","Manip.cnf");
$obj->parse("2010-06-06-12:00:00");

sub test {
   my(@test)=@_;
   my @date = $obj->list_holidays(@test);
   my @ret  = ();
   foreach my $date (@date) {
      my $val = $date->value();
      push(@ret,$val);
   }
   return @ret;
}

my $tests="

   =>
   2010010100:00:00
   2010011800:00:00
   2010021500:00:00
   2010053100:00:00
   2010070500:00:00
   2010090600:00:00
   2010101100:00:00
   2010111100:00:00
   2010112500:00:00
   2010112600:00:00
   2010122400:00:00
   2010123100:00:00

1999
   =>
   1999010100:00:00
   1999011800:00:00
   1999021500:00:00
   1999053100:00:00
   1999060200:00:00
   1999070500:00:00
   1999090600:00:00
   1999101100:00:00
   1999111100:00:00
   1999112500:00:00
   1999112600:00:00
   1999122400:00:00
   1999123100:00:00

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
