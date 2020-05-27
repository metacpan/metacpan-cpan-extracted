#!/usr/bin/env perl

use v5.16.3;
use strict;
use warnings;

BEGIN {
    use Data::AnyXfer;
    Data::AnyXfer->test(1);
}

use Test::Most;
use Data::AnyXfer::Elastic::Snapshot tests => 1;

can_ok(
    Data::AnyXfer::Elastic::Snapshot->new( silo => 'public_data' ),
    qw/ create_repository get_repository delete_repository create get delete
        restore/,
);

done_testing();
