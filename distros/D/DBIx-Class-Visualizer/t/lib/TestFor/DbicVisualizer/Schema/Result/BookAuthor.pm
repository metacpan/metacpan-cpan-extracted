package TestFor::DbicVisualizer::Schema::Result::BookAuthor;

use base 'DBIx::Class::Core';

__PACKAGE__->table('BookAuthor');
__PACKAGE__->add_columns(
    book_id => {
        data_type => 'int',
        is_foreign_key => 1,
    },
    author_id => {
        data_type => 'int',
        is_foreign_key => 1,
    },
);

__PACKAGE__->set_primary_key(qw/book_id author_id/);

__PACKAGE__->belongs_to(author => 'TestFor::DbicVisualizer::Schema::Result::Author', 'author_id');
__PACKAGE__->belongs_to(book => 'TestFor::DbicVisualizer::Schema::Result::Book', 'book_id');

1;
