# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl placeholders.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 24;
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

my $single_update1 = $parser->parse('UPDATE table1 SET field1 = value1');
my $single_update2 = $parser->parse($single_update1->print());

foreach my $single_update ($single_update1, $single_update2) {
	ok(ref($single_update) eq 'DBIx::MyParse::Query', 'single_update1');
	ok($single_update->getCommand() eq 'SQLCOM_UPDATE', 'single_update2');

	my $fields = $single_update->getUpdateFields();

	ok(ref($fields) eq 'ARRAY', 'single_update3');
	my $field = $fields->[0];
	ok(ref($field) eq 'DBIx::MyParse::Item', 'single_update4');
	ok($field->getType() eq 'FIELD_ITEM', 'single_update5');
	ok($field->getFieldName() eq 'field1', 'single_update6');

	my $values = $single_update->getUpdateValues();
	ok(ref($values) eq 'ARRAY', 'single_update7');
	my $value = $values->[0];
	ok(ref($value) eq 'DBIx::MyParse::Item', 'single_update8');
	ok($value->getType() eq 'FIELD_ITEM', 'single_update9');
	ok($value->getFieldName() eq 'value1', 'single_update10');
}
