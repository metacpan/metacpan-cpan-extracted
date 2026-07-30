use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
$|++;
my $lib = compile_ok(<<~'');
    #include "std.h"
    DLLEXPORT int add_ints(int a, int b) { return a + b; }
    DLLEXPORT void noop(void) {}
    DLLEXPORT int echo_int(int x) { return x; }
    DLLEXPORT int *return_null(void) { return NULL; }
    DLLEXPORT int read_ptr(const int *p) { return p ? *p : -1; }
    DLLEXPORT char *echo_str(const char *s) { return (char *)s; }
    DLLEXPORT int sum_array(int *arr, int n) { int s=0; for(int i=0;i<n;i++) s+=arr[i]; return s; }
    DLLEXPORT double echo_double(double x) { return x; }
//ext: .c

#
subtest 'Wrong argument count' => sub {
    my $fn = wrap( $lib, 'add_ints', [ Int, Int ], Int );

    # Too few arguments
    like dies { $fn->(42) }, qr/too few|arg|usage/i, 'Too few args dies';
    like dies { $fn->() },   qr/too few|arg|usage/i, 'Zero args dies';

    # Too many arguments
    like dies { $fn->( 1, 2, 3 ) }, qr/too many|arg/i, 'Too many args dies';
};
#
subtest 'Wrong argument types' => sub {
    my $fn = wrap( $lib, 'add_ints', [ Int, Int ], Int );

    # Pass a string where int expected
    my $result = $fn->( "hello", 1 );
    isnt $result, 42, 'String arg does not produce expected numeric result';

    # Pass undef where int expected (treated as 0 or NULL)
    $result = $fn->( undef, 5 );
    is $result, 5, 'undef as first arg treated as 0';
};
#
subtest 'NULL pointer handling' => sub {
    my $get_null = wrap( $lib, 'return_null', [], Pointer [Int] );
    my $null_ptr = $get_null->();
    ok !defined $null_ptr, 'return_null returns undef';
    my $read_ptr = wrap( $lib, 'read_ptr', [ Pointer [Int] ], Int );

    # NULL pointer passed via FFI may resolve to 0
    my $val = $read_ptr->($null_ptr);
    ok defined $val,            'Reading from NULL pointer returns a value (does not crash)';
    ok $val == -1 || $val == 0, 'NULL pointer read returns -1 or 0';

    # Pass undef as pointer arg
    $val = $read_ptr->(undef);
    ok defined $val, 'undef pointer returns a value';
};
#
subtest 'wrap() on non-existent symbol' => sub {
    my $fn = wrap( $lib, 'nonexistent_function_xyz', [Int], Int );
    ok !defined $fn, 'wrap() returns undef for missing symbol';
};
#
subtest 'wrap() with malformed signatures' => sub {

    # Empty args array is valid for void functions
    my $fn = wrap( $lib, 'noop', [], Void );
    ok defined $fn,       'Empty args array accepted for void function';
    ok lives { $fn->() }, 'Void function with empty args runs';

    # Non-arrayref args should die
    like dies { wrap( $lib, 'add_ints', 'Int, Int', Int ) }, qr/.+/, 'String args rejected';
};
#
subtest 'sizeof/alignof/offsetof on valid types' => sub {
    is sizeof( Struct [ x => Int, y => Int ] ), 8, 'sizeof Struct with two Ints';
    ok alignof(Int) > 0, 'alignof(Int) returns positive';
    is offsetof( Struct [ x => Int, y => Int ], 'x' ), 0, 'offsetof first member is 0';
};
#
subtest 'load_library on non-existent path' => sub {
    ok !load_library('/no/such/lib.dll'), 'load_library returns false for missing lib';
};
#
subtest 'find_symbol on bad handle' => sub {
    my $bad_lib = load_library('nonexistent_xyz');
    skip_all 'Could not get a bad handle' unless defined $bad_lib;
    ok !find_symbol( $bad_lib, 'no_such_func' ), 'find_symbol returns false for missing symbol';
};
#
subtest 'calloc returns valid pin' => sub {
    my $ptr = calloc( 1, sizeof(Int) );
    ok is_pin($ptr), 'calloc returns a pin';
    ok defined $ptr, 'calloc pointer is defined';
};
#
subtest 'malloc returns valid pin' => sub {
    my $ptr = malloc(64);
    ok is_pin($ptr), 'malloc(64) returns a pin';
    ok defined $ptr, 'malloc pointer is defined';
};
#
subtest 'realloc modifies pin in-place' => sub {
    my $ptr = malloc(64);
    ok is_pin($ptr), 'malloc(64) returns a pin';

    # realloc updates the pin's pointer in-place and returns YES (boolean)
    my $ret = realloc( $ptr, 128 );
    ok defined $ret, 'realloc returns a truthy value';
    ok is_pin($ptr), 'Original pin is still valid after realloc';
};
#
subtest 'memset and memcpy' => sub {
    my $src = calloc( 4, sizeof(Char) );
    my $dst = calloc( 4, sizeof(Char) );
    ok is_pin($src), 'calloc src is a pin';
    ok is_pin($dst), 'calloc dst is a pin';
    memset( $src, 0xFF, 4 );
    memcpy( $dst, $src, 4 );
    is Affix::raw( $dst, 4 ), Affix::raw( $src, 4 ), 'memcpy produced identical memory';
};
done_testing;
