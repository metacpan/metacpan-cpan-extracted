use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];

# Prepare C library
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c
typedef struct {
    int x, y;
} Point;

typedef struct {
    Point top_left;
    Point bottom_right;
} Rect;

static Rect g_rect = { {10, 10}, {50, 50} };

DLLEXPORT void* get_rect_ptr() { return &g_rect; }
DLLEXPORT int get_tl_x() { return g_rect.top_left.x; }
END_C
my $lib_path = compile_ok($C_CODE);
typedef Point => Struct [ x => Int, y => Int ];
typedef Rect => Struct [ top_left => Point(), bottom_right => Point() ];
subtest 'Recursive Liveness (Struct in Struct)' => sub {

    # Cast to Live
    affix $lib_path, 'get_rect_ptr', [] => Pointer [ Rect() ];
    my $ptr  = get_rect_ptr();
    my $live = cast( $ptr, Rect() );

    # top_left should be a Live view (Hash)
    my $tl = $live->{top_left};
    is $tl->{x}, 10, 'Initial nested value ok via unified hash access';

    # Write to nested member
    $tl->{x} = 42;
    affix $lib_path, 'get_tl_x', [] => Int;
    is get_tl_x(), 42, 'Modified nested member via live view affected C memory';
};
subtest 'Recursive Liveness (Array in Struct)' => sub {
    typedef NestedArray => Struct [ id => Int, data => Array [ Int, 4 ] ];
    affix $lib_path, [ get_rect_ptr => 'get_arr_ptr' ], [] => Pointer [ NestedArray() ];
    my $ptr  = get_arr_ptr();
    my $live = cast( $ptr, NestedArray() );
    my $arr  = $live->{data};
    $arr->[0] = 999;
    is $arr->[0], 999, 'Modified nested array via live view';
};
subtest 'Recursive Liveness: Live array of Structs' => sub {
    my $Point    = Struct [ x => Int, y => Int ];
    my $ptr      = malloc( sizeof($Point) * 2 );
    my $live_arr = cast( $ptr, Array [ $Point, 2 ] );

    # Set values
    $live_arr->[0]{x} = 10;
    $live_arr->[0]{y} = 20;

    # Accessing $live_arr->[0] returns an Affix::Live blessed hash
    my $p0 = $live_arr->[0];
    $p0->{x} = 30;
    is $live_arr->[0]{x}, 30, 'Changes to live element reflect in original memory';
};
subtest 'Recursive Liveness: Live struct with Array' => sub {

    # Using typedef to ensure member names are preserved in the infix registry
    typedef ListStruct => Struct [ items => Array [ Int, 3 ] ];
    my $ptr         = malloc( sizeof( ListStruct() ) );
    my $live_struct = cast( $ptr, ListStruct() );

    # Accessing $live_struct->{items} returns an Affix::Pointer object
    my $items = $live_struct->{items};
    $items->[0] = 100;
    is $live_struct->{items}[0], 100, 'Changes to live array field reflect in struct';
};
#
done_testing;
