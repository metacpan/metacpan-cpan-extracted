
use strict;
use warnings;

use Test::Fatal;
use Test::More;
use lib 't/lib';

use Tests;

unless ( $ENV{ETCD_TEST_HOST} and $ENV{ETCD_TEST_PORT}) {
    plan skip_all => "Please set environment variable ETCD_TEST_HOST and ETCD_TEST_PORT.";
}

Tests::run_tests( { session => 'Simple' } );

done_testing;
