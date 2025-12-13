use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
use Config;
use Data::Dumper;

# ============================================================================
# C Source Code Definition
# ============================================================================
my $c_source = <<'END_C';
#include "std.h"
//ext: .c

#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/* --- Primitives & Globals for Pinning --- */
DLLEXPORT int32_t global_counter = 100;
DLLEXPORT double  global_pi      = 3.14159;
DLLEXPORT char    global_buffer[64] = "Initial";

DLLEXPORT int32_t get_counter() { return global_counter; }
DLLEXPORT void    set_counter(int32_t v) { global_counter = v; }

/* --- Structs & Nested Types --- */
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

/* --- Deep Pointers & Arrays --- */
DLLEXPORT void set_int_deep(int*** ptr, int val) {
    if (ptr && *ptr && **ptr) {
        ***ptr = val;
    }
}

DLLEXPORT int sum_array_static(int arr[5]) {
    int sum = 0;
    for(int i=0; i<5; i++) sum += arr[i];
    return sum;
}

/* --- Unions --- */
typedef union {
    int32_t i;
    double  d;
    char    c;
} Variant;

DLLEXPORT double get_variant_val(Variant v, int type) {
    if (type == 0) return (double)v.i;
    if (type == 1) return v.d;
    return 0.0;
}

/* --- Recursive Linked List --- */
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

/* --- Callbacks --- */
// 1. Simple: int -> int
typedef int (*IntMap)(int);
DLLEXPORT int map_int(int val, IntMap cb) {
    return cb(val);
}

// 2. Struct Pointer: Rect* -> void
typedef void (*RectInspector)(Rect*);
DLLEXPORT void inspect_rect(Rect* r, RectInspector cb) {
    cb(r);
}

// 3. Returning Struct: void -> Point
typedef Point (*PointGenerator)(void);
DLLEXPORT int check_point_gen(PointGenerator cb) {
    Point p = cb();
    return p.x + p.y;
}

/* --- Memory Management Helpers --- */
DLLEXPORT void* get_heap_int(int val) {
    int* p = (int*)malloc(sizeof(int));
    *p = val;
    return p;
}

DLLEXPORT void libc_free(void * ptr){free(ptr);}

END_C

# ============================================================================
# Compilation & Setup
# ============================================================================
my $lib = compile_ok( $c_source, "Compiling test library" );
ok( $lib, "Library compiled at $lib" );

# Type Definitions
typedef Point => Struct [ x => Int, y => Int ];
typedef Rect => Struct [ top_left => Point(), bottom_right => Point(), label => Array [ Char, 16 ] ];
typedef 'Node';
typedef Node => Struct [ value => Int, next => Pointer [ Node() ] ];    # Recursive

# ============================================================================
# Tests
# ============================================================================
subtest 'Core Primitives & Pinning' => sub {

    # 1. Basic Functions
    isa_ok my $get = wrap( $lib, 'get_counter', []    => Int ),  ['Affix'];
    isa_ok my $set = wrap( $lib, 'set_counter', [Int] => Void ), ['Affix'];
    is $get->(), 100, 'Initial global value read correctly via function';
    $set->(500);
    is $get->(), 500, 'Global value modified via function';

    # 2. Pinning Scalar
    my $pinned_int;
    ok pin( $pinned_int, $lib, 'global_counter', Int ), 'Pin global_counter';
    is $pinned_int, 500, 'Pinned scalar matches current global value';
    $pinned_int = 999;    # Write via magic
    is $get->(), 999, 'Writing to pinned scalar updates C global';
    $set->(42);           # Use the wrapped function, not direct call
    is $pinned_int, 42, 'Modifying C global updates pinned scalar';
    ok unpin($pinned_int), 'Unpin variable';
    $pinned_int = 0;
    is $get->(), 42, 'Unpinned variable detached from C global';

    # 3. Pinning Array/Buffer
    my $pinned_buf;
    ok pin( $pinned_buf, $lib, 'global_buffer', Array [ Char, 64 ] ), 'Pin char array';
    is $pinned_buf, "Initial", 'Read C string from pinned array';

    # 4. Modifying via Pointer Cast
    my $sym = find_symbol( load_library($lib), 'global_buffer' );

    # Assign the result of cast to a new variable
    my $sym_arr = Affix::cast( $sym, Array [ Char, 64 ] );
    $$sym_arr = "Perl was here";
    is $pinned_buf, "Perl was here", 'Writing string to pinned array persisted in C memory';
};
subtest 'Structs: Value, Pointers, and Write-back' => sub {

    # 1. Pass by Value
    isa_ok my $area = wrap( $lib, 'rect_area_val', [ Rect() ] => Int ), ['Affix'];
    my $r = { top_left => { x => 0, y => 0 }, bottom_right => { x => 10, y => 5 }, label => "Test" };
    is $area->($r), 50, 'Struct passed by value (nested)';

    # 2. Pass by Pointer (Write-back)
    isa_ok my $move = wrap( $lib, 'move_rect_ptr', [ Pointer [ Rect() ], Int, Int ] => Void ), ['Affix'];
    $move->( $r, 5, 5 );
    is $r->{top_left}{x}, 5, 'Nested struct write-back (x)';
    is $r->{top_left}{y}, 5, 'Nested struct write-back (y)';
    like $r->{label}, qr/Moved/, 'Char array in struct write-back';

    # 3. Return by Value
    isa_ok my $mk_pt = wrap( $lib, 'return_struct_val', [ Int, Int ] => Point() ), ['Affix'];
    my $p = $mk_pt->( 100, 200 );
    is $p, { x => 100, y => 200 }, 'Struct returned by value';
};
subtest 'Deep Pointers & Memory' => sub {

    # 1. Deep Indirection (***int)
    isa_ok my $set_deep = wrap( $lib, 'set_int_deep', [ Pointer [ Pointer [ Pointer [Int] ] ], Int ] => Void ), ['Affix'];

    # Manually construct the pointer chain with correct types
    # Keep original 'malloc' pointers alive (managed) while using 'cast' aliases
    # Layer 1: The int value (int*)
    my $p_mem = malloc(8);
    my $p_val = Affix::cast( $p_mem, Pointer [Int] );

    # Assigning directly ($p_val = 0) would overwrite the magic scalar with a normal SV*
    $$p_val = 0;

    # Layer 2: Pointer to Layer 1 (int**)
    my $pp_mem = malloc(8);
    my $pp_val = Affix::cast( $pp_mem, Pointer [ Pointer [Int] ] );
    $$pp_val = $p_val;    # Writes address of $p_mem into $pp_mem

    # Layer 3: Pointer to Layer 2 (int***)
    my $ppp_mem = malloc(8);
    my $ppp_val = Affix::cast( $ppp_mem, Pointer [ Pointer [ Pointer [Int] ] ] );

    # FIXED: Dereference to invoke SET magic, writing the pointer address to memory.
    $$ppp_val = $pp_val;

    # Call Function
    $set_deep->( $ppp_val, 12345 );

    # Verification
    is $$p_val, 12345, '***int deep write successful via Pins';

    # Cleanup (Freeing the originals clears the memory)
    Affix::free($p_mem);
    Affix::free($pp_mem);
    Affix::free($ppp_mem);

    # 2. Manual Memory Management (malloc/free/cast)
    isa_ok my $get_heap = wrap( $lib, 'get_heap_int', [Int] => Pointer [Int] ), ['Affix'];

    # Alias libc free to avoid conflict with Affix::free
    diag affix( $lib, 'libc_free', [ Pointer [Void] ] => Void );
    my $heap_ptr = $get_heap->(99);
    ok $heap_ptr, 'Received pointer from C';
    is $$heap_ptr, 99, 'Dereferenced managed pointer value';
    $$heap_ptr = 88;
    is $$heap_ptr, 88, 'Modified heap memory via magic deref';
    my $void_alias = Affix::cast( $heap_ptr, Pointer [Void] );
    my $addr       = $$void_alias;
    ok $addr > 0, 'Cast to void*, deref returns address';
    my $int_alias = Affix::cast( $void_alias, Pointer [Int] );
    is $$int_alias, 88, 'Cast back to int*, value preserved';

    # Use the bound C free
    libc_free($heap_ptr);
    pass 'Freed C memory';
};
subtest 'Arrays & Unions' => sub {

    # 1. Fixed Arrays passed by value (copy)
    isa_ok my $sum_arr = wrap( $lib, 'sum_array_static', [ Array [ Int, 5 ] ] => Int ), ['Affix'];
    is $sum_arr->( [ 1, 2, 3, 4, 5 ] ), 15, 'Fixed size array passed by value';

    # 2. Unions
    my $Variant = Union [ i => Int, d => Double, c => Char ];
    isa_ok my $get_var = wrap( $lib, 'get_variant_val', [ $Variant, Int ] => Double ), ['Affix'];
    is $get_var->( { i => 42 },  0 ), 42.0, 'Union passed as Int';
    is $get_var->( { d => 3.5 }, 1 ), 3.5,  'Union passed as Double';
};
subtest 'Recursive Data Structures (Linked List)' => sub {
    isa_ok my $sum_nodes = wrap( $lib, 'sum_list', [ Pointer [ Node() ] ] => Int ), ['Affix'];
    my $head = { value => 10, next => { value => 20, next => { value => 30, next => undef } } };
    is $sum_nodes->($head), 60, 'Recursive linked list marshalled correctly';
};
subtest 'Callbacks' => sub {

    # 1. Simple Int -> Int
    isa_ok my $map = wrap( $lib, 'map_int', [ Int, Callback [ [Int] => Int ] ] => Int ), ['Affix'];
    my $res = $map->(
        10,
        sub {
            my $v = shift;
            return $v * 2;
        }
    );
    is $res, 20, 'Simple callback executed';

    # 2. Struct Pointer Argument (Rect*)
    isa_ok my $inspect = wrap( $lib, 'inspect_rect', [ Pointer [ Rect() ], Callback [ [ Pointer [ Rect() ] ] => Void ] ] => Void ), ['Affix'];
    my $r = { top_left => { x => 1, y => 1 }, bottom_right => { x => 2, y => 2 }, label => "Check" };
    my $seen_label;
    $inspect->(
        $r,
        sub {
            my $ptr = shift;

            # $$ptr reads the struct (HashRef)
            # $ptr is now a Pin (scalar ref), so we must dereference it to get the hash.
            my $struct = $$ptr;
            $seen_label = $struct->{label};

            # Modify and write back
            $struct->{label} = "Checked";
            $$ptr = $struct;
        }
    );
    is $seen_label, "Check", 'Callback received struct pointer correctly';

    # 3. Returning Struct from Callback
    isa_ok my $chk_pt = wrap( $lib, 'check_point_gen', [ Callback [ [] => Point() ] ] => Int ), ['Affix'];
    my $sum = $chk_pt->(
        sub {
            return { x => 7, y => 8 };
        }
    );
    is $sum, 15, 'Callback returned struct by value correctly';
};
done_testing;
