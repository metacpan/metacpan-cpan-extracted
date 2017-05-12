#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Data::Bitfield qw( bitfield boolfield );

bitfield TEST =>
   first  => boolfield(0),
   second => boolfield(1),
   third  => boolfield(2);

is( pack_TEST( first => 1, third => 1 ), 0x05,
   'pack_TEST' );

is_deeply( { unpack_TEST( 0x05 ) }, { first => 1, second => !1, third => 1 },
   'unpack_TEST' );

ok( exception { pack_TEST( different => 0 ) },
   'Unrecognised field dies' );

is( exception {
      bitfield { unrecognised_ok => 1 }, TESTx =>
         first => boolfield(0);

      pack_TESTx( different => 0 );
   }, undef,
   'Unrecognised field OK with unrecognised_ok option' );

ok( exception {
      bitfield NOTHING =>
         field => boolfield(0),
         field => boolfield(1);
   }, 'Attempt to redefine a field dies' );

ok( exception {
      bitfield NOTHING =>
         field => boolfield(0),
         again => boolfield(0);
   }, 'Attempt to re-use a bit index dies' );

done_testing;
