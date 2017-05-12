package Sakila::Payment;

use strict;

use base qw(DBIx::Cookbook::RDBO::Sakila);

__PACKAGE__->meta->setup(
    table   => 'payment',

    columns => [
        payment_id   => { type => 'integer', not_null => 1 },
        customer_id  => { type => 'integer', not_null => 1 },
        staff_id     => { type => 'integer', not_null => 1 },
        rental_id    => { type => 'integer' },
        amount       => { type => 'numeric', not_null => 1, precision => 5, scale => 2 },
        payment_date => { type => 'datetime', not_null => 1 },
        last_update  => { type => 'timestamp', not_null => 1 },
    ],

    primary_key_columns => [ 'payment_id' ],

    foreign_keys => [
        customer => {
            class       => 'Sakila::Customer',
            key_columns => { customer_id => 'customer_id' },
        },

        rental => {
            class       => 'Sakila::Rental',
            key_columns => { rental_id => 'rental_id' },
        },

        staff => {
            class       => 'Sakila::Staff',
            key_columns => { staff_id => 'staff_id' },
        },
    ],
);

1;

