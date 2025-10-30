#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

use_ok('Data::Random::String::Matches');

# Test basic generation of multiple strings
subtest 'Basic generate_many' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/);
	my @results = $gen->generate_many(10);

	is(scalar @results, 10, 'Generated correct number of strings');

	for my $str (@results) {
		like($str, qr/^\d{4}$/, "String matches pattern: $str");
	}
};

# Test that duplicates are allowed by default
subtest 'Duplicates allowed by default' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[AB]/);
	my @results = $gen->generate_many(20);

	is(scalar @results, 20, 'Generated correct number');

	# With only 2 possible values, we should see duplicates
	my %seen;
	$seen{$_}++ for @results;

	cmp_ok(scalar keys %seen, '<=', 2, 'Only A and B possible');
	ok((grep { $_ > 1 } values %seen), 'Has duplicates');
};

# Test unique flag
subtest 'Unique strings generation' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{3}/);
	my @results = $gen->generate_many(50, 1);

	my %seen;
	$seen{$_}++ for @results;

	is(scalar keys %seen, scalar @results, 'All strings are unique');
	cmp_ok(scalar @results, '<=', 50, 'Got up to 50 results');

	for my $str (@results) {
		like($str, qr/^\d{3}$/, "Unique string matches: $str");
	}
};

# Test unique with string argument
subtest 'Unique with string argument' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-C]{2}/);
	my @results = $gen->generate_many(9, 'unique');

	my %seen;
	$seen{$_}++ for @results;

	is(scalar keys %seen, scalar @results, 'All strings unique with "unique" string');
	cmp_ok(scalar @results, '<=', 9, 'At most 9 combinations (AA, AB, AC, BA, BB, BC, CA, CB, CC)');
};

# Test warning when unique count not achievable
subtest 'Warning for impossible unique count' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[AB]/);

	# Only 2 possible strings (A and B), but asking for 10 unique
	my @results;
	warning_like {
		@results = $gen->generate_many(10, 1);
	} qr/Only generated \d+ unique strings out of 10 requested/,
	  'Warns when unique count not achievable';

	cmp_ok(scalar @results, '<=', 2, 'Can only get 2 unique strings');

	my %seen;
	$seen{$_}++ for @results;
	is(scalar keys %seen, scalar @results, 'All results are unique');
};

# Test error handling - invalid count
subtest 'Error handling - invalid count' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{3}/);

	throws_ok {
		$gen->generate_many(0);
	} qr/Count must be a positive integer/, 'Dies with count = 0';

	throws_ok {
		$gen->generate_many(-5);
	} qr/Count must be a positive integer/, 'Dies with negative count';

	throws_ok {
		$gen->generate_many();
	} qr/Count must be a positive integer/, 'Dies with no count';
};

# Test large batch generation
subtest 'Large batch generation' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z0-9]{6}/);
	my @results = $gen->generate_many(1000);

	is(scalar @results, 1000, 'Generated 1000 strings');

	# Sample check (don't test all 1000)
	for my $i (0, 100, 500, 999) {
		like($results[$i], qr/^[A-Z0-9]{6}$/, "Sample string $i matches");
	}
};

# Test large unique batch
subtest 'Large unique batch' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z]{2}\d{3}/);
	my @results = $gen->generate_many(500, 1);

	my %seen;
	$seen{$_}++ for @results;

	is(scalar keys %seen, scalar @results, 'All 500 strings are unique');
	cmp_ok(scalar @results, '>=', 100, 'Generated substantial number of unique strings');
};

# Test with complex patterns
subtest 'Complex pattern generation' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z]{3}-\d{4}/);
	my @results = $gen->generate_many(25);

	is(scalar @results, 25, 'Generated 25 complex strings');

	for my $str (@results) {
		like($str, qr/^[A-Z]{3}-\d{4}$/, "Complex string matches: $str");
	}
};

# Test with alternation
subtest 'Alternation patterns' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(cat|dog|bird)/);
	my @results = $gen->generate_many(30);

	is(scalar @results, 30, 'Generated 30 alternation strings');

	my %types;
	for my $str (@results) {
		like($str, qr/^(cat|dog|bird)$/, "Alternation matches: $str");
		$types{$str}++;
	}

	# Should see variation
	cmp_ok(scalar keys %types, '>=', 2, 'Generated multiple alternatives');
};

# Test with backreferences
subtest 'Backreferences' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(\w{3})-\1/);
	my @results = $gen->generate_many(20);

	is(scalar @results, 20, 'Generated 20 backreference strings');

	for my $str (@results) {
		like($str, qr/^(\w{3})-\1$/, "Backreference matches: $str");

		# Verify the backreference actually repeats
		my ($first, $second) = split /-/, $str;
		is($first, $second, "Backreference repeats correctly in: $str");
	}
};

# Test with Unicode
subtest 'Unicode patterns' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\p{L}{4}/);
	my @results = $gen->generate_many(15);

	is(scalar @results, 15, 'Generated 15 Unicode strings');

	for my $str (@results) {
		like($str, qr/^\p{L}{4}$/, "Unicode string matches");
	}
};

# Test return value in scalar context
subtest 'Scalar context' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{3}/);
	my $count = $gen->generate_many(10);

	is($count, 10, 'Returns count in scalar context');
};

# Test that each call is independent
subtest 'Independence of calls' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/);

	my @first = $gen->generate_many(10);
	my @second = $gen->generate_many(10);

	is(scalar @first, 10, 'First call generates 10');
	is(scalar @second, 10, 'Second call generates 10');

	# Arrays should be different (extremely unlikely to be identical)
	my $same = 1;
	for my $i (0..9) {
		if ($first[$i] ne $second[$i]) {
			$same = 0;
			last;
		}
	}
	is($same, 0, 'Multiple calls produce different results');
};

# Test edge case - generate 1
subtest 'Generate single string via generate_many' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{5}/);
	my @results = $gen->generate_many(1);

	is(scalar @results, 1, 'Generated 1 string');
	like($results[0], qr/^\d{5}$/, 'Single string matches');
};

# Test realistic use case - test data generation
subtest 'Realistic use case - test data' => sub {
	# Generate test email addresses
	my $email_gen = Data::Random::String::Matches->new(qr/[a-z]{5,10}\@test\.com/);
	my @emails = $email_gen->generate_many(50, 1);

	cmp_ok(scalar @emails, '>=', 30, 'Generated many unique emails');

	for my $email (@emails) {
		like($email, qr/^[a-z]{5,10}\@test\.com$/, "Valid test email: $email");
	}

	# Verify uniqueness
	my %seen;
	$seen{$_}++ for @emails;
	is(scalar keys %seen, scalar @emails, 'All emails are unique');
};

# Test performance - should be reasonably fast
subtest 'Performance check' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z0-9]{8}/);

	my $start = time();
	my @results = $gen->generate_many(1000);
	my $elapsed = time() - $start;

	is(scalar @results, 1000, 'Generated 1000 strings');
	cmp_ok($elapsed, '<', 10, 'Completed in reasonable time (< 10 seconds)');
};

done_testing();
