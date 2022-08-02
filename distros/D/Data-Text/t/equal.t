#!perl -wT

use strict;
use warnings;
use Test::Most tests => 11;
use Test::NoWarnings;

BEGIN {
	use_ok('Data::Text');
}

DISTANCE: {
	my $text1a = new_ok('Data::Text' => [
		'text1'
	]);
	my $text1b = new_ok('Data::Text' => [
		'text1'
	]);
	my $text2 = new_ok('Data::Text' => [
		'text2'
	]);

	ok($text1a == $text1b);
	ok($text1a == $text1a);
	ok($text1a != $text2);
	ok($text1a->equal($text1b));
	ok($text2 != $text1b);
	ok($text2->not_equal($text1b));
}
