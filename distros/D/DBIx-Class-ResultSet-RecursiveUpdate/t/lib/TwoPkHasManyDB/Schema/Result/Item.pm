package TwoPkHasManyDB::Schema::Result::Item;

use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("item");
__PACKAGE__->add_columns(
		"id",
		{ data_type => "INTEGER", is_auto_increment => 1,
		is_nullable => 0 },
		);
__PACKAGE__->set_primary_key("id");


__PACKAGE__->has_many(
		"relateditems",
		"TwoPkHasManyDB::Schema::Result::RelatedItem",
		{ "foreign.item_id" => "self.id" },
		{ cascade_copy => 0, cascade_delete => 0 },
		);

__PACKAGE__->has_many(
		"relateditems2",
		"TwoPkHasManyDB::Schema::Result::RelatedItem2",
		{ "foreign.item_id" => "self.id" },
		{ cascade_copy => 0, cascade_delete => 0 },
		);
1;
