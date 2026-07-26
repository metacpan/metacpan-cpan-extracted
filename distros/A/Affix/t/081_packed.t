use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
no warnings 'portable';
#
$|++;
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c

#include <stdint.h>

#pragma pack(push, 1)
typedef struct {
    char a;
    int  b;
} PackedCharInt;
#pragma pack(pop)

typedef struct {
    char a;
    int  b;
} UnpackedCharInt;

#pragma pack(push, 1)
typedef struct {
    char     a;
    uint64_t b;
} PackedCharU64;
#pragma pack(pop)

DLLEXPORT int sizeof_packed_char_int(void)   { return (int)sizeof(PackedCharInt); }
DLLEXPORT int sizeof_unpacked_char_int(void) { return (int)sizeof(UnpackedCharInt); }
DLLEXPORT int sizeof_packed_char_u64(void)   { return (int)sizeof(PackedCharU64); }

DLLEXPORT int offset_packed_b(void)   { return (int)offsetof(PackedCharInt, b); }
DLLEXPORT int offset_unpacked_b(void) { return (int)offsetof(UnpackedCharInt, b); }

DLLEXPORT void fill_packed(PackedCharInt *p) { p->a = 65; p->b = 12345; }
DLLEXPORT void fill_unpacked(UnpackedCharInt *p) { p->a = 65; p->b = 12345; }
DLLEXPORT int check_packed(PackedCharInt *p) { return (p->a == 65 && p->b == 12345) ? 1 : 0; }
DLLEXPORT int check_unpacked(UnpackedCharInt *p) { return (p->a == 65 && p->b == 12345) ? 1 : 0; }

DLLEXPORT void fill_packed_u64(PackedCharU64 *p) { p->a = 'X'; p->b = 0xDEADBEEFCAFEBABEULL; }
DLLEXPORT char     get_packed_u64_char(PackedCharU64 *p) { return p->a; }
DLLEXPORT uint64_t get_packed_u64_val(PackedCharU64 *p)  { return p->b; }

#pragma pack(push, 1)
typedef struct {
    int32_t a;
    int8_t  b;
    int32_t c;
} PackedABC;
#pragma pack(pop)

DLLEXPORT PackedABC make_packed_abc(int32_t a, int8_t b, int32_t c) {
    PackedABC r = {0};
    r.a = a;
    r.b = b;
    r.c = c;
    return r;
}
END_C
#
my $lib = compile_ok($C_CODE);
ok( $lib && -e $lib, 'Compiled shared library' );
#
affix $lib, 'sizeof_packed_char_int',   []                        => Int;
affix $lib, 'sizeof_unpacked_char_int', []                        => Int;
affix $lib, 'sizeof_packed_char_u64',   []                        => Int;
affix $lib, 'offset_packed_b',          []                        => Int;
affix $lib, 'offset_unpacked_b',        []                        => Int;
affix $lib, 'fill_packed',              [ Pointer [Void] ]        => Void;
affix $lib, 'fill_unpacked',            [ Pointer [Void] ]        => Void;
affix $lib, 'check_packed',             [ Pointer [Void] ]        => Bool;
affix $lib, 'check_unpacked',           [ Pointer [Void] ]        => Bool;
affix $lib, 'fill_packed_u64',          [ Pointer [Void] ]        => Void;
affix $lib, 'get_packed_u64_char',      [ Pointer [Void] ]        => Char;
affix $lib, 'get_packed_u64_val',       [ Pointer [Void] ]        => UInt64;
affix $lib, 'make_packed_abc',          [ SInt32, SInt8, SInt32 ] => Packed( Struct [ a => SInt32, b => SInt8, c => SInt32 ] );
#
subtest 'C-level size and layout' => sub {
    is sizeof_packed_char_int(),   5, 'C sizeof(PackedCharInt) is 5 bytes';
    is sizeof_unpacked_char_int(), 8, 'C sizeof(UnpackedCharInt) is 8 bytes';
    is sizeof_packed_char_u64(),   9, 'C sizeof(PackedCharU64) is 9 bytes';
    is offset_packed_b(),          1, 'Packed field b offset is 1';
    is offset_unpacked_b(),        4, 'Unpacked field b offset is 4';
    ok sizeof_packed_char_int() < sizeof_unpacked_char_int(), 'Packed is smaller than unpacked';
    is sizeof_packed_char_int() + 3, sizeof_unpacked_char_int(), 'Difference is 3 bytes of padding';
};
#
subtest 'Perl sizeof matches C -- Packed(Struct[...])' => sub {
    is sizeof( Packed( Struct [ a => Char, b => Int ] ) ),    5, 'sizeof Packed(Char,Int) = 5';
    is sizeof( Packed( Struct [ a => Char, b => UInt64 ] ) ), 9, 'sizeof Packed(Char,UInt64) = 9';
    is sizeof( Struct [ a => Char, b => Int ] ), 8, 'sizeof Struct(Char,Int) = 8 (unpadded)';
};
#
subtest 'Perl sizeof matches C -- Packed[N, Struct[...]]' => sub {
    is sizeof( Packed [ 1, [ a => Char, b => Int ] ] ),    5, 'sizeof Packed[1,(Char,Int)] = 5';
    is sizeof( Packed [ 1, [ a => Char, b => UInt64 ] ] ), 9, 'sizeof Packed[1,(Char,UInt64)] = 9';
    is sizeof( Packed [ 4, [ a => Char, b => Int ] ] ),    8, 'sizeof Packed[4,(Char,Int)] = 8 (align 4)';
};
#
subtest 'Packed struct -- C fill and verify via C pointer' => sub {
    my $mem = calloc( 1, sizeof_packed_char_int() );
    ok $mem, 'calloc returned memory';
    fill_packed($mem);
    ok check_packed($mem), 'C verifies packed fields: a=65, b=12345';
};
#
subtest 'Unpacked Struct -- Perl field access' => sub {
    my $mem = calloc( 1, sizeof_unpacked_char_int() );
    fill_unpacked($mem);
    ok check_unpacked($mem), 'C verifies unpacked fields';
    my $p = cast( $mem, Struct [ a => Char, b => Int ] );
    is $p->{a}, 65,    'Read unpacked field a via magic';
    is $p->{b}, 12345, 'Read unpacked field b via magic';
};
#
subtest 'Packed struct -- Perl field access via magic' => sub {
    my $mem = calloc( 1, sizeof_packed_char_int() );
    fill_packed($mem);
    my $p = cast( $mem, Packed( Struct [ a => Char, b => Int ] ) );
    is $p->{a}, 65,    'Read packed field a via magic';
    is $p->{b}, 12345, 'Read packed field b via magic';
    $p->{a} = 90;
    $p->{b} = 54321;
    is $p->{a}, 90,    'Write and read packed field a';
    is $p->{b}, 54321, 'Write and read packed field b';
};
#
subtest 'Packed char + uint64_t -- C-level roundtrip' => sub {
    my $mem = calloc( 1, sizeof_packed_char_u64() );
    fill_packed_u64($mem);
    is get_packed_u64_char($mem), 88,                 'C reads packed char as 88 (ASCII "X")';
    is get_packed_u64_val($mem),  0xDEADBEEFCAFEBABE, 'C reads packed uint64_t correctly';
    my $p = cast( $mem, Packed( Struct [ a => Char, b => UInt64 ] ) );
    $p->{a} = 90;
    is get_packed_u64_char($mem), 90, 'C sees char updated via magic';
    $p->{b} = 0x1122334455667788;
    is get_packed_u64_val($mem), 0x1122334455667788, 'C sees u64 updated via magic';
};
#
subtest 'Packed struct -- by-value return' => sub {
    my $ret = make_packed_abc( 42, -66, 99 );
    is ref($ret), 'HASH', 'Return value is a hashref';
    is $ret->{a},  42,    'Field a returned correctly';
    is $ret->{b}, -66,    'Field b returned correctly';
    is $ret->{c},  99,    'Field c returned correctly';
};
#
done_testing;
