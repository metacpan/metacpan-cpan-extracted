use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
#
my $orig_destroy = \&Affix::Memory::DESTROY;
my $destroyed    = 0;
no warnings qw[redefine prototype];
*Affix::Memory::DESTROY = sub { $destroyed++; $orig_destroy->(@_); };
#
$|++;
#
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c

#include <stdlib.h>

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
END_C
#
my $lib_path = compile_ok($C_CODE);
ok $lib_path && -e $lib_path, 'Compiled a test shared library successfully';
affix $lib_path, 'read_int_from_void_ptr', [ Pointer [Void] ],     Int;
affix $lib_path, 'sum_int_array',          [ Pointer [Int], Int ], Int;
#
subtest 'malloc: memory survives while the pin is alive' => sub {
    my $a          = malloc(64);
    my $a_addr     = address($a);
    my $collisions = 0;
    for ( 1 .. 10_000 ) {
        my $p = malloc(64);
        $collisions++ if address($p) == $a_addr;
    }
    is $collisions, 0, 'live block is never handed out again';
};
#
subtest 'malloc: memory is reclaimed once the pin is released' => sub {
    my $before = $destroyed;
    my $addr;
    {
        my $p = malloc(64);
        $addr = address($p);
    }
    is $destroyed, $before + 1, 'releasing the pin destroyed the Affix::Memory object and freed the memory';

    # Address reuse is an allocator implementation detail (glibc does not
    # guarantee prompt reuse and varies with prior heap state), so it is
    # diagnostic only; the refcount check above is the actual reclaim proof.
    my $reclaimed = 0;
    for ( 1 .. 10000 ) {
        my $p = malloc(64);
        $reclaimed++ if address($p) == $addr;
    }
    is $destroyed, $before + 1 + 10000, 'every allocation in the reuse loop was destroyed exactly once';
    note "freed block address was reused $reclaimed/10000 times";
};
#
subtest 'malloc: free() works across statements' => sub {
    ok no_warnings {
        my $ptr = malloc(64);
        ok $ptr,       'malloc returned a pin';
        ok free($ptr), 'free() on malloc pin returns true';
    }, 'no "unmanaged pointer" warning';
};
#
subtest 'calloc: zero-initialized and free()-able' => sub {
    ok no_warnings {
        my $arr = calloc( 4, sizeof Int );
        ok $arr, 'calloc returned a pin';
        is sum_int_array( $arr, 4 ), 0, 'calloc memory is zero-initialized';
        ok free($arr), 'free() on calloc pin returns true';
    }, 'no "unmanaged pointer" warning';
};
#
subtest 'realloc: grows and preserves data' => sub {
    my $r = calloc( 2, sizeof Int );
    ok $r, 'calloc returned a pin';
    my $small = cast( $r, Array [ Int, 2 ] );
    $small->[0] = 10;
    $small->[1] = 20;
    ok realloc( $r, 32 ), 'realloc grew to 32 bytes';
    my $big = cast( $r, Array [ Int, 8 ] );
    is $big->[0], 10, 'data preserved at index 0 after realloc';
    is $big->[1], 20, 'data preserved at index 1 after realloc';

    # realloc() preserves but does not zero the extension; write every slot
    # so the C-side sum is deterministic.
    $big->[$_] = 10 * ( $_ + 1 ) for 0 .. 7;
    is sum_int_array( $r, 8 ), 360, 'C sees all eight ints after realloc';
    my $warned = 0;
    local $SIG{__WARN__} = sub { $warned++ };
    ok free($r), 'free() works on the reallocated pin';
    is $warned, 0, 'no warning during free';
};
#
subtest 'realloc: shrinks without corrupting the owner' => sub {
    my $r = calloc( 8, sizeof Int );
    ok realloc( $r, 16 ), 'realloc shrank to 16 bytes';
    my $v = cast( $r, Array [ Int, 4 ] );
    is $v->[0], 0, 'reallocated memory still readable';
    is $v->[3], 0, 'reallocated memory still readable at the end';
    ok free($r), 'free() works after shrinking';
};
#
subtest 'free() then DESTROY does not double-free' => sub {
    my $ptr = malloc(64);
    ok free($ptr), 'explicit free succeeded';

    # Reassign/undef to let the pin go out of scope; DESTROY must no-op
    $ptr = undef;
    ok 1, 'no crash/double-free when the pin is released after free()';
};
#
subtest 'malloc interop: C reads/writes the pinned memory' => sub {
    my $p = malloc( sizeof Int );
    my $i = cast( $p, Pointer [Int] );
    $$i = 42;
    is read_int_from_void_ptr($p), 42, 'C read the value Perl wrote via the pin';
    $$i = 1234;
    is read_int_from_void_ptr($p), 1234, 'C reads updates too';
    ok free($p), 'free() after interop';
};
#
subtest 'own() semantics unchanged' => sub {
    is own( malloc(64) ), F(), 'own() is false for a malloc pin (wrapped in Pointer[Void])';
    my $mem = alloc_owned(64);
    ok own($mem),  'own() is true for an Affix::Memory object';
    ok free($mem), 'free() works on the raw object';
};
#
done_testing;
