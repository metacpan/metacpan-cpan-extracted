package DBSchema::Result::Role;

# Created by DBIx::Class::Schema::Loader v0.03000 @ 2006-10-02 08:24:09

use strict;
use warnings;

use base 'DBIx::Class';
use overload '""' => sub {$_[0]->id}, fallback => 1;

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table("role");
__PACKAGE__->add_columns(
    "id" => {
        data_type => 'integer',
        is_auto_increment => 1,
    },
    "role" => {
        data_type => 'varchar',
        size      => '100',
      }
  );
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many("user_roles", "UserRole", { "foreign.role" => "self.id" });
__PACKAGE__->many_to_many('users', 'user_roles' => 'user');

1;

