use v5.40;
use lib 'lib', 'blib/arch', 'blib/lib';
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];

# Prepare C library
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c
typedef struct {
    int x, y;
} Point;

static Point g_point = { 10, 20 };

DLLEXPORT void* get_point_ptr() { return &g_point; }
DLLEXPORT int get_x() { return g_point.x; }
END_C
my $lib_path = compile_ok($C_CODE);
subtest 'Unified Pointer/Struct Access' => sub {
    typedef Point => Struct [ x => Int, y => Int ];
    affix $lib_path, 'get_point_ptr', [] => Pointer [ Point() ];
    my $ptr = get_point_ptr();

    # Standard $ptr is a Pointer[Point]
    # We want $ptr->{x} to work without explicit cast to LiveStruct
    is $ptr->{x}, 10, 'Read x field directly from pointer';
    is $ptr->{y}, 20, 'Read y field directly from pointer';
    $ptr->{x} = 42;
    affix $lib_path, 'get_x', [] => Int;
    is get_x(), 42, 'Write x field directly to pointer affects C memory';
};
subtest 'Unified Access with Recursive Liveness' => sub {
    typedef Rect => Struct [ top_left => Point(), bottom_right => Point() ];
    affix $lib_path, [ get_point_ptr => 'get_rect_ptr' ], [] => Pointer [ Rect() ];
    my $ptr = get_rect_ptr();

    # $ptr->{top_left} should return a Pointer[Point]
    # $ptr->{top_left}->{x} should work recursively
    is $ptr->{top_left}->{x}, 42, 'Read nested field directly from pointer (Recursive)';
};
done_testing;
