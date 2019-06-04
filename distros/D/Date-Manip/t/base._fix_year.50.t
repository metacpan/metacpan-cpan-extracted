#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $dmt = new Date::Manip::TZ;
our $obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");
$obj->_method("50");

sub test {
   my(@test)=@_;
   my @ret = $obj->_fix_year(@test);
   return @ret;
}

sub _y {
   my($yyyy) = @_;
   $yyyy     =~ /^..(..)/;
   my $yy    = $1;
   return($yyyy,$yy);
}

my $y               = ( localtime(time) )[5];
$y                 += 1900;

my($yyyy,$yy)       = _y($y);

my($yyyyM05,$yyM05) = _y($y-5);
my($yyyyP05,$yyP05) = _y($y+5);

my($yyyyM49,$yyM49) = _y($y-49);
my($yyyyM50,$yyM50) = _y($y-50);
my($yyyyM51,$yyM51) = _y($y-51);  $yyyyM51 += 100;

my($yyyyP48,$yyP48) = _y($y+48);
my($yyyyP49,$yyP49) = _y($y+49);
my($yyyyP50,$yyP50) = _y($y+50);  $yyyyP50 -= 100;

my $tests="

$yy     => $yyyy

$yyM05  => $yyyyM05

$yyP05  => $yyyyP05

$yyM49  => $yyyyM49

$yyM50  => $yyyyM50

$yyM51  => $yyyyM51

$yyP48  => $yyyyP48

$yyP49  => $yyyyP49

$yyP50  => $yyyyP50

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
