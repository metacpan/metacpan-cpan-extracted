#!/usr/bin/env perl
# integration.t -- black-box end-to-end integration tests for CGI::ACL
#
# Tests multi-routine workflows and interaction with CGI::Lingua,
# Object::Configure, and Net::CIDR.  Mocking is kept to a minimum;
# real GeoIP lookups are used for country-detection scenarios.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Without::Module ();	# loaded without hiding any modules; used at runtime in one subtest
use Readonly;
use Scalar::Util qw(refaddr);
use Socket qw(AF_INET);

# Load the module under test (and key integration partners)
BEGIN {
	use_ok('CGI::ACL')           or BAIL_OUT('CGI::ACL failed to load');
	use_ok('CGI::Lingua')        or BAIL_OUT('CGI::Lingua failed to load');
	use_ok('Object::Configure')  or BAIL_OUT('Object::Configure failed to load');
}

# ── Configuration ────────────────────────────────────────────────────────────

# Fixed test values — no magic strings or numbers anywhere else in the file
Readonly my %config => (
	# RFC 5737 / RFC 3849 documentation addresses (safe to use in tests)
	RFC_IP_1          => '203.0.113.5',    # TEST-NET-3
	RFC_IP_2          => '198.51.100.1',   # TEST-NET-2
	RFC_CIDR          => '192.0.2.0/24',   # TEST-NET-1
	CIDR_INSIDE       => '192.0.2.42',     # inside RFC_CIDR
	CIDR_OUTSIDE      => '10.0.0.1',       # outside RFC_CIDR
	IPv6_ADDR         => '2001:db8::1',    # RFC 3849 documentation IPv6
	IPv6_ADDR2        => '2001:db8::2',    # second documentation IPv6
	LOCAL_IP          => '127.0.0.1',      # loopback

	# Real-world IPs with stable GeoIP registrations
	IP_GB             => '212.159.106.41', # F9 Broadband, United Kingdom
	IP_US             => '130.14.25.184',  # NCBI, United States
	IP_RU             => '87.226.159.0',   # Russian Federation

	# Country codes (lowercase per ISO 3166-1)
	COUNTRY_GB        => 'gb',
	COUNTRY_US        => 'us',
	COUNTRY_RU        => 'ru',
	COUNTRY_BR        => 'br',
	WILDCARD          => '*',

	# Cloud provider hostnames for mocking _verified_rdns
	AWS_HOST          => 'ec2-1-2-3-4.compute-1.amazonaws.com',
	GCP_HOST          => '203-0-113-5.bc.googleusercontent.com',
	NONCLOUD_HOST     => 'mail.example.com',
);

# ── Helpers ───────────────────────────────────────────────────────────────────

# Run all_denied() with a fixed REMOTE_ADDR without polluting the global env
sub denied_at {
	my ($acl, $addr, @rest) = @_;
	local $ENV{REMOTE_ADDR} = $addr;
	return $acl->all_denied(@rest);
}

# Per-run lingua cache: each IP address makes exactly one WHOIS query for the
# entire test run.  CGI::Lingua caches the resolved country inside the object;
# subsequent calls to country() on the cached object return the stored value
# without a new network round-trip.
#
# local $_ protects the caller's loop variable: CGI::Lingua and the WHOIS
# modules it calls use $_ internally (e.g. in grep/map inside
# Net::Whois::IANA), and without localisation that clobbers map/grep
# iterations in the calling code, producing scrambled results.
my %_lingua_cache;
sub lingua_for {
	my $addr = shift;
	unless(exists $_lingua_cache{$addr}) {
		local $_;
		local $ENV{REMOTE_ADDR} = $addr;
		my $l = CGI::Lingua->new(supported => ['en']);
		do { local $SIG{__WARN__} = sub {}; $l->country() };
		$_lingua_cache{$addr} = $l;
	}
	return $_lingua_cache{$addr};
}

# ── RIPE WHOIS availability check ─────────────────────────────────────────────
# Subtests that rely on RIPE-registered IPs (GB, RU) are wrapped in a SKIP
# block when RIPE's WHOIS server is rate-limiting.  ARIN (US) and APNIC (CN)
# use independent servers and are unaffected.
#
# Pre-resolve now so every subsequent lingua_for() call hits the cache and makes
# zero additional WHOIS requests.
my %_ripe_ips = map { $config{$_} => 1 } qw(IP_GB IP_RU);
my $ripe_ok = 1;

# Pre-resolve RIPE IPs once: populates the lingua cache and detects rate-limiting.
# Using lingua_for() here means zero additional WHOIS calls inside the subtests.
for my $ip (sort keys %_ripe_ips) {
	my $country = do { local $SIG{__WARN__} = sub {}; lingua_for($ip)->country() };
	unless(defined $country) {
		$ripe_ok = 0;
		last;
	}
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: SYNOPSIS workflow
# Purpose: the exact example from the module POD must work end-to-end
# ─────────────────────────────────────────────────────────────────────────────
subtest 'SYNOPSIS workflow: UK-only subnet site' => sub {
	# Build the ACL described in the SYNOPSIS
	my $acl = CGI::ACL->new()
		->deny_country($config{WILDCARD})
		->allow_country('GB')
		->allow_ip($config{RFC_CIDR});

	isa_ok($acl, 'CGI::ACL', 'ACL object created from SYNOPSIS chain');

	# UK IP inside the allowed CIDR passes both checks
	local $ENV{REMOTE_ADDR} = $config{CIDR_INSIDE};
	my $lingua = CGI::Lingua->new(supported => ['en']);
	diag "SYNOPSIS: CIDR inside, country=" . ($lingua->country() // 'undef') if $ENV{TEST_VERBOSE};

	# IP is in the allowed CIDR — access should be granted without checking country
	is($acl->all_denied(lingua => $lingua), 0, 'CIDR-inside IP is allowed');

	# US IP (not GB and not in allowed CIDR) must be denied
	local $ENV{REMOTE_ADDR} = $config{IP_US};
	my $us_lingua = lingua_for($config{IP_US});
	diag "SYNOPSIS: US IP, country=" . ($us_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};
	is($acl->all_denied(lingua => $us_lingua), 1, 'US IP denied (not in CIDR, not GB)');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: pure IP allow-list workflow
# Purpose: exercise allow_ip → all_denied end-to-end without country checks
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Pure IP workflow: exact match' => sub {
	my $acl = new_ok('CGI::ACL');
	$acl->allow_ip($config{RFC_IP_1});
	diag "allow_ip exact=$config{RFC_IP_1}" if $ENV{TEST_VERBOSE};

	# The exact address that was allowed must pass
	is(denied_at($acl, $config{RFC_IP_1}), 0, 'exact allowed IP is not denied');

	# Any other address must be rejected once an allow-list exists
	is(denied_at($acl, $config{RFC_IP_2}), 1, 'unlisted IP is denied');

	returns_ok(denied_at($acl, $config{RFC_IP_1}), { type => 'SCALAR', regex => qr/^[01]$/ }, 'return value schema ok');
};

# Purpose: CIDR range matching integrates correctly with Net::CIDR
subtest 'Pure IP workflow: CIDR range matching' => sub {
	my $acl = new_ok('CGI::ACL');
	$acl->allow_ip($config{RFC_CIDR});
	diag "allow_ip CIDR=$config{RFC_CIDR}" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{CIDR_INSIDE}),  0, 'IP inside CIDR range is allowed');
	is(denied_at($acl, $config{CIDR_OUTSIDE}), 1, 'IP outside CIDR range is denied');
};

# Purpose: verify Net::CIDR::cidrlookup is actually invoked for CIDR matches
subtest 'Pure IP workflow: Net::CIDR::cidrlookup is called for range lookup' => sub {
	# Spy on cidrlookup — the real function is still called (spy passes through)
	my $spy = spy 'Net::CIDR::cidrlookup';

	my $acl = CGI::ACL->new()->allow_ip($config{RFC_CIDR});

	# Trigger the CIDR path (non-exact match)
	denied_at($acl, $config{CIDR_INSIDE});

	my @calls = $spy->();
	diag "Net::CIDR::cidrlookup called " . scalar(@calls) . " time(s)" if $ENV{TEST_VERBOSE};
	ok(scalar @calls >= 1, 'Net::CIDR::cidrlookup was invoked for CIDR lookup');

	# First argument to cidrlookup must be the client address
	is($calls[0][1], $config{CIDR_INSIDE}, 'cidrlookup received the correct client IP');

	unmock('Net::CIDR', 'cidrlookup');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: incremental IP accumulation
# Purpose: adding IPs one-by-one must work correctly (cache is rebuilt each time)
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Stateful IP workflow: multiple allow_ip calls accumulate' => sub {
	my $acl = new_ok('CGI::ACL');

	# Before any allow_ip, no restrictions → allow all
	is(denied_at($acl, $config{RFC_IP_1}), 0, 'no restrictions: allow');

	# Add first IP — now ACL has a restriction
	$acl->allow_ip($config{RFC_IP_1});
	is(denied_at($acl, $config{RFC_IP_1}), 0, 'first IP is allowed after allow_ip');
	is(denied_at($acl, $config{RFC_IP_2}), 1, 'second IP still denied after first allow_ip');

	# Add second IP — both must now be accessible
	$acl->allow_ip($config{RFC_IP_2});
	diag "added two IPs: $config{RFC_IP_1} $config{RFC_IP_2}" if $ENV{TEST_VERBOSE};
	is(denied_at($acl, $config{RFC_IP_1}), 0, 'first IP still allowed');
	is(denied_at($acl, $config{RFC_IP_2}), 0, 'second IP now allowed');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: clone isolation (new() on an existing object)
# Purpose: modifying a clone must not affect the original, and vice versa
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Clone isolation: clone inherits state but is independent' => sub {
	# Build a base ACL with one restriction
	my $base = CGI::ACL->new()->deny_country($config{COUNTRY_BR});

	# Clone it — should carry the same restriction
	my $clone = $base->new();
	isa_ok($clone, 'CGI::ACL', 'clone is a CGI::ACL object');
	isnt(refaddr($clone), refaddr($base), 'clone is a different reference');

	# Both deny Brazil at this point
	local $ENV{REMOTE_ADDR} = $config{IP_GB};
	my $br_lingua = lingua_for($config{IP_RU});    # RU resolves, use as a denied country proxy
	diag "clone isolation: base deny_countries=" . join(',', sort keys %{$base->{deny_countries}}) if $ENV{TEST_VERBOSE};

	# Add a new country to the clone — must NOT affect the base
	$clone->deny_country($config{COUNTRY_RU});
	ok( $clone->{deny_countries}{ $config{COUNTRY_RU} }, 'clone has new denial');
	ok(!$base->{deny_countries}{ $config{COUNTRY_RU} },  'base is unaffected by clone change');

	# Add an IP to the base — must NOT appear in the clone
	$base->allow_ip($config{RFC_IP_1});
	ok( $base->{allowed_ips}{ $config{RFC_IP_1} },   'base has new IP');
	ok(!$clone->{allowed_ips}{ $config{RFC_IP_1} },  'clone is unaffected by base change') if $clone->{allowed_ips};
	ok(!defined($clone->{allowed_ips}),               'clone allowed_ips still undef') unless defined $clone->{allowed_ips};
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: concurrent multiple instances
# Purpose: two ACL objects with different configs must not interfere
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Concurrent instances: independent access policies' => sub {
	# ACL A allows only RFC_IP_1
	my $acl_a = CGI::ACL->new()->allow_ip($config{RFC_IP_1});

	# ACL B allows only RFC_IP_2
	my $acl_b = CGI::ACL->new()->allow_ip($config{RFC_IP_2});

	diag "ACL A allows $config{RFC_IP_1}, ACL B allows $config{RFC_IP_2}" if $ENV{TEST_VERBOSE};

	# Each must allow only its own IP
	is(denied_at($acl_a, $config{RFC_IP_1}), 0, 'ACL A allows its own IP');
	is(denied_at($acl_a, $config{RFC_IP_2}), 1, 'ACL A denies ACL B\'s IP');

	is(denied_at($acl_b, $config{RFC_IP_2}), 0, 'ACL B allows its own IP');
	is(denied_at($acl_b, $config{RFC_IP_1}), 1, 'ACL B denies ACL A\'s IP');

	# Modifying one must not change the other
	$acl_a->allow_ip($config{RFC_IP_2});
	is(denied_at($acl_b, $config{RFC_IP_1}), 1, 'ACL B still denies ACL A\'s IP after ACL A was modified');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: CGI::Lingua integration — country deny list
# Purpose: test real GeoIP lookup + deny_country working together
# ─────────────────────────────────────────────────────────────────────────────
subtest 'CGI::Lingua integration: deny_country with real GeoIP' => sub {
	plan skip_all => 'RIPE WHOIS rate-limited; run again later' unless $ripe_ok;

	my $acl = CGI::ACL->new()->deny_country($config{COUNTRY_RU});

	diag "RU country=" . (lingua_for($config{IP_RU})->country() // 'undef') if $ENV{TEST_VERBOSE};
	is(denied_at($acl, $config{IP_RU}, lingua => lingua_for($config{IP_RU})), 1, 'Russian IP is denied');

	diag "GB country=" . (lingua_for($config{IP_GB})->country() // 'undef') if $ENV{TEST_VERBOSE};
	is(denied_at($acl, $config{IP_GB}, lingua => lingua_for($config{IP_GB})), 0, 'UK IP is allowed');
};

# Purpose: wildcard deny with an explicit allow list
subtest 'CGI::Lingua integration: wildcard deny + allow_country workflow' => sub {
	# Deny everything except US
	my $acl = CGI::ACL->new()
		->deny_country($config{WILDCARD})
		->allow_country($config{COUNTRY_US});

	# US should be allowed
	local $ENV{REMOTE_ADDR} = $config{IP_US};
	my $us_lingua = CGI::Lingua->new(supported => ['en']);
	diag "US lingua->country=" . ($us_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};
	is($acl->all_denied(lingua => $us_lingua), 0, 'US is allowed by explicit permit');

	# UK is not in the permit list — must be denied
	local $ENV{REMOTE_ADDR} = $config{IP_GB};
	my $gb_lingua = CGI::Lingua->new(supported => ['en']);
	diag "GB lingua->country=" . ($gb_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};
	is($acl->all_denied(lingua => $gb_lingua), 1, 'GB denied (not in wildcard-deny permit list)');
};

# Purpose: lingua->country() is actually invoked when CGI::ACL checks countries
subtest 'CGI::Lingua integration: lingua->country() is called by all_denied' => sub {
	# Install a spy on CGI::Lingua::country — pass-through, just counts calls
	my $spy = spy 'CGI::Lingua::country';

	my $acl = CGI::ACL->new()->deny_country($config{COUNTRY_RU});

	local $ENV{REMOTE_ADDR} = $config{IP_GB};
	my $lingua = CGI::Lingua->new(supported => ['en']);

	# The spy must show that country() was called at least once by all_denied
	$acl->all_denied(lingua => $lingua);
	my @calls = $spy->();
	diag "lingua->country() call count: " . scalar @calls if $ENV{TEST_VERBOSE};
	ok(scalar @calls >= 1, 'lingua->country() was invoked by all_denied');

	unmock('CGI::Lingua', 'country');
};

# Purpose: multiple country restrictions in an arrayref work correctly
subtest 'CGI::Lingua integration: arrayref of denied countries' => sub {
	plan skip_all => 'RIPE WHOIS rate-limited; run again later' unless $ripe_ok;

	my $acl = CGI::ACL->new()->deny_country(country => [$config{COUNTRY_RU}, $config{COUNTRY_BR}]);
	diag "deny_countries: " . join(',', sort keys %{$acl->{deny_countries}}) if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{IP_RU}, lingua => lingua_for($config{IP_RU})), 1, 'Russian IP denied from arrayref list');
	is(denied_at($acl, $config{IP_GB}, lingua => lingua_for($config{IP_GB})), 0, 'UK IP allowed (not in deny list)');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: IP allow-list beats country restriction
# Purpose: when an IP is in the allow-list, country is not consulted
# ─────────────────────────────────────────────────────────────────────────────
subtest 'IP allow-list overrides country deny (IP match short-circuits country check)' => sub {
	plan skip_all => 'RIPE WHOIS rate-limited; run again later' unless $ripe_ok;

	my $acl = CGI::ACL->new()
		->deny_country($config{COUNTRY_GB})
		->allow_ip($config{IP_GB});

	# Explicitly allowed IP must not be denied despite the country rule
	diag "IP allow beats country deny: IP=$config{IP_GB} country=" . (lingua_for($config{IP_GB})->country() // 'undef') if $ENV{TEST_VERBOSE};
	is(denied_at($acl, $config{IP_GB}, lingua => lingua_for($config{IP_GB})), 0, 'explicitly allowed IP is not denied by country rule');

	# Non-GB, non-allowed IP: RU is not in the deny list so it should be allowed
	diag "non-GB, non-allowed IP: country=" . (lingua_for($config{IP_RU})->country() // 'undef') if $ENV{TEST_VERBOSE};
	is(denied_at($acl, $config{IP_RU}, lingua => lingua_for($config{IP_RU})), 0, 'non-GB non-allowed IP is allowed (only GB is denied)');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: deny_cloud integration
# Purpose: verify _is_cloud_host is invoked and cloud IPs are denied
# (DNS mocked to avoid network dependency)
# ─────────────────────────────────────────────────────────────────────────────
subtest 'deny_cloud workflow: cloud IP is denied (mocked DNS)' => sub {
	# Spy on _is_cloud_host to verify it is actually called
	my $cloud_spy = spy 'CGI::ACL::_is_cloud_host';

	# Mock _verified_rdns so no real DNS is needed
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		my $ip = $_[0];
		diag "_verified_rdns mocked: $ip" if $ENV{TEST_VERBOSE};
		return $config{AWS_HOST}      if $ip eq $config{RFC_IP_1};
		return $config{NONCLOUD_HOST} if $ip eq $config{RFC_IP_2};
		return undef;
	};

	my $acl = CGI::ACL->new()->deny_cloud();

	# Cloud IP must be denied
	is(denied_at($acl, $config{RFC_IP_1}), 1, 'cloud IP is denied');

	# Non-cloud IP with deny_cloud only must be allowed
	is(denied_at($acl, $config{RFC_IP_2}), 0, 'non-cloud IP is allowed');

	# Verify _is_cloud_host was actually called (integration contract)
	my @cloud_calls = $cloud_spy->();
	diag "_is_cloud_host call count: " . scalar @cloud_calls if $ENV{TEST_VERBOSE};
	ok(scalar @cloud_calls >= 2, '_is_cloud_host was invoked for both IPs');

	# First call must have received the cloud IP as the argument
	my ($first_call_ip) = grep { $_->[1] eq $config{RFC_IP_1} } @cloud_calls;
	ok(defined $first_call_ip, '_is_cloud_host was called with the cloud IP');

	unmock('CGI::ACL', '_is_cloud_host');
};

# Purpose: POD specifies that deny_cloud overrides allow_ip (cloud wins)
subtest 'deny_cloud overrides allow_ip per POD specification' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		return $config{AWS_HOST} if $_[0] eq $config{RFC_IP_1};
		return undef;
	};

	# Explicitly allow the cloud IP — deny_cloud should still block it
	my $acl = CGI::ACL->new()
		->deny_cloud()
		->allow_ip($config{RFC_IP_1});

	diag "deny_cloud overrides allow_ip: IP=$config{RFC_IP_1}" if $ENV{TEST_VERBOSE};

	# deny_cloud takes precedence over allow_ip (as documented)
	is(denied_at($acl, $config{RFC_IP_1}), 1, 'cloud IP is denied despite being in allow_ip list');
};

# Purpose: deny_cloud with IPv6 cloud address (security fix for IPv6 bypass)
subtest 'deny_cloud blocks IPv6 cloud addresses (mocked DNS)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		return $config{AWS_HOST}      if $_[0] eq $config{IPv6_ADDR};
		return $config{NONCLOUD_HOST} if $_[0] eq $config{IPv6_ADDR2};
		return undef;
	};

	my $acl = CGI::ACL->new()->deny_cloud();
	diag "IPv6 deny_cloud: $config{IPv6_ADDR} -> cloud, $config{IPv6_ADDR2} -> non-cloud" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{IPv6_ADDR}),  1, 'IPv6 cloud IP is denied');
	is(denied_at($acl, $config{IPv6_ADDR2}), 0, 'IPv6 non-cloud IP is allowed');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: Object::Configure integration
# Purpose: env-var injection sets up ACL restrictions at construction time
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Object::Configure: env var CGI__ACL__deny_cloud activates cloud blocking' => sub {
	# Set the env var that Object::Configure translates to deny_cloud => 1
	local $ENV{CGI__ACL__deny_cloud} = 1;

	my $acl = CGI::ACL->new();
	isa_ok($acl, 'CGI::ACL', 'object created with env-var config');
	diag "deny_cloud from env: $acl->{deny_cloud}" if $ENV{TEST_VERBOSE};

	ok($acl->{deny_cloud}, 'deny_cloud is truthy when set via CGI__ACL__deny_cloud env var');
};

# Purpose: constructor passed a pre-built allowed_ips hashref seeds the list
subtest 'Constructor: pre-seeded allowed_ips hash is respected' => sub {
	# Pass the allowed_ips hashref directly to the constructor (per POD example)
	my $acl = CGI::ACL->new(allowed_ips => { $config{RFC_IP_1} => 1 });
	isa_ok($acl, 'CGI::ACL', 'object created with pre-seeded allowed_ips');
	diag "pre-seeded IP: $config{RFC_IP_1}" if $ENV{TEST_VERBOSE};

	# The pre-seeded IP must be allowed without calling allow_ip
	is(denied_at($acl, $config{RFC_IP_1}), 0, 'pre-seeded IP is allowed');
	is(denied_at($acl, $config{RFC_IP_2}), 1, 'non-seeded IP is denied');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: combined restrictions — all rule types active simultaneously
# Purpose: verify the evaluation order documented in the POD
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Combined restrictions: all rule types active (deny_cloud + IP + country)' => sub {
	# Build a mock for DNS to make the test deterministic
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		return $config{AWS_HOST} if $_[0] eq $config{RFC_IP_1};
		return undef;
	};

	my $acl = CGI::ACL->new()
		->deny_cloud()                          # deny cloud providers
		->allow_ip($config{RFC_IP_2})           # allow one specific IP
		->deny_country($config{COUNTRY_RU});    # deny Russia

	# Rule 1: cloud IP denied even if it were in the allow list
	is(denied_at($acl, $config{RFC_IP_1}), 1, 'cloud IP denied (cloud check wins)');

	# Rule 2: non-cloud explicitly allowed IP passes
	is(denied_at($acl, $config{RFC_IP_2}), 0, 'explicitly allowed IP passes');

	# Rule 3: non-allowed, non-cloud IP without country lingua is denied
	is(denied_at($acl, $config{RFC_IP_2}, lingua => lingua_for($config{IP_RU})), 0, 'allowed IP not subject to country check');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: POD edge cases
# Purpose: confirm behaviours explicitly called out in the documentation
# ─────────────────────────────────────────────────────────────────────────────

# POD says: "localhost (127.0.0.1) is NOT automatically allowed once any
# restriction is configured; call allow_ip('127.0.0.1') explicitly."
subtest 'POD edge case: localhost is NOT auto-allowed once any restriction is set' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{RFC_IP_1});
	diag "localhost auto-allow check: restriction set, REMOTE_ADDR=127.0.0.1" if $ENV{TEST_VERBOSE};

	# 127.0.0.1 is not in the allow list, so it should be denied
	is(denied_at($acl, $config{LOCAL_IP}), 1, '127.0.0.1 denied once an allow-list is set');

	# Explicitly adding 127.0.0.1 must make it pass
	$acl->allow_ip($config{LOCAL_IP});
	is(denied_at($acl, $config{LOCAL_IP}), 0, '127.0.0.1 allowed after explicit allow_ip');
};

# POD says: "allow_country() has no effect unless deny_country('*') has been
# called first."
subtest 'POD edge case: allow_country alone does not restrict access' => sub {
	# Only allow_country is set — no wildcard deny
	my $acl = CGI::ACL->new()->allow_country($config{COUNTRY_GB});

	local $ENV{REMOTE_ADDR} = $config{IP_RU};
	my $ru_lingua = CGI::Lingua->new(supported => ['en']);
	diag "allow_country alone: RU country=" . ($ru_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};

	# Without the wildcard deny, the permit list is not consulted — all allowed
	is($acl->all_denied(lingua => $ru_lingua), 0, 'RU allowed (allow_country alone has no effect)');
};

# POD all_denied formal spec: "no restrictions => result! = 0"
subtest 'POD formal spec: no restrictions always returns 0' => sub {
	my $acl = new_ok('CGI::ACL');

	# No lingua, any IP — should always return 0
	is(denied_at($acl, $config{RFC_IP_1}),  0, 'no restrictions: RFC IP allowed');
	is(denied_at($acl, $config{LOCAL_IP}),  0, 'no restrictions: localhost allowed');
	is(denied_at($acl, $config{IPv6_ADDR}), 0, 'no restrictions: IPv6 allowed');
};

# POD formal spec: "¬valid_ip(addr) => result! = 1"
subtest 'POD formal spec: invalid REMOTE_ADDR always returns 1' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{RFC_IP_1});
	diag "invalid IP test with allow list active" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, 'not-an-ip'),        1, 'text string in REMOTE_ADDR is denied');
	is(denied_at($acl, '999.999.999.999'),  1, 'out-of-range quad is denied');
	is(denied_at($acl, ''),                 1, 'empty REMOTE_ADDR is denied');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: method chaining on all public setters
# Purpose: all setters must return $self so chaining always works
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Method chaining: all setters return $self' => sub {
	my $acl = CGI::ACL->new();

	# Each setter must return the same object
	my $r1 = $acl->allow_ip($config{RFC_IP_1});
	is($r1, $acl, 'allow_ip returns $self');

	my $r2 = $acl->deny_country($config{COUNTRY_RU});
	is($r2, $acl, 'deny_country returns $self');

	my $r3 = $acl->allow_country($config{COUNTRY_US});
	is($r3, $acl, 'allow_country returns $self');

	my $r4 = $acl->deny_cloud();
	is($r4, $acl, 'deny_cloud returns $self');

	# The entire chain must produce one coherent object
	my $chained = CGI::ACL->new()
		->allow_ip($config{RFC_IP_2})
		->deny_country($config{WILDCARD})
		->allow_country($config{COUNTRY_GB})
		->deny_cloud();

	isa_ok($chained, 'CGI::ACL', 'chained construction produces a valid object');
	diag "chained: deny_cloud=$chained->{deny_cloud}" if $ENV{TEST_VERBOSE};
	ok($chained->{deny_cloud},                              'deny_cloud set via chain');
	ok($chained->{allowed_ips}{ $config{RFC_IP_2} },        'IP set via chain');
	ok($chained->{deny_countries}{ $config{WILDCARD} },     'wildcard deny set via chain');
	ok($chained->{allow_countries}{ $config{COUNTRY_GB} },  'allow country set via chain');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: return value schema validation across the public API
# Purpose: ensure every public method returns the documented type
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Return value schemas match POD specifications' => sub {
	my $acl = CGI::ACL->new();

	# new() → OBJECT
	returns_ok($acl, { type => 'OBJECT' }, 'new() return schema');

	# allow_ip() → OBJECT
	returns_ok($acl->allow_ip($config{RFC_IP_1}),         { type => 'OBJECT' }, 'allow_ip() return schema');

	# deny_country() → OBJECT
	returns_ok($acl->deny_country($config{COUNTRY_GB}),   { type => 'OBJECT' }, 'deny_country() return schema');

	# allow_country() → OBJECT
	returns_ok($acl->allow_country($config{COUNTRY_US}),  { type => 'OBJECT' }, 'allow_country() return schema');

	# deny_cloud() → OBJECT
	returns_ok($acl->deny_cloud(),                         { type => 'OBJECT' }, 'deny_cloud() return schema');

	# all_denied() → 0 or 1
	my $result = denied_at($acl, $config{RFC_IP_1}, lingua => lingua_for($config{IP_US}));
	returns_ok($result, { type => 'SCALAR', regex => qr/^[01]$/ }, 'all_denied() return schema');
	diag "all_denied return value: $result" if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: deny_all_countries() convenience method end-to-end
# Purpose: verify the POD-documented sugar method produces identical behaviour
# to deny_country('*') in a real multi-step workflow
# ─────────────────────────────────────────────────────────────────────────────
subtest 'deny_all_countries() workflow: permit-list with real GeoIP' => sub {
	# POD: "Sugar for deny_country('*'); switches all_denied() into default-deny
	# mode for country checks."  Build two ACLs — one using the sugar, one using
	# deny_country('*') directly — and verify both produce identical results.
	my $acl_sugar = CGI::ACL->new()
		->deny_all_countries()
		->allow_country($config{COUNTRY_US});

	my $acl_raw = CGI::ACL->new()
		->deny_country($config{WILDCARD})
		->allow_country($config{COUNTRY_US});

	# US IP: both ACLs must allow it
	local $ENV{REMOTE_ADDR} = $config{IP_US};
	my $us_lingua = CGI::Lingua->new(supported => ['en']);
	diag "deny_all_countries sugar: US country=" . ($us_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};

	my $sugar_us = $acl_sugar->all_denied(lingua => $us_lingua);
	my $raw_us   = $acl_raw->all_denied(  lingua => $us_lingua);
	is($sugar_us, 0,       'deny_all_countries + allow US: US is permitted');
	is($sugar_us, $raw_us, 'deny_all_countries result identical to deny_country("*") for allowed country');

	# Non-US IP (GB is not in permit list): both ACLs must deny it
	local $ENV{REMOTE_ADDR} = $config{IP_GB};
	my $gb_lingua = CGI::Lingua->new(supported => ['en']);
	diag "deny_all_countries sugar: GB country=" . ($gb_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};

	my $sugar_gb = $acl_sugar->all_denied(lingua => $gb_lingua);
	my $raw_gb   = $acl_raw->all_denied(  lingua => $gb_lingua);
	is($sugar_gb, 1,       'deny_all_countries + allow US: GB is denied (not in permit list)');
	is($sugar_gb, $raw_gb, 'deny_all_countries result identical to deny_country("*") for non-listed country');

	# Returns $self: verify method chaining produced a functional object
	isa_ok($acl_sugar, 'CGI::ACL', 'deny_all_countries chained object is still valid');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: clone isolation — cloud cache is cleared on new()
# Purpose: a cloned object must re-query DNS for IPs that were cached in the
# parent; the per-object cloud cache must not be shared between instances
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Clone isolation: cloud cache is cleared on clone, forcing fresh DNS lookup' => sub {
	# Each call to the mock increments $dns_calls, letting us verify exactly
	# when the DNS path is taken vs. the cache hit path.
	my $dns_calls = 0;
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		$dns_calls++;
		diag "_verified_rdns call #$dns_calls for $_[0]" if $ENV{TEST_VERBOSE};
		return $config{AWS_HOST} if $_[0] eq $config{RFC_IP_1};
		return undef;
	};

	my $orig = CGI::ACL->new()->deny_cloud();

	# First call on orig: cache miss → DNS queried → result cached
	is(denied_at($orig, $config{RFC_IP_1}), 1, 'cloud IP denied (first call: DNS queried)');
	my $calls_after_first = $dns_calls;

	# Second call on orig: cache hit → DNS must NOT be queried again
	is(denied_at($orig, $config{RFC_IP_1}), 1, 'cloud IP denied again (second call: served from cache)');
	is($dns_calls, $calls_after_first, 'no additional DNS call on second all_denied() (cache hit)');

	# Clone the object: POD says cache is cleared (consistent with _cidrlist)
	my $clone = $orig->new();
	isa_ok($clone, 'CGI::ACL', 'clone is a valid CGI::ACL object');
	isnt(refaddr($orig), refaddr($clone), 'clone is a distinct object reference');

	# First call on clone: cache is empty → DNS must be queried again
	is(denied_at($clone, $config{RFC_IP_1}), 1, 'cloud IP denied on clone (cache cleared → fresh DNS)');
	ok($dns_calls > $calls_after_first, 'DNS was re-queried for the clone (cache not inherited from parent)');
	diag "total DNS calls: $dns_calls (expected >$calls_after_first)" if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: concurrent ACL instances with different country deny policies
# Purpose: modifying one object's country set must never bleed into another
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Concurrent ACLs: independent country deny policies do not share state' => sub {
	plan skip_all => 'RIPE WHOIS rate-limited; run again later' unless $ripe_ok;

	# ACL A denies Russia; ACL B denies the UK.  Each must act independently.
	my $acl_a = CGI::ACL->new()->deny_country($config{COUNTRY_RU});
	my $acl_b = CGI::ACL->new()->deny_country($config{COUNTRY_GB});

	my $ru_lingua = lingua_for($config{IP_RU});
	my $gb_lingua = lingua_for($config{IP_GB});

	diag "concurrent ACLs: RU=" . ($ru_lingua->country() // 'undef')
	   . " GB=" . ($gb_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};

	# Russian IP: A denies (RU in A's list), B allows (RU not in B's list)
	is(denied_at($acl_a, $config{IP_RU}, lingua => $ru_lingua), 1, 'ACL A denies Russian IP');
	is(denied_at($acl_b, $config{IP_RU}, lingua => $ru_lingua), 0, 'ACL B allows Russian IP (not in B deny list)');

	# UK IP: A allows (GB not in A's list), B denies (GB in B's list)
	is(denied_at($acl_a, $config{IP_GB}, lingua => $gb_lingua), 0, 'ACL A allows UK IP (not in A deny list)');
	is(denied_at($acl_b, $config{IP_GB}, lingua => $gb_lingua), 1, 'ACL B denies UK IP');

	# After adding RU to ACL B, ACL A must be unaffected
	$acl_b->deny_country($config{COUNTRY_RU});
	is(denied_at($acl_a, $config{IP_RU}, lingua => $ru_lingua), 1, 'ACL A unchanged after ACL B was modified');
	ok(!$acl_a->{deny_countries}{$config{COUNTRY_GB}}, 'ACL A deny_countries does not contain GB (no state bleed from B)');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: SYNOPSIS §5 — production-grade combined policy
# Purpose: exercise the full rule-evaluation order from the POD with all four
# restriction types active simultaneously (cloud + IP + deny-all + allow-country)
# ─────────────────────────────────────────────────────────────────────────────
subtest 'SYNOPSIS §5: production-grade combined policy (cloud + IP + deny-all + allow-country)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		return $config{AWS_HOST} if $_[0] eq $config{RFC_IP_1};
		return undef;
	};

	# Production ACL from POD §5: block cloud, allow one IP, deny all countries
	# except US.  Tests each rule tier in the documented evaluation order.
	my $acl = CGI::ACL->new()
		->deny_cloud()                           # tier 3: cloud check
		->allow_ip($config{RFC_IP_2})            # tier 4: IP allow-list
		->deny_all_countries()                   # tier 5a: default-deny
		->allow_country($config{COUNTRY_US});    # tier 5b: permit list

	# Tier 3 wins: cloud IP denied regardless of everything else
	is(denied_at($acl, $config{RFC_IP_1}), 1, '§5: cloud IP denied (cloud check takes precedence)');

	# Tier 4 wins: explicitly allowed IP passes without a country check
	is(denied_at($acl, $config{RFC_IP_2}), 0, '§5: explicitly allowed IP permitted (IP check short-circuits country)');

	# Tier 5: non-cloud, non-listed IP reaches the country check
	local $ENV{REMOTE_ADDR} = $config{IP_US};
	my $us_lingua = CGI::Lingua->new(supported => ['en']);
	diag "§5 US lingua->country=" . ($us_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};
	is($acl->all_denied(lingua => $us_lingua), 0, '§5: US visitor permitted by country allow-list');

	local $ENV{REMOTE_ADDR} = $config{IP_GB};
	my $gb_lingua = CGI::Lingua->new(supported => ['en']);
	diag "§5 GB lingua->country=" . ($gb_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};
	is($acl->all_denied(lingua => $gb_lingua), 1, '§5: GB visitor denied (not in country allow-list)');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: SYNOPSIS §6 — shared base ACL cloned for route-specific policies
# Purpose: verify that a base ACL cloned for an admin route correctly inherits
# base restrictions while adding route-specific ones independently
# ─────────────────────────────────────────────────────────────────────────────
subtest 'SYNOPSIS §6: base ACL cloned for route-specific admin policy' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };

	# Base ACL: deny cloud + permit US only (used by all public routes)
	my $base_acl = CGI::ACL->new()
		->deny_cloud()
		->deny_all_countries()
		->allow_country($config{COUNTRY_US});

	# Admin route: clone base, then restrict to one trusted IP as well
	my $admin_acl = $base_acl->new()
		->allow_ip($config{RFC_IP_2});

	isa_ok($admin_acl, 'CGI::ACL', 'admin clone is a valid CGI::ACL object');
	isnt(refaddr($base_acl), refaddr($admin_acl), 'admin clone is a distinct object');

	# Admin clone: explicitly allowed IP passes without a country check
	is(denied_at($admin_acl, $config{RFC_IP_2}), 0, 'admin clone: trusted IP permitted');

	# Admin clone: unlisted IP still goes through country check (US only)
	local $ENV{REMOTE_ADDR} = $config{IP_US};
	my $us_lingua = lingua_for($config{IP_US});
	diag "§6 admin US lingua->country=" . ($us_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};
	is($admin_acl->all_denied(lingua => $us_lingua), 0, 'admin clone: US visitor permitted by country');

	local $ENV{REMOTE_ADDR} = $config{IP_GB};
	my $gb_lingua = CGI::Lingua->new(supported => ['en']);
	diag "§6 admin GB lingua->country=" . ($gb_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};
	is($admin_acl->all_denied(lingua => $gb_lingua), 1, 'admin clone: GB visitor denied (not in permit list)');

	# Mutations to the admin clone must NOT leak into the base ACL
	ok(!defined($base_acl->{allowed_ips}) || !$base_acl->{allowed_ips}{ $config{RFC_IP_2} },
		'base ACL unaffected: trusted IP added to admin clone is not visible in base');

	# Base ACL: must still work independently after clone was modified
	local $ENV{REMOTE_ADDR} = $config{IP_US};
	is($base_acl->all_denied(lingua => $us_lingua), 0, 'base ACL still allows US after admin clone was modified');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: deny_cloud + allow_country fast-path (no lingua needed)
# Purpose: when deny_cloud is the only "meaningful" restriction (allow_countries
# alone is explicitly documented as not meaningful), a non-cloud IP must be
# allowed immediately without consulting the lingua argument
# ─────────────────────────────────────────────────────────────────────────────
subtest 'deny_cloud + allow_country fast-path: non-cloud IP allowed without lingua' => sub {
	# POD PSEUDOCODE: after the cloud check, if "no meaningful further restrictions"
	# (i.e. allowed_ips = ∅ AND deny_countries = ∅), return 0 immediately.
	# allow_countries alone is explicitly "not meaningful" — documented in the
	# FORMAL SPECIFICATION: "allow_countries alone is not meaningful".
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };

	my $acl = CGI::ACL->new()
		->deny_cloud()
		->allow_country($config{COUNTRY_US});    # allow_country WITHOUT deny_country('*')

	# Non-cloud IP: fast-path returns 0 without needing a lingua object.
	# Calling all_denied() without lingua must NOT carp (no country restriction active).
	my @carps;
	{
		local $SIG{__WARN__} = sub { push @carps, $_[0] };
		my $result = denied_at($acl, $config{RFC_IP_1});
		is($result, 0, 'non-cloud IP allowed (deny_cloud + allow_country fast-path, no lingua needed)');
	}
	ok(!@carps, 'no carp emitted: country check was not reached (no deny_countries set)');
	diag "carp messages (expected none): @carps" if $ENV{TEST_VERBOSE} && @carps;
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: Object::Configure _* key injection prevention
# Purpose: env-var injection of _cloud_cache via Object::Configure must be
# stripped so an attacker cannot pre-seed the DNS cache to bypass cloud detection
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Object::Configure: _cloud_cache env-var injection is stripped (security)' => sub {
	# The env var CGI__ACL___cloud_cache would set the _cloud_cache key if not
	# stripped.  If accepted as a string (JSON-ish), hash-dereferencing it inside
	# all_denied() would die.  If somehow parsed as a real hashref (not possible
	# via env vars, but via future injection vectors), cloud detection would be
	# bypassed for the targeted IP.  The fix: new() strips all _* keys from
	# Object::Configure output before merging them into the object.
	local $ENV{'CGI__ACL___cloud_cache'} = '{"1.2.3.4":{"result":0,"expires":9999999999}}';

	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		return $config{AWS_HOST} if $_[0] eq '1.2.3.4';
		return undef;
	};

	my $acl = CGI::ACL->new()->deny_cloud();

	# Verify the injected string was not stored (key must be stripped)
	ok(!defined($acl->{_cloud_cache}), '_cloud_cache not initialised from env-var injection');

	# Functional check: cloud IP must still be detected and denied
	my $result = eval { denied_at($acl, '1.2.3.4') };
	my $err = $@; undef $@;
	ok(!$err,        'no exception when _cloud_cache injection is stripped (no hash-deref on string)');
	is($result, 1,   'cloud IP correctly denied (injection stripped → real DNS mock ran)');
	diag "Object::Configure security: result=$result err=$err" if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: CIDR list cache invalidation after allow_ip()
# Purpose: adding a new address via allow_ip() must clear and rebuild the
# internal Net::CIDR list (_cidrlist) so the new entry becomes effective
# ─────────────────────────────────────────────────────────────────────────────
subtest 'CIDR list cache invalidation: allow_ip() clears and rebuilds _cidrlist' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{RFC_CIDR});

	# Warm the CIDR cache by running a lookup
	is(denied_at($acl, $config{CIDR_INSIDE}),  0, 'CIDR inside allowed (cache warm)');
	is(denied_at($acl, $config{CIDR_OUTSIDE}), 1, 'CIDR outside denied (cache warm)');
	ok(defined $acl->{_cidrlist}, '_cidrlist is memoised after first CIDR lookup');

	# Adding a new IP must clear the cache so it is rebuilt with both entries
	$acl->allow_ip($config{RFC_IP_1});
	ok(!defined($acl->{_cidrlist}), '_cidrlist cleared after allow_ip() call');

	# Verify that BOTH the original CIDR and the newly added IP work after rebuild
	is(denied_at($acl, $config{CIDR_INSIDE}), 0, 'original CIDR inside still allowed after cache rebuild');
	is(denied_at($acl, $config{RFC_IP_1}),    0, 'newly added IP allowed after cache rebuild');
	is(denied_at($acl, $config{RFC_IP_2}),    1, 'unlisted IP still denied after cache rebuild');
	ok(defined $acl->{_cidrlist}, '_cidrlist re-memoised after rebuild lookup');
	diag "CIDR list rebuilt successfully" if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: optional dependency — CGI::Lingua
# Purpose: CGI::ACL documents that lingua is optional (only needed for country
# checks).  IP-only and cloud-only workflows must succeed even when CGI::Lingua
# is removed from Perl's module loader, proving CGI::ACL has no implicit
# dependency on it for non-country operations.
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Test::Without::Module: IP-only ACL unaffected when CGI::Lingua unavailable' => sub {
	# Hide CGI::Lingua from future require() calls.  Since CGI::ACL itself never
	# calls require/use CGI::Lingua internally, this must have no effect on its
	# IP-allow and deny_cloud logic paths.
	Test::Without::Module->import('CGI::Lingua');

	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };

	my $acl = CGI::ACL->new()
		->allow_ip($config{RFC_IP_1})
		->allow_ip($config{RFC_CIDR})
		->deny_cloud();

	my $r1 = eval { denied_at($acl, $config{RFC_IP_1}) };
	my $r2 = eval { denied_at($acl, $config{CIDR_INSIDE}) };
	my $r3 = eval { denied_at($acl, $config{RFC_IP_2}) };

	# Restore CGI::Lingua before any assertions so failures don't strand the loader
	Test::Without::Module->unimport('CGI::Lingua');

	is($r1, 0, 'exact IP allowed when CGI::Lingua is unavailable');
	is($r2, 0, 'CIDR inside allowed when CGI::Lingua is unavailable');
	is($r3, 1, 'unlisted IP denied when CGI::Lingua is unavailable');
	diag "IP-only ACL works without CGI::Lingua: r1=$r1 r2=$r2 r3=$r3" if $ENV{TEST_VERBOSE};
};

done_testing();
