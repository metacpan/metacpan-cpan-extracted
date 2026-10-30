use v5.40;
no warnings 'experimental';
use blib;
use Affix               qw[:all];
use Test2::Tools::Affix qw[:all];
use Config;
use Benchmark qw[:all];
$|++;
diag 'Affix ' . $Affix::VERSION;

# Conditionally load FFI::Platypus and Inline::C
my ( $has_platypus, $has_inline_c );

BEGIN {
    try {
        builtin::load_module 'FFI::Platypus';
        FFI::Platypus->import();
        $has_platypus = 1;
        diag 'FFI::Platypus found, including it in benchmarks.';
    }
    catch ($e) {
        diag 'FFI::Platypus not found, skipping its benchmarks.';
    }
    try {
        builtin::load_module 'Inline';
        Inline->import();
        $has_inline_c = 1;
        diag 'Inline::C found, including it in benchmarks.';
    }
    catch ($e) {
        diag 'Inline::C not found, skipping its benchmarks.';
    }
}

# Prepare a C library for benchmarking
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c
#include <stdlib.h>
#include <stdint.h>
#include <math.h>

typedef struct {
    int32_t a, b, c, d;
} BenchStruct;

typedef struct {
    BenchStruct nested;
    int32_t id;
} OuterStruct;

typedef enum {
    RED = 1,
    GREEN = 2,
    BLUE = 3
} Color;

DLLEXPORT double fast_pow(double x, double y) { return x + y; }
DLLEXPORT double benchmark_sin(double x) { return sin(x); }
DLLEXPORT void* get_ptr() { static int32_t dummy = 42; return &dummy; }
DLLEXPORT int32_t take_ptr(int32_t* p) { return *p; }
DLLEXPORT BenchStruct get_struct() { static BenchStruct s = {1, 2, 3, 4}; return s; }
DLLEXPORT OuterStruct get_outer() { static OuterStruct o = {{10, 20, 30, 40}, 99}; return o; }
DLLEXPORT int32_t take_enum(Color c) { return (int32_t)c; }
DLLEXPORT Color return_enum(int32_t v) { return (Color)v; }

#if defined(__SIZEOF_INT128__)
typedef __int128 int128_t;
DLLEXPORT int128_t add128(int128_t a, int128_t b) { return a + b; }
#endif
END_C
my $lib  = compile_ok($C_CODE);
my $libm = '' . libm();

# affix Bindings
affix $lib, 'fast_pow',      [ Double, Double ] => Double;
affix $lib, 'benchmark_sin', [Double]           => Double;
affix $lib, 'get_ptr',       []                 => Pointer [Int];
affix $lib, 'take_ptr',      [ Pointer [Int] ]  => Int;
affix $lib, 'get_struct',    []                 => Struct [ a => Int, b => Int, c => Int, d => Int ];
affix $lib, 'get_outer',     []                 => Struct [ nested => Struct [ a => Int, b => Int, c => Int, d => Int ], id => Int ];
typedef Color => Enum [ [ RED => 1 ], [ GREEN => 2 ], [ BLUE => 3 ] ];
affix $lib, 'take_enum',   [ Color() ] => Int;
affix $lib, 'return_enum', [Int]       => Color();

# Affix wrap Variants
my $wrap_sin   = wrap $lib,        'benchmark_sin', [Double], Double;
my $direct_sin = direct_wrap $lib, 'benchmark_sin', [Double], Double;

# FFI::Platypus Bindings
my ( $ffi, $platypus_sin_func );
if ($has_platypus) {
    $ffi = FFI::Platypus->new( api => 2, lib => "$lib" );
    $ffi->attach( [ fast_pow      => 'platypus_fast_pow' ],    [ 'double', 'double' ] => 'double' );
    $ffi->attach( [ benchmark_sin => 'platypus_sin' ],         ['double']             => 'double' );
    $ffi->attach( [ get_ptr       => 'platypus_get_ptr' ],     []                     => 'int*' );
    $ffi->attach( [ take_ptr      => 'platypus_take_ptr' ],    ['int*']               => 'int' );
    $ffi->attach( [ take_enum     => 'platypus_take_enum' ],   ['int']                => 'int' );
    $ffi->attach( [ return_enum   => 'platypus_return_enum' ], ['int']                => 'int' );
    $platypus_sin_func = $ffi->function( 'benchmark_sin', ['double'] => 'double' );

    package BenchStruct {
        use FFI::Platypus::Record;
        record_layout_1( int => 'a', int => 'b', int => 'c', int => 'd' );
    }
    $ffi->type( 'record(BenchStruct)' => 'BenchStruct' );
    $ffi->attach( [ get_struct => 'platypus_get_struct' ], [] => 'BenchStruct' );
}

# Inline::C Bindings
Inline->import( C => <<'END_OF_C' ) if $has_inline_c;
#include <math.h>
double inline_sin(double x) { return sin(x); }
END_OF_C

# Verification
my $num = 1.5;
subtest verify => sub {
    is benchmark_sin($num), float( sin($num), tolerance => 0.000001 ), 'affix correctly calculates sin';
    is $wrap_sin->($num),   float( sin($num), tolerance => 0.000001 ), 'wrap correctly calculates sin';
    is $direct_sin->($num), float( sin($num), tolerance => 0.000001 ), 'direct_wrap correctly calculates sin';
    if ($has_platypus) {
        is platypus_sin($num),         float( sin($num), tolerance => 0.000001 ), 'platypus [attach] correctly calculates sin';
        is $platypus_sin_func->($num), float( sin($num), tolerance => 0.000001 ), 'platypus [function] correctly calculates sin';
    }
    if ($has_inline_c) {
        is inline_sin($num), float( sin($num), tolerance => 0.000001 ), 'inline correctly calculates sin';
    }
};

# Benchmarks
my $bench_count = -5;
my $ptr         = malloc(4);
$$ptr = 123;
is fastest(
    $bench_count,                                                                    #
    Affix    => sub { fast_pow( 1.5, 2.5 ) },                                        #
    Platypus => ( $has_platypus ? ( sub { platypus_fast_pow( 1.5, 2.5 ) } ) : () )
    ),
    'Affix', ' func pow(1.5, 2.5)';
isnt fastest(
    $bench_count,
    Affix    => sub { benchmark_sin(0.5) },                                          #
    Platypus => ( $has_platypus ? ( sub { platypus_sin(0.5) } ) : () ),              #
    Inline   => ( $has_inline_c ? ( sub { inline_sin(0.5) } )   : () )
    ),
    'Platypus', 'func sin(0.5)';
is fastest(
    $bench_count,                                                                    #
    Affix    => sub { $wrap_sin->(0.5) },                                            #
    Platypus => ( $has_platypus ? ( sub { $platypus_sin_func->(0.5) } ) : () )
    ),
    'Affix', 'anon sin(0.5)';
is fastest(
    $bench_count,                                                                    #
    Affix    => sub { take_ptr($ptr) },                                              #
    Platypus => ( $has_platypus ? ( sub { platypus_take_ptr($ptr) } ) : () )
    ),
    'Affix', 'pass pointer';
is fastest(
    $bench_count,                                                                    #
    Affix    => sub { my $x = get_ptr() },                                           #
    Platypus => ( $has_platypus ? ( sub { my $x = platypus_get_ptr() } ) : () )
    ),
    'Affix', 'return pointer';
is fastest(
    $bench_count,                                                                    #
    Affix    => sub { get_struct() },                                                #
    Platypus => ( $has_platypus ? ( sub { platypus_get_struct() } ) : () )
    ),
    'Affix', 'Aggregate Marshalling';
like fastest(
    $bench_count,
    'Affix: pass_int'    => sub { take_enum(2) },
    'Affix: pass_str'    => sub { take_enum('GREEN') },
    'Affix: return'      => sub { return_enum(3) },
    'Platypus: pass_int' => ( $has_platypus ? ( sub { platypus_take_enum(2) } )   : () ),
    'Platypus: return'   => ( $has_platypus ? ( sub { platypus_return_enum(3) } ) : () )
    ),
    qr/^Affix/, 'Enum Marshalling';
my $has_live = eval { LiveStruct( [ a => Int ] ); 1 };
if ($has_live) {
    my $Inner = Struct [ a => Int, b => Int, c => Int, d => Int ];
    eval 'affix $lib, [ get_struct => "get_struct_live" ], [] => LiveStruct $Inner';
    my $live_struct = get_struct_live();
    my $copy_struct = get_struct();
    like fastest(
        $bench_count,
        'struct_copy_pull'   => sub { get_struct() },
        'struct_live_pull'   => sub { get_struct_live() },
        'member_access_copy' => sub { my $v             = $copy_struct->{a} },
        'member_access_live' => sub { my $v             = $live_struct->{a} },
        'member_write_live'  => sub { $live_struct->{a} = 100 },
        ),
        qr/live|access|write/, 'Live vs Copy Aggregates';
}
my $live_ptr   = get_ptr();
my $live_array = calloc( 10, Int );
like fastest(
    $bench_count,
    ptr_deref_magic  => sub { my $v          = $$live_ptr },
    ptr_indexing_r   => sub { my $v          = $live_ptr->[0] },
    ptr_indexing_w   => sub { $live_ptr->[0] = 42 },
    array_indexing_r => sub { my $v          = $live_array->[5] },
    ),
    qr/ptr|array/, 'Pointer and Array Indexing';
subtest i128 => sub {
    skip_all 'No 128bit integer support', 1 unless eval { Int128(); 1 };
    affix $lib, 'add128', [ Int128, Int128 ] => Int128;
    my $a = '170141183460469231731687303715884105727';
    my $b = '1';
    is fastest( $bench_count, 'add128' => sub { add128( $a, $b ) } ), 'add128', '128-bit Integers';
};
done_testing;

sub fastest ( $times, %marks ) {
    delete $marks{$_} for grep { !defined $marks{$_} } keys %marks;
    note sprintf 'running %s for %s seconds each', join( ', ', keys %marks ), abs($times);
    my @marks;
    my $len = [ sort { $b <=> $a } map { length $_ } keys %marks ]->[0];
    for my $name ( sort keys %marks ) {
        my $res = timethis( $times, $marks{$name}, '', 'none' );
        my ( $r, $pu, $ps, $cu, $cs, $n ) = @$res;
        push @marks, { name => $name, res => $res, n => $n, s => ( $pu + $ps ) };
        note sprintf '%' . ( $len + 1 ) . 's - %s', $name, timestr($res);
    }
    my $results = cmpthese {
        map { $_->{name} => $_->{res} } @marks
    }, 'none';
    my $len_1 = [ sort { $b <=> $a } map { length $_->[1] } @$results ]->[0];
    note sprintf '%-' . ( $len + 1 ) . 's %' . ( $len_1 + 1 ) . 's' . ( ' %5s' x ( scalar( @{ $results->[0] } ) - 2 ) ), @$_ for @$results;
    [ sort { $b->{n} * $a->{s} <=> $a->{n} * $b->{s} } @marks ]->[0]->{name};
}
