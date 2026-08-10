#!/usr/bin/env perl

# Locale portability tests.
#
# GEOGRAPHIC: verify that the caching layer correctly handles locale-dependent
# country lookups via Locale::Country::Multilingual, concurrent instances,
# and case-sensitive key storage.
#
# POSIX: verify that our croak/carp messages are locale-independent -- they
# must not contain OS-sourced strings that would change under different LC_ALL
# settings.

use strict;
use warnings;
use autodie qw(:all);

use POSIX qw(LC_ALL setlocale ENOENT);
use Test::Most;
use Test::DescribeMe qw(extended);

# ---------------------------------------------------------------------------
# GEOGRAPHIC subtests (Locale::Country::Multilingual)
# ---------------------------------------------------------------------------
GEOGRAPHIC: {
	my $lcm_ok = eval { require Locale::Country::Multilingual; 1 };
	if(!$lcm_ok) {
		note('Locale::Country::Multilingual not installed -- skipping geographic subtests');
		last GEOGRAPHIC;
	}

	require Class::Simple::Readonly::Cached;
	my $cache_a = {};
	my $cache_b = {};

	# Sanity subtest: if the country mapping is broken, all subsequent
	# geographic tests would produce false positives.  BAIL_OUT stops
	# the entire suite, not just this block.
	subtest 'LCM sanity: US maps to United States' => sub {
		my $lcm = Locale::Country::Multilingual->new();
		my $name = $lcm->code2country('US');
		BAIL_OUT('LCM mapping broken: US does not resolve to "United States"')
			unless defined($name) && $name eq 'United States';
		pass('LCM country mapping is sane');
	};

	# Two independent instances with separate caches.
	my $inst_a = Class::Simple::Readonly::Cached->new(
		cache  => $cache_a,
		object => Locale::Country::Multilingual->new(),
	);
	my $inst_b = Class::Simple::Readonly::Cached->new(
		cache  => $cache_b,
		object => Locale::Country::Multilingual->new(),
	);

	# Country codes and expected English names under all five target locales.
	my %expected_en = (
		GB => 'United Kingdom',
		US => 'United States',
		FR => 'France',
		DE => 'Germany',
		CN => 'China',
	);

	subtest 'English lookups via instance A (first call = miss)' => sub {
		for my $code (sort keys %expected_en) {
			is($inst_a->code2country($code), $expected_en{$code}, "EN $code");
		}
	};

	subtest 'English lookups via instance A (second call = hit)' => sub {
		for my $code (sort keys %expected_en) {
			is($inst_a->code2country($code), $expected_en{$code}, "cached EN $code");
		}
		my $hits = $inst_a->state()->{hits} // {};
		my $n = 0;
		$n += $_ for values %{$hits};
		cmp_ok($n, '>=', scalar(keys %expected_en),
			'at least 5 hits after re-fetching all 5 codes');
	};

	# French lookups through instance B use different arg tuples, so they
	# produce distinct cache keys from the English lookups above.
	my %expected_fr = (
		US => "\x{c9}tats-Unis",
		FR => 'France',
		DE => 'Allemagne',
	);

	subtest 'French lookups via instance B' => sub {
		for my $code (sort keys %expected_fr) {
			is($inst_b->code2country($code, 'fr_FR'),
				$expected_fr{$code}, "FR $code");
		}
	};

	# Cache keys are built from the exact argument values: 'US' and 'us' are
	# stored under different keys (LCM codes are case-sensitive).
	subtest 'Cache key is case-sensitive (stores args verbatim)' => sub {
		my $upper = $inst_a->code2country('US');
		is($upper, 'United States', 'uppercase code works');
		ok(exists $cache_a->{'Class::Simple::Readonly::Cached::code2country::US'},
			'cache stores key with exact arg casing');
	};

	# Hits on instance A must not affect instance B's counters.
	subtest 'Concurrent instances are fully isolated' => sub {
		my $ha = do { my $n=0; $n += $_ for values %{$inst_a->state()->{hits} // {}}; $n };
		my $hb = do { my $n=0; $n += $_ for values %{$inst_b->state()->{hits} // {}}; $n };
		cmp_ok($ha, '>', 0, 'instance A has at least one hit');
		isnt($ha, $hb, 'hit counters differ between instances (independent state)');
	};
}

# ---------------------------------------------------------------------------
# POSIX locale subtests
# ---------------------------------------------------------------------------
POSIX_LOCALES: {
	require Class::Simple::Readonly::Cached;

	# Only locales actually installed on this system will be testable.
	my @candidate_locales = ('en_US.UTF-8', 'en_US.utf8', 'de_DE.UTF-8', 'ja_JP.UTF-8', 'C.UTF-8', 'C.utf8');
	my @available;
	for my $loc (@candidate_locales) {
		my $prev = setlocale(LC_ALL);
		my $ok   = setlocale(LC_ALL, $loc);
		if(defined($ok)) {
			push @available, $loc;
		}
		setlocale(LC_ALL, $prev);   # restore
	}

	if(!@available) {
		note('No suitable locales available -- skipping POSIX locale subtests');
		last POSIX_LOCALES;
	}

	for my $locale (@available) {
		subtest "Error messages are locale-independent under $locale" => sub {
			my $prev = setlocale(LC_ALL);
			setlocale(LC_ALL, $locale);

			# Source the OS error string directly from Perl's $! layer.
			# Never use POSIX::strerror -- it may diverge from Perl's
			# stringification of $! under some locale configurations.
			local $! = ENOENT;
			my $os_error = "$!";

			# Our croak messages are hard-coded ASCII; they must not vary
			# with locale and must not include any $!-derived string.
			my $err;
			eval { Class::Simple::Readonly::Cached->new(cache => 'not_a_ref') };
			$err = "$@";

			setlocale(LC_ALL, $prev);   # always restore before assertions

			ok(length($err), "new() with bad cache croaks under $locale");
			like($err, qr/Cache must be ref to HASH or object/,
				"croak text is the expected ASCII literal under $locale");
			unlike($err, qr/\Q$os_error\E/,
				"croak text does not contain any OS error string under $locale");
		};
	}
}

done_testing();
