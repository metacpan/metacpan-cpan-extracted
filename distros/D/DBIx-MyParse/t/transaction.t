# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl transaction.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 30;
BEGIN {
	use_ok('DBIx::MyParse');
	use_ok('DBIx::MyParse::Query');
	use_ok('DBIx::MyParse::Item')
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $parser = DBIx::MyParse->new();
$parser->setDatabase('test');

ok(ref($parser) eq 'DBIx::MyParse', 'new_parser');

#
# Transaction tests
#

my $begin_query1 = $parser->parse("START TRANSACTION");
ok(ref($begin_query1) eq 'DBIx::MyParse::Query', 'start_transaction1');
my $begin_command1 = $begin_query1->getCommand();
ok($begin_command1 eq 'SQLCOM_BEGIN', 'start_transaction2');

my $begin_query2 = $parser->parse("BEGIN WORK");
ok(ref($begin_query2) eq 'DBIx::MyParse::Query', 'begin_work1');
my $begin_command2 = $begin_query2->getCommand();
ok($begin_command2 eq 'SQLCOM_BEGIN', 'begin_work2');

my $commit_query = $parser->parse("COMMIT");
ok(ref($commit_query) eq 'DBIx::MyParse::Query','commit1');
my $commit_command = $commit_query->getCommand();
ok($commit_command eq 'SQLCOM_COMMIT', 'commit2');

my $rollback_query = $parser->parse("ROLLBACK");
ok(ref($rollback_query) eq 'DBIx::MyParse::Query','rollback1');
my $rollback_command = $rollback_query->getCommand();
ok($rollback_command eq 'SQLCOM_ROLLBACK', 'rollback2');


#my $autocommit_query = $parser->parse("SET AUTOCOMMIT = 1");
#ok(0 == 1, 'autocommit1');

my $savepoint_query = $parser->parse("SAVEPOINT test");
ok(ref($savepoint_query) eq 'DBIx::MyParse::Query','savepoint1');
ok($savepoint_query->getCommand() eq 'SQLCOM_SAVEPOINT', 'savepoint2');
ok($savepoint_query->getSavepoint() eq 'test', 'savepoint3');

my $rollback_savepoint_query = $parser->parse("ROLLBACK TO SAVEPOINT test");
ok(ref($rollback_savepoint_query) eq 'DBIx::MyParse::Query','rollback_savepoint1');
ok($rollback_savepoint_query->getCommand() eq 'SQLCOM_ROLLBACK_TO_SAVEPOINT', 'rollback_savepoint2');
ok($rollback_savepoint_query->getSavepoint() eq 'test', 'rollback_savepoint3');

my $lock_query = $parser->parse("
	LOCK TABLES
	table1 AS alias1 READ,
	table2 READ LOCAL,
	table3 WRITE,
	table4 LOW_PRIORITY WRITE
");

ok(ref($lock_query) eq 'DBIx::MyParse::Query','lock1');
ok($lock_query->getCommand() eq 'SQLCOM_LOCK_TABLES', 'lock2');
my $lock_tables = $lock_query->getTables();
ok(ref($lock_tables) eq 'ARRAY', 'lock3');
my $read_table = $lock_tables->[0];
ok(ref($read_table) eq 'DBIx::MyParse::Item','lock4');
ok($read_table->getType() eq 'TABLE_ITEM','lock5');
ok($read_table->getTableName() eq 'table1','lock6');
ok($read_table->getAlias() eq 'alias1', 'lock7');

my $options = $lock_query->getOptions();
ok($options->[0] =~ m{TL_READ_NO_INSERT|TL_READ_WITH_SHARED_LOCKS}, 'lock8');
ok($options->[1] =~ m{TL_IGNORE|TL_READ}, 'lock9');
ok($options->[2] =~ m{TL_WRITE_DELAYED|TL_WRITE}, 'lock10');
ok($options->[3] =~ m{TL_WRITE_CONCURRENT_INSERT|TL_WRITE_LOW_PRIORITY}, 'lock11');

my $unlock_query = $parser->parse("UNLOCK TABLES");
ok($unlock_query->getCommand() eq 'SQLCOM_UNLOCK_TABLES', 'unlock1');
