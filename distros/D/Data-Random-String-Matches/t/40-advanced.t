#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

use_ok('Data::Random::String::Matches');

# Test alternation
subtest 'Alternation patterns' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(cat|dog|bird)/);

	my %seen;
	for (1..20) {
		my $str = $gen->generate_smart();
		ok($str =~ /^(cat|dog|bird)$/, "Generated string matches alternation: $str");
		$seen{$str}++;
	}

	# Should see at least 2 different alternatives
	cmp_ok(scalar keys %seen, '>=', 2, 'Generates different alternatives');
};

# Test nested alternation
subtest 'Nested alternation' => sub {
	my $gen = Data::Random::String::Matches->new(qr/((foo|bar)(baz|qux))/);
	my $str = $gen->generate_smart();

	like($str, qr/^(foo|bar)(baz|qux)$/, 'Nested alternation works');
};

# Test backreferences
subtest 'Backreferences' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(\w{3})-\1/);
	my $str = $gen->generate_smart();

	like($str, qr/^(\w{3})-\1$/, 'Backreference pattern matches');

	# Verify the backreference actually repeats
	my ($first, $second) = split /-/, $str;
	is($first, $second, 'Backreference generates same text');
};

# Test multiple backreferences
subtest 'Multiple backreferences' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(\d{2})-(\w{3})-\1-\2/);
	my $str = $gen->generate_smart();

	like($str, qr/^(\d{2})-(\w{3})-\1-\2$/, 'Multiple backreferences match');

	if ($str =~ /^(\d{2})-(\w{3})-(\d{2})-(\w{3})$/) {
		is($1, $3, 'First backreference matches');
		is($2, $4, 'Second backreference matches');
	}
};

# Test capturing groups
subtest 'Capturing groups' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(foo)(bar)/);
	my $str = $gen->generate_smart();

	is($str, 'foobar', 'Capturing groups concatenate correctly');
};

# Test non-capturing groups
subtest 'Non-capturing groups' => sub {
	my $gen = Data::Random::String::Matches->new(qr/(?:foo|bar)\d+/);
	my $str = $gen->generate_smart();

	like($str, qr/^(?:foo|bar)\d+$/, 'Non-capturing groups work');
};

# Test groups with quantifiers
subtest 'Groups with quantifiers' => sub {
	my $gen1 = Data::Random::String::Matches->new(qr/(ha){2}/);
	my $str1 = $gen1->generate_smart();
	is($str1, 'haha', 'Group with exact quantifier');

	my $gen2 = Data::Random::String::Matches->new(qr/(ho){2,3}/);
	my $str2 = $gen2->generate_smart();
	like($str2, qr/^(ho){2,3}$/, 'Group with range quantifier');
	ok($str2 eq 'hoho' || $str2 eq 'hohoho', 'Group repeats correctly');
};

# Test escape sequences
subtest 'Escape sequences' => sub {
	my $gen_d = Data::Random::String::Matches->new(qr/\d{3}/);
	my $str_d = $gen_d->generate_smart();
	like($str_d, qr/^\d{3}$/, '\d generates digits');

	my $gen_w = Data::Random::String::Matches->new(qr/\w{5}/);
	my $str_w = $gen_w->generate_smart();
	like($str_w, qr/^\w{5}$/, '\w generates word characters');

	my $gen_s = Data::Random::String::Matches->new(qr/\s/);
	my $str_s = $gen_s->generate_smart();
	like($str_s, qr/^\s$/, '\s generates whitespace');
};

# Test negated escape sequences
subtest 'Negated escape sequences' => sub {
	my $gen_D = Data::Random::String::Matches->new(qr/\D{3}/);
	my $str_D = $gen_D->generate_smart();
	like($str_D, qr/^\D{3}$/, '\D generates non-digits');
	unlike($str_D, qr/\d/, 'No digits in \D output');

	my $gen_W = Data::Random::String::Matches->new(qr/\W{3}/);
	my $str_W = $gen_W->generate_smart();
	like($str_W, qr/^\W{3}$/, '\W generates non-word characters');
};

# Test special escape sequences
subtest 'Special escape sequences' => sub {
	my $gen_t = Data::Random::String::Matches->new(qr/a\tb/);
	my $str_t = $gen_t->generate_smart();
	is($str_t, "a\tb", '\t generates tab');

	my $gen_n = Data::Random::String::Matches->new(qr/a\nb/);
	my $str_n = $gen_n->generate_smart();
	is($str_n, "a\nb", '\n generates newline');
};

# Test character classes with escape sequences
subtest 'Character classes with escape sequences' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[\d\w]{5}/);
	my $str = $gen->generate_smart();
	like($str, qr/^[\d\w]{5}$/, 'Character class with escape sequences');
};

# Test negated character classes
subtest 'Negated character classes' => sub {
	my $gen = Data::Random::String::Matches->new(qr/[^0-9]{5}/);
	my $str = $gen->generate_smart();
	like($str, qr/^[^0-9]{5}$/, 'Negated character class matches');
	unlike($str, qr/\d/, 'Negated class contains no digits');
};

# Test complex quantifiers
subtest 'Complex quantifiers' => sub {
	my $gen_plus = Data::Random::String::Matches->new(qr/a+/);
	my $str_plus = $gen_plus->generate_smart();
	like($str_plus, qr/^a+$/, '+ quantifier works');
	cmp_ok(length($str_plus), '>=', 1, 'Plus generates at least one');

	my $gen_star = Data::Random::String::Matches->new(qr/ab*c/);
	my $str_star = $gen_star->generate_smart();
	like($str_star, qr/^ab*c$/, '* quantifier works');

	my $gen_question = Data::Random::String::Matches->new(qr/colou?r/);
	my $str_question = $gen_question->generate_smart();
	like($str_question, qr/^colou?r$/, '? quantifier works');
	ok($str_question eq 'color' || $str_question eq 'colour', 'Optional character handled');
};

# Test dot metacharacter
subtest 'Dot metacharacter' => sub {
	my $gen = Data::Random::String::Matches->new(qr/a.b/);
	my $str = $gen->generate_smart();
	like($str, qr/^a.b$/, 'Dot matches any character');
	is(length($str), 3, 'Dot generates exactly one character');
};

# Test complex real-world patterns
subtest 'Real-world patterns' => sub {
	# Email-like
	my $gen_email = Data::Random::String::Matches->new(qr/[a-z]{3,8}@[a-z]{3,8}\.com/);
	my $email = $gen_email->generate_smart();
	like($email, qr/^[a-z]{3,8}@[a-z]{3,8}\.com$/, 'Email-like pattern');

	# Phone number
	my $gen_phone = Data::Random::String::Matches->new(qr/\d{3}-\d{3}-\d{4}/);
	my $phone = $gen_phone->generate_smart();
	like($phone, qr/^\d{3}-\d{3}-\d{4}$/, 'Phone number pattern');

	# API key (from earlier test)
	my $gen_api = Data::Random::String::Matches->new(qr/^AIza[0-9A-Za-z_-]{35}$/);
	my $api_key = $gen_api->generate_smart();
	like($api_key, qr/^AIza[0-9A-Za-z_-]{35}$/, 'API key pattern');
	is(length($api_key), 39, 'API key has correct length');
};

# Test mixed features
subtest 'Mixed features' => sub {
	# Alternation with backreferences
	my $gen1 = Data::Random::String::Matches->new(qr/(cat|dog)-\1/);
	my $str1 = $gen1->generate_smart();

	like($str1, qr/^(cat|dog)-\1$/, 'Alternation with backreference');
	ok($str1 eq 'cat-cat' || $str1 eq 'dog-dog', 'Correct repetition');

	# Groups with character classes and quantifiers
	my $gen2 = Data::Random::String::Matches->new(qr/([A-Z]\d){3}/);
	my $str2 = $gen2->generate_smart();
	like($str2, qr/^([A-Z]\d){3}$/, 'Complex mixed pattern');
	is(length($str2), 6, 'Mixed pattern has correct length');
};

# Test edge cases
subtest 'Edge cases' => sub {
	# Empty alternation option
	my $gen1 = Data::Random::String::Matches->new(qr/a(|b)c/);
	my $str1 = $gen1->generate_smart();
	like($str1, qr/^a(|b)c$/, 'Alternation with empty option');
	ok($str1 eq 'ac' || $str1 eq 'abc', 'Empty alternation works');

	# Single character patterns
	my $gen2 = Data::Random::String::Matches->new(qr/x/);
	my $str2 = $gen2->generate_smart();
	is($str2, 'x', 'Single literal character');
};

# Test that generate() falls back correctly
subtest 'Generate fallback' => sub {
	my $gen = Data::Random::String::Matches->new(qr/\d{3}/, 3);

	lives_ok {
		my $str = $gen->generate();
		like($str, qr/^\d{3}$/, 'generate() produces matching string');
	} 'generate() works with fallback';
};

done_testing();
