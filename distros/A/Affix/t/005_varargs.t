use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
#
$|++;
#
my $c_code = <<'END_C';
#include "std.h"
//ext: .c
#include <stdarg.h>
#include <string.h>
#include <stdio.h>

typedef struct {
    int x, y;
} Point;

/*
 * Sums values based on format string.
 * i: int
 * d: double
 * P: Point {int, int}
 */
DLLEXPORT int var_sum(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int total = 0;
    while (*fmt) {
        switch (*fmt++) {
            case 'i': total += va_arg(ap, int); break;
            case 'd': total += (int)va_arg(ap, double); break;
            case 's': {
                char* s = va_arg(ap, char*);
                total += s ? strlen(s) : 0;
                break;
            }
            case 'P': {
                Point p = va_arg(ap, Point);
                total += p.x + p.y;
                break;
            }
        }
    }
    va_end(ap);
    return total;
}
END_C
my $lib = compile_ok( $c_code, { name => 'variadic_dynamic_lib' } );

# 2. Bind with "Empty" Variadic Signature
# We define the fixed arguments (*char) and end with a semicolon.
# We do NOT specify any optional types here. Affix must generate them at runtime.
# Signature: (*char;)->int
isa_ok my $fn = wrap( $lib, 'var_sum', [ Pointer [Char], VarArgs ] => Int ), ['Affix'];
subtest 'Runtime Type Inference' => sub {

    # 3 Integers
    # Affix should generate JIT for: (*char; sint64, sint64, sint64)->int
    is $fn->( "iii", 10, 20, 30 ), 60, 'Inferred 3 integers';

    # Floats (promoted to double)
    # 1.5 -> 1, 2.5 -> 2. Sum = 3.
    is $fn->( "dd", 1.5, 2.5 ), 3, 'Doubles passed correctly';

    # Mixed Types
    # (*char; sint64, double)->int
    # Note: 2.5 cast to int is 2
    is $fn->( "id", 100, 2.5 ), 102, 'Inferred mixed int/double';

    # Strings (*char)
    # len("Hello") = 5
    is $fn->( "s", "Hello" ), 5, 'Strings passed correctly';

    # Edge case where we don't pass any varargs. Like calling `printf( "Just this string, please." );`
    # (*char;)->int
    is $fn->(""), 0, 'Called with no variadic arguments';
};
subtest 'Runtime Coercion (Structs)' => sub {
    typedef Point__ => Struct [ x => Int, y => Int ];
    my $p1 = { x => 1, y => 2 };    # Sum = 3
    my $p2 = { x => 3, y => 4 };    # Sum = 7

    # Coerced Struct
    # Affix should generate JIT for: (*char; {x:int,y:int}, {x:int,y:int})->int
    is $fn->( "PP", coerce( Point__(), $p1 ), coerce( Point__(), $p2 ) ), 10, 'Dynamically generated signature for coerced structs';
};

# 5. Test Safety / Constraints
subtest 'Safety' => sub {

    # coerce() modifies the SV (attaches magic).
    # It cannot function on read-only constants.
    like dies {
        $fn->( "i", coerce( Int, 10 ) );
    }, qr/read-only/, 'coerce(Int, 10) correctly dies on read-only value';

    # Correct usage with variable
    my $v = 100;
    is $fn->( "i", coerce( Int, $v ) ), 100, 'coerce(Int, $var) works';
};
subtest coercion => sub {
    typedef Point_ => Struct [ x => Int, y => Int ];

    # Without coerce(), Affix wouldn't know to pass this as a Point_ struct by value.
    my $pt = { x => 10, y => 20 };

    # coerce() attaches magic to $pt telling Affix to treat it as a @Point.
    # The JIT generates a trampoline expecting a struct {int,int} on the stack/registers.
    # 10 + 20 = 30.
    is $fn->( 'P', coerce( Point_(), $pt ) ), 30, 'Struct passed by value using coerce()';

    # Reuse the trampoline (Cache Hit check)
    # The signature generated for ('P', Point) should be cached.
    my $pt2 = { x => 5, y => 5 };
    is $fn->( 'P', coerce( Point_(), $pt2 ) ), 10, 'Repeated call with coerced struct works';

    # Ensure previous calls didn't "lock" the signature to a specific set of types.
    # Call with 1 Integer (different from previous calls)
    is $fn->( 'i', 99 ), 99, 'Signature remains dynamic for new argument patterns';
};
subtest 'printf' => sub {    # Should be safe/standard across platforms
    ok my $printf = wrap( libc, 'printf', [ String, VarArgs ], Int ), q[wrap( libc, 'printf', [ String, VarArgs ], Int)];
    is $printf->( '# %s: %d <---', 'Test', 100 ), 16, q[->( ... )];
};
done_testing;
