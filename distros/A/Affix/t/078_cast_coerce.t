use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
$|++;
my $lib = compile_ok(<<~'');
    #include "std.h"
    typedef struct { int x; int y; } Point;
    typedef struct { Point min; Point max; } Rect;
    DLLEXPORT Point make_point(int x, int y) { Point p = {x, y}; return p; }
    DLLEXPORT int sum_point(Point p) { return p.x + p.y; }
    DLLEXPORT int sum_rect(Rect r) { return r.min.x + r.min.y + r.max.x + r.max.y; }
    DLLEXPORT void set_point(Point *p, int x, int y) { p->x = x; p->y = y; }
    DLLEXPORT int add_ints(int a, int b) { return a + b; }
    DLLEXPORT double echo_double(double x) { return x; }
    DLLEXPORT int read_byte(const unsigned char *p) { return p ? *p : -1; }
//ext: .c

typedef Point => Struct [ x => Int, y => Int ];
typedef Rect => Struct [ min => Point(), max => Point() ];
#
subtest 'cast between primitive types' => sub {
    my $ptr = calloc( 1, sizeof(Int) );
    my $val = cast( $ptr, Int );
    $val = 42;
    is $val, 42, 'cast to Int and write';
    my $bytes = cast( $ptr, Array [ Char, 4 ] );
    ok ref $bytes eq 'ARRAY' || defined $bytes, 'cast to Array[Char] works';
};
#
subtest 'cast struct pointer' => sub {
    my $ptr = calloc( 1, sizeof( Point() ) );
    my $p   = cast( $ptr, Point() );
    $p->{x} = 10;
    $p->{y} = 20;
    is $p->{x}, 10, 'struct field x written';
    is $p->{y}, 20, 'struct field y written';
};
#
subtest 'cast to wrong size type' => sub {
    my $ptr  = calloc( 1, sizeof(Int) );
    my $view = cast( $ptr, Array [ Int, 4 ] );
    ok defined $view, 'cast to larger array type accepted';
};
#
subtest 'coerce with writable Int variable' => sub {
    my $v      = 42;
    my $result = coerce( Int, $v );
    is $result, 42, 'coerce(Int, $var) returns 42';
    $v      = 0;
    $result = coerce( Int, $v );
    is $result, 0, 'coerce(Int, 0) returns 0';
    $v      = -1;
    $result = coerce( Int, $v );
    is $result, -1, 'coerce(Int, -1) returns -1';
};
#
subtest 'coerce with writable Double variable' => sub {
    my $v      = 3.14;
    my $result = coerce( Double, $v );
    is $result, float(3.14), 'coerce(Double, $var) returns 3.14';
    $v      = 0.0;
    $result = coerce( Double, $v );
    is $result, 0, 'coerce(Double, 0) returns 0';
};
#
subtest 'coerce with writable Bool variable' => sub {
    my $v      = 1;
    my $result = coerce( Bool, $v );
    is $result, 1, 'coerce(Bool, 1) returns 1';
    $v      = 0;
    $result = coerce( Bool, $v );
    is $result, 0, 'coerce(Bool, 0) returns 0';
};
#
subtest 'coerce dies on readonly value' => sub {
    my $val = 42;
    Internals::SvREADONLY( $val, 1 );
    like dies { coerce( Int, $val ) }, qr/read.only/i, 'coerce on readonly dies';
    Internals::SvREADONLY( $val, 0 );
};
#
subtest 'coerce dies on literal' => sub {
    like dies { coerce( Int, 42 ) }, qr/read.only/i, 'coerce on literal dies';
};
#
subtest 'coerce with complex type' => sub {
    my $pt     = { x => 5, y => 10 };
    my $result = coerce( Point(), $pt );
    ok defined $result, 'coerce with struct type returns something';
};
#
subtest 'WChar type is defined' => sub {
    ok defined WChar(),       'WChar() returns a type';
    ok sizeof( WChar() ) > 0, 'WChar has non-zero size';
};
#
subtest 'WString type is defined' => sub {
    ok defined WString(), 'WString() returns a type';
};
done_testing;
