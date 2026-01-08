use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
use Config;
#
$|++;
#
my $c_source = <<'END_C';
#include "std.h"
//ext: .c

#include <stdio.h>
#include <stdint.h>

/* SIMD Vectors */
/* GCC/Clang vector extensions */
#if defined(__GNUC__) || defined(__clang__)
    typedef float v4f __attribute__((vector_size(16)));
    typedef double v2d __attribute__((vector_size(16)));
    typedef int v4i __attribute__((vector_size(16)));

    DLLEXPORT int has_vector() { return 1; }

    DLLEXPORT v4f add_v4f(v4f a, v4f b) {
        return a + b;
    }

    DLLEXPORT v2d add_v2d(v2d a, v2d b) {
        return a + b;
    }

    DLLEXPORT v4i add_v4i(v4i a, v4i b) {
        return a + b;
    }
#else
    DLLEXPORT int has_vector() { return 0; }
#endif

/* Long Double */
DLLEXPORT long double add_ld(long double a, long double b) {
    return a + b;
}

DLLEXPORT double ld_to_d(long double a) {
    return (double)a;
}
END_C

# Compile the library
my $lib   = compile_ok($c_source);
my $check = wrap( $lib, 'has_vector', [] => Int );
if ( !$check->() ) {
    skip_all "Compiler does not support vector extensions";
}
subtest 'Vector[4, Float]' => sub {

    # Bind: v4f add_v4f(v4f a, v4f b);
    isa_ok my $add = wrap( $lib, 'add_v4f', [ Vector [ 4, Float ], Vector [ 4, Float ] ] => Vector [ 4, Float ] ), ['Affix'];

    # Pass as Packed String (Fast Path)
    # 1.0, 2.0, 3.0, 4.0
    my $v1 = pack( 'f*', 1.0, 2.0, 3.0, 4.0 );

    # 10.0, 20.0, 30.0, 40.0
    my $v2  = pack( 'f*', 10.0, 20.0, 30.0, 40.0 );
    my $res = $add->( $v1, $v2 );

    # Result comes back as ArrayRef (default unmarshalling)
    is ref($res), 'ARRAY', 'Returned array ref';

    # Check values (allow small float epsilon)
    is $res->[0], float(11.0), 'Index 0 correct';
    is $res->[1], float(22.0), 'Index 1 correct';
    is $res->[2], float(33.0), 'Index 2 correct';
    is $res->[3], float(44.0), 'Index 3 correct';
};
subtest 'Vector[2, Double]' => sub {
    isa_ok my $add = wrap( $lib, 'add_v2d', [ Vector [ 2, Double ], Vector [ 2, Double ] ] => Vector [ 2, Double ] ), ['Affix'];

    # Pass as Array Ref (Slow Path)
    my $v1  = [ 1.5, 2.5 ];
    my $v2  = [ 0.5, 0.5 ];
    my $res = $add->( $v1, $v2 );
    is $res->[0], float(2.0), 'Double Vector Index 0';
    is $res->[1], float(3.0), 'Double Vector Index 1';
};
subtest 'Vector[4, Int]' => sub {
    isa_ok my $add = wrap( $lib, 'add_v4i', [ Vector [ 4, Int ], Vector [ 4, Int ] ] => Vector [ 4, Int ] ), ['Affix'];

    # Pass Packed (Native integers)
    my $v1  = pack( 'i*', 10, 20, 30, 40 );
    my $v2  = pack( 'i*', 1,  2,  3,  4 );
    my $res = $add->( $v1, $v2 );
    is $res->[0], 11, 'Int Vector Index 0';
    is $res->[3], 44, 'Int Vector Index 3';
};
done_testing;
