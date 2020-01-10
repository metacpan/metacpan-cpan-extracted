use utf8;
package Catalyst::Authentication::RedmineCookie::Schema::Result::GroupsUsers;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("groups_users");
__PACKAGE__->add_columns(
  "group_id",
  { data_type => "integer", is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->add_unique_constraint("groups_users_ids", ["group_id", "user_id"]);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-01-08 16:40:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LogqyioZ6dUH0tNechwiew


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
