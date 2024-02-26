package MyApp::Schema::Result::Book;
use v5.26;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components("Relationship::Predicate", "InflateColumn::DateTime", "InflateColumn::Time",);

__PACKAGE__->table("Book");

__PACKAGE__->add_columns(
  id        => {data_type => "integer", is_nullable => 0, is_auto_increment => 1,},
  title     => {data_type => "varchar", is_nullable => 0, size              => 45},
  author_id => {data_type => "integer", is_nullable => 1, is_foreign_key    => 1,},
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "author",
  "MyApp::Schema::Result::Person",
  {id            => "author_id"},
  {is_deferrable => 1, join_type => "LEFT", on_delete => "NO ACTION", on_update => "NO ACTION",},
);

1;
