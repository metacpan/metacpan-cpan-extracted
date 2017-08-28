use Test::More;
BEGIN {
    if (! $ENV{TEST_POD}) {
        plan skip_all => "TEST_POD not set";
    }
}
use Test::Requires;

test_requires 'Test::Pod';
Test::Pod::all_pod_files_ok();