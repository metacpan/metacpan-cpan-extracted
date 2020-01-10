use utf8;
package Catalyst::Authentication::RedmineCookie::Schema::Result::Users;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("users");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "login",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "hashed_password",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 40 },
  "firstname",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 30 },
  "lastname",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "admin",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "status",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "last_login_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
    locale => "ja_JP",
    timezone => "Asia/Tokyo",
  },
  "language",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 5 },
  "auth_source_id",
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
  "type",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "identity_url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "mail_notification",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "salt",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "must_change_passwd",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "passwd_changed_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
    locale => "ja_JP",
    timezone => "Asia/Tokyo",
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-01-08 16:40:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:R0cM5jSZ99OQt/aX82RFJw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
