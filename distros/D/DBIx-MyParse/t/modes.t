# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl modes.t'

#########################

use strict;
use warnings;

use Test::More tests => 6;

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

my $concat_parser = DBIx::MyParse->new(
	sql_modes => 'PIPES_AS_CONCAT',
	db => 'test'
);
ok(ref($concat_parser) eq $parser_class_name, 'concat1');

my $concat_query = $concat_parser->parse("SELECT 'a' || 'b'");
my $concat_item = $concat_query->getSelectItems()->[0];
ok($concat_item->getItemType() eq 'FUNC_ITEM', 'concat2');
ok($concat_item->getFuncName() eq 'concat', 'concat2');
