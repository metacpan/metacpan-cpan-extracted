#	$Id: 92-pod.t 49 2014-05-02 11:30:14Z adam $

use strict;
use Test::More;

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
all_pod_coverage_ok();
