#!/usr/bin/env perl

use v5.16.3;
use strict;
use warnings;

BEGIN {
    use Data::AnyXfer;
    Data::AnyXfer->test(1);
}

use Test::Most;

use Data::AnyXfer::Elastic::Index;

# more tests covering Elasticsearch::Index are performed by testimport.t

can_ok(
    Data::AnyXfer::Elastic::Index->new(
        silo => 'public_data',
        index_name => 'void',
        index_type => 'void'
    ),
    qw/index get get_source exists delete update
        bulk bulk_helper mget delete_by_query
        search count scroll clear_scroll scroll_helper msearch
        explain count suggest/
);

done_testing();
