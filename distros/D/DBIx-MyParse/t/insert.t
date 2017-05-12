# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl insert.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 124;
BEGIN {
	use_ok('DBIx::MyParse');
	use_ok('DBIx::MyParse::Query');
	use_ok('DBIx::MyParse::Item')
};

use strict;

my $parser = DBIx::MyParse->new();
$parser->setDatabase('test');

ok(ref($parser) eq 'DBIx::MyParse', 'new_parser');

#
# INSERT and REPLACE tests
#


foreach my $verb ('INSERT','REPLACE') {
	my $insert_query1 = $parser->parse("
		$verb INTO database_name.table_name (field_name) VALUES ('value1')
	");
	my $insert_query2 = $parser->parse($insert_query1->print());

	foreach my $insert_query ($insert_query1, $insert_query2) {
		ok(ref($insert_query) eq 'DBIx::MyParse::Query', 'new_insert');
		ok($insert_query->getCommand() eq 'SQLCOM_'.$verb, 'new_insert1');

		my $tables = $insert_query->getTables();
		ok(ref($tables) eq 'ARRAY', 'insert_tables1');
		ok(scalar(@{$tables}) == 1, 'insert_tables2');
		my $table = $tables->[0];
		ok(ref($table) eq 'DBIx::MyParse::Item', 'insert_table1');
		ok($table->getType() eq 'TABLE_ITEM', 'insert_table2');
		ok($table->getDatabaseName() eq 'database_name', 'insert_table3');
		ok($table->getTableName() eq 'table_name', 'insert_table4');
	
		my $fields = $insert_query->getInsertFields();
		ok(ref($fields) eq 'ARRAY', 'insert_fields1');
		ok(scalar(@{$fields}) == 1, 'insert_fields2');
	
		my $field = $fields->[0];
		ok(ref($field) eq 'DBIx::MyParse::Item', 'insert_field1');
		ok($field->getType() eq 'FIELD_ITEM', 'insert_field2');
		ok($field->getFieldName() eq 'field_name', 'insert_field3');

		my $all_values = $insert_query->getInsertValues();
		ok(ref($all_values) eq 'ARRAY', 'insert_all_values1');

		my $values = $all_values->[0];
		ok(ref($values) eq 'ARRAY', 'insert_values1');

		my $value = $values->[0];
		ok(ref($value) eq 'DBIx::MyParse::Item', 'insert_value1');
		ok($value->getType() eq 'STRING_ITEM', 'insert_value2');
		ok($value->getValue() eq 'value1', 'insert_value3');
	}

	#
	# Multiple-row INSERT/REPLACE
	#

	my $multiple_insert_query1 = $parser->parse("
		$verb INTO database_name.table_name (field_name) VALUES ('value1'),('value2')
	");

	my $multiple_insert_query2 = $parser->parse($multiple_insert_query1->print());

	foreach my $multiple_insert_query ($multiple_insert_query1, $multiple_insert_query2) {
		ok($multiple_insert_query->getCommand() eq 'SQLCOM_'.$verb, 'insert_multiple1');
		my $multiple_all_values = $multiple_insert_query->getInsertValues();
		my $second_row = $multiple_all_values->[1];
		my $second_value = $second_row->[0];
		ok($second_value->getValue() eq 'value2', 'insert_multiple2');
	}

	#
	# Alternative-syntax INSERT/REPLACE
	#

	my $alternative_insert_query1 = $parser->parse("
		$verb INTO table_name SET field_name = 'value1'
	");
	
	my $alternative_insert_query2 = $parser->parse($alternative_insert_query1->print());

	foreach my $alternative_insert_query ($alternative_insert_query1, $alternative_insert_query2) {
	
		my $alternative_all_values = $alternative_insert_query->getInsertValues();
		my $first_row = $alternative_all_values->[0];
		my $first_value = $first_row->[0];
		ok($first_value->getValue() eq 'value1', 'insert_alternative1');

		my $alternative_fields = $alternative_insert_query->getInsertFields();
		my $first_field = $alternative_fields->[0];
		ok($first_field->getFieldName() eq 'field_name', 'insert_alternative1');
	}


	#
	# INSERT/REPLACE ... SELECT ... construction
	#

	my $insert_select1 = $parser->parse("
		$verb INTO first_table SELECT field_name FROM second_table
	");

	my $insert_select2 = $parser->parse($insert_select1->print());

	foreach my $insert_select ($insert_select1, $insert_select2) {
		ok(ref($insert_select) eq 'DBIx::MyParse::Query', 'select_insert1');
		ok($insert_select->getCommand() eq 'SQLCOM_'.$verb.'_SELECT', 'select_insert2');

		my $multiple_tables = $insert_select->getTables();
		my $insert_table = $multiple_tables->[0];
		my $select_table = $multiple_tables->[1];
	
		ok(ref($insert_table) eq 'DBIx::MyParse::Item', 'select_insert3');
		ok(ref($select_table) eq 'DBIx::MyParse::Item', 'select_insert4');
		ok($insert_table->getTableName() eq 'first_table', 'select_insert5');
		ok($select_table->getTableName() eq 'second_table', 'select_insert6');
	}
}

#
# ON DUPLICATE KEY UPDATE 
#

my $duplicate_query1 = $parser->parse("
	INSERT INTO table_name VALUES (1) ON DUPLICATE KEY UPDATE field = 'value'
");

my $duplicate_query2 = $parser->parse($duplicate_query1->print());

foreach my $duplicate_query ($duplicate_query1, $duplicate_query2) {
	ok(ref($duplicate_query) eq 'DBIx::MyParse::Query', 'duplicate_insert1');
	ok($duplicate_query->getCommand() eq 'SQLCOM_INSERT', 'duplicate_insert2');
	
	my $update_fields = $duplicate_query->getUpdateFields();
	my $update_values = $duplicate_query->getUpdateValues();

	ok($update_fields->[0]->getFieldName() eq 'field', 'duplicate_insert2');
	ok($update_values->[0]->getValue() eq 'value', 'duplicate_insert3');
}

