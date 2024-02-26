package MyApp::Schema::Result::Person;
use v5.26;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components("Relationship::Predicate", "InflateColumn::DateTime", "InflateColumn::Time",);

__PACKAGE__->table("Person");

__PACKAGE__->add_columns(
  id        => {data_type => "integer", is_nullable => 0, is_auto_increment => 1,},
  firstname => {data_type => "varchar", is_nullable => 0, size              => 100},
  lastname  => {data_type => "varchar", is_nullable => 0, size              => 100},
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "books", "MyApp::Schema::Result::Book",
  {"foreign.author_id" => "self.id"},
  {cascade_copy        => 0, cascade_delete => 0},
);

1;
