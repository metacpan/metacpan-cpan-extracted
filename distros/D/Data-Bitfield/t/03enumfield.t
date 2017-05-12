#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Data::Bitfield qw( bitfield enumfield );

bitfield TEST =>
   first  => enumfield(0, qw( false true )),
   second => enumfield(2, qw( zero one two three ));

is( pack_TEST( first => "true", second => "two" ), 9,
   'pack_TEST' );

is_deeply( { unpack_TEST( 9 ) }, { first => "true", second => "two" },
   'unpack_TEST' );

is( exception {
      bitfield ANOTHER =>
         zero => enumfield(0, qw( z Z )),
         one  => enumfield(1, qw( o O )),
         two  => enumfield(2, qw( t T ));
         three => enumfield(3, qw( th Th TH )),
   }, undef,
   'Non-overlapping enums' );

ok( exception { pack_TEST( first => "hello" ) },
   'Unrecognised enum value dies' );

done_testing;
