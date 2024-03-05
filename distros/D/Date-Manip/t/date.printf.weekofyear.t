#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/New_York");

sub test {
   my($op,@test)=@_;
   if ($op eq 'config') {
      $obj->config(@test);
      return 1;
   }
   if ($op eq 'date') {
      $obj->parse(@test);

      my $dmt   = $$obj{'tz'};
      my $dmb   = $$dmt{'base'};
      my $posix = $dmb->_config('use_posix_printf');
      if ($posix) {
         return $obj->printf('%G %g %V %W %L %U %J');
      } else {
         return $obj->printf('%G %W %L %U %J');
      }
   }
}

my $tests=q{

config  use_posix_printf 0 firstday 1 week1ofyear jan4 => 1

date    'Jan 1 1996' => '1996 01 1996 01 1996-W01-1'

date    'Jan 1 1997' => '1997 01 1997 01 1997-W01-3'

date    'Jan 1 2004' => '2004 01 2003 52 2004-W01-4'

date    'Jan 1 2006' => '2005 52 2006 01 2005-W52-7'

config  use_posix_printf 1 firstday 1 week1ofyear jan4 => 1

date    'Jan 1 1996' => '1996 96 01 01 1996 52 1996-W01-1'

date    'Jan 1 1997' => '1997 97 01 52 1997 52 1997-W01-3'

date    'Jan 1 2004' => '2004 04 01 52 2003 52 2004-W01-4'

date    'Jan 1 2006' => '2005 05 52 52 2006 01 2005-W52-7'

};

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
