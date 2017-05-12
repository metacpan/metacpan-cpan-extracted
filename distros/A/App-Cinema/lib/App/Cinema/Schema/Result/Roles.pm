package App::Cinema::Schema::Result::Roles;
use Moose;
use namespace::autoclean;
BEGIN {
	extends 'DBIx::Class';
	our $VERSION = $App::Cinema::VERSION;
}

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("roles");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "role",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
	"user_roles",
	"App::Cinema::Schema::Result::UserRoles",
	{ "foreign.role_id" => "self.id" },
);
__PACKAGE__->many_to_many( users => 'user_roles', 'user' );

# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-01-29 22:05:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oGyWcJWJOejjk+TOzGvb0g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
