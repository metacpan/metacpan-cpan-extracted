package Sakila::City;

use strict;

use base qw(DBIx::Cookbook::RDBO::Sakila);

__PACKAGE__->meta->setup(
    table   => 'city',

    columns => [
        city_id     => { type => 'integer', not_null => 1 },
        city        => { type => 'varchar', length => 50, not_null => 1 },
        country_id  => { type => 'integer', not_null => 1 },
        last_update => { type => 'timestamp', not_null => 1 },
    ],

    primary_key_columns => [ 'city_id' ],

    foreign_keys => [
        country => {
            class       => 'Sakila::Country',
            key_columns => { country_id => 'country_id' },
        },
    ],

    relationships => [
        address => {
            class      => 'Sakila::Address',
            column_map => { city_id => 'city_id' },
            type       => 'one to many',
        },
    ],
);

1;

