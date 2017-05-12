package MyDBIC::Schema::Foo;

use strict;
use warnings;

use base 'MyDBIC::Base::DBIC';

__PACKAGE__->table('foos');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    name => {
        data_type   => 'varchar',
        size        => 16,
        is_nullable => 1,
    },
    static => {
        data_type   => 'char',
        size        => 8,
        is_nullable => 1,
    },
    my_int => {
        data_type         => 'int',
        is_auto_increment => 0,
        is_nullable       => 0,
    },
    my_dec => {
        data_type         => 'float',
        is_auto_increment => 0,
        is_nullable       => 1,
    },
    my_bool => {
        data_type         => 'boolean',
        is_auto_increment => 0,
        is_nullable       => 0,
        default_value     => 1,
    },

    ctime => {
        data_type   => 'datetime',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many( bars => 'MyDBIC::Schema::Bar' => 'foo_id' );
__PACKAGE__->has_many( foo_goo => 'MyDBIC::Schema::FooGoo', 'foo_id' );
__PACKAGE__->many_to_many( foogoos => 'foo_goo', 'goo' );

1;
