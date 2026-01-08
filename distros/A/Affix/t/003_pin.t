use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
#
$|++;
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c

#include <stdint.h>
#include <stdbool.h>
#include <string.h> // For strcmp
#include <stdlib.h> // For malloc

DLLEXPORT int  global_counter    = 100;
DLLEXPORT char global_buffer[64] = "Initial";

DLLEXPORT void set_global_counter(int value) { global_counter = value;}
DLLEXPORT int get_global_counter(void) { return global_counter;}

DLLEXPORT void set_int_deep(int*** ptr, int val) {
    if (ptr && *ptr && **ptr) {
        ***ptr = val;
    }
}
END_C
#
my $lib_path = compile_ok($C_CODE);
ok( $lib_path && -e $lib_path, 'Compiled a test shared library successfully' );
#
isa_ok my $get = wrap( $lib_path, 'get_global_counter', []    => Int ),  ['Affix'];
isa_ok my $set = wrap( $lib_path, 'set_global_counter', [Int] => Void ), ['Affix'];
is $get->(), 100, 'Initial global value read correctly via function';
$set->(500);
is $get->(), 500, 'Global value modified via function';
#
my $pinned_int;
ok pin( $pinned_int, $lib_path, 'global_counter', Int ), 'Pin global_counter';
is $pinned_int, 500, 'Pinned scalar matches current global value';
$pinned_int = 999;    # Write via magic
is $get->(), 999, 'Writing to pinned scalar updates C global';
$set->(42);           # Use the wrapped function, not direct call
is $pinned_int, 42, 'Modifying C global updates pinned scalar';
ok unpin($pinned_int), 'Unpin variable';
$pinned_int = 0;
is $get->(), 42, 'Unpinned variable detached from C global';
#
my $pinned_buf;
ok pin( $pinned_buf, $lib_path, 'global_buffer', Array [ Char, 64 ] ), 'Pin char array';
is $pinned_buf, "Initial", 'Read C string from pinned array';
#
my $sym = find_symbol( load_library($lib_path), 'global_buffer' );
#
my $sym_arr = Affix::cast( $sym, Array [ Char, 64 ] );
$$sym_arr = "Perl was here";
is $pinned_buf, "Perl was here", 'Writing string to pinned array persisted in C memory';
done_testing;
