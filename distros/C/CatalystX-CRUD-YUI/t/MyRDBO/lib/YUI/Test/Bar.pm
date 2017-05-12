package YUI::Test::Bar;

use strict;

use base qw(YUI::Test);

__PACKAGE__->meta->setup(
    table => 'bars',

    columns => [
        id     => { type => 'serial' },
        name   => { type => 'varchar', length => 16 },
        foo_id => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns => ['id'],

    unique_key => ['name'],

    foreign_keys => [
        foo => {
            class       => 'YUI::Test::Foo',
            key_columns => { foo_id => 'id' }
        },
    ],
);

1;

