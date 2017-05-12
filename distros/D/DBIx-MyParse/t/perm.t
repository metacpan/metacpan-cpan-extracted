use strict;
use Data::Dumper;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl perm.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);

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

my $item_class = 'DBIx::MyParse::Item';

my $group_by_absent = [
	'',
	sub {
		ok(!defined $_[0]->getGroup(),'group_by_absent1');
	}
];

my $group_by_present = [
	'GROUP BY group_by_field',
	sub {
		my $group_by = $_[0]->getGroup();
		ok(ref($group_by) eq 'ARRAY' ,'group_by_present1');
		my $group_by_first = $group_by->[0];
		ok(ref($group_by_first) eq $item_class,'group_by_present2');
		ok($group_by_first->getFieldName() eq 'group_by_field','group_by_present3');
	}
];

my $limit_absent = [
	'',
	sub {
		my $limit = $_[0]->getLimit();
		ok(!defined $limit,'limit_absent1');
	}
];

my $limit_present_single = [
	'LIMIT 10',
	sub {
		my $limit = $_[0]->getLimit();
		ok(ref($limit) eq 'ARRAY','limit_present_single1');
		my $row_count = $limit->[0];
		ok(ref($row_count) eq $item_class, 'limit_present_single2');
		ok($row_count->getType() eq 'INT_ITEM','limit_present_single3');
		ok($row_count->getValue() == 10,'limit_present_single4');
		ok(!defined $limit->[1],'limit_present_single5');
	}
];

my $limit_present_double = [
	'LIMIT 20 OFFSET 30',
	sub {
		my $limit = $_[0]->getLimit();
		ok(ref($limit) eq 'ARRAY','limit_present_double1');
		my $row_count = $limit->[0];
		ok(ref($row_count) eq $item_class, 'limit_present_double2');
		ok($row_count->getType() eq 'INT_ITEM','limit_present_double3');
		ok($row_count->getValue() == 20,'limit_present_double4');

		my $offset = $limit->[1];
		ok(ref($offset) eq $item_class, 'limit_present_double4');
		ok($offset->getType() eq 'INT_ITEM','limit_present_double5');
		ok($offset->getValue() == 30,'limit_present_double6');

	}
];

my $from_absent = [
];

my $having_present = [
	'HAVING having_field1 = 1234',
	sub {
		my $having = $_[0]->getHaving();
		ok(ref($having) eq $item_class,'having_present1');
		ok($having->getType() eq 'ITEM_FUNC','having_present2');
	}
];

my @tests = (
	[ $group_by_absent, $group_by_present ],
	[ $limit_absent, $limit_present_single, $limit_present_double ]
);

my @plan;

foreach my $first_test (@{$tests[0]}) {
	foreach my $second_test (@{$tests[1]}) {
		my $new_test = [$first_test, $second_test];
		push @plan, $new_test;
	}
}

foreach my $plan_item (@plan) {
	my $query_text1 = "SELECT * FROM select_table $plan_item->[0]->[0] $plan_item->[1]->[0]";
	my $query_obj1 = $parser->parse($query_text1);
	my $query_text2 = $query_obj1->print();
	my $query_obj2 = $parser->parse($query_text2);
	foreach my $query_obj ($query_obj1, $query_obj2) {
		$plan_item->[0]->[1]($query_obj);
		$plan_item->[1]->[1]($query_obj);
	}
}
