use utf8;
package Catalyst::Authentication::RedmineCookie::Schema::Result::Members;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("members");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "project_id",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "created_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
    locale => "ja_JP",
    timezone => "Asia/Tokyo",
  },
  "mail_notification",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(
  "index_members_on_user_id_and_project_id",
  ["user_id", "project_id"],
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-01-08 16:40:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5SfuiHLEGAkGnvmVteYxYQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
