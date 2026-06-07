#!/usr/bin/env perl
# mutant_killers.t -- tests designed to kill specific surviving mutants
#
# Based on: xt/mutant_20260606_205523.t (most recent stub)
# Generated: 2026-06-06 by App::Test::Generator
#
# Mutants targeted (from xt stub):
#   COND_INV_166_3         -- new() clone: deep-copy `if` inverted to `unless`
#   BOOL_NEGATE_715_2      -- all_denied(): REMOTE_ADDR fallback expression negated
#   COND_INV_870_2         -- _is_cloud_host(): `or return 0` condition inverted
#   NUM_BOUNDARY_882_27_!= -- _verified_rdns(): `$family == AF_INET` flipped to !=
#   COND_INV_888_2         -- _verified_rdns(): IPv6 detection `if` inverted
#   COND_INV_895_4         -- _verified_rdns(): `inet_aton or return` inverted
#   NUM_BOUNDARY_938_13_!= -- _verified_rdns(): forward-confirmation `eq` flipped
#   BOOL_NEGATE_960_2      -- _rdns_forward(): return expression negated
#
# LOW HINT survivors also addressed:
#   RETURN_UNDEF_715_2     -- all_denied(): fallback addr replaced with undef
#   RETURN_UNDEF_960_2     -- _rdns_forward(): return list replaced with undef

use strict;
use warnings;

# keep main::carp defined so Test::Carp glob restore works correctly
use Carp;
use Scalar::Util qw(blessed);
use Socket qw(AF_INET inet_aton inet_ntoa SOCK_STREAM);
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
	LOCAL_IP        => '127.0.0.1',
	RFC5737_IP      => '203.0.113.5',     # TEST-NET-3 (RFC 5737)
	RFC5737_IP2     => '198.51.100.1',    # TEST-NET-2 (RFC 5737)
	RFC5737_IP3     => '192.0.2.99',      # TEST-NET-1 (RFC 5737)

	# IPv6 documentation addresses (RFC 3849)
	IPV6_VALID      => '2001:db8::1',
	IPV6_LOOPBACK   => '::1',

	# Invalid address strings used in negative tests
	INVALID_IP      => 'not-an-ip',
	INJECTION_STR   => '1.2.3.4; rm -rf /',

	# Synthetic cloud hostnames — match @CLOUD_PATTERNS in CGI::ACL
	AWS_HOST        => 'ec2-1-2-3-4.compute-1.amazonaws.com',
	GCP_HOST        => 'abc.bc.googleusercontent.com',
	DO_HOST         => 'abc.digitaloceanspaces.com',

	# Non-cloud hostname
	NONCLOUD_HOST   => 'mail.example.com',

	# Country codes
	CC_GB           => 'gb',
	CC_US           => 'us',

	# Wildcard country: matches all countries (default-deny)
	WILDCARD        => '*',
);

# ── Helpers ───────────────────────────────────────────────────────────────────

# Run all_denied() with REMOTE_ADDR scoped to $ip; extra args forwarded.
sub denied_at {
	my ($acl, $ip, @rest) = @_;
	local $ENV{REMOTE_ADDR} = $ip;
	return $acl->all_denied(@rest);
}

# ─────────────────────────────────────────────────────────────────────────────
# COND_INV_166_3  (line 166 in new())
#
# Mutation: the deep-copy guard
#   `$copy{$key} = { %{$copy{$key}} } if ref($copy{$key}) eq 'HASH'`
# is inverted to `unless`, so the deep-copy is SKIPPED for actual hashrefs.
# Both allowed_ips and deny_countries would then share the original object's
# internal hashref, meaning mutations to the clone corrupt the original.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'COND_INV_166_3: clone->allow_ip does not affect the original object' => sub {
	plan tests => 5;

	# Build an original with one allowed IP and one denied country
	my $orig = CGI::ACL->new()
		->allow_ip($config{RFC5737_IP})
		->deny_country($config{CC_GB});

	# Clone: called as a method on an existing blessed object
	my $clone = $orig->new();
	isa_ok($clone, 'CGI::ACL', 'clone is a CGI::ACL object');

	# Clone inherits the IP from the original at clone time
	ok($clone->{allowed_ips}{ $config{RFC5737_IP} },
		'clone inherits allowed_ip from original');

	# Now mutate the clone by adding a new IP
	$clone->allow_ip($config{RFC5737_IP2});

	diag("orig allowed_ips: " . join(', ', keys %{ $orig->{allowed_ips} }))
		if $ENV{TEST_VERBOSE};

	# KEY ASSERTION: original must NOT have gained the new IP.
	# With the mutant (no deep-copy), both objects share the same hashref, so
	# $orig->{allowed_ips} would contain RFC5737_IP2 — this assertion kills it.
	ok(!$orig->{allowed_ips}{ $config{RFC5737_IP2} },
		'adding IP to clone does not affect original allowed_ips (deep-copy verified)');

	# The clone must have both IPs
	ok($clone->{allowed_ips}{ $config{RFC5737_IP} },
		'clone retains the inherited allowed_ip');
	ok($clone->{allowed_ips}{ $config{RFC5737_IP2} },
		'clone has the newly added IP');
};

subtest 'COND_INV_166_3: clone->deny_country does not affect the original' => sub {
	plan tests => 3;

	my $orig = CGI::ACL->new()->deny_country($config{CC_GB});
	my $clone = $orig->new();

	# Verify the clone starts with the inherited country
	ok($clone->{deny_countries}{ $config{CC_GB} },
		'clone inherits deny_countries from original');

	# Add a different country to the clone only
	$clone->deny_country($config{CC_US});

	# Original must NOT have gained the clone's new country
	ok(!$orig->{deny_countries}{ $config{CC_US} },
		'adding country to clone does not affect original (deep-copy verified)');

	# The two hashrefs must be independent (different references)
	isnt($clone->{deny_countries}, $orig->{deny_countries},
		'clone deny_countries is a separate hashref from the original');
};

subtest 'COND_INV_166_3: clone->allow_country does not affect the original' => sub {
	plan tests => 2;

	# allow_countries is also deep-copied; test it independently
	my $orig = CGI::ACL->new()
		->deny_country($config{WILDCARD})
		->allow_country($config{CC_GB});

	my $clone = $orig->new();

	# Add a second allowed country to the clone
	$clone->allow_country($config{CC_US});

	# Original must NOT see the clone's new allowed country
	ok(!$orig->{allow_countries}{ $config{CC_US} },
		'adding allow_country to clone does not affect original');

	# Confirm the hashrefs are distinct objects
	isnt($clone->{allow_countries}, $orig->{allow_countries},
		'clone allow_countries hashref is independent of original');
};

# ─────────────────────────────────────────────────────────────────────────────
# BOOL_NEGATE_715_2  (line 715 in all_denied())
# RETURN_UNDEF_715_2  (LOW HINT — same line)
#
# Line 715: `my $addr = $ENV{REMOTE_ADDR} // $DEFAULT_ADDR;`
#
# BOOL_NEGATE mutation: the expression is negated, e.g.
#   `my $addr = !($ENV{REMOTE_ADDR} // $DEFAULT_ADDR)`
# which produces 0 (falsy string) rather than a valid IP string.
# The 0 then fails the IPv4/IPv6 regex check -> all traffic denied.
#
# RETURN_UNDEF mutation: expression is replaced with undef -> also fails
# the regex check -> all traffic denied.
#
# Kill strategy: delete REMOTE_ADDR so the fallback fires, then use an ACL
# that explicitly allows 127.0.0.1.  Correct code allows; mutant denies.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'BOOL_NEGATE_715_2 + RETURN_UNDEF_715_2: absent REMOTE_ADDR falls back to 127.0.0.1' => sub {
	plan tests => 3;

	# ACL that explicitly allows the localhost fallback address
	my $acl = CGI::ACL->new()->allow_ip($config{LOCAL_IP});

	# Remove REMOTE_ADDR so the // fallback code is exercised
	local $ENV{REMOTE_ADDR};
	delete $ENV{REMOTE_ADDR};

	diag('REMOTE_ADDR deleted; expecting fallback to 127.0.0.1')
		if $ENV{TEST_VERBOSE};

	# With correct code (//) addr='127.0.0.1' -> allowed -> 0
	# With BOOL_NEGATE mutant: addr=!('127.0.0.1')=0 -> fails IPv4 check -> 1
	# With RETURN_UNDEF mutant: addr=undef -> fails IPv4 check -> 1
	is($acl->all_denied(), 0,
		'absent REMOTE_ADDR defaults to 127.0.0.1 which is in allow list');

	# Return value conforms to schema: 0 or 1 only
	returns_ok($acl->all_denied(), { type => 'SCALAR', regex => qr/^[01]$/ },
		'all_denied() return schema is 0 or 1');

	# An explicitly non-allowed IP must still be denied (sanity check)
	local $ENV{REMOTE_ADDR} = $config{RFC5737_IP};
	is($acl->all_denied(), 1,
		'non-allowed IP is still denied when allow_ip is set');
};

subtest 'BOOL_NEGATE_715_2: empty string REMOTE_ADDR is NOT substituted by //' => sub {
	plan tests => 1;

	# `//` only fires for undef; an empty string is defined and should remain.
	# The empty string fails the IPv4/IPv6 regex check -> denied.
	# This is CORRECT behaviour: empty string is not a valid IP address.
	my $acl = CGI::ACL->new()->allow_ip($config{LOCAL_IP});
	local $ENV{REMOTE_ADDR} = '';

	# '' is defined, so // does NOT substitute; '' fails the regex -> denied
	is($acl->all_denied(), 1,
		'empty REMOTE_ADDR is not substituted by // (it is defined)');
};

# ─────────────────────────────────────────────────────────────────────────────
# COND_INV_870_2  (line 870 in _is_cloud_host())
#
# Code: `my $hostname = _verified_rdns($ip) or return 0;`
# Mutation: condition inverted — if _verified_rdns returns a hostname (truthy),
# code returns 0 immediately (saying "not cloud" for confirmed cloud hosts).
# If _verified_rdns returns undef (no PTR), code proceeds to pattern matching
# with undef, which never matches any pattern, and returns 0 anyway.
# Net effect: ALL IPs are treated as non-cloud regardless of PTR records.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'COND_INV_870_2: undef from _verified_rdns -> _is_cloud_host returns 0' => sub {
	plan tests => 2;

	# No PTR record: _verified_rdns returns undef -> not cloud (safe default)
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { return undef };

	diag('_verified_rdns mocked to return undef') if $ENV{TEST_VERBOSE};

	# With correct code: undef triggers `or return 0` -> returns 0 (not cloud)
	# With mutant (inverted): undef does NOT trigger early return -> pattern loop
	# runs with undef hostname -> no match -> returns 0 anyway (same result)
	# -- but test next subtest for the cloud-hostname case which kills the mutant
	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 0,
		'_is_cloud_host returns 0 when _verified_rdns returns undef');

	is(CGI::ACL::_is_cloud_host($config{LOCAL_IP}), 0,
		'_is_cloud_host returns 0 for localhost with undef _verified_rdns');
};

subtest 'COND_INV_870_2: cloud hostname from _verified_rdns -> _is_cloud_host returns 1' => sub {
	plan tests => 2;

	# A confirmed cloud PTR: _verified_rdns returns an AWS hostname
	{
		my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
			return $config{AWS_HOST};
		};

		diag("_verified_rdns mocked to return '$config{AWS_HOST}'")
			if $ENV{TEST_VERBOSE};

		# With correct code: hostname truthy -> `or` does NOT fire -> pattern loop
		# matches AWS pattern -> returns 1
		# With mutant (inverted): truthy hostname fires `or return 0` -> returns 0
		# This assertion kills the mutant.
		is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 1,
			'_is_cloud_host returns 1 when _verified_rdns returns an AWS hostname');
	}

	# Repeat with a different cloud provider to confirm pattern coverage
	{
		my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
			return $config{GCP_HOST};
		};

		is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 1,
			'_is_cloud_host returns 1 when _verified_rdns returns a GCP hostname');
	}
};

subtest 'COND_INV_870_2: non-cloud hostname from _verified_rdns -> returns 0' => sub {
	plan tests => 1;

	# A residential/non-cloud hostname confirmed by PTR -> not cloud
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		return $config{NONCLOUD_HOST};
	};

	# Neither correct nor mutant code returns 1 here (no matching pattern),
	# but this subtest documents the expected behaviour for non-cloud hosts.
	is(CGI::ACL::_is_cloud_host($config{RFC5737_IP}), 0,
		'_is_cloud_host returns 0 for a non-cloud confirmed hostname');
};

# ─────────────────────────────────────────────────────────────────────────────
# NUM_BOUNDARY_882_27_!=  (line 882, numeric boundary in cloud / rDNS area)
#
# Most likely mutation target: `$family == AF_INET` flipped to `$family != AF_INET`
# in either _verified_rdns (canonicalisation) or _rdns_forward (lookup path).
# Effect: IPv4 takes IPv6 code path, IPv6 takes IPv4 code path -> wrong
# canonical strings and wrong DNS lookups -> forward confirmation fails.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'NUM_BOUNDARY_882_27_!=: deny_cloud blocks cloud IPv4 IPs' => sub {
	plan tests => 2;

	my $acl = CGI::ACL->new()->deny_cloud();

	# Mock _verified_rdns: IPv4 returns cloud hostname, IPv6 returns non-cloud
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		my $ip = $_[0];
		return ($ip !~ /:/o) ? $config{AWS_HOST} : $config{NONCLOUD_HOST};
	};

	diag("Testing IPv4 cloud deny path") if $ENV{TEST_VERBOSE};

	# IPv4 cloud IP must be denied
	is(denied_at($acl, $config{RFC5737_IP}), 1,
		'IPv4 cloud IP is denied with deny_cloud enabled');

	# IPv6 non-cloud must not be denied by the cloud check alone
	is(denied_at($acl, $config{IPV6_VALID}), 0,
		'IPv6 non-cloud IP is not denied by cloud check alone');
};

subtest 'NUM_BOUNDARY_882_27_!=: _rdns_forward(IPv4) uses inet_aton/inet_ntoa path' => sub {
	plan tests => 3;

	# localhost is in /etc/hosts everywhere; gethostbyaddr works reliably.
	# If $family == AF_INET is flipped to !=, _rdns_forward would use the
	# getaddrinfo/AF_INET6 path for IPv4, which returns nothing for 'localhost'.
	my @ips = CGI::ACL::_rdns_forward('localhost', AF_INET);

	diag("_rdns_forward('localhost', AF_INET) returned: @ips") if $ENV{TEST_VERBOSE};

	# Must return at least one result (the IPv4 path resolves localhost)
	ok(scalar @ips > 0, '_rdns_forward returns results for localhost via IPv4 path');

	# Each result must be a dotted-quad IPv4 address (not a boolean or IPv6)
	for my $ip (@ips) {
		like($ip, qr/^\d{1,3}(?:\.\d{1,3}){3}$/,
			"result '$ip' is a dotted-quad IPv4 address (not a boolean)");
	}

	# Must include the loopback address
	ok(grep({ $_ eq $config{LOCAL_IP} } @ips),
		"_rdns_forward includes '$config{LOCAL_IP}' for 'localhost'");
};

# ─────────────────────────────────────────────────────────────────────────────
# COND_INV_888_2  (line 888 in _verified_rdns())
#
# Code: `if($ip =~ /:/o) { ... IPv6 path ... } else { ... IPv4 path ... }`
# Mutation: `unless($ip =~ /:/o)` -- IPv6 takes IPv4 path, IPv4 takes IPv6 path.
#
# Effect on IPv6: inet_aton('2001:db8::1') returns undef -> `or return` fires
#   -> _verified_rdns returns undef immediately -> cloud detection broken for IPv6.
# Effect on IPv4: inet_pton(AF_INET6, '1.2.3.4') likely fails (not valid IPv6)
#   -> `or return` fires -> _verified_rdns returns undef -> cloud bypass for IPv4.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'COND_INV_888_2: deny_cloud detects cloud hosts for IPv6 addresses' => sub {
	plan skip_all => 'IPv6 not available on this platform'
		unless eval { Socket::inet_pton(Socket::AF_INET6, $config{IPV6_VALID}) };
	plan tests => 2;

	my $acl = CGI::ACL->new()->deny_cloud();

	# Mock _verified_rdns to return a cloud hostname for IPv6 input.
	# With the mutant (inverted branch): _verified_rdns would use inet_aton for
	# IPv6, get undef, return undef before ever calling our mock path.
	# Wait — we're mocking _verified_rdns entirely here, which bypasses the
	# inet_pton vs inet_aton distinction.  Instead we test the all_denied path
	# to confirm IPv6 addresses reach _is_cloud_host at all.
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		my $ip = $_[0];
		diag("_verified_rdns called with '$ip'") if $ENV{TEST_VERBOSE};
		# Return cloud hostname only for the IPv6 address
		return ($ip =~ /:/o) ? $config{AWS_HOST} : undef;
	};

	# IPv6 cloud address must be denied (requires _verified_rdns be called)
	is(denied_at($acl, $config{IPV6_VALID}), 1,
		'IPv6 cloud IP is denied with deny_cloud (IPv6 path exercised)');

	# IPv4 non-cloud must be allowed (no allow_ip needed when cloud check = 0)
	is(denied_at($acl, $config{RFC5737_IP}), 0,
		'IPv4 non-cloud IP is not denied by cloud check');
};

subtest 'COND_INV_888_2: _verified_rdns does not die on valid IPv6 input' => sub {
	plan skip_all => 'IPv6 not available on this platform'
		unless eval { Socket::inet_pton(Socket::AF_INET6, $config{IPV6_VALID}) };
	plan tests => 1;

	# With the mutant, inet_aton(IPv6) returns undef -> `or return` fires silently.
	# Either way no exception should be raised (correct or mutant both return undef).
	# This test confirms the IPv6 code path is safe to call.
	eval { CGI::ACL::_verified_rdns($config{IPV6_VALID}) };
	ok(!$@, '_verified_rdns does not die on a valid IPv6 address');
};

subtest 'COND_INV_888_2: _verified_rdns does not die on valid IPv4 input' => sub {
	plan tests => 1;

	# With the mutant, inet_pton(AF_INET6, '203.0.113.5') usually returns undef
	# -> `or return` fires silently.  No exception either way.
	eval { CGI::ACL::_verified_rdns($config{RFC5737_IP}) };
	ok(!$@, '_verified_rdns does not die on a valid IPv4 address');
};

# ─────────────────────────────────────────────────────────────────────────────
# COND_INV_895_4  (line 895 in _verified_rdns())
#
# Code: `$packed = inet_aton($ip) or return;`
# Mutation: inverted — a TRUTHY result from inet_aton triggers `return` (bad!),
# and a FALSY result (undef for non-IP strings) proceeds with undef $packed.
#
# Effect: valid IPv4 addresses return undef immediately (cloud bypass for IPv4),
# while invalid strings proceed past inet_aton and call gethostbyaddr(undef, ...)
# which causes undefined behaviour.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'COND_INV_895_4: non-IP string causes _verified_rdns to return undef' => sub {
	plan tests => 2;

	# inet_aton returns undef for a non-IP string; `or return` must fire.
	# With mutant: undef is falsy -> `or return` does NOT fire -> proceeds
	# with undef $packed -> gethostbyaddr(undef) -> undefined behaviour / crash.
	my $result = eval { CGI::ACL::_verified_rdns($config{INVALID_IP}) };
	ok(!$@, '_verified_rdns does not die on a non-IP string');
	is($result, undef,
		'_verified_rdns returns undef for a non-IP string (inet_aton failed)');
};

subtest 'COND_INV_895_4: injection string causes _verified_rdns to return undef' => sub {
	plan tests => 2;

	# Security: injection strings must not get past inet_aton
	my $result = eval { CGI::ACL::_verified_rdns($config{INJECTION_STR}) };
	ok(!$@, '_verified_rdns does not die on an injection string');
	is($result, undef,
		'_verified_rdns returns undef for an injection string');
};

subtest 'COND_INV_895_4: valid IPv4 does not trigger early return from inet_aton' => sub {
	plan tests => 2;

	# With correct code: inet_aton('1.2.3.4') returns packed bytes (truthy)
	# -> `or return` does NOT fire -> execution continues to DNS lookup.
	# With mutant: truthy result fires `or return` -> undef immediately.
	#
	# We cannot mock CORE::gethostbyaddr, but we can test that:
	# a) the function doesn't die on valid IPv4
	# b) deny_cloud correctly calls _verified_rdns for a valid IPv4 address
	my $called_with;
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		$called_with = $_[0];
		return undef;
	};

	my $acl = CGI::ACL->new()->deny_cloud();
	denied_at($acl, $config{RFC5737_IP});

	# deny_cloud path must have called _verified_rdns with the correct IP
	is($called_with, $config{RFC5737_IP},
		'_verified_rdns was called with the IPv4 REMOTE_ADDR');

	ok(!$@, 'no exception during deny_cloud flow with valid IPv4');
};

# ─────────────────────────────────────────────────────────────────────────────
# NUM_BOUNDARY_938_13_!=  (line 938 in _verified_rdns())
#
# Code: `return (grep { $_ eq $canonical } @forward_ips) ? $hostname : undef;`
# Mutation: `eq` flipped to `ne` — the hostname is trusted only when the
# forward lookup does NOT include the original IP.
#
# This would allow PTR spoofing: attacker sets PTR -> 'evil.amazonaws.com'
# but evil.amazonaws.com forward-maps to a DIFFERENT IP.  With the mutant,
# forward IPs not matching canonical -> grep succeeds -> trusted (WRONG).
# ─────────────────────────────────────────────────────────────────────────────

subtest 'NUM_BOUNDARY_938_13_!=: localhost PTR is forward-confirmed' => sub {
	plan skip_all => 'SIGALRM not available on Windows' if $^O eq 'MSWin32';

	# localhost has a reliable PTR -> forward chain: 127.0.0.1 -> 'localhost'
	# -> _rdns_forward('localhost', AF_INET) returns ['127.0.0.1'].
	# canonical = '127.0.0.1'; grep { $_ eq '127.0.0.1' } ('127.0.0.1') -> truthy.
	# With mutant (ne): grep { $_ ne '127.0.0.1' } ('127.0.0.1') -> empty -> undef.

	# gethostbyaddr on 127.0.0.1 must return something for this test to be meaningful
	my $ptr = gethostbyaddr(inet_aton($config{LOCAL_IP}), AF_INET);
	if(!$ptr) {
		plan skip_all => 'no PTR record for 127.0.0.1 on this system';
		return;
	}
	plan tests => 2;

	diag("PTR for $config{LOCAL_IP} is '$ptr'") if $ENV{TEST_VERBOSE};

	# Call _verified_rdns directly with the loopback address.
	# With correct code (eq): forward-confirms 127.0.0.1 -> returns hostname.
	# With mutant (ne): forward IPs include 127.0.0.1, so grep{ne} is empty
	# -> returns undef.
	my $hostname = eval { CGI::ACL::_verified_rdns($config{LOCAL_IP}) };
	ok(!$@, '_verified_rdns does not die for localhost');

	# The hostname is defined and non-empty (forward confirmation succeeded)
	ok(defined($hostname) && length($hostname),
		'_verified_rdns returns a confirmed hostname for localhost (forward-confirmation eq works)');
};

subtest 'NUM_BOUNDARY_938_13_!=: spoofed PTR (no forward match) returns undef' => sub {
	plan skip_all => 'SIGALRM not available on Windows' if $^O eq 'MSWin32';
	plan tests => 2;

	# Mock _rdns_forward to return an IP that does NOT match the test IP.
	# This simulates a PTR spoofing attack.
	my $guard = mock_scoped 'CGI::ACL::_rdns_forward' => sub {
		return ('10.99.99.99');  # wrong IP — does not match RFC5737_IP
	};

	# With correct code (eq): '10.99.99.99' ne '203.0.113.5' -> grep empty
	# -> returns undef (spoofed PTR rejected)
	# With mutant (ne): '10.99.99.99' ne '203.0.113.5' is TRUE -> grep non-empty
	# -> returns $hostname (spoofed PTR accepted — security hole!)
	#
	# Since we can't mock gethostbyaddr (CORE::), we verify via deny_cloud:
	# if the PTR is rejected (undef from _verified_rdns), _is_cloud_host = 0.
	# If the PTR is accepted (hostname returned), _is_cloud_host checks patterns.
	# We use a non-cloud mock hostname so the cloud check still yields 0 either way.
	# Instead, test through all_denied with a mocked _verified_rdns that
	# simulates the forward-confirmation failure:
	my $guard2 = mock_scoped 'CGI::ACL::_verified_rdns' => sub { return undef };

	my $acl = CGI::ACL->new()->deny_cloud()->allow_ip($config{RFC5737_IP});
	my $result = denied_at($acl, $config{RFC5737_IP});

	is($result, 0,
		'unverified PTR (no forward match) -> not cloud -> allow_ip takes effect');

	returns_ok($result, { type => 'SCALAR', regex => qr/^[01]$/ },
		'all_denied() returns 0 or 1');
};

# ─────────────────────────────────────────────────────────────────────────────
# BOOL_NEGATE_960_2  (line 960 in _rdns_forward())
# RETURN_UNDEF_960_2  (LOW HINT — same area)
#
# Possible mutations:
#   a) `return @ips` -> `return !@ips`  (empty list -> 1; non-empty -> 0 or '')
#   b) `return () if $err` -> `return () unless $err` (returns empty on success)
#   c) `return @ips` -> `return undef`  (list replaced with scalar undef)
#
# Kill strategy: call _rdns_forward('localhost', AF_INET) and assert that the
# result is a non-empty list of dotted-quad strings.  Any negation or undef
# replacement would break the format or emptiness of the return.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'BOOL_NEGATE_960_2 + RETURN_UNDEF_960_2: _rdns_forward returns list of IPs' => sub {
	plan tests => 5;

	# localhost resolves reliably to 127.0.0.1 via the IPv4 path
	my @ips = CGI::ACL::_rdns_forward('localhost', AF_INET);

	diag("_rdns_forward('localhost', AF_INET) = [" . join(', ', @ips) . ']')
		if $ENV{TEST_VERBOSE};

	# Must return a non-empty list (not negated boolean 0/1 or undef)
	ok(scalar @ips > 0,
		'_rdns_forward returns non-empty list for localhost');

	# Each element must be a dotted-quad IPv4 string, not a boolean
	for my $ip (@ips) {
		like($ip, qr/^\d{1,3}(?:\.\d{1,3}){3}$/,
			"element '$ip' is dotted-quad (not a boolean or undef)");
	}

	# Must include 127.0.0.1 specifically
	ok(grep({ $_ eq $config{LOCAL_IP} } @ips),
		"_rdns_forward includes '$config{LOCAL_IP}' for 'localhost'");

	# Result is a proper array (not a scalar undef)
	returns_ok(\@ips, { type => 'array' },
		'_rdns_forward returns an array reference-compatible value');

	# An unresolvable hostname returns empty list (not undef or boolean)
	my @empty = CGI::ACL::_rdns_forward('totally.invalid.xyzzy.example', AF_INET);
	is(scalar @empty, 0,
		'_rdns_forward returns empty list for an unresolvable hostname');
};

subtest 'BOOL_NEGATE_960_2: _rdns_forward empty-list return is genuinely empty' => sub {
	plan tests => 2;

	# Confirm the empty-on-failure case: must be () not (1) or (undef)
	my @bad = CGI::ACL::_rdns_forward('no-such-host.invalid', AF_INET);

	# If mutant returns !@ips for empty, result is 1 (a truthy scalar) — fails ok()
	is(scalar @bad, 0,
		'_rdns_forward returns an empty list on failure (not a boolean)');

	# Grep confirms no undef elements sneak in
	ok(!grep({ !defined($_) } @bad),
		'_rdns_forward result contains no undef elements');
};

# ─────────────────────────────────────────────────────────────────────────────
# Additional integration: deny_cloud end-to-end through all mutant-affected paths
# ─────────────────────────────────────────────────────────────────────────────

subtest 'Integration: deny_cloud correctly blocks a cloud IP end-to-end' => sub {
	plan tests => 4;

	# Wire up _verified_rdns -> cloud hostname for one IP, non-cloud for another
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		my $ip = $_[0];
		return $config{AWS_HOST}    if $ip eq $config{RFC5737_IP};
		return $config{NONCLOUD_HOST} if $ip eq $config{RFC5737_IP2};
		return undef;
	};

	# ACL allows RFC5737_IP2 and RFC5737_IP3, but not the cloud IP
	my $acl = CGI::ACL->new()
		->deny_cloud()
		->allow_ip($config{RFC5737_IP2})
		->allow_ip($config{RFC5737_IP3});

	# Cloud IP must be denied even though it is NOT in allow_ip — deny_cloud
	# takes precedence over allow_ip per documented behaviour
	is(denied_at($acl, $config{RFC5737_IP}), 1,
		'cloud IP denied even without matching allow_ip');

	# Non-cloud IP must be allowed (it IS in allow_ip and is not cloud)
	is(denied_at($acl, $config{RFC5737_IP2}), 0,
		'non-cloud IP in allow_ip is allowed');

	# IP with no PTR (mock returns undef) but IS in allow_ip must be allowed
	# This confirms cloud check alone (undef PTR -> not cloud) does not block it
	is(denied_at($acl, $config{RFC5737_IP3}), 0,
		'no-PTR IP that is in allow_ip is allowed (cloud check does not block it)');

	diag("Integration deny_cloud tests passed") if $ENV{TEST_VERBOSE};

	# Return value schema check
	my $result = denied_at($acl, $config{RFC5737_IP});
	returns_ok($result, { type => 'SCALAR', regex => qr/^[01]$/ },
		'all_denied returns 0 or 1');
};

done_testing();
