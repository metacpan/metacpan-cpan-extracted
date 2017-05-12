package App::Cinema::Schema::Result::UserRoles;
use Moose;
use namespace::autoclean;

BEGIN {
	extends 'DBIx::Class';
	our $VERSION = $App::Cinema::VERSION;
}

__PACKAGE__->load_components( "InflateColumn::DateTime", "Core" );
__PACKAGE__->table("user_roles");
__PACKAGE__->add_columns(
	"user_id",
	{
		data_type     => "VARCHAR",
		default_value => undef,
		is_nullable   => 0,
		size          => 20,
	},
	"role_id",
	{ data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key( "user_id", "role_id" );
__PACKAGE__->belongs_to(
	"user",
	"App::Cinema::Schema::Result::Users",
	{ username => "user_id" },
);
__PACKAGE__->belongs_to(
	"role",
	"App::Cinema::Schema::Result::Roles",
	{ id => "role_id" },
);

# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-01-29 22:05:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6jZBfHBynQ3WibUvhtQ52A

# You can replace this text with custom content, and it will be preserved on regeneration
1;
