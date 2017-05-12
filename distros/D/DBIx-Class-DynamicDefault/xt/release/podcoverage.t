use strict;
use warnings;
use Test::Pod::Coverage;

all_pod_coverage_ok({ trustme => [ qw/add_columns insert update/ ] });
