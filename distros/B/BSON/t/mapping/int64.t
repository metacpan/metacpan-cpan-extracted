use 5.0001;
use strict;
use warnings;

use Test::More 0.96;
use Math::BigInt;

use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;
use TestUtils;
use JSON::MaybeXS;

use Config;
use BSON qw/encode decode/;
use BSON::Types ':all';

my ($hash, $bson, $expect);

my $max_int64 =
  $Config{use64bitint} ? 9223372036854775807 : Math::BigInt->new("9223372036854775807");
my $min_int64 =
  $Config{use64bitint} ? -9223372036854775808 : Math::BigInt->new("-9223372036854775808");

my $max_int32_p1 = Math::BigInt->new("2147483648");
my $min_int31_m1 = Math::BigInt->new("-2147483649");

my $bigpos = Math::BigInt->new("9223372036854775808");
my $bigneg = Math::BigInt->new("-9223372036854775809");

# test constructor
packed_is( INT64, bson_int64(), 0, "empty bson_int64() is 0" );
packed_is( INT64, BSON::Int64->new, 0, "empty constructor is 0" );

# test constructor errors; these will cap at min/max int64
packed_is( INT64, bson_int64(9223372036854775808), $max_int64, "bson_int64(9223372036854775808)" );
packed_is( INT64, bson_int64(9223372036854775808.01), $max_int64, "bson_int64(9223372036854775808.01)" );
packed_is( INT64, bson_int64(9223372036854775807.99), $max_int64, "bson_int64(9223372036854775807.99)" );
packed_is( INT64, bson_int64(-9223372036854775809), $min_int64, "bson_int64(-9223372036854775809)" );
packed_is( INT64, bson_int64(-9223372036854775809.01), $min_int64,  "bson_int64(-9223372036854775809.01)");
packed_is( INT64, bson_int64(-9223372036854775808.99), $min_int64,  "bson_int64(-9223372036854775808.99)");

packed_is( INT64, bson_int64($bigpos), $max_int64, "bson_int64(bigpos)" );
packed_is( INT64, bson_int64($bigneg), $min_int64, "bson_int64(bigpos)" );

# test overloading
packed_is( INT64, bson_int64($max_int32_p1), $max_int32_p1, "overloading correct" );

subtest 'native (64-bit perls)' => sub {
    plan skip_all => 'not a 64-bit perl' unless $Config{use64bitint};

    # int64 -> int64
    $bson = $expect = encode( { A => $max_int32_p1 } );
    $hash = decode( $bson );
    is( sv_type( $hash->{A} ), 'IV', "int64->int64" );
    packed_is( INT64, $hash->{A}, $max_int32_p1, "value correct" );

    # BSON::Int64 -> int64
    $bson = encode( { A => bson_int64($max_int32_p1) } );
    $hash = decode( $bson );
    is( sv_type( $hash->{A} ), 'IV', "BSON::Int64->int64" );
    packed_is( INT64, $hash->{A}, $max_int32_p1, "value correct" );
    bytes_are( $bson, $expect, "BSON correct" );

    # BSON::Int64(string) -> int64
    $bson = encode( { A => bson_int64("0") } );
    $hash = decode( $bson );
    is( sv_type( $hash->{A} ), 'IV', "BSON::Int64->int64" );
    packed_is( INT64, $hash->{A}, 0, "value correct" );

    # Math::BigInt -> int64
    $bson = encode( { A => Math::BigInt->new("0") } );
    $hash = decode( $bson );
    is( sv_type( $hash->{A} ), 'IV', "Math::BigInt->int64" );
    packed_is( INT64, $hash->{A}, 0, "value correct" );

    # Math::Int64 -> int64
    SKIP: {
        eval { require Math::Int64 };
        skip( "Math::Int64 not installed", 2 )
            unless $INC{'Math/Int64.pm'};
        $bson = encode( { A => Math::Int64::int64("0") } );
        $hash = decode( $bson );
        is( sv_type( $hash->{A} ), 'IV', "Math::Int64->int64" );
        packed_is( INT64, $hash->{A}, 0, "value correct" );
    }

};

subtest 'Math::BigInt (32-bit perls)' => sub {
    plan skip_all => 'not a 32-bit perl' if $Config{use64bitint};

    # NV -> Math::BigInt
    $bson = $expect = encode( { A => $max_int32_p1 } );
    $hash = decode( $bson );
    is( ref( $hash->{A} ), 'Math::BigInt', "int64->Math::BigInt" );
    packed_is( INT64, $hash->{A}, $max_int32_p1, "value correct" );

    # BSON::Int64 -> Math::BigInt
    $bson = encode( { A => bson_int64($max_int32_p1) } );
    $hash = decode( $bson );
    is( ref( $hash->{A} ), 'Math::BigInt', "BSON::Int64->Math::BigInt" );
    packed_is( INT64, $hash->{A}, $max_int32_p1, "value correct" );
    bytes_are( $bson, $expect, "BSON correct" );

    # BSON::Int64(string) -> Math::BigInt
    $bson = encode( { A => bson_int64("0") } );
    $hash = decode( $bson );
    is( ref( $hash->{A} ), 'Math::BigInt', "BSON::Int64->Math::BigInt" );
    packed_is( INT64, $hash->{A}, 0, "value correct" );

    # Math::BigInt -> Math::BigInt
    $bson = encode( { A => Math::BigInt->new("0") } );
    $hash = decode( $bson );
    is( ref( $hash->{A} ), 'Math::BigInt', "Math::BigInt->Math::BigInt" );
    packed_is( INT64, $hash->{A}, 0, "value correct" );

    # Math::Int64 -> Math::BigInt
    SKIP: {
        eval { require Math::Int64 };
        skip( "Math::Int64 not installed", 2 )
            unless $INC{'Math/Int64.pm'};
        $bson = encode( { A => Math::Int64::int64("0") } );
        $hash = decode( $bson );
        is( ref( $hash->{A} ), 'Math::BigInt', "Math::Int64->Math::BigInt" );
        packed_is( INT64, $hash->{A}, 0, "value correct" );
    }

};

subtest 'wrapped' => sub {
    # int64 -> BSON::Int64
    $bson = $expect = encode( { A => $max_int32_p1 } );
    $hash = decode( $bson, wrap_numbers => 1 );
    is( ref( $hash->{A} ), 'BSON::Int64', "int64->BSON::Int64" );
    packed_is( INT64, $hash->{A}, $max_int32_p1, "value correct" );

    # BSON::Int64 -> BSON::Int64
    $bson = encode( { A => bson_int64($max_int32_p1) } );
    $hash = decode( $bson, wrap_numbers => 1 );
    is( ref( $hash->{A} ), 'BSON::Int64', "int64->BSON::Int64" );
    packed_is( INT64, $hash->{A}, $max_int32_p1, "value correct" );
    bytes_are( $bson, $expect, "BSON correct" );

    # BSON::Int64(string) -> BSON::Int64
    $bson = encode( { A => bson_int64("0") } );
    $hash = decode( $bson, wrap_numbers => 1 );
    is( ref( $hash->{A} ), 'BSON::Int64', "int64->BSON::Int64" );
    packed_is( INT64, $hash->{A}, 0, "value correct" );

    # Math::BigInt -> BSON::Int64
    $bson = encode( { A => Math::BigInt->new("0") } );
    $hash = decode( $bson, wrap_numbers => 1 );
    is( ref( $hash->{A} ), 'BSON::Int64', "Math::BigInt->BSON::Int64" );
    packed_is( INT64, $hash->{A}, 0, "value correct" );

    # Math::Int64 -> BSON::Int64
    SKIP: {
        eval { require Math::Int64 };
        skip( "Math::Int64 not installed", 2 )
            unless $INC{'Math/Int64.pm'};
        $bson = encode( { A => Math::Int64::int64("0") } );
        $hash = decode( $bson, wrap_numbers => 1 );
        is( ref( $hash->{A} ), 'BSON::Int64', "Math::Int64->BSON::Int64" );
        packed_is( INT64, $hash->{A}, 0, "value correct" );
    }

};

if ( $Config{use64bitint} ) {
    # to JSON
    SKIP: {
        skip "JSON::PP has trouble with TO_JSON being false", 1
            if ref JSON::MaybeXS->new eq 'JSON::PP';
        is( to_myjson({a=>bson_int64(0)}), q[{"a":0}], 'bson_int64(0)' );
    }
    is( to_myjson({a=>bson_int64(42)}), q[{"a":42}], 'bson_int64(42)' );

    # to extended JSON
    is( to_extjson({a=>bson_int64(0)}), q[{"a":{"$numberLong":"0"}}], 'extjson: bson_int64(0)' );
    is( to_extjson({a=>bson_int64(42)}), q[{"a":{"$numberLong":"42"}}], 'extjson: bson_int64(0)' );
}

done_testing;

#
# This file is part of BSON
#
# This software is Copyright (c) 2019 by Stefan G. and MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
#
# vim: set ts=4 sts=4 sw=4 et tw=75:
