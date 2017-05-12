package YUI::Test::Goo;

use strict;

use base qw(YUI::Test);

__PACKAGE__->meta->setup(
    table => 'goos',

    columns => [
        id   => { type => 'serial' },
        name => { type => 'varchar', length => 16 },
    ],

    primary_key_columns => ['id'],

    relationships => [
        foogoos => {
            map_class => 'YUI::Test::FooGoo',
            type      => 'many to many',
        }
    ],
);

1;

