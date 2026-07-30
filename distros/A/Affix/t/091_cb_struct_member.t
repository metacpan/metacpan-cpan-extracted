use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
my $C_CODE = <<'END_C';
#include "std.h"
#include <stdint.h>
//ext: .c

typedef int32_t (*cb_int32)(int32_t);
typedef int8_t  (*cb_int8)(int8_t);
typedef int64_t (*cb_int64)(int64_t);

typedef struct { cb_int32 fn; int32_t data; } SC_basic;
typedef struct { cb_int8  fn; int8_t  data; } SC_i8;
typedef struct { cb_int64 fn; int64_t data; } SC_i64;
typedef struct { cb_int32 fn1; cb_int32 fn2; int32_t data; } SC_two_cbs;

DLLEXPORT int32_t call_basic(SC_basic *s) { return s->fn(s->data); }
DLLEXPORT int8_t  call_i8(SC_i8 *s)       { return s->fn(s->data); }
DLLEXPORT int64_t call_i64(SC_i64 *s)     { return s->fn(s->data); }
DLLEXPORT int32_t call_two(SC_two_cbs *s) { return s->fn1(s->data) + s->fn2(s->data); }
END_C
my $lib = compile_ok($C_CODE);
ok( $lib && -e $lib, 'compiled shared library' );
subtest 'basic struct member callback (int32->int32)' => sub {
    my $st  = Struct [ fn => Pointer [ Callback [ [Int32] => Int32 ] ], data => Int32 ];
    my $fn  = wrap( $lib, 'call_basic', [ Pointer [$st] ], Int32 );
    my $mem = Affix::malloc( sizeof($st) );
    my $pin = cast( $mem, $st );
    $pin->{fn}   = sub ($x) { $x + 1 };
    $pin->{data} = 41;
    is $fn->($pin), 42, 'callback received correct arg and returned correct value';
};
subtest 'struct member callback (int8->int8)' => sub {
    my $st  = Struct [ fn => Pointer [ Callback [ [Int8] => Int8 ] ], data => Int8 ];
    my $fn  = wrap( $lib, 'call_i8', [ Pointer [$st] ], Int8 );
    my $mem = Affix::malloc( sizeof($st) );
    my $pin = cast( $mem, $st );
    $pin->{fn}   = sub ($x) { $x * 2 };
    $pin->{data} = 20;
    is $fn->($pin), 40, 'int8 callback roundtrip';
};
subtest 'struct member callback (int64->int64)' => sub {
    my $st  = Struct [ fn => Pointer [ Callback [ [Int64] => Int64 ] ], data => Int64 ];
    my $fn  = wrap( $lib, 'call_i64', [ Pointer [$st] ], Int64 );
    my $mem = Affix::malloc( sizeof($st) );
    my $pin = cast( $mem, $st );
    $pin->{fn}   = sub ($x) { $x - 100 };
    $pin->{data} = 1_000_000;
    is $fn->($pin), 999_900, 'int64 callback roundtrip';
};
subtest 'struct with two callback pointers' => sub {
    my $st  = Struct [ fn1 => Pointer [ Callback [ [Int32] => Int32 ] ], fn2 => Pointer [ Callback [ [Int32] => Int32 ] ], data => Int32 ];
    my $fn  = wrap( $lib, 'call_two', [ Pointer [$st] ], Int32 );
    my $mem = Affix::malloc( sizeof($st) );
    my $pin = cast( $mem, $st );
    $pin->{fn1}  = sub ($x) {$x};
    $pin->{fn2}  = sub ($x) { $x * 3 };
    $pin->{data} = 10;
    is $fn->($pin), 40, 'two callbacks in one struct';
};
subtest 'struct member callback with negative values' => sub {
    my $st  = Struct [ fn => Pointer [ Callback [ [Int32] => Int32 ] ], data => Int32 ];
    my $fn  = wrap( $lib, 'call_basic', [ Pointer [$st] ], Int32 );
    my $mem = Affix::malloc( sizeof($st) );
    my $pin = cast( $mem, $st );
    $pin->{fn}   = sub ($x) { -$x };
    $pin->{data} = -999;
    is $fn->($pin), 999, 'negative values through struct callback';
};
done_testing;
