#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::TZ;
$obj->config("forcedate","now,America/New_York");

sub test {
   my($offset,@args) = @_;
   $obj->define_offset("reset");
   my($err,$val) = $obj->define_offset($offset,@args);
   return ($err,$val)  if ($err);
   my @ret = (0);
   push(@ret,$obj->zone($offset,"stdonly"));
   push(@ret,1);
   push(@ret,$obj->zone($offset,"dstonly"));
   return @ret;
}

my $tests="

# +06:30:00;
#    0 => [
#         indian/cocos,
#         asia/colombo,
#         asia/dhaka,
#         asia/kolkata,
#         asia/rangoon,
#         ],
#      1 => [
#         asia/colombo,
#         asia/kolkata,
#         asia/karachi,
#         ],

+06:30:01 std Asia/Colombo Indian/Cocos     => 1 __undef__

+00:09:21 dstonly Europe/Paris              => 2 __undef__

+00:34:39 stdonly Europe/Dublin             => 2 __undef__

+06:30:00 std Asia/Colombo Foo/Bar          => 3 Foo/Bar

+06:30:00 std Asia/Colombo America/New_York => 4 America/New_York

+06:30:00 stdonly Asia/Colombo Asia/Karachi => 5 Asia/Karachi

+06:30:00 dstonly Asia/Colombo Indian/Cocos => 5 Indian/Cocos

+06:30:00:50 std Asia/Colombo               => 9 __undef__

+06:30:00
std
Asia/Colombo
Asia/Dhaka
Asia/Karachi
   =>
   0
   Asia/Colombo
   Asia/Dhaka
   1
   Asia/Colombo
   Asia/Karachi

+06:30:00
stdonly
Asia/Dhaka
Asia/Kolkata
Asia/Yangon
   =>
   5
   Asia/Kolkata
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
