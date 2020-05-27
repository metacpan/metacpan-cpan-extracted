#!/usr/bin/env perl

use v5.16.3;
use strict;
use warnings;

BEGIN {
    use Data::AnyXfer;
    Data::AnyXfer->test(1);
}

use Test::Most;
use aliased 'Data::AnyXfer::Elastic::Utils';

# Test to ensure that if being executued with test variable set then the index
# name is prepended with the current hostname. e.g. eddev_properties

foreach my $test ( hostname_tests() ) {
    my $index_name = Utils->configure_index_name(
        'index',
        $test->{hostname},    #
        $test->{user},
    );

    is( $index_name, $test->{expected}, $test->{expected} );
}

# test for when index name is an array
my $name = Utils->configure_index_name( [ 'countries', 'cities' ], 'foodev',
    'foo' );
is_deeply(
    $name,
    [ 'foo_foodev_dt_nyxfrdrft_countries', 'foo_foodev_dt_nyxfrdrft_cities' ],
    "Multiple index names"
);

done_testing();


sub hostname_tests {
    return (
        {   hostname => 'eddev',
            user     => 'ed',
            expected => 'ed_eddev_dt_nyxfrdrft_index',
        },
        {   hostname => 'leodev',
            user     => 'leo',
            expected => 'leo_leodev_dt_nyxfrdrft_index'
        },
        {   hostname => 'maya',
            user     => 'web',
            expected => 'web_maya_dt_nyxfrdrft_index'
        },
        {   hostname => 'stage',
            user     => 'web',
            expected => 'web_stage_dt_nyxfrdrft_index'
        },
        {   hostname => 'training',
            user     => 'web',
            expected => 'web_training_dt_nyxfrdrft_index'
        },
        {   hostname => 'w-bos',
            user     => 'web',
            expected => 'web_w_bos_dt_nyxfrdrft_index'
        },
        {   hostname => 'w-maya',
            user     => 'web',
            expected => 'web_w_maya_dt_nyxfrdrft_index'
        },
        {   hostname => 'w-smoker',
            user     => 'web',
            expected => 'web_w_smoker_dt_nyxfrdrft_index'
        },
        {   hostname => 'wt-test-maya',
            user     => 'web',
            expected => 'web_wt_test_maya_dt_nyxfrdrft_index'
        },
        {   hostname => 'wt-test-node2',
            user     => 'web',
            expected => 'web_wt_test_node2_dt_nyxfrdrft_index'
        },
        {   hostname => 'wt-test-node3',
            user     => 'web',
            expected => 'web_wt_test_node3_dt_nyxfrdrft_index'
        },
        {   hostname => 'w-smoker-oneoff',
            user     => 'web',
            expected => 'web_w_smoker_oneoff_dt_nyxfrdrft_index'
        },

    );
}
