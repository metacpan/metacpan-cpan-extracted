use Test::More;

use strict;
use warnings;

use lib 't/lib';

BEGIN {
	eval 'use DBD::SQLite 1.0 ()';
	plan skip_all => "DBD::SQLite required to run this test" if $@;

	plan tests => 18;

	use_ok("Test::CDBI::Variant");
}

Test::CDBI::Variant::get_pristene_db;

{
	my $attr = Music::Album::Attribute->retrieve('1');

	cmp_ok($attr, 'eq', '1', "correct stringification");
	cmp_ok($attr->attribute, 'eq','size', "proper attribute");
	isa_ok($attr->attr_value, 'Music::Album::Edge');
	cmp_ok($attr->attr_value->value, '==', 16, "proper edge size from size");
}

{
	my $attr = Music::Album::Attribute->retrieve(2);
	cmp_ok($attr, 'eq', '2', "correct stringification");
	cmp_ok($attr->attribute, 'eq','area', "proper attribute");
	isa_ok($attr->attr_value, 'Music::Album::Edge');
	cmp_ok($attr->attr_value->value, '==', 4, "proper edge size from area");
}

{
	my $attr = Music::Album::Attribute->retrieve(3);
	cmp_ok($attr, 'eq', '3', "correct stringification");
	cmp_ok($attr->attribute, 'eq','start_end', "proper attribute");
	isa_ok($attr->attr_value, 'Music::Album::StartEnd');
	cmp_ok($attr->attr_value->start, '==',   1, "correct start");
	cmp_ok($attr->attr_value->end,   '==', 100, "correct end");
}

{
	my $attr = Music::Album::Attribute->find_or_create(
		{ albumattrid => 4, attribute => 'area', attr_value => 25 }
	);

	cmp_ok($attr, 'eq', '4', "correct stringification");
	cmp_ok($attr->attribute, 'eq','area', "proper attribute");
	isa_ok($attr->attr_value, 'Music::Album::Edge');
	cmp_ok($attr->attr_value->value, '==', 5, "proper edge size");
}
