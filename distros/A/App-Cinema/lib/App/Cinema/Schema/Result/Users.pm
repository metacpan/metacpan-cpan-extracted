package App::Cinema::Schema::Result::Users;
use Moose;
use namespace::autoclean;

BEGIN {
	extends 'DBIx::Class';
	our $VERSION = $App::Cinema::VERSION;
}

__PACKAGE__->load_components( "InflateColumn::DateTime", "Core" );
__PACKAGE__->table("users");
__PACKAGE__->add_columns(
	"username",
	{
		data_type     => "VARCHAR",
		default_value => undef,
		is_nullable   => 0,
		size          => 20,
	},
	"password",
	{
		data_type     => "VARCHAR",
		default_value => undef,
		is_nullable   => 1,
		size          => 20,
	},
	"first_name",
	{
		data_type     => "VARCHAR",
		default_value => undef,
		is_nullable   => 1,
		size          => 20,
	},
	"last_name",
	{
		data_type     => "VARCHAR",
		default_value => undef,
		is_nullable   => 1,
		size          => 20,
	},
	"email_address",
	{
		data_type     => "VARCHAR",
		default_value => undef,
		is_nullable   => 1,
		size          => 30,
	},
	"active",
	{
		data_type     => "INT",
		default_value => undef,
		is_nullable   => 1,
		size          => 11
	},
);
__PACKAGE__->set_primary_key("username");
__PACKAGE__->has_many(
	"events",
	"App::Cinema::Schema::Result::Event",
	{ "foreign.uid" => "self.username" },
);
__PACKAGE__->has_many(
	"user_roles",
	"App::Cinema::Schema::Result::UserRoles",
	{ "foreign.user_id" => "self.username" },
);
__PACKAGE__->has_many(
	"items",
	"App::Cinema::Schema::Result::Item",
	{ "foreign.uid" => "self.username" },
);
__PACKAGE__->has_many(
	"comments",
	"App::Cinema::Schema::Result::Comment",
	{ "foreign.uid" => "self.username" },
);

#roles : field name of User
__PACKAGE__->many_to_many( roles => 'user_roles', 'role' );

# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-01-29 22:05:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QkqRwnhCbdwkU6qhZJIchw

# You can replace this text with custom content, and it will be preserved on regeneration
1;
