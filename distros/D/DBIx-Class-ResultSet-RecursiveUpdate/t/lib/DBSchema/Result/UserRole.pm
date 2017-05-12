package DBSchema::Result::UserRole;

# Created by DBIx::Class::Schema::Loader v0.03000 @ 2006-10-02 08:24:09

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table("user_role");
__PACKAGE__->add_columns(
    "user" => { data_type => 'integer' } , 
    "role" => { data_type => 'integer' }
);
__PACKAGE__->set_primary_key("user", "role");
__PACKAGE__->belongs_to("user", "User", { id => "user" });
__PACKAGE__->belongs_to("role", "Role", { id => "role" });

1;

