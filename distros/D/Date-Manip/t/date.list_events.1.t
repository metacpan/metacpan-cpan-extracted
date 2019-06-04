#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/New_York");
$obj->config("ConfigFile","Events.cnf");
our $obj2 = $obj->new_date();

sub test {
   my($date,$date2)=@_;
   $obj->err(1);
   $obj->parse($date);
   $obj2->parse($date2);

   my @d = $obj->list_events($obj2,"dates");
   my @ret = ();
   foreach my $d (@d) {
      my($x,@name) = @$d;
      my $v = $x->value();
      push(@ret,$v,@name);
   }
   return @ret;
}

my $tests ="

'2000-01-31 12:00:00'
'2000-02-04 00:00:00'
   =>
   2000013112:00:00
   2000020100:00:00
   Event01
   Event03
   2000020112:00:00
   Event01
   Event02
   Event03
   Event04
   2000020113:00:00
   Event01
   Event03
   2000020200:00:00
   2000020313:00:00
   Event05
   2000020314:00:00

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
