package DBSchema::Result::Address;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("address");
__PACKAGE__->add_columns(
  "address_id",
  { data_type => "INTEGER", is_auto_increment => 1,
      is_nullable => 0 },
  "user_id",
  { data_type => "INTEGER", is_nullable => 0 },
  "street",
  { data_type => "VARCHAR", is_nullable => 0, size => 32 },
  "city",
  { data_type => "VARCHAR", is_nullable => 0, size => 32 },
  "state",
  { data_type => "VARCHAR", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("address_id");

__PACKAGE__->belongs_to(
    'user',
    'DBSchema::Result::User',
    'user_id',
);


1;
