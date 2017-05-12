use strict;
use Test::More;

plan skip_all => "Pod::Coverage 0.18 required for testing POD coverage"
    unless eval "use Pod::Coverage 0.18; 1";

plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
    unless eval "use Test::Pod::Coverage 1.08; 1";

all_pod_coverage_ok();
