#!/usr/bin/perl -w

use Test::More tests => 3;

SKIP: {
	skip "Didn't find item", 2 unless $item;
	is($item->status,'Available',"We can ship it!");
	cmp_ok($item->cost,'==',1.95,'Everything is 1.95');
}

TODO: {
	local $TODO = 'Implement cost_cdn';
	cmp_ok(cost_cdn(1.95),'==',2.39,'Everything in Canada is 2.39');
}
sub cost_cdn {};
