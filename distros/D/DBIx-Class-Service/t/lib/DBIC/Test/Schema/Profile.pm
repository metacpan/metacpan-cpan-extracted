package DBIC::Test::Schema::Profile;

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
__PACKAGE__->table("Profile");
__PACKAGE__->add_columns(
  "user_seq",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "name",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "nickname",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "created_on",
  { data_type => "DATETIME", is_nullable => 0, size => undef, set_on_create => 1, },
  "updated_on",
  { data_type => "DATETIME", is_nullable => 0, size => undef, set_on_create => 1, set_on_update => 1 },
);
__PACKAGE__->set_primary_key("user_seq");
__PACKAGE__->belongs_to(
  "user_seq",
  "DBIC::Test::Schema::User",
  { user_seq => "user_seq" },
);


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2008-03-27 19:43:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TxSErHcw+OPRBDykD6mnaw

__PACKAGE__->column_info('created_on')->{set_on_create} = 1;
__PACKAGE__->column_info('updated_on')->{set_on_create} = 1;
__PACKAGE__->column_info('updated_on')->{set_on_update} = 1;


# You can replace this text with custom content, and it will be preserved on regeneration
1;
