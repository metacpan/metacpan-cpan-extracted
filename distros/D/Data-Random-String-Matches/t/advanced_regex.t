#!/usr/bin/env perl

use strict;
use warnings;

use utf8;
use Test::Most;
# use Test::DescribeMe qw(extended);	# These can fail at the moment.  Disable while debugging

use open ':std', ':encoding(UTF-8)';

use_ok('Data::Random::String::Matches');

# Test Unicode properties
subtest 'Unicode properties - Letters' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\p{L}{5}/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Generated string with \p{L}');
	is(length($str), 5, 'Correct length');
	like($str, qr/^\p{L}{5}$/, 'Matches letter property');
};

subtest 'Unicode properties - Numbers' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\p{N}{3}/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Generated string with \p{N}');
	is(length($str), 3, 'Correct length');
	like($str, qr/^\p{N}{3}$/, 'Matches number property');
};

subtest 'Unicode properties - Uppercase' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\p{Lu}{4}/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Generated string with \p{Lu}');
	is(length($str), 4, 'Correct length');
	like($str, qr/^\p{Lu}{4}$/, 'Matches uppercase property');
};

subtest 'Unicode properties - Lowercase' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\p{Ll}{4}/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Generated string with \p{Ll}');
	is(length($str), 4, 'Correct length');
	like($str, qr/^\p{Ll}{4}$/, 'Matches lowercase property');
};

subtest 'Unicode properties in character class' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[\p{L}\d]{6}/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Generated string with mixed property class');
	is(length($str), 6, 'Correct length');
	like($str, qr/^[\p{L}\d]{6}$/, 'Matches mixed property class');
};

# Test Named Captures
subtest 'Named captures - basic' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(?<digits>\d{3})/);
	my $str = $gen->generate_smart();

	like($str, qr/^\d{3}$/, 'Named capture generates correctly');
};

subtest 'Named captures - multiple' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(?<year>\d{4})-(?<month>\d{2})/);
	my $str = $gen->generate_smart();

	like($str, qr/^\d{4}-\d{2}$/, 'Multiple named captures work');
	is(length($str), 7, 'Correct total length');
};

subtest 'Named backreferences' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(?<word>\w{3})-\k<word>/);
	my $str = $gen->generate_smart();

	like($str, qr/^(\w{3})-\1$/, 'Named backreference works');

	if ($str =~ /^(\w{3})-(\w{3})$/) {
		is($1, $2, 'Named backreference repeats correctly');
	}
};

subtest 'Mixed named and numbered captures' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(?<first>\d{2})(\w{3})\k<first>/);
	my $str = $gen->generate_smart();

	like($str, qr/^(\d{2})(\w{3})\1$/, 'Mixed captures work');
};

# Test Possessive Quantifiers
subtest 'Possessive quantifiers - *+' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d*+[A-Z]/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Possessive *+ generates');
	like($str, qr/^\d*[A-Z]$/, 'Possessive *+ pattern matches');
};

subtest 'Possessive quantifiers - ++' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d++/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Possessive ++ generates');
	like($str, qr/^\d+$/, 'Possessive ++ pattern matches');
	cmp_ok(length($str), '>=', 1, 'At least one digit');
};

subtest 'Possessive quantifiers - ?+' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z]?+\d{2}/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Possessive ?+ generates');
	like($str, qr/^[A-Z]?\d{2}$/, 'Possessive ?+ pattern matches');
};

subtest 'Possessive quantifiers - {n,m}+' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{2,4}+[A-Z]/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Possessive {n,m}+ generates');
	like($str, qr/^\d{2,4}[A-Z]$/, 'Possessive range quantifier matches');
};

# Test Lookaheads
subtest 'Positive lookahead' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{3}(?=ABC)/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Positive lookahead generates');
	like($str, qr/^\d{3}$/, 'Lookahead doesn\'t consume');
};

subtest 'Negative lookahead' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{3}(?!XYZ)/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Negative lookahead generates');
	like($str, qr/^\d{3}$/, 'Negative lookahead doesn\'t consume');
};

subtest 'Multiple lookaheads' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\w{4}(?=\d)(?=[A-Z])/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Multiple lookaheads generate');
	like($str, qr/^\w{4}$/, 'Multiple lookaheads don\'t consume');
};

# Test Lookbehinds
subtest 'Positive lookbehind' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(?<=ABC)\d{3}/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Positive lookbehind generates');
	like($str, qr/^\d{3}$/, 'Lookbehind doesn\'t add to result');
};

subtest 'Negative lookbehind' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(?<!XYZ)\d{3}/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Negative lookbehind generates');
	like($str, qr/^\d{3}$/, 'Negative lookbehind doesn\'t add to result');
};

# Test Complex Combinations
subtest 'Unicode with named captures' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(?<letters>\p{L}{3})-(?<numbers>\d{3})/);
	my $str = $gen->generate_smart();

	like($str, qr/^\p{L}{3}-\d{3}$/, 'Unicode with named captures works');
};

subtest 'Possessive with backreferences' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(\w{3})++\1/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Possessive with backreference generates');
	# Pattern should have repeated word chars
};

subtest 'Named captures with possessive quantifiers' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(?<id>\d{3})+(?<code>[A-Z]{2})/);
	my $str = $gen->generate_smart();

	# The group (\d{3})+ can repeat, so we get 3, 6, 9, 12, etc. digits
	like($str, qr/^(\d{3})+[A-Z]{2}$/, 'Named capture with group quantifier works');

	# Extract and verify
	if ($str =~ /^(\d+)([A-Z]{2})$/) {
		my $digit_count = length($1);
		is($digit_count % 3, 0, 'Digit count is multiple of 3');
	}
};

subtest 'Unicode properties with lookahead' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\p{L}{3}(?=\d)/);
	my $str = $gen->generate_smart();

	like($str, qr/^\p{L}{3}$/, 'Unicode with lookahead works');
};

subtest 'All features combined' => sub {
	# Pattern with Unicode, named capture, possessive, and lookahead
	my $gen = Data::Random::String::Matches->new(qr/(?<prefix>\p{Lu}{2})\d++\k<prefix>(?=[A-Z])/);
	my $str = $gen->generate_smart();

	ok(defined $str, 'Complex combination generates');
	like($str, qr/^(\p{Lu}{2})\d+\1$/, 'Complex pattern matches');
};

# Test edge cases
subtest 'Empty lookahead' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{3}(?=)/);
	my $str = $gen->generate_smart();

	like($str, qr/^\d{3}$/, 'Empty lookahead works');
};

subtest 'Nested groups with named captures' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(?<outer>(?<inner>\d{2})[A-Z])/);
	my $str = $gen->generate_smart();

	like($str, qr/^\d{2}[A-Z]$/, 'Nested named captures work');
};

subtest 'Unicode property variations' => sub {
	# Test both short and long forms
	my $gen1 = Data::Random::String::Matches->new(qr/\p{L}{3}/);
	my $str1 = $gen1->generate_smart();
	like($str1, qr/^\p{L}{3}$/, 'Short form \p{L} works');

	my $gen2 = Data::Random::String::Matches->new(qr/\p{Letter}{3}/);
	my $str2 = $gen2->generate_smart();
	like($str2, qr/^\p{Letter}{3}$/, 'Long form \p{Letter} works');
};

subtest 'Possessive quantifiers preserve semantics' => sub {
	# Possessive quantifiers should generate same as non-possessive for our purposes
	my $gen1 = Data::Random::String::Matches->new(qr/\d{2,4}/);
	my $gen2 = Data::Random::String::Matches->new(qr/\d{2,4}+/);

	my $str1 = $gen1->generate_smart();
	my $str2 = $gen2->generate_smart();

	like($str1, qr/^\d{2,4}$/, 'Non-possessive generates correctly');
	like($str2, qr/^\d{2,4}$/, 'Possessive generates correctly');
};

subtest 'Multiple named backreferences' => sub {
	my $gen = Data::Random::String::Matches->new(
		qr/(?<a>\d{2})(?<b>\w{3})\k<a>\k<b>\k<a>/
	);
	my $str = $gen->generate_smart();

	if ($str =~ /^(\d{2})(\w{3})(\d{2})(\w{3})(\d{2})$/) {
		is($1, $3, 'First named backref matches');
		is($1, $5, 'First named backref matches again');
		is($2, $4, 'Second named backref matches');
	}
};

done_testing();
