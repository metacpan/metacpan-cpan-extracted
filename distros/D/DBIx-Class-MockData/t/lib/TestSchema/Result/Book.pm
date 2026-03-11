package TestSchema::Result::Book;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('book');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    author_id => {
        data_type   => 'integer',
        is_nullable => 0,
    },
    title => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },
    slug => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },
    isbn => {
        data_type   => 'varchar',
        size        => 20,
        is_nullable => 1,
    },
    price => {
        data_type   => 'numeric',
        size        => [10, 2],
        is_nullable => 0,
    },
    published_on => {
        data_type   => 'date',
        is_nullable => 1,
    },
    in_print => {
        data_type     => 'boolean',
        default_value => 1,
        is_nullable   => 0,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( unique_slug => ['slug'] );

__PACKAGE__->belongs_to(
    author => 'TestSchema::Result::Author', 'author_id'
);

__PACKAGE__->has_many(
    reviews => 'TestSchema::Result::Review', 'book_id'
);

1;
