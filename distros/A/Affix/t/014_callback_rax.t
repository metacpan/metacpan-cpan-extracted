use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
#
$|++;

# Test to ensure RAX is preserved across callback execution.
# RAX is often used for the return value of functions.
# If the trampoline clobbers RAX and doesn't restore it,
# the caller might see a wrong return value or corrupt state.
my $C_CODE = <<'END_C';
#define DLLEXPORT __attribute__((visibility("default")))
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

// A callback that returns a value in RAX
typedef int (*IntCallback)(int);

DLLEXPORT int call_with_rax_dependent_return(IntCallback cb) {
    // Call the callback, which might clobber RAX
    int res = cb(10);
    // Return a value that relies on RAX not being clobbered by the trampoline's own epilogue
    return res + 1;
}

#ifdef __cplusplus
}
#endif
END_C
#
my $lib_path = compile_ok($C_CODE);
ok( $lib_path && -e $lib_path, 'Compiled a test shared library successfully' );
subtest 'RAX Preservation' => sub {
    isa_ok my $harness = wrap( $lib_path, 'call_with_rax_dependent_return', [ Callback [ [SInt32] => SInt32 ] ] => SInt32 ), ['Affix'];
    my $callback_sub = sub($val) {

        # This callback will return 42.
        return $val + 32;
    };

    # If RAX is preserved, result should be 42 + 1 = 43.
    # If RAX is clobbered, the return value of `cb(10)` might be lost,
    # or the final return value might be corrupted.
    is $harness->($callback_sub), 43, 'RAX preservation: callback return value maintained';
};
done_testing;
