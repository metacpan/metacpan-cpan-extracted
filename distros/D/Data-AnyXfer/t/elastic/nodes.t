#!/usr/bin/env perl

use v5.16.3;
use strict;
use warnings;

BEGIN {
    use Data::AnyXfer;
    Data::AnyXfer->test(1);
}

use Test::Most;
use Data::AnyXfer::Elastic::Nodes tests => 1;

can_ok(
    Data::AnyXfer::Elastic::Nodes->new( silo => 'public_data' ),
    qw/info stats hot_threads/
);

done_testing();
