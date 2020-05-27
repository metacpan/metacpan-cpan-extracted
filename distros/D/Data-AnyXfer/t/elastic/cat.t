#!/usr/bin/env perl

use v5.16.3;
use strict;
use warnings;

BEGIN {
    use Data::AnyXfer;
    Data::AnyXfer->test(1);
}

use Test::Most;
use Data::AnyXfer::Elastic::Cat tests => 1;

can_ok(
    Data::AnyXfer::Elastic::Cat->new( silo => 'public_data' ),
    qw/ help aliases allocation count health indices master nodes
        pending_tasks recovery shards thread_pool /,
);

done_testing();
