use utf8;
package Catalyst::Authentication::RedmineCookie::Schema::Result::MemberRoles;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("member_roles");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "member_id",
  { data_type => "integer", is_nullable => 0 },
  "role_id",
  { data_type => "integer", is_nullable => 0 },
  "inherited_from",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-01-17 15:00:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JSenirGEJ82feu5iaFhsVg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
