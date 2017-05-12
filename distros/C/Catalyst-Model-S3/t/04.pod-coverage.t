#!perl -wT

use strict;
use warnings;

use Test::More;


eval 'use Test::Pod::Coverage 1.04';
if ( $@ ) {
    plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage';
}
else {
    Test::Pod::Coverage::all_pod_coverage_ok();
}
