#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Array::Iterator') }

# Create an iterator from a list
subtest 'Constructor and Basic Iteration' => sub {
	my @array = (1, 2, 3, 4, 5);
	my $iterator = Array::Iterator->new(@array);

	isa_ok($iterator, 'Array::Iterator', 'Object is an instance of Array::Iterator');
	is($iterator->current_index(), 0, 'Initial index should be 0');

	ok($iterator->has_next(), 'Iterator should have next element');
	is($iterator->next(), 1, 'First call to next() should return first element');
	is($iterator->current(), 1, 'current() should return the current element');
};

# Iteration through all elements
subtest 'Full Iteration' => sub {
	my @array = (10, 20, 30);
	my $iterator = Array::Iterator->new(@array);
	my @collected;

	while ($iterator->has_next()) {
		push @collected, $iterator->next();
	}

	is_deeply(\@collected, \@array, 'Iterated elements should match input array');
	ok(!$iterator->has_next(), 'Iterator should be exhausted');
	is($iterator->get_next(), undef, 'get_next() should return undef when exhausted');
};

# Peeking ahead
subtest 'Peek' => sub {
	my @array = qw(a b c d e);
	my $iterator = Array::Iterator->new(@array);

	is($iterator->peek(1), 'a', 'peek(1) should return first element without advancing');
	is($iterator->next(), 'a', 'next() should return first element after peek');
	is($iterator->peek(2), 'c', 'peek(2) should return the second element ahead');

	lives_ok { $iterator->peek(10) } 'Peeking out of bounds no longer dies';
	ok(!defined($iterator->peek(10)));
};

# Reset functionality
subtest 'Reset' => sub {
	my @array = (100, 200, 300);
	my $iterator = Array::Iterator->new(@array);

	$iterator->next();
	$iterator->reset();

	is($iterator->current_index(), 0, 'After reset, index should be 0');
	is($iterator->next(), 100, 'After reset, next() should return the first element again');
};

# Handling empty array
subtest 'Empty Iterator' => sub {
	my @empty;

	dies_ok { Array::Iterator->new(@empty) } 'Dies when given empty array to iterate over';
};

# Hash reference initialization
subtest 'Iterator with Hash Reference' => sub {
	my %hash = (
		__array__ => [ 'apple', 'banana', 'cherry' ]
	);

	my $iterator = Array::Iterator->new(\%hash);
	is($iterator->next(), 'apple', 'Iterator should work with hash reference input');
};

# Run all tests
done_testing();
