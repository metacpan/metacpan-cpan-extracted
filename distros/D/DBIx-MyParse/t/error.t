# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MyParse.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
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
# error tests
#

my $error_query = $parser->parse("SELECT FROM WHERE");

ok(ref($error_query) eq 'DBIx::MyParse::Query', 'error_query1');
ok($error_query->getError() eq 'ER_PARSE_ERROR', 'error_query2');
ok($error_query->getErrno() == 1064, 'error_query3');
ok($error_query->getErrstr() =~ m{FROM WHERE}sio, 'error_query3');
