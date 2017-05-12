# -*- cperl -*-
use 5.010;
use warnings;
use strict;

use English qw( -no_match_vars );
use Test::More;

my $dependency = 'Test::Pod 1.22';
eval "use $dependency;";
plan( skip_all => "$dependency required for testing POD" )
    if $EVAL_ERROR;

all_pod_files_ok();
