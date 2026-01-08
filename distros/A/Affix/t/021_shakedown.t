use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
#
my $c_source = <<'END_C';
#include "std.h"
//ext: .c

#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

// Primitives & Globals for Pinning
DLLEXPORT int32_t global_counter = 100;
DLLEXPORT double  global_pi      = 3.14159;
DLLEXPORT char    global_buffer[64] = "Initial";

DLLEXPORT int32_t get_counter() { return global_counter; }
DLLEXPORT void    set_counter(int32_t v) { global_counter = v; }

// Structs & Nested Types
typedef struct {
    int x;
    int y;
} Point;

typedef struct {
    Point top_left;
    Point bottom_right;
    char label[16];
} Rect;

DLLEXPORT int rect_area_val(Rect r) {
    int w = r.bottom_right.x - r.top_left.x;
    int h = r.bottom_right.y - r.top_left.y;
    return w * h;
}

DLLEXPORT void move_rect_ptr(Rect* r, int dx, int dy) {
    if (r) {
        r->top_left.x += dx;
        r->top_left.y += dy;
        r->bottom_right.x += dx;
        r->bottom_right.y += dy;
        snprintf(r->label, 16, "Moved");
    }
}

DLLEXPORT Point return_struct_val(int x, int y) {
    Point p = { x, y };
    return p;
}

// Recursive Linked List
typedef struct Node {
    int value;
    struct Node* next;
} Node;

DLLEXPORT int sum_list(Node* head) {
    int sum = 0;
    while(head) {
        sum += head->value;
        head = head->next;
    }
    return sum;
}
END_C
#
my $lib = compile_ok($c_source);
ok( $lib, "Library compiled at $lib" );
#
typedef Point => Struct [ x => Int, y => Int ];
typedef Rect => Struct [ top_left => Point(), bottom_right => Point(), label => Array [ Char, 16 ] ];
typedef 'Node';
typedef Node => Struct [ value => Int, next => Pointer [ Node() ] ];    # Recursive
#
subtest 'Structs: Value, Pointers, and Write-back' => sub {
    isa_ok my $area = wrap( $lib, 'rect_area_val', [ Rect() ] => Int ), ['Affix'];
    my $r = { top_left => { x => 0, y => 0 }, bottom_right => { x => 10, y => 5 }, label => "Test" };
    is $area->($r), 50, 'Struct passed by value (nested)';
    #
    isa_ok my $move = wrap( $lib, 'move_rect_ptr', [ Pointer [ Rect() ], Int, Int ] => Void ), ['Affix'];
    $move->( $r, 5, 5 );
    is $r->{top_left}{x}, 5, 'Nested struct write-back (x)';
    is $r->{top_left}{y}, 5, 'Nested struct write-back (y)';
    like $r->{label}, qr/Moved/, 'Char array in struct write-back';
    #
    isa_ok my $mk_pt = wrap( $lib, 'return_struct_val', [ Int, Int ] => Point() ), ['Affix'];
    my $p = $mk_pt->( 100, 200 );
    is $p, { x => 100, y => 200 }, 'Struct returned by value';
};
subtest 'Recursive Data Structures (Linked List)' => sub {
    isa_ok my $sum_nodes = wrap( $lib, 'sum_list', [ Pointer [ Node() ] ] => Int ), ['Affix'];
    my $head = { value => 10, next => { value => 20, next => { value => 30, next => undef } } };
    is $sum_nodes->($head), 60, 'Recursive linked list marshalled correctly';
};
#
done_testing;
