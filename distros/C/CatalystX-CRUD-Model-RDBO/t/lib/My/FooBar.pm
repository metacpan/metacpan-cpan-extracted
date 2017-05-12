package My::FooBar;
use strict;
use base qw(
    Rose::DB::Object
    Rose::DB::Object::Helpers
    Rose::DBx::Object::MoreHelpers
);
use Carp;
use Data::Dump qw( dump );
use My::DB;

__PACKAGE__->meta->setup(
    table   => 'foo_bars',
    columns => [
        foo_id => { type => 'integer', not_null => 1 },
        bar_id => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns => [ 'foo_id', 'bar_id' ],

    foreign_keys => [
        foo => {
            class       => 'My::Foo',
            key_columns => { foo_id => 'id' }
        },
        bar => {
            class       => 'My::Bar',
            key_columns => { bar_id => 'id' }
        },
    ],
);

sub init_db {
    return My::DB->new;
}

1;
