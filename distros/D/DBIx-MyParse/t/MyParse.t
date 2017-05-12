# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MyParse.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 34;
BEGIN {
	use_ok('DBIx::MyParse');
	use_ok('DBIx::MyParse::Query');
	use_ok('DBIx::MyParse::Item')
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $parser = DBIx::MyParse->new(db => 'test');

ok(ref($parser) eq 'DBIx::MyParse', 'new_parser');

#
# SELECT tests
#

my $select_query = $parser->parse("
	SELECT field_name
	FROM table_name
	WHERE where_condition
	GROUP BY group_by
	HAVING having_condition
	ORDER BY order_spec
	LIMIT 1234,2345
");

ok(ref($select_query) eq 'DBIx::MyParse::Query', 'new_select');

my $select_items = $select_query->getSelectItems();

ok(ref($select_items) eq 'ARRAY', 'select_items1');
ok(scalar(@{$select_items}) == 1, 'select_items2');

my $select_item = $select_items->[0];

ok(ref($select_item) eq 'DBIx::MyParse::Item', 'select_item1');
ok($select_item->getType() eq 'FIELD_ITEM', 'select_item2');
ok($select_item->getFieldName() eq 'field_name', 'select_item3');


my $tables = $select_query->getTables();
ok(ref($tables) eq 'ARRAY', 'select_tables1');
my $table = $tables->[0];
ok(ref($table) eq 'DBIx::MyParse::Item', 'select_tables2');
ok($table->getTableName() eq 'table_name', 'select_table3');

my $where = $select_query->getWhere();

ok(ref($where) eq 'DBIx::MyParse::Item', 'select_where1');
ok($where->getType() eq 'FIELD_ITEM', 'select_where2');
ok($where->getFieldName() eq 'where_condition', 'select_where3');

my $groups = $select_query->getGroup();
ok(ref($groups) eq 'ARRAY', 'select_groups1');
ok(scalar(@{$groups}) == 1, 'select_groups2');
my $group = $groups->[0];
ok(ref($group) eq 'DBIx::MyParse::Item', 'select_group1');
ok($group->getType() eq 'FIELD_ITEM', 'select_group2');
ok($group->getFieldName() eq 'group_by','select_group3');

my $having = $select_query->getHaving();
ok(ref($having) eq 'DBIx::MyParse::Item', 'select_having1');
ok($having->getType() eq 'REF_ITEM', 'select_having2');
ok($having->getFieldName() eq 'having_condition','select_having3');

my $orders = $select_query->getOrder();
ok(ref($orders) eq 'ARRAY', 'select_orders1');
ok(scalar(@{$orders}) == 1, 'select_orders2');

my $order = $orders->[0];
ok(ref($order) eq 'DBIx::MyParse::Item', 'select_order1');
ok($order->getType() eq 'FIELD_ITEM', 'select_order2');
ok($order->getFieldName() eq 'order_spec', 'select_order3');

my $limit = $select_query->getLimit();
ok(ref($limit) eq 'ARRAY', 'select_limit1');

my $limit1 = $limit->[0];
my $limit2 = $limit->[1];

ok(ref($limit1) eq 'DBIx::MyParse::Item', 'select_limit2');
ok(ref($limit2) eq 'DBIx::MyParse::Item', 'select_limit3');
ok($limit2->getValue() == 1234, 'select_limit4');
ok($limit1->getValue() == 2345, 'select_limit4');
