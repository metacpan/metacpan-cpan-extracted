package #
    DBICTest::Schema::Artist;

use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table("artist");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "cds",
  "DBICTest::Schema::CD",
  { "foreign.artist" => "self.id" },
  {},
);




1