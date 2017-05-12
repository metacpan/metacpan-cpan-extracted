
# $Id: pod-coverage.t,v 1.1 2008-06-11 08:08:00 jonasbn Exp $

use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

all_pod_coverage_ok();
