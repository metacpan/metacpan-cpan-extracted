# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl subquery.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
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

my $subselect_string = "SELECT field1 FROM table1 WHERE cond1";

ok(ref($parser) eq 'DBIx::MyParse', 'new_parser');

my $select_subs1 = $parser->parse("SELECT (".$subselect_string.")");
my $select_subs2 = $parser->parse($select_subs1->print());

foreach my $select_subs ($select_subs1, $select_subs2) {
	ok($select_subs->getCommand() eq 'SQLCOM_SELECT', 'select_subs1');
}

my $from_subs1 = $parser->parse("SELECT field1 FROM (".$subselect_string.") AS derived1");
my $from_subs2 = $parser->parse($from_subs1->print());

foreach my $from_subs ($from_subs1, $from_subs2) {
	ok($from_subs->getCommand() eq 'SQLCOM_SELECT', 'from_subs1');
}
	
my $in_subs1 = $parser->parse("SELECT field2 FROM table2 WHERE field3 IN (".$subselect_string.")");
my $in_subs2 = $parser->parse($in_subs1->print());

foreach my $in_subs( $in_subs1, $in_subs2) {
	ok($in_subs->getCommand() eq 'SQLCOM_SELECT', 'in_subs1');
}

my $exists_subs1 = $parser->parse("SELECT field2 FROM table2 WHERE EXISTS (".$subselect_string.")");
my $exists_subs2 = $parser->parse($exists_subs1->print());

foreach my $exists_subs ($exists_subs1, $exists_subs2) {
	ok($exists_subs->getCommand() eq 'SQLCOM_SELECT', 'exists_subs1');
}


