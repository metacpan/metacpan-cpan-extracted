# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl twins.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 28;
BEGIN {
	use_ok('DBIx::MyParse');
	use_ok('DBIx::MyParse::Query');
	use_ok('DBIx::MyParse::Item')
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
my $parser = DBIx::MyParse->new();
$parser->setDatabase('test');

ok(ref($parser) eq 'DBIx::MyParse', 'new_parser');

my $describe = $parser->parse("DESCRIBE test.table1 column1");
ok($describe->getCommand() eq 'SQLCOM_SELECT', 'describe1');
ok($describe->getOrigCommand() eq 'SQLCOM_SHOW_FIELDS', 'describe2');

my $select_items = $describe->getSelectItems();
ok($select_items->[0]->getType() eq 'FIELD_ITEM','describe3');
ok($select_items->[0]->getFieldName() eq 'COLUMN_NAME','describe4');
ok($select_items->[5]->getFieldName() eq 'EXTRA','describe5');

my $schema_select = $describe->getSchemaSelect();
ok($schema_select->getType() eq 'TABLE_ITEM','describe6');
ok($schema_select->getDatabaseName() eq 'test', 'describe7');
ok($schema_select->getTableName() eq 'table1', 'describe8');

ok ($describe->getWild() eq 'column1','describe9');

# =================================================================

my $show_tables = $parser->parse("SHOW TABLES FROM database2 LIKE 'name2'");
ok($show_tables->getCommand() eq 'SQLCOM_SELECT', 'show_tables1');	
ok($show_tables->getOrigCommand() eq 'SQLCOM_SHOW_TABLES', 'show_tables2');

my $tables2 = $show_tables->getSchemaSelect();
ok($tables2->getDatabaseName() eq 'database2', 'show_tables3');
ok($show_tables->getWild() eq 'name2', 'show_tables4');

my $schema_select2 = $show_tables->getSchemaSelect();
ok($schema_select2->getType() eq 'DATABASE_ITEM','show_tables5');
ok($schema_select2->getDatabaseName() eq 'database2','show_tables6');

# ================================================================

my $show_table_status = $parser->parse("SHOW TABLE STATUS FROM mysql LIKE 'user'");
ok($show_table_status->getOrigCommand() eq 'SQLCOM_SHOW_TABLE_STATUS','show_table_status1');

my $schema_select3 = $show_table_status->getSchemaSelect();
ok($schema_select3->getType() eq 'DATABASE_ITEM','show_table_status2');
ok($schema_select3->getDatabaseName() eq 'mysql','show_table_status3');

ok($show_table_status->getWild() eq 'user','show_table_status4');

# ================================================================

my $show_databases = $parser->parse("SHOW DATABASES LIKE 'mysql'");
ok($show_databases->getOrigCommand() eq 'SQLCOM_SHOW_DATABASES','show_databases1');
ok($show_databases->getWild() eq 'mysql','show_databases2');

# ================================================================

my $use = $parser->parse("USE mysql");
ok($use->getCommand() eq 'SQLCOM_CHANGE_DB','use1');
my $schema_select4 = $use->getSchemaSelect();
ok($schema_select4->getType() eq 'DATABASE_ITEM','use2');
ok($schema_select4->getDatabaseName() eq 'mysql','use3');
