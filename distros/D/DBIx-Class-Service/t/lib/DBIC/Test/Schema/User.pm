package DBIC::Test::Schema::User;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(
  "ResultSetManager",
  "UTF8Columns",
  "InflateColumn::DateTime",
  "TimeStamp",
  "Core",
);
__PACKAGE__->table("User");
__PACKAGE__->add_columns(
  "user_seq",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "user_id",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "password_digest",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "created_on",
  { data_type => "DATETIME", is_nullable => 0, size => undef, set_on_create => 1 },
  "updated_on",
  { data_type => "DATETIME", is_nullable => 0, size => undef, set_on_create => 1, set_on_update => 1 },
);
__PACKAGE__->set_primary_key("user_seq");
__PACKAGE__->has_many(
  "profiles",
  "DBIC::Test::Schema::Profile",
  { "foreign.user_seq" => "self.user_seq" },
);
__PACKAGE__->has_many(
  "diaries",
  "DBIC::Test::Schema::Diary",
  { "foreign.user_seq" => "self.user_seq" },
);


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2008-03-27 19:43:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:H9XN7HIDSfIk6xNs+8U2ew

__PACKAGE__->column_info('created_on')->{set_on_create} = 1;
__PACKAGE__->column_info('updated_on')->{set_on_create} = 1;
__PACKAGE__->column_info('updated_on')->{set_on_update} = 1;

# You can replace this text with custom content, and it will be preserved on regeneration
1;
