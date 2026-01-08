use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
use Config;
#
$|++;
#
# This C code will be compiled into a temporary library for many of the tests.
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c

#include <stdlib.h>
#include <string.h>

DLLEXPORT const char* get_hello_string() { return "Hello from C"; }
DLLEXPORT bool set_hello_string(const char * hi) { return strcmp(hi, "Hello from Perl")==0; }

DLLEXPORT int read_int_from_void_ptr(void* p) {
    if (!p) return -999;
    return *(int*)p;
}

DLLEXPORT int sum_int_array(int* arr, int count) {
    int total = 0;
    for (int i = 0; i < count; i++)
        total += arr[i];
    return total;
}

DLLEXPORT bool check_is_null(void* p) {
    return (p == NULL);
}

// Dereferences a pointer and returns its value + 10.
DLLEXPORT int deref_and_add(int* p) {
    if (!p) return -1;
    return *p + 10;
}

DLLEXPORT void modify_int_ptr(int* p, int new_val) {
    if (p) *p = new_val + 1;
}

DLLEXPORT int check_string_ptr_ptr(char** s) {
    if (s && *s && strcmp(*s, "perl") == 0) {
        // Modify the inner pointer to prove we can
        *s = "C changed me";
        return 1; // success
    }
    return 0; // failure
}

typedef struct {
    int32_t id;
    double value;
    const char* label;
} MyStruct;

MyStruct g_struct = { 99, -1.0, "Global" };

DLLEXPORT void init_struct(MyStruct* s, int32_t id, double value, const char* label) {
    if (s) {
        s->id = id;
        s->value = value;
        s->label = label;
    }
}
DLLEXPORT MyStruct* get_static_struct_ptr() {
    return &g_struct;
}

DLLEXPORT int32_t get_struct_id(MyStruct* s) {
    return s ? s->id : -1;
}

DLLEXPORT int call_int_cb(int (*cb)(int), int val) {
    return cb(val);
}

DLLEXPORT void * test() {
  void * ret = malloc(8);
  if ( ret == NULL ) { }
  else { strcpy(ret, "Testing"); }
  return ret;
}

DLLEXPORT void c_free(void* p) { free(p); }

DLLEXPORT void set_int_deep(int*** ptr, int val) {
    if (ptr && *ptr && **ptr) {
        ***ptr = val;
    }
}

DLLEXPORT void* get_heap_int(int val) {
    int* p = (int*)malloc(sizeof(int));
    *p = val;
    return p;
}

DLLEXPORT void libc_free(void * ptr){ free(ptr); }
END_C
#
my $lib_path = compile_ok($C_CODE);
ok( $lib_path && -e $lib_path, 'Compiled a test shared library successfully' );
#
affix $lib_path, 'read_int_from_void_ptr', [ Pointer [Void] ], Int;
my $mem = malloc(8);

# Cast returns a new pin. We must assign it or use the returned object.
# Also, we keep $mem alive to ensure the memory isn't freed if $int_ptr assumes
# $mem owns it (though cast usually creates unmanaged aliases, so we need $mem to stay alive).
my $int_ptr = Affix::cast( $mem, Pointer [Int] );

# Test magical 'set' via dereferencing
# $$int_ptr is a scalar magic that writes to the address
$$int_ptr = 42;

# Use the original $mem pointer for reading (verifying they point to the same place)
is( read_int_from_void_ptr($mem), 42, 'Magical set via deref wrote to C memory' );

# Test cast again
my $long_ptr = Affix::cast( $mem, Pointer [LongLong] );
$$long_ptr = 1234567890123;
is $$long_ptr, 1234567890123, 'Magical get after casting to a new type works';

# Test realloc
my $r_ptr = calloc( 2, Int );

# realloc updates the pointer inside $r_ptr in-place.
Affix::realloc( $r_ptr, 32 );    # Reallocate to hold 8 ints

# But $r_ptr still thinks it's [2:int]. We must cast to update the type view.
my $arr_ptr = Affix::cast( $r_ptr, Array [ Int, 8 ] );

# Read the entire array from C into a Perl variable
my $array_values = $$arr_ptr;

# Modify perl's copy
$array_values->[0] = 10;
$array_values->[7] = 80;

# Write the entire modified array ref back to the C pointer
$$arr_ptr = $array_values;

# Visual evidence that the memory has actually been updated
#~ Affix::dump( $arr_ptr, 32 );
# sum_int_array takes *int, so passing [8:int] (array ref) works as pointer
ok affix( $lib_path, 'sum_int_array', [ Pointer [Int], Int ], Int ), 'affix ... "sum_int_array", ...';
is sum_int_array( $arr_ptr, 8 ), 90, 'realloc successfully resized memory';
#
isa_ok my $check_is_null = wrap( $lib_path, 'check_is_null', '(*void)->bool' ), ['Affix'];
ok $check_is_null->(undef), 'Passing undef to a *void argument is received as NULL';
subtest 'char*' => sub {
    isa_ok my $get_string = wrap( $lib_path, 'get_hello_string', '()->*char' ), ['Affix'];
    is $get_string->(), 'Hello from C', 'Correctly returned a C string';
    isa_ok my $set_string = wrap( $lib_path, 'set_hello_string', '(*char)->bool' ), ['Affix'];
    ok $set_string->('Hello from Perl'), 'Correctly passed a string to C';
};
subtest 'int32*' => sub {
    isa_ok my $deref  = wrap( $lib_path, 'deref_and_add',  '(*int32)->int32' ),       ['Affix'];
    isa_ok my $modify = wrap( $lib_path, 'modify_int_ptr', '(*int32, int32)->void' ), ['Affix'];
    my $int_var = 50;
    is $deref->( \$int_var ), 60, 'Passing a scalar ref as an "in" pointer works';
    $modify->( \$int_var, 999 );
    is $int_var, 1000, 'C function correctly modified the value in our scalar ref ("out" param)';
};
subtest 'void*' => sub {
    isa_ok my $read_void = wrap( $lib_path, 'read_int_from_void_ptr', '(*void)->int32' ), ['Affix'];
    my $int_val = 12345;
    is $read_void->( \$int_val ), 12345, 'Correctly passed a scalar ref as a void* and read its value';
};
subtest 'char**' => sub {
    isa_ok my $check_ptr_ptr = wrap( $lib_path, 'check_string_ptr_ptr', '(**char)->int32' ), ['Affix'];
    my $string = 'perl';
    ok $check_ptr_ptr->( \$string ), 'Correctly passed a reference to a string as char**';
    is $string, 'C changed me', 'C function was able to modify the inner pointer';
};
subtest 'Struct Pointers (*@My::Struct)' => sub {
    ok typedef( 'My::Struct' => Struct [ id => SInt32, value => Float64, label => Pointer [Char] ] ), q[typedef('My::Struct' = ...)];
    isa_ok my $init_struct = wrap( $lib_path, 'init_struct', '(*@My::Struct, int32, float64, *char)->void' ), ['Affix'];
    my %struct_hash;
    $init_struct->( \%struct_hash, 101, 9.9, "Initialized" );
    is \%struct_hash, { id => 101, value => float(9.9), label => "Initialized" }, 'Correctly initialized a Perl hash via a struct pointer';
    isa_ok my $get_ptr = wrap( $lib_path, 'get_static_struct_ptr', '()->*@My::Struct' ), ['Affix'];
    my $struct_ptr = $get_ptr->();

    # Struct pointer now returns a Pin (Scalar Ref). Dereference it to check contents.
    is $$struct_ptr, { id => 99, value => float(-1.0), label => 'Global' }, 'Dereferencing a returned struct pointer works';
};
subtest 'Function Pointers (*(int->int))' => sub {
    isa_ok my $harness = wrap( $lib_path, 'call_int_cb', '(*((int32)->int32), int32)->int32' ), ['Affix'];
    my $result = $harness->( sub { $_[0] * 10 }, 7 );
    is $result, 70, 'Correctly passed a simple coderef as a function pointer';
    ok $check_is_null->(undef), 'Passing undef as a function pointer is received as NULL';
};
subtest 'Memory Management (malloc, calloc, free)' => sub {
    my $ptr = malloc(32);
    ok $ptr, 'malloc returns a pinned SV*';

    #~ use Data::Printer;
    #~ p $ptr;
    #~ diag length $ptr;
    #~ diag Affix::dump( $ptr, 32 );
    ok my $array_ptr = calloc( 4, Int ), 'calloc returns an array';

    #~ diag Affix::dump( $array_ptr, 32 );
    ok $array_ptr, 'calloc returns an Affix::Pointer object';
    is sum_int_array( $array_ptr, 4 ), 0, 'Memory from calloc is zero-initialized';
    ok free($array_ptr), 'Explicitly calling free() returns true';

    # Note: Double-free would crash, so we assume it worked.
    like( warning { free( find_symbol( load_library($lib_path), 'sum_int_array' ) ) },
        qr/unmanaged/, 'free() croaks when called on an unmanaged pointer' );

    # Test that auto-freeing via garbage collection doesn't crash
    subtest 'GC of managed pointers' => sub {
        ok my $scoped_ptr = malloc(16), 'malloc(16)';

        #~ ok cast( $scoped_ptr, '*int'), 'cast void pointer to int pointer';
        #substr $$scoped_ptr, 0, 1, 'a';
        #~ diag '[' . ($$scoped_ptr) . ']';
        my $values = $$scoped_ptr;
        substr( $values, 4 ) = 'hi';
        $$scoped_ptr = $values;

        #~ Affix::dump( $scoped_ptr, 32 );
        #~ diag '[' . ($$scoped_ptr) . ']';
        # When $scoped_ptr goes out of scope here, its DESTROY method is called.
    };
    pass('Managed pointer went out of scope without crashing');
};
subtest 'Pointer Arithmetic and String Utils' => sub {
    imported_ok qw[ptr_add ptr_diff strdup strnlen is_null];
    subtest 'ptr_add and ptr_diff' => sub {
        my $buf = calloc( 10, Int );    # 40 bytes
        ok !is_null($buf), 'buffer is not null';
        my $p2 = ptr_add( $buf, 8 );    # width of 2 ints
        is ptr_diff( $p2,  $buf ),  8, 'ptr_diff calculates 8 bytes';
        is ptr_diff( $buf, $p2 ),  -8, 'ptr_diff calculates -8 bytes';
        $$p2 = 999;                     # Write to offset

        # Verify via original array pointer
        my $arr = cast( $buf, Array [ Int, 10 ] );
        is $$arr->[2], 999, 'ptr_add moved to index 2 correctly';
        free($buf);
    };
    subtest 'strdup and strnlen' => sub {
        my $str = "Hello World";
        my $dup = strdup($str);
        ok !is_null($dup), 'strdup returned non-null';
        is cast( $dup, String ), $str, 'strdup content matches';
        is strnlen( $dup, 5 ),   5,  'strnlen capped at max';
        is strnlen( $dup, 100 ), 11, 'strnlen found true length';

        # Ensure it's managed memory that we can free
        ok free($dup), 'free(dup) worked';
    };
};
subtest 'return malloc\'d pointer' => sub {
    ok affix( $lib_path, 'test', [] => Pointer [Void] ), 'affix test()';

    # We MUST bind C's free, because Affix::free uses Perl's allocator.
    # Mixing them causes crashes on Windows.
    ok affix( $lib_path, 'c_free', [ Pointer [Void] ] => Void ), 'affix c_free()';
    ok my $string = test(),                                      'test()';
    is Affix::cast( $string, String ), 'Testing', 'read C string';

    # Correct cleanup: Use the allocator that created it.
    c_free($string);
    pass('freed via c_free');
};
subtest 'deep pointers' => sub {

    # 1. Deep Indirection (***int)
    isa_ok my $set_deep = wrap( $lib_path, 'set_int_deep', [ Pointer [ Pointer [ Pointer [Int] ] ], Int ] => Void ), ['Affix'];

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
    isa_ok my $get_heap = wrap( $lib_path, 'get_heap_int', [Int] => Pointer [Int] ), ['Affix'];

    # Alias libc free to avoid conflict with Affix::free
    diag affix( $lib_path, 'libc_free', [ Pointer [Void] ] => Void );
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
#
done_testing;
