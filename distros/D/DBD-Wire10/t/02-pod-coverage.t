use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

all_pod_coverage_ok({also_private => [qr/^[A-Z_0-9]+$/]});
