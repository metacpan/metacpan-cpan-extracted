#!perl -T
#
# $Id: /svn/DateTime-Event-Klingon/tags/VERSION_1_0_1/t/pod-coverage.t 323 2008-04-01T06:37:25.246199Z jaldhar  $
#
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More;

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc;";
if ($EVAL_ERROR) {
    plan skip_all =>
        "Test::Pod::Coverage $min_tpc required for testing POD coverage";
}

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc;";
if ($EVAL_ERROR) {
    plan skip_all =>
        "Pod::Coverage $min_pc required for testing POD coverage";
}

all_pod_coverage_ok();
