use strict;
use warnings;

use Test::More;

BEGIN { plan skip_all => 'Not release testing context' unless $ENV{ RELEASE_TESTING } }

use Test::Needs { 'Test::Pod::Coverage' => 1.04 };

Test::Pod::Coverage::all_pod_coverage_ok();
