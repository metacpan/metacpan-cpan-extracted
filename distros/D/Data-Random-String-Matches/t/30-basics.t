#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

use_ok('Data::Random::String::Matches');

# Test constructor
subtest 'Constructor tests' => sub {
	my $gen = Data::Random::String::Matches->new(qr/test/);
	isa_ok($gen, 'Data::Random::String::Matches', 'new() returns correct object');

	my $gen2 = Data::Random::String::Matches->new('test', 15);
	is($gen2->{length}, 15, 'length parameter is set correctly');

	throws_ok {
		Data::Random::String::Matches->new()
	} qr/Regex pattern is required/, 'dies without regex parameter';
};

# Test basic pattern matching
subtest 'Basic pattern matching' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/, 4);
	my $str = $gen->generate();

	ok(defined $str, 'generate() returns a defined value');
	like($str, qr/^\d{4}$/, 'generated string matches 4 digits pattern');
	is(length($str), 4, 'generated string has correct length');
};

# Test character classes
subtest 'Character class patterns' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z]{3}/, 3);
	my $str = $gen->generate();

	like($str, qr/^[A-Z]{3}$/, 'matches uppercase letters pattern');

	my $gen2 = Data::Random::String::Matches->new(qr/[a-z0-9]{6}/, 6);
	my $str2 = $gen2->generate();
	like($str2, qr/^[a-z0-9]{6}$/, 'matches lowercase alphanumeric pattern');
};

# Test mixed patterns
subtest 'Mixed patterns' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z]{2}\d{4}/, 6);
	my $str = $gen->generate();

	like($str, qr/^[A-Z]{2}\d{4}$/, 'matches mixed letter-digit pattern');

	my $gen2 = Data::Random::String::Matches->new(qr/test\d+/, 8);
	my $str2 = $gen2->generate();
	like($str2, qr/^test\d+$/, 'matches literal prefix with digits');
};

# Test word character patterns
subtest 'Word character patterns' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\w{5}/, 5);
	my $str = $gen->generate();

	like($str, qr/^\w{5}$/, 'matches word character pattern');
};

# Test multiple generation consistency
subtest 'Multiple generation' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{3}/, 3);

	my @results;
	for (1..10) {
		my $str = $gen->generate();
		push @results, $str;
		like($str, qr/^\d{3}$/, "attempt $_ generates matching string");
	}

	# Check that we get some variation
	my %unique = map { $_ => 1 } @results;
	cmp_ok(scalar keys %unique, '>', 1, 'generates different strings');
};

# Test string pattern conversion
subtest 'String pattern conversion' => sub {
	my $gen = Data::Random::String::Matches->new('[0-9]{4}', 4);
	my $str = $gen->generate();

	like($str, qr/^[0-9]{4}$/, 'string pattern is converted to regex');
};

# Test max_attempts parameter
subtest 'Max attempts parameter' => sub {
	# Use a very long literal string that's unlikely to be randomly generated
	# and make the length too short, so smart parser will generate wrong length
	my $long_string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
	my $gen = Data::Random::String::Matches->new(qr/^$long_string$/, 5);

	# Temporarily break smart parser by making it return wrong result
	no warnings 'redefine';
	local *Data::Random::String::Matches::_build_from_pattern = sub { return 'WRONG' };

	throws_ok {
		$gen->generate(10)
	} qr/Failed to generate matching string/,
	  'dies after max attempts when smart parser returns non-matching string';
};

# Test with complex patterns
subtest 'Complex patterns' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z][a-z]{2}\d{2}/, 5);
	my $str = $gen->generate();

	like($str, qr/^[A-Z][a-z]{2}\d{2}$/,
		 'matches complex pattern with different character classes');
	is(length($str), 5, 'complex pattern generates correct length');
};

# Test edge cases
subtest 'Edge cases' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z]/, 1);
	my $str = $gen->generate();

	like($str, qr/^[A-Z]$/, 'handles single character pattern');
	is(length($str), 1, 'single character has length 1');

	my $gen2 = Data::Random::String::Matches->new(qr/ABC/, 3);
	my $str2 = $gen2->generate();
	is($str2, 'ABC', 'handles literal string pattern');
};

# Test generate_smart method (if available)
subtest 'generate_smart method' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{3}/, 3);

	lives_ok {
		my $str = $gen->generate_smart();
	} 'generate_smart() executes without errors';
};

# Test fixed length complex pattern
subtest 'fixed length' => sub {
	my $gen = Data::Random::String::Matches->new(qr/^AIza[0-9A-Za-z_-]{35}$/);
	lives_ok {
		my $str = $gen->generate_smart();
		like($str, qr/^AIza[0-9A-Za-z_-]{35}$/, 'Complex API key generation works');
		is(length($str), 39, 'Generated string has correct length');
	} 'generate_smart() executes without errors for complex pattern';
};

# Test alternation patterns
subtest 'Alternation patterns' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(cat|dog|bird)/);
	my $str = $gen->generate_smart();
	ok(defined $str, 'Alternation pattern generates something');
};

# Test optional elements
subtest 'Optional elements' => sub {
	my $gen = Data::Random::String::Matches->new(qr/colou?r/);
	my $str = $gen->generate_smart();
	like($str, qr/^colou?r$/, 'Optional character pattern works');
};

# Test randomness
subtest 'Randomness check' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[0-9]/, 1);

	my %seen;
	for (1..50) {
		my $str = $gen->generate();
		$seen{$str}++;
	}

	# Should see multiple different digits
	cmp_ok(scalar keys %seen, '>=', 3, 'generates reasonably random distribution');
};

done_testing();
