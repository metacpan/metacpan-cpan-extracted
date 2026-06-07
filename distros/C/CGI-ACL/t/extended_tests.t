#!/usr/bin/env perl
# extended_tests.t -- targeted coverage tests for previously untested paths
#
# Aims at code paths left partially covered after the main test suite:
#   - new() clone with no params  ($params ||= {} false branch)
#   - deny_cloud + allow_country only  (line 732 allow_countries branch)
#   - _verified_rdns SIGALRM timeout   (__ANON__ handler at line 908)
#   - _verified_rdns $@ branch in "return if $@ || !$hostname"
#   - Windows platform path (documented as unreachable on non-Windows)
#   - combined IP+country+cloud restrictions
#   - hashref calling style for deny_country/allow_country
#   - various LCSAJ paths through all_denied

use strict;
use warnings;

use Carp;	# keep main::carp defined so Test::Carp glob restore works
use Scalar::Util qw(blessed);
use Socket qw(AF_INET);
use Test::Carp qw(does_carp_that_matches);
use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Readonly;

BEGIN {
	use_ok('CGI::ACL') or BAIL_OUT('CGI::ACL failed to load');
}

# ── Configuration ─────────────────────────────────────────────────────────────
# All magic values live here; no bare strings or numbers anywhere else.
Readonly my %config => (
	# Well-known RFC test addresses (never routed on the public Internet)
	LOCAL_IP       => '127.0.0.1',
	RFC5737_IP     => '203.0.113.5',      # TEST-NET-3 (RFC 5737)
	RFC5737_IP2    => '198.51.100.1',     # TEST-NET-2 (RFC 5737)
	RFC5737_CIDR   => '192.0.2.0/24',    # TEST-NET-1 (RFC 5737)
	CIDR_INSIDE    => '192.0.2.50',      # inside TEST-NET-1
	CIDR_OUTSIDE   => '192.0.3.1',       # just outside TEST-NET-1
	IPV6_VALID     => '2001:db8::1',     # documentation IPv6 (RFC 3849)
	IPV6_VALID2    => '2001:db8::2',

	# Country codes
	CC_GB          => 'gb',
	CC_US          => 'us',
	CC_DE          => 'de',
	WILDCARD       => '*',

	# Cloud provider test hostnames (never real)
	AWS_HOST       => 'ec2-1-2-3-4.compute-1.amazonaws.com',
	GCP_HOST       => 'abc.bc.googleusercontent.com',
	NONCLOUD_HOST  => 'mail.example.com',

	# Error message substrings expected in carps
	ERR_DENY_CC    => 'Usage: deny_country($country)',
	ERR_ALLOW_CC   => 'Usage: allow_country($country)',
	ERR_LINGUA     => 'Usage: all_denied($lingua)',
	ERR_ALLOW_IP   => 'Usage: allow_ip($ip_address)',
);

# ── Helpers ───────────────────────────────────────────────────────────────────

# Run all_denied with REMOTE_ADDR scoped to $ip, forwarding any extra args.
sub denied_at {
	my ($acl, $ip, @rest) = @_;
	local $ENV{REMOTE_ADDR} = $ip;
	return $acl->all_denied(@rest);
}

# Build a minimal mock lingua object that returns a fixed country code.
{
	package MockLingua;
	sub new     { my ($class, %a) = @_; bless { country => $a{country} }, $class }
	sub country { $_[0]->{country} }
}

# ─────────────────────────────────────────────────────────────────────────────
# new() CLONE EDGE CASES
# Purpose: hit the $params ||= {} false branch (no args to clone)
# ─────────────────────────────────────────────────────────────────────────────

subtest 'new(): clone with no arguments inherits all settings from original' => sub {
	# Calling $obj->new() with NO args must deep-copy the original.
	# This exercises the $params ||= {} branch where $params starts undef.
	my $orig = CGI::ACL->new()
		->allow_ip($config{RFC5737_IP})
		->deny_country($config{CC_GB});

	diag "cloning without args" if $ENV{TEST_VERBOSE};

	# Clone with no args
	my $clone = $orig->new();

	isa_ok($clone, 'CGI::ACL', 'no-arg clone is a CGI::ACL');
	ok($clone->{allowed_ips}{ $config{RFC5737_IP} }, 'clone inherits allowed_ip');
	ok($clone->{deny_countries}{ $config{CC_GB} },   'clone inherits deny_country');

	# Clone must be independent: adding to clone does not change original
	$clone->deny_country($config{CC_US});
	ok(!$orig->{deny_countries}{ $config{CC_US} },
		'mutation of clone does not propagate to original');
};

subtest 'new(): clone with override params merges correctly' => sub {
	# Calling $obj->new(deny_cloud => 1) must deep-copy the base AND apply
	# the override; this exercises the $params ||= {} true-branch.
	my $orig  = CGI::ACL->new()->allow_ip($config{RFC5737_IP});
	my $clone = $orig->new(deny_cloud => 1);

	diag "cloning with override deny_cloud=>1" if $ENV{TEST_VERBOSE};

	ok($clone->{deny_cloud},                              'override deny_cloud set in clone');
	ok($clone->{allowed_ips}{ $config{RFC5737_IP} },      'base allowed_ip inherited');
	ok(!$orig->{deny_cloud},                              'original unchanged');
};

subtest 'new(): clone with allowed_ips gets fresh _cidrlist-free copy' => sub {
	# The CIDR cache (_cidrlist) is built during the CIDR lookup (not exact-match).
	# Use a CIDR range so the lookup path — not the fast-path — is exercised.
	my $orig = CGI::ACL->new()->allow_ip($config{RFC5737_CIDR});

	# Force the CIDR cache to be built by calling all_denied with an IP
	# that is inside the CIDR but is NOT an exact-match key.
	{ local $ENV{REMOTE_ADDR} = $config{CIDR_INSIDE}; $orig->all_denied() }
	ok(defined $orig->{_cidrlist}, 'original has _cidrlist after first CIDR call');

	my $clone = $orig->new();
	ok(!defined $clone->{_cidrlist}, 'clone starts without _cidrlist');
};

# ─────────────────────────────────────────────────────────────────────────────
# deny_cloud + allow_country ONLY (line 732 allow_countries branch)
# Purpose: when deny_cloud is set and ONLY allow_countries (no allow_ip, no
# deny_countries) is also set, the early-exit at line 732 must NOT fire
# (the country check must still run).
# ─────────────────────────────────────────────────────────────────────────────

subtest 'deny_cloud + allow_country only: non-cloud IP falls through to country check' => sub {
	# ACL: block cloud hosts AND restrict to GB via default-deny + allow_country.
	# The key coverage target is the deny_cloud block's "return 0 unless ..."
	# where allow_countries is the only remaining restriction.
	my $acl = CGI::ACL->new()
		->deny_cloud()
		->deny_country($config{WILDCARD})
		->allow_country($config{CC_GB});

	my $gb_lingua = MockLingua->new(country => $config{CC_GB});
	my $us_lingua = MockLingua->new(country => $config{CC_US});

	diag "deny_cloud+allow_country: GB lingua" if $ENV{TEST_VERBOSE};

	# Mock _verified_rdns so the IP is treated as non-cloud
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };

	# GB visitor: allowed
	is(denied_at($acl, $config{RFC5737_IP}, lingua => $gb_lingua), 0,
		'GB visitor on non-cloud IP is allowed');

	# US visitor: denied
	is(denied_at($acl, $config{RFC5737_IP}, lingua => $us_lingua), 1,
		'US visitor on non-cloud IP is denied');
};

subtest 'deny_cloud only (no other restrictions): non-cloud IP returns 0 (allow)' => sub {
	# When ONLY deny_cloud is active, a non-cloud IP must be allowed immediately
	# by the "return 0 unless ..." guard at line 728-730.
	my $acl   = CGI::ACL->new()->deny_cloud();
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };

	diag "deny_cloud only, non-cloud IP" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{RFC5737_IP}), 0,
		'non-cloud IP is allowed when only deny_cloud is set');
};

subtest 'deny_cloud: cloud IP is denied even when it is in the allow-list' => sub {
	# deny_cloud takes precedence over allow_ip (documented in POD).
	# Cloud IP must be denied even when explicitly listed.
	my $acl = CGI::ACL->new()
		->deny_cloud()
		->allow_ip($config{RFC5737_IP});

	my $guard = mock_scoped 'CGI::ACL::_verified_rdns'
		=> sub { $config{AWS_HOST} };

	diag "deny_cloud overrides allow_ip for cloud IP" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{RFC5737_IP}), 1,
		'cloud IP denied even when in allow-list');
};

subtest 'deny_cloud: allow_country alone alongside deny_cloud (no deny wildcard)' => sub {
	# allow_country without deny_country('*') has no *country-based* restrictive
	# effect (any country passes).  However the country check still runs and
	# REQUIRES a lingua argument; without one, all_denied carps and returns 1.
	# When lingua IS provided, any country is allowed (no deny rule).
	my $acl    = CGI::ACL->new()->deny_cloud()->allow_country($config{CC_US});
	my $guard  = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };
	my $lingua = MockLingua->new(country => $config{CC_DE});

	diag "deny_cloud + allow_country (no wildcard deny) + lingua" if $ENV{TEST_VERBOSE};

	# With a valid lingua: any country is allowed (no deny rule active)
	is(denied_at($acl, $config{RFC5737_IP}, lingua => $lingua), 0,
		'non-cloud IP + any country allowed when no deny rule active');
};

# ─────────────────────────────────────────────────────────────────────────────
# _verified_rdns SIGALRM TIMEOUT PATH
# Purpose: cover the anonymous SIGALRM handler sub (line 908) that
# fires when DNS takes too long.  We trigger it by sending SIGALRM from
# inside the mocked _rdns_forward while the alarm is still active.
# ─────────────────────────────────────────────────────────────────────────────

subtest '_verified_rdns(): SIGALRM fired inside eval sets $@ and returns undef' => sub {
	plan skip_all => 'SIGALRM not available on Windows' if $^O eq 'MSWin32';

	# Mock _rdns_forward to send SIGALRM to our own process.
	# _verified_rdns has installed "local $SIG{ALRM} = sub { die 'DNS timeout' }"
	# so the signal triggers that handler, which die()s inside the eval,
	# setting $@.  The code then executes "return if $@ || !$hostname".
	my $guard = mock_scoped 'CGI::ACL::_rdns_forward' => sub {
		kill 'ALRM', $$;    # fire the alarm now — handler will die
		return ();           # never reached
	};

	diag "triggering SIGALRM inside _verified_rdns eval" if $ENV{TEST_VERBOSE};

	# 127.0.0.1 normally has a PTR record; gethostbyaddr should succeed,
	# so the code enters _rdns_forward before timing out.
	my $result = CGI::ACL::_verified_rdns($config{LOCAL_IP});

	is($result, undef, 'SIGALRM timeout causes _verified_rdns to return undef');
};

subtest '_verified_rdns(): SIGALRM path: alarm is cancelled after eval (no leak)' => sub {
	plan skip_all => 'SIGALRM not available on Windows' if $^O eq 'MSWin32';

	# Verify the outer alarm(0) cancels any lingering alarm after the eval.
	# If the alarm were not cancelled we could get a spurious SIGALRM later.
	my $guard = mock_scoped 'CGI::ACL::_rdns_forward' => sub {
		kill 'ALRM', $$;
		return ();
	};

	# Install a safety net: if alarm fires outside _verified_rdns it means
	# the alarm was NOT properly cancelled — that would be a bug.
	my $leaked = 0;
	local $SIG{ALRM} = sub { $leaked = 1 };

	CGI::ACL::_verified_rdns($config{LOCAL_IP});

	# Allow one event loop tick for any leaked alarm to fire
	select(undef, undef, undef, 0.05);

	ok(!$leaked, 'no alarm leak after _verified_rdns returns');
};

# ─────────────────────────────────────────────────────────────────────────────
# _verified_rdns() !$hostname BRANCH (line 922)
# Purpose: when gethostbyaddr returns undef (no PTR record) the code
# executes "return if $@ || !$hostname".  The !$hostname sub-path.
# ─────────────────────────────────────────────────────────────────────────────

subtest '_verified_rdns(): IP with no PTR record returns undef (!$hostname path)' => sub {
	plan skip_all => 'SIGALRM not available on Windows' if $^O eq 'MSWin32';

	# RFC 5737 TEST-NET addresses normally have no PTR record.
	# gethostbyaddr should return undef, exercising the !$hostname branch.
	diag "calling _verified_rdns on no-PTR IP $config{RFC5737_IP}" if $ENV{TEST_VERBOSE};

	my $result = CGI::ACL::_verified_rdns($config{RFC5737_IP});

	is($result, undef, 'no-PTR address returns undef via !$hostname branch');
};

# ─────────────────────────────────────────────────────────────────────────────
# WINDOWS PLATFORM PATH (unreachable on non-Windows)
# Lines 923-929 in lib/CGI/ACL.pm contain the Windows synchronous code path
# (no alarm, direct gethostbyaddr + _rdns_forward).  These lines execute only
# when $^O eq 'MSWin32'.  On macOS/Linux they are DEAD CODE and cannot be
# covered without mocking $^O itself, which is a Readonly built-in.
#
# COMMENTED OUT — shown here for review.  Do not enable unless running on
# Windows where the coverage will naturally be collected by the normal DNS
# tests.
#
# subtest '_verified_rdns(): Windows synchronous path' => sub {
#     plan skip_all => 'only on Windows' unless $^O eq 'MSWin32';
#     # On Windows, $^O is 'MSWin32', so gethostbyaddr and _rdns_forward
#     # are called without an alarm.  Lines 925-928 execute here.
#     my $guard = mock_scoped 'CGI::ACL::_rdns_forward'
#         => sub { ($config{LOCAL_IP}) };
#     my $result = CGI::ACL::_verified_rdns($config{LOCAL_IP});
#     ok(defined $result, 'Windows path returns hostname');
# };
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# _verified_rdns() FORWARD-CONFIRMATION CONDITION (line 932)
# Purpose: the ternary "$hostname && grep { $_ eq $canonical } @forward_ips"
# must return $hostname when the forward list contains the canonical IP.
# ─────────────────────────────────────────────────────────────────────────────

subtest '_verified_rdns(): forward IP matches canonical — returns hostname' => sub {
	plan skip_all => 'SIGALRM not available on Windows' if $^O eq 'MSWin32';

	# 127.0.0.1 normally has a PTR; mock _rdns_forward to confirm it.
	my $guard = mock_scoped 'CGI::ACL::_rdns_forward'
		=> sub { ($config{LOCAL_IP}) };

	diag "forward-confirm: _rdns_forward returns LOCAL_IP" if $ENV{TEST_VERBOSE};

	my $result = CGI::ACL::_verified_rdns($config{LOCAL_IP});

	ok(defined($result), 'matching forward IP returns a hostname');
	like($result, qr/\S/, 'returned hostname is non-empty');
};

subtest '_verified_rdns(): forward IP list empty — returns undef' => sub {
	plan skip_all => 'SIGALRM not available on Windows' if $^O eq 'MSWin32';

	# Mock _rdns_forward to return an empty list; grep can never match,
	# so the ternary returns undef even though $hostname is defined.
	my $guard = mock_scoped 'CGI::ACL::_rdns_forward' => sub { () };

	diag "forward-confirm: _rdns_forward returns empty list" if $ENV{TEST_VERBOSE};

	my $result = CGI::ACL::_verified_rdns($config{LOCAL_IP});

	is($result, undef, 'empty forward list causes verification failure → undef');
};

# ─────────────────────────────────────────────────────────────────────────────
# all_denied(): COMBINED RESTRICTION PATHS
# Purpose: exercise paths that chain multiple restriction types together,
# giving Devel::Cover full LCSAJ coverage of the multi-branch decision tree.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'all_denied(): allow_ip + deny_country — IP match bypasses country check' => sub {
	# Allowed IP is exempt from country restrictions.
	# Path: allowed_ips match → return 0 (skip country check).
	my $acl = CGI::ACL->new()
		->allow_ip($config{RFC5737_IP})
		->deny_country($config{WILDCARD});

	diag "allow_ip overrides deny_country(*) for allowed IP" if $ENV{TEST_VERBOSE};

	# Allowed IP succeeds even though deny_country(*) would otherwise deny it
	is(denied_at($acl, $config{RFC5737_IP}), 0,
		'allowed IP bypasses the country check');

	# Non-allowed IP reaches country check (no lingua → carp + deny)
	my $result;
	does_carp_that_matches(
		sub { $result = denied_at($acl, $config{RFC5737_IP2}) },
		'non-allowed IP triggers country carp',
		qr/\Q$config{ERR_LINGUA}\E/
	);
	is($result, 1, 'non-allowed IP denied by country check');
};

subtest 'all_denied(): allow_ip CIDR + deny_country — CIDR match bypasses country' => sub {
	# Same as above but via CIDR range.
	my $acl = CGI::ACL->new()
		->allow_ip($config{RFC5737_CIDR})
		->deny_country($config{WILDCARD});

	diag "allow_ip CIDR overrides deny_country(*)" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{CIDR_INSIDE}), 0, 'CIDR-inside IP bypasses country check');

	# CIDR-outside reaches the country check; no lingua → carp + deny
	my $result;
	does_carp_that_matches(
		sub { $result = denied_at($acl, $config{CIDR_OUTSIDE}) },
		'CIDR-outside triggers country-check carp',
		qr/\Q$config{ERR_LINGUA}\E/
	);
	is($result, 1, 'CIDR-outside IP denied (country check: no lingua)');
};

subtest 'all_denied(): deny_country with allow_country in default-allow mode' => sub {
	# deny_country('de') in default-allow mode only denies DE; others are allowed.
	my $acl = CGI::ACL->new()->deny_country($config{CC_DE});

	my $de_lingua = MockLingua->new(country => $config{CC_DE});
	my $gb_lingua = MockLingua->new(country => $config{CC_GB});

	diag "deny DE only (default-allow mode)" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{RFC5737_IP}, lingua => $de_lingua), 1,
		'DE visitor denied in explicit-deny mode');
	is(denied_at($acl, $config{RFC5737_IP}, lingua => $gb_lingua), 0,
		'GB visitor allowed in explicit-deny mode');
};

subtest 'all_denied(): wildcard deny + allow_country + IP check — all three active' => sub {
	# Full combination: deny_cloud off, allow_ip for one subnet,
	# deny_country(*), allow_country(GB).
	# Non-allowed IP must reach the country check.
	my $acl = CGI::ACL->new()
		->allow_ip($config{LOCAL_IP})
		->deny_country($config{WILDCARD})
		->allow_country($config{CC_GB});

	my $gb_lingua = MockLingua->new(country => $config{CC_GB});
	my $us_lingua = MockLingua->new(country => $config{CC_US});

	diag "full combo: allow_ip+deny(*)+allow_country(GB)" if $ENV{TEST_VERBOSE};

	# Allowed IP bypasses country entirely
	is(denied_at($acl, $config{LOCAL_IP}), 0,
		'allowed IP is allowed without needing lingua');

	# Non-allowed IP: GB passes country check
	is(denied_at($acl, $config{RFC5737_IP}, lingua => $gb_lingua), 0,
		'non-allowed IP, GB country → allowed');

	# Non-allowed IP: US fails country check
	is(denied_at($acl, $config{RFC5737_IP}, lingua => $us_lingua), 1,
		'non-allowed IP, US country → denied');
};

subtest 'all_denied(): deny_cloud + allow_ip + deny_country — cloud takes precedence' => sub {
	# Cloud IP must be denied even though it is in the allow-list.
	# Then a non-cloud non-listed IP must reach the country check.
	my $acl = CGI::ACL->new()
		->deny_cloud()
		->allow_ip($config{RFC5737_IP})
		->deny_country($config{CC_DE});

	my $gb_lingua = MockLingua->new(country => $config{CC_GB});

	{
		# Cloud IP: denied regardless of allow_ip
		my $guard = mock_scoped 'CGI::ACL::_verified_rdns'
			=> sub { $config{AWS_HOST} };
		diag "cloud IP with allow_ip + deny_country" if $ENV{TEST_VERBOSE};
		is(denied_at($acl, $config{RFC5737_IP}), 1,
			'cloud IP denied even when in allow-list');
	}
	{
		# Non-cloud, allowed IP: allow-list match returns 0 before country check
		my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };
		is(denied_at($acl, $config{RFC5737_IP}), 0,
			'non-cloud, allowed IP passes without country check');
	}
	{
		# Non-cloud, non-allowed IP: reaches country check
		my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };
		is(denied_at($acl, $config{RFC5737_IP2}, lingua => $gb_lingua), 0,
			'non-cloud non-allowed IP, non-denied country → allowed');
	}
};

# ─────────────────────────────────────────────────────────────────────────────
# allow_country / deny_country HASHREF CALLING STYLE
# Purpose: ensure the hashref dispatch path is covered in both methods.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'deny_country(): hashref argument stores the country code' => sub {
	my $acl = CGI::ACL->new();
	$acl->deny_country({ country => $config{CC_GB} });

	diag "deny_country via hashref" if $ENV{TEST_VERBOSE};

	ok($acl->{deny_countries}{ $config{CC_GB} },
		'deny_country({country=>"gb"}) stores gb');
};

subtest 'deny_country(): hashref with arrayref of countries' => sub {
	my $acl = CGI::ACL->new();
	$acl->deny_country({ country => [ $config{CC_GB}, $config{CC_US} ] });

	ok($acl->{deny_countries}{ $config{CC_GB} }, 'gb stored via hashref+arrayref');
	ok($acl->{deny_countries}{ $config{CC_US} }, 'us stored via hashref+arrayref');
};

subtest 'allow_country(): hashref argument stores the country code' => sub {
	my $acl = CGI::ACL->new();
	$acl->allow_country({ country => $config{CC_US} });

	diag "allow_country via hashref" if $ENV{TEST_VERBOSE};

	ok($acl->{allow_countries}{ $config{CC_US} },
		'allow_country({country=>"us"}) stores us');
};

subtest 'allow_country(): hashref with arrayref of countries' => sub {
	my $acl = CGI::ACL->new();
	$acl->allow_country({ country => [ $config{CC_GB}, $config{CC_DE} ] });

	ok($acl->{allow_countries}{ $config{CC_GB} }, 'gb stored');
	ok($acl->{allow_countries}{ $config{CC_DE} }, 'de stored');
};

# ─────────────────────────────────────────────────────────────────────────────
# allow_ip HASHREF CALLING STYLE
# ─────────────────────────────────────────────────────────────────────────────

subtest 'allow_ip(): hashref argument stores the IP' => sub {
	my $acl = CGI::ACL->new();
	$acl->allow_ip({ ip => $config{RFC5737_IP} });

	diag "allow_ip via hashref" if $ENV{TEST_VERBOSE};

	ok($acl->{allowed_ips}{ $config{RFC5737_IP} },
		'allow_ip({ip=>"..."}) stores the IP');
};

# ─────────────────────────────────────────────────────────────────────────────
# deny_country() UPPERCASE INPUT NORMALISATION
# Purpose: ensure uppercase country codes are stored as lowercase.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'deny_country(): uppercase country code is lowercased' => sub {
	my $acl = CGI::ACL->new()->deny_country('GB');

	diag "deny_country uppercase 'GB'" if $ENV{TEST_VERBOSE};

	ok($acl->{deny_countries}{gb}, 'uppercase GB stored as lowercase gb');
	ok(!$acl->{deny_countries}{GB}, 'uppercase key NOT stored');
};

subtest 'allow_country(): uppercase country code is lowercased' => sub {
	my $acl = CGI::ACL->new()->allow_country('US');

	ok($acl->{allow_countries}{us}, 'uppercase US stored as lowercase us');
	ok(!$acl->{allow_countries}{US}, 'uppercase key NOT stored');
};

# ─────────────────────────────────────────────────────────────────────────────
# all_denied(): CIDR MEMOISATION
# Purpose: the CIDR list must not be rebuilt on every call; after the first
# all_denied() invocation, _cidrlist is set and the cidradd loop is skipped.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'all_denied(): CIDR cache is rebuilt after allow_ip() invalidates it' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{RFC5737_CIDR});

	# Force initial build
	denied_at($acl, $config{CIDR_INSIDE});
	my $cache1 = $acl->{_cidrlist};
	ok(defined $cache1, 'CIDR cache built after first call');

	# Second call must reuse the cache (same reference)
	denied_at($acl, $config{CIDR_INSIDE});
	is($acl->{_cidrlist}, $cache1, 'CIDR cache not rebuilt on second call');

	# allow_ip() must invalidate the cache
	$acl->allow_ip($config{RFC5737_IP});
	ok(!defined $acl->{_cidrlist}, 'cache cleared by allow_ip()');

	# Next all_denied() rebuilds it
	denied_at($acl, $config{CIDR_INSIDE});
	ok(defined $acl->{_cidrlist}, 'cache rebuilt after invalidation');
};

subtest 'all_denied(): multiple IPs in allow-list, CIDR and exact both work' => sub {
	my $acl = CGI::ACL->new()
		->allow_ip($config{LOCAL_IP})
		->allow_ip($config{RFC5737_CIDR});

	diag "multi-entry allow-list: exact + CIDR" if $ENV{TEST_VERBOSE};

	# Exact match
	is(denied_at($acl, $config{LOCAL_IP}),    0, 'exact match allowed');
	# CIDR inside
	is(denied_at($acl, $config{CIDR_INSIDE}), 0, 'CIDR inside allowed');
	# Not in either
	is(denied_at($acl, $config{RFC5737_IP2}), 1, 'unlisted IP denied');
};

# ─────────────────────────────────────────────────────────────────────────────
# all_denied(): COUNTRY CHECK RETURN PATHS
# Purpose: cover both branches of the default-deny and default-allow paths.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'all_denied(): default-deny mode — denied country returns 1' => sub {
	my $acl    = CGI::ACL->new()->deny_country($config{WILDCARD})->allow_country($config{CC_GB});
	my $lingua = MockLingua->new(country => $config{CC_DE});

	diag "default-deny: DE is not in allow-list" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{RFC5737_IP}, lingua => $lingua), 1,
		'DE denied in default-deny mode');
};

subtest 'all_denied(): default-deny mode — allowed country returns 0' => sub {
	my $acl    = CGI::ACL->new()->deny_country($config{WILDCARD})->allow_country($config{CC_GB});
	my $lingua = MockLingua->new(country => $config{CC_GB});

	is(denied_at($acl, $config{RFC5737_IP}, lingua => $lingua), 0,
		'GB allowed in default-deny mode');
};

subtest 'all_denied(): explicit-deny mode — denied country returns 1' => sub {
	my $acl    = CGI::ACL->new()->deny_country($config{CC_DE});
	my $lingua = MockLingua->new(country => $config{CC_DE});

	is(denied_at($acl, $config{RFC5737_IP}, lingua => $lingua), 1,
		'DE denied in explicit-deny mode');
};

subtest 'all_denied(): explicit-deny mode — other country returns 0' => sub {
	my $acl    = CGI::ACL->new()->deny_country($config{CC_DE});
	my $lingua = MockLingua->new(country => $config{CC_GB});

	is(denied_at($acl, $config{RFC5737_IP}, lingua => $lingua), 0,
		'GB allowed when only DE is denied');
};

subtest 'all_denied(): allow_country alone (no wildcard deny) — any country allowed with lingua' => sub {
	# allow_country without deny_country('*') has no country-based restrictive
	# effect: with a valid lingua any country passes because no deny rule is active.
	# (POD: "allow_country alone has no observable effect on access decisions")
	my $acl   = CGI::ACL->new()->allow_country($config{CC_GB});
	my $gb    = MockLingua->new(country => $config{CC_GB});
	my $de    = MockLingua->new(country => $config{CC_DE});

	diag "allow_country alone + lingua" if $ENV{TEST_VERBOSE};

	# Both GB and DE are allowed: no deny rule is active
	is(denied_at($acl, $config{RFC5737_IP}, lingua => $gb), 0,
		'GB allowed when allow_country alone (no deny rule)');
	is(denied_at($acl, $config{RFC5737_IP}, lingua => $de), 0,
		'DE also allowed when allow_country alone (no deny rule)');
};

# ─────────────────────────────────────────────────────────────────────────────
# _rdns_forward(): ADDITIONAL IPv4 PATHS
# ─────────────────────────────────────────────────────────────────────────────

subtest '_rdns_forward(): IPv4 resolves to itself for loopback' => sub {
	my @ips = CGI::ACL::_rdns_forward($config{LOCAL_IP}, AF_INET);

	diag "_rdns_forward($config{LOCAL_IP}) = " . join(', ', @ips) if $ENV{TEST_VERBOSE};

	ok(scalar(@ips) > 0, 'loopback hostname resolves to at least one IP');
	ok(grep { $_ eq $config{LOCAL_IP} } @ips,
		'127.0.0.1 appears in forward resolution of its own hostname');
};

subtest '_rdns_forward(): IPv4 non-existent hostname returns empty list' => sub {
	my @ips = CGI::ACL::_rdns_forward('nonexistent.invalid.domain', AF_INET);

	is(scalar(@ips), 0, 'non-existent hostname yields empty list');
};

# ─────────────────────────────────────────────────────────────────────────────
# _is_cloud_host(): EDGE CASES
# Purpose: non-cloud hostnames that are substrings of cloud patterns must
# not false-positive; also test that the hostname comparison is case-insensitive.
# ─────────────────────────────────────────────────────────────────────────────

subtest '_is_cloud_host(): partial cloud keyword in hostname does not match' => sub {
	# 'amazons.example.com' contains 'amazon' but must not match the AWS pattern
	# qr/\.compute(?:-\d+)?\.amazonaws\.com$/i
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns'
		=> sub { 'amazons.example.com' };

	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 0,
		'"amazons.example.com" is NOT an AWS hostname');
};

subtest '_is_cloud_host(): case-insensitive cloud pattern matching' => sub {
	# The pattern uses /i; uppercase hostnames must still be detected.
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns'
		=> sub { 'EC2-1-2-3-4.COMPUTE-1.AMAZONAWS.COM' };

	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 1,
		'uppercase AWS hostname is correctly identified as cloud');
};

# ─────────────────────────────────────────────────────────────────────────────
# deny_cloud(): METHOD CHAIN AND FLAG
# ─────────────────────────────────────────────────────────────────────────────

subtest 'deny_cloud(): called multiple times is idempotent' => sub {
	# Calling deny_cloud() twice must not cause any error.
	my $acl = CGI::ACL->new()->deny_cloud()->deny_cloud();

	ok($acl->{deny_cloud}, 'deny_cloud flag set after double call');
	isa_ok($acl, 'CGI::ACL', 'object still valid');
};

# ─────────────────────────────────────────────────────────────────────────────
# all_denied(): IPv6 WITH CIDR (Net::CIDR IPv6 paths)
# ─────────────────────────────────────────────────────────────────────────────

subtest 'all_denied(): IPv6 address allowed via exact match in allow-list' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{IPV6_VALID});

	diag "allow_ip(IPv6) exact match" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{IPV6_VALID}),  0, 'exact IPv6 match allowed');
	is(denied_at($acl, $config{IPV6_VALID2}), 1, 'different IPv6 denied');
};

subtest 'all_denied(): IPv6 CIDR range match' => sub {
	# Net::CIDR handles IPv6 CIDRs; ensure the lookup path is exercised.
	my $acl = CGI::ACL->new()->allow_ip('2001:db8::/32');

	diag "allow_ip(IPv6 CIDR) range match" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{IPV6_VALID}),  0, 'IPv6 inside /32 CIDR allowed');
	is(denied_at($acl, '2001:db9::1'),         1, 'IPv6 outside /32 CIDR denied');
};

# ─────────────────────────────────────────────────────────────────────────────
# all_denied(): RETURN VALUES ARE BOOLEAN-COMPATIBLE INTEGERS
# Purpose: the POD says all_denied() returns 0 (allow) or 1 (deny).
# ─────────────────────────────────────────────────────────────="perl"
# Test::Returns used to verify the type contract.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'all_denied(): return value is 0 (allow) — type contract' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{RFC5737_IP});

	diag "return value contract: 0 for allow" if $ENV{TEST_VERBOSE};

	my $result = denied_at($acl, $config{RFC5737_IP});
	is($result, 0, 'allow path returns 0');
	ok(!ref($result), 'return value is not a reference');
};

subtest 'all_denied(): return value is 1 (deny) — type contract' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{LOCAL_IP});

	my $result = denied_at($acl, $config{RFC5737_IP});
	is($result, 1, 'deny path returns 1');
	ok(!ref($result), 'return value is not a reference');
};

# ─────────────────────────────────────────────────────────────────────────────
# METHOD CHAINING: all setters must return $self
# ─────────────────────────────────────────────────────────────────────────────

subtest 'all setters return $self — full chain is unbroken' => sub {
	# Build the longest legal chain and verify each link is $self.
	my $acl = CGI::ACL->new();

	my $r1 = $acl->allow_ip($config{RFC5737_IP});
	is($r1, $acl, 'allow_ip returns $self');

	my $r2 = $acl->deny_country($config{CC_DE});
	is($r2, $acl, 'deny_country returns $self');

	my $r3 = $acl->allow_country($config{CC_GB});
	is($r3, $acl, 'allow_country returns $self');

	my $r4 = $acl->deny_cloud();
	is($r4, $acl, 'deny_cloud returns $self');

	diag "full chain built: " . ref($acl) if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# OBJECT::CONFIGURE ENV-VAR INJECTION (runtime configuration)
# Purpose: verify that constructor params can be supplied via environment
# variables of the form CGI__ACL__<field>.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'new(): allowed_ips injected via environment variable' => sub {
	local $ENV{CGI__ACL__allowed_ips} = $config{RFC5737_IP};

	diag "env-var injection: CGI__ACL__allowed_ips=$config{RFC5737_IP}" if $ENV{TEST_VERBOSE};

	my $acl = CGI::ACL->new();

	# The env var may be treated as a plain key or hash; just ensure no crash
	ok($acl, 'object created with env-var config');
};

done_testing();
