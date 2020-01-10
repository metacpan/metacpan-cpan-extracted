use utf8;
package Catalyst::Authentication::RedmineCookie::Schema::Result::RolesManagedRoles;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("roles_managed_roles");
__PACKAGE__->add_columns(
  "role_id",
  { data_type => "integer", is_nullable => 0 },
  "managed_role_id",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->add_unique_constraint(
  "index_roles_managed_roles_on_role_id_and_managed_role_id",
  ["role_id", "managed_role_id"],
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-01-08 16:41:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Dl316HeR1jN4AMdFrF30sA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
