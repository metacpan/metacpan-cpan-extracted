use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
#
$|++;
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c

#include <stdint.h>

DLLEXPORT int global_counter = 100;
DLLEXPORT int get_counter(void) { return global_counter; }
DLLEXPORT void set_counter(int v) { global_counter = v; }
END_C
#
my $lib = compile_ok($C_CODE);
ok( $lib && -e $lib, 'Compiled shared library' );
#
isa_ok my $get = wrap( $lib, 'get_counter', []    => Int ),  ['Affix'];
isa_ok my $set = wrap( $lib, 'set_counter', [Int] => Void ), ['Affix'];
#
subtest 'pin() 4-arg: baseline (named symbol)' => sub {
    my $pinned;
    ok pin( $pinned, $lib, 'global_counter', Int() ), '4-arg pin succeeded';
    is $pinned, 100, 'Reads initial global value';
    $pinned = 200;
    is $get->(), 200, 'Writing to pinned scalar updates C global';
    $set->(42);
    is $pinned, 42, 'C update visible through pinned scalar';
    ok unpin($pinned), 'Unpinned variable';
};
#
subtest 'pin() 3-arg: raw address via find_symbol' => sub {

    # Get the raw address of a known global symbol
    my $lib_obj = load_library($lib);
    my $sym     = find_symbol( $lib_obj, 'global_counter' );
    ok $sym, 'find_symbol returned symbol handle';
    my $addr = address($sym);
    ok $addr > 0, 'Got valid address from symbol';

    # Set global to a known value
    $set->(777);
    is $get->(), 777, 'Set global to 777';

    # 3-arg pin: bind a new scalar to the raw address
    my $pin2;
    ok pin( $pin2, $addr, Int() ), '3-arg pin to global_counter address succeeded';
    is $pin2, 777, '3-arg pin reads current value (777)';

    # Write through the new pin
    $pin2 = 888;
    is $get->(), 888, 'Writing through 3-arg pin updates C global';

    # Write through C function, read through 3-arg pin
    $set->(999);
    is $pin2, 999, 'C function update visible through 3-arg pin';
    ok unpin($pin2), 'Unpinned 3-arg pin';
};
#
subtest 'pin() 4-arg: with library object' => sub {
    my $lib_obj = load_library($lib);
    ok $lib_obj, 'load_library returned library object';
    my $pinned;
    ok pin( $pinned, $lib_obj, 'global_counter', Int() ), '4-arg pin with library object succeeded';
    $pinned = 111;
    is $get->(), 111, 'Writing through pinned scalar updates C global';
    ok unpin($pinned), 'Unpinned';
};
#
subtest 'pin() 4-arg: pin array type' => sub {
    my $pinned_buf;
    ok pin( $pinned_buf, $lib, 'global_counter', Array [ Int, 1 ] ), 'Pin as Array[Int,1]';
    ok is_pin($pinned_buf),                                          'Result is a pin';
    ok unpin($pinned_buf),                                           'Unpinned array pin';
};
#
subtest 'pin() 2-arg: clone from existing pin' => sub {

    # First create a pinned scalar via 4-arg pin
    my $original;
    ok pin( $original, $lib, 'global_counter', Int() ), '4-arg pin for source';
    $original = 42;
    is $get->(), 42, 'Set global to 42 via original pin';

    # Clone via 2-arg pin
    my $cloned;
    ok pin( $cloned, $original ), '2-arg pin cloned from original';
    is $cloned, 42, 'Cloned pin reads same value';

    # Write through clone, read through original
    $cloned = 77;
    is $original, 77, 'Original sees writes through clone';

    # Write through original, read through clone
    $original = 88;
    is $cloned, 88, 'Clone sees writes through original';

    # Both update C
    is $get->(), 88, 'C global updated through either pin';
    ok unpin($cloned),   'Unpinned clone';
    ok unpin($original), 'Unpinned original';
};
#
subtest 'unpin() returns false for non-pinned scalar' => sub {
    ok !unpin(42),      'unpin returns false for plain integer';
    ok !unpin("hello"), 'unpin returns false for string';
};
#
done_testing;
