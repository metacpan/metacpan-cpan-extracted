# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl create.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 16;
BEGIN {
	use_ok('DBIx::MyParse');
	use_ok('DBIx::MyParse::Query');
	use_ok('DBIx::MyParse::Item')
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $parser = DBIx::MyParse->new();

ok(ref($parser) eq 'DBIx::MyParse', 'new_parser');

my $create_database1 = $parser->parse("CREATE DATABASE IF NOT EXISTS db_name");
my $create_database2 = $parser->parse($create_database1->print());

my $query_class_name = 'DBIx::MyParse::Query';
my $item_class_name = 'DBIx::MyParse::Item';
foreach my $create_database ($create_database1, $create_database2) {
	ok(ref($create_database) eq $query_class_name, 'create_database1');
	ok($create_database->getCommand() eq 'SQLCOM_CREATE_DB','create_database2');
	my $db_item = $create_database->getSchemaSelect();
	ok(ref($db_item) eq $item_class_name, 'create_database3');
	ok($db_item->getItemType() eq 'DATABASE_ITEM', 'create_database4');
	ok($db_item->getDatabaseName() eq 'db_name','create_database5');

	ok($create_database->getOption("CREATE_IF_NOT_EXISTS"), 'create_database6');
}
