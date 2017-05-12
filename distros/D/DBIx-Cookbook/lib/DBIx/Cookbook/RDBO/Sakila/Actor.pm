package Sakila::Actor;

use strict;

use base qw(DBIx::Cookbook::RDBO::Sakila);

__PACKAGE__->meta->setup(
    table   => 'actor',

    columns => [
        actor_id    => { type => 'integer', not_null => 1 },
        first_name  => { type => 'varchar', length => 45, not_null => 1 },
        last_name   => { type => 'varchar', length => 45, not_null => 1 },
        last_update => { type => 'timestamp', not_null => 1 },
    ],

    primary_key_columns => [ 'actor_id' ],

    relationships => [
        film_actor => {
            class      => 'Sakila::FilmActor',
            column_map => { actor_id => 'actor_id' },
            type       => 'one to many',
        },
    ],
);

1;

