package #
    DBICTest::Schema::CD;

use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table("cd");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "artist",
  { data_type => "integer" },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "artist",
  "DBICTest::Schema::Artist",
  { id => "artist" }
);

1