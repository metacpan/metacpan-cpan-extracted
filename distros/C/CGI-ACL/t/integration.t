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

# ── Helper ───────────────────────────────────────────────────────────────────

# Run all_denied() with a fixed REMOTE_ADDR without polluting the global env
sub denied_at {
	my ($acl, $addr, @rest) = @_;
	local $ENV{REMOTE_ADDR} = $addr;
	return $acl->all_denied(@rest);
}

# Build a real CGI::Lingua for a given REMOTE_ADDR (resolves country from GeoIP)
sub lingua_for {
	my $addr = shift;
	local $ENV{REMOTE_ADDR} = $addr;
	return CGI::Lingua->new(supported => ['en']);
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
	# Deny Russian Federation by ISO code
	my $acl = CGI::ACL->new()->deny_country($config{COUNTRY_RU});

	# Build lingua for each test IP under the right REMOTE_ADDR
	local $ENV{REMOTE_ADDR} = $config{IP_RU};
	my $ru_lingua = CGI::Lingua->new(supported => ['en']);
	diag "RU lingua->country=" . ($ru_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};

	# Russian IP must be denied
	is($acl->all_denied(lingua => $ru_lingua), 1, 'Russian IP is denied');

	# UK IP must be allowed (not on the deny list)
	local $ENV{REMOTE_ADDR} = $config{IP_GB};
	my $gb_lingua = CGI::Lingua->new(supported => ['en']);
	diag "GB lingua->country=" . ($gb_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};
	is($acl->all_denied(lingua => $gb_lingua), 0, 'UK IP is allowed');
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
	# Deny both RU and BR in a single call
	my $acl = CGI::ACL->new()->deny_country(country => [$config{COUNTRY_RU}, $config{COUNTRY_BR}]);
	diag "deny_countries: " . join(',', sort keys %{$acl->{deny_countries}}) if $ENV{TEST_VERBOSE};

	# Russian IP must be denied
	local $ENV{REMOTE_ADDR} = $config{IP_RU};
	my $ru_lingua = CGI::Lingua->new(supported => ['en']);
	is($acl->all_denied(lingua => $ru_lingua), 1, 'Russian IP denied from arrayref list');

	# UK IP must be allowed
	local $ENV{REMOTE_ADDR} = $config{IP_GB};
	my $gb_lingua = CGI::Lingua->new(supported => ['en']);
	is($acl->all_denied(lingua => $gb_lingua), 0, 'UK IP allowed (not in deny list)');
};

# ─────────────────────────────────────────────────────────────────────────────
# Scenario: IP allow-list beats country restriction
# Purpose: when an IP is in the allow-list, country is not consulted
# ─────────────────────────────────────────────────────────────────────────────
subtest 'IP allow-list overrides country deny (IP match short-circuits country check)' => sub {
	# Deny the UK country, but allow the specific IP explicitly
	my $acl = CGI::ACL->new()
		->deny_country($config{COUNTRY_GB})
		->allow_ip($config{IP_GB});

	# The IP is explicitly allowed, so it must not be denied despite the country rule
	local $ENV{REMOTE_ADDR} = $config{IP_GB};
	my $gb_lingua = CGI::Lingua->new(supported => ['en']);
	diag "IP allow beats country deny: IP=$config{IP_GB} country=" . ($gb_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};
	is($acl->all_denied(lingua => $gb_lingua), 0, 'explicitly allowed IP is not denied by country rule');

	# A non-GB, non-allowed IP falls through to the country check: RU is not in
	# the deny list, so it should be allowed.  This confirms the deny_country rule
	# is selective — only clients from GB are denied.
	local $ENV{REMOTE_ADDR} = $config{IP_RU};
	my $other_lingua = CGI::Lingua->new(supported => ['en']);
	diag "non-GB, non-allowed IP: country=" . ($other_lingua->country() // 'undef') if $ENV{TEST_VERBOSE};
	is($acl->all_denied(lingua => $other_lingua), 0, 'non-GB non-allowed IP is allowed (only GB is denied)');
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

done_testing();
