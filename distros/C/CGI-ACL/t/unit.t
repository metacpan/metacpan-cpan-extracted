#!/usr/bin/env perl
# unit.t — black-box unit tests for CGI::ACL's documented public API.
#
# Strategy: each subtest exercises exactly one documented behaviour from the
# POD API specification.  A %ledger at the top enumerates every documented
# message and return state.  As each condition is triggered the ledger entry
# is deleted.  The final assertion verifies the ledger is empty — any
# remaining entries mean a documented API contract was never exercised.
#
# Test::Mockingbird mocks are file-scoped by default: $CLOUD_IP resolves to
# $CLOUD_HOST; every other address resolves to undef (non-cloud).  Individual
# subtests may install an inner mock_scoped to override the file-level guard
# for a single scenario (e.g. a dying DNS, or a 300-char overlong PTR).

use strict;
use warnings;
use Carp;	# required: prevents Test::Carp glob aliasing from clearing Carp::carp

use Test::Most;
use Test::Carp;
use Test::Mockingbird;
use Test::Returns;
use Readonly;
use Scalar::Util qw(refaddr);

BEGIN { use_ok('CGI::ACL') }

# ── Constants ──────────────────────────────────────────────────────────────────

# RFC 5737 / RFC 3849 documentation addresses — guaranteed non-routable
Readonly my $SAFE_IP	  => '203.0.113.5';
Readonly my $SAFE_IP_2	  => '198.51.100.1';
Readonly my $SAFE_CIDR	  => '192.0.2.0/24';
Readonly my $CIDR_INSIDE  => '192.0.2.42';
Readonly my $CIDR_OUTSIDE => '192.0.3.1';
Readonly my $LOOPBACK	  => '127.0.0.1';
Readonly my $IPv6_ADDR	  => '2001:db8::1';
Readonly my $IPv6_ADDR_2  => '2001:db8::2';

# Cloud IP: our file-level mock returns an AWS PTR for this address
Readonly my $CLOUD_IP	  => '1.2.3.4';
Readonly my $CLOUD_HOST	  => 'ec2-1-2-3-4.compute-1.amazonaws.com';

# Country codes used throughout
Readonly my $CC_GB	  => 'gb';
Readonly my $CC_US	  => 'us';
Readonly my $CC_CN	  => 'cn';
Readonly my $WILDCARD	  => q{*};

# ── API Ledger ─────────────────────────────────────────────────────────────────
# One entry per documented carp message and per documented return state.
# Subtests delete their entry as they exercise the condition.  The final
# subtest asserts the ledger is empty.

my %ledger = (

	# ── new() ──────────────────────────────────────────────────────────────
	msg_new_plain_fn	 => 'new(): POD message "use ->new() not ::new()" not triggered',
	ret_new_class_obj	 => 'new(): class-path return (CGI::ACL object) never exercised',
	ret_new_clone_obj	 => 'new(): clone-path return (CGI::ACL object) never exercised',
	ret_new_undef		 => 'new(): plain-function undef return never exercised',

	# ── allow_ip() ─────────────────────────────────────────────────────────
	msg_allow_ip_usage	 => 'allow_ip(): POD message "Usage: allow_ip" not triggered',
	msg_allow_ip_invalid	 => 'allow_ip(): POD message "is not a valid IP address" not triggered',
	ret_allow_ip_self_ok	 => 'allow_ip(): success $self return never exercised',
	ret_allow_ip_self_err	 => 'allow_ip(): error $self return never exercised',

	# ── deny_country() ─────────────────────────────────────────────────────
	msg_deny_country_usage	 => 'deny_country(): POD message "Usage: deny_country" not triggered',
	ret_deny_country_self_ok => 'deny_country(): success $self return never exercised',
	ret_deny_country_self_err=> 'deny_country(): error $self return never exercised',

	# ── allow_country() ────────────────────────────────────────────────────
	msg_allow_country_usage	   => 'allow_country(): POD message "Usage: allow_country" not triggered',
	ret_allow_country_self_ok  => 'allow_country(): success $self return never exercised',
	ret_allow_country_self_err => 'allow_country(): error $self return never exercised',

	# ── deny_cloud() ───────────────────────────────────────────────────────
	ret_deny_cloud_self	 => 'deny_cloud(): $self return never exercised',

	# ── deny_all_countries() ───────────────────────────────────────────────
	ret_deny_all_self	 => 'deny_all_countries(): $self return never exercised',

	# ── all_denied() → 0 (allow) ───────────────────────────────────────────
	ret_0_no_restrictions	 => 'all_denied() → 0: no-restrictions fast path never exercised',
	ret_0_non_cloud_no_more	 => 'all_denied() → 0: non-cloud + no further restrictions never exercised',
	ret_0_ip_exact		 => 'all_denied() → 0: exact IP match allow never exercised',
	ret_0_ip_cidr		 => 'all_denied() → 0: CIDR match allow never exercised',
	ret_0_country_allowed	 => 'all_denied() → 0: allowed country (wildcard-deny mode) never exercised',
	ret_0_country_not_denied => 'all_denied() → 0: country not in specific deny list never exercised',

	# ── all_denied() → 1 (deny) ────────────────────────────────────────────
	ret_1_invalid_addr	  => 'all_denied() → 1: invalid REMOTE_ADDR deny never exercised',
	ret_1_cloud_ip		  => 'all_denied() → 1: cloud IP deny never exercised',
	ret_1_ip_not_listed	  => 'all_denied() → 1: IP not in allow list never exercised',
	ret_1_wildcard_not_allowed=> 'all_denied() → 1: country not in wildcard allow list never exercised',
	ret_1_country_denied	  => 'all_denied() → 1: country in specific deny list never exercised',
	ret_1_unknown_country	  => 'all_denied() → 1: unknown/undef country never exercised',
	ret_1_no_lingua		  => 'all_denied() → 1: no-lingua deny never exercised',
	ret_1_non_blessed	  => 'all_denied() → 1: non-blessed lingua deny never exercised',

	# ── all_denied() carp messages ─────────────────────────────────────────
	msg_all_denied_no_lingua  => 'all_denied(): POD message "Usage: all_denied" not triggered',
	msg_all_denied_non_blessed=> 'all_denied(): POD message "lingua must be a blessed object" not triggered',
);

# ── Stub object: minimal CGI::Lingua workalike ─────────────────────────────────
{
	package Test::UnitLingua;
	sub new     { my ($class, $cc) = @_; bless { cc => $cc }, $class }
	sub country { $_[0]->{cc} }
}

# ── File-level DNS mock ─────────────────────────────────────────────────────────
# Prevents all real DNS round-trips.  $CLOUD_IP resolves to an AWS hostname;
# every other address is undef (non-cloud).  Inner subtests that need a
# different behaviour install their own mock_scoped, which shadows this one.

my $_dns_guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
	my ($ip) = @_;
	return $CLOUD_HOST if defined $ip && $ip eq $CLOUD_IP;
	return undef;
};

# ── Helper ─────────────────────────────────────────────────────────────────────

sub denied_at {
	my ($acl, $addr, %rest) = @_;
	local $ENV{REMOTE_ADDR} = $addr;
	return $acl->all_denied(%rest);
}

# ==============================================================================
# new()
# ==============================================================================

subtest 'new() — class method returns a blessed CGI::ACL object' => sub {
	# Exercises the class-path constructor (the common case).
	my $acl = CGI::ACL->new();
	isa_ok($acl, 'CGI::ACL', 'new() returns a CGI::ACL object');
	returns_ok($acl, { type => 'OBJECT' }, 'return satisfies OBJECT schema');
	delete $ledger{ret_new_class_obj};
};

subtest 'new() — constructor accepts and stores public field arguments' => sub {
	# POD SYNOPSIS shows pre-seeded construction: CGI::ACL->new(deny_cloud => 1).
	# We verify the object is usable (no crash on method calls) without making
	# real DNS calls (the file-level mock handles the cloud check).
	my $acl = CGI::ACL->new(deny_cloud => 1);
	isa_ok($acl, 'CGI::ACL', 'pre-seeded new() still returns an object');
	ok($acl->can('all_denied'), 'resulting object has all_denied()');
};

subtest 'new() — clone from an existing object makes an independent copy' => sub {
	# POD: "Calling new() on an existing object returns a clone."
	# Mutations to the clone must not propagate to the original.
	my $orig  = CGI::ACL->new()->allow_ip($SAFE_IP);
	my $clone = $orig->new();

	isa_ok($clone, 'CGI::ACL', 'clone is a CGI::ACL object');
	returns_ok($clone, { type => 'OBJECT' }, 'clone satisfies OBJECT schema');
	isnt(refaddr($orig), refaddr($clone), 'clone is a distinct object reference');

	# Adding an IP to the clone must not appear in the original
	$clone->allow_ip($SAFE_IP_2);
	is(denied_at($orig, $SAFE_IP_2), 1, 'IP added to clone is invisible to the original');
	delete $ledger{ret_new_clone_obj};
};

subtest 'new() — plain function call carps "use ->new()" and returns undef' => sub {
	# POD MESSAGES: CGI::ACL use ->new() not ::new() to instantiate
	# Callers who chain methods on the return value would crash silently if
	# we returned an object; returning undef forces an obvious error instead.
	my $result;
	does_carp_that_matches(
		sub { $result = CGI::ACL::new() },
		qr/use\s+->\s*new\(\)\s+not\s+::\s*new\(\)/,
	);
	is($result, undef, 'plain-function new() returns undef');
	ok(!defined $result, 'return is explicitly undef (not a false-but-defined value)');
	delete $ledger{msg_new_plain_fn};
	delete $ledger{ret_new_undef};
};

# ==============================================================================
# allow_ip()
# ==============================================================================

subtest 'allow_ip() — single IPv4 address allows exactly that IP' => sub {
	# Exercises the happy path and proves allow_ip returns $self.
	my $acl = CGI::ACL->new();
	my $ret = $acl->allow_ip($SAFE_IP);
	is($ret, $acl, 'allow_ip() returns $self on success');
	returns_ok($ret, { type => 'OBJECT' }, 'return satisfies OBJECT schema');
	is(denied_at($acl, $SAFE_IP),   0, 'allowed IP is permitted');
	is(denied_at($acl, $SAFE_IP_2), 1, 'unlisted IP is denied');
	delete $ledger{ret_allow_ip_self_ok};
};

subtest 'allow_ip() — named-parameter form (ip => $addr)' => sub {
	my $acl = CGI::ACL->new()->allow_ip(ip => $SAFE_IP);
	is(denied_at($acl, $SAFE_IP),   0, 'IP added via named param is permitted');
	is(denied_at($acl, $SAFE_IP_2), 1, 'unlisted IP is still denied');
};

subtest 'allow_ip() — CIDR block allows IPs inside the range' => sub {
	my $acl = CGI::ACL->new()->allow_ip($SAFE_CIDR);
	is(denied_at($acl, $CIDR_INSIDE),  0, 'IP inside CIDR is permitted');
	is(denied_at($acl, $CIDR_OUTSIDE), 1, 'IP outside CIDR is denied');
};

subtest 'allow_ip() — IPv6 single address' => sub {
	my $acl = CGI::ACL->new()->allow_ip($IPv6_ADDR);
	is(denied_at($acl, $IPv6_ADDR),   0, 'allowed IPv6 is permitted');
	is(denied_at($acl, $IPv6_ADDR_2), 1, 'unlisted IPv6 is denied');
};

subtest 'allow_ip() — non-hash/non-scalar ref argument carps "Usage: allow_ip" and returns $self' => sub {
	# Guard 1: ARRAY ref (not HASH) triggers the usage carp.
	my $acl = CGI::ACL->new();
	my $ret;
	does_carp_that_matches(
		sub { $ret = $acl->allow_ip(['bad']) },
		qr/Usage:\s*allow_ip/,
	);
	is($ret, $acl, 'returns $self (exact same object) on bad-ref error');
	delete $ledger{msg_allow_ip_usage};
	delete $ledger{ret_allow_ip_self_err};
};

subtest 'allow_ip() — missing ip value carps "Usage: allow_ip" and returns $self' => sub {
	# Guard 2: no ip key supplied → carp + $self.
	my $acl = CGI::ACL->new();
	my $ret;
	does_carp_that_matches(
		sub { $ret = $acl->allow_ip() },
		qr/Usage:\s*allow_ip/,
	);
	is($ret, $acl, 'returns $self on missing-arg error');
};

subtest 'allow_ip() — invalid format carps "is not a valid IP address" and returns $self' => sub {
	# Guard 3: format validation rejects non-IP strings.
	my $acl = CGI::ACL->new();
	my $ret;
	does_carp_that_matches(
		sub { $ret = $acl->allow_ip('not-a-valid-ip') },
		qr/allow_ip:.*is not a valid IP address/i,
	);
	is($ret, $acl, 'returns $self on format-validation error');
	delete $ledger{msg_allow_ip_invalid};
};

subtest 'allow_ip() — method chaining accumulates multiple addresses' => sub {
	# Each allow_ip() call returns $self so the calls can be chained.
	my $acl = CGI::ACL->new()
		->allow_ip($SAFE_IP)
		->allow_ip($SAFE_CIDR);

	is(denied_at($acl, $SAFE_IP),       0, 'first chained IP is allowed');
	is(denied_at($acl, $CIDR_INSIDE),   0, 'chained CIDR inside address is allowed');
	is(denied_at($acl, $CIDR_OUTSIDE),  1, 'unlisted address is still denied');
};

# ==============================================================================
# deny_country()
# ==============================================================================

subtest 'deny_country() — positional scalar denies that country, allows others' => sub {
	my $acl = CGI::ACL->new();
	my $ret = $acl->deny_country('CN');
	is($ret, $acl, 'deny_country() returns $self on success');
	returns_ok($ret, { type => 'OBJECT' }, 'return satisfies OBJECT schema');

	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_CN)), 1, 'denied country is denied');
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_GB)), 0, 'non-denied country is allowed');
	delete $ledger{ret_deny_country_self_ok};
};

subtest 'deny_country() — named-parameter form (country => $cc)' => sub {
	my $acl = CGI::ACL->new()->deny_country(country => 'CN');
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_CN)), 1, 'named-param deny works');
};

subtest 'deny_country() — arrayref adds multiple countries at once' => sub {
	my $acl = CGI::ACL->new()->deny_country(country => ['CN', 'RU']);
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	is($acl->all_denied(lingua => Test::UnitLingua->new('cn')), 1, 'first arrayref country denied');
	is($acl->all_denied(lingua => Test::UnitLingua->new('ru')), 1, 'second arrayref country denied');
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_GB)), 0, 'unlisted country allowed');
};

subtest 'deny_country() — wildcard "*" switches to default-deny mode' => sub {
	# POD: passing '*' means all countries are denied unless also in allow_country().
	my $acl = CGI::ACL->new()->deny_country($WILDCARD);
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_GB)), 1, 'wildcard denies GB');
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_US)), 1, 'wildcard denies US');
};

subtest 'deny_country() — country codes are stored lowercase (case-insensitive)' => sub {
	# POD COMMON PITFALLS: "Country codes are case-insensitive but stored lowercase."
	# deny_country('CN') should match lingua->country() returning 'cn' or 'CN'.
	my $acl = CGI::ACL->new()->deny_country('CN');
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	is($acl->all_denied(lingua => Test::UnitLingua->new('cn')), 1, 'uppercase deny matches lowercase lingua return');
	is($acl->all_denied(lingua => Test::UnitLingua->new('CN')), 1, 'uppercase deny matches uppercase lingua return (both lc-normalised)');
};

subtest 'deny_country() — non-array/non-hash ref carps "Usage: deny_country" and returns $self' => sub {
	# Guard 1: SCALAR ref (not HASH or ARRAY) triggers the usage carp.
	my $acl = CGI::ACL->new();
	my $ret;
	does_carp_that_matches(
		sub { $ret = $acl->deny_country(\'scalar-ref') },
		qr/Usage:\s*deny_country/,
	);
	is($ret, $acl, 'returns $self on bad-ref error');
	delete $ledger{msg_deny_country_usage};
	delete $ledger{ret_deny_country_self_err};
};

subtest 'deny_country() — missing argument carps "Usage: deny_country" and returns $self' => sub {
	my $acl = CGI::ACL->new();
	my $ret;
	does_carp_that_matches(
		sub { $ret = $acl->deny_country() },
		qr/Usage:\s*deny_country/,
	);
	is($ret, $acl, 'returns $self on missing-argument error');
};

# ==============================================================================
# allow_country()
# ==============================================================================

subtest 'allow_country() — alone has no restrictive effect (documented pitfall)' => sub {
	# POD COMMON PITFALLS §1: "allow_country alone has no effect."
	# Without deny_country('*'), all traffic is already allowed; allow_country
	# adds no restriction and must not cause non-listed countries to be denied.
	my $acl = CGI::ACL->new();
	my $ret = $acl->allow_country('GB');
	is($ret, $acl, 'allow_country() returns $self on success');
	returns_ok($ret, { type => 'OBJECT' }, 'return satisfies OBJECT schema');

	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_US)), 0,
		'allow_country alone: non-listed country is still allowed (no wildcard deny active)');
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_GB)), 0,
		'allow_country alone: listed country has no special effect without deny_country("*")');
	delete $ledger{ret_allow_country_self_ok};
};

subtest 'allow_country() + deny_country("*") — permit-list mode' => sub {
	# The meaningful use of allow_country: paired with deny_country('*') it
	# forms an explicit permit list (allowlist).
	my $acl = CGI::ACL->new()->deny_country($WILDCARD)->allow_country('GB');
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_GB)), 0, 'allow-listed GB is permitted');
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_US)), 1, 'non-listed US is denied');
};

subtest 'allow_country() — arrayref adds multiple permitted countries at once' => sub {
	my $acl = CGI::ACL->new()
		->deny_country($WILDCARD)
		->allow_country(country => ['GB', 'US']);
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_GB)), 0, 'GB from arrayref permitted');
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_US)), 0, 'US from arrayref permitted');
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_CN)), 1, 'CN not in list denied');
};

subtest 'allow_country() — non-array/non-hash ref carps "Usage: allow_country" and returns $self' => sub {
	# Guard 1: CODE ref triggers the usage carp.
	my $acl = CGI::ACL->new();
	my $ret;
	does_carp_that_matches(
		sub { $ret = $acl->allow_country(sub {}) },
		qr/Usage:\s*allow_country/,
	);
	is($ret, $acl, 'returns $self on bad-ref error');
	delete $ledger{msg_allow_country_usage};
	delete $ledger{ret_allow_country_self_err};
};

subtest 'allow_country() — missing argument carps "Usage: allow_country" and returns $self' => sub {
	my $acl = CGI::ACL->new();
	my $ret;
	does_carp_that_matches(
		sub { $ret = $acl->allow_country() },
		qr/Usage:\s*allow_country/,
	);
	is($ret, $acl, 'returns $self on missing-argument error');
};

# ==============================================================================
# deny_cloud()
# ==============================================================================

subtest 'deny_cloud() — returns $self for method chaining' => sub {
	my $acl = CGI::ACL->new();
	my $ret = $acl->deny_cloud();
	is($ret, $acl, 'deny_cloud() returns $self');
	returns_ok($ret, { type => 'OBJECT' }, 'return satisfies OBJECT schema');
	delete $ledger{ret_deny_cloud_self};
};

subtest 'deny_cloud() — cloud IP is denied (even when in the allow_ip list)' => sub {
	# POD: "deny_cloud takes precedence over allow_ip."
	# POD COMMON PITFALLS §2: "deny_cloud overrides allow_ip."
	my $acl = CGI::ACL->new()->deny_cloud()->allow_ip($CLOUD_IP);
	is(denied_at($acl, $CLOUD_IP), 1, 'cloud IP denied even when in allow_ip list');
	delete $ledger{ret_1_cloud_ip};
};

subtest 'deny_cloud() — non-cloud IP is allowed when deny_cloud is the only rule' => sub {
	# POD PSEUDOCODE: "IF is_cloud THEN RETURN 1 ... IF no meaningful further
	# restrictions THEN RETURN 0".  Non-cloud + no IP list + no country list → allow.
	my $acl = CGI::ACL->new()->deny_cloud();
	is(denied_at($acl, $SAFE_IP), 0, 'non-cloud IP allowed (deny_cloud is the only active rule)');
	delete $ledger{ret_0_non_cloud_no_more};
};

# ==============================================================================
# deny_all_countries()
# ==============================================================================

subtest 'deny_all_countries() — returns $self for method chaining' => sub {
	my $acl = CGI::ACL->new();
	my $ret = $acl->deny_all_countries();
	is($ret, $acl, 'deny_all_countries() returns $self');
	returns_ok($ret, { type => 'OBJECT' }, 'return satisfies OBJECT schema');
	delete $ledger{ret_deny_all_self};
};

subtest 'deny_all_countries() — equivalent to deny_country("*")' => sub {
	# POD: "Sugar for deny_country('*')."  Both methods must produce identical
	# all_denied() results for the same allow-list configuration.
	my $acl_sugar = CGI::ACL->new()->deny_all_countries()->allow_country('GB');
	my $acl_raw   = CGI::ACL->new()->deny_country($WILDCARD)->allow_country('GB');
	local $ENV{REMOTE_ADDR} = $SAFE_IP;

	is($acl_sugar->all_denied(lingua => Test::UnitLingua->new($CC_GB)),
	   $acl_raw->all_denied(  lingua => Test::UnitLingua->new($CC_GB)),
	   'deny_all_countries + allow GB: matches deny_country("*") + allow GB for listed country');

	is($acl_sugar->all_denied(lingua => Test::UnitLingua->new($CC_CN)),
	   $acl_raw->all_denied(  lingua => Test::UnitLingua->new($CC_CN)),
	   'deny_all_countries: non-listed country result identical to deny_country("*")');
};

# ==============================================================================
# all_denied()
# ==============================================================================

subtest 'all_denied() — no restrictions: always returns 0 (allow)' => sub {
	# POD evaluation order §1: fast-path return when nothing is configured.
	my $acl = CGI::ACL->new();
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	my $result = $acl->all_denied();
	is($result, 0, 'no restrictions: all_denied returns 0');
	returns_ok($result, { type => 'SCALAR', regex => qr/^[01]$/ }, 'return is 0 or 1');
	delete $ledger{ret_0_no_restrictions};
};

subtest 'all_denied() — malformed REMOTE_ADDR always returns 1 (deny)' => sub {
	# POD evaluation order §2: invalid address → deny.
	# \z anchor ensures a trailing \n does not slip past the validator.
	my $acl = CGI::ACL->new()->allow_ip($SAFE_IP);
	is(denied_at($acl, 'not-an-ip'),        1, 'non-IP string in REMOTE_ADDR is denied');
	is(denied_at($acl, '999.999.999.999'),  1, 'out-of-range quad is denied');
	is(denied_at($acl, "1.2.3.4\n"),        1, 'trailing newline is denied (\\z anchor enforced)');
	delete $ledger{ret_1_invalid_addr};
};

subtest 'all_denied() — absent REMOTE_ADDR defaults to 127.0.0.1' => sub {
	# POD PSEUDOCODE: "raw := REMOTE_ADDR // '127.0.0.1'"
	delete local $ENV{REMOTE_ADDR};

	# An ACL that explicitly allows loopback must let the defaulted address through
	my $acl_match = CGI::ACL->new()->allow_ip($LOOPBACK);
	is($acl_match->all_denied(), 0, 'absent REMOTE_ADDR → 127.0.0.1 → matches loopback allow');

	# An ACL that does not include loopback must deny the defaulted address
	my $acl_miss = CGI::ACL->new()->allow_ip($SAFE_IP);
	is($acl_miss->all_denied(), 1, 'absent REMOTE_ADDR → 127.0.0.1 → not in allow list → denied');
};

subtest 'all_denied() — exact IP match returns 0 (allow)' => sub {
	# POD evaluation order §4 (first branch): exact-match hash lookup.
	my $acl = CGI::ACL->new()->allow_ip($SAFE_IP);
	is(denied_at($acl, $SAFE_IP),   0, 'exact IP match returns 0 (allow)');
	is(denied_at($acl, $SAFE_IP_2), 1, 'non-matching IP returns 1 (deny)');
	delete $ledger{ret_0_ip_exact};
};

subtest 'all_denied() — CIDR range match returns 0 (allow)' => sub {
	# POD evaluation order §4 (second branch): Net::CIDR range lookup.
	my $acl = CGI::ACL->new()->allow_ip($SAFE_CIDR);
	is(denied_at($acl, $CIDR_INSIDE),  0, 'IP inside CIDR returns 0 (allow)');
	is(denied_at($acl, $CIDR_OUTSIDE), 1, 'IP outside CIDR returns 1 (deny)');
	delete $ledger{ret_0_ip_cidr};
};

subtest 'all_denied() — IP allow list configured but no match returns 1 (deny)' => sub {
	# POD evaluation order §4: no match → fall through → deny (no further rules).
	my $acl = CGI::ACL->new()->allow_ip($SAFE_IP);
	is(denied_at($acl, $SAFE_IP_2), 1, 'unlisted IP is denied');
	delete $ledger{ret_1_ip_not_listed};
};

subtest 'all_denied() — wildcard deny + allow_country: listed country returns 0' => sub {
	# POD evaluation order §5 (wildcard branch): country in allow_countries → allow.
	my $acl = CGI::ACL->new()->deny_country($WILDCARD)->allow_country('GB');
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_GB)), 0, 'allow-listed country is permitted');
	delete $ledger{ret_0_country_allowed};
};

subtest 'all_denied() — wildcard deny + allow_country: non-listed country returns 1' => sub {
	# POD evaluation order §5 (wildcard branch): country not in allow_countries → deny.
	my $acl = CGI::ACL->new()->deny_country($WILDCARD)->allow_country('GB');
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_US)), 1, 'non-allow-listed country is denied');
	delete $ledger{ret_1_wildcard_not_allowed};
};

subtest 'all_denied() — specific deny list: matching country returns 1 (deny)' => sub {
	# POD evaluation order §5 (specific-deny branch): country in deny_countries → deny.
	my $acl = CGI::ACL->new()->deny_country($CC_CN);
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_CN)), 1, 'denied country is denied');
	delete $ledger{ret_1_country_denied};
};

subtest 'all_denied() — specific deny list: non-matching country returns 0 (allow)' => sub {
	# POD evaluation order §5 (specific-deny branch): country not in deny_countries → allow.
	my $acl = CGI::ACL->new()->deny_country($CC_CN);
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	is($acl->all_denied(lingua => Test::UnitLingua->new($CC_GB)), 0, 'non-denied country is allowed');
	delete $ledger{ret_0_country_not_denied};
};

subtest 'all_denied() — unknown country (undef from lingua) returns 1 (deny)' => sub {
	# POD PSEUDOCODE: "IF country is falsy (undef / "" / "0") THEN RETURN 1"
	my $acl = CGI::ACL->new()->deny_country($CC_CN);
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	is($acl->all_denied(lingua => Test::UnitLingua->new(undef)), 1, 'undef country causes deny');
	delete $ledger{ret_1_unknown_country};
};

subtest 'all_denied() — country restriction with no lingua carps "Usage: all_denied" and returns 1' => sub {
	# POD MESSAGES: "Usage: all_denied($lingua)"
	# POD COMMON PITFALLS §4: "Forgetting the lingua argument."
	my $acl = CGI::ACL->new()->deny_country($CC_CN);
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	my $result;
	does_carp_that_matches(
		sub { $result = $acl->all_denied() },
		qr/Usage:\s*all_denied/,
	);
	is($result, 1, 'no-lingua call returns 1 (deny)');
	returns_ok($result, { type => 'SCALAR', regex => qr/^[01]$/ }, 'return is 0 or 1');
	delete $ledger{msg_all_denied_no_lingua};
	delete $ledger{ret_1_no_lingua};
};

subtest 'all_denied() — non-blessed lingua carps "lingua must be a blessed object" and returns 1' => sub {
	# POD MESSAGES: "all_denied: lingua must be a blessed object"
	my $acl = CGI::ACL->new()->deny_country($CC_CN);
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	my $result;
	does_carp_that_matches(
		sub { $result = $acl->all_denied(lingua => 'plain-string') },
		qr/lingua must be a blessed object/,
	);
	is($result, 1, 'non-blessed lingua returns 1 (deny)');
	delete $ledger{msg_all_denied_non_blessed};
	delete $ledger{ret_1_non_blessed};
};

subtest 'all_denied() — IP in allow list short-circuits country check entirely' => sub {
	# POD evaluation order §4 returns 0 before reaching §5.  A denied country
	# paired with an allowed IP must still result in 0 (allow).
	my $acl = CGI::ACL->new()
		->allow_ip($SAFE_IP)
		->deny_country($CC_US);

	is(denied_at($acl, $SAFE_IP, lingua => Test::UnitLingua->new($CC_US)), 0,
		'matched allow_ip short-circuits country check (denied country ignored for allowed IP)');
};

# ==============================================================================
# Global state integrity
# ==============================================================================

subtest 'all_denied() — does not corrupt alarm() state of the calling process' => sub {
	# POD SIDE EFFECTS: none beyond _cidrlist and _cloud_cache.
	# The DNS timeout code sets and restores alarm(); that must not clobber
	# an alarm the caller had running.  With the DNS mock active the alarm
	# path is not reached, but we confirm the calling alarm survives.
	if ($^O eq 'MSWin32') {
		plan skip_all => 'alarm() is not supported on Windows';
		return;
	}
	my $acl = CGI::ACL->new()->deny_cloud();
	my $before = alarm(30);		# start a 30-second countdown
	eval { denied_at($acl, $SAFE_IP) };
	my $remaining = alarm($before);	# restore and capture what was left
	ok($remaining > 0, 'alarm() countdown survived the all_denied() call (was not zeroed)');
};

subtest 'all_denied() — clears $@ after a DNS exception (no stale error leaks to caller)' => sub {
	# POD / Changes 0.10: "$@ must be cleared after capturing DNS eval error".
	# Inner mock overrides the file-level guard to force a DNS die, exercising
	# the $@ cleanup path.  The result must be 0 (fail-safe: treat as non-cloud).
	my $guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { die 'simulated DNS timeout' };
	my $acl = CGI::ACL->new()->deny_cloud();
	$@ = 'stale-error-from-before';
	my $result = denied_at($acl, $SAFE_IP);
	my $err = $@;
	undef $@;
	is($result, 0, 'DNS exception → fail-safe: non-cloud assumed, allow returned');
	ok(!$err, '$@ is clean after all_denied() handles a DNS exception (no stale error)');
};

subtest 'all_denied() — does not clobber $_ in the calling scope' => sub {
	# POD SIDE EFFECTS does not list $_ — it must not be modified.
	my $acl = CGI::ACL->new()->deny_country($CC_CN);
	local $ENV{REMOTE_ADDR} = $SAFE_IP;
	local $_ = 'sentinel';
	$acl->all_denied(lingua => Test::UnitLingua->new($CC_GB));
	is($_, 'sentinel', '$_ is unchanged after all_denied()');
};

# ==============================================================================
# COMMON PITFALLS (explicit POD section coverage)
# ==============================================================================

subtest 'PITFALL §3 — localhost is not automatically allowed once restrictions are set' => sub {
	# POD: "Note that localhost (127.0.0.1) is not automatically allowed once
	# any restriction is configured; call allow_ip('127.0.0.1') explicitly."
	my $acl = CGI::ACL->new()->allow_ip($SAFE_IP);	# no loopback entry
	is(denied_at($acl, $LOOPBACK), 1,
		'loopback is denied by an IP-restricted ACL that does not list 127.0.0.1');
};

subtest 'PITFALL §5 — VPN and proxy users bypass IP restrictions' => sub {
	# POD: "A client behind a VPN or HTTP proxy presents its exit-node address."
	# Verify that a VPN exit-node IP that is NOT in the allow list is denied,
	# even if the real client's original IP would have been allowed.
	my $acl = CGI::ACL->new()->allow_ip($SAFE_IP);
	is(denied_at($acl, $SAFE_IP_2), 1,
		'a different (VPN exit-node) IP that is not in the allow list is denied');
};

subtest 'PITFALL §6 — country code input is case-insensitive, stored lowercase' => sub {
	# POD: "Country codes are case-insensitive but stored lowercase."
	# deny_country('GB') and deny_country('gb') must produce identical behaviour.
	my $acl_upper = CGI::ACL->new()->deny_country('GB');
	my $acl_lower = CGI::ACL->new()->deny_country('gb');
	local $ENV{REMOTE_ADDR} = $SAFE_IP;

	is($acl_upper->all_denied(lingua => Test::UnitLingua->new('gb')),
	   $acl_lower->all_denied(lingua => Test::UnitLingua->new('gb')),
	   'deny_country("GB") == deny_country("gb") for lowercase lingua return');
	is($acl_upper->all_denied(lingua => Test::UnitLingua->new('GB')),
	   $acl_lower->all_denied(lingua => Test::UnitLingua->new('GB')),
	   'deny_country("GB") == deny_country("gb") for uppercase lingua return');
};

# ==============================================================================
# Ledger assertion — every documented API contract must have been exercised
# ==============================================================================

subtest 'API Ledger — all documented messages and return states were exercised' => sub {
	for my $key (sort keys %ledger) {
		fail("UNTESTED DOCUMENTED CONTRACT: $ledger{$key}");
	}
	is(scalar keys %ledger, 0, 'ledger is empty — no documented API gap remains');
};

done_testing();
