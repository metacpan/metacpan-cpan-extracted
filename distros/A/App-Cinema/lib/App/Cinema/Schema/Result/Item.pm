package App::Cinema::Schema::Result::Item;
use Moose;
use namespace::autoclean;

BEGIN {
	extends 'DBIx::Class';
	our $VERSION = $App::Cinema::VERSION;
}

__PACKAGE__->load_components( "InflateColumn::DateTime", "Core" );
__PACKAGE__->table("item");
__PACKAGE__->add_columns(
	"id",
	{
		data_type     => "INT",
		default_value => undef,
		is_nullable   => 0,
		size          => 11
	},
	"title",
	{
		data_type     => "VARCHAR",
		default_value => undef,
		is_nullable   => 1,
		size          => 50,
	},
	"plot",
	{
		data_type     => "VARCHAR",
		default_value => undef,
		is_nullable   => 1,
		size          => 1000,
	},
	"year",
	{
		data_type     => "INT",
		default_value => undef,
		is_nullable   => 1,
		size          => 11
	},
	"release_date",
	{
		data_type     => "VARCHAR",
		default_value => undef,
		is_nullable   => 1,
		size          => 20,
	},
	"uid",
	{
		data_type     => "VARCHAR",
		default_value => undef,
		is_nullable   => 0,
		size          => 20,
	},
	"img",
	{
		data_type     => "VARCHAR",
		default_value => undef,
		is_nullable   => 1,
		size          => 100,
	},
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
	"genre_items",
	"App::Cinema::Schema::Result::GenreItems",
	{ "foreign.i_id" => "self.id" },
);
__PACKAGE__->belongs_to(
	"oneuser",
	"App::Cinema::Schema::Result::Users",
	{ username => "uid" },
);

__PACKAGE__->many_to_many( genres => 'genre_items', 'genre' );

# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-01-29 22:05:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nd641VbtLhAKOkop9QNNGQ

# You can replace this text with custom content, and it will be preserved on regeneration
1;
