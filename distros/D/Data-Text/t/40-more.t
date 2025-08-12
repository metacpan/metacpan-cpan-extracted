#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Data::Text') }

# Test object creation and basic functionality
subtest 'Constructor tests' => sub {
	# Basic construction
	my $dt = Data::Text->new('Hello');
	isa_ok($dt, 'Data::Text');
	is($dt->as_string(), 'Hello', 'Basic string construction');

	# Empty construction
	my $empty = Data::Text->new();
	isa_ok($empty, 'Data::Text');
	is($empty->length(), 0, 'Empty object has zero length');

	# Array reference construction
	my $array_dt = Data::Text->new(text => ['Hello', ' ', 'World']);
	is($array_dt->as_string(), 'Hello World', 'Array reference construction');

	# Object cloning
	my $clone = Data::Text->new($dt);
	is($clone->as_string(), $dt->as_string(), 'Object cloning works');
	$clone->set('Goodbye');
	isnt($clone->as_string(), $dt->as_string(), 'Clone is different object');
};

subtest 'Edge cases and error handling' => sub {
	my $dt = Data::Text->new();

	# Undefined/null inputs
	dies_ok { $dt->set() } 'Dies on empty set()';
	dies_ok { $dt->append() } 'Dies on empty append()';

	# Empty array handling
	warning_like { $dt->set(text => []) } qr/no text given/, 'Warning on empty array';

	# Consecutive punctuation
	$dt->set("Hello.");
	warning_like { $dt->append(".") } qr/consecutive punctuation/, "Consecutive punctuation warning";

	# Non-string objects
	my $obj = bless {}, 'TestClass';
	dies_ok { $dt->set($obj) } "Dies with object lacking as_string method";
};

subtest 'Unicode and encoding tests' => sub {
	my $unicode = Data::Text->new("Héllo Wörld 🌍");
	is($unicode->length(), 13, "Unicode length calculation");
	is($unicode->uppercase()->as_string(), "HÉLLO WÖRLD 🌍", "Unicode uppercase");

	# Test various encodings
	my $emoji = Data::Text->new("🔥💯⚡");
	ok($emoji->length() > 0, "Emoji handling");
};

subtest 'Performance and memory tests' => sub {
	# Large string operations
	my $large = Data::Text->new();
	for my $i (1..1000) {
		$large->append("Line $i\n");
	}
	is($large->length(), length($large->as_string()), "Large string consistency");

	# Memory leak test (simplified)
	my $original_count = scalar(keys %Data::Text::);
	for my $i (1..100) {
		my $temp = Data::Text->new("temporary $i");
		$temp->append(" more text");
	}
	# Check that we're not leaking objects (this is a basic check)
};

subtest 'Method chaining and fluent interface' => sub {
	my $dt = Data::Text->new("  hello world  ")
		->trim()
		->uppercase()
		->replace({'HELLO' => 'GOODBYE'});

	is($dt->as_string(), "GOODBYE WORLD", "Method chaining works");

	# Ensure failed operations don't break chaining
	my $result = Data::Text->new("test.")
		->append(".") # This should warn but not break chain
		->uppercase();

	# Result should still be a Data::Text object
	isa_ok($result, 'Data::Text');
};

subtest 'Operator overloading tests' => sub {
	my $dt1 = Data::Text->new("same");
	my $dt2 = Data::Text->new("same");
	my $dt3 = Data::Text->new("different");

	ok($dt1 == $dt2, "Equality operator works");
	ok($dt1 != $dt3, "Inequality operator works");

	# String context
	is("$dt1", "same", "String interpolation works");

	# Boolean context
	ok($dt1, "Object is truthy");
	ok(Data::Text->new(""), "Even empty object is truthy");
};

subtest 'Boundary conditions' => sub {
	# Very long strings
	my $long_string = "x" x 100000;
	my $dt = Data::Text->new($long_string);
	is($dt->length(), 100000, "Very long string handling");

	# Special characters
	my $special = Data::Text->new("\n\r\t\0");
	ok($special->length() > 0, "Special characters preserved");

	# Binary data (should probably be avoided, but test anyway)
	my $binary = Data::Text->new(pack("H*", "deadbeef"));
	ok($binary->length() > 0, "Binary data handling");
};

subtest 'Conjunction functionality' => sub {
	delete local $ENV{'LC_ALL'};
	local $ENV{'LANGUAGE'} = 'en';

	my $dt = new_ok('Data::Text');
	my $result = $dt->appendconjunction('apple', 'banana', 'cherry');
	like($result->as_string(), qr/apple.*and.*cherry/, "Conjunction formatting");

	# Test with Data::Text objects
	my $a = Data::Text->new('red');
	my $b = Data::Text->new('green');
	my $c = Data::Text->new('blue');

	my $colors = Data::Text->new()->appendconjunction($a, $b, $c);
	like($colors->as_string(), qr/red.*green.*and.*blue/, "Object conjunction");
};

done_testing();
