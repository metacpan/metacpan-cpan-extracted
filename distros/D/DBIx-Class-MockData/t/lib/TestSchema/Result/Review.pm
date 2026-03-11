package TestSchema::Result::Review;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('review');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    book_id => {
        data_type   => 'integer',
        is_nullable => 0,
    },
    reviewer_name => {
        data_type   => 'varchar',
        size        => 100,
        is_nullable => 0,
    },
    rating => {
        data_type   => 'integer',
        is_nullable => 0,
    },
    body => {
        data_type   => 'text',
        is_nullable => 1,
    },
    reviewed_at => {
        data_type   => 'datetime',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    book => 'TestSchema::Result::Book', 'book_id'
);

1;
