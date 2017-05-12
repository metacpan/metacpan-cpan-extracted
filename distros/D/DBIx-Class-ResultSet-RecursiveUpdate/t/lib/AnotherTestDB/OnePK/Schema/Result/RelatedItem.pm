package AnotherTestDB::OnePK::Schema::Result::RelatedItem;

use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("relateditem");
__PACKAGE__->add_columns(
		"idcol",
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
		'AnotherTestDB::OnePK::Schema::Result::Item',
		{ idcol => 'item_id'},
		);

__PACKAGE__->has_many(
		"conditionitems",
		"AnotherTestDB::OnePK::Schema::Result::ConditionItem",
		{ "foreign.rel_item_id" => "self.idcol" },
		{ cascade_copy => 0, cascade_delete => 0 },
		);


__PACKAGE__->set_primary_key("idcol");

1;

