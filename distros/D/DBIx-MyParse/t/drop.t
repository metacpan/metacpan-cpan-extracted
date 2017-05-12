# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl drop.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 26;
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

my $drop_database1 = $parser->parse("DROP DATABASE IF EXISTS db_name");
my $drop_database2 = $parser->parse($drop_database1->print());

foreach my $drop_database ($drop_database1, $drop_database2) {
	ok(ref($drop_database) eq $query_class_name, 'drop_database1');
	ok($drop_database->getCommand() eq 'SQLCOM_DROP_DB','drop_database2');
	my $db_item = $drop_database->getSchemaSelect();
	ok(ref($db_item) eq 'DBIx::MyParse::Item', 'drop_database3');
	ok($db_item->getItemType() eq 'DATABASE_ITEM', 'drop_database4');
	ok($db_item->getDatabaseName() eq 'db_name','drop_database5');
	
	ok($drop_database->getOption("DROP_IF_EXISTS"), 'drop_database6');
}


my $drop_table = $parser->parse("
	DROP TEMPORARY TABLE table1, table2
");

ok(ref($drop_table) eq $query_class_name, 'drop_table1');
ok($drop_table->getCommand() eq 'SQLCOM_DROP_TABLE', 'drop_table2');
my $tables = $drop_table->getTables();
ok(ref($tables) eq 'ARRAY', 'drop_table3');
ok(scalar(@{$tables}) == 2, 'drop_table4');
my $table1 = $tables->[0];
my $table2 = $tables->[1];

ok(ref($table1) eq $item_class_name, 'drop_table5');
ok($table1->getType() eq 'TABLE_ITEM', 'drop_table6');
ok($table1->getTableName() eq 'table1', 'drop_table7');

ok(ref($table2) eq $item_class_name, 'drop_table8');
ok($table2->getType() eq 'TABLE_ITEM', 'drop_table9');
ok($table2->getTableName() eq 'table2', 'drop_table10');
