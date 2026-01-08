use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
#
$|++;
my $lib = compile_ok( <<'END_C', { name => 'lvalue param lib' } );
#include "std.h"
//ext: .c
#include <stdlib.h>
#include <string.h>

DLLEXPORT void create_thing(void **out) {
    if (out) {
        char *mem = malloc(16);
        if (mem) {
            strcpy(mem, "LValue Test");
            *out = mem;
        }
    }
}

DLLEXPORT void free_thing(void *ptr) {
    if (ptr)
        free(ptr);
}
END_C
#
ok typedef( MyThing => Void ), 'Defined opaque MyThing';
ok affix( $lib, 'create_thing', [ Pointer [ Pointer [Void] ] ] => Void ), 'Bound create_thing';
ok affix( $lib, 'free_thing',   [ Pointer [Void] ]             => Void ), 'Bound free_thing';
subtest 'pass by reference' => sub {
    my $thing;
    create_thing( \$thing );
    ok defined($thing), 'Scalar populated via reference';
    is Affix::cast( $thing, String ), "LValue Test", 'Pointer content correct';
    free_thing($thing);
};
#
subtest 'pass by value (might be a terrible over-optimization...)' => sub {

    # This might (and probably should) go away in the future
    my $thing;
    create_thing($thing);
    is $thing,                        D(),           'Direct scalar argument populated';
    is Affix::cast( $thing, String ), 'LValue Test', 'Pointer content correct';
    free_thing($thing);
};
subtest 'explicit undef (NULL)' => sub {
    create_thing(undef);
    pass 'Explicit undef passed as NULL (no crash)';
};
done_testing;
