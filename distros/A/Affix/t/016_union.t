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
END_C
#
my $lib_path = compile_ok($C_CODE);
ok( $lib_path && -e $lib_path, 'Compiled a test shared library successfully' );
#
isa_ok my $get_var = wrap( $lib_path, 'get_variant_val', [ Union [ i => Int, d => Double, c => Char ], Int ] => Double ), ['Affix'];
is $get_var->( { i => 42 },  0 ), 42.0, 'Union passed as Int';
is $get_var->( { d => 3.5 }, 1 ), 3.5,  'Union passed as Double';
#
done_testing;
