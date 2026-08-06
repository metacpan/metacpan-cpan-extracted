#!/usr/bin/env perl
# function.t -- white-box function-level tests for CGI::ACL

use strict;
use warnings;

use Carp;	# required: prevents Test::Carp glob aliasing from clearing Carp::carp
use Test::Most;
use Test::Carp;
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Returns;
use Readonly;
use Scalar::Util qw(refaddr);
use Socket qw(AF_INET);

# Load the module under test
BEGIN { use_ok('CGI::ACL') }

# ── Configuration ────────────────────────────────────────────────────────────

# All test constants live here; no magic strings or numbers elsewhere
Readonly my %config => (
	LOCAL_IP              => '127.0.0.1',
	RFC5737_IP            => '203.0.113.5',     # TEST-NET-3 per RFC 5737
	RFC5737_IP2           => '198.51.100.1',    # TEST-NET-2 per RFC 5737
	RFC5737_CIDR          => '192.0.2.0/24',    # TEST-NET-1 per RFC 5737
	CIDR_INSIDE           => '192.0.2.100',     # falls inside RFC5737_CIDR
	CIDR_OUTSIDE          => '10.0.0.1',        # outside all test CIDRs
	IPv6_ADDR             => '2001:db8::1',     # documentation IPv6 per RFC 3849
	IPv6_ADDR2            => '2001:db8::2',     # second documentation IPv6
	IPv6_INVALID          => 'not::a::valid::ipv6::too::many',  # too many groups
	INVALID_IP            => 'not-an-ip',       # clearly malformed address
	INVALID_IP2           => '999.999.999.999', # out-of-range dotted quad
	COUNTRY_GB            => 'gb',
	COUNTRY_US            => 'us',
	COUNTRY_BR            => 'br',
	COUNTRY_GB_UPPER      => 'GB',
	COUNTRY_US_UPPER      => 'US',
	WILDCARD              => '*',

	# Cloud-provider hostname samples for _is_cloud_host() tests
	AWS_HOST              => 'ec2-1-2-3-4.compute-1.amazonaws.com',
	GCP_HOST              => '203-0-113-5.bc.googleusercontent.com',
	AZURE_HOST            => 'myvm.cloudapp.net',
	AZURE_HOST2           => 'myvm.azure.com',
	DO_HOST               => 'myserver.digitalocean.something',
	LINODE_HOST           => 'li-1234-5.members.linode.com',
	HETZNER_HOST          => 'srv1.hetzner.de',
	HETZNER_LEGACY_HOST   => 'srv1.your-server.de',
	OVH_HOST              => 'ns1234.ovh.net',
	OVH_EU_HOST           => 'ip-1-2-3-4.eu',
	NONCLOUD_HOST         => 'mail.example.com',

	# Expected carp/crog message fragments
	DENY_ALL_WARN         => 'Usage: all_denied($lingua)',
	DENY_IP_WARN          => 'Usage: allow_ip($ip_address)',
	DENY_COUNTRY_WARN     => 'Usage: deny_country($country)',
	ALLOW_COUNTRY_WARN    => 'Usage: allow_country($country)',
	PLAIN_FN_WARN         => 'CGI::ACL: use ->new() not ::new() to instantiate',
);

# ── Mock Lingua helpers ───────────────────────────────────────────────────────

# Minimal lingua stub that returns a fixed country code
{
	package Test::FakeLingua;
	sub new      { my ($class, $country) = @_; bless { country => $country }, $class }
	sub country  { $_[0]->{country} }
}

# Lingua stub whose country() always throws — tests the eval guard in all_denied()
{
	package Test::DyingLingua;
	sub new     { bless {}, shift }
	sub country { die "country() intentionally dies for testing\n" }
}

# ── Helper ───────────────────────────────────────────────────────────────────

# Run all_denied() with a controlled REMOTE_ADDR
sub denied_with_addr {
	my ($acl, $addr, @rest) = @_;
	local $ENV{REMOTE_ADDR} = $addr;
	return $acl->all_denied(@rest);
}

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: new()
# Purpose: verify constructor handles class method, function, and clone paths
# ─────────────────────────────────────────────────────────────────────────────
subtest 'new() - class method returns blessed CGI::ACL object' => sub {
	my $acl = CGI::ACL->new();
	diag "new() returned: $acl" if $ENV{TEST_VERBOSE};

	# Must be a defined, blessed reference
	ok(defined $acl, 'new() returns defined value');
	isa_ok($acl, 'CGI::ACL', 'object has correct class');

	# Confirm schema compliance via Test::Returns
	returns_ok($acl, { type => 'OBJECT' }, 'return schema ok');

	# Fresh object has no restrictions
	is($acl->{allowed_ips},     undef, 'allowed_ips is undef initially');
	is($acl->{deny_countries},  undef, 'deny_countries is undef initially');
	is($acl->{allow_countries}, undef, 'allow_countries is undef initially');
	is($acl->{deny_cloud},      undef, 'deny_cloud is undef initially');
};

# Purpose: calling new() with pre-seeded hash populates the fields
subtest 'new() - with initial arguments' => sub {
	my $acl = CGI::ACL->new(deny_cloud => 1);
	diag "new(deny_cloud=>1) deny_cloud=$acl->{deny_cloud}" if $ENV{TEST_VERBOSE};

	isa_ok($acl, 'CGI::ACL', 'new with args returns object');
	is($acl->{deny_cloud}, 1, 'deny_cloud was pre-set via constructor');
};

# Purpose: calling on an existing object returns a shallow clone
subtest 'new() - shallow clone when called on an instance' => sub {
	my $orig  = CGI::ACL->new(deny_cloud => 1);
	my $clone = $orig->new();
	diag "orig refaddr=" . refaddr($orig) . " clone refaddr=" . refaddr($clone) if $ENV{TEST_VERBOSE};

	isa_ok($clone, 'CGI::ACL', 'clone is a CGI::ACL object');
	isnt(refaddr($clone), refaddr($orig), 'clone is a different object');
	is($clone->{deny_cloud}, 1, 'clone inherits deny_cloud from original');
};

# Purpose: calling as a plain function (not a method) emits a carp warning
subtest 'new() - plain function call carps and returns undef' => sub {
	my $result;

	# CGI::ACL::new() with no args emits a carp (not croak)
	does_carp_that_matches(
		sub { $result = CGI::ACL::new() },
		qr/\Quse ->new() not ::new() to instantiate\E/,
	);
	is($result, undef, 'plain function call returns undef');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: allow_ip()
# Purpose: test IP storage, CIDR cache invalidation, error paths, and chaining
# ─────────────────────────────────────────────────────────────────────────────
subtest 'allow_ip() - positional scalar argument' => sub {
	my $acl = CGI::ACL->new();
	diag "allow_ip positional: $config{RFC5737_IP}" if $ENV{TEST_VERBOSE};

	my $ret = $acl->allow_ip($config{RFC5737_IP});

	# The IP must appear in the allowed_ips hash
	ok($acl->{allowed_ips}{ $config{RFC5737_IP} }, 'IP stored in allowed_ips');

	# The method must return $self for chaining
	is($ret, $acl, 'returns $self');
	returns_ok($ret, { type => 'OBJECT' }, 'return schema ok');
};

# Purpose: named-parameter form stores IP correctly
subtest 'allow_ip() - named ip => argument' => sub {
	my $acl = CGI::ACL->new();
	$acl->allow_ip(ip => $config{RFC5737_IP});
	ok($acl->{allowed_ips}{ $config{RFC5737_IP} }, 'IP stored via named param');
};

# Purpose: hashref form stores IP correctly
subtest 'allow_ip() - hashref argument' => sub {
	my $acl = CGI::ACL->new();
	$acl->allow_ip({ ip => $config{RFC5737_IP} });
	ok($acl->{allowed_ips}{ $config{RFC5737_IP} }, 'IP stored via hashref');
};

# Purpose: IPv6 address is stored correctly
subtest 'allow_ip() - IPv6 address stored correctly' => sub {
	my $acl = CGI::ACL->new();
	diag "allow_ip IPv6: $config{IPv6_ADDR}" if $ENV{TEST_VERBOSE};

	$acl->allow_ip($config{IPv6_ADDR});
	ok($acl->{allowed_ips}{ $config{IPv6_ADDR} }, 'IPv6 address stored in allowed_ips');
};

# Purpose: adding an IP must delete the memoised _cidrlist cache
subtest 'allow_ip() - invalidates the _cidrlist cache' => sub {
	my $acl = CGI::ACL->new();

	# Seed a fake cache entry
	$acl->{_cidrlist} = ['dummy'];
	$acl->allow_ip($config{RFC5737_IP});

	# Cache must have been cleared
	ok(!defined $acl->{_cidrlist}, '_cidrlist deleted after allow_ip');
};

# Purpose: passing a non-hash reference emits a carp and returns $self
subtest 'allow_ip() - non-hash ref argument carps and chains' => sub {
	my $acl = CGI::ACL->new();
	my $ret;

	does_carp_that_matches(
		sub { $ret = $acl->allow_ip(\'bad scalar ref') },
		qr/\QUsage: allow_ip\E/,
	);
	is($ret, $acl, 'returns $self on bad-ref error path');
};

# Purpose: passing no ip key emits a carp and returns $self
subtest 'allow_ip() - missing ip key carps and chains' => sub {
	my $acl = CGI::ACL->new();
	my $ret;

	does_carp_that_matches(
		sub { $ret = $acl->allow_ip(not_ip => 'x') },
		qr/\QUsage: allow_ip\E/,
	);
	is($ret, $acl, 'returns $self on missing-key error path');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: deny_country()
# Purpose: test country storage, case folding, wildcard, arrayref, error paths
# ─────────────────────────────────────────────────────────────────────────────
subtest 'deny_country() - positional scalar stores lowercase' => sub {
	my $acl = CGI::ACL->new();
	diag "deny_country positional: $config{COUNTRY_GB_UPPER}" if $ENV{TEST_VERBOSE};

	my $ret = $acl->deny_country($config{COUNTRY_GB_UPPER});

	ok($acl->{deny_countries}{ $config{COUNTRY_GB} }, 'country stored lowercase');
	is($ret, $acl, 'returns $self');
	returns_ok($ret, { type => 'OBJECT' }, 'return schema ok');
};

# Purpose: named-parameter form stores country correctly
subtest 'deny_country() - named country => argument' => sub {
	my $acl = CGI::ACL->new();
	$acl->deny_country(country => $config{COUNTRY_US_UPPER});
	ok($acl->{deny_countries}{ $config{COUNTRY_US} }, 'country stored via named param');
};

# Purpose: hashref form stores country correctly
subtest 'deny_country() - hashref argument' => sub {
	my $acl = CGI::ACL->new();
	$acl->deny_country({ country => $config{COUNTRY_BR} });
	ok($acl->{deny_countries}{ $config{COUNTRY_BR} }, 'country stored via hashref');
};

# Purpose: arrayref stores all countries in the list
subtest 'deny_country() - arrayref of countries' => sub {
	my $acl = CGI::ACL->new();
	$acl->deny_country(country => [ $config{COUNTRY_GB_UPPER}, $config{COUNTRY_US_UPPER} ]);
	diag "deny_countries hash: " . join(', ', sort keys %{$acl->{deny_countries}}) if $ENV{TEST_VERBOSE};

	# Both must be present, lowercased
	ok($acl->{deny_countries}{ $config{COUNTRY_GB} }, 'first country stored');
	ok($acl->{deny_countries}{ $config{COUNTRY_US} }, 'second country stored');
};

# Purpose: wildcard '*' stored and triggers default-deny semantics
subtest 'deny_country() - wildcard' => sub {
	my $acl = CGI::ACL->new();
	$acl->deny_country($config{WILDCARD});
	ok($acl->{deny_countries}{ $config{WILDCARD} }, 'wildcard stored in deny_countries');
};

# Purpose: non-hash/non-array ref emits carp and returns $self
subtest 'deny_country() - bad ref carps and chains' => sub {
	my $acl = CGI::ACL->new();
	my $ret;

	does_carp_that_matches(
		sub { $ret = $acl->deny_country(\'not a hash or array ref') },
		qr/\QUsage: deny_country\E/,
	);
	is($ret, $acl, 'returns $self on bad-ref error path');
};

# Purpose: calling with no country key carps and returns $self
subtest 'deny_country() - missing key carps and chains' => sub {
	my $acl = CGI::ACL->new();
	my $ret;

	does_carp_that_matches(
		sub { $ret = $acl->deny_country() },
		qr/\QUsage: deny_country\E/,
	);
	is($ret, $acl, 'returns $self on missing argument');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: allow_country()
# Purpose: same interface as deny_country but writes to allow_countries
# ─────────────────────────────────────────────────────────────────────────────
subtest 'allow_country() - positional scalar stores lowercase' => sub {
	my $acl = CGI::ACL->new();
	my $ret = $acl->allow_country($config{COUNTRY_GB_UPPER});
	diag "allow_countries: " . join(', ', sort keys %{$acl->{allow_countries}}) if $ENV{TEST_VERBOSE};

	ok($acl->{allow_countries}{ $config{COUNTRY_GB} }, 'country stored lowercase');
	is($ret, $acl, 'returns $self');
	returns_ok($ret, { type => 'OBJECT' }, 'return schema ok');
};

# Purpose: arrayref of countries all stored in allow_countries
subtest 'allow_country() - arrayref of countries' => sub {
	my $acl = CGI::ACL->new();
	$acl->allow_country(country => [ $config{COUNTRY_GB_UPPER}, $config{COUNTRY_US_UPPER} ]);

	ok($acl->{allow_countries}{ $config{COUNTRY_GB} }, 'GB stored in allow_countries');
	ok($acl->{allow_countries}{ $config{COUNTRY_US} }, 'US stored in allow_countries');
};

# Purpose: bad-ref argument emits carp and still returns $self
subtest 'allow_country() - bad ref carps and chains' => sub {
	my $acl = CGI::ACL->new();
	my $ret;

	does_carp_that_matches(
		sub { $ret = $acl->allow_country(\42) },
		qr/\QUsage: allow_country\E/,
	);
	is($ret, $acl, 'returns $self on bad-ref error');
};

# Purpose: calling with no country key carps and returns $self
subtest 'allow_country() - missing key carps and chains' => sub {
	my $acl = CGI::ACL->new();
	my $ret;

	does_carp_that_matches(
		sub { $ret = $acl->allow_country() },
		qr/\QUsage: allow_country\E/,
	);
	is($ret, $acl, 'returns $self on missing argument');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: deny_cloud()
# Purpose: verify deny_cloud flag is set and method chaining works
# ─────────────────────────────────────────────────────────────────────────────
# Subtest: deny_all_countries()
# Purpose: convenience sugar for deny_country('*'); must activate default-deny mode
# ─────────────────────────────────────────────────────────────────────────────
subtest 'deny_all_countries() - stores wildcard and returns $self' => sub {
	my $acl = CGI::ACL->new();
	my $ret = $acl->deny_all_countries();
	diag "deny_countries after deny_all_countries: " . join(',', sort keys %{$acl->{deny_countries} // {}}) if $ENV{TEST_VERBOSE};

	# The wildcard sentinel must be set in deny_countries
	ok($acl->{deny_countries}{ $config{WILDCARD} }, "deny_countries{'*'} is set");
	is($ret, $acl, 'returns $self for chaining');
	returns_ok($ret, { type => 'OBJECT' }, 'return schema ok');
};

# Purpose: calling deny_all_countries twice is idempotent
subtest 'deny_all_countries() - idempotent on double call' => sub {
	my $acl = CGI::ACL->new()->deny_all_countries()->deny_all_countries();
	ok($acl->{deny_countries}{ $config{WILDCARD} }, 'wildcard still set after double call');
	is(scalar keys %{$acl->{deny_countries}}, 1, 'no duplicate keys from double call');
};

# Purpose: deny_all_countries is equivalent to deny_country('*')
subtest 'deny_all_countries() - equivalent to deny_country("*")' => sub {
	my $via_method = CGI::ACL->new()->deny_all_countries();
	my $via_call   = CGI::ACL->new()->deny_country($config{WILDCARD});

	is_deeply($via_method->{deny_countries}, $via_call->{deny_countries},
		'deny_all_countries and deny_country("*") produce identical state');
};

# Purpose: in default-deny mode only allow_country permits a country
subtest 'deny_all_countries() + allow_country - denies non-allowed country' => sub {
	my $acl = CGI::ACL->new()
		->deny_all_countries()
		->allow_country($config{COUNTRY_GB_UPPER});

	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};
	diag "deny_all_countries + allow GB" if $ENV{TEST_VERBOSE};

	is($acl->all_denied(lingua => Test::FakeLingua->new($config{COUNTRY_GB})), 0,
		'allowed country passes in default-deny mode');
	is($acl->all_denied(lingua => Test::FakeLingua->new($config{COUNTRY_BR})), 1,
		'non-allowed country denied in default-deny mode');
};

# Purpose: method chain deny_all_countries()->allow_country()->allow_ip() compiles cleanly
subtest 'deny_all_countries() - full method chain works' => sub {
	my $acl = CGI::ACL->new()
		->deny_all_countries()
		->allow_country($config{COUNTRY_US_UPPER})
		->allow_ip($config{RFC5737_IP});

	ok($acl->{deny_countries}{ $config{WILDCARD} }, 'wildcard set via chain');
	ok($acl->{allow_countries}{ $config{COUNTRY_US} }, 'allow_country set via chain');
	ok($acl->{allowed_ips}{ $config{RFC5737_IP} },     'allow_ip set via chain');
};

# ─────────────────────────────────────────────────────────────────────────────
subtest 'deny_cloud() - sets flag and returns $self' => sub {
	my $acl = CGI::ACL->new();
	my $ret = $acl->deny_cloud();
	diag "deny_cloud flag=$acl->{deny_cloud}" if $ENV{TEST_VERBOSE};

	# Flag must be set to a true value
	ok($acl->{deny_cloud}, 'deny_cloud flag is set');
	is($ret, $acl, 'returns $self for chaining');
	returns_ok($ret, { type => 'OBJECT' }, 'return schema ok');
};

# Purpose: method chaining — deny_cloud followed by allow_ip must work
subtest 'deny_cloud() - full chain compiles without errors' => sub {
	my $acl = CGI::ACL->new()
		->deny_cloud()
		->allow_ip($config{RFC5737_IP});

	ok($acl->{deny_cloud},                         'deny_cloud set via chain');
	ok($acl->{allowed_ips}{ $config{RFC5737_IP} }, 'IP set via chain');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: all_denied() — fast path (no restrictions)
# Purpose: no restrictions configured → always allow
# ─────────────────────────────────────────────────────────────────────────────
subtest 'all_denied() - no restrictions returns 0 (allow)' => sub {
	my $acl = CGI::ACL->new();
	local $ENV{REMOTE_ADDR} = $config{RFC5737_IP};
	diag "all_denied() no restrictions, REMOTE_ADDR=$config{RFC5737_IP}" if $ENV{TEST_VERBOSE};

	my $result = $acl->all_denied();
	is($result, 0, 'allow when no restrictions are set');
	returns_ok($result, { type => 'SCALAR', regex => qr/^[01]$/ }, 'return schema ok');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: all_denied() — IP address validation
# Purpose: malformed REMOTE_ADDR always triggers a deny
# ─────────────────────────────────────────────────────────────────────────────
subtest 'all_denied() - invalid REMOTE_ADDR returns 1 (deny)' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{RFC5737_IP});

	# A non-IP string must be rejected even if allow_ip is configured
	local $ENV{REMOTE_ADDR} = $config{INVALID_IP};
	diag "Testing invalid REMOTE_ADDR=$config{INVALID_IP}" if $ENV{TEST_VERBOSE};
	is($acl->all_denied(), 1, 'non-IP string in REMOTE_ADDR is denied');

	# An out-of-range dotted quad must also be rejected
	local $ENV{REMOTE_ADDR} = $config{INVALID_IP2};
	is($acl->all_denied(), 1, 'out-of-range IP is denied');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: all_denied() — IP allow-list
# Purpose: exact match and CIDR range matching
# ─────────────────────────────────────────────────────────────────────────────
subtest 'all_denied() - exact IP match allows access' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{RFC5737_IP});
	diag "exact match: allow=$config{RFC5737_IP} deny=$config{RFC5737_IP2}" if $ENV{TEST_VERBOSE};

	is(denied_with_addr($acl, $config{RFC5737_IP}),  0, 'allowed IP is not denied');
	is(denied_with_addr($acl, $config{RFC5737_IP2}), 1, 'unlisted IP is denied');
};

# Purpose: CIDR range lookups allow IPs inside the range
subtest 'all_denied() - CIDR range allows IPs inside the block' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{RFC5737_CIDR});
	diag "CIDR=$config{RFC5737_CIDR} inside=$config{CIDR_INSIDE} outside=$config{CIDR_OUTSIDE}" if $ENV{TEST_VERBOSE};

	is(denied_with_addr($acl, $config{CIDR_INSIDE}),  0, 'IP inside CIDR is allowed');
	is(denied_with_addr($acl, $config{CIDR_OUTSIDE}), 1, 'IP outside CIDR is denied');
};

# Purpose: allowed IPv6 address passes the exact-match check
subtest 'all_denied() - allowed IPv6 exact match allows access' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{IPv6_ADDR});
	diag "IPv6 allow=$config{IPv6_ADDR} deny=$config{IPv6_ADDR2}" if $ENV{TEST_VERBOSE};

	is(denied_with_addr($acl, $config{IPv6_ADDR}),  0, 'allowed IPv6 is not denied');
	is(denied_with_addr($acl, $config{IPv6_ADDR2}), 1, 'unlisted IPv6 is denied');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: all_denied() — cloud blocking
# Purpose: deny_cloud blocks cloud IPs regardless of allow_ip entries
# ─────────────────────────────────────────────────────────────────────────────
subtest 'all_denied() - deny_cloud blocks cloud IPs (mocked)' => sub {
	# Mock _verified_rdns so the test never touches real DNS
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		my $ip = $_[0];
		diag "_verified_rdns mocked for $ip" if $ENV{TEST_VERBOSE};
		return $config{AWS_HOST}      if $ip eq $config{RFC5737_IP};
		return $config{NONCLOUD_HOST} if $ip eq $config{RFC5737_IP2};
		return undef;
	};

	# Both IPs are explicitly allowed; deny_cloud must still override for the cloud one
	my $acl = CGI::ACL->new()->deny_cloud()
		->allow_ip($config{RFC5737_IP})
		->allow_ip($config{RFC5737_IP2});

	# deny_cloud takes precedence over allow_ip
	is(denied_with_addr($acl, $config{RFC5737_IP}),  1, 'cloud IP denied even if allow_ip set');
	is(denied_with_addr($acl, $config{RFC5737_IP2}), 0, 'non-cloud IP is allowed');
};

# Purpose: deny_cloud alone (no other restrictions) denies cloud, allows others
subtest 'all_denied() - deny_cloud alone with cloud vs non-cloud' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		return $config{AWS_HOST} if $_[0] eq $config{RFC5737_IP};
		return undef;
	};

	my $acl = CGI::ACL->new()->deny_cloud();

	is(denied_with_addr($acl, $config{RFC5737_IP}),  1, 'cloud IP denied');
	is(denied_with_addr($acl, $config{RFC5737_IP2}), 0, 'non-cloud IP allowed');
};

# Purpose: deny_cloud blocks an IPv6 address whose PTR matches a cloud pattern
subtest 'all_denied() - deny_cloud blocks IPv6 cloud IP (mocked)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		my $ip = $_[0];
		diag "_verified_rdns IPv6 mock for $ip" if $ENV{TEST_VERBOSE};
		return $config{AWS_HOST} if $ip eq $config{IPv6_ADDR};
		return undef;
	};

	my $acl = CGI::ACL->new()->deny_cloud();

	# IPv6 cloud address must be denied
	is(denied_with_addr($acl, $config{IPv6_ADDR}),  1, 'IPv6 cloud IP is denied');

	# IPv6 non-cloud address must be allowed
	is(denied_with_addr($acl, $config{IPv6_ADDR2}), 0, 'IPv6 non-cloud IP is allowed');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: all_denied() — country restrictions
# Purpose: wildcard deny + allow list; specific deny list; no-lingua path
# ─────────────────────────────────────────────────────────────────────────────
subtest 'all_denied() - default-deny with allow list' => sub {
	my $acl = CGI::ACL->new()
		->deny_country($config{WILDCARD})
		->allow_country($config{COUNTRY_GB_UPPER});

	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};

	# Country in the allow list → access allowed
	my $allowed_lingua = Test::FakeLingua->new($config{COUNTRY_GB});
	is($acl->all_denied(lingua => $allowed_lingua), 0, 'allowed country is not denied');

	# Country NOT in the allow list → access denied
	my $denied_lingua = Test::FakeLingua->new($config{COUNTRY_BR});
	is($acl->all_denied(lingua => $denied_lingua), 1, 'non-allowed country is denied');
};

# Purpose: explicit deny list (not wildcard) denies named countries only
subtest 'all_denied() - explicit deny list' => sub {
	my $acl = CGI::ACL->new()->deny_country($config{COUNTRY_BR});

	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};
	diag "Explicit deny list: BR denied, GB allowed" if $ENV{TEST_VERBOSE};

	is($acl->all_denied(lingua => Test::FakeLingua->new($config{COUNTRY_BR})), 1, 'listed country is denied');
	is($acl->all_denied(lingua => Test::FakeLingua->new($config{COUNTRY_GB})), 0, 'unlisted country is allowed');
};

# Purpose: deny_country('*') alone (no allow_country) must deny every known country
subtest 'all_denied() - wildcard deny alone denies any known country' => sub {
	my $acl = CGI::ACL->new()->deny_country($config{WILDCARD});

	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};
	diag "Wildcard deny: GB=$config{COUNTRY_GB} US=$config{COUNTRY_US}" if $ENV{TEST_VERBOSE};

	# Even a "safe" country should be denied with no allow list present
	is($acl->all_denied(lingua => Test::FakeLingua->new($config{COUNTRY_GB})), 1, 'GB denied by wildcard');
	is($acl->all_denied(lingua => Test::FakeLingua->new($config{COUNTRY_US})), 1, 'US denied by wildcard');
};

# Purpose: allow_country alone (without deny_country '*') allows everyone
# (the permit list is only consulted when the wildcard deny is active)
subtest 'all_denied() - allow_country alone has no restrictive effect' => sub {
	my $acl = CGI::ACL->new()->allow_country($config{COUNTRY_GB_UPPER});

	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};
	diag "allow_country only: GB should be allowed" if $ENV{TEST_VERBOSE};

	# No deny rule means the deny-list check falls through returning allow
	is($acl->all_denied(lingua => Test::FakeLingua->new($config{COUNTRY_GB})), 0, 'GB allowed (no deny rule)');
	is($acl->all_denied(lingua => Test::FakeLingua->new($config{COUNTRY_BR})), 0, 'BR allowed (no deny rule)');
};

# Purpose: unknown country (lingua returns undef) must always deny
subtest 'all_denied() - unknown country returns 1 (deny)' => sub {
	my $acl = CGI::ACL->new()->deny_country($config{COUNTRY_BR});

	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};
	is($acl->all_denied(lingua => Test::FakeLingua->new(undef)), 1, 'unknown country is denied');
};

# Purpose: country restrictions active but no lingua supplied must carp and deny
subtest 'all_denied() - no lingua with country restriction carps' => sub {
	my $acl = CGI::ACL->new()->deny_country($config{COUNTRY_BR});

	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};
	my $result;
	does_carp_that_matches(
		sub { $result = $acl->all_denied() },
		qr/\QUsage: all_denied\E/,
	);
	is($result, 1, 'returns 1 (deny) when no lingua is provided');
};

# Purpose: auto-vivification guard: deny_countries must stay undef when only
# deny_cloud is set and all_denied() is called (the country branch must not
# touch deny_countries at all when the cloud check short-circuits)
subtest 'all_denied() - no auto-vivification of deny_countries with deny_cloud only' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };

	my $acl = CGI::ACL->new()->deny_cloud();
	denied_with_addr($acl, $config{RFC5737_IP2});

	# deny_countries must NOT have been auto-vivified by the cloud code path
	is($acl->{deny_countries}, undef, 'deny_countries is still undef after deny_cloud call');
};

# Purpose: auto-vivification guard: deny_countries must stay undef when
# deny_cloud + allow_country are combined (the reported "known pitfall" case)
subtest 'all_denied() - no auto-vivification with deny_cloud + allow_country' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };

	my $acl = CGI::ACL->new()
		->deny_cloud()
		->allow_country($config{COUNTRY_GB_UPPER});

	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};
	diag "deny_cloud + allow_country: checking auto-vivification guard" if $ENV{TEST_VERBOSE};

	# After the cloud fast-path optimization, deny_cloud + allow_country (no
	# deny_countries) short-circuits to return 0 before any country check.
	# Lingua is passed here to avoid any latent warnings but is not consulted.
	$acl->all_denied(lingua => Test::FakeLingua->new($config{COUNTRY_GB}));

	# The wildcard-deny branch must not have auto-vivified deny_countries
	is($acl->{deny_countries}, undef, 'deny_countries stays undef with deny_cloud+allow_country');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: all_denied() — CIDR cache memoisation
# Purpose: _cidrlist is built once and reused; invalidated by allow_ip
# ─────────────────────────────────────────────────────────────────────────────
subtest 'all_denied() - _cidrlist is memoised on first use' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{RFC5737_CIDR});
	diag "Testing CIDR memoisation for $config{RFC5737_CIDR}" if $ENV{TEST_VERBOSE};

	# First call builds the cache
	ok(!defined $acl->{_cidrlist}, '_cidrlist absent before first call');
	denied_with_addr($acl, $config{CIDR_INSIDE});
	ok(defined $acl->{_cidrlist}, '_cidrlist populated after first call');

	# Second call reuses the cache (same reference)
	my $first_list = $acl->{_cidrlist};
	denied_with_addr($acl, $config{CIDR_INSIDE});
	is($acl->{_cidrlist}, $first_list, '_cidrlist reference is unchanged on reuse');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: _set_countries() (internal helper)
# Purpose: inserts lowercased codes; handles scalar and arrayref; no $_ clobber
# ─────────────────────────────────────────────────────────────────────────────
subtest '_set_countries() - scalar country stored lowercase' => sub {
	my $h = {};
	CGI::ACL::_set_countries($h, $config{COUNTRY_GB_UPPER});
	diag "_set_countries scalar: keys=" . join(',', sort keys %{$h}) if $ENV{TEST_VERBOSE};

	ok($h->{ $config{COUNTRY_GB} },        'uppercase input stored as lowercase');
	ok(!$h->{ $config{COUNTRY_GB_UPPER} }, 'original uppercase key is absent');
};

# Purpose: arrayref input stores every element, lowercased
subtest '_set_countries() - arrayref stores all codes lowercased' => sub {
	my $h = {};
	CGI::ACL::_set_countries($h, [ $config{COUNTRY_GB_UPPER}, $config{COUNTRY_US_UPPER} ]);

	ok($h->{ $config{COUNTRY_GB} }, 'GB stored from arrayref');
	ok($h->{ $config{COUNTRY_US} }, 'US stored from arrayref');
};

# Purpose: _set_countries must not clobber $_ in the calling scope
subtest '_set_countries() - does not clobber $_ in caller scope' => sub {
	my $h = {};

	# Set $_ to a sentinel and confirm it is unchanged after the call
	local $_ = 'sentinel-value';
	CGI::ACL::_set_countries($h, [ $config{COUNTRY_GB_UPPER}, $config{COUNTRY_US_UPPER} ]);
	is($_, 'sentinel-value', '$_ is unchanged after _set_countries with arrayref');

	# Repeat for scalar input
	local $_ = 'sentinel2';
	CGI::ACL::_set_countries($h, $config{COUNTRY_BR});
	is($_, 'sentinel2', '$_ is unchanged after _set_countries with scalar');
};

# Purpose: return value from _set_countries should be undef (void function)
subtest '_set_countries() - returns nothing (void context)' => sub {
	my $h = {};
	my @r = CGI::ACL::_set_countries($h, $config{COUNTRY_GB});
	is(scalar @r, 0, '_set_countries returns nothing in list context');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: _is_cloud_host() (internal helper)
# Purpose: returns 1 for cloud hostnames, 0 for non-cloud and undef PTR
# ─────────────────────────────────────────────────────────────────────────────
subtest '_is_cloud_host() - returns 1 for AWS hostname (mocked)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $config{AWS_HOST} };
	diag "AWS host: $config{AWS_HOST}" if $ENV{TEST_VERBOSE};

	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 1, 'AWS hostname returns 1');
};

# Purpose: returns 1 for Google Cloud hostname
subtest '_is_cloud_host() - returns 1 for GCP hostname (mocked)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $config{GCP_HOST} };
	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 1, 'GCP hostname returns 1');
};

# Purpose: returns 1 for Azure cloudapp.net hostname
subtest '_is_cloud_host() - returns 1 for Azure cloudapp.net hostname (mocked)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $config{AZURE_HOST} };
	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 1, 'Azure cloudapp.net hostname returns 1');
};

# Purpose: returns 1 for Azure .azure.com hostname
subtest '_is_cloud_host() - returns 1 for Azure .azure.com hostname (mocked)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $config{AZURE_HOST2} };
	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 1, 'Azure .azure.com hostname returns 1');
};

# Purpose: returns 1 for DigitalOcean hostname
subtest '_is_cloud_host() - returns 1 for DigitalOcean hostname (mocked)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $config{DO_HOST} };
	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 1, 'DigitalOcean hostname returns 1');
};

# Purpose: returns 1 for Linode/Akamai hostname (.members.linode.com)
subtest '_is_cloud_host() - returns 1 for Linode hostname (mocked)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $config{LINODE_HOST} };
	diag "Linode host: $config{LINODE_HOST}" if $ENV{TEST_VERBOSE};

	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 1, 'Linode hostname returns 1');
};

# Purpose: returns 1 for Hetzner Cloud hostname (contains 'hetzner')
subtest '_is_cloud_host() - returns 1 for Hetzner Cloud hostname (mocked)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $config{HETZNER_HOST} };
	diag "Hetzner host: $config{HETZNER_HOST}" if $ENV{TEST_VERBOSE};

	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 1, 'Hetzner Cloud hostname returns 1');
};

# Purpose: returns 1 for Hetzner legacy dedicated server (.your-server.de)
subtest '_is_cloud_host() - returns 1 for Hetzner legacy hostname (mocked)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $config{HETZNER_LEGACY_HOST} };
	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 1, 'Hetzner legacy hostname returns 1');
};

# Purpose: returns 1 for OVH Cloud hostname (.ovh.net)
subtest '_is_cloud_host() - returns 1 for OVH Cloud hostname (mocked)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $config{OVH_HOST} };
	diag "OVH host: $config{OVH_HOST}" if $ENV{TEST_VERBOSE};

	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 1, 'OVH .ovh.net hostname returns 1');
};

# Purpose: returns 1 for OVH European IP range hostname (ip-N-N-N-N.eu)
subtest '_is_cloud_host() - returns 1 for OVH EU IP range hostname (mocked)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $config{OVH_EU_HOST} };
	diag "OVH EU host: $config{OVH_EU_HOST}" if $ENV{TEST_VERBOSE};

	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 1, 'OVH EU hostname returns 1');
};

# Purpose: non-cloud hostname must return 0
subtest '_is_cloud_host() - returns 0 for non-cloud hostname (mocked)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $config{NONCLOUD_HOST} };
	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 0, 'residential hostname returns 0');
};

# Purpose: undef PTR (no record or verification failure) must return 0
subtest '_is_cloud_host() - returns 0 when _verified_rdns returns undef' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };
	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 0, 'undef PTR returns 0');
};

# Purpose: IPv6 cloud IP is also blocked when its PTR matches a cloud pattern
subtest '_is_cloud_host() - returns 1 for IPv6 cloud hostname (mocked)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $config{AWS_HOST} };
	is(CGI::ACL::_is_cloud_host($config{IPv6_ADDR}), 1, 'IPv6 cloud host returns 1');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: _verified_rdns() (internal helper)
# Purpose: returns undef for invalid IPs; confirms forward lookup
# ─────────────────────────────────────────────────────────────────────────────
subtest '_verified_rdns() - invalid IPv4 string returns undef' => sub {
	# An obviously wrong string fails inet_aton, so the function returns undef
	my $result = CGI::ACL::_verified_rdns($config{INVALID_IP});
	diag "_verified_rdns('$config{INVALID_IP}') = " . (defined $result ? $result : 'undef') if $ENV{TEST_VERBOSE};
	is($result, undef, 'non-IP string returns undef');
};

# Purpose: out-of-range dotted quad also returns undef
subtest '_verified_rdns() - out-of-range IPv4 returns undef' => sub {
	my $result = CGI::ACL::_verified_rdns($config{INVALID_IP2});
	is($result, undef, 'out-of-range quad returns undef');
};

# Purpose: invalid IPv6 address fails inet_pton and returns undef
subtest '_verified_rdns() - invalid IPv6 string returns undef' => sub {
	my $result = CGI::ACL::_verified_rdns($config{IPv6_INVALID});
	is($result, undef, 'invalid IPv6 string returns undef');
};

# Purpose: a documentation-range IPv6 address (RFC 3849) has no PTR in any
# real DNS and should return undef via gethostbyaddr returning undef
subtest '_verified_rdns() - documentation IPv6 address returns undef (no PTR)' => sub {
	# 2001:db8::/32 is reserved and will never have a real PTR record;
	# gethostbyaddr on a packed IPv6 for this range should return undef
	my $result = CGI::ACL::_verified_rdns($config{IPv6_ADDR});
	diag "_verified_rdns(IPv6=$config{IPv6_ADDR}) = " . (defined $result ? $result : 'undef') if $ENV{TEST_VERBOSE};
	is($result, undef, 'documentation IPv6 with no PTR returns undef');
};

# Purpose: when forward confirmation fails the function returns undef
subtest '_verified_rdns() - forward confirmation mismatch returns undef' => sub {
	# Mock _rdns_forward so the confirmed IP list does NOT include LOCAL_IP
	my $guard = mock_scoped 'CGI::ACL::_rdns_forward' => sub {
		return ('10.0.0.1');    # deliberately wrong IP in forward list
	};

	# Use 127.0.0.1: gethostbyaddr returns 'localhost' on this machine,
	# but the mocked forward confirms a different IP, so verification fails.
	my $result = CGI::ACL::_verified_rdns($config{LOCAL_IP});
	is($result, undef, 'mismatched forward confirmation returns undef');
};

# Purpose: when forward confirmation succeeds the hostname is returned
subtest '_verified_rdns() - successful forward confirmation returns hostname' => sub {
	# Mock _rdns_forward to confirm 127.0.0.1 so verification succeeds
	my $guard = mock_scoped 'CGI::ACL::_rdns_forward' => sub {
		return ($config{LOCAL_IP});
	};

	# 127.0.0.1 should have a PTR on any standard POSIX system
	my $result = CGI::ACL::_verified_rdns($config{LOCAL_IP});
	diag "_verified_rdns(LOCAL_IP) = " . (defined $result ? $result : 'undef') if $ENV{TEST_VERBOSE};
	ok(defined $result, 'valid forward confirmation returns hostname (defined)');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: _rdns_forward() (internal helper)
# Purpose: IPv4 and IPv6 resolution paths
# ─────────────────────────────────────────────────────────────────────────────
subtest '_rdns_forward() - IPv4: resolves dotted quad back to itself' => sub {
	# inet_aton('127.0.0.1') => packed form; inet_ntoa => '127.0.0.1'
	my @ips = CGI::ACL::_rdns_forward($config{LOCAL_IP}, AF_INET);
	diag "_rdns_forward($config{LOCAL_IP}) = " . join(', ', @ips) if $ENV{TEST_VERBOSE};
	ok(grep { $_ eq $config{LOCAL_IP} } @ips, '127.0.0.1 resolves back to itself');
};

# Purpose: IPv4 with an unresolvable name returns an empty list
subtest '_rdns_forward() - IPv4: unresolvable hostname returns empty list' => sub {
	my @ips = CGI::ACL::_rdns_forward('this.hostname.does.not.exist.invalid', AF_INET);
	is(scalar @ips, 0, 'unresolvable hostname returns empty list');
};

# Purpose: IPv6 path uses getaddrinfo; mock it to return a controlled address
subtest '_rdns_forward() - IPv6: mocked getaddrinfo returns expected IPs' => sub {
	use Socket qw(NI_NUMERICHOST);

	# Build a minimal fake addr hashref for the getaddrinfo return value
	my $fake_sockaddr = pack('C4', 0, 0, 0, 0);    # dummy sockaddr bytes

	# Mock getaddrinfo to return one addr entry with no error
	my $guard_gai = mock_scoped 'Socket::getaddrinfo' => sub {
		diag "mock getaddrinfo called" if $ENV{TEST_VERBOSE};
		return (0, { addr => $fake_sockaddr });
	};

	# Mock getnameinfo to return our expected IPv6 address
	my $guard_gni = mock_scoped 'Socket::getnameinfo' => sub {
		return (0, $config{IPv6_ADDR});
	};

	my $family = Socket::AF_INET6;
	my @ips = CGI::ACL::_rdns_forward('ip6-localhost', $family);
	diag "_rdns_forward IPv6 mocked result: " . join(', ', @ips) if $ENV{TEST_VERBOSE};
	ok(grep { $_ eq $config{IPv6_ADDR} } @ips, 'mocked IPv6 forward returns expected IP');
};

# Purpose: IPv6 path with getaddrinfo error returns empty list
subtest '_rdns_forward() - IPv6: getaddrinfo error returns empty list' => sub {
	my $guard = mock_scoped 'Socket::getaddrinfo' => sub {
		return ('Name or service not known');    # non-zero error string
	};

	my $family = Socket::AF_INET6;
	my @ips = CGI::ACL::_rdns_forward('nosuchhost.invalid', $family);
	is(scalar @ips, 0, 'getaddrinfo error returns empty list');
};

# Purpose: IPv6 path where getnameinfo returns an error skips that address
subtest '_rdns_forward() - IPv6: getnameinfo error is skipped' => sub {
	use Socket qw(NI_NUMERICHOST);

	my $fake_sockaddr = pack('C4', 0, 0, 0, 0);

	# getaddrinfo succeeds but getnameinfo fails for every address
	my $guard_gai = mock_scoped 'Socket::getaddrinfo' => sub {
		return (0, { addr => $fake_sockaddr });
	};
	my $guard_gni = mock_scoped 'Socket::getnameinfo' => sub {
		return ('EAI_NONAME');    # non-zero error
	};

	my $family = Socket::AF_INET6;
	my @ips = CGI::ACL::_rdns_forward('ip6-localhost', $family);

	# A getnameinfo error means the address is skipped, list is empty
	is(scalar @ips, 0, 'getnameinfo error skips the address, returns empty list');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: new() — clone isolation (deep copy)
# Purpose: mutations to a clone must never propagate back to the original.
# The deep copy covers allowed_ips, deny_countries, and allow_countries.
# Derived caches (_cidrlist, _cloud_cache) must be cleared on every clone.
# ─────────────────────────────────────────────────────────────────────────────
subtest 'new() - clone deep-copies allowed_ips (mutations isolated)' => sub {
	my $orig  = CGI::ACL->new()->allow_ip($config{RFC5737_IP});
	my $clone = $orig->new();
	diag "orig allowed_ips addr=" . refaddr($orig->{allowed_ips}) .
	     " clone addr=" . refaddr($clone->{allowed_ips}) if $ENV{TEST_VERBOSE};

	isnt(refaddr($orig->{allowed_ips}), refaddr($clone->{allowed_ips}),
		'clone gets a fresh allowed_ips hashref (not the same reference)');

	$clone->allow_ip($config{RFC5737_IP2});
	ok(!$orig->{allowed_ips}{ $config{RFC5737_IP2} },
		'IP added to clone does not appear in original');
};

subtest 'new() - clone deep-copies deny_countries (mutations isolated)' => sub {
	my $orig  = CGI::ACL->new()->deny_country($config{COUNTRY_GB});
	my $clone = $orig->new();

	isnt(refaddr($orig->{deny_countries}), refaddr($clone->{deny_countries}),
		'clone gets a fresh deny_countries hashref');

	$clone->deny_country($config{COUNTRY_US});
	ok(!$orig->{deny_countries}{ $config{COUNTRY_US} },
		'country denied in clone does not affect original');
};

subtest 'new() - clone clears _cidrlist and _cloud_cache' => sub {
	# Derived caches belong to the object; they must be cleared on clone
	# so the fresh object rebuilds them from its own (possibly modified) state.
	my $orig = CGI::ACL->new()->allow_ip($config{RFC5737_CIDR});
	$orig->{_cidrlist}    = ['synthetic-cidr'];
	$orig->{_cloud_cache} = { $config{RFC5737_IP} => { result => 1, expires => time() + 9999 } };

	my $clone = $orig->new();

	ok(!defined $clone->{_cidrlist},    'clone starts with no _cidrlist');
	ok(!defined $clone->{_cloud_cache}, 'clone starts with no _cloud_cache');
};

# ─────────────────────────────────────────────────────────────────────────────
# deny_country() / allow_country() — empty arrayref and undef-element edge cases
# Purpose: an empty arrayref must be a strict no-op (no hashref created).
# A arrayref containing undef must have those elements silently filtered.
# ─────────────────────────────────────────────────────────────────────────────
subtest 'deny_country() - empty arrayref is a no-op, no deny_countries created' => sub {
	# If deny_countries is created as {} (truthy empty hashref), the early-return
	# guard would fire and all subsequent calls would require a lingua argument.
	my $acl = CGI::ACL->new();
	$acl->deny_country(country => []);
	is($acl->{deny_countries}, undef,
		'deny_country([]) must leave deny_countries as undef');
};

subtest 'deny_country() - arrayref with undef elements filters them out' => sub {
	my $acl = CGI::ACL->new();
	$acl->deny_country(country => [ $config{COUNTRY_GB}, undef, $config{COUNTRY_US} ]);
	ok($acl->{deny_countries}{ $config{COUNTRY_GB} }, 'GB stored correctly');
	ok($acl->{deny_countries}{ $config{COUNTRY_US} }, 'US stored correctly');
	ok(!exists $acl->{deny_countries}{''}, 'empty-string key absent (undef was filtered)');
	is(scalar keys %{$acl->{deny_countries}}, 2, 'exactly two keys in deny_countries');
};

subtest 'allow_country() - empty arrayref is a no-op, no allow_countries created' => sub {
	my $acl = CGI::ACL->new();
	$acl->allow_country(country => []);
	is($acl->{allow_countries}, undef,
		'allow_country([]) must leave allow_countries as undef');
};

subtest 'allow_country() - arrayref with undef elements filters them out' => sub {
	my $acl = CGI::ACL->new();
	$acl->allow_country(country => [ undef, $config{COUNTRY_US}, undef ]);
	ok($acl->{allow_countries}{ $config{COUNTRY_US} }, 'US stored from mixed arrayref');
	ok(!exists $acl->{allow_countries}{''}, 'empty-string key absent (undef was filtered)');
	is(scalar keys %{$acl->{allow_countries}}, 1, 'exactly one key in allow_countries');
};

# ─────────────────────────────────────────────────────────────────────────────
# _set_countries() — undef element filtering
# Purpose: a bug here would silently store '' as a country code and could
# match falsy $@ or empty lingua->country() returns in unexpected ways.
# ─────────────────────────────────────────────────────────────────────────────
subtest '_set_countries() - undef elements in arrayref are silently skipped' => sub {
	my $h = {};
	CGI::ACL::_set_countries($h, [ $config{COUNTRY_GB}, undef, $config{COUNTRY_US} ]);
	ok($h->{ $config{COUNTRY_GB} }, 'GB stored');
	ok($h->{ $config{COUNTRY_US} }, 'US stored');
	ok(!exists $h->{''}, 'undef did not become empty-string key');
	is(scalar keys %{$h}, 2, 'exactly two keys stored (undef counted correctly)');
};

# ─────────────────────────────────────────────────────────────────────────────
# all_denied() — additional paths not covered by the earlier subtests
# ─────────────────────────────────────────────────────────────────────────────

# Purpose: absent REMOTE_ADDR must default to '127.0.0.1', not die or treat as invalid
subtest 'all_denied() - absent REMOTE_ADDR defaults to 127.0.0.1' => sub {
	delete local $ENV{REMOTE_ADDR};

	my $acl_match = CGI::ACL->new()->allow_ip($config{LOCAL_IP});
	is($acl_match->all_denied(), 0,
		'missing REMOTE_ADDR defaults to 127.0.0.1 — matches allow_ip');

	my $acl_no_match = CGI::ACL->new()->allow_ip($config{RFC5737_IP});
	is($acl_no_match->all_denied(), 1,
		'missing REMOTE_ADDR as 127.0.0.1 — not in allow list — denied');
};

# Purpose: a DNS failure inside _is_cloud_host() must never escape all_denied().
# The eval wrapper must catch it and fail safe (treat the IP as non-cloud).
subtest 'all_denied() - DNS exception in _is_cloud_host() is caught (fail-safe)' => sub {
	my $guard = mock_scoped 'CGI::ACL::_is_cloud_host' => sub {
		die "simulated DNS timeout\n";
	};
	my $acl = CGI::ACL->new()->deny_cloud();

	my $result = eval { denied_with_addr($acl, $config{RFC5737_IP}) };
	my $err    = $@; undef $@;

	is($err,    '',  'DNS exception does not propagate from all_denied()');
	is($result, 0,   'DNS failure treated as non-cloud (fail safe: allow)');
	diag "fail-safe result=$result" if $ENV{TEST_VERBOSE};
};

# Purpose: $@ must be cleared after catching a DNS exception so that any outer
# eval in the caller does not see a stale error string from inside all_denied().
subtest 'all_denied() - $@ is cleared after catching a DNS exception' => sub {
	my $guard = mock_scoped 'CGI::ACL::_is_cloud_host' => sub {
		die "intentional DNS die for $@ clearing test\n";
	};
	my $acl = CGI::ACL->new()->deny_cloud();

	denied_with_addr($acl, $config{RFC5737_IP});

	# $@ must not contain the DNS die message after all_denied() returns
	ok(!$@, '$@ is empty after all_denied() swallows the DNS exception');
};

# Purpose: the per-object cloud cache must eliminate repeated DNS round-trips
# for the same IP within the TTL.  We count _verified_rdns calls to prove it.
subtest 'all_denied() - cloud result is cached (second call skips DNS)' => sub {
	my $dns_calls = 0;
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		$dns_calls++;
		return undef;    # non-cloud
	};
	my $acl = CGI::ACL->new()->deny_cloud();
	diag "Expect exactly 1 DNS call for 2 back-to-back requests" if $ENV{TEST_VERBOSE};

	denied_with_addr($acl, $config{RFC5737_IP});
	is($dns_calls, 1, 'first request triggers one DNS lookup');

	denied_with_addr($acl, $config{RFC5737_IP});
	is($dns_calls, 1, 'second request uses cache — DNS not called again');
};

# Purpose: the cache is per-object; two independent ACL instances each do their
# own DNS lookup because their _cloud_cache hashrefs are separate.
subtest 'all_denied() - cloud cache is NOT shared between ACL objects' => sub {
	my $dns_calls = 0;
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		$dns_calls++;
		return undef;
	};

	my $acl1 = CGI::ACL->new()->deny_cloud();
	my $acl2 = CGI::ACL->new()->deny_cloud();

	denied_with_addr($acl1, $config{RFC5737_IP});
	denied_with_addr($acl2, $config{RFC5737_IP});

	is($dns_calls, 2, 'each object does its own DNS lookup (independent caches)');
};

# Purpose: a plain string passed as lingua must carp and return 1 (deny).
# The check happens BEFORE any country() call, preventing "can't call method on non-ref".
subtest 'all_denied() - non-blessed lingua carps and returns deny' => sub {
	my $acl = CGI::ACL->new()->deny_country($config{COUNTRY_BR});
	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};
	my $result;

	does_carp_that_matches(
		sub { $result = $acl->all_denied(lingua => 'plain-string') },
		qr/lingua must be a blessed object/,
	);
	is($result, 1, 'non-blessed lingua causes deny');
};

# Purpose: an exception thrown by lingua->country() must be caught inside all_denied().
# The $@ value must be cleared so the caller's eval (if any) is not confused.
subtest 'all_denied() - dying lingua->country() is caught, returns deny, $@ cleared' => sub {
	my $acl = CGI::ACL->new()->deny_country($config{COUNTRY_BR});
	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};

	my $result = eval { $acl->all_denied(lingua => Test::DyingLingua->new()) };
	my $err    = $@; undef $@;

	is($err, '', 'dying country() does not propagate from all_denied()');
	is($result, 1, 'exception from country() causes deny (unknown country)');
};

# Purpose: prove the boolean reduction for the cloud fast-path.
# deny_cloud + allow_country (no deny_country) must allow without consulting lingua.
# Before the optimization, this path would carp about a missing lingua and deny.
subtest 'all_denied() - deny_cloud + allow_country alone allows without lingua' => sub {
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };
	my $acl   = CGI::ACL->new()->deny_cloud()->allow_country($config{COUNTRY_GB_UPPER});
	diag "deny_cloud+allow_country: fast-path should return 0" if $ENV{TEST_VERBOSE};

	# No lingua — would carp if the country check fired.  Prove it does NOT fire.
	is(denied_with_addr($acl, $config{RFC5737_IP}), 0,
		'non-cloud IP allowed via cloud fast-path (no lingua, no carp)');
};

# Purpose: an injection string passed to allow_ip() must be rejected early (carp)
# and must not reach Net::CIDR or all_denied(); the valid CIDR added afterwards
# must still function correctly.
subtest 'all_denied() - invalid allow_ip entry is rejected early, valid CIDR still works' => sub {
	my $acl = CGI::ACL->new();

	# Injection string: now rejected at allow_ip() with a carp (not silently stored)
	does_carp(sub { $acl->allow_ip('"; DROP TABLE users; --') });

	# Valid CIDR added after the rejection must work normally
	$acl->allow_ip($config{RFC5737_CIDR});

	my $result = eval { denied_with_addr($acl, $config{CIDR_INSIDE}) };
	my $err    = $@; undef $@;

	is($err, '', 'no exception from all_denied() after an invalid entry was rejected');
	is($result, 0, 'IP inside valid CIDR still allowed after invalid entry was rejected');

	my $result2 = eval { denied_with_addr($acl, $config{CIDR_OUTSIDE}) };
	undef $@;
	is($result2, 1, 'IP outside all ranges is denied');
};

# ─────────────────────────────────────────────────────────────────────────────
# _is_cloud_host() — private/loopback/link-local IP short-circuit
# Purpose: the $PRIVATE_IP_RE guard must return 0 BEFORE calling _verified_rdns.
# Strategy: install a mock that explicitly fails the test if called.  If
# _is_cloud_host() incorrectly attempts DNS for a private address the mock
# fires and the test fails, making the regression immediately visible.
# ─────────────────────────────────────────────────────────────────────────────
for my $case (
	[ 'IPv4 loopback (127.0.0.1)',         '127.0.0.1'   ],
	[ 'RFC 1918 class A (10.0.0.1)',        '10.0.0.1'    ],
	[ 'RFC 1918 class B (172.16.0.1)',      '172.16.0.1'  ],
	[ 'RFC 1918 class C (192.168.1.1)',     '192.168.1.1' ],
	[ 'IPv4 link-local (169.254.1.1)',      '169.254.1.1' ],
	[ 'IPv6 loopback (::1)',               '::1'          ],
	[ 'IPv6 unique-local fc00::/7 (fc00::1)', 'fc00::1'   ],
	[ 'IPv6 link-local fe80::/10 (fe80::1)',  'fe80::1'   ],
) {
	my ($label, $ip) = @{$case};
	subtest "_is_cloud_host() - $label returns 0 without DNS" => sub {
		# The sentinel mock must NEVER be called; if it is, the short-circuit is broken
		my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
			fail("_verified_rdns called for private IP '$ip' — short-circuit is broken");
			return undef;
		};
		diag "_is_cloud_host($ip) — expect short-circuit" if $ENV{TEST_VERBOSE};
		is(CGI::ACL::_is_cloud_host($ip), 0, "$label returns 0 (no DNS call)");
	};
}

# ─────────────────────────────────────────────────────────────────────────────
# new() — _* key stripping (security: constructor injection prevention)
# Purpose: private/derived keys (names beginning with '_') must be stripped
# from all constructor arguments so a caller cannot pre-seed internal caches.
# Accepting _cloud_cache would let a caller mark any IP as non-cloud permanently.
# Accepting _cidrlist would inject a fabricated CIDR lookup structure.
# ─────────────────────────────────────────────────────────────────────────────

# Strategy: pass _cloud_cache as a constructor argument and confirm it is absent
# from the resulting object.  The test IPs are RFC 5737 documentation addresses.
subtest 'new() - _cloud_cache stripped from class constructor params' => sub {
	my $acl = CGI::ACL->new(
		deny_cloud   => 1,
		_cloud_cache => { $config{RFC5737_IP} => { result => 0, expires => 9_999_999_999 } },
	);
	ok(!defined($acl->{_cloud_cache}),
		'_cloud_cache is stripped from class-path constructor arguments');
	is($acl->{deny_cloud}, 1, 'public deny_cloud is preserved through _* stripping');
};

subtest 'new() - _cidrlist stripped from class constructor params' => sub {
	my $acl = CGI::ACL->new(
		_cidrlist => ['0.0.0.0/0'],   # allow-everything fabrication — must be stripped
	);
	ok(!defined($acl->{_cidrlist}),
		'_cidrlist is stripped from class-path constructor arguments');
};

subtest 'new() - _cloud_cache stripped from clone constructor params' => sub {
	# Exploit: $base->new(_cloud_cache => {...}) pre-seeds the DNS cache so
	# that a cloud IP is treated as non-cloud, bypassing deny_cloud() silently.
	my $orig  = CGI::ACL->new()->deny_cloud();
	my $clone = $orig->new(
		_cloud_cache => { $config{RFC5737_IP} => { result => 0, expires => 9_999_999_999 } },
	);
	ok(!defined($clone->{_cloud_cache}),
		'_cloud_cache is stripped from clone-path constructor arguments');
	is($clone->{deny_cloud}, 1, 'public deny_cloud is preserved through _* stripping in clone');
};

subtest 'new() - _cidrlist stripped from clone constructor params' => sub {
	my $orig  = CGI::ACL->new()->allow_ip($config{LOCAL_IP});
	my $clone = $orig->new(
		_cidrlist    => ['0.0.0.0/0'],   # fabricated; must not reach cidrlookup
	);
	ok(!defined($clone->{_cidrlist}),
		'_cidrlist is stripped from clone-path constructor arguments');
	# The clone's CIDR list must be re-derived from its own allowed_ips on next use
	is(denied_with_addr($clone, $config{RFC5737_IP}), 1,
		'non-listed IP denied; fabricated _cidrlist was not used');
};

# ─────────────────────────────────────────────────────────────────────────────
# _is_cloud_host() — RFC 1035 §3.1 hostname-length guard (added in 0.10)
# Purpose: a PTR record longer than 253 characters is protocol-invalid and
# must be rejected BEFORE any @CLOUD_PATTERNS regex work.  This prevents a
# compromised resolver from crafting an overlong hostname that embeds a cloud
# pattern at a position beyond the boundary.
# ─────────────────────────────────────────────────────────────────────────────

# Constant for boundary testing: ".compute-1.amazonaws.com" is 24 chars.
# 253 - 24 = 229 prefix chars => total exactly 253 chars (accepted).
# 230 prefix chars => total exactly 254 chars (rejected by > 253 guard).
Readonly my $CLOUD_SUFFIX_LEN => length('.compute-1.amazonaws.com');

subtest '_is_cloud_host() - PTR hostname exactly 253 chars passes length guard (cloud match)' => sub {
	# The RFC 1035 guard is `> 253`, so 253 is the last allowed length.
	# A 253-char cloud hostname must still be detected as cloud.
	my $prefix        = 'a' x (253 - $CLOUD_SUFFIX_LEN);
	my $hostname_253  = $prefix . '.compute-1.amazonaws.com';
	is(length($hostname_253), 253, 'precondition: hostname is exactly 253 chars');

	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $hostname_253 };
	diag "_is_cloud_host: 253-char AWS hostname -> expect 1" if $ENV{TEST_VERBOSE};
	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 1,
		'253-char cloud hostname detected (RFC 1035 guard does not fire at boundary)');
};

subtest '_is_cloud_host() - PTR hostname > 253 chars is rejected before pattern matching' => sub {
	# 254-char hostname: must return 0 regardless of content (length guard fires first).
	# We intentionally embed a valid cloud suffix so the only possible return-0 path
	# is the RFC 1035 length check — if patterns ran, the result would be 1.
	my $prefix        = 'a' x (254 - $CLOUD_SUFFIX_LEN);
	my $hostname_254  = $prefix . '.compute-1.amazonaws.com';
	is(length($hostname_254), 254, 'precondition: hostname is exactly 254 chars');

	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $hostname_254 };
	diag "_is_cloud_host: 254-char hostname with cloud suffix -> expect 0 (RFC 1035 guard)" if $ENV{TEST_VERBOSE};
	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 0,
		'254-char hostname rejected by RFC 1035 guard; cloud pattern never consulted');
};

# ─────────────────────────────────────────────────────────────────────────────
# all_denied() — cloud cache internals (white-box TTL / expiry probes)
# Purpose: verify the exact cache structure and the expiry / non-caching paths.
# These are internal implementation details that the black-box tests in other
# files cannot reach.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'all_denied() - successful DNS lookup populates cache with correct TTL' => sub {
	# After a successful (non-error) DNS lookup the cache entry must have:
	# - result == 0 (non-cloud per mock)
	# - expires set to approximately now + 300 seconds
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };
	my $acl   = CGI::ACL->new()->deny_cloud();
	ok(!defined($acl->{_cloud_cache}), 'cache absent before any all_denied call');

	my $t_before = time();
	denied_with_addr($acl, $config{RFC5737_IP});
	my $t_after = time();

	diag "Cache after lookup: " . join(', ', map { "$_=>" . ($acl->{_cloud_cache}{$config{RFC5737_IP}}{$_} // 'undef') } qw(result expires)) if $ENV{TEST_VERBOSE};

	ok(defined($acl->{_cloud_cache}), 'cache hashref created after first call');
	my $entry = $acl->{_cloud_cache}{ $config{RFC5737_IP} };
	ok(defined($entry), 'cache entry exists for the queried IP');
	is($entry->{result}, 0, 'cached result is 0 (non-cloud per mock)');
	ok($entry->{expires} > $t_after,        'expiry is in the future');
	ok($entry->{expires} <= $t_after + 301, 'expiry is within expected TTL window (~300s)');
};

subtest 'all_denied() - expired cache entry is evicted and DNS re-queried' => sub {
	# Strategy: perform one successful lookup to populate the cache, then
	# manually back-date the expiry to force a re-lookup on the next call.
	# The DNS call count must increment from 1 to 2.
	my $calls = 0;
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $calls++; return undef; };
	my $acl   = CGI::ACL->new()->deny_cloud();

	denied_with_addr($acl, $config{RFC5737_IP});
	is($calls, 1, 'first call triggers one DNS lookup');

	# Back-date the TTL so the entry looks expired
	$acl->{_cloud_cache}{ $config{RFC5737_IP} }{expires} = time() - 1;
	diag "Cache entry expired manually; second call should re-query DNS" if $ENV{TEST_VERBOSE};

	denied_with_addr($acl, $config{RFC5737_IP});
	is($calls, 2, 'second call re-queries DNS because cache entry is expired');
};

subtest 'all_denied() - DNS error result is NOT cached (retried on next call)' => sub {
	# When _verified_rdns (called inside _is_cloud_host) dies, the eval in
	# all_denied() captures $dns_error; the result is NOT written to the cache.
	# The next request must re-attempt the lookup rather than using a cached error.
	my $calls = 0;
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		$calls++;
		die "simulated resolver timeout\n";
	};
	my $acl = CGI::ACL->new()->deny_cloud();

	denied_with_addr($acl, $config{RFC5737_IP});
	is($calls, 1, 'first call triggers DNS (which fails)');

	# Cache must remain empty after a failed lookup
	ok(!defined($acl->{_cloud_cache}{ $config{RFC5737_IP} }),
		'failed lookup result is NOT stored in cache');
	diag "Cache entry absent after DNS error; next call must retry" if $ENV{TEST_VERBOSE};

	denied_with_addr($acl, $config{RFC5737_IP});
	is($calls, 2, 'second call retries DNS — error result was not cached');
};

subtest 'all_denied() - deny_cloud + allow_ip: non-cloud IP not in allow list is denied' => sub {
	# After the cloud check passes (non-cloud), the IP allow-list check fires.
	# An IP not in the allow list must fall through and be denied.
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };
	my $acl   = CGI::ACL->new()->deny_cloud()->allow_ip($config{RFC5737_IP});

	is(denied_with_addr($acl, $config{RFC5737_IP}),  0, 'listed non-cloud IP allowed');
	is(denied_with_addr($acl, $config{RFC5737_IP2}), 1, 'unlisted non-cloud IP denied');
};

# ─────────────────────────────────────────────────────────────────────────────
# all_denied() — country normalisation and falsy-country edge cases
# Purpose: all_denied() must call lc() on the value returned by lingua->country()
# before comparing it against the stored (already-lowercased) deny/allow sets.
# Additionally, any falsy country value (undef, '', '0') must trigger deny.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'all_denied() - uppercase country code from lingua is normalised with lc()' => sub {
	# deny_country() stores 'cn' (lowercase); lingua returns 'CN' (uppercase).
	# The lc() in all_denied() must normalise before the hash lookup so the
	# comparison still fires correctly.
	my $acl = CGI::ACL->new()->deny_country('CN');
	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};
	diag "Checking lc() normalisation: lingua returns 'CN', stored as 'cn'" if $ENV{TEST_VERBOSE};

	is($acl->all_denied(lingua => Test::FakeLingua->new('CN')), 1,
		'uppercase CN from lingua matches lowercase-stored deny entry');
	is($acl->all_denied(lingua => Test::FakeLingua->new('cn')), 1,
		'lowercase cn from lingua also matches (control)');
	is($acl->all_denied(lingua => Test::FakeLingua->new('GB')), 0,
		'non-denied country (GB) still allowed with lc() in place');
};

subtest 'all_denied() - uppercase country code normalised in wildcard-deny + allow list' => sub {
	# deny_country('*') + allow_country('GB') — lingua returns 'GB' (uppercase).
	# The stored allow key is 'gb'.  lc() must normalise before the allow lookup.
	my $acl = CGI::ACL->new()
		->deny_all_countries()
		->allow_country('GB');
	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};

	is($acl->all_denied(lingua => Test::FakeLingua->new('GB')), 0,
		'uppercase GB from lingua is allowed (lc normalisation matches stored key)');
	is($acl->all_denied(lingua => Test::FakeLingua->new('US')), 1,
		'non-allowed uppercase US is denied');
};

subtest 'all_denied() - empty-string country from lingua causes deny' => sub {
	# Empty string is Perl-falsy; the `$country = $country_val or return 1` guard
	# must treat it as "unknown country" and deny — the same as undef.
	my $acl = CGI::ACL->new()->deny_country($config{COUNTRY_BR});
	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};
	is($acl->all_denied(lingua => Test::FakeLingua->new('')), 1,
		'empty-string country is treated as unknown and denied');
};

subtest 'all_denied() - "0" country string from lingua causes deny (Perl-falsy)' => sub {
	# The string "0" is Perl-falsy.  A lingua whose country() returns "0" must
	# be treated the same as undef (unknown country → deny).
	my $acl = CGI::ACL->new()->deny_country($config{COUNTRY_BR});
	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};
	is($acl->all_denied(lingua => Test::FakeLingua->new('0')), 1,
		'"0" country string treated as falsy/unknown and denied');
};

# ─────────────────────────────────────────────────────────────────────────────
# deny_country() / allow_country() — additional calling-style and accumulation tests
# ─────────────────────────────────────────────────────────────────────────────

subtest 'deny_country() - multiple sequential calls accumulate countries' => sub {
	# Each call must ADD to deny_countries, not replace it.
	my $acl = CGI::ACL->new()
		->deny_country('CN')
		->deny_country('RU')
		->deny_country('KP');
	diag "deny_countries keys: " . join(', ', sort keys %{$acl->{deny_countries}}) if $ENV{TEST_VERBOSE};

	ok($acl->{deny_countries}{cn}, 'CN accumulated after first call');
	ok($acl->{deny_countries}{ru}, 'RU accumulated after second call');
	ok($acl->{deny_countries}{kp}, 'KP accumulated after third call');
	is(scalar keys %{$acl->{deny_countries}}, 3, 'exactly 3 countries stored (no overwrite)');
};

subtest 'allow_country() - named param scalar form stores country correctly' => sub {
	# Confirm the two-arg named-pair form (not an arrayref) works: allow_country(country => 'US')
	# Confirm the two-arg named-pair form routes through Params::Get correctly.
	my $acl = CGI::ACL->new();
	$acl->allow_country(country => $config{COUNTRY_US_UPPER});
	diag "allow_countries after named-scalar: " . join(', ', sort keys %{$acl->{allow_countries}}) if $ENV{TEST_VERBOSE};

	ok($acl->{allow_countries}{ $config{COUNTRY_US} }, 'US stored via named-scalar form');
	ok(!$acl->{allow_countries}{ $config{COUNTRY_US_UPPER} }, 'uppercase key absent (stored lowercase)');
};

subtest 'deny_country() - named param scalar form stores country correctly' => sub {
	# Mirror of the allow_country test — same calling convention, different target hash.
	my $acl = CGI::ACL->new();
	$acl->deny_country(country => $config{COUNTRY_BR});
	ok($acl->{deny_countries}{ $config{COUNTRY_BR} }, 'BR stored via named-scalar deny_country form');
};

# ─────────────────────────────────────────────────────────────────────────────
# allow_ip() — fail-closed initialisation guarantee (white-box)
# Purpose: even when EVERY allow_ip() call receives an invalid value and carps,
# allowed_ips must be initialised to {} (not left as undef).  Without this,
# the early-return guard in all_denied() would treat the ACL as unrestricted
# and allow all traffic — a fail-open security regression.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'allow_ip() - fail-closed: allowed_ips initialised to {} even on all-invalid input' => sub {
	# The `$self->{allowed_ips} //= {}` line runs BEFORE format validation.
	# Verify the resulting object has a defined (empty) hashref so the guard
	# in all_denied() enters the IP-check branch and finds no match → deny.
	my $acl = CGI::ACL->new();
	does_carp(sub { $acl->allow_ip('not-an-ip-at-all') });

	ok(defined($acl->{allowed_ips}),   'allowed_ips is defined (not undef) after invalid allow_ip');
	is(ref($acl->{allowed_ips}), 'HASH', 'allowed_ips is a HASH ref');
	ok(!%{$acl->{allowed_ips}},        'allowed_ips is empty — invalid entry was not stored');

	# The empty hashref triggers the IP-check branch which finds no match → deny.
	is(denied_with_addr($acl, $config{RFC5737_IP}), 1,
		'all-invalid allow_ip ACL fails closed (denies all traffic)');
};

# ─────────────────────────────────────────────────────────────────────────────
# Subtest: memory cycle checks
# Purpose: objects must be garbage-collectible (no circular refs)
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Memory cycle: plain ACL object has no cycles' => sub {
	my $acl = CGI::ACL->new();
	memory_cycle_ok($acl, 'fresh CGI::ACL object has no cycles');
};

# Purpose: an ACL with all restriction types set must also be cycle-free
subtest 'Memory cycle: fully configured ACL has no cycles' => sub {
	local $ENV{REMOTE_ADDR} = $config{LOCAL_IP};

	my $acl = CGI::ACL->new()
		->allow_ip($config{RFC5737_IP})
		->deny_country($config{COUNTRY_BR})
		->allow_country($config{COUNTRY_GB})
		->deny_cloud();

	# Trigger memoisation of _cidrlist by calling all_denied
	{
		my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };
		$acl->all_denied(lingua => Test::FakeLingua->new($config{COUNTRY_GB}));
	}

	diag "Checking cycle safety for fully configured ACL" if $ENV{TEST_VERBOSE};
	memory_cycle_ok($acl, 'fully configured ACL with cidrlist has no cycles');
};

done_testing();
