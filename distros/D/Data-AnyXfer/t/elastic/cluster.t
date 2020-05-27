#!/usr/bin/env perl

use v5.16.3;
use strict;
use warnings;

BEGIN {
    use Data::AnyXfer;
    Data::AnyXfer->test(1);
}

use Test::Most;
use Data::AnyXfer::Elastic::Cluster tests => 1;

can_ok(
    Data::AnyXfer::Elastic::Cluster->new( silo => 'public_data' ),
    qw/health stats get_settings put_settings state
        pending_tasks reroute/
);

done_testing();
