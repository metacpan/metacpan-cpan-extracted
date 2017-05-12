package Sakila::FilmCategory;

use strict;

use base qw(DBIx::Cookbook::RDBO::Sakila);

__PACKAGE__->meta->setup(
    table   => 'film_category',

    columns => [
        film_id     => { type => 'integer', not_null => 1 },
        category_id => { type => 'integer', not_null => 1 },
        last_update => { type => 'timestamp', not_null => 1 },
    ],

    primary_key_columns => [ 'film_id', 'category_id' ],

    foreign_keys => [
        category => {
            class       => 'Sakila::Category',
            key_columns => { category_id => 'category_id' },
        },

        film => {
            class       => 'Sakila::Film',
            key_columns => { film_id => 'film_id' },
        },
    ],
);

1;

