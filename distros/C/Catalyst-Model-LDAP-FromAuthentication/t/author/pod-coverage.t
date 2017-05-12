#!/usr/bin/env perl

use Test::More;
use Test::Pod::Coverage 1.04;
all_pod_coverage_ok({
    also_private => [qw/
        build_per_context_instance
    /]
});
