#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/New_York");
$obj->config("use_posix_printf","1");

sub test {
   my(@test)=@_;
   $obj->parse($test[0]);
   return $obj->printf($test[1]);
}

my $tests=q{

'Jan 3, 1996 8:11:12'     %C                     => '19'

'Jan 3, 1996 8:11:12'     %F                     => '1996-01-03'

'Jan 3, 1996 8:11:12'     %l                     => ' 8'

'Jan 3, 1996 8:11:12'     %P                     => 'am'

'Jan 8, 1996 8:11:12'     %u                     => '1'

'Jan 7, 1996 8:11:12'     %u                     => '7'

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
