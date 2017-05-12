# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl select.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
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

#
# SELECT tests
#

my $on_join = $parser->parse("SELECT * FROM table1 LEFT JOIN table2 ON field1 = field2");

my $using_join = $parser->parse("SELECT * FROM table1 LEFT OUTER JOIN table2 USING (field1)");

my $natural_join = $parser->parse("SELECT * FROM table1 NATURAL JOIN table2");

my $use_index = $parser->parse("SELECT * FROM table1 USE INDEX (index1, index2)");
# IGNORE INDEX (ignore_index) FORCE INDEX (force_index)");







