use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];

# Prepare C library
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c
typedef struct {
    int32_t id;
    double  value;
} MyStruct;

static MyStruct g_struct = { 1, 1.5 };

DLLEXPORT void* get_struct_ptr() { return &g_struct; }
DLLEXPORT int32_t get_id() { return g_struct.id; }
DLLEXPORT double get_val() { return g_struct.value; }
DLLEXPORT void set_vals(int32_t id, double val) { g_struct.id = id; g_struct.value = val; }
END_C
my $lib_path = compile_ok($C_CODE);
subtest 'Live Struct' => sub {
    typedef MyStruct => Struct [ id => Int32, value => Double ];

    # Standard: deep copy
    affix $lib_path, 'get_struct_ptr', [] => Pointer [ MyStruct() ];
    my $ptr  = get_struct_ptr();
    my $copy = $ptr;
    is $copy->{id}, 1, 'Copy has correct ID';
    $copy->{id} = 100;
    affix $lib_path, 'get_id', [] => Int32;
    is get_id(), 100, 'Modifying deep copy affects C memory';

    # Live: zero-copy view
    # We use cast() with to get a live view via pins on the values
    my $live = cast( $ptr, Struct [ id => Int32, value => Double ] );
    is $live->{id}, 100, 'Live view has correct ID';

    # Write to live view
    $live->{id} = 42;
    is get_id(), 42, 'Modifying live view affected C memory immediately';

    # C-side modification
    affix $lib_path, 'set_vals', [ Int32, Double ] => Void;
    set_vals( 99, 3.14 );
    is $live->{id},    99,          'C modification visible in live view ID';
    is $live->{value}, float(3.14), 'C modification visible in live view Value';
};
done_testing;
