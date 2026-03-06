use v5.40;
use lib 'lib', 'blib/arch', 'blib/lib';
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];

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
    my $ptr  = get_array_ptr();
    my $copy = $$ptr;             # returns ArrayRef
    is $copy->[0], 10, 'Copy has correct element';
    $copy->[0] = 100;
    affix $lib_path, 'get_elem', [Int] => Int;
    is get_elem(0), 10, 'Modifying deep copy did NOT affect C memory';

    # Live: zero-copy view via Live()
    my $live = cast( $ptr, Live [ Array [ Int, 4 ] ] );
    isa_ok $live, ['Affix::Pointer'], 'Live array is an Affix::Pointer';
    is $live->[0], 10, 'Live view has correct element';

    # Write to live view
    $live->[0] = 42;
    is get_elem(0), 42, 'Modifying live view affected C memory immediately';

    # C-side modification
    affix $lib_path, 'set_elem', [ Int, Int ] => Void;
    set_elem( 3, 999 );
    is $live->[3], 999, 'C modification visible in live view';
};
done_testing;
