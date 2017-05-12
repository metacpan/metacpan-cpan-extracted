package TestAppC3Fail::Schema::DB::User;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("users");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "first_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "middle_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "last_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "email_address",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);
__PACKAGE__->set_primary_key("id");

1;
