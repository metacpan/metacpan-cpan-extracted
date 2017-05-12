package Sakila::Staff;

use strict;

use base qw(DBIx::Cookbook::RDBO::Sakila);

__PACKAGE__->meta->setup(
    table   => 'staff',

    columns => [
        staff_id    => { type => 'integer', not_null => 1 },
        first_name  => { type => 'varchar', length => 45, not_null => 1 },
        last_name   => { type => 'varchar', length => 45, not_null => 1 },
        address_id  => { type => 'integer', not_null => 1 },
        picture     => { type => 'blob', length => 65535 },
        email       => { type => 'varchar', length => 50 },
        store_id    => { type => 'integer', not_null => 1 },
        active      => { type => 'integer', default => 1, not_null => 1 },
        username    => { type => 'varchar', length => 16, not_null => 1 },
        password    => { type => 'varchar', length => 40 },
        last_update => { type => 'timestamp', not_null => 1 },
    ],

    primary_key_columns => [ 'staff_id' ],

    foreign_keys => [
        address => {
            class       => 'Sakila::Address',
            key_columns => { address_id => 'address_id' },
        },

        store_obj => {
            class       => 'Sakila::Store',
            key_columns => { store_id => 'store_id' },
        },
    ],

    relationships => [
        payment => {
            class      => 'Sakila::Payment',
            column_map => { staff_id => 'staff_id' },
            type       => 'one to many',
        },

        rental => {
            class      => 'Sakila::Rental',
            column_map => { staff_id => 'staff_id' },
            type       => 'one to many',
        },

        store => {
            class                => 'Sakila::Store',
            column_map           => { staff_id => 'manager_staff_id' },
            type                 => 'one to one',
            with_column_triggers => '0',
        },
    ],
);

1;

