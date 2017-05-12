package MyApp::Schema::Result::BookAuthor;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("book_author");

__PACKAGE__->add_columns(
  "book_id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
  "author_id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("book_id", "author_id");

__PACKAGE__->belongs_to(
  "book",
  "MyApp::Schema::Result::Book",
  { id => "book_id" },
  { join_type => "LEFT" },
);

__PACKAGE__->belongs_to(
  "author",
  "MyApp::Schema::Result::Author",
  { id => "author_id" },
  { join_type => "LEFT" },
);

1;
