use strict;
use Test::More;

plan skip_all => "Enable TEST_POD environment variable to test POD"
    if not $ENV{TEST_POD} and not -d '.git';

plan skip_all => "Test::Pod required for testing pod coverage"
    if not eval "use Test::Pod; 1";

Test::Pod::all_pod_files_ok();
