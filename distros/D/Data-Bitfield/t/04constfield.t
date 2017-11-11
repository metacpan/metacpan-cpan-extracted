#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Data::Bitfield qw( bitfield boolfield constfield );

bitfield TEST =>
   first  => boolfield(0),
   second => boolfield(1),
   constfield(2, 4, 0x9);

is( pack_TEST( first => 1, second => 1 ), 3 | 9<<2,
   'pack_TEST' );

done_testing;
