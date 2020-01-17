use utf8;
package Catalyst::Authentication::RedmineCookie::Schema::Result::Projects;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("projects");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "homepage",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 255 },
  "is_public",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
  "parent_id",
  { data_type => "integer", is_nullable => 1 },
  "created_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
    locale => "ja_JP",
    timezone => "Asia/Tokyo",
  },
  "updated_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
    locale => "ja_JP",
    timezone => "Asia/Tokyo",
  },
  "identifier",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "status",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "lft",
  { data_type => "integer", is_nullable => 1 },
  "rgt",
  { data_type => "integer", is_nullable => 1 },
  "inherit_members",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "default_version_id",
  { data_type => "integer", is_nullable => 1 },
  "default_assigned_to_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-01-17 15:00:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5439wSyfG/zv1syOZnj2iA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
