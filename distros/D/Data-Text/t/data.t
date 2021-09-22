#!perl -wT

use strict;
use warnings;
use Test::Most tests => 19;
use Test::Carp;

BEGIN {
	use_ok('Data::Text');
}

DATA: {
	my $d = new_ok('Data::Text');

	$d->append('Hello, world.');

	is($d->as_string(), 'Hello, world.', 'Basic test');

	does_carp_that_matches(
		sub {
			$d->append("\n\t. A new paragraph.\n");
		},
		qr/attempt to add/
	);

	is($d->as_string(), 'Hello, world.', "Didn't add");
	cmp_ok($d->length(), '==', '13', 'Verify length() works');

	does_carp_that_matches(
		sub {
			$d = new_ok('Data::Text');
			$d->append('Hello. ');
			$d->append("\n\t. What is happening?");
		},
		qr/attempt to add/
	);

	does_carp_that_matches(
		sub {
			$d = new_ok('Data::Text');
			$d->append('Hello.');
			$d->append("\n\t. What is happening?");
		},
		qr/attempt to add/
	);

	does_carp_that_matches(
		sub {
			$d = new_ok('Data::Text');
			$d->append('Hello.');
			$d->append("\n\t");
			$d->append('. What is happening?');
		},
		qr/attempt to add/
	);


	$d = new_ok('Data::Text');

	is($d->append(text => ['Bonjour', ' ', 'tout le monde']), $d, 'Supports daisy chaining');
	is($d->as_string(), 'Bonjour tout le monde', 'Supports reference to array of strings');

	is(new_ok('Data::Text')->append(' There are some spaces here.  ')->trim()->as_string(),
		'There are some spaces here.', 'Verify trim() works');

	is(new_ok('Data::Text')->append("\tThe tab stays   ")->rtrim()->as_string(), "\tThe tab stays", 'Verify rtrim works');
}
