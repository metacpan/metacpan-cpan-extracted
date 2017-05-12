#!perl
# $Id: 99-pod-coverage.t,v 1.1 2008/05/02 14:30:33 pauldoom Exp $

use Test::More;

plan skip_all => "Test::Pod::Coverage disabled (need to document more methods)";

#eval "use Test::Pod::Coverage";
#plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

# Test coverage on all
all_pod_coverage_ok();
