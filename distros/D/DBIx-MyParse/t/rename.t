# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl rename.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 37;
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

#
# error tests
#

my $rename_simple = $parser->parse("
	RENAME TABLE
	table0 TO table1,
	table2 TO table3,
	table4 TO table5
");

ok(ref($rename_simple) eq $query_class_name, 'rename_simple1');
ok($rename_simple->getCommand() eq 'SQLCOM_RENAME_TABLE', 'rename_simple2');
my $tables = $rename_simple->getTables();
ok(ref($tables) eq 'ARRAY', 'rename_simple3');
ok(scalar(@{$tables}) == 6, 'rename_simple4');

foreach my $i (0..5){
	my $table = $tables->[$i];
	ok(ref($table) eq $item_class_name,'rename_simple5_'.$i);
	ok($table->getType() eq 'TABLE_ITEM','rename_simple6_'.$i);
	ok($table->getTableName() eq 'table'.$i, 'rename_simple7_'.$i);
}

my $rename_complex = $parser->parse("
	RENAME TABLE
	current_db.tbl_name1
	TO other_db.tbl_name2
");

ok(ref($rename_complex) eq $query_class_name, 'rename_complex1');
my $tables_complex = $rename_complex->getTables();
ok(ref($tables_complex) eq 'ARRAY', 'rename_complex2');
ok(scalar(@{$tables_complex}) == 2, 'rename_complex3');

my $table1 = $tables_complex->[0];

ok(ref($table1) eq $item_class_name, 'rename_complex4');
ok($table1->getType() eq 'TABLE_ITEM', 'rename_complex5');
ok($table1->getTableName() eq 'tbl_name1', 'rename_complex6');
ok($table1->getDatabaseName() eq 'current_db', 'rename_complex7');

my $table2 = $tables_complex->[1];
ok(ref($table2) eq $item_class_name, 'rename_complex8');
ok($table2->getType() eq 'TABLE_ITEM', 'rename_complex9');
ok($table2->getTableName() eq 'tbl_name2', 'rename_complex10');
ok($table2->getDatabaseName() eq 'other_db', 'rename_complex11');
