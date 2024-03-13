#!perl -wT

use strict;
use warnings;
use Test::Most tests => 45;
use Test::Carp;

BEGIN {
	use_ok('Data::Text');
}

DATA: {
	my $d = new_ok('Data::Text');

	is($d->as_string(), undef, 'Undef before data has been added');
	cmp_ok($d->length(), '==', '0', 'Verify length() works on new string');
	is($d->set('Hello, world.')->as_string(), 'Hello, world.', 'Basic set test');
	is($d->set({ text => 'Hello, world!' })->as_string(), 'Hello, world!', 'Basic set test giving ref argument');

	$d = new_ok('Data::Text', [text => 'Tulip']);

	cmp_ok($d, 'eq', 'Tulip', 'Initialisation with a string works');

	$d = new_ok('Data::Text', [text => $d]);

	is($d->as_string(), 'Tulip', 'Initialisation with an object works');

	$d = new_ok('Data::Text');

	is($d->append('Hello, world.')->as_string(), 'Hello, world.', 'Basic append test');

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

	does_carp_that_matches(
		sub {
			$d = new_ok('Data::Text', [text => 'Hey, where are you'])->append(', ');
			$d->append(', what is happening?');
		},
		qr/attempt to add/
	);

	does_carp_that_matches(
		sub {
			$d = new_ok('Data::Text');
			$d->append();
		},
		qr/no text given/
	);

	does_carp_that_matches(
		sub {
			$d = new_ok('Data::Text');
			$d->append(text => undef);
		},
		qr/no text given/
	);

	does_carp_that_matches(
		sub {
			$d = new_ok('Data::Text');
			$d->append(text => []);
		},
		qr/no text given/
	);

	does_carp_that_matches(
		sub {
			$d = new_ok('Data::Text');
			$d->set([]);
		},
		qr/no text given/
	);

	does_carp_that_matches(
		sub {
			$d = new_ok('Data::Text');
			$d->append([]);
		},
		qr/no text given/
	);

	does_carp_that_matches(
		sub {
			$d = new_ok('Data::Text');
			$d->set();
		},
		qr/no text given/
	);

	$d = new_ok('Data::Text');

	is($d->append(text => ['Bonjour', new_ok('Data::Text' => [' ']), 'tout le monde']), $d, 'Supports array refs');
	is($d->as_string(), 'Bonjour tout le monde', 'Supports reference to array of strings');

	$d->replace({ 'Bonjour' => 'Au revoir' });
	is($d->as_string(), 'Au revoir tout le monde', 'Verify replace() works');
	$d = new_ok('Data::Text');
	# String::Clean will have an assert failure, ensure that doesn't happen
	$d->replace({ 'Bonjour' => 'Au revoir' });

	is(new_ok('Data::Text')->append(' There are some spaces here.  ')->trim()->as_string(),
		'There are some spaces here.', 'Verify trim() works');

	is(new_ok('Data::Text')->append({ text => "\tThe tab stays   " })->rtrim()->as_string(), "\tThe tab stays", 'Verify rtrim() works');
}
