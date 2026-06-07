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

subtest 'allow_ip(): injection strings stored in allow-list do not crash all_denied' => sub {
	# An injection string would never match a real REMOTE_ADDR, but its
	# presence must not cause Net::CIDR to die inside all_denied.
	my $acl = CGI::ACL->new();

	# These should store without crashing (allow_ip does not validate format)
	# but all_denied must handle them gracefully when building the CIDR list.
	for my $bad ($config{SHELL_INJECT}, $config{SQL_INJECT}, $config{LONG_STRING}) {
		$acl->allow_ip($bad);
	}
	diag "allow_ip with injection strings stored" if $ENV{TEST_VERBOSE};

	# VALID_IP is not in the list → must be denied without an unhandled exception
	my $result = eval { denied_at($acl, $config{VALID_IP}) };
	ok(!$@,              'all_denied does not throw when allow-list has invalid entries');
	is($result, 1,       'VALID_IP is denied (not in the (invalid) allow-list)');
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

done_testing();
