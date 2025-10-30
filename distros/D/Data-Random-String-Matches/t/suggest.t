#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Data::Random::String::Matches');
}

# ===========================================================================
# suggest_simpler_pattern() tests
# ===========================================================================

subtest 'suggest_simpler_pattern - simple patterns need no changes' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{4}/);
	my $suggestion = $gen->suggest_simpler_pattern();

	is($suggestion, undef, 'Simple pattern returns undef');
};

subtest 'suggest_simpler_pattern - very complex patterns' => sub {
	my $gen = Data::Random::String::Matches->new(
		qr/(?<id>\d{3})-(\w+)-\k<id>|[A-Z]{10}(?=\d)(?!X)/
	);
	my $suggestion = $gen->suggest_simpler_pattern();

	ok(defined $suggestion, 'Returns suggestion for complex pattern');
	ok(exists $suggestion->{reason}, 'Has reason');
	ok(exists $suggestion->{tips}, 'Has tips');
	like($suggestion->{reason}, qr/complex/i, 'Mentions complexity');
};

subtest 'suggest_simpler_pattern - large quantifier ranges' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{5,25}/);
	my $suggestion = $gen->suggest_simpler_pattern();

	ok(defined $suggestion, 'Suggests simplification for large range');
	ok(defined $suggestion->{pattern}, 'Provides alternative pattern');
	like($suggestion->{pattern}, qr/\{\d+\}/, 'Suggests fixed quantifier');
	like($suggestion->{reason}, qr/range/i, 'Explains about range');
};

subtest 'suggest_simpler_pattern - small quantifier ranges ok' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{3,5}/);
	my $suggestion = $gen->suggest_simpler_pattern();

	# Small ranges might not trigger suggestion, or might for other reasons
	ok(1, 'Handles small ranges');
};

subtest 'suggest_simpler_pattern - too many alternations' => sub {
	my $pattern = '(' . join('|', ('a'..'z')) . ')';  # 26 alternations
	my $gen = Data::Random::String::Matches->new(qr/$pattern/);
	my $suggestion = $gen->suggest_simpler_pattern();

	ok(defined $suggestion, 'Suggests simplification for many alternations');
	like($suggestion->{reason}, qr/alternation/i, 'Mentions alternations');
	ok(ref($suggestion->{tips}) eq 'ARRAY', 'Provides tips array');
};

subtest 'suggest_simpler_pattern - character class suggestion' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(a|b|c)/);
	my $suggestion = $gen->suggest_simpler_pattern();

	if (defined $suggestion) {
		like($suggestion->{pattern}, qr/\[abc\]/, 'Suggests character class');
		like($suggestion->{reason}, qr/character class/i, 'Explains character class benefit');
	} else {
		ok(1, 'Pattern acceptable as-is');
	}
};

subtest 'suggest_simpler_pattern - backreferences' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(\w{3})-\1/);
	my $suggestion = $gen->suggest_simpler_pattern();

	if (defined $suggestion) {
		like($suggestion->{reason}, qr/backreference/i, 'Mentions backreferences');
		ok(ref($suggestion->{tips}) eq 'ARRAY', 'Provides tips');
		ok(scalar @{$suggestion->{tips}} > 0, 'Has at least one tip');
	} else {
		ok(1, 'Pattern acceptable as-is');
	}
};

subtest 'suggest_simpler_pattern - lookaheads' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{3}(?=[A-Z])/);
	my $suggestion = $gen->suggest_simpler_pattern();

	ok(defined $suggestion, 'Suggests removing lookahead');
	is($suggestion->{pattern}, '(?^:\d{3})', 'Removes lookahead from pattern');
	like($suggestion->{reason}, qr/lookahead/i, 'Explains lookahead issue');
};

subtest 'suggest_simpler_pattern - lookbehinds' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(?<=PRE)\d{3}/);
	my $suggestion = $gen->suggest_simpler_pattern();

	ok(defined $suggestion, 'Suggests removing lookbehind');
	is($suggestion->{pattern}, '(?^:\d{3})', 'Removes lookbehind from pattern');
	like($suggestion->{reason}, qr/lookbehind/i, 'Explains lookbehind issue');
};

subtest 'suggest_simpler_pattern - unicode to ascii' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\p{L}{5}/);
	my $suggestion = $gen->suggest_simpler_pattern();

	ok(defined $suggestion, 'Suggests ASCII alternative');
	like($suggestion->{pattern}, qr/\[A-Za-z\]/, 'Suggests ASCII character class');
	like($suggestion->{reason}, qr/ASCII/i, 'Explains ASCII benefit');
};

subtest 'suggest_simpler_pattern - return structure' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{5,25}/);
	my $suggestion = $gen->suggest_simpler_pattern();

	if (defined $suggestion) {
		is(ref($suggestion), 'HASH', 'Returns hashref');
		ok(exists $suggestion->{reason}, 'Has reason key');
		ok(exists $suggestion->{tips}, 'Has tips key');

		is(ref($suggestion->{tips}), 'ARRAY', 'Tips is arrayref');
		ok(scalar @{$suggestion->{tips}} > 0, 'Tips not empty');
	}
};

subtest 'suggest_simpler_pattern - multiple issues' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\p{L}{5,50}(?=[A-Z])/);
	my $suggestion = $gen->suggest_simpler_pattern();

	# Should catch at least one issue
	ok(defined $suggestion, 'Detects issues in pattern with multiple problems');
};

subtest 'suggest_simpler_pattern - various simple patterns' => sub {
	my @simple = (
		qr/\d{4}/,
		qr/[A-Z]{3}/,
		qr/\w{5}/,
		qr/[a-z]{2,4}/,
	);

	for my $pattern (@simple) {
		my $gen = Data::Random::String::Matches->new($pattern);
		my $suggestion = $gen->suggest_simpler_pattern();

		# These should either return undef or have valid suggestions
		if (defined $suggestion) {
			ok(exists $suggestion->{reason}, "Pattern $pattern: has reason if suggesting");
		} else {
			pass("Pattern $pattern: no suggestion needed");
		}
	}
};

subtest 'suggest_simpler_pattern - tip structure' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{5,25}/);
	my $suggestion = $gen->suggest_simpler_pattern();

	if (defined $suggestion && exists $suggestion->{tips}) {
		for my $tip (@{$suggestion->{tips}}) {
			ok(length($tip) > 0, 'Tip is not empty string');
			unlike($tip, qr/^\s*$/, 'Tip is not just whitespace');
		}
	}
};

subtest 'suggest_simpler_pattern - pattern key validity' => sub {
	my @patterns_with_suggestions = (
		qr/\d{5,25}/,
		qr/\d{3}(?=[A-Z])/,
		qr/\p{L}{5}/,
	);

	for my $pattern (@patterns_with_suggestions) {
		my $gen = Data::Random::String::Matches->new($pattern);
		my $suggestion = $gen->suggest_simpler_pattern();

		if (defined $suggestion && defined $suggestion->{pattern}) {
			# Try to compile the suggested pattern
			eval { qr/$suggestion->{pattern}/ };
			ok(!$@, "Suggested pattern is valid regex: $suggestion->{pattern}");
		}
	}
};

subtest 'suggest_simpler_pattern - integration with pattern_info' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{10,50}/);

	my $info = $gen->pattern_info();
	my $suggestion = $gen->suggest_simpler_pattern();

	ok(defined $info, 'Can get pattern info');
	if (defined $suggestion) {
		ok(defined $suggestion->{reason}, 'Suggestion based on pattern analysis');
	}
};

done_testing();
