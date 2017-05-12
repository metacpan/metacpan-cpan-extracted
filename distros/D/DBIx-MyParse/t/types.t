# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl types.t'

#########################

use Test::More tests => 110;

my $item_package = 'DBIx::MyParse::Item';

BEGIN {
	use_ok('DBIx::MyParse');
	use_ok('DBIx::MyParse::Query');
	use_ok('DBIx::MyParse::Item')
};

my $parser = DBIx::MyParse->new();
ok(ref($parser) eq 'DBIx::MyParse', 'new_parser');

my $types_sql = '
	SELECT
		*,
		database1.table1.field1,
		ABS(2),
		SUM(sum_field),
		"string\'\"\0",
		1234,
		NULL,
		?,
		3.14,
		3456 AND "string2",
		0x4D7953514C00,
		1.1e+1,
		INTERVAL(1,2,3,4),
		TRUE,
		(SELECT 1)
';

my $types1 = $parser->parse($types_sql);
my $types2 = $parser->parse($types1->print());

foreach my $types ($types1, $types2) {
	my $select_items = $types->getSelectItems();
	ok(ref($select_items) eq 'ARRAY','types1');

	my $all_item = $select_items->[0];
	ok(ref($all_item) eq $item_package, 'all_item1');
	ok($all_item->getType() eq 'FIELD_ITEM','all_item2');
	ok($all_item->getFieldName() eq '*', 'all_item3');

	my $field_item = $select_items->[1];
	ok(ref($field_item) eq $item_package,'field_item1');

	ok($field_item->getType() eq 'FIELD_ITEM','field_item2');
	ok($field_item->getDatabaseName() eq 'database1','field_item3');
	ok($field_item->getTableName() eq 'table1','field_item4');
	ok($field_item->getFieldName() eq 'field1','field_item5');

	my $func_item = $select_items->[2];
	ok(ref($func_item) eq $item_package,'func_item1');
	ok($func_item->getType() eq 'FUNC_ITEM','func_item2');
	my $func_args = $func_item->getArguments();
	ok(ref($func_args) eq 'ARRAY','func_item3');
	my $func_arg = $func_args->[0];
	ok(ref($func_arg) eq $item_package, 'func_item4');
	ok($func_arg->getType() eq 'INT_ITEM','func_item5');
	ok($func_arg->getValue() == 2,'func_item6');

	my $sum_item = $select_items->[3];
	ok(ref($sum_item) eq $item_package, 'sum_func1');
	ok($sum_item->getType() eq 'SUM_FUNC_ITEM','sum_func2');
	my $sum_args = $sum_item->getArguments();
	ok(ref($sum_args) eq 'ARRAY','sum_func3');
	my $sum_arg = $sum_args->[0];
	ok(ref($sum_arg) eq $item_package,'sum_func4');
	ok($sum_arg->getType() eq 'FIELD_ITEM','sum_func5');
	ok($sum_arg->getFieldName() eq 'sum_field','sum_func6');

	my $string_item = $select_items->[4];
	ok($string_item->getType() eq 'STRING_ITEM','string_item1');
	ok($string_item->getValue() eq "string'\"\0",'string_item2');
	
	my $int_item = $select_items->[5];
	ok($int_item->getType() eq 'INT_ITEM','int_item1');
	ok($int_item->getValue() == 1234, 'int_item2');

	my $null_item = $select_items->[6];
	ok(ref($null_item) eq $item_package,'null_item1');
	ok($null_item->getType() eq 'NULL_ITEM','null_item2');
	ok(!defined($null_item->getValue()),'null_item3');

	my $param_item = $select_items->[7];
	ok($param_item->getType() eq 'PARAM_ITEM','param_item1');

	my $decimal_item = $select_items->[8];
	ok($decimal_item->getType() eq 'DECIMAL_ITEM','decimal_item1');
	ok($decimal_item->getValue() == 3.14,'decimal_item2');	

	my $cond_item = $select_items->[9];
	ok($cond_item->getType() eq 'COND_ITEM','cond_item1');
	ok($cond_item->getFuncType() eq 'COND_AND_FUNC','cond_item2');
	ok($cond_item->getFuncName() eq 'and', 'cond_item3');
	my $cond_args = $cond_item->getArguments();
	ok(ref($cond_args) eq 'ARRAY','cond_item4');
	my $cond_arg1 = $cond_args->[0];
	ok(ref($cond_arg1) eq $item_package,'cond_item5');
	ok($cond_arg1->getType() eq 'INT_ITEM','cond_item6');
	ok($cond_arg1->getValue() == 3456,'cond_item7');
	my $cond_arg2 = $cond_args->[1];
	ok(ref($cond_arg2) eq $item_package,'cond_item8');
	ok($cond_arg2->getType() eq 'STRING_ITEM','cond_item9');
	ok($cond_arg2->getValue() eq 'string2','cond_item10');

	my $varbin_item = $select_items->[10];
	ok($varbin_item->getType() eq 'VARBIN_ITEM','varbin_item1');
	ok($varbin_item->getValue() eq "MySQL\0",'varbin_item2');	

	my $real_item = $select_items->[11];
	ok($real_item->getType() eq 'REAL_ITEM','real_item1');
	ok($real_item->getValue() == 11,'real_item2');

	my $row_item = $select_items->[12];
	my $row_arguments = $row_item->getArguments();
	my $row_argument = $row_arguments->[0];
	ok(ref($row_argument) eq 'DBIx::MyParse::Item','row_item1');
	ok($row_argument->getType() eq 'ROW_ITEM','row_item2');
	ok(scalar(@{$row_argument->getArguments()}) == 4, 'row_item3');

	my $true_item = $select_items->[13];
	ok($true_item->getType() eq 'INT_ITEM','true_item1');
	ok($true_item->getValue() == 1, 'true_item2');

	my $subselect_item = $select_items->[14];
	ok ($subselect_item->getType() eq 'SUBSELECT_ITEM', 'subselect_item1');
	ok ($subselect_item->getSubselectType() eq 'SINGLEROW_SUBS','subselect_item2');
	ok (ref($subselect_item->getSubselectQuery()) eq 'DBIx::MyParse::Query','subselect_item3');
}
