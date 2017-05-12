package AnotherTestDB::OnePK::Schema::Result::Item;

use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("item");
__PACKAGE__->add_columns(
		"idcol",
		{ data_type => "INTEGER", is_auto_increment => 1,
		is_nullable => 0 },
		);
__PACKAGE__->set_primary_key("idcol");


__PACKAGE__->has_many(
		"relateditems",
		"AnotherTestDB::OnePK::Schema::Result::RelatedItem",
		{ "foreign.item_id" => "self.idcol" },
		{ cascade_copy => 0, cascade_delete => 0 },
		);

__PACKAGE__->has_many(
		"true_relateditems",
		"AnotherTestDB::OnePK::Schema::Result::RelatedItem",
		{ "foreign.item_id" => "self.idcol" },
		{where => { 'conditionitems.condition' => 'true'},
		'join' => qq/conditionitems/,
		 cascade_copy => 0, cascade_delete => 0 },
		);
1;
