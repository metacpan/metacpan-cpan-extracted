use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
#
$|++;
#
subtest import => sub {
    imported_ok qw[affix pin unpin wrap];
    imported_ok qw[libm libc];
    imported_ok qw[sizeof alignof offsetof];
    imported_ok qw[calloc free malloc realloc dump own
        memchr    memcmp     memcpy     memmove     memset
        strdup    strnlen
        ptr_add   ptr_diff
        address
        is_null
    ];
    imported_ok qw[load_library find_symbol ];
    imported_ok qw[typedef cast coerce];
    imported_ok qw[get_last_error_message];
    imported_ok qw[direct_affix direct_wrap];    # Secrets
};
subtest types => sub {
    imported_ok qw[
        Array     Bool    Callback Char   CodeRef Complex   Double Enum   File
        Float     Float32 Float64  Int    Int128  Int16     Int32  Int64  Int8    Long  LongDouble
        LongLong  M256    M256d    M512   M512d   M512i     Packed PerlIO Pointer SChar
        SInt128   SInt16  SInt32   SInt64 SInt8   SSize_t   SV
        Short     Size_t  String   Struct UChar   UInt      UInt128
        UInt16    UInt32  UInt64   UInt8  ULong   ULongLong UShort
        Union     VarArgs Vector   Void   WChar   WString    ];
    subtest abstract => sub {
        is Void,       'void',       'Void';
        is Bool,       'bool',       'Bool';
        is Char,       'char',       'Char';
        is UChar,      'uchar',      'UChar';
        is Short,      'short',      'Short';
        is UShort,     'ushort',     'UShort';
        is Int,        'int',        'Int';
        is UInt,       'uint',       'UInt';
        is Long,       'long',       'Long';
        is ULong,      'ulong',      'ULong';
        is LongLong,   'longlong',   'LongLong';
        is ULongLong,  'ulonglong',  'ULongLong';
        is Float,      'float',      'Float';
        is Double,     'double',     'Double';
        is LongDouble, 'longdouble', 'LongDouble';
        is SChar,      'char',       'SChar';
    };
    subtest explicit => sub {
        is SInt8,   'sint8',   'SInt8';
        is SInt16,  'sint16',  'SInt16';
        is SInt32,  'sint32',  'SInt32';
        is SInt64,  'sint64',  'SInt64';
        is SInt128, 'sint128', 'SInt128';
    };
    subtest SIMD => sub {
        is M256,  'm256',  'M256';
        is M256d, 'm256d', 'M256d';
        is M512,  'm512',  'M512';
        is M512d, 'm512d', 'M512d';
        is M512i, 'm512i', 'M512i';
    };
    subtest composite => sub {
        is Pointer [Void],             '*void',  'Pointer[Void]';
        is Pointer [Char],             '*char',  'Pointer[Char]';
        is Pointer [ Pointer [Void] ], '**void', 'Pointer[Pointer[Void]]';
        #
        is Struct [ name => Pointer [Char] ], '{name:*char}', 'Struct[ name => ... ]';
        is Struct [ name => Pointer [Char], dob => Struct [ y => Int, m => Int, d => Int ] ], '{name:*char,dob:{y:int,m:int,d:int}}',
            'Struct[ name => ..., dob => ...]';
        #
        is Union [ i => Int, f => Float ], '<i:int,f:float>', 'Union[...]';
    };
    subtest etc => sub {
        is SV,     '@SV',     'SV';
        is File,   '@File',   'File';
        is PerlIO, '@PerlIO', 'PerlIO';
    };
};
#
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c

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

DLLEXPORT long long multi_arg_sum(
    long long a, long long b, long long c, long long d,
    long long e, long long f, long long g, long long h, long long i
) {
    return a + b + c + d + e + f + g + h + i;
}
END_C
#
my $lib_path = compile_ok($C_CODE);
ok( $lib_path && -e $lib_path, 'Compiled a test shared library successfully' );
subtest 'Forward Calls: Comprehensive Primitives' => sub {
    for my ( $type, $value )(
        bool  => false,                                       #
        int8  => -100,           uint8  => 100,               #
        int16 => -30000,         uint16 => 60000,             #
        int32 => -2_000_000_000, uint32 => 4_000_000_000,     #
        int64 => -5_000_000_000, uint64 => 10_000_000_000,    #
        float =>  1.23,          double => -4.56              #
    ) {
        my $name = "echo_$type";
        my $sig  = "($type)->$type";
        isa_ok my $fn = wrap( $lib_path, $name, $sig ), ['Affix'], $sig;
        is $fn->($value), $value == int $value ? $value : float( $value, tolerance => 0.01 ), "Correctly passed and returned type '$type'";
    }
};
subtest 'Forward Call with Many Arguments' => sub {
    note 'Testing a C function with more arguments than available registers.';
    my $sig = '(int64, int64, int64, int64, int64, int64, int64, int64, int64)->int64';
    isa_ok my $summer = wrap( $lib_path, 'multi_arg_sum', $sig ), ['Affix'];
    my $result = $summer->( 1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000 );
    is $result, 111111111, 'Correctly passed 9 arguments to a C function';
};
subtest 'Parser Error Reporting' => sub {
    note 'Testing that malformed signatures produce helpful error messages.';
    like warning { Affix::wrap( $lib_path, 'add', '(int, ^, int)->int' ) }, qr[parse signature], 'wrap() warning on invalid signature';
    like warning { Affix::sizeof('{int, double') },                         qr[parse signature], 'sizeof() warning on unterminated aggregate';
};
subtest 'These are called under valgrind in 900_leak' => sub {
    subtest 'use Affix' => sub {
        use Affix qw[];
        pass 'loaded';
    };
    subtest 'affix($$$$)' => sub {
        no warnings 'redefine';
        ok affix( libm, 'pow', [ Double, Double ], Double ), 'affix pow( Double, Double )';
        is pow( 5, 2 ), 25, 'pow(5, 2)';
    };
    subtest 'wrap($$$$)' => sub {
        isa_ok my $pow = wrap( libm, 'pow', [ Double, Double ], Double ), ['Affix'], 'double pow(double, double)';
        is $pow->( 5, 2 ), 25, '$pow->(5, 2)';
    };
    subtest 'return pointer' => sub {
        my $lib = compile_ok(<<'');
#include "std.h"
// ext: .c
void * test( ) { void * ret = "Testing"; return ret; }

        ok my $fn         = wrap( $lib, 'test', [] => Pointer [Void] ), 'affix';
        ok my $string_ptr = $fn->(),                                    'call';

        # Casting a pointer to String should return the Value "Testing"
        is Affix::cast( $string_ptr, String ), 'Testing', 'cast($ptr, String) returns value';
    }
};
subtest 'affix/wrap function pointer' => sub {
    my $lib = compile_ok(<<~'');
    #include "std.h"
    //ext: .c
    DLLEXPORT int add(int a, int b) { return a + b; }


    # Get address via find_symbol (simulating getting it from vtable or dlsym)
    my $ptr = find_symbol( load_library($lib), 'add' );
    ok $ptr, 'Got function pointer';

    # Test wrap(undef, $ptr, ...)
    subtest 'wrap(undef, $ptr, ...)' => sub {
        my $fn = wrap( undef, $ptr, [ Int, Int ] => Int );
        is $fn->( 10, 20 ), 30, 'Wrapped raw function pointer works';
    };

    # Test affix(undef, [$ptr => 'name'], ...)
    subtest 'affix(undef, [$ptr => name], ...)' => sub {
        affix( undef, [ $ptr => 'my_add' ], [ Int, Int ] => Int );
        is my_add( 5, 5 ), 10, 'Affixed raw function pointer works';
    };

    # 4. Test wrap with explicit raw integer (simulating cast)
    subtest 'wrap(undef, int_addr, ...)' => sub {
        my $addr = address($ptr);                               # Convert Pin to UV
        my $fn   = wrap( undef, $addr, [ Int, Int ] => Int );
        is $fn->( 3, 4 ), 7, 'Wrapped raw integer address works';
    };
};
#
done_testing;
