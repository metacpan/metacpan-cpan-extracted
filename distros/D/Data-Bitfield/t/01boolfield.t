#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Data::Bitfield qw( bitfield boolfield );

{
   bitfield { format => "bytes-LE" }, BYTES =>
      first  => boolfield(0),
      second => boolfield(1),
      third  => boolfield(2);

   is( sprintf( "%v02x", pack_BYTES( first => 1, third => 1 ) ), "05",
      'pack_BYTES' );

   is_deeply( { unpack_BYTES( "\x05" ) }, { first => 1, second => !1, third => 1 },
      'unpack_BYTES' );
}

# endpoints
{
   bitfield { format => "bytes-LE" }, U32L =>
      high => boolfield(31),
      low  => boolfield(0);

   is( pack_U32L( low => 1, high => 1 ), "\x01\x00\x00\x80",
      'pack_U32L' );

   is_deeply( { unpack_U32L( "\x01\x00\x00\x80" ) }, { low => 1, high => 1 },
      'unpack_U32L' );
}

# wide data
{
   bitfield { format => "bytes-LE" }, WIDE =>
      low => boolfield(0),
      far => boolfield(19*8);

   is( sprintf( "%v02x", pack_WIDE( low => 1, far => 1 ) ),
      "01.".("00."x18)."01",
      'pack_WIDE' );
}

# 24bit is awkward to emulate
{
   bitfield { format => "bytes-LE" }, U24L =>
      high => boolfield(23),
      low  => boolfield(0);

   is( pack_U24L( low => 1, high => 1 ), "\x01\x00\x80",
      'pack_U24L' );

   is_deeply( { unpack_U24L( "\x01\x00\x80" ) }, { low => 1, high => 1 },
      'unpack_U24L' );
}

# integer encoding
{
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
}

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
