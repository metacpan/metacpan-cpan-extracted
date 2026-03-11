package TestSchema::Result::Author;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('author');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    first_name => {
        data_type   => 'varchar',
        size        => 100,
        is_nullable => 0,
    },
    last_name => {
        data_type   => 'varchar',
        size        => 100,
        is_nullable => 0,
    },
    email => {
        data_type   => 'varchar',
        size        => 200,
        is_nullable => 0,
    },
    bio => {
        data_type   => 'text',
        is_nullable => 1,
    },
    created_at => {
        data_type   => 'datetime',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( unique_email => ['email'] );

__PACKAGE__->has_many(
    books => 'TestSchema::Result::Book', 'author_id'
);

1;
