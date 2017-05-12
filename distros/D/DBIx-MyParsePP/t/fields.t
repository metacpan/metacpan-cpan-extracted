use strict;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl fields.t'

#########################

use Test::More tests => 4;

use DBIx::MyParsePP;

my $parser = DBIx::MyParsePP->new();

my $fields_query = $parser->parse("
	SELECT 
		select_field1,
		select_table2.select_field2,
		select_db3.select_table3.select_field3
	FROM from_table1, from_db2.from_table2
	LEFT JOIN from_db3.from_table3 USING (from_field3)
	LEFT JOIN from_table4 ON (from_field4)
	WHERE where_field1 = where_field2
	GROUP BY group_field1
	HAVING having_field1
	ORDER BY order_field1
");

my $fields = $fields_query->getFields();
ok(defined $fields, 'fields1');

my $fields_string = join(' ', map { $_->toString() } @{$fields});
my $test_string = 'select_field1  select_table2 .select_field2  select_db3 .select_table3 .select_field3  from_table1  from_db2 .from_table2  from_db3 .from_table3  from_field3  from_table4  from_field4  where_field1  where_field2  group_field1  having_field1  order_field1 ';
ok(length($fields_string) == length($test_string), 'fields2');

my $tables_query = $parser->parse("
	SELECT
		select_db1.select_table1.*,
		select_table2.*,
		select_db3.select_table3.select_field3,
		select_table4.select_field4
	FROM from_db1.from_table1, from_table2
");

my $tables = $tables_query->getTables();
ok(defined $tables, 'tables1');
my $tables_string = join(' ', map { $_->toString() } @{$tables});
my $tables_orig = 'select_db1 .select_table1  select_table2  select_db3 .select_table3  select_table4  from_table1  from_table2 ';
ok($tables_string eq $tables_orig, 'tables2');
