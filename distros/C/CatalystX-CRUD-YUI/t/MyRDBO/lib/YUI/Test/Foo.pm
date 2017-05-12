package YUI::Test::Foo;

use strict;

use base qw(YUI::Test);

__PACKAGE__->meta->setup(
    table => 'foos',

    columns => [
        id      => { type => 'serial' },
        name    => { type => 'varchar', length => 16 },
        static  => { type => 'character', length => 8 },
        my_int  => { type => 'integer', default => '0', not_null => 1 },
        my_dec  => { type => 'float' },
        my_bool => { type => 'boolean', default => 't', not_null => 1 },
        ctime   => { type => 'datetime' },
    ],

    primary_key_columns => ['id'],

    relationships => [
        bars => {
            class      => 'YUI::Test::Bar',
            column_map => { id => 'foo_id' },
            type       => 'one to many',
        },

        foogoos => {
            map_class => 'YUI::Test::FooGoo',
            type      => 'many to many',
        }
    ],
);

1;

