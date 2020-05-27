#!/usr/bin/env perl

use v5.16.3;
use strict;
use warnings;

BEGIN {
    use Data::AnyXfer;
    Data::AnyXfer->test(1);
}

use Test::Most;
use Data::AnyXfer::Elastic::Indices tests => 1;

can_ok(
    Data::AnyXfer::Elastic::Indices->new( silo => 'public_data' ),
    (

        #INDEX METHODS
        'create',
        'exists',
        'delete',
        'close',
        'open',
        'clear_cache',
        'refresh',
        'flush',

        #MAPPING METHODS
        'put_mapping',
        'get_mapping',
        'get_field_mapping',
        'exists_type',

        #ALIAS METHODS
        'update_aliases',
        'get_aliases',
        'put_alias',
        'get_alias',
        'exists_alias',
        'delete_alias',

        #SETTINGS METHODS
        'put_settings',
        'get_settings',

        #TEMPLATE METHODS
        'put_template',
        'get_template',
        'exists_template',
        'delete_template',

    )
);

done_testing();
