#!/usr/bin/env perl
# edge_cases.t -- destructive, pathological, boundary and security tests
#
# Actively tries to break CGI::ACL with degenerate inputs: undef, 0, "",
# typeglobs, circular refs, injection strings, and upstream mock failures.
# Every test documents what the code *should* do, not what it happens to do.

use strict;
use warnings;

use Carp;	# keeps main::carp defined so Test::Carp's glob restore works correctly
use Scalar::Util qw(blessed);
use Test::Carp qw(does_carp_that_matches);
use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Warn;
use Readonly;

BEGIN {
	use_ok('CGI::ACL') or BAIL_OUT('CGI::ACL failed to load');
}

# ── Configuration ─────────────────────────────────────────────────────────────

# All magic values live here; no bare strings or numbers anywhere else.
Readonly my %config => (
	# Valid IPs for use as known-good references
	VALID_IP      => '203.0.113.5',     # RFC 5737 TEST-NET-3
	VALID_IP2     => '198.51.100.1',    # RFC 5737 TEST-NET-2
	VALID_CIDR    => '192.0.2.0/24',    # RFC 5737 TEST-NET-1
	CIDR_INSIDE   => '192.0.2.99',      # inside VALID_CIDR
	LOCAL_IP      => '127.0.0.1',       # loopback
	ZERO_IP       => '0.0.0.0',         # all-zero quad
	BCAST_IP      => '255.255.255.255', # broadcast
	IPV6_VALID    => '2001:db8::1',     # RFC 3849 doc IPv6
	ALLOW_ALL     => '0.0.0.0/0',       # default-route CIDR -- allows everything

	# Country codes
	CC_GB         => 'gb',
	CC_US         => 'us',
	WILDCARD      => '*',

	# Attack / injection strings
	SHELL_INJECT  => '1.2.3.4;rm -rf /',
	SQL_INJECT    => "' OR 1=1 --",
	NEWLINE_SPLIT => "1.2.3.4\nX-Injected-Header: evil",
	NULL_BYTE     => "1.2.3.4\x00evil",
	LONG_STRING   => ('A' x 65536),     # 64 KiB of garbage

	# Upstream mock return values (edge cases passed to cloud-check helpers)
	MOCK_EMPTY    => '',
	MOCK_ZERO_STR => '0',
	MOCK_UNDEF    => undef,

	# Error message substrings expected in carps / croaks
	ERR_ALLOW_IP  => 'Usage: allow_ip($ip_address)',
	ERR_DENY_CC   => 'Usage: deny_country($country)',
	ERR_ALLOW_CC  => 'Usage: allow_country($country)',
	ERR_LINGUA    => 'Usage: all_denied($lingua)',
	ERR_NEW       => 'use ->new() not ::new() to instantiate',
);

# ── Helper ────────────────────────────────────────────────────────────────────

# Run all_denied with REMOTE_ADDR scoped to $ip, forwarding any extra args.
sub denied_at {
	my ($acl, $ip, @rest) = @_;
	local $ENV{REMOTE_ADDR} = $ip;
	return $acl->all_denied(@rest);
}

# ─────────────────────────────────────────────────────────────────────────────
# CONSTRUCTOR EDGE CASES
# ─────────────────────────────────────────────────────────────────────────────
subtest 'new(): plain-function call carps and returns undef' => sub {
	# CGI::ACL::new() called without a class is a usage error
	my $ret;
	does_carp_that_matches(
		sub { $ret = CGI::ACL::new() },
		'plain CGI::ACL::new() carps',
		qr/\Q$config{ERR_NEW}\E/
	);
	ok(!defined($ret), 'plain new() returns undef (not a broken object)');
};

subtest 'new(): undef/empty params do not crash' => sub {
	# Passing undef or empty hashref should produce a functional empty object
	my $acl_empty  = CGI::ACL->new();
	my $acl_undef  = CGI::ACL->new(undef);   # silently accepted
	isa_ok($acl_empty, 'CGI::ACL', 'no-arg new() returns object');
	isa_ok($acl_undef, 'CGI::ACL', 'undef-arg new() returns object');

	# Both should have no restrictions → all_denied returns 0
	is(denied_at($acl_empty,  $config{VALID_IP}), 0, 'empty ACL allows all');
	is(denied_at($acl_undef,  $config{VALID_IP}), 0, 'undef-param ACL allows all');
};

subtest 'new(): clone deep-copies nested hashes — mutations are isolated' => sub {
	# Shallow copy would allow a clone to corrupt the original's country list
	my $orig  = CGI::ACL->new()->deny_country($config{CC_GB});
	my $clone = $orig->new();

	$clone->deny_country($config{CC_US});
	ok( $clone->{deny_countries}{ $config{CC_US} }, 'clone has the new denial');
	ok(!$orig->{deny_countries}{ $config{CC_US} },  'original is unaffected');
};

subtest 'new(): circular reference in params does not crash' => sub {
	# A circular reference blessed into CGI::ACL should not explode at
	# construction time (though it may produce odd serialisation elsewhere)
	my %params;
	$params{_self_ref} = \%params;    # circular

	my $acl = eval { CGI::ACL->new(%params) };
	ok(!$@,         'circular ref in constructor does not throw');
	isa_ok($acl, 'CGI::ACL', 'still returns a CGI::ACL object');
};

subtest 'new(): private cache keys are stripped from clone constructor params' => sub {
	# Exploit scenario: caller passes _cloud_cache with a pre-seeded entry that
	# marks a cloud IP as non-cloud (result => 0) with a far-future expiry.
	# If the cache entry were accepted, all_denied() would trust the cache hit
	# and never call DNS, silently bypassing deny_cloud() for the targeted IP.
	my $orig  = CGI::ACL->new()->deny_cloud();
	my $clone = $orig->new(
		_cloud_cache => { $config{VALID_IP} => { result => 0, expires => 9_999_999_999 } },
		_cidrlist    => ['synthetic-cidr-entry'],
	);

	ok(!defined($clone->{_cloud_cache}),
		'_cloud_cache is stripped from clone params (cache injection prevented)');
	ok(!defined($clone->{_cidrlist}),
		'_cidrlist is stripped from clone params (CIDR injection prevented)');
	ok($clone->{deny_cloud},
		'deny_cloud (public key) is preserved through clone');
};

subtest 'new(): private cache keys are stripped from class constructor params' => sub {
	# Same injection via the class-method path (CGI::ACL->new(_cloud_cache => ...))
	# The injected key flows through Object::Configure::configure; it must be
	# stripped from the bless'd hashref before the object is returned.
	my $acl = CGI::ACL->new(
		deny_cloud   => 1,
		_cloud_cache => { $config{VALID_IP} => { result => 0, expires => 9_999_999_999 } },
	);

	ok(!defined($acl->{_cloud_cache}),
		'_cloud_cache is stripped from class constructor (env-var injection path closed)');
	ok($acl->{deny_cloud},
		'deny_cloud (public key) survives stripping');
};

# ─────────────────────────────────────────────────────────────────────────────
# allow_ip EDGE CASES
# ─────────────────────────────────────────────────────────────────────────────
subtest 'allow_ip(): bad-ref arguments carp and return $self (no crash)' => sub {
	my $acl = CGI::ACL->new();

	# Scalar ref must carp and return $self for method-chaining safety
	my ($ret_sref, $ret_aref, $ret_cref);
	does_carp(sub { $ret_sref = $acl->allow_ip(\'scalar ref')   });
	does_carp(sub { $ret_aref = $acl->allow_ip([])              });
	does_carp(sub { $ret_cref = $acl->allow_ip(sub { })         });

	# All must return $self so the chain is unbroken
	is($ret_sref, $acl, 'allow_ip(scalar ref) returns $self');
	is($ret_aref, $acl, 'allow_ip(arrayref)   returns $self');
	is($ret_cref, $acl, 'allow_ip(coderef)    returns $self');
};

subtest 'allow_ip(): no-arg and undef-ip carp and return $self' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{VALID_IP});

	# Calling with no args must carp
	my $ret_noarg;
	does_carp(sub { $ret_noarg = $acl->allow_ip() });
	is($ret_noarg, $acl, 'allow_ip() returns $self');

	# Named key with undef value must also carp
	my $ret_undef;
	does_carp(sub { $ret_undef = $acl->allow_ip(ip => undef) });
	is($ret_undef, $acl, 'allow_ip(ip=>undef) returns $self');
};

subtest 'allow_ip(): "0.0.0.0/0" (default-route CIDR) allows every IP' => sub {
	# This is extreme but valid: a /0 encompass the entire IPv4 space
	my $acl = CGI::ACL->new()->allow_ip($config{ALLOW_ALL});
	diag "allow_ip(0.0.0.0/0) — expect all IPs allowed" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{VALID_IP}),  0, '0.0.0.0/0 allows arbitrary IP');
	is(denied_at($acl, $config{LOCAL_IP}),  0, '0.0.0.0/0 allows loopback');
	is(denied_at($acl, $config{ZERO_IP}),   0, '0.0.0.0/0 allows 0.0.0.0');
};

subtest 'allow_ip(): injection strings are rejected with carp, not stored' => sub {
	# allow_ip() now validates format at input and carps on invalid values.
	# Previously invalid strings were silently stored and discarded by the
	# eval-wrapped Net::CIDR calls; this change rejects them early, preventing
	# memory accumulation in persistent processes and O(n) cidradd overhead.
	my $acl = CGI::ACL->new();

	for my $bad ($config{SHELL_INJECT}, $config{SQL_INJECT}, $config{LONG_STRING}) {
		my $ret;
		does_carp(sub { $ret = $acl->allow_ip($bad) });
		is($ret, $acl, 'allow_ip returns $self on invalid input (chaining not broken)');
	}
	diag "allow_ip with injection strings rejected" if $ENV{TEST_VERBOSE};

	# allowed_ips MUST be defined (as an empty hashref) so that the early-return
	# guard in all_denied() sees "IP restrictions configured" and does not allow
	# all traffic (fail-open).  The values must be empty (nothing stored).
	ok(defined($acl->{allowed_ips}),        'allowed_ips initialised to signal IP restrictions intended');
	ok(!%{$acl->{allowed_ips}},             'allowed_ips is empty — invalid entries were not stored');

	# With an empty allow-list the IP check finds no match → all_denied denies (fail-closed).
	my $result = eval { denied_at($acl, $config{VALID_IP}) };
	ok(!$@,     'all_denied does not throw when only invalid entries were attempted');
	is($result, 1, 'VALID_IP denied — empty allow-list fails closed, not open');
};

# ─────────────────────────────────────────────────────────────────────────────
# deny_country / allow_country EDGE CASES
# ─────────────────────────────────────────────────────────────────────────────
subtest 'deny_country(): bad-ref arguments carp and return $self' => sub {
	my $acl = CGI::ACL->new();
	my ($ret_sref, $ret_cref);

	does_carp(sub { $ret_sref = $acl->deny_country(\'not a hash') });
	does_carp(sub { $ret_cref = $acl->deny_country(sub { })       });

	is($ret_sref, $acl, 'deny_country(scalar ref) returns $self');
	is($ret_cref, $acl, 'deny_country(coderef)    returns $self');

	# Neither call must have touched deny_countries
	ok(!defined($acl->{deny_countries}), 'deny_countries is still undef after bad args');
};

subtest 'deny_country(): empty arrayref is a no-op (no restriction created)' => sub {
	# deny_country(country => []) means "deny no countries".
	# It must NOT create an empty deny_countries hashref that trips the
	# early-return guard and causes all traffic to be denied.
	my $acl = CGI::ACL->new()->deny_country(country => []);

	diag "deny_country([]) — expect no restriction, all_denied returns 0" if $ENV{TEST_VERBOSE};

	# No restriction was actually registered — the empty list is a no-op
	is(denied_at($acl, $config{VALID_IP}), 0,
		'empty country arrayref is a no-op: all traffic still allowed');
};

subtest 'deny_country(): arrayref with undef elements skips undef, keeps valid codes' => sub {
	# undef in the list must not be stored as "" and must not emit a warning
	my $acl;
	warning_is {
		$acl = CGI::ACL->new()->deny_country(country => [undef, $config{CC_GB}, undef]);
	} undef, 'no warnings from arrayref containing undef';

	diag "deny_countries: " . join(',', sort keys %{$acl->{deny_countries} // {}}) if $ENV{TEST_VERBOSE};

	ok(!$acl->{deny_countries}{''}, 'empty string is NOT stored as a country key');
	ok( $acl->{deny_countries}{$config{CC_GB}}, 'valid code from array is stored');
};

subtest 'allow_country(): same edge cases as deny_country' => sub {
	my $acl = CGI::ACL->new();

	# Empty arrayref must be a no-op — must not create allow_countries = {}
	$acl->allow_country(country => []);
	ok(!defined($acl->{allow_countries}),
		'allow_country([]) leaves allow_countries undef');

	# Arrayref with undef skips undef silently
	my $acl2;
	warning_is {
		$acl2 = CGI::ACL->new()->allow_country(country => [undef, $config{CC_US}]);
	} undef, 'no warnings from allow_country([undef, cc])';

	ok(!$acl2->{allow_countries}{''},             'no "" key stored');
	ok( $acl2->{allow_countries}{$config{CC_US}}, 'valid code stored');
};

# ─────────────────────────────────────────────────────────────────────────────
# all_denied(): REMOTE_ADDR SECURITY EDGE CASES
# ─────────────────────────────────────────────────────────────────────────────
subtest 'all_denied(): injection strings in REMOTE_ADDR are denied' => sub {
	# Any non-IP in REMOTE_ADDR must be rejected before reaching any ACL logic.
	# These strings must all return 1 (deny), even if a matching allow-list
	# entry exists, because the address itself is syntactically invalid.
	my $acl = CGI::ACL->new()->allow_ip($config{VALID_IP});

	my @attacks = (
		[ $config{SHELL_INJECT},   'shell injection in REMOTE_ADDR' ],
		[ $config{SQL_INJECT},     'SQL injection in REMOTE_ADDR'   ],
		[ $config{NEWLINE_SPLIT},  'HTTP header split in REMOTE_ADDR' ],
		[ $config{NULL_BYTE},      'null byte in REMOTE_ADDR'       ],
		[ $config{LONG_STRING},    'oversized REMOTE_ADDR'          ],
		[ 'not-an-ip',             'plain non-IP string'            ],
		[ '999.999.999.999',       'out-of-range quad'              ],
		[ '1.2.3.4.5',             'five-octet quad'                ],
		[ '1.2.3',                 'three-octet partial'            ],
	);

	for my $case (@attacks) {
		my ($addr, $desc) = @$case;
		diag "Attack: $desc" if $ENV{TEST_VERBOSE};
		is(denied_at($acl, $addr), 1, "$desc is denied");
	}
};

subtest 'all_denied(): falsy REMOTE_ADDR "0" does not fall back to 127.0.0.1' => sub {
	# REMOTE_ADDR = "0" is a defined but falsy value.
	# Using || for the fallback would silently substitute 127.0.0.1, which
	# could be in the allow-list — a security bypass.
	# The correct operator is // (defined-or).
	my $acl = CGI::ACL->new()->allow_ip($config{LOCAL_IP});

	# "0" is not a valid IPv4 address; it must be rejected (denied) directly,
	# NOT treated as if 127.0.0.1 were the client address.
	is(denied_at($acl, '0'), 1,
		'"0" REMOTE_ADDR is denied (not treated as loopback via || fallback)');
};

subtest 'all_denied(): empty-string REMOTE_ADDR does not fall back to 127.0.0.1' => sub {
	# Same hazard as "0": empty string "" is falsy, so || causes it to fall
	# back to 127.0.0.1.  Must use // so "" is validated (and rejected) itself.
	my $acl = CGI::ACL->new()->allow_ip($config{LOCAL_IP});

	is(denied_at($acl, ''), 1,
		'"" REMOTE_ADDR is denied (not treated as loopback via || fallback)');
};

subtest 'all_denied(): undef REMOTE_ADDR falls back to 127.0.0.1 safely' => sub {
	# undef (not set) is the documented fallback case.  The DEFAULT_ADDR
	# (127.0.0.1) is used, which is still subject to normal ACL rules.
	my $acl = CGI::ACL->new()->allow_ip($config{VALID_IP});

	# 127.0.0.1 is NOT in the allow-list → must be denied
	local $ENV{REMOTE_ADDR} = undef;
	is($acl->all_denied(), 1, 'undef REMOTE_ADDR falls back to 127.0.0.1 → denied');

	# Add loopback explicitly — now the fallback address must be allowed
	$acl->allow_ip($config{LOCAL_IP});
	is($acl->all_denied(), 0, 'after allow_ip(127.0.0.1), undef REMOTE_ADDR is allowed');
};

subtest 'all_denied(): boundary IPs 0.0.0.0 and 255.255.255.255 are valid addresses' => sub {
	# These are syntactically valid IPv4 addresses even if unusual.
	# They must be processed by the normal ACL logic, not rejected.
	my $acl = CGI::ACL->new()->allow_ip($config{ZERO_IP});
	diag "boundary IPs: 0.0.0.0 and 255.255.255.255" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{ZERO_IP}),  0, '0.0.0.0 is allowed when explicitly in list');
	is(denied_at($acl, $config{BCAST_IP}), 1, '255.255.255.255 is denied (not in list)');
};

subtest 'all_denied(): valid IPv6 addresses are processed normally' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{IPV6_VALID});
	diag "IPv6 ACL check: $config{IPV6_VALID}" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{IPV6_VALID}),   0, 'exact IPv6 match is allowed');
	is(denied_at($acl, '2001:db8::2'),         1, 'different IPv6 is denied');
	is(denied_at($acl, '::1'),                 1, 'IPv6 loopback denied when not listed');
};

# ─────────────────────────────────────────────────────────────────────────────
# all_denied(): LINGUA EDGE CASES
# ─────────────────────────────────────────────────────────────────────────────

# Build a minimal mock lingua object with a configurable country() return value
{
	package MockLingua;
	sub new  { my ($class, %args) = @_; bless { country => $args{country} }, $class }
	sub country { $_[0]->{country} }
}

subtest 'all_denied(): lingua->country() returning undef denies access' => sub {
	# Unknown country (undef from lingua) must be denied per the POD spec
	my $acl = CGI::ACL->new()->deny_country($config{CC_GB});
	my $lingua = MockLingua->new(country => undef);
	diag "lingua country=undef" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{VALID_IP}, lingua => $lingua), 1,
		'undef country from lingua results in deny');
};

subtest 'all_denied(): lingua->country() returning empty string denies access' => sub {
	# "" is falsy — the code uses if(my $country = $lingua->country()) so
	# an empty string should be treated the same as undef: unknown → deny
	my $acl = CGI::ACL->new()->deny_country($config{CC_GB});
	my $lingua = MockLingua->new(country => '');
	diag "lingua country=''" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{VALID_IP}, lingua => $lingua), 1,
		'empty-string country from lingua results in deny');
};

subtest 'all_denied(): lingua->country() returning "0" denies access' => sub {
	# "0" is falsy — must be treated as unknown country, not as country code "0"
	my $acl = CGI::ACL->new()->deny_country($config{CC_GB});
	my $lingua = MockLingua->new(country => '0');
	diag "lingua country='0'" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{VALID_IP}, lingua => $lingua), 1,
		'"0" country from lingua results in deny (falsy = unknown)');
};

subtest 'all_denied(): non-object string as lingua carps instead of dying' => sub {
	# Passing a plain string where an object is expected must carp, not die.
	# Dying is uncatchable in CGI scripts that don't wrap all_denied() in eval.
	my $acl = CGI::ACL->new()->deny_country($config{CC_GB});

	local $ENV{REMOTE_ADDR} = $config{VALID_IP};

	# A plain string is not a blessed object; calling ->country() on it would die
	my $result = eval { $acl->all_denied(lingua => 'not_an_object') };
	# Must not have thrown an unhandled exception
	is($result, 1,
		'non-object lingua: all_denied returns 1 (deny) without crashing');
	ok(!$@, 'non-object lingua does not propagate an unhandled exception');
};

subtest 'all_denied(): blessed object without country() method carps instead of dying' => sub {
	# An object that happens not to implement country() is still a broken caller,
	# but must not kill the CGI process.
	{
		package NullLingua;
		sub new { bless {}, shift }
		# deliberately no country() method
	}

	my $acl    = CGI::ACL->new()->deny_country($config{CC_GB});
	my $result = eval { denied_at($acl, $config{VALID_IP}, lingua => NullLingua->new()) };

	ok(!$@,         'missing country() method does not kill the process');
	is($result, 1,  'missing country() method results in deny (safe default)');
};

subtest 'all_denied(): no lingua when country restrictions active → carp + deny' => sub {
	# The module must warn the developer that lingua is needed, then safely deny
	my $acl = CGI::ACL->new()->deny_country($config{CC_GB});

	my $result;
	does_carp_that_matches(
		sub { $result = denied_at($acl, $config{VALID_IP}) },
		'missing lingua produces the documented carp',
		qr/\Q$config{ERR_LINGUA}\E/
	);
	is($result, 1, 'missing lingua results in deny');
};

# ─────────────────────────────────────────────────────────────────────────────
# all_denied(): CLOUD CHECK — UPSTREAM MOCK EDGE CASES
# ─────────────────────────────────────────────────────────────────────────────
subtest 'deny_cloud: _verified_rdns returning undef → non-cloud (allow)' => sub {
	# No PTR record or failed forward confirmation = not a cloud host
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };
	my $acl   = CGI::ACL->new()->deny_cloud();
	diag "_verified_rdns returns undef" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{VALID_IP}), 0, 'undef rDNS → not cloud → allowed');
};

subtest 'deny_cloud: _verified_rdns returning empty string → non-cloud (allow)' => sub {
	# An empty hostname is falsy and must not be matched against cloud patterns
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $config{MOCK_EMPTY} };
	my $acl   = CGI::ACL->new()->deny_cloud();
	diag "_verified_rdns returns ''" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{VALID_IP}), 0, 'empty rDNS → not cloud → allowed');
};

subtest 'deny_cloud: _verified_rdns returning "0" → non-cloud (allow)' => sub {
	# "0" is falsy; _is_cloud_host uses "or return 0" so falsy = not cloud
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $config{MOCK_ZERO_STR} };
	my $acl   = CGI::ACL->new()->deny_cloud();
	diag "_verified_rdns returns '0'" if $ENV{TEST_VERBOSE};

	is(denied_at($acl, $config{VALID_IP}), 0, '"0" rDNS → not cloud → allowed');
};

subtest 'deny_cloud: _verified_rdns returning a known cloud hostname → deny' => sub {
	# Belt-and-suspenders check that cloud patterns still fire through the mock
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns'
		=> sub { 'ec2-1-2-3-4.compute-1.amazonaws.com' };
	my $acl = CGI::ACL->new()->deny_cloud();

	is(denied_at($acl, $config{VALID_IP}), 1, 'cloud hostname → denied');
};

subtest 'deny_cloud: _verified_rdns dies → must not propagate to caller' => sub {
	# If DNS completely explodes, the cloud check must fail safe (not cloud)
	# rather than killing the CGI process.
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns'
		=> sub { die "simulated DNS catastrophe\n" };
	my $acl = CGI::ACL->new()->deny_cloud();
	diag "_verified_rdns dies" if $ENV{TEST_VERBOSE};

	my $result = eval { denied_at($acl, $config{VALID_IP}) };
	# A dying DNS lookup must not propagate — fail safe means non-cloud → allow (0)
	ok(!$@,        'dying _verified_rdns does not propagate an exception');
	is($result, 0, 'dying _verified_rdns fails safe: result is allow (0)');
};

# ─────────────────────────────────────────────────────────────────────────────
# $_ MUTATION CHECKS
# Purpose: none of the public methods must clobber $_ (common Perl pitfall
# when using for/map/grep without explicit loop variables)
# ─────────────────────────────────────────────────────────────────────────────
subtest '$_ is not clobbered by any public method' => sub {
	my $acl = CGI::ACL->new();

	# Seed $_ with a sentinel before each call
	$_ = 'sentinel';
	$acl->allow_ip($config{VALID_IP});
	is($_, 'sentinel', 'allow_ip does not clobber $_');

	$_ = 'sentinel';
	$acl->deny_country($config{CC_GB});
	is($_, 'sentinel', 'deny_country does not clobber $_');

	$_ = 'sentinel';
	$acl->allow_country($config{CC_US});
	is($_, 'sentinel', 'allow_country does not clobber $_');

	$_ = 'sentinel';
	$acl->deny_cloud();
	is($_, 'sentinel', 'deny_cloud does not clobber $_');

	$_ = 'sentinel';
	denied_at($acl, $config{VALID_IP});
	is($_, 'sentinel', 'all_denied does not clobber $_');
};

# ─────────────────────────────────────────────────────────────────────────────
# LIST vs SCALAR CONTEXT
# Purpose: all_denied() must return a single boolean value regardless of context
# ─────────────────────────────────────────────────────────────────────────────
subtest 'all_denied(): return value is the same in list and scalar context' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{VALID_IP});

	my $scalar  = denied_at($acl, $config{VALID_IP});
	my @list    = denied_at($acl, $config{VALID_IP});

	is($scalar,         0,  'all_denied returns 0 in scalar context');
	is(scalar @list,    1,  'all_denied returns exactly 1 element in list context');
	is($list[0],        0,  'all_denied list[0] equals scalar result');
};

# ─────────────────────────────────────────────────────────────────────────────
# RETURN VALUE SCHEMA VALIDATION
# Purpose: confirm all public methods return the correct types
# ─────────────────────────────────────────────────────────────────────────────
subtest 'Return value schemas: all public methods conform to POD' => sub {
	my $acl = CGI::ACL->new();

	returns_ok($acl,                              { type => 'OBJECT' }, 'new()');
	returns_ok($acl->allow_ip($config{VALID_IP}), { type => 'OBJECT' }, 'allow_ip()');
	returns_ok($acl->deny_country($config{CC_GB}),{ type => 'OBJECT' }, 'deny_country()');
	returns_ok($acl->allow_country($config{CC_US}),{ type => 'OBJECT' }, 'allow_country()');
	returns_ok($acl->deny_cloud(),                { type => 'OBJECT' }, 'deny_cloud()');

	# all_denied must return 0 or 1
	my $r = denied_at($acl, $config{VALID_IP},
		lingua => MockLingua->new(country => $config{CC_US}));
	returns_ok($r, { type => 'SCALAR', regex => qr/^[01]$/ }, 'all_denied()');
	diag "all_denied returned: $r" if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# CIDR CACHE COHERENCE
# Purpose: invalidation after allow_ip must force a rebuild
# ─────────────────────────────────────────────────────────────────────────────
subtest 'CIDR cache: invalidated by allow_ip, rebuilt on next all_denied' => sub {
	my $acl = CGI::ACL->new()->allow_ip($config{VALID_CIDR});

	# First call builds and memoises the CIDR list
	is(denied_at($acl, $config{CIDR_INSIDE}), 0, 'first CIDR check allows inside address');
	ok(defined($acl->{_cidrlist}), 'cache was populated after first all_denied');

	# allow_ip must invalidate the cache
	$acl->allow_ip($config{VALID_IP2});
	ok(!defined($acl->{_cidrlist}), 'cache is cleared after allow_ip');

	# Next call rebuilds with both entries
	is(denied_at($acl, $config{VALID_IP2}), 0, 'newly added IP is allowed after rebuild');
	is(denied_at($acl, $config{CIDR_INSIDE}), 0, 'original CIDR still works after rebuild');
};

# ─────────────────────────────────────────────────────────────────────────────
# IDEMPOTENCY
# Purpose: adding the same IP or country twice must not corrupt state
# ─────────────────────────────────────────────────────────────────────────────
subtest 'allow_ip(): adding same IP twice is idempotent' => sub {
	my $acl = CGI::ACL->new()
		->allow_ip($config{VALID_IP})
		->allow_ip($config{VALID_IP});    # duplicate

	is(scalar keys %{$acl->{allowed_ips}}, 1, 'duplicate allow_ip does not create two entries');
	is(denied_at($acl, $config{VALID_IP}), 0, 'IP is still allowed');
};

subtest 'deny_country(): adding same country twice is idempotent' => sub {
	my $acl = CGI::ACL->new()
		->deny_country($config{CC_GB})
		->deny_country($config{CC_GB});   # duplicate

	is(scalar keys %{$acl->{deny_countries}}, 1, 'duplicate deny_country does not create two entries');
};

# ── Additional constants for new edge-case subtests ───────────────────────────

Readonly my $IPv6_CIDR        => '2001:db8::/32';   # IPv6 CIDR for range tests
Readonly my $IPv6_IN_CIDR     => '2001:db8::42';    # inside $IPv6_CIDR
Readonly my $IPv6_NOT_IN_CIDR => '2001:db9::1';     # outside $IPv6_CIDR
Readonly my $INVALID_CIDR_PFX => '192.0.2.1/33';    # valid base IP, impossible prefix
Readonly my $CRLF_PTR_HOST    => "harmless-host.example.com\r\n";  # PTR record with CRLF
Readonly my $STRESS_IP_COUNT  => 100;

# Lingua stubs: extra types needed for new tests
{
	package DyingLingua;
	sub new     { bless {}, shift }
	sub country { die "country() exploded\n" }
}

{
	package HugeLingua;
	sub new     { bless {}, shift }
	sub country { 'A' x 65_536 }    # 64 KiB return value — must not crash
}

# ─────────────────────────────────────────────────────────────────────────────
# REGRESSION 0.10: \z ANCHOR IN REMOTE_ADDR VALIDATOR
# POD change note: "Fix all_denied() IP validator: replace ^ / $ anchors with
# \A / \z so that a trailing-newline REMOTE_ADDR cannot slip past the regex."
# Perl's $ matches before a terminating \n; \z never does.
# ─────────────────────────────────────────────────────────────────────────────
subtest 'REGRESSION 0.10: "1.2.3.4\n" in REMOTE_ADDR is denied (\z anchor)' => sub {
	# The old $ anchor accepted "1.2.3.4\n" because $ matches before a final \n.
	# If allowed through, the address "1.2.3.4" (without the newline) could match
	# an allow-list entry — a bypass for any ACL that allows that exact IP.
	my $acl = CGI::ACL->new()->allow_ip($config{VALID_IP});

	is(denied_at($acl, "$config{VALID_IP}\n"), 1,
		'"IP\n" denied (\z anchor prevents $ bypass — regression guard)');
	is(denied_at($acl, "$config{VALID_IP}\n\r"), 1,
		'"IP\n\r" denied (CRLF variant also rejected)');
	is(denied_at($acl, $config{VALID_IP}), 0,
		'clean IP (no newline) still allowed (positive anchor check)');
};

# ─────────────────────────────────────────────────────────────────────────────
# REGRESSION: whitespace padding in REMOTE_ADDR
# ─────────────────────────────────────────────────────────────────────────────
subtest 'REMOTE_ADDR with leading or trailing whitespace is denied' => sub {
	# An IP padded with whitespace must not be normalised and allowed; the validator
	# must reject it outright.  Under the old ^ / $ anchors a trailing space would
	# not match IPv4 regex, but under \A / \z it definitely does not — both anchors
	# guard against whitespace.  This test documents the expected deny behaviour.
	my $acl = CGI::ACL->new()->allow_ip($config{VALID_IP});

	is(denied_at($acl, " $config{VALID_IP}"),  1, 'leading space in REMOTE_ADDR → denied');
	is(denied_at($acl, "$config{VALID_IP} "),  1, 'trailing space in REMOTE_ADDR → denied');
	is(denied_at($acl, "\t$config{VALID_IP}"), 1, 'leading tab in REMOTE_ADDR → denied');
	diag "whitespace REMOTE_ADDR regression" if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# allow_ip(): ADDITIONAL ARGUMENT TYPES
# ─────────────────────────────────────────────────────────────────────────────
subtest 'allow_ip(): typeglob argument carps and returns $self (no crash)' => sub {
	# Typeglobs are an unusual but valid Perl value type that a caller might
	# accidentally pass (e.g., via an unguarded *STDOUT argument).
	# A typeglob stringifies to "*main::STDOUT" — defined, but not a valid IP.
	# allow_ip() emits the "not a valid IP address or CIDR block" carp (not the
	# "Usage:" carp, which fires only on undef/missing args).
	my $acl = CGI::ACL->new();
	my $ret;
	does_carp_that_matches(
		sub { $ret = $acl->allow_ip(*STDOUT) },
		qr/allow_ip.*not a valid/i,
	);
	is($ret, $acl, 'allow_ip(glob) returns $self for chaining safety');
	ok(!$acl->{allowed_ips} || !%{$acl->{allowed_ips}},
		'typeglob is not stored in allowed_ips');
};

subtest 'allow_ip(): hashref {ip => $addr} is a documented positive path' => sub {
	# POD API SPECIFICATION documents three argument forms; hashref is one of them.
	# Verify the hashref form routes through _get_param correctly.
	my $acl = CGI::ACL->new()->allow_ip({ip => $config{VALID_IP}});

	is(denied_at($acl, $config{VALID_IP}),  0, 'hashref form allow_ip: IP is permitted');
	is(denied_at($acl, $config{VALID_IP2}), 1, 'hashref form allow_ip: other IP still denied');
};

subtest 'allow_ip(): valid IP with impossible CIDR prefix — no carp, eval guard, denied' => sub {
	# '192.0.2.1' is a valid IPv4 base address so format validation passes (no carp).
	# '/33' is an impossible IPv4 prefix; Net::CIDR::cidradd dies.  The eval guard
	# in all_denied() catches the die, the CIDR list ends up empty, and every IP is
	# denied — no crash, fail-closed behaviour.
	my $acl = CGI::ACL->new();

	# No carp should be emitted (base IP is valid; only the prefix is bad)
	my $ret;
	warning_is { $ret = $acl->allow_ip($INVALID_CIDR_PFX) } undef,
		'allow_ip(valid-IP/bad-prefix) emits no warning';
	is($ret, $acl, 'returns $self on bad-prefix entry');

	# The stored entry has a valid-looking key but cidradd will fail at lookup time
	ok(defined($acl->{allowed_ips}),    'allowed_ips is defined (guard sees IP restriction)');
	ok($acl->{allowed_ips}{$INVALID_CIDR_PFX}, 'bad-prefix entry is stored under its original key');

	# Fail-closed: no IP should match, even the base address
	my $result = eval { denied_at($acl, '192.0.2.1') };
	ok(!$@,        'all_denied() does not throw on bad-prefix CIDR entry');
	is($result, 1, 'fail-closed: base IP denied (CIDR range lookup failed)');
	diag "all_denied with bad CIDR prefix: $result" if $ENV{TEST_VERBOSE};
};

subtest 'allow_ip(): IPv6 CIDR block allows addresses inside the range' => sub {
	# Net::CIDR supports IPv6; verify that a /32 prefix works end-to-end.
	my $acl = CGI::ACL->new()->allow_ip($IPv6_CIDR);

	is(denied_at($acl, $IPv6_IN_CIDR),     0, 'IPv6 address inside CIDR is allowed');
	is(denied_at($acl, $IPv6_NOT_IN_CIDR), 1, 'IPv6 address outside CIDR is denied');
	is(denied_at($acl, $config{VALID_IP}), 1, 'IPv4 address denied when only IPv6 CIDR is set');
};

subtest "allow_ip(): ${\$STRESS_IP_COUNT}-entry allow-list stress test — no crash" => sub {
	# Build an ACL with many individual CIDR /32 entries and verify the CIDR
	# rebuild machinery handles large lists without blowing the stack or OOM.
	my $acl = CGI::ACL->new();

	for my $i (1 .. $STRESS_IP_COUNT) {
		$acl->allow_ip("10.0.0.$i");    # RFC 1918, safe to use in tests
	}

	is(scalar keys %{$acl->{allowed_ips}}, $STRESS_IP_COUNT,
		"$STRESS_IP_COUNT entries stored");

	# Spot-check a few endpoints
	is(denied_at($acl, '10.0.0.1'),   0, 'first entry allowed after large list build');
	is(denied_at($acl, "10.0.0.$STRESS_IP_COUNT"), 0, 'last entry allowed');
	is(denied_at($acl, '10.0.0.' . ($STRESS_IP_COUNT + 1)), 1, 'entry beyond range denied');
	diag "stress list: $STRESS_IP_COUNT entries, CIDR cache holds" if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# all_denied(): HOSTILE LINGUA OBJECTS
# ─────────────────────────────────────────────────────────────────────────────
subtest 'all_denied(): lingua->country() that dies is caught, treated as unknown → deny' => sub {
	# The country() call is wrapped in eval per the 0.08 fix.  A dying lingua
	# must not propagate the exception to the CGI caller.
	my $acl = CGI::ACL->new()->deny_country($config{CC_GB});

	my $result = eval { denied_at($acl, $config{VALID_IP}, lingua => DyingLingua->new()) };
	ok(!$@,        'dying lingua->country() does not propagate an unhandled exception');
	is($result, 1, 'dying lingua->country() is treated as unknown country → deny');
	diag "dying lingua result: $result" if $ENV{TEST_VERBOSE};
};

subtest 'all_denied(): lingua->country() returning 64 KiB string does not crash' => sub {
	# An unexpectedly large country() return must not blow the stack or trigger
	# a fatal regex error.  The 64 KiB value is not a valid country code so it
	# must not match any deny-list entry; the result must be a safe 0 or 1.
	my $acl_deny_gb = CGI::ACL->new()->deny_country($config{CC_GB});
	my $acl_wildcard = CGI::ACL->new()->deny_country($config{WILDCARD});

	my $result_deny = eval { denied_at($acl_deny_gb, $config{VALID_IP}, lingua => HugeLingua->new()) };
	my $result_wild = eval { denied_at($acl_wildcard, $config{VALID_IP}, lingua => HugeLingua->new()) };

	ok(!$@, 'huge lingua->country() return does not throw');
	ok(defined $result_deny && $result_deny =~ /^[01]$/, 'result is 0 or 1 for specific deny');
	is($result_wild, 1, 'huge country code: wildcard-deny treats unknown/unmatched as deny');
	diag "HugeLingua results: deny_gb=$result_deny wildcard=$result_wild" if $ENV{TEST_VERBOSE};
};

subtest 'all_denied(): typeglob passed as lingua argument — carps, returns 1 (deny)' => sub {
	# Typeglobs are not blessed objects; blessed() returns undef for them.
	# The lingua type check must fire, carp once, and return 1.
	my $acl = CGI::ACL->new()->deny_country($config{CC_GB});

	local $ENV{REMOTE_ADDR} = $config{VALID_IP};
	my $result = eval { $acl->all_denied(lingua => *STDOUT) };

	ok(!$@,        'typeglob as lingua does not throw');
	is($result, 1, 'typeglob as lingua → deny (not a blessed object)');
	diag "typeglob lingua result: $result" if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# deny_cloud: CLOUD CACHE TTL EXPIRY AND PRIVATE-IP BYPASS
# ─────────────────────────────────────────────────────────────────────────────
subtest 'deny_cloud: expired cache entry forces a fresh DNS lookup' => sub {
	# The cache stores {result, expires}; once expires < time() the entry is stale
	# and must NOT be used.  A fresh DNS query must be triggered instead.
	my $dns_calls = 0;
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		$dns_calls++;
		return undef;    # non-cloud for this test
	};

	my $acl = CGI::ACL->new()->deny_cloud();

	# First call: cache miss → DNS queried, result stored
	is(denied_at($acl, $config{VALID_IP}), 0, 'first call: non-cloud → allowed');
	my $after_first = $dns_calls;
	is($after_first, 1, 'DNS queried exactly once on first call');

	# Second call: cache hit → DNS NOT queried
	is(denied_at($acl, $config{VALID_IP}), 0, 'second call: allowed (from cache)');
	is($dns_calls, $after_first, 'cache hit: no additional DNS call');

	# Manually expire the cache entry
	$acl->{_cloud_cache}{ $config{VALID_IP} }{expires} = time() - 1;
	diag "cache entry manually expired" if $ENV{TEST_VERBOSE};

	# Third call: expired cache → cache miss → DNS queried again
	is(denied_at($acl, $config{VALID_IP}), 0, 'third call: allowed (re-queried after expiry)');
	ok($dns_calls > $after_first, 'expired cache triggered a fresh DNS lookup');
	diag "total DNS calls: $dns_calls" if $ENV{TEST_VERBOSE};
};

subtest 'deny_cloud: private IP (loopback) bypasses _verified_rdns entirely' => sub {
	# _is_cloud_host() skips DNS for private/loopback addresses per the documented
	# short-circuit.  Installing a counting mock verifies DNS is NEVER called.
	my $dns_calls = 0;
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $dns_calls++ };

	my $acl = CGI::ACL->new()->deny_cloud();

	# 127.0.0.1 matches the private-IP regex → _is_cloud_host returns 0 immediately
	my $result = eval { denied_at($acl, $config{LOCAL_IP}) };
	ok(!$@,             'loopback with deny_cloud does not throw');
	is($dns_calls, 0,   '_verified_rdns not called for 127.0.0.1 (private IP short-circuit)');
	is($result, 0,      'loopback is non-cloud → allowed (only deny_cloud set, no other rules)');
	diag "loopback cloud check: dns_calls=$dns_calls result=$result" if $ENV{TEST_VERBOSE};
};

subtest 'deny_cloud: _verified_rdns returning CRLF-contaminated hostname — no crash' => sub {
	# A hostile PTR record might embed \r\n to attempt response splitting.
	# The cloud patterns are matched against the raw hostname string; a CRLF
	# must not cause an exception or a false-positive cloud match.
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $CRLF_PTR_HOST };
	my $acl = CGI::ACL->new()->deny_cloud();

	my $result = eval { denied_at($acl, $config{VALID_IP}) };
	ok(!$@, 'CRLF-contaminated PTR hostname does not throw');
	ok(defined $result && $result =~ /^[01]$/, 'result is 0 or 1 for CRLF PTR');
	diag "CRLF PTR result: $result" if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# REGRESSION 0.10: $@ IS CLEARED AFTER EVAL BLOCKS IN all_denied()
# Changes note: "Fix $@ not cleared after capturing DNS eval error and
# lingua->country() eval error; callers were seeing stale $@ state."
# ─────────────────────────────────────────────────────────────────────────────
subtest 'REGRESSION 0.10: $@ cleared after DNS exception in all_denied()' => sub {
	# Before the fix, $@ retained the DNS die message after all_denied() returned.
	# A caller wrapping all_denied() in eval would see a spurious $@ even though
	# the cloud check had already handled the error (fail-safe: treat as non-cloud).
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns'
		=> sub { die "simulated DNS timeout\n" };
	my $acl = CGI::ACL->new()->deny_cloud();

	$@ = 'stale-error-before-call';
	my $result = denied_at($acl, $config{VALID_IP});
	my $err = $@; undef $@;

	is($result, 0,   'DNS exception: fail-safe result is allow (0)');
	ok(!$err,        '$@ is cleared after DNS exception in all_denied() (0.10 regression)');
	diag "DNS exception $@ regression: result=$result err=" . ($err // 'undef') if $ENV{TEST_VERBOSE};
};

subtest 'REGRESSION 0.10: $@ cleared after lingua->country() exception in all_denied()' => sub {
	# Same $@ leakage risk for the lingua->country() eval path.
	my $acl = CGI::ACL->new()->deny_country($config{CC_GB});

	$@ = 'stale-error-before-call';
	my $result = denied_at($acl, $config{VALID_IP}, lingua => DyingLingua->new());
	my $err = $@; undef $@;

	is($result, 1, 'lingua exception: safe deny (1)');
	ok(!$err,      '$@ cleared after lingua->country() exception (0.10 regression)');
	diag "lingua exception $@ regression: err=" . ($err // 'undef') if $ENV{TEST_VERBOSE};
};

subtest 'REGRESSION 0.10: $@ not polluted by a normal (no exception) all_denied() call' => sub {
	# all_denied() uses several eval blocks; each must ensure $@ is cleared on
	# both success and failure paths so callers see a clean $@.
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { undef };
	my $acl   = CGI::ACL->new()->deny_cloud()->allow_ip($config{VALID_IP});

	$@ = 'stale-error-before-call';
	my $result = denied_at($acl, $config{VALID_IP});
	my $err = $@; undef $@;

	is($result, 0, 'allowed IP returns 0');
	ok(!$err,      '$@ is clean after a normal all_denied() call (0.10 regression)');
};

# ─────────────────────────────────────────────────────────────────────────────
# COUNTRY CODE SAFETY AND BOUNDARY
# ─────────────────────────────────────────────────────────────────────────────
subtest "deny_country(): injection strings stored as literal lowercase keys (no code execution)" => sub {
	# deny_country() stores country codes as hash keys and compares them to
	# lingua->country() output.  There is no database, no shell, no template
	# engine — injection strings are inert literal strings.  This test verifies:
	# (a) no crash, (b) the string is stored (lowercased), (c) all_denied
	# respects it only when lingua returns the exact same string.
	my $injection = "'; DROP TABLE countries; --";
	my $acl = CGI::ACL->new()->deny_country($injection);

	ok(defined($acl->{deny_countries}), 'deny_countries was initialised');
	my $lc_inject = lc($injection);
	ok($acl->{deny_countries}{$lc_inject}, 'injection string stored as lowercase key');
	diag "injection key: $lc_inject" if $ENV{TEST_VERBOSE};

	# Only the exact same string (lowercased) from lingua would trigger the deny
	my $matches = MockLingua->new(country => $lc_inject);
	my $no_match = MockLingua->new(country => $config{CC_US});

	is(denied_at($acl, $config{VALID_IP}, lingua => $matches),  1, 'exact injection match → deny');
	is(denied_at($acl, $config{VALID_IP}, lingua => $no_match), 0, 'normal country code → allow');
};

subtest 'allow_country("*"): wildcard stored but no unexpected denial without deny_country("*")' => sub {
	# allow_country('*') stores '*' as a permit-list key.  Without deny_country('*'),
	# the permit list is never consulted (allow_country alone has no effect).
	# This test documents that storing '*' does not accidentally deny all traffic.
	my $acl = CGI::ACL->new()->allow_country($config{WILDCARD});

	is(denied_at($acl, $config{VALID_IP}), 0,
		'allow_country("*") alone: all_denied still returns 0 (no restriction active)');
	ok($acl->{allow_countries}{ $config{WILDCARD} },
		'"*" key is stored in allow_countries');

	# Even with deny_country('*') active, allow_country('*') should permit anyone
	# because '*' in the allow list is checked as a literal country code,
	# and lingua->country() would need to return '*' literally for it to match.
	# Verify no crash when this unusual state exists.
	$acl->deny_country($config{WILDCARD});
	my $result = eval {
		denied_at($acl, $config{VALID_IP}, lingua => MockLingua->new(country => $config{CC_US}))
	};
	ok(!$@,        'deny_country("*") + allow_country("*") does not throw');
	ok(defined $result, 'result is defined (not undef)');
	is($result, 1, 'US not in allow list (only "*" literal is) → denied');
	diag 'allow_country("*") edge case: result=' . ($result // 'undef') if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# CONSTRUCTOR DESTRUCTIVE CASES
# ─────────────────────────────────────────────────────────────────────────────
subtest 'new(): multi-level clone chain (clone of a clone) — independent, no crash' => sub {
	# Verify that cloning a clone works and that all three levels are independent.
	my $level1 = CGI::ACL->new()->allow_ip($config{VALID_IP});
	my $level2 = $level1->new()->allow_ip($config{VALID_IP2});
	my $level3 = $level2->new();

	# level3 inherits both IPs from level2 (which inherited from level1)
	is(denied_at($level3, $config{VALID_IP}),  0, 'level3: IP from level1 allowed');
	is(denied_at($level3, $config{VALID_IP2}), 0, 'level3: IP from level2 allowed');

	# Mutating level3 must not affect level2 or level1
	$level3->deny_country($config{CC_US});
	ok(!$level2->{deny_countries}, 'level2 unaffected by level3 deny_country');
	ok(!$level1->{deny_countries}, 'level1 unaffected by level3 deny_country');
	diag 'multi-level clone: all levels independent' if $ENV{TEST_VERBOSE};
};

subtest 'new(): typeglob value in constructor parameter — no crash, object still usable' => sub {
	# An unusual but syntactically valid caller might pass a typeglob value.
	# Object::Configure will see it in the constructor hash; the module must not
	# crash, and the resulting object must behave correctly for normal operations.
	my $acl = eval { CGI::ACL->new(some_unknown_key => *STDOUT) };
	ok(!$@,     'constructor with typeglob value does not throw');
	isa_ok($acl, 'CGI::ACL', 'typeglob-value constructor still returns a CGI::ACL object');

	# Basic operation must be unaffected
	$acl->allow_ip($config{VALID_IP});
	is(denied_at($acl, $config{VALID_IP}),  0, 'IP allow still works after typeglob constructor');
	is(denied_at($acl, $config{VALID_IP2}), 1, 'IP deny still works after typeglob constructor');
};

done_testing();
