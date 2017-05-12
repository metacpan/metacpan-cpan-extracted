package AnotherTestDB::OnePK::Schema::Result::ConditionItem;

use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("conditionitem");
__PACKAGE__->add_columns(
		"idcol",
		{ data_type => "INTEGER", is_auto_increment => 1,
		is_nullable => 0 },
		"condition",
		{ data_type => "TEXT", is_nullable => 0 },
		"rel_item_id",
		{
		data_type => "integer",
		is_foreign_key => 1,
		is_nullable => 0,
		},

		);

__PACKAGE__->belongs_to(
	'related_item',
	'AnotherTestDB::OnePK::Schema::Result::RelatedItem',
	{ idcol => 'rel_item_id'},
);

__PACKAGE__->set_primary_key("idcol");

1;

