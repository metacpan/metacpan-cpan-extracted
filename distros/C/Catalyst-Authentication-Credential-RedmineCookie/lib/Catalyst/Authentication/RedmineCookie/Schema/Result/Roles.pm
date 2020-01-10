use utf8;
package Catalyst::Authentication::RedmineCookie::Schema::Result::Roles;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("roles");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 30 },
  "position",
  { data_type => "integer", is_nullable => 1 },
  "assignable",
  { data_type => "tinyint", default_value => 1, is_nullable => 1 },
  "builtin",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "permissions",
  { data_type => "text", is_nullable => 1 },
  "issues_visibility",
  {
    data_type => "varchar",
    default_value => "default",
    is_nullable => 0,
    size => 30,
  },
  "users_visibility",
  {
    data_type => "varchar",
    default_value => "all",
    is_nullable => 0,
    size => 30,
  },
  "time_entries_visibility",
  {
    data_type => "varchar",
    default_value => "all",
    is_nullable => 0,
    size => 30,
  },
  "all_roles_managed",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
  "settings",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-01-08 16:41:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yp2TAofJE0DzQgYoacqUYA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
