#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Clutter;
use Champlain;

exit tests();

sub tests {

	if (! Champlain::HAS_MEMPHIS) {
		plan skip_all => "No support for memphis";
		return 0;
	}
	plan tests => 9;
	
	Clutter->init();

	my $box = Champlain::BoundingBox->new();
	isa_ok($box, 'Champlain::BoundingBox');


	$box->left(10);
	is($box->left, 10, "left");

	$box->bottom(20);
	is($box->bottom, 20, "bottom");

	$box->right(30);
	is($box->right, 30, "right");

	$box->top(40);
	is($box->top, 40, "top");

	is_deeply(
		[ $box->get_center ],
		[ ($box->right + $box->left)/2, ($box->top + $box->bottom)/2 ],
		"get_center"
	);

	my $copy = $box->copy;
	isa_ok($copy, 'Champlain::BoundingBox');

	$copy->right(100);
	is($copy->right, 100, "copy changed");
	is($box->right, 30, "original unchanged");

	return 0;
}
