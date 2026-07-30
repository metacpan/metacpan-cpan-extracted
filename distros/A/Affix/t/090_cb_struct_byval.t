use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c

typedef struct { int8_t m0; } CS_1byte;
typedef struct { int16_t m0; } CS_2byte;
typedef struct { int32_t m0; } CS_4byte;
typedef struct { int64_t m0; } CS_8byte;
typedef struct { int16_t m0; int16_t m1; } CS_2x2;

DLLEXPORT int8_t test_1byte_cb(int8_t (*op)(CS_1byte), CS_1byte s) { return op(s); }
DLLEXPORT int16_t test_2byte_cb(int16_t (*op)(CS_2byte), CS_2byte s) { return op(s); }
DLLEXPORT int32_t test_4byte_cb(int32_t (*op)(CS_4byte), CS_4byte s) { return op(s); }
DLLEXPORT int64_t test_8byte_cb(int64_t (*op)(CS_8byte), CS_8byte s) { return op(s); }
DLLEXPORT int16_t test_2x2_cb(int16_t (*op)(CS_2x2), CS_2x2 s) { return op(s); }
END_C
my $lib = compile_ok($C_CODE);
ok( $lib && -e $lib, 'Compiled a test shared library successfully' );
subtest '1-byte struct by value callback' => sub {
    my $fn = wrap( $lib, 'test_1byte_cb', [ Callback [ [ Struct [ m0 => Int8 ] ] => Int8 ], Struct [ m0 => Int8 ] ], Int8 );
    isa_ok $fn, 'Affix';
    my $got = $fn->( sub { $_[0]->{m0} }, { m0 => -42 } );
    is $got, -42, "1-byte struct roundtrip";
};
subtest '2-byte struct by value callback' => sub {
    my $fn = wrap( $lib, 'test_2byte_cb', [ Callback [ [ Struct [ m0 => Short ] ] => Short ], Struct [ m0 => Short ] ], Short );
    isa_ok $fn, 'Affix';
    my $got = $fn->( sub { $_[0]->{m0} }, { m0 => -32580 } );
    is $got, -32580, "2-byte struct roundtrip";
};
subtest '4-byte struct by value callback' => sub {
    my $fn = wrap( $lib, 'test_4byte_cb', [ Callback [ [ Struct [ m0 => Int32 ] ] => Int32 ], Struct [ m0 => Int32 ] ], Int32 );
    isa_ok $fn, 'Affix';
    my $got = $fn->( sub { $_[0]->{m0} }, { m0 => 879273776 } );
    is $got, 879273776, "4-byte struct roundtrip";
};
subtest '8-byte struct by value callback' => sub {
    my $fn = wrap( $lib, 'test_8byte_cb', [ Callback [ [ Struct [ m0 => Int64 ] ] => Int64 ], Struct [ m0 => Int64 ] ], Int64 );
    isa_ok $fn, 'Affix';
    my $got = $fn->( sub { $_[0]->{m0} }, { m0 => 1847558423 } );
    is $got, 1847558423, "8-byte struct roundtrip";
};
subtest '2-field struct by value callback' => sub {
    my $fn
        = wrap( $lib, 'test_2x2_cb', [ Callback [ [ Struct [ m0 => Short, m1 => Short ] ] => Short ], Struct [ m0 => Short, m1 => Short ] ], Short );
    isa_ok $fn, 'Affix';
    my $got = $fn->( sub { $_[0]->{m0} }, { m0 => -32580, m1 => 100 } );
    is $got, -32580, "2x2-byte struct roundtrip";
};
done_testing;
