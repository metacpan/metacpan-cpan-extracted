use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];

# Prepare C library
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c
static int g_array[4] = { 10, 20, 30, 40 };

DLLEXPORT void* get_array_ptr() { return g_array; }
DLLEXPORT int get_elem(int i) { return g_array[i]; }
DLLEXPORT void set_elem(int i, int val) { g_array[i] = val; }
END_C
my $lib_path = compile_ok($C_CODE);
subtest 'Live Array' => sub {

    # Standard: deep copy
    affix $lib_path, 'get_array_ptr', [] => Pointer [ Array [ Int, 4 ] ];
    my $live_ptr = get_array_ptr();
    is $live_ptr->[0], 10, 'Live object starts with correct element';

    # To make a deep copy (snapshot)
    my $snapshot = [@$live_ptr];
    $snapshot->[0] = 100;
    affix $lib_path, 'get_elem', [Int] => Int;
    is get_elem(0), 10, 'Modifying snapshot did NOT affect C memory';
    $live_ptr->[0] = 42;
    is get_elem(0), 42, 'Modifying live pointer affected C memory immediately';

    # C-side modification
    affix $lib_path, 'set_elem', [ Int, Int ] => Void;
    set_elem( 3, 999 );
};
done_testing;
