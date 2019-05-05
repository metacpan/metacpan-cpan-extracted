#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Data::Bitfield qw( bitfield boolfield constfield );

# integer encoding
{
   bitfield { format => "bytes-LE" }, BYTES =>
      first  => boolfield(0),
      second => boolfield(1),
      constfield(2, 4, 0x9);

   is( sprintf( "%v02x", pack_BYTES( first => 1, second => 1 ) ), "27",
      'pack_BYTES' );
}

done_testing;
