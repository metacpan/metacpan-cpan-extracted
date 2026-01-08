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

DLLEXPORT void just_something_to_export(void) { return; }
END_C
#
my $lib_path = compile_ok($C_CODE);
ok( $lib_path && -e $lib_path, 'Compiled a test shared library successfully' );
subtest 'Library Loading and Lifecycle' => sub {
    note 'Testing load_library(), Affix::Lib objects, and reference counting.';
    my $lib1 = load_library($lib_path);
    isa_ok $lib1, ['Affix::Lib'], 'load_library returns an Affix::Lib object';
    my $lib2 = load_library($lib_path);
    is int $lib1, int $lib2, 'Loading the same library returns a handle to the same underlying object (singleton behavior)';
    my $bad_lib = load_library('non_existent_library_12345.so');
    is $bad_lib,                 undef, 'load_library returns undef for a non-existent library';
    is get_last_error_message(), D(),   'get_last_error_message provides a useful error on failed load';
};
subtest 'Symbol Finding' => sub {
    ok my $lib    = load_library($lib_path),                         'load_library returns a pointer';
    ok my $symbol = find_symbol( $lib, 'just_something_to_export' ), 'find_symbol returns a pointer';
    is find_symbol( $lib, 'non_existent_symbol_12345' ), U(), 'find_symbol returns undef for a non-existent symbol';
};
#
done_testing;
