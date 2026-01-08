use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
#
$|++;
#
# This C code will be compiled into a temporary library for many of the tests.
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c

typedef struct {
    int x;
    int y;
} Point;

typedef struct {
    Point top_left;
    Point bottom_right;
    char label[16];
} Rect;

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

typedef int (*IntMap)(int);
DLLEXPORT int map_int(int val, IntMap cb) {
    return cb(val);
}

typedef void (*RectInspector)(Rect*);
DLLEXPORT void inspect_rect(Rect* r, RectInspector cb) {
    cb(r);
}

typedef Point (*PointGenerator)(void);
DLLEXPORT int check_point_gen(PointGenerator cb) {
    Point p = cb();
    return p.x + p.y;
}

typedef union {
    int i;
    float f;
    char c[8];
} MyUnion;

DLLEXPORT int invoke_union_cb(void (*cb)(MyUnion*)) {
    MyUnion u;
    u.i = 42;
    cb(&u);
    return u.i;
}
END_C
#
my $lib_path = compile_ok($C_CODE);
ok( $lib_path && -e $lib_path, 'Compiled a test shared library successfully' );
note 'Testing a callback with 10 mixed arguments passed as a direct coderef.';
subtest 'kitchen sink' => sub {
    isa_ok my $harness
        = wrap( $lib_path, 'call_kitchen_sink',
        [ Callback [ [ SInt32, Float64, SInt32, Float64, SInt32, Float64, SInt32, Float64, Pointer [Char], Pointer [SInt32] ] => Void ] ] => SInt32 ),
        ['Affix'];
    my $callback_sub = sub( $a, $b, $c, $d, $e, $f, $g, $h, $i, $j_ref ) {
        is $a,      1,              'Callback arg 1 (int)';
        is $b,      2.0,            'Callback arg 2 (double)';
        is $c,      3,              'Callback arg 3 (int)';
        is $d,      4.0,            'Callback arg 4 (double)';
        is $e,      5,              'Callback arg 5 (int)';
        is $f,      6.0,            'Callback arg 6 (double)';
        is $g,      7,              'Callback arg 7 (int)';
        is $h,      8.0,            'Callback arg 8 (double)';
        is $i,      'kitchen sink', 'Callback arg 9 (string)';
        is $$j_ref, 100,            'Callback arg 10 (int*)';
        $$j_ref = 200;
    };
    is $harness->($callback_sub), 201, 'return value';
};
subtest simple => sub {
    typedef Point => Struct [ x => Int, y => Int ];
    typedef Rect => Struct [ top_left => Point(), bottom_right => Point(), label => Array [ Char, 16 ] ];
    isa_ok my $map = wrap( $lib_path, 'map_int', [ Int, Callback [ [Int] => Int ] ] => Int ), ['Affix'];
    my $res = $map->(
        10,
        sub {
            my $v = shift;
            return $v * 2;
        }
    );
    is $res, 20, 'Simple callback executed';
    #
    isa_ok my $inspect = wrap( $lib_path, 'inspect_rect', [ Pointer [ Rect() ], Callback [ [ Pointer [ Rect() ] ] => Void ] ] => Void ), ['Affix'];
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
    #
    isa_ok my $chk_pt = wrap( $lib_path, 'check_point_gen', [ Callback [ [] => Point() ] ] => Int ), ['Affix'];
    my $sum = $chk_pt->(
        sub {
            return { x => 7, y => 8 };
        }
    );
    is $sum, 15, 'Callback returned struct by value correctly';
};
subtest 'unions passed to callbacks' => sub {
    ok typedef( MyUnion => Union [ i => SInt32, f => Float32, c => Array [ Char, 8 ] ] ), 'typedef @MyUnion';
    isa_ok my $invoke = wrap( $lib_path, 'invoke_union_cb', [ Callback [ [ Pointer [ MyUnion() ] ] => Void ] ] => Int ), ['Affix'];
    my $cb = sub($pin) {

        # Dereference the pin
        my $u = $$pin;
        is $u->{i}, 42, 'Read integer member from union pointer directly';    # magical

        # IEEE 754 2.0f is 0x40000000 (1073741824 decimal)
        $u->{f} = 2.0;
    };
    my $ret = $invoke->($cb);

    # Verify the write inside the callback persisted to the C caller
    is $ret, 1073741824, 'Callback modifications persisted to C (Union write-back)';
};
#
done_testing;
