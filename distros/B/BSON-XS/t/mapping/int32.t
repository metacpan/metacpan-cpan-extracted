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

use BSON qw/encode decode/;
use BSON::Types ':all';

my ($hash, $bson, $expect);

my $bigpos = Math::BigInt->new("2147483648");
my $bigneg = Math::BigInt->new("-2147483649");

# test constructor
packed_is( INT32, bson_int32(), 0, "empty bson_int32() is 0" );
packed_is( INT32, BSON::Int32->new, 0, "empty constructor is 0" );

# test constructor errors; these will wind up doubles on 32-bit platforms
eval { bson_int32(2**31) };
like( $@, qr/can't fit/, "bson_int32(2**31) fails" );
eval { bson_int32(-2**31-1) };
like( $@, qr/can't fit/, "bson_int32(-2**31-1) fails" );

# test constructor errors with Math::BigInt
eval { bson_int32($bigpos) };
like( $@, qr/can't fit/, "bson_int32(big BigInt) fails" );
eval { bson_int32($bigneg) };
like( $@, qr/can't fit/, "bson_int32(-big BigInt) fails" );

# test overloading
packed_is( INT32, bson_int32(314159), 314159, "overloading correct" );

subtest 'native' => sub {
    # int32 -> int32
    $bson = $expect = encode( { A => 314159 } );
    $hash = decode( $bson );
    is( sv_type( $hash->{A} ), 'IV', "int32->int32" );
    packed_is( INT32, $hash->{A}, 314159, "value correct" );

    # BSON::Int32 -> int32
    $bson = encode( { A => bson_int32(314159) } );
    $hash = decode( $bson );
    is( sv_type( $hash->{A} ), 'IV', "BSON::Int32->int32" );
    packed_is( INT32, $hash->{A}, 314159, "value correct" );
    is( $bson, $expect, "BSON correct" );

    # BSON::Int32(string) -> int32
    $bson = encode( { A => bson_int32("314159") } );
    $hash = decode( $bson );
    is( sv_type( $hash->{A} ), 'IV', "BSON::Int32->int32" );
    packed_is( INT32, $hash->{A}, 314159, "value correct" );
    is( $bson, $expect, "BSON correct" );
};

subtest 'wrapped' => sub {
    # int32 -> BSON::Int32
    $bson = $expect = encode( { A => 314159 } );
    $hash = decode( $bson, wrap_numbers => 1 );
    is( ref( $hash->{A} ), 'BSON::Int32', "int32->BSON::Int32" );
    packed_is( INT32, $hash->{A}, 314159, "value correct" );

    # BSON::Int32 -> BSON::Int32
    $bson = encode( { A => bson_int32(314159) } );
    $hash = decode( $bson, wrap_numbers => 1 );
    is( ref( $hash->{A} ), 'BSON::Int32', "int32->BSON::Int32" );
    packed_is( INT32, $hash->{A}, 314159, "value correct" );
    is( $bson, $expect, "BSON correct" );

    # BSON::Int32(string) -> BSON::Int32
    $bson = encode( { A => bson_int32("314159") } );
    $hash = decode( $bson, wrap_numbers => 1 );
    is( ref( $hash->{A} ), 'BSON::Int32', "int32->BSON::Int32" );
    packed_is( INT32, $hash->{A}, 314159, "value correct" );
    is( $bson, $expect, "BSON correct" );
};

# to JSON
SKIP: {
    skip "JSON::PP has trouble with TO_JSON being false", 1
        if ref JSON::MaybeXS->new eq 'JSON::PP';
    is( to_myjson({a=>bson_int32(0)}), q[{"a":0}], 'bson_int32(0)' );
}

is( to_myjson({a=>bson_int32(42)}), q[{"a":42}], 'bson_int32(42)' );

# to extended JSON
SKIP: {
    skip "JSON::PP has trouble with TO_JSON being false", 1
        if ref JSON::MaybeXS->new eq 'JSON::PP';
    is( to_extjson({a=>bson_int32(0)}), q[{"a":{"$numberInt":"0"}}], 'extjson: bson_int32(0)' );
}

is( to_extjson({a=>bson_int32(42)}), q[{"a":{"$numberInt":"42"}}], 'extjson: bson_int32(42)' );

done_testing;

#
# This file is part of BSON-XS
#
# This software is Copyright (c) 2019 by MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
#
# vim: set ts=4 sts=4 sw=4 et tw=75:
