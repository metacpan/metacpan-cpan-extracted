package Sakila::Rental;

use strict;

use base qw(DBIx::Cookbook::RDBO::Sakila);

__PACKAGE__->meta->setup(
    table   => 'rental',

    columns => [
        rental_id    => { type => 'serial', not_null => 1 },
        rental_date  => { type => 'datetime', not_null => 1 },
        inventory_id => { type => 'integer', not_null => 1 },
        customer_id  => { type => 'integer', not_null => 1 },
        return_date  => { type => 'datetime' },
        staff_id     => { type => 'integer', not_null => 1 },
        last_update  => { type => 'timestamp', not_null => 1 },
    ],

    primary_key_columns => [ 'rental_id' ],

    unique_key => [ 'rental_date', 'inventory_id', 'customer_id' ],

    foreign_keys => [
        customer => {
            class       => 'Sakila::Customer',
            key_columns => { customer_id => 'customer_id' },
        },

        inventory => {
            class       => 'Sakila::Inventory',
            key_columns => { inventory_id => 'inventory_id' },
        },

        staff => {
            class       => 'Sakila::Staff',
            key_columns => { staff_id => 'staff_id' },
        },
    ],

    relationships => [
        payment => {
            class      => 'Sakila::Payment',
            column_map => { rental_id => 'rental_id' },
            type       => 'one to many',
        },
    ],
);

1;

