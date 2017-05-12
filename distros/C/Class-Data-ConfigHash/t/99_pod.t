use Test::More;
use strict;
if (! $ENV{TEST_POD}) {
    plan skip_all => "Enable TEST_POD environment variable to test POD";
} else {
    eval "use Test::Pod 1.00";
    plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
    Test::Pod::all_pod_files_ok();
}