use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
#
$|++;
#
note 'Defining named types for subsequent tests.';
subtest 'Define multiple types' => sub {
    ok typedef( Point    => Struct [ x => SInt32, y => SInt32 ] ),                                     'typedef @Point';
    ok typedef( Rect     => Struct [ top_left => Point(), bottom_right => Point() ] ),                 'typedef @Rect';
    ok typedef( RectPlus => Struct [ top_left => Point(), bottom_right => Point(), Pointer [Char] ] ), 'typedef @RectPlus';
    ok typedef( MyStruct => Struct [ id => SInt32, value => Float64, label => Pointer [Char] ] ),      'typedef @MyStruct';
    ok typedef( MyUnion  => Union [ i => SInt32, f => Float32, c => Array [ Char, 8 ] ] ),             'typedef @MyUnion';
};
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c

#include <stdint.h>
#include <stdbool.h>
#include <string.h> // For strcmp
#include <stdlib.h> // For malloc

typedef struct {
    int32_t id;
    double value;
    const char* label;
} MyStruct;

typedef enum { RED, GREEN, BLUE } Color;

DLLEXPORT int check_color(Color c) {
    if (c == GREEN) return 1;
    return 0;
}

DLLEXPORT int sum_struct_ids(MyStruct* structs, int count) {
    int total = 0;
    for (int i = 0; i < count; i++) {
        total += structs[i].id;
    }
    return total;
}



typedef struct {
    int x;
    int y;
} Point;

DLLEXPORT Point create_point(int x, int y) {
    Point p = {x, y};
    return p;
}

DLLEXPORT int sum_point_by_val(Point p) {
    return p.x + p.y;
}

typedef struct {
    Point top_left;
    Point bottom_right;
    const char* name;
} Rectangle;

DLLEXPORT int get_rect_width(Rectangle* r) {
    if (!r) return -1;
    return r->bottom_right.x - r->top_left.x;
}

typedef union {
    int i;
    float f;
    char c[8];
} MyUnion;

DLLEXPORT float process_union_float(MyUnion u) {
    return u.f * 10.0;
}


DLLEXPORT int read_union_int(MyUnion u) {
    return u.i;
}

// Takes a callback that processes a struct
DLLEXPORT double process_struct_with_cb(MyStruct* s, double (*cb)(MyStruct*)) {
    return cb(s);
}

// Takes a callback that returns a struct
DLLEXPORT int check_returned_struct_from_cb(Point (*cb)(void)) {
    Point p = cb();
    return p.x + p.y;
}
END_C
#
my $lib_path = compile_ok($C_CODE);
ok( $lib_path && -e $lib_path, 'Compiled a test shared library successfully' );
subtest 'Forward Calls: Advanced Pointers and Arrays of Structs (with Typedefs)' => sub {
    plan 2;
    note 'Testing marshalling arrays of structs using typedefs.';
    isa_ok my $sum_ids = wrap( $lib_path, 'sum_struct_ids', '(*@MyStruct, int32)->int32' ), ['Affix'];
    my $struct_array
        = [ { id => 10, value => 1.1, label => 'A' }, { id => 20, value => 2.2, label => 'B' }, { id => 30, value => 3.3, label => 'C' }, ];
    is $sum_ids->( $struct_array, 3 ), 60, 'Correctly passed an array of structs and summed IDs';
};
subtest 'Forward Calls: Enums and Unions (with Typedefs)' => sub {
    plan 4;
    note 'Testing marshalling for enums and unions.';
    isa_ok my $check_color = wrap( $lib_path, 'check_color', '(int32)->int32' ), ['Affix'];
    is $check_color->(1), 1, 'Correctly passed an enum value (GREEN)';
    isa_ok my $process_union = wrap( $lib_path, 'process_union_float', '(@MyUnion)->float32' ), ['Affix'];
    my $union_data = { f => 2.5 };
    is $process_union->($union_data), float(25.0), 'Correctly passed a union with the float member active';
};
subtest 'Forward Calls: Nested Structs and By-Value Returns (with Typedefs)' => sub {
    plan 4;
    isa_ok my $get_width = wrap( $lib_path, 'get_rect_width', '(*@RectPlus)->int32' ), ['Affix'];
    is $get_width->( \{ top_left => { x => 10, y => 20 }, bottom_right => { x => 60, y => 80 }, name => 'My Rectangle' } ), 50,
        'Correctly passed nested struct and calculated width';
    isa_ok my $create_point = wrap( $lib_path, 'create_point', '(int32, int32)->@Point' ), ['Affix'];
    my $point = $create_point->( 123, 456 );
    is $point, { x => 123, y => 456 }, 'Correctly received a struct returned by value';
};
subtest 'Advanced Structs and Unions' => sub {
    affix $lib_path, 'sum_point_by_val', '(@Point)->int';
    my $point_hash = { x => 10, y => 25 };
    is( sum_point_by_val($point_hash), 35, 'Correctly passed a struct by value' );
    affix $lib_path, 'read_union_int', '(@MyUnion)->int';
    my $union_hash = { i => 999 };
    is( read_union_int($union_hash), 999, 'Correctly read int member from a C union' );
};
subtest 'Advanced Callbacks (Reverse FFI) (with Typedefs)' => sub {
    diag 'Testing callbacks that send and receive structs by passing coderefs directly.';
    isa_ok my $harness1 = wrap( $lib_path, 'process_struct_with_cb', '(*@MyStruct, (*(@MyStruct))->float64)->float64' ), ['Affix'];
    my $struct_to_pass = { id => 100, value => 5.5, label => 'Callback Struct' };
    my $cb1            = sub ($struct_ref) {

        # Struct Pointer comes as a Pin (Scalar Ref). Dereference it.
        my $struct = $$struct_ref;
        return $struct->{value} * 2;
    };
    is $harness1->( $struct_to_pass, $cb1 ), 11.0, 'Callback coderef received struct pointer and returned correct value';
    isa_ok my $harness2 = wrap( $lib_path, 'check_returned_struct_from_cb', '( *(()->void  )->@Point )->int32' ), ['Affix'];
    is $harness2->(
        sub {
            pass "Inside callback that will return a struct";
            return { x => 70, y => 30 };
        }
        ),
        100, 'C code correctly received a struct returned by value from a Perl callback';
};
done_testing;
__END__


/* Basic Primitives */
DLLEXPORT int add(int a, int b) { return a + b; }
DLLEXPORT unsigned int u_add(unsigned int a, unsigned int b) { return a + b; }

// Functions to test every supported primitive type
DLLEXPORT int8_t   echo_int8   (int8_t   v) { return v; }
DLLEXPORT uint8_t  echo_uint8  (uint8_t  v) { return v; }
DLLEXPORT int16_t  echo_int16  (int16_t  v) { return v; }
DLLEXPORT uint16_t echo_uint16 (uint16_t v) { return v; }
DLLEXPORT int32_t  echo_int32  (int32_t  v) { return v; }
DLLEXPORT uint32_t echo_uint32 (uint32_t v) { return v; }
DLLEXPORT int64_t  echo_int64  (int64_t  v) { return v; }
DLLEXPORT uint64_t echo_uint64 (uint64_t v) { return v; }
DLLEXPORT float    echo_float  (float    v) { return v; }
DLLEXPORT double   echo_double (double   v) { return v; }
DLLEXPORT bool     echo_bool   (bool     v) { return v; }

/* Pointers and References */
DLLEXPORT const char* get_hello_string() { return "Hello from C"; }
DLLEXPORT bool set_hello_string(const char * hi) { return strcmp(hi, "Hello from Perl")==0; }

// Dereferences a pointer and returns its value + 10.
DLLEXPORT int deref_and_add(int* p) {
    if (!p) return -1;
    return *p + 10;
}

// Modifies the integer pointed to by the argument.
DLLEXPORT void modify_int_ptr(int* p, int new_val) {
    if (p) *p = new_val + 1;
}

// Takes a pointer to a pointer and verifies the string.
DLLEXPORT int check_string_ptr_ptr(char** s) {
    if (s && *s && strcmp(*s, "perl") == 0) {
        // Modify the inner pointer to prove we can
        *s = "C changed me";
        return 1; // success
    }
    return 0; // failure
}

// "Constructor" for the struct.
DLLEXPORT void init_struct(MyStruct* s, int32_t id, double value, const char* label) {
    if (s) {
        s->id = id;
        s->value = value;
        s->label = label;
    }
}

// "Getter" for a struct member.
DLLEXPORT int32_t get_struct_id(MyStruct* s) {
    return s ? s->id : -1;
}

// Sums an array of 64-bit integers.
DLLEXPORT int64_t sum_s64_array(int64_t* arr, int len) {
    int64_t total = 0;
    for (int i = 0; i < len; i++)
        total += arr[i];
    return total;
}

// Returns a pointer to a static internal struct
MyStruct g_struct = { 99, -1.0, "Global" };
DLLEXPORT MyStruct* get_static_struct_ptr() {
    return &g_struct;
}


/* Advanced Pointers */
DLLEXPORT bool check_is_null(void* p) {
    return (p == NULL);
}
// Takes a void* and casts it to an int*
DLLEXPORT int read_int_from_void_ptr(void* p) {
    if (!p) return -999;
    return *(int*)p;
}






// A callback with many arguments to test register/stack passing
typedef void (*kitchen_sink_cb)(
    int a, double b, int c, double d, int e, double f, int g, double h,
    const char* i, int* j
);
DLLEXPORT int call_kitchen_sink(kitchen_sink_cb cb) {
    int j_val = 100;
    cb(1, 2.0, 3, 4.0, 5, 6.0, 7, 8.0, "kitchen sink", &j_val);
    return j_val + 1;
}

/* Functions with many arguments */
DLLEXPORT long long multi_arg_sum(
    long long a, long long b, long long c, long long d,
    long long e, long long f, long long g, long long h, long long i
) {
    return a + b + c + d + e + f + g + h + i;
}

/* Simple Callback Harness */
DLLEXPORT int call_int_cb(int (*cb)(int), int val) {
    return cb(val);
}

DLLEXPORT double call_math_cb(double (*cb)(double, int), double d, int i) {
    return cb(d, i);
}

DLLEXPORT int sum_int_array(int* arr, int count) {
    int total = 0;
    for (int i = 0; i < count; i++)
        total += arr[i];
    return total;
}


DLLEXPORT char get_char_at(char s[20], int index) {
    warn("# get_char_at('%s', %d);", s, index);
    if (index >= 20 || index < 0) return '!';
    return s[index];
}


DLLEXPORT float sum_float_array(float* arr, int len) {
    float total = 0.0f;
    for (int i = 0; i < len; i++)
        total += arr[i];
    return total;
}

#if !(defined(__FreeBSD__) && defined(__aarch64__))
/* Long Double */
DLLEXPORT long double add_ld(long double a, long double b) {
    return a + b;
}

DLLEXPORT double ld_to_d(long double a) {
    return (double)a;
}
#endif
