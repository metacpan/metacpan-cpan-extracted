use v5.40;
use lib 'lib', 'blib/arch', 'blib/lib';
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all Struct];

# Prepare C library
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c
typedef struct {
    int x, y;
} Point;

static Point g_point = {10, 20};
static int g_array[3] = {1, 2, 3};

DLLEXPORT void* get_point_ptr() { return &g_point; }
DLLEXPORT void* get_array_ptr() { return g_array; }
DLLEXPORT int get_x() { return g_point.x; }
DLLEXPORT int get_array_val(int i) { return g_array[i]; }
END_C
my $lib_path = compile_ok($C_CODE);
affix $lib_path, 'get_point_ptr', []    => Pointer [Void];
affix $lib_path, 'get_array_ptr', []    => Pointer [Void];
affix $lib_path, 'get_x',         []    => Int;
affix $lib_path, 'get_array_val', [Int] => Int;
subtest 'Live Struct' => sub {
    my $ptr  = get_point_ptr();
    my $live = cast $ptr, Live [ Struct [ x => Int, y => Int ] ];
    isa_ok $live, ['Affix::Live'], 'Live struct is blessed as Affix::Live';
    is $live->{x}, 10, 'Initial X is 10';
    $live->{x} = 42;
    is get_x(), 42, 'Modifying live struct affected C memory';
};
subtest 'Live Array' => sub {
    my $ptr  = get_array_ptr();
    my $live = cast $ptr, Live [ Array [ Int, 3 ] ];
    isa_ok $live, ['Affix::Pointer'], 'Live array is an Affix::Pointer';
    is $live->[0], 1, 'Initial [0] is 1';
    $live->[0] = 99;
    is get_array_val(0), 99, 'Modifying live array affected C memory';
};
done_testing;
