package TwoPkHasManyDB::Schema::Result::RelatedItem;

use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("relateditem");
__PACKAGE__->add_columns(
		"id",
		{ data_type => "INTEGER", is_auto_increment => 1,
		is_nullable => 0 },
		"item_id",
		{
		data_type => "integer",
		is_foreign_key => 1,
		is_nullable => 0,
		},

		);


__PACKAGE__->belongs_to(
		'item',
		'TwoPkHasManyDB::Schema::Result::Item',
		{ id => 'item_id'},
		);

__PACKAGE__->set_primary_key("id", "item_id");

1;

