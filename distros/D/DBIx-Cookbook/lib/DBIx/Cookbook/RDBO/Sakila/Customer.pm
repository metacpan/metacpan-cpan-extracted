package Sakila::Customer;

use strict;

use base qw(DBIx::Cookbook::RDBO::Sakila);

__PACKAGE__->meta->setup(
    table   => 'customer',

    columns => [
        customer_id => { type => 'integer', not_null => 1 },
        store_id    => { type => 'integer', not_null => 1 },
        first_name  => { type => 'varchar', length => 45, not_null => 1 },
        last_name   => { type => 'varchar', length => 45, not_null => 1 },
        email       => { type => 'varchar', length => 50 },
        address_id  => { type => 'integer', not_null => 1 },
        active      => { type => 'integer', default => 1, not_null => 1 },
        create_date => { type => 'datetime', not_null => 1 },
        last_update => { type => 'timestamp', not_null => 1 },
    ],

    primary_key_columns => [ 'customer_id' ],

    foreign_keys => [
        address => {
            class       => 'Sakila::Address',
            key_columns => { address_id => 'address_id' },
        },

        store => {
            class       => 'Sakila::Store',
            key_columns => { store_id => 'store_id' },
        },
    ],

    relationships => [
        payment => {
            class      => 'Sakila::Payment',
            column_map => { customer_id => 'customer_id' },
            type       => 'one to many',
        },

        rental => {
            class      => 'Sakila::Rental',
            column_map => { customer_id => 'customer_id' },
            type       => 'one to many',
        },
    ],
);

1;

