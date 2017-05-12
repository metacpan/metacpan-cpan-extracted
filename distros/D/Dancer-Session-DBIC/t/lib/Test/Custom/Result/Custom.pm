package Test::Custom::Result::Custom;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(TimeStamp));

__PACKAGE__->table("customs");

__PACKAGE__->add_columns(
  "customs_id",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "custom_data",
  { data_type => "text", is_nullable => 0 },
  "created",
  { data_type => "datetime", set_on_create => 1, is_nullable => 0 },
  "last_modified",
  { data_type => "datetime", set_on_create => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("customs_id");

1;
