# -*- cperl -*-
use 5.010;
use warnings;
use strict;

use English qw( -no_match_vars );
use Test::More tests => 1;

foreach my $dependency ( 'Test::Pod::Coverage 1.08',
                         'Pod::Coverage       0.18' ) {

    eval "use $dependency;";
    plan( skip_all => "$dependency required for testing POD coverage" )
        if $EVAL_ERROR;
}

pod_coverage_ok( 'Carp::Capture' );
