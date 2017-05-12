#!perl
# 
# Part of Comedi::Lib
#
# Copyright (c) 2009 Manuel Gebele <forensixs@gmx.de>, Germany
#
use Test::More tests => 1;
use warnings;
use strict;

use Comedi::Lib;

SKIP:
{
   my $cref;
   my $max = 0x30; # COMEDI_NUM_BOARD_MINORS   
   my $no  = 0x00;
   my $pre = '/dev/comedi';

   # Try to find a valid Comedi device
   while ($no < $max) {
      if (-e "$pre$no") {
         eval {
            $cref = Comedi::Lib->new(device => "$pre$no", open_flag => 1);
         };
         goto break unless $@; # we've found a Comedi device
      }      
      $no++;
   }
break:

   skip "Couldn't open virtual device file", 1 unless $cref;

   my $ret = $cref->close();
   ok($ret == 0, "\$cref->close() <$pre$no> success");
}
