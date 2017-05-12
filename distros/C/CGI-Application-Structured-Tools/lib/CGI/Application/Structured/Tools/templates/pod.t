#!perl -T
#
# $Id: pod.t 52 2009-01-06 03:22:31Z jaldhar $
#
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp;";
if ($EVAL_ERROR) {
    plan skip_all => "Test::Pod $min_tp required for testing POD";
}
all_pod_files_ok();
