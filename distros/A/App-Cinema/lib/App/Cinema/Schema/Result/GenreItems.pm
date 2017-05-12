package App::Cinema::Schema::Result::GenreItems;

use Moose;
use namespace::autoclean;

BEGIN {
	extends 'DBIx::Class';
	our $VERSION = $App::Cinema::VERSION;
}

__PACKAGE__->load_components( "InflateColumn::DateTime", "Core" );
__PACKAGE__->table("genre_items");
__PACKAGE__->add_columns(
	"g_id",
	{ data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
	"i_id",
	{ data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key( "g_id", "i_id" );
__PACKAGE__->belongs_to(
	"item",
	"App::Cinema::Schema::Result::Item",
	{ id => "i_id" }
);
__PACKAGE__->belongs_to(
	"genre",
	"App::Cinema::Schema::Result::Genre",
	{ id => "g_id" }
);

# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-01-29 22:05:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:06gSe4qEMFxHExvH6YUXJA

# You can replace this text with custom content, and it will be preserved on regeneration
1;
