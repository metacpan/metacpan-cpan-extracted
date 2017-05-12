# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl aggregate.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN {
	use_ok('DBIx::MyParse');
	use_ok('DBIx::MyParse::Query');
	use_ok('DBIx::MyParse::Item')
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $parser = DBIx::MyParse->new( datadir => '/dev' );
$parser->setDatabase('null');

ok(ref($parser) eq 'DBIx::MyParse', 'new_parser');

#
# various aggregate functions
#

my $statement = $parser->parse("
	SELECT
		COUNT(DISTINCT count_field),
		non_count_field
	FROM table_name
	GROUP BY non_count_field");

ok(ref($statement) eq 'DBIx::MyParse::Query', 'aggregate1');

my $items = $statement->getSelectItems();
ok(ref($items) eq 'ARRAY', 'aggregate2');

my $count_distinct = $items->[0];
ok(ref($count_distinct) eq 'DBIx::MyParse::Item','aggregate3');
ok($count_distinct->getType() eq 'SUM_FUNC_ITEM', 'aggregate4');
ok($count_distinct->getFuncType() eq 'COUNT_DISTINCT_FUNC', 'aggregate5');

my $arguments = $count_distinct->getArguments();
ok(ref($arguments) eq 'ARRAY', 'aggregate6');
my $argument = $arguments->[0];
ok(ref($argument) eq 'DBIx::MyParse::Item','aggregate6');
ok($argument->getType() eq 'FIELD_ITEM', 'aggregate7');
ok($argument->getFieldName() eq 'count_field','aggregate8');
