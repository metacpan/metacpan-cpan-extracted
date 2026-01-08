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

/* Simple Struct */
typedef struct {
    int x;
    int y;
} Point;

/* Nested Struct */
typedef struct {
    Point top_left;
    Point bottom_right;
} Rect;

/* Union */
typedef union {
    int32_t as_int;
    double  as_double;
    char    as_char;
} Variant;

/* Recursive Struct (Linked List) with Array and Union */
typedef struct Node {
    int id;
    Variant data;
    int type_flag;        // 0 = int, 1 = double, 2 = char
    int matrix[2][2];     // Nested fixed-size array
    struct Node* next;    // Recursive pointer
} Node;

/*
 * Calculates the area of a Rect passed by value.
 * Tests nested struct marshalling (Perl -> C).
 */
DLLEXPORT int rect_area(Rect r) {
    int width  = r.bottom_right.x - r.top_left.x;
    int height = r.bottom_right.y - r.top_left.y;
    return width * height;
}

/*
 * Modifies a Point passed by pointer.
 * Tests pointer write-back (C -> Perl).
 */
DLLEXPORT void move_point(Point* p, int dx, int dy) {
    if (p) {
        p->x += dx;
        p->y += dy;
    }
}

/*
 * Traverses a linked list of Nodes and sums the values.
 * Tests recursive types, pointers, unions, and arrays.
 */
DLLEXPORT double sum_nodes(Node* head) {
    double total = 0;
    Node* current = head;

    while (current) {
        // Add value from union based on flag
        if (current->type_flag == 0)      total += current->data.as_int;
        else if (current->type_flag == 1) total += current->data.as_double;
        else if (current->type_flag == 2) total += current->data.as_char;

        // Add diagonal of the matrix
        total += current->matrix[0][0];
        total += current->matrix[1][1];

        current = current->next;
    }
    return total;
}

/*
 * Returns a static pointer to a nested struct.
 * Tests unmarshalling deep structures (C -> Perl).
 */
static Rect static_rect = { {0, 0}, {10, 20} };
DLLEXPORT Rect* get_static_rect(void) {
    return &static_rect;
}

END_C

# 2. Compile the library
my $lib = compile_ok($c_source);

# 3. Define Types in Affix
# ------------------------
# Simple Struct: Point
# typedef Point => Struct [ x => Int, y => Int ];
# (Alternative manual syntax for demonstration):
my $Point = Struct [ x => Int, y => Int ];

# Nested Struct: Rect
# Uses the previously defined $Point object
my $Rect = Struct [ top_left => $Point, bottom_right => $Point ];

# Union: Variant
my $Variant = Union [ as_int => Int, as_double => Double, as_char => Char ];

# Recursive Struct: Node
# We use a named typedef here so the 'next' field can refer to itself.
typedef 'Node';
typedef 'Node' => Struct [
    id        => Int,
    data      => $Variant,
    type_flag => Int,

    # 2x2 Array of Ints (Array of Arrays)
    matrix => Array [ Array [ Int, 2 ], 2 ],
    next   => Pointer [ Node() ]
];

# 4. Bind Functions
# -----------------
# int rect_area(Rect r)
isa_ok my $rect_area = wrap( $lib, 'rect_area', [$Rect] => Int ), ['Affix'];

# void move_point(Point* p, int dx, int dy)
isa_ok my $move_point = wrap( $lib, 'move_point', [ Pointer [$Point], Int, Int ] => Void ), ['Affix'];

# double sum_nodes(Node* head)
isa_ok my $sum_nodes = wrap( $lib, 'sum_nodes', [ Pointer [ Node() ] ] => Double ), ['Affix'];

# Rect* get_static_rect()
isa_ok my $get_static_rect = wrap( $lib, 'get_static_rect', [] => Pointer [$Rect] ), ['Affix'];

# 5. Run Tests
# ------------
subtest 'Nested Structs (Pass by Value)' => sub {

    # { top_left => {x,y}, bottom_right => {x,y} }
    my $r = { top_left => { x => 10, y => 10 }, bottom_right => { x => 30, y => 20 } };

    # Width = 20, Height = 10, Area should be 200
    is $rect_area->($r), 200, 'Nested struct passed by value correctly marshalled';
};
subtest 'Pointers and Write-back' => sub {
    my $p = { x => 100, y => 100 };

    # Pass $p as a pointer (Affix handles the reference automatically if defined as Pointer[])
    $move_point->( $p, 50, -25 );
    is $p->{x}, 150, 'Struct member X modified via pointer';
    is $p->{y}, 75,  'Struct member Y modified via pointer';
};
subtest 'Unions, Arrays, and Recursive Linked Lists' => sub {

    # Construct a linked list in Perl: Node1 -> Node2 -> Node3 -> NULL
    # Node 3: Char type (value 10), Matrix diag (1, 1) = sum 12
    my $node3 = {
        id        => 3,
        type_flag => 2,                        # char
        data      => { as_char => 10 },
        matrix    => [ [ 1, 0 ], [ 0, 1 ] ],
        next      => undef
    };

    # Node 2: Double type (value 5.5), Matrix diag (2, 2) = sum 9.5
    my $node2 = {
        id        => 2,
        type_flag => 1,                        # double
        data      => { as_double => 5.5 },
        matrix    => [ [ 2, 0 ], [ 0, 2 ] ],
        next      => $node3                    # Link to node 3
    };

    # Node 1: Int type (value 100), Matrix diag (0, 0) = sum 100
    my $node1 = {
        id        => 1,
        type_flag => 0,                        # int
        data      => { as_int => 100 },
        matrix    => [ [ 0, 0 ], [ 0, 0 ] ],
        next      => $node2                    # Link to node 2
    };

    # Expected sum:
    # N3: 10 + 1 + 1   = 12
    # N2: 5.5 + 2 + 2  = 9.5
    # N1: 100 + 0 + 0  = 100
    # Total = 121.5
    my $total = $sum_nodes->($node1);
    is $total, 121.5, 'Complex recursive struct with union and arrays marshalled correctly';
};
subtest 'Pinning / Dereferencing Deep Structures' => sub {

    # Get a pointer to the static C struct
    my $ptr = $get_static_rect->();

    # Verify we got a pointer-like SV (unblessed ref with magic, per new implementation)
    ok $ptr, 'Got a pointer';

    # Dereference to read (Deep copy from C -> Perl)
    my $val = $$ptr;
    is $val, { top_left => { x => 0, y => 0 }, bottom_right => { x => 10, y => 20 } }, 'Dereferenced nested struct pointer correctly';

    # Modify via pointer using pinning syntax logic (write to C)
    # Since $ptr is magic, assigning to $$ptr should marshal data back to C memory
    $$ptr = { top_left => { x => 99, y => 99 }, bottom_right => { x => 100, y => 100 } };

    # Read again to verify round-trip
    my $val_new = $$ptr;
    is $val_new->{top_left}{x}, 99, 'Write-back to static C struct via magic successful';

    # Verify it persists (call the C accessor again)
    my $ptr2 = $get_static_rect->();
    is $$ptr2->{top_left}{x}, 99, 'Changes persisted in C memory';
};
#
done_testing;
