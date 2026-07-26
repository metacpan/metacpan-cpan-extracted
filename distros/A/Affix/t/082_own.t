use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
#
$|++;
#
# own() checks if a scalar is an Affix::Memory object.
# alloc_owned() returns a raw Affix::Memory object.
# malloc()/calloc() wrap the result in Pointer[Void], so own() returns false for those.
#
subtest 'own() on alloc_owned returns true' => sub {
    my $mem = alloc_owned(64);
    ok $mem,      'alloc_owned returned memory';
    ok own($mem), 'own() returns true for alloc_owned result';
};
#
subtest 'own() on malloc returns false (wrapped in Pointer[Void])' => sub {
    my $mem = malloc(64);
    ok $mem,       'malloc returned memory';
    ok !own($mem), 'own() returns false for malloc result (wrapped in Pointer[Void])';
};
#
subtest 'own() on calloc returns false (wrapped in Pointer[Void])' => sub {
    my $mem = calloc( 4, 16 );
    ok $mem,       'calloc returned memory';
    ok !own($mem), 'own() returns false for calloc result (wrapped in Pointer[Void])';
};
#
subtest 'own() on plain scalar returns false' => sub {
    ok !own(42),      'own() returns false for a plain integer';
    ok !own("hello"), 'own() returns false for a string';
};
#
subtest 'own() on references returns false' => sub {
    ok !own( { a => 1 } ),  'own() returns false for a hash reference';
    ok !own( [ 1, 2, 3 ] ), 'own() returns false for an array reference';
};
#
subtest 'own() on undef returns false' => sub {
    ok !own(undef), 'own() returns false for undef';
};
#
subtest 'own() on pinned scalar returns false' => sub {
    my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c
DLLEXPORT int g_val = 42;
DLLEXPORT int get_val(void) { return g_val; }
END_C
    my $lib = compile_ok($C_CODE);
    my $pinned;
    pin( $pinned, $lib, 'g_val', Int() );
    ok is_pin($pinned), 'pinned scalar is a pin';
    ok !own($pinned),   'own() returns false for a pinned scalar (not Affix::Memory)';
};
#
done_testing;
