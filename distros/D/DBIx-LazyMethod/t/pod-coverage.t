# t/pod-coverage.t $Id: pod-coverage.t,v 1.1 2004/03/27 13:38:46 cwg Exp $

use Test::More;

eval "use Test::Pod::Coverage 0.08";
plan skip_all => "Test::Pod::Coverage 0.08 required for testing POD coverage" if $@;

all_pod_coverage_ok();
