# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl items.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 74;
BEGIN {
	use_ok('DBIx::MyParse');
	use_ok('DBIx::MyParse::Query');
	use_ok('DBIx::MyParse::Item')
};

my $query_class_name = 'DBIx::MyParse::Query';
my $item_class_name = 'DBIx::MyParse::Item';
my $parser_class_name = 'DBIx::MyParse';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $parser = DBIx::MyParse->new();
$parser->setDatabase('test');

ok(ref($parser) eq $parser_class_name, 'new_parser');

my $select1 = $parser->parse("SELECT LEFT(field, 6) = 'string' AS alias");
my $expr1 = $select1->getSelectItems()->[0];
my $select2 = $parser->parse($select1->print());
my $expr2 = $select2->getSelectItems()->[0];

my $int_item3 = DBIx::MyParse::Item->new(
	item_type => 'INT_ITEM',
	value => 6
);

my $int_item4 = DBIx::MyParse::Item->new();
$int_item4->setType('INT_ITEM');
$int_item4->setValue(6);

my $field_item3 = DBIx::MyParse::Item->new(
	item_type => 'FIELD_ITEM',
	field_name => 'field'
);
my $field_item4 = DBIx::MyParse::Item->new();
$field_item4->setType('FIELD_ITEM');
$field_item4->setFieldName('field');

my $string_item3 = DBIx::MyParse::Item->new(
	item_type => 'STRING_ITEM',
	value => 'string'
);

my $string_item4 = DBIx::MyParse::Item->new();
$string_item4->setType('STRING_ITEM');
$string_item4->setValue('string');

my $func_item3 = DBIx::MyParse::Item->new(
	item_type => 'FUNC_ITEM',
	func_type => 'UNKNOWN_FUNC',
	func_name => 'left',
	arguments => [$field_item3, $int_item3]
);

my $func_item4 = DBIx::MyParse::Item->new();
$func_item4->setType('FUNC_ITEM');
$func_item4->setFuncType('UNKNOWN_FUNC');
$func_item4->setFuncName('left');
$func_item4->setArguments([ $field_item4, $int_item4 ]);

my $eq_item3 = DBIx::MyParse::Item->new(
	item_type => 'FUNC_ITEM',
	func_type => 'EQ_FUNC',
	func_name => '=',
	alias => 'alias',
	arguments => [$func_item3, $string_item3]
);

my $eq_item4 = DBIx::MyParse::Item->new();
$eq_item4->setType('FUNC_ITEM');
$eq_item4->setFuncType('EQ_FUNC');
$eq_item4->setFuncName('=');
$eq_item4->setAlias('alias');
$eq_item4->setArguments([$func_item4, $string_item4]);


my $eq_item5 = DBIx::MyParse::Item->newEq(
	DBIx::MyParse::Item->new(
		item_type => 'FUNC_ITEM', func_type => 'UNKNOWN_FUNC', func_name => 'left',
		arguments => [
			DBIx::MyParse::Item->newField('field'),
			DBIx::MyParse::Item->newInt(6)
		]
	),		
	DBIx::MyParse::Item->newString('string')
);
$eq_item5->setAlias('alias');

my $select3 = $parser->parse("SELECT ".$eq_item3->print(1));
my $expr3 = $select3->getSelectItems()->[0];

my $select4 = $parser->parse("SELECT ".$eq_item4->print(1));
my $expr4 = $select4->getSelectItems()->[0];

my $select5 = $parser->parse("SELECT ".$eq_item5->print(1));
my $expr5 = $select5->getSelectItems()->[0];

foreach my $expr ($expr1, $expr2, $expr3, $expr4, $expr5) {
	ok(ref($expr) eq 'DBIx::MyParse::Item', 'eq_item1');
	ok($expr->getAlias() eq 'alias', 'eq_item2');
	ok($expr->getType() eq 'FUNC_ITEM', 'eq_item3');
	ok($expr->getFuncType() eq 'EQ_FUNC', 'eq_item4');
	ok($expr->getFuncName() eq '=', 'eq_item5');

	my ($func_item, $string_item) = @{$expr->getArguments()};

	ok($func_item->getType() eq 'FUNC_ITEM', 'func_item1');
	ok($func_item->getFuncType() eq 'UNKNOWN_FUNC', 'func_item2');
	ok($func_item->getFuncName() eq 'left', 'func_item3');

	ok($string_item->getType() eq 'STRING_ITEM', 'string_item1');
	ok($string_item->getValue() eq 'string', 'string_item2');

	my ($field_item, $int_item) = @{$func_item->getArguments()};

	ok($field_item->getType() eq 'FIELD_ITEM', 'field_item1');
	ok($field_item->getFieldName() eq 'field', 'field_item2');

	ok ($int_item->getType() eq 'INT_ITEM' ,'int_item1');
	ok ($int_item->getValue() == 6, 'int_item2');

}


