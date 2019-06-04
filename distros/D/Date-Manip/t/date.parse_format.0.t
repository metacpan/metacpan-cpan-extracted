#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-12:30:45,America/New_York");

sub test {
   my(@test) = @_;
   my $err = $obj->parse_format(@test);
   if ($err) {
      return $err;
   }
   my $v = $obj->value();
   return $v;
}

my $tests=q{

%Y\\.%m\\-%d
2000.12-13
   =>
   2000121300:00:00

'.*?\\[%d/%b/%Y:%T %z\\].*'
'10.11.12.13 - - [17/Aug/2009:12:33:30 -0400] "GET /favicon.ico ..."'
   =>
   2009081712:33:30

%r
'12:01:02 AM'
   =>
   2000012100:01:02

};

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
