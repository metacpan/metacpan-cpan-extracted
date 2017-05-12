package YUI::Test::FooGoo;

use strict;

use base qw( YUI::Test );

__PACKAGE__->meta->setup(
    table => 'foo_goos',

    columns => [
        foo_id => { type => 'integer', not_null => 1 },
        goo_id => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns => [ 'foo_id', 'goo_id' ],

    foreign_keys => [
        foo => {
            class       => 'YUI::Test::Foo',
            key_columns => { foo_id => 'id' }
        },
        goo => {
            class       => 'YUI::Test::Goo',
            key_columns => { goo_id => 'id' }
        },
    ],
);
