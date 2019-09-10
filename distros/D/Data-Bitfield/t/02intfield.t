#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Data::Bitfield qw( bitfield intfield signed_intfield );

{
   bitfield { format => "bytes-LE" }, BYTES =>
      first  => intfield(0,2),
      second => intfield(2,2),
      third  => intfield(4,4);

   is( sprintf( "%v02x", pack_BYTES( first => 1, third => 6 ) ), "61",
      'pack_BYTES' );

   is_deeply( { unpack_BYTES( "\x46" ) }, { first => 2, second => 1, third => 4 },
      'unpack_BYTES' );
}

# 16bits in little- and big-endian
{
   bitfield { format => "bytes-LE" }, U16L =>
      i => intfield(0, 16);
   bitfield { format => "bytes-BE" }, U16B =>
      i => intfield(0, 16);

   is( sprintf( "%v02x", pack_U16L( i => 0x1234 ) ), "34.12",
      'pack_U16L' );
   is( sprintf( "%v02x", pack_U16B( i => 0x1234 ) ), "12.34",
      'pack_U16B' );

   is_deeply( { unpack_U16L( "\x78\x56" ) }, { i => 0x5678 },
      'unpack_U16L' );
   is_deeply( { unpack_U16B( "\x56\x78" ) }, { i => 0x5678 },
      'unpack_U16B' );
}

# Two 8bit fields still encode in the correct direction
{
   bitfield { format => "bytes-LE" }, U8U8L =>
      x => intfield(0, 8),
      y => intfield(8, 8);
   bitfield { format => "bytes-BE" }, U8U8B =>
      x => intfield(0, 8),
      y => intfield(8, 8);

   is( sprintf( "%v02x", pack_U8U8L( x => 1, y => 2 ) ), "01.02",
      'pack_U16L' );
   is( sprintf( "%v02x", pack_U8U8B( x => 1, y => 2 ) ), "01.02",
      'pack_U16L' );

   is_deeply( { unpack_U8U8L( "\x01\x02" ) }, { x => 1, y => 2 },
      'unpack_U8U8L' );
   is_deeply( { unpack_U8U8B( "\x01\x02" ) }, { x => 1, y => 2 },
      'unpack_U8U8B' );
}

# signed_intfield
{
   bitfield { format => "bytes-LE" }, S4S4 =>
      a => signed_intfield(0, 4),
      b => signed_intfield(4, 4);

   is( sprintf( "%v02X", pack_S4S4( a => 3, b => -3 ) ), "D3",
      'pack_S4S4' );

   is_deeply( { unpack_S4S4( "\xC4" ) }, { a => 4, b => -4 },
      'unpack_S4S4' );
}

# integer encoding
{
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
}

done_testing;
