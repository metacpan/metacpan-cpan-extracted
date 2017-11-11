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

   is( sprintf( "%v02x", pack_BYTES( first => 1, third => 1 ) ),
      sprintf( "%v02x", "\x05" ),
      'pack_BYTES' );

   is_deeply( { unpack_BYTES( "\x05" ) }, { first => 1, second => !1, third => 1 },
      'unpack_BYTES' );
}

# endpoints of little-endian
{
   bitfield { format => "bytes-LE" }, U32L =>
      high => boolfield(31),
      low  => boolfield(0);

   is( pack_U32L( low => 1, high => 1 ), "\x01\x00\x00\x80",
      'pack_U32L' );

   is_deeply( { unpack_U32L( "\x01\x00\x00\x80" ) }, { low => 1, high => 1 },
      'unpack_U32L' );
}

# endpoints of big-endian
{
   bitfield { format => "bytes-BE" }, U32B =>
      high => boolfield(31),
      low  => boolfield(0);

   is( pack_U32B( low => 1, high => 1 ), "\x80\x00\x00\x01",
      'pack_U32B' );

   is_deeply( { unpack_U32B( "\x80\x00\x00\x01" ) }, { low => 1, high => 1 },
      'unpack_U32B' );
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

   bitfield { format => "bytes-BE" }, U24B =>
      high => boolfield(23),
      low  => boolfield(0);

   is( pack_U24B( low => 1, high => 1 ), "\x80\x00\x01",
      'pack_U24B' );

   is_deeply( { unpack_U24B( "\x80\x00\x01" ) }, { low => 1, high => 1 },
      'unpack_U24B' );
}

done_testing;
