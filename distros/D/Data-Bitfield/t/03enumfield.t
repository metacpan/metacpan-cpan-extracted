#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Data::Bitfield qw( bitfield enumfield );

{
   bitfield { format => "bytes-LE" }, BYTES =>
      first  => enumfield(0, qw( false true )),
      second => enumfield(2, qw( zero one two three ));

   is( sprintf( "%v02x", pack_BYTES( first => "true", second => "two" ) ), "09",
      'pack_BYTES' );

   is_deeply( { unpack_BYTES( "\x09" ) }, { first => "true", second => "two" },
      'unpack_BYTES' );
}

is( exception {
      bitfield ANOTHER =>
         zero => enumfield(0, qw( z Z )),
         one  => enumfield(1, qw( o O )),
         two  => enumfield(2, qw( t T ));
         three => enumfield(3, qw( th Th TH )),
   }, undef,
   'Non-overlapping enums' );

ok( exception { pack_BYTES( first => "hello" ) },
   'Unrecognised enum value dies' );

done_testing;
