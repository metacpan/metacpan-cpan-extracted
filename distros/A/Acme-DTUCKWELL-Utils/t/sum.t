#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Acme::DTUCKWELL::Utils;

plan tests => 2;

#check sum of 1 to 10 comes out as 55 
is( sum(1,2,3,4,5,6,7,8,9,10), 55,
    'Sum as expected');

#Check characters don't work
is( sum('A',2,3,4,5),
      'Invalid',
      'Characters return Invalid as expected');

