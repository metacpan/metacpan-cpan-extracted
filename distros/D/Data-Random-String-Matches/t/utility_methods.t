#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Data::Random::String::Matches');
}

# ===========================================================================
# set_seed() tests
# ===========================================================================

subtest 'set_seed - basic functionality' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{10}/);

	is($gen->get_seed(), undef, 'No seed initially');

	# Set seed and generate
	$gen->set_seed(12345);
	my $str1 = $gen->generate();

	# Reset seed and generate again
	$gen->set_seed(12345);
	my $str2 = $gen->generate();

	is($str1, $str2, 'Same seed produces same result');
	like($str1, qr/^\d{10}$/, 'Generated string matches pattern');
};

subtest 'set_seed - returns self for chaining' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/);
	my $result = $gen->set_seed(999);

	is($result, $gen, 'Returns self for method chaining');

	# Test chaining
	my $str = $gen->set_seed(999)->generate();
	like($str, qr/^\d{4}$/, 'Chaining works');
};

subtest 'set_seed - different seeds produce different results' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z]{10}/);

	$gen->set_seed(111);
	my $str1 = $gen->generate();

	$gen->set_seed(222);
	my $str2 = $gen->generate();

	isnt($str1, $str2, 'Different seeds produce different results');

	cmp_ok($gen->get_seed(), '==', 222, 'Get seed works');
};

subtest 'set_seed - error handling' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/);

	eval { $gen->set_seed() };
	like($@, qr/Usage/, 'Dies without seed');

	eval { $gen->set_seed(undef) };
	like($@, qr/Seed must be defined/, 'Dies with undef seed');
};

subtest 'set_seed - various seed types' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{5}/);

	# Numeric seed
	ok($gen->set_seed(12345), 'Accepts numeric seed');

	# Zero seed
	ok($gen->set_seed(0), 'Accepts zero as seed');
};

# ===========================================================================
# validate() tests
# ===========================================================================

subtest 'validate - matching strings' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/);

	ok($gen->validate('1234'), 'Valid 4-digit string');
	ok($gen->validate('0000'), 'Valid with zeros');
	ok($gen->validate('9999'), 'Valid with nines');
};

subtest 'validate - non-matching strings' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/);

	ok(!$gen->validate('123'), 'Too short');
	ok(!$gen->validate('12345'), 'Too long');
	ok(!$gen->validate('abcd'), 'Wrong characters');
	ok(!$gen->validate('12a4'), 'Mixed invalid chars');
};

subtest 'validate - complex patterns' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z]{3}-\d{4}/);

	ok($gen->validate('ABC-1234'), 'Valid complex pattern');
	ok(!$gen->validate('ABC1234'), 'Missing dash');
	ok(!$gen->validate('abc-1234'), 'Wrong case');
	ok(!$gen->validate('AB-1234'), 'Too few letters');
};

subtest 'validate - with alternation' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(cat|dog|bird)/);

	ok($gen->validate('cat'), 'First alternative');
	ok($gen->validate('dog'), 'Second alternative');
	ok($gen->validate('bird'), 'Third alternative');
	ok(!$gen->validate('fish'), 'Invalid alternative');
};

subtest 'validate - with backreferences' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(\w{3})-\1/);

	ok($gen->validate('abc-abc'), 'Valid backreference');
	ok($gen->validate('XYZ-XYZ'), 'Valid uppercase backreference');
	ok(!$gen->validate('abc-xyz'), 'Backreference mismatch');
	ok(!$gen->validate('abc-abcd'), 'Length mismatch');
};

subtest 'validate - error handling' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/);

	eval { $gen->validate() };
	like($@, qr/Usage/, 'Dies without string');

	eval { $gen->validate(undef) };
	like($@, qr/String must be defined/, 'Dies with undef');
};

subtest 'validate - special cases' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/);

	ok($gen->validate('0000'), 'All zeros valid');
	ok(!$gen->validate(''), 'Empty string invalid');
	ok(!$gen->validate(' 1234'), 'Leading space invalid');
	ok(!$gen->validate('1234 '), 'Trailing space invalid');
};

subtest 'validate - generated strings always validate' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z0-9]{8}/);

	for (1..10) {
		my $str = $gen->generate();
		ok($gen->validate($str), "Generated string validates: $str");
	}
};

# ===========================================================================
# pattern_info() tests
# ===========================================================================

subtest 'pattern_info - basic structure' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/);
	my $info = $gen->pattern_info();

	ok(defined $info, 'Returns defined value');
	is(ref($info), 'HASH', 'Returns hashref');

	# Check required keys
	ok(exists $info->{pattern}, 'Has pattern key');
	ok(exists $info->{min_length}, 'Has min_length key');
	ok(exists $info->{max_length}, 'Has max_length key');
	ok(exists $info->{estimated_length}, 'Has estimated_length key');
	ok(exists $info->{features}, 'Has features key');
	ok(exists $info->{complexity}, 'Has complexity key');
};

subtest 'pattern_info - simple pattern' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/);

	for(1..3) {	# Verify the internal caching
		my $info = $gen->pattern_info();

		is($info->{pattern}, '(?^:\d{4})', 'Pattern stored correctly');
		cmp_ok($info->{min_length}, '>=', 4, 'Min length reasonable');
		ok($info->{max_length} >= 4, 'Max length reasonable');
		is($info->{complexity}, 'simple', 'Simple pattern detected');
	}
};

subtest 'pattern_info - features detection' => sub {
	# Alternation
	my $gen1 = Data::Random::String::Matches->new(qr/(cat|dog)/);
	my $info1 = $gen1->pattern_info();
	ok($info1->{features}{has_alternation}, 'Detects alternation');

	# Backreferences
	my $gen2 = Data::Random::String::Matches->new(qr/(\w{3})-\1/);
	my $info2 = $gen2->pattern_info();
	ok($info2->{features}{has_backreferences}, 'Detects backreferences');

	# Unicode
	my $gen3 = Data::Random::String::Matches->new(qr/\p{L}{5}/);
	my $info3 = $gen3->pattern_info();
	ok($info3->{features}{has_unicode}, 'Detects Unicode properties');

	# Named groups
	my $gen4 = Data::Random::String::Matches->new(qr/(?<id>\d{3})/);
	my $info4 = $gen4->pattern_info();
	ok($info4->{features}{has_named_groups}, 'Detects named groups');

	# Possessive
	my $gen5 = Data::Random::String::Matches->new(qr/\d++/);
	my $info5 = $gen5->pattern_info();
	ok($info5->{features}{has_possessive}, 'Detects possessive quantifiers');
};

subtest 'pattern_info - length estimation' => sub {
	# Fixed length
	my $gen1 = Data::Random::String::Matches->new(qr/\d{5}/);
	my $info1 = $gen1->pattern_info();
	ok($info1->{min_length} <= 5, 'Min length <= 5');
	ok($info1->{max_length} >= 5, 'Max length >= 5');

	# Variable length
	my $gen2 = Data::Random::String::Matches->new(qr/\d{3,7}/);
	my $info2 = $gen2->pattern_info();
	ok($info2->{min_length} <= 3, 'Min accounts for lower bound');
	ok($info2->{max_length} >= 7, 'Max accounts for upper bound');
};

subtest 'pattern_info - complexity levels' => sub {
	# Simple
	my $gen1 = Data::Random::String::Matches->new(qr/\d{4}/);
	is($gen1->pattern_info()->{complexity}, 'simple', 'Simple pattern');

	# Complex (with multiple features)
	my $gen2 = Data::Random::String::Matches->new(qr/(?<id>\d{3})-(\w+)-\k<id>|[A-Z]{10}/);
	my $complexity = $gen2->pattern_info()->{complexity};
	ok($complexity =~ /^(moderate|complex|very_complex)$/, 'Complex pattern detected');
};

subtest 'pattern_info - estimated length' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{3,7}/);
	my $info = $gen->pattern_info();

	ok($info->{estimated_length} >= $info->{min_length}, 'Estimated >= min');
	ok($info->{estimated_length} <= $info->{max_length}, 'Estimated <= max');
};

subtest 'pattern_info - features hash structure' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/);
	my $features = $gen->pattern_info()->{features};

	is(ref($features), 'HASH', 'Features is a hashref');

	# Check all expected feature keys exist
	ok(exists $features->{has_alternation}, 'has_alternation key');
	ok(exists $features->{has_backreferences}, 'has_backreferences key');
	ok(exists $features->{has_unicode}, 'has_unicode key');
	ok(exists $features->{has_lookahead}, 'has_lookahead key');
	ok(exists $features->{has_lookbehind}, 'has_lookbehind key');
	ok(exists $features->{has_named_groups}, 'has_named_groups key');
	ok(exists $features->{has_possessive}, 'has_possessive key');
};

subtest 'pattern_info - no features in simple pattern' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z]{5}/);
	my $features = $gen->pattern_info()->{features};

	ok(!$features->{has_alternation}, 'No alternation');
	ok(!$features->{has_backreferences}, 'No backreferences');
	ok(!$features->{has_unicode}, 'No unicode');
	ok(!$features->{has_named_groups}, 'No named groups');
};

# ===========================================================================
# Integration tests
# ===========================================================================

subtest 'Integration - set_seed with generate_many' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/);

	$gen->set_seed(42);
	my @batch1 = $gen->generate_many(5);

	$gen->set_seed(42);
	my @batch2 = $gen->generate_many(5);

	is_deeply(\@batch1, \@batch2, 'Seeded generate_many is reproducible');
};

subtest 'Integration - validate with generate' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z]{3}\d{4}/);

	for (1..20) {
		my $str = $gen->generate();
		ok($gen->validate($str), "Generated string $str validates");
	}
};

subtest 'Integration - pattern_info accuracy check' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[A-Z]{3}\d{4}/);
	my $info = $gen->pattern_info();

	# Generate several strings and check lengths
	for (1..10) {
		my $str = $gen->generate();
		my $len = length($str);

		ok($len >= $info->{min_length}, "Length $len >= min $info->{min_length}");
		ok($len <= $info->{max_length}, "Length $len <= max $info->{max_length}");
	}
};

subtest 'Integration - all methods together' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/);

	# Get info
	my $info = $gen->pattern_info();
	ok($info->{complexity}, 'Got pattern info');

	# Set seed for reproducibility
	$gen->set_seed(123);

	# Generate and validate
	my $str = $gen->generate();
	ok($gen->validate($str), 'Generated and validated');

	# Generate many
	my @many = $gen->generate_many(5);
	is(scalar @many, 5, 'Generated many');

	# Validate all
	for my $s (@many) {
		ok($gen->validate($s), "Batch string validates: $s");
	}
};

done_testing();
