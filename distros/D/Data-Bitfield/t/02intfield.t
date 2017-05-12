#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Data::Bitfield qw( bitfield intfield );

bitfield TEST =>
   first  => intfield(0,2),
   second => intfield(2,2),
   third  => intfield(4,4);

is( pack_TEST( first => 1, third => 6 ), (1 << 0) | (6 << 4),
   'pack_TEST' );

is_deeply( { unpack_TEST( (1 << 0) | (6 << 4) ) },
      { first => 1, second => 0, third => 6 },
   'unpack_TEST' );

ok( exception { pack_TEST( first => "hello" ) },
   'Non-numerical intfield value dies' );

ok( exception { pack_TEST( first => 17 ) },
   'Out-of-range intfield value dies' );

done_testing;
