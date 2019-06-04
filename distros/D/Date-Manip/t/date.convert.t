#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/New_York");

sub test {
   my($date,$isdst,@test)=@_;
   $obj->_init();
   my $err = $obj->set("date",$date,$isdst);
   $err = $obj->convert(@test) if (! $err);
   if ($err) {
      return $obj->err();
   } else {
      my $d1 = $obj->value();
      return($d1);
   }
}

my $tests="

[ 1985 01 01 00 30 00 ] 0 America/Chicago => 1984123123:30:00

[ 1985 01 01 12 00 00 ] 0 America/Chicago => 1985010111:00:00

[ 1985 04 28 01 00 00 ] 0 America/Chicago => 1985042800:00:00

[ 1985 04 28 03 00 00 ] 0 America/Chicago => 1985042801:00:00

[ 1985 04 28 03 30 00 ] 0 America/Chicago => 1985042801:30:00

[ 1985 04 28 04 00 00 ] 0 America/Chicago => 1985042803:00:00

[ 1985 10 27 00 30 00 ] 0 America/Chicago => 1985102623:30:00

[ 1985 10 27 01 00 00 ] 1 America/Chicago => 1985102700:00:00

[ 1985 10 27 01 30 00 ] 1 America/Chicago => 1985102700:30:00

[ 1985 10 27 01 00 00 ] 0 America/Chicago => 1985102701:00:00

[ 1985 10 27 01 30 00 ] 0 America/Chicago => 1985102701:30:00

[ 1985 10 27 02 00 00 ] 0 America/Chicago => 1985102701:00:00

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
