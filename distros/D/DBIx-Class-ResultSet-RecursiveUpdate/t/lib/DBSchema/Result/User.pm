package DBSchema::Result::User;

# Created by DBIx::Class::Schema::Loader v0.03000 @ 2006-10-02 08:24:09

use strict;
use warnings;

use base 'DBIx::Class';
#use overload '""' => sub {$_[0]->name}, fallback => 1;

__PACKAGE__->load_components('Core');
__PACKAGE__->table("usr");
__PACKAGE__->add_columns(
    "id" => {
        data_type => 'integer',
        is_auto_increment => 1,
    },
    "username" => {
        data_type => 'varchar',
        size      => '100',
    },
    "password" => {
        data_type => 'varchar',
        size      => '100',
    },
    "name" => {
        data_type => 'varchar',
        size      => '100',
      },
  );
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many("user_roles", "UserRole", { "foreign.user" => "self.id" });
__PACKAGE__->has_many("owned_dvds", "Dvd", { "foreign.owner" => "self.id" });
__PACKAGE__->has_many(
  "borrowed_dvds",
  "Dvd",
  { "foreign.current_borrower" => "self.id" },
);
__PACKAGE__->many_to_many('roles', 'user_roles' => 'role');

__PACKAGE__->might_have(
    "address",
    "DBSchema::Result::Address",
    { 'foreign.user_id' => 'self.id' }
);

1;

