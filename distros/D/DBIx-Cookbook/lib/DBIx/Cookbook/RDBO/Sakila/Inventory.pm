package Sakila::Inventory;

use strict;

use base qw(DBIx::Cookbook::RDBO::Sakila);

__PACKAGE__->meta->setup(
    table   => 'inventory',

    columns => [
        inventory_id => { type => 'integer', not_null => 1 },
        film_id      => { type => 'integer', not_null => 1 },
        store_id     => { type => 'integer', not_null => 1 },
        last_update  => { type => 'timestamp', not_null => 1 },
    ],

    primary_key_columns => [ 'inventory_id' ],

    foreign_keys => [
        film => {
            class       => 'Sakila::Film',
            key_columns => { film_id => 'film_id' },
        },

        store => {
            class       => 'Sakila::Store',
            key_columns => { store_id => 'store_id' },
        },
    ],

    relationships => [
        rental => {
            class      => 'Sakila::Rental',
            column_map => { inventory_id => 'inventory_id' },
            type       => 'one to many',
        },
    ],
);

1;

