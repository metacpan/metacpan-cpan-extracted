use utf8;
package Catalyst::Authentication::RedmineCookie::Schema::Result::UserPreferences;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("user_preferences");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "others",
  { data_type => "text", is_nullable => 1 },
  "hide_mail",
  { data_type => "tinyint", default_value => 1, is_nullable => 1 },
  "time_zone",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-01-08 16:40:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6GlJjjnrXdyQu+fs3pgSsw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
