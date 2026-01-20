use Test2::V0;
use Test::Alien;
use Alien::ggml;

alien_ok 'Alien::ggml';

diag "Install type: " . Alien::ggml->install_type;
diag "Libs: " . Alien::ggml->libs;

SKIP: {
    # Skip XS test on macOS due to @rpath security restrictions
    skip 'XS test skipped on macOS due to @rpath security restrictions', 1
        if $^O eq 'darwin';
    
    skip 'XS runtime loading test skipped for share install (see Alien::Build::Manual::FAQ)', 1
        if $^O eq 'linux' && Alien::ggml->install_type eq 'share';
    
    xs_ok do { local $/; <DATA> }, with_subtest { ok(1) };
}

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <ggml.h>
MODULE = Foo PACKAGE = Foo