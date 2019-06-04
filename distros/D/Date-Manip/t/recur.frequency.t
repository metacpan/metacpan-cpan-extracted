#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

my $obj = new Date::Manip::Recur;
$obj->config("forcedate","2000-01-21-00:00:00,America/New_York");

sub test {
   my (@test)=@_;
   my $err = $obj->frequency(@test);
   if ($err) {
      return $obj->err();
   } else {
      my @ret = @{ $$obj{"data"}{"interval"} };
      push(@ret,"*");
      foreach my $v (@{ $$obj{"data"}{"rtime"} }) {
         my $str = "";
         foreach my $v2 (@$v) {
            $str .= ","  if ($str ne "");
            if (ref($v2)) {
               my($x,$y) = @$v2;
               $str .= "$x-$y";
            } else {
               $str .= "$v2";
            }
         }
         push(@ret,$str);
      }
      return @ret;
   }
}

my $tests="

1:2:3:4:5:6
   => '[frequency] Invalid frequency string'

+1:2:3:4:5:6:7
   => '[frequency] Invalid frequency string'

1:2:3*--4:5:6:7
   => '[frequency] Invalid rtime string'

1:2:3*4-3:5:6:7
   => '[frequency] Invalid rtime range string'

1:2*-1--3:0:5-8,11:1:7
   => '[frequency] Invalid rtime range string'

-1*2:3:4:5:6:7
   => '[frequency] Invalid frequency string'

1:2:-3*4:5:6:7
   => '[frequency] Invalid frequency string'

##############

1:2:3:4:5:6:7 => 1 2 3 4 5 6 7 *

1:02:3:4:5:6:7 => 1 2 3 4 5 6 7 *

1:2:0*0:5:6:7 => 1 2 * 0 0 5 6 7

0:0:0*4:5:6:7 => 0 0 1 * 4 5 6 7

1:2:0:0*5,8:6:7 => 1 2 0 0 * 5,8 6 7

1:2:0:0*5-5,8:6:7 => 1 2 0 0 * 5,8 6 7

1:2:0:0*05,8:6:7 => 1 2 0 0 * 5,8 6 7

1:2:0:0*5-8,11:6:7 => 1 2 0 0 * 5,6,7,8,11 6 7

1:2:0*0:5-8,11:6:7 => 1 2 * 0 0 5,6,7,8,11 6 7

1:2*-3--1:0:5-8,11:1:7 => 1 2 * -3,-2,-1 0 5,6,7,8,11 1 7

1:2*2--2:0:5-8,11:1:7 => 1 2 * 2--2 0 5,6,7,8,11 1 7

*0:2:0:3:0:0:0 => * 0 2 0 3 0 0 0

##############

#
# 1:2:3:4
#

1:2:3:4:5:6:7 => 1 2 3 4 5 6 7 *

1:-2:3:4:5:6:7
   => '[frequency] Invalid frequency string'

#
# 1:2:3*4
#

1:2:3*4:5:6:7 => 1 2 3 * 4 5 6 7

1:2:3*8:5:6:7
   => '[frequency] Day of week must be 1-7'

1:2:3*-1:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# 1:0:3*4
#

1:0:3*4:5:6:7 => 1 0 3 * 4 5 6 7

1:0:3*8:5:6:7
   => '[frequency] Day of week must be 1-7'

1:0:3*-1:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# 0:2:3*4
#

0:2:3*4:5:6:7 => 0 2 3 * 4 5 6 7

0:2:3*8:5:6:7
   => '[frequency] Day of week must be 1-7'

0:2:3*-1:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# 0:0:3*4
#

0:0:3*4:5:6:7 => 0 0 3 * 4 5 6 7

0:0:3*8:5:6:7
   => '[frequency] Day of week must be 1-7'

0:0:3*-1:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# 1:2*3:4
#

1:2*3:4:5:6:7 => 1 2 * 3 4 5 6 7

1:2*-3:4:5:6:7 => 1 2 * -3 4 5 6 7

1:2*-8:4:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

1:2*8:4:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

1:2*3:-4:5:6:7
   => '[frequency] Day of week must be 1-7'

1:2*3:8:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# 0:2*3:4
#

0:2*3:4:5:6:7 => 0 2 * 3 4 5 6 7

0:2*-3:4:5:6:7 => 0 2 * -3 4 5 6 7

0:2*-8:4:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

0:2*8:4:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

0:2*3:-4:5:6:7
   => '[frequency] Day of week must be 1-7'

0:2*3:8:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# 1*2:3:4
#

1*2:3:4:5:6:7 => 1 * 2 3 4 5 6 7

1*-1:3:4:5:6:7
   => '[frequency] Month of year must be 1-12'

1*13:3:4:5:6:7
   => '[frequency] Month of year must be 1-12'

1*2:-1:4:5:6:7 => 1 * 2 -1 4 5 6 7

1*2:-6:4:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

1*2:6:4:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

1*2:3:-1:5:6:7
   => '[frequency] Day of week must be 1-7'

1*2:3:8:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# 0*2:3:4
#

0*2:3:4:5:6:7 => 1 * 2 3 4 5 6 7

0*-1:3:4:5:6:7
   => '[frequency] Month of year must be 1-12'

0*13:3:4:5:6:7
   => '[frequency] Month of year must be 1-12'

0*2:-1:4:5:6:7 => 1 * 2 -1 4 5 6 7

0*2:-6:4:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

0*2:6:4:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

0*2:3:-1:5:6:7
   => '[frequency] Day of week must be 1-7'

0*2:3:8:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# *1:2:3:4
#

*1:2:3:4:5:6:7 => * 1 2 3 4 5 6 7

*-100:2:3:4:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*12345:2:3:4:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*1:-1:3:4:5:6:7
   => '[frequency] Month of year must be 1-12'

*1:13:3:4:5:6:7
   => '[frequency] Month of year must be 1-12'

*1:2:-1:4:5:6:7 => * 1 2 -1 4 5 6 7

*1:2:-6:4:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

*1:2:6:4:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

*1:2:3:-1:5:6:7
   => '[frequency] Day of week must be 1-7'

*1:2:3:8:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# *0:2:3:4
#

*0:2:3:4:5:6:7 => * 0 2 3 4 5 6 7

*0:-1:3:4:5:6:7
   => '[frequency] Month of year must be 1-12'

*0:13:3:4:5:6:7
   => '[frequency] Month of year must be 1-12'

*0:2:-1:4:5:6:7 => * 0 2 -1 4 5 6 7

*0:2:-6:4:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

*0:2:6:4:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

*0:2:3:-1:5:6:7
   => '[frequency] Day of week must be 1-7'

*0:2:3:8:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# 1:0*3:4
#

1:0*3:4:5:6:7 => 1 * 0 3 4 5 6 7

1:0*-3:4:5:6:7 => 1 * 0 -3 4 5 6 7

1:0*63:4:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

1:0*-63:4:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

1:0*3:-4:5:6:7
   => '[frequency] Day of week must be 1-7'

1:0*3:8:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# 1*0:3:4
#

1*0:3:4:5:6:7 => 1 * 0 3 4 5 6 7

1*0:-3:4:5:6:7 => 1 * 0 -3 4 5 6 7

1*0:63:4:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

1*0:-63:4:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

1*0:3:-4:5:6:7
   => '[frequency] Day of week must be 1-7'

1*0:3:8:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# *1:0:3:4
#

*1:0:3:4:5:6:7 => * 1 0 3 4 5 6 7

*-100:0:3:4:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*12345:0:3:4:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*1:0:-3:4:5:6:7 => * 1 0 -3 4 5 6 7

*1:0:63:4:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

*1:0:-63:4:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

*1:0:3:-4:5:6:7
   => '[frequency] Day of week must be 1-7'

*1:0:3:8:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# 0*0:3:4
#

0*0:3:4:5:6:7 => 1 * 0 3 4 5 6 7

0*0:-3:4:5:6:7 => 1 * 0 -3 4 5 6 7

0*0:63:4:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

0*0:-63:4:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

0*0:3:-4:5:6:7
   => '[frequency] Day of week must be 1-7'

0*0:3:8:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# *0:0:3:4
#

*0:0:3:4:5:6:7 => * 0 0 3 4 5 6 7

*0:0:-3:4:5:6:7 => * 0 0 -3 4 5 6 7

*0:0:63:4:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

*0:0:-63:4:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

*0:0:3:-4:5:6:7
   => '[frequency] Day of week must be 1-7'

*0:0:3:8:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# 0:0*3:4
#

0:0*3:4:5:6:7 => 0 1 * 3 4 5 6 7

0:0*-3:4:5:6:7 => 0 1 * -3 4 5 6 7

0:0*-8:4:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

0:0*8:4:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

0:0*3:-4:5:6:7
   => '[frequency] Day of week must be 1-7'

0:0*3:8:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# 1:2:0*4 
#

1:2:0*4:5:6:7 => 1 2 * 0 4 5 6 7

1:2:0*-1:5:6:7 => 1 2 * 0 -1 5 6 7

1:2:0*33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

1:2:0*-33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

#
# 1:2*0:4
#

1:2*0:4:5:6:7 => 1 2 * 0 4 5 6 7

1:2*0:-1:5:6:7 => 1 2 * 0 -1 5 6 7

1:2*0:33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

1:2*0:-33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

#
# 1*2:0:4
#

1*2:0:4:5:6:7 => 1 * 2 0 4 5 6 7

1*-1:0:4:5:6:7
   => '[frequency] Month of year must be 1-12'

1*13:0:4:5:6:7
   => '[frequency] Month of year must be 1-12'

1*2:0:-1:5:6:7 => 1 * 2 0 -1 5 6 7

1*2:0:-33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

1*2:0:33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

#
# *1:2:0:4
#

*1:2:0:4:5:6:7 => * 1 2 0 4 5 6 7

*-1:2:0:4:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*12345:2:0:4:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*1:-1:0:4:5:6:7
   => '[frequency] Month of year must be 1-12'

*1:13:0:4:5:6:7
   => '[frequency] Month of year must be 1-12'

*1:2:0:-1:5:6:7 => * 1 2 0 -1 5 6 7

*1:2:0:-33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

*1:2:0:33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

#
# 0:2:0*4
#

0:2:0*4:5:6:7 => 0 2 * 0 4 5 6 7

0:2:0*-4:5:6:7 => 0 2 * 0 -4 5 6 7

0:2:0*33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

0:2:0*-33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

#
# 0:2*0:4
#

0:2*0:4:5:6:7 => 0 2 * 0 4 5 6 7

0:2*0:-4:5:6:7 => 0 2 * 0 -4 5 6 7

0:2*0:33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

0:2*0:-33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

#
# 0*2:0:4
#

0*2:0:4:5:6:7 => 1 * 2 0 4 5 6 7

0*-1:0:4:5:6:7
   => '[frequency] Month of year must be 1-12'

0*13:0:4:5:6:7
   => '[frequency] Month of year must be 1-12'

0*2:0:-1:5:6:7 => 1 * 2 0 -1 5 6 7

0*2:0:-33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

0*2:0:33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

#
# *0:2:0:4
#

*0:2:0:4:5:6:7 => * 0 2 0 4 5 6 7

*0:-2:0:4:5:6:7
   => '[frequency] Month of year must be 1-12'

*0:13:0:4:5:6:7
   => '[frequency] Month of year must be 1-12'

*0:2:0:-4:5:6:7 => * 0 2 0 -4 5 6 7

*0:2:0:33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

*0:2:0:-33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

#
# 1:2:3*0
#

1:2:3*0:5:6:7 => 1 2 3 * 0 5 6 7

#
# 1:0:3*0
#

1:0:3*0:5:6:7 => 1 0 3 * 0 5 6 7

#
# 0:2:3*0
#

0:2:3*0:5:6:7 => 0 2 3 * 0 5 6 7

#
# 0:0:3*0
#

0:0:3*0:5:6:7 => 0 0 3 * 0 5 6 7

#
# 1:0*3:0
#

1:0*3:0:5:6:7 => 1 * 0 3 0 5 6 7

1:0*-3:0:5:6:7 => 1 * 0 -3 0 5 6 7

1:0*63:0:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

1:0*-63:0:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

#
# 1*0:3:0
#

1*0:3:0:5:6:7 => 1 * 0 3 0 5 6 7

1*0:-3:0:5:6:7 => 1 * 0 -3 0 5 6 7

1*0:63:0:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

1*0:-63:0:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

#
# *1:0:3:0
#

*1:0:3:0:5:6:7 => * 1 0 3 0 5 6 7

*-1:0:3:0:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*12345:0:3:0:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*1:0:-3:0:5:6:7 => * 1 0 -3 0 5 6 7

*1:0:63:0:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

*1:0:-63:0:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

#
# 1:2*3:0
#

1:2*3:0:5:6:7 => 1 2 * 3 0 5 6 7

1:2*-3:0:5:6:7 => 1 2 * -3 0 5 6 7

1:2*6:0:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

1:2*-6:0:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

#
# 0:2*3:0
#

0:2*3:0:5:6:7 => 0 2 * 3 0 5 6 7

0:2*-3:0:5:6:7 => 0 2 * -3 0 5 6 7

0:2*6:0:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

0:2*-6:0:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

#
# 1*2:3:0
#

1*2:3:0:5:6:7 => 1 * 2 3 0 5 6 7

1*-2:3:0:5:6:7
   => '[frequency] Month of year must be 1-12'

1*13:3:0:5:6:7
   => '[frequency] Month of year must be 1-12'

1*2:-3:0:5:6:7 => 1 * 2 -3 0 5 6 7

1*2:6:0:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

1*2:-6:0:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

#
# 0*2:3:0
#

0*2:3:0:5:6:7 => 1 * 2 3 0 5 6 7

0*-2:3:0:5:6:7
   => '[frequency] Month of year must be 1-12'

0*13:3:0:5:6:7
   => '[frequency] Month of year must be 1-12'

0*2:-3:0:5:6:7 => 1 * 2 -3 0 5 6 7

0*2:6:0:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

0*2:-6:0:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

#
# *1:2:3:0
#

*1:2:3:0:5:6:7 => * 1 2 3 0 5 6 7

*-1:2:3:0:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*12345:2:3:0:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*1:-2:3:0:5:6:7
   => '[frequency] Month of year must be 1-12'

*1:13:3:0:5:6:7
   => '[frequency] Month of year must be 1-12'

*1:2:-3:0:5:6:7 => * 1 2 -3 0 5 6 7

*1:2:6:0:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

*1:2:-6:0:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

#
# *0:2:3:0
#

*0:2:3:0:5:6:7 => * 0 2 3 0 5 6 7

*0:-2:3:0:5:6:7
   => '[frequency] Month of year must be 1-12'

*0:13:3:0:5:6:7
   => '[frequency] Month of year must be 1-12'

*0:2:-3:0:5:6:7 => * 0 2 -3 0 5 6 7

*0:2:6:0:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

*0:2:-6:0:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

#
# 0:0*3:0
#

0:0*3:0:5:6:7 => 0 1 * 3 0 5 6 7

0:0*-3:0:5:6:7 => 0 1 * -3 0 5 6 7

0:0*6:0:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

0:0*-6:0:5:6:7
   => '[frequency] Week of month must be 1-5 or -1 to -5'

#
# 0*0:3:0
#

0*0:3:0:5:6:7 => 1 * 0 3 0 5 6 7

0*0:-3:0:5:6:7 => 1 * 0 -3 0 5 6 7

0*0:63:0:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

0*0:-63:0:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

#
# *0:0:3:0
#

*0:0:3:0:5:6:7 => * 0 0 3 0 5 6 7

*0:0:-3:0:5:6:7 => * 0 0 -3 0 5 6 7

*0:0:63:0:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

*0:0:-63:0:5:6:7
   => '[frequency] Week of year must be 1-53 or -1 to -53'

#
# 1:0:0*4
#

1:0:0*4:5:6:7 => 1 * 0 0 4 5 6 7

1:0:0*-4:5:6:7 => 1 * 0 0 -4 5 6 7

1:0:0*400:5:6:7
   => '[frequency] Day of year must be 1-366 or -1 to -366'

1:0:0*-400:5:6:7
   => '[frequency] Day of year must be 1-366 or -1 to -366'

#
# 1:0*0:4
#

1:0*0:4:5:6:7 => 1 * 0 0 4 5 6 7

1:0*0:-4:5:6:7 => 1 * 0 0 -4 5 6 7

1:0*0:400:5:6:7
   => '[frequency] Day of year must be 1-366 or -1 to -366'

1:0*0:-400:5:6:7
   => '[frequency] Day of year must be 1-366 or -1 to -366'

#
# 1*0:0:4
#

1*0:0:4:5:6:7 => 1 * 0 0 4 5 6 7

1*0:0:-4:5:6:7 => 1 * 0 0 -4 5 6 7

1*0:0:400:5:6:7
   => '[frequency] Day of year must be 1-366 or -1 to -366'

1*0:0:-400:5:6:7
   => '[frequency] Day of year must be 1-366 or -1 to -366'

#
# *1:0:0:4
#

*1:0:0:4:5:6:7 => * 1 0 0 4 5 6 7

*-1:0:0:4:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*12345:0:0:4:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*1:0:0:-4:5:6:7 => * 1 0 0 -4 5 6 7

*1:0:0:400:5:6:7
   => '[frequency] Day of year must be 1-366 or -1 to -366'

*1:0:0:400:5:6:7
   => '[frequency] Day of year must be 1-366 or -1 to -366'

#
# 0:0:0*4
#

0:0:0*4:5:6:7 => 0 0 1 * 4 5 6 7

0:0:0*8:5:6:7
   => '[frequency] Day of week must be 1-7'

0:0:0*-1:5:6:7
   => '[frequency] Day of week must be 1-7'

#
# 0:0*0:4
#

0:0*0:4:5:6:7 => 0 1 * 0 4 5 6 7

0:0*0:-4:5:6:7 => 0 1 * 0 -4 5 6 7

0:0*0:33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

0:0*0:-33:5:6:7
   => '[frequency] Day of month must be 1-31 or -1 to -31'

#
# 0*0:0:4
#

0*0:0:4:5:6:7 => 1 * 0 0 4 5 6 7

0*0:0:-4:5:6:7 => 1 * 0 0 -4 5 6 7

0*0:0:400:5:6:7
   => '[frequency] Day of year must be 1-366 or -1 to -366'

0*0:0:-400:5:6:7
   => '[frequency] Day of year must be 1-366 or -1 to -366'

#
# *0:0:0:4
#

*0:0:0:4:5:6:7 => * 0 0 0 4 5 6 7

*0:0:0:-4:5:6:7 => * 0 0 0 -4 5 6 7

*0:0:0:400:5:6:7
   => '[frequency] Day of year must be 1-366 or -1 to -366'

*0:0:0:-400:5:6:7
   => '[frequency] Day of year must be 1-366 or -1 to -366'

#
# 1:2:0*0
#

1:2:0*0:5:6:7 => 1 2 * 0 0 5 6 7

#
# 1:2*0:0
#

1:2*0:0:5:6:7 => 1 2 * 0 0 5 6 7

#
# 1*2:0:0
#

1*2:0:0:5:6:7 => 1 * 2 0 0 5 6 7

1*-2:0:0:5:6:7
   => '[frequency] Month of year must be 1-12'

1*13:0:0:5:6:7
   => '[frequency] Month of year must be 1-12'

#
# *1:2:0:0
#

*1:2:0:0:5:6:7 => * 1 2 0 0 5 6 7

*-1:2:0:0:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*12345:2:0:0:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*1:-2:0:0:5:6:7
   => '[frequency] Month of year must be 1-12'

*1:13:0:0:5:6:7
   => '[frequency] Month of year must be 1-12'

#
# 1:0:0*0
#

1:0:0*0:5:6:7 => 1 * 0 0 0 5 6 7

#
# 1:0*0:0
#

1:0*0:0:5:6:7 => 1 * 0 0 0 5 6 7

#
# 1*0:0:0
#

1*0:0:0:5:6:7 => 1 * 0 0 0 5 6 7

#
# *1:0:0:0
#

*1:0:0:0:5:6:7 => * 1 0 0 0 5 6 7

*-1:0:0:0:5:6:7
   => '[frequency] Year must be in the range 1-9999'

*12345:0:0:0:5:6:7
   => '[frequency] Year must be in the range 1-9999'

#
# 0:2:0*0
#

0:2:0*0:5:6:7 => 0 2 * 0 0 5 6 7

#
# 0:2*0:0
#

0:2*0:0:5:6:7 => 0 2 * 0 0 5 6 7

#
# 0*2:0:0
#

0*2:0:0:5:6:7 => 1 * 2 0 0 5 6 7

0*-2:0:0:5:6:7
   => '[frequency] Month of year must be 1-12'

0*13:0:0:5:6:7
   => '[frequency] Month of year must be 1-12'

#
# *0:2:0:0
#

*0:2:0:0:5:6:7 => * 0 2 0 0 5 6 7

*0:-2:0:0:5:6:7
   => '[frequency] Month of year must be 1-12'

*0:13:0:0:5:6:7
   => '[frequency] Month of year must be 1-12'

#
# 0:0:0*0
#

0:0:0*0:5:6:7 => 0 0 1 * 0 5 6 7

#
# 0:0*0:0
#

0:0*0:0:5:6:7 => 0 1 * 0 0 5 6 7

#
# 0*0:0:0
#

0*0:0:0:5:6:7 => 1 * 0 0 0 5 6 7

#
# *0:0:0:0
#

*0:0:0:0:5:6:7 => * 0 0 0 0 5 6 7

#################

1:2:0:0*5-8,-11:1:7
   => '[frequency] Hour must be 0-23'

1:2:0:0*5-8,11:-1:7
   => '[frequency] Minute/second must be 0-59'

1:2:0:0*5-8,11:1:-7
   => '[frequency] Minute/second must be 0-59'

1:2:0:0*5-8,11:-3--1:7
   => '[frequency] Minute/second must be 0-59'

1*-1:1:1:1:1:1
   => '[frequency] Month of year must be 1-12'

1*13:1:1:1:1:1
   => '[frequency] Month of year must be 1-12'

1*1:-6:0:1:1:1
   => '[frequency] Week of month must be 1-5 or -1 to -5'

1*1:6:0:1:1:1
   => '[frequency] Week of month must be 1-5 or -1 to -5'

1*0:-54:0:1:1:1
   => '[frequency] Week of year must be 1-53 or -1 to -53'

1*0:54:0:1:1:1
   => '[frequency] Week of year must be 1-53 or -1 to -53'

1*1:6:0:1:1:1
   => '[frequency] Week of month must be 1-5 or -1 to -5'

1*0:0:367:1:1:1
   => '[frequency] Day of year must be 1-366 or -1 to -366'

1*0:0:-367:1:1:1
   => '[frequency] Day of year must be 1-366 or -1 to -366'

1*1:0:32:1:1:1
   => '[frequency] Day of month must be 1-31 or -1 to -31'

1*1:0:-32:1:1:1
   => '[frequency] Day of month must be 1-31 or -1 to -31'

1*0:1:-1:1:1:1
   => '[frequency] Day of week must be 1-7'

1*0:1:8:1:1:1
   => '[frequency] Day of week must be 1-7'

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
