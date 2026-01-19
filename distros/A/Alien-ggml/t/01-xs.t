use Test2::V0;
use Test::Alien;
use Alien::ggml;

alien_ok 'Alien::ggml';

SKIP: {
    skip 'XS test skipped on macOS due to @rpath security restrictions', 1
        if $^O eq 'darwin';
    xs_ok do { local $/; <DATA> }, with_subtest { ok(1) };
}

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <ggml.h>
MODULE = Foo PACKAGE = Foo