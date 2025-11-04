#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Data::Random::String::Matches');
}

# ===========================================================================
# Regression test for quote handling in character classes
# Issue: Argument "#" isn't numeric in range (or flop)
# Pattern: qr/^[!#-'*+\\-\\.\\^_`|~0-9A-Za-z]+$/
# ===========================================================================

subtest 'Character class with single quotes in range' => sub {
	# The problematic pattern that caused the original error
	my $gen = Data::Random::String::Matches->new(qr/^[!#-'*+\\-\\.\\^_`|~0-9A-Za-z]+$/);

	# Should not die
	my $str;
	eval {
		$str = $gen->generate();
	};

	ok(!$@, 'Generates without error') or diag("Error: $@");
	ok(defined $str, 'Generated string is defined');

	if (defined $str) {
		# Verify it matches the pattern
		like($str, qr/^[!#-'*+\\-\\.\\^_`|~0-9A-Za-z]+$/, 'Generated string matches pattern');

		# Check that string contains valid characters
		my @chars = split //, $str;
		for my $char (@chars) {
			my $ord = ord($char);
			# Valid ranges: ! (33), #-' (35-39), * (42), + (43), - (45), . (46),
			# ^ (94), _ (95), ` (96), | (124), ~ (126), 0-9 (48-57), A-Z (65-90), a-z (97-122)
			ok(
				$char =~ /[!#-'*+\\\-\.\^_`|~0-9A-Za-z]/,
				"Character '$char' (ord $ord) is valid"
			);
		}
	}
};

subtest 'Character class with range starting after quote' => sub {
	# Range #-' includes: # $ % & '
	my $gen = Data::Random::String::Matches->new(qr/[#-']/);

	my $str = $gen->generate();
	ok(defined $str, 'Generated string defined');
	like($str, qr/^[#-']$/, 'Matches range #-\'');

	# Verify it's one of the expected characters
	ok($str =~ /^[#\$%&']$/, "Character is in range: $str");
};

subtest 'Character class with quote as range end' => sub {
	# Test various ranges ending in quotes
	my @test_patterns = (
		qr/[!-']/,	# ! " # $ % & '
		qr/["-']/,	# " # $ % & '
		qr/[#-']/,	# # $ % & '
	);

	for my $pattern (@test_patterns) {
		my $gen = Data::Random::String::Matches->new($pattern);
		my $str = $gen->generate();

		ok(defined $str, "Pattern $pattern generates successfully");
		like($str, $pattern, 'Generated string matches pattern');
	}
};

subtest 'Character class with double quotes in range' => sub {
	# Range with double quotes
	my $gen = Data::Random::String::Matches->new(qr/[!-"]/);

	my $str = $gen->generate();
	ok(defined $str, 'Generated with double quote range');
	like($str, qr/^[!-"]$/, 'Matches range with double quote');

	# Should be ! or "
	ok($str eq '!' || $str eq '"', "Character is ! or \": got '$str'");
};

subtest 'Character class with backtick' => sub {
	# Backtick in character class
	my $gen = Data::Random::String::Matches->new(qr/[_`a]/);

	my $str = $gen->generate();
	ok(defined $str, 'Generated with backtick');
	like($str, qr/^[_`a]$/, 'Matches pattern with backtick');

	ok($str =~ /^[_`a]$/, "Character is valid: $str");
};

subtest 'Character class with escaped special chars' => sub {
	# Pattern with escaped special characters
	my $gen = Data::Random::String::Matches->new(qr/[a\-z]/);

	my $str = $gen->generate();
	ok(defined $str, 'Generated with escaped dash');

	# Should be 'a', '-', or 'z' (not a range because dash is escaped)
	ok($str =~ /^[az\-]$/, "Character is a, z, or dash: $str");
};

subtest 'Character class with multiple quote types' => sub {
	# Mix of single and double quotes
	my $gen = Data::Random::String::Matches->new(qr/["'`]/);

	my $str = $gen->generate();
	ok(defined $str, 'Generated with multiple quote types');
	ok($str eq '"' || $str eq "'" || $str eq '`', "Character is a quote type: $str");
};

subtest 'Complex character class from original error' => sub {
	# Full pattern that caused the error
	my $pattern = qr/^[!#-'*+\\-\\.\\^_`|~0-9A-Za-z]+$/;
	my $gen = Data::Random::String::Matches->new($pattern);

	# Generate multiple times to ensure consistency
	for my $i (1..10) {
		my $str = $gen->generate();
		ok(defined $str, "Iteration $i: Generated successfully");
		like($str, $pattern, "Iteration $i: Matches pattern");
		ok(length($str) > 0, "Iteration $i: Non-empty string");
	}
};

subtest 'Character class range boundaries with quotes' => sub {
	# Test ranges that include quote characters at boundaries
	my @test_cases = (
		{
			pattern => qr/[!-']/,
			desc	=> 'Range from ! to \'',
			chars   => ['!', '"', '#', '$', '%', '&', "'"],
		},
		{
			pattern => qr/['-*]/,
			desc	=> 'Range from \' to *',
			chars   => ["'", '(', ')', '*'],
		},
	);

	for my $test (@test_cases) {
		my $gen = Data::Random::String::Matches->new($test->{pattern});

		# Generate multiple strings
		my %seen;
		for (1..50) {
			my $str = $gen->generate();
			$seen{$str}++;
		}

		# Check we only got valid characters
		for my $char (keys %seen) {
			ok(
				(grep { $_ eq $char } @{$test->{chars}}),
				"$test->{desc}: Character '$char' is valid"
			);
		}

		# Should have some variety (at least 2 different chars in 50 tries)
		cmp_ok(scalar keys %seen, '>=', 2, "$test->{desc}: Generated variety");
	}
};

subtest 'Escaped vs unescaped dash in character class' => sub {
	# Escaped dash: literal dash character
	my $gen1 = Data::Random::String::Matches->new(qr/[a\-z]/);
	my %chars1;
	$chars1{$gen1->generate()}++ for (1..30);

	# Should only see a, -, z (not b, c, d, etc.)
	for my $char (keys %chars1) {
		ok($char =~ /^[az\-]$/, "Escaped dash pattern: got '$char'");
	}

	# Unescaped dash: range
	my $gen2 = Data::Random::String::Matches->new(qr/[a-z]/);
	my %chars2;
	$chars2{$gen2->generate()}++ for (1..30);

	# Should see variety of lowercase letters
	ok(scalar(keys %chars2) >= 5, 'Unescaped dash creates range with variety');
};

subtest 'Validate pattern_info with quotes' => sub {
	# Ensure pattern_info doesn't crash on these patterns
	my $gen = Data::Random::String::Matches->new(qr/^[!#-'*+\\-\\.\\^_`|~0-9A-Za-z]+$/);

	my $info;
	eval {
		$info = $gen->pattern_info();
	};

	ok(!$@, 'pattern_info does not crash') or diag("Error: $@");
	ok(defined $info, 'pattern_info returns defined value');

	if (defined $info) {
		ok(exists $info->{min_length}, 'Has min_length');
		ok(exists $info->{max_length}, 'Has max_length');
		ok(exists $info->{complexity}, 'Has complexity');
	}
};

subtest 'Generate many with quote patterns' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[!#-']/);

	# Pattern [!#-'] has 6 possible characters: ! " # $ % & '
	# So we can only generate at most 6 unique single-char strings
	my @strings = $gen->generate_many(6, 1);

	cmp_ok(scalar @strings, '>=', 5, 'Generated at least 5 unique strings')
		or diag('Only got ', scalar(@strings));
	cmp_ok(scalar @strings, '<=', 6, 'Generated at most 6 unique strings (the maximum possible)');

	# All should match
	for my $str (@strings) {
		like($str, qr/^[!#-']$/, "String '$str' matches pattern");
	}

	# Check uniqueness
	my %seen;
	for my $str (@strings) {
		ok(!$seen{$str}, "String '$str' is unique");
		$seen{$str}++;
	}
};

subtest 'Validate with quote patterns' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[#-']/);

	# Test valid characters in range
	ok($gen->validate('#'), 'Validates #');
	ok($gen->validate('$'), 'Validates $');
	ok($gen->validate('%'), 'Validates %');
	ok($gen->validate('&'), 'Validates &');
	ok($gen->validate("'"), 'Validates \'');

	# Test invalid characters
	ok(!$gen->validate('!'), 'Rejects !');
	ok(!$gen->validate('('), 'Rejects (');
	ok(!$gen->validate('a'), 'Rejects a');
};

done_testing();
