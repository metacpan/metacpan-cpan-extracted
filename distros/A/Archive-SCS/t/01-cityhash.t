#!perl
use strict;
use warnings;
use lib qw( blib/arch blib/lib );

use Archive::SCS::CityHash qw(
  cityhash64
);
use Test::More;

is unpack('H*', cityhash64 ''), '9ae16a3b2f90404f';

done_testing;
