# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl params.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
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

my $params_query = $parser->parse('INSERT INTO table1 VALUES (?)');

ok(ref($params_query) eq 'DBIx::MyParse::Query', 'params_query1');

my $insert_rows = $params_query->getInsertValues();
ok(ref($insert_rows) eq 'ARRAY', 'params_query2');

my $insert_row = $insert_rows->[0];
ok(ref($insert_row) eq 'ARRAY', 'params_query3');

my $insert_value = $insert_row->[0];
ok(ref($insert_value) eq 'DBIx::MyParse::Item','params_query4');
ok($insert_value->getType() eq 'PARAM_ITEM', 'params_query5');
