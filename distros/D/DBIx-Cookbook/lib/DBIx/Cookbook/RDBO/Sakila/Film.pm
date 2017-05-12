package Sakila::Film;

use strict;

use base qw(DBIx::Cookbook::RDBO::Sakila);

__PACKAGE__->meta->setup(
    table   => 'film',

    columns => [
        film_id              => { type => 'integer', not_null => 1 },
        title                => { type => 'varchar', length => 255, not_null => 1 },
        description          => { type => 'text', length => 65535 },
        release_year         => { type => 'scalar', length => 4 },
        language_id          => { type => 'integer', not_null => 1 },
        original_language_id => { type => 'integer' },
        rental_duration      => { type => 'integer', default => 3, not_null => 1 },
        rental_rate          => { type => 'numeric', default => 4.99, not_null => 1, precision => 4, scale => 2 },
        length               => { type => 'integer' },
        replacement_cost     => { type => 'numeric', default => 19.99, not_null => 1, precision => 5, scale => 2 },
        rating               => { type => 'enum', check_in => [ 'G', 'PG', 'PG-13', 'R', 'NC-17' ], default => 'G' },
        special_features     => { type => 'set', values => [ 'Trailers', 'Commentaries', 'Deleted Scenes', 'Behind the Scenes' ] },
        last_update          => { type => 'timestamp', not_null => 1 },
    ],

    primary_key_columns => [ 'film_id' ],

    foreign_keys => [
        language => {
            class       => 'Sakila::Language',
            key_columns => { language_id => 'language_id' },
        },

        original => {
            class       => 'Sakila::Language',
            key_columns => { original_language_id => 'language_id' },
        },
    ],

    relationships => [
        film_actor => {
            class      => 'Sakila::FilmActor',
            column_map => { film_id => 'film_id' },
            type       => 'one to many',
        },

        film_category => {
            class      => 'Sakila::FilmCategory',
            column_map => { film_id => 'film_id' },
            type       => 'one to many',
        },

        inventory => {
            class      => 'Sakila::Inventory',
            column_map => { film_id => 'film_id' },
            type       => 'one to many',
        },
    ],
);

1;

