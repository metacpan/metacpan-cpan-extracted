#!perl -wT

use strict;
use warnings;
use Test::Most tests => 58;
use Test::Carp;

BEGIN {
	delete $ENV{'LANG'};
	delete $ENV{'LC_ALL'};

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

	does_croak_that_matches(
		sub {
			$d = new_ok('Data::Text');
			$d->append();
		},
		qr/Usage:\s/
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

	does_croak_that_matches(
		sub {
			$d = new_ok('Data::Text');
			$d->set([]);
		},
		qr/Usage:\s/
	);

	does_croak_that_matches(
		sub {
			$d = new_ok('Data::Text');
			$d->append([]);
		},
		qr/Usage:\s/
	);

	does_croak_that_matches(
		sub {
			$d = new_ok('Data::Text');
			$d->set();
		},
		qr/Usage:\s/
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

	# Test Data::Text->new()
	my $obj1 = Data::Text->new('Hello');
	is($obj1->as_string(), 'Hello', 'new() initializes correctly with string');

	my $obj2 = Data::Text->new(['Hello', 'World']);
	is($obj2->as_string(), 'HelloWorld', 'new() initializes correctly with array reference');

	# Test set()
	$obj1->set('World');
	is($obj1->as_string(), 'World', 'set() updates string correctly');

	$obj1->set(['New', 'String']);
	is($obj1->as_string(), 'NewString', 'set() updates with array reference correctly');

	# Test append()
	$obj1->append(' Again');
	is($obj1->as_string(), 'NewString Again', 'append() works with string');

	$obj1->append(['!']);
	is($obj1->as_string(), 'NewString Again!', 'append() works with array reference');

	# Test equal and not_equal
	my $obj3 = Data::Text->new('Test');
	my $obj4 = Data::Text->new('Test');
	my $obj5 = Data::Text->new('Different');

	ok($obj3 == $obj4, '== operator works for equal objects');
	ok($obj3 != $obj5, '!= operator works for different objects');

	# Test length()
	is($obj3->length, 4, 'length() returns correct length');

	# Test trim() and rtrim()
	$obj1->set('   Trim me   ');
	$obj1->trim();
	is($obj1->as_string(), 'Trim me', 'trim() removes leading and trailing spaces');

	$obj1->set('Trim trailing   ');
	$obj1->rtrim();
	is($obj1->as_string(), 'Trim trailing', 'rtrim() removes trailing spaces');

	# Test replace()
	$obj1->set('Hello World');
	$obj1->replace({ 'World' => 'Universe' });
	is($obj1->as_string(), 'Hello Universe', 'replace() works correctly');

	# Test appendconjunction()
	$obj1->set('')->appendconjunction('Apple', 'Banana', 'Cherry');
	is($obj1->as_string(), 'Apple, Banana, and Cherry', 'appendconjunction() works correctly');
}
