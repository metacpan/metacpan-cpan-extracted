package Sakila::Country;

use strict;

use base qw(DBIx::Cookbook::RDBO::Sakila);

__PACKAGE__->meta->setup(
    table   => 'country',

    columns => [
        country_id  => { type => 'integer', not_null => 1 },
        country     => { type => 'varchar', length => 50, not_null => 1 },
        last_update => { type => 'timestamp', not_null => 1 },
    ],

    primary_key_columns => [ 'country_id' ],

    relationships => [
        city => {
            class      => 'Sakila::City',
            column_map => { country_id => 'country_id' },
            type       => 'one to many',
        },
    ],
);

1;

