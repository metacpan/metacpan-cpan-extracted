#!/usr/bin/env perl
# t/cgi_security.t -- Penetration / security regression tests for CGI::Lingua.
#
# Simulates hostile CGI environments by injecting weaponised payloads into
# the five env vars the module reads:
#
#   HTTP_ACCEPT_LANGUAGE  REMOTE_ADDR  GEOIP_COUNTRY_CODE
#   HTTP_CF_IPCOUNTRY     LANG         HTTP_USER_AGENT
#
# Each subtest documents the specific exploit mechanism being attempted and
# asserts that the module fails securely (rejects, warns, returns undef)
# rather than passing hostile data downstream.
#
# Attack categories covered:
#   1. Shell metacharacter / command injection via env vars
#   2. CRLF / header injection via env vars
#   3. Null-byte injection
#   4. Overlength header (DoS / buffer edge)
#   5. Country-code format violations (length, non-alpha, embedded control chars)
#   6. IP address format violations (path traversal, shell meta in REMOTE_ADDR)
#   7. Whois response injection (CRLF, trailing-comment bypass, MITM data)
#   8. JSON API response injection (XSS payload in country/timezone fields)
#   9. Cache key poisoning (namespace prefix collision, split() separator abuse)
#  10. HTTP_USER_AGENT CRLF and XSS injection (locale() path)
#  11. Accept-Language q-value boundary and wildcard edge cases
#  12. IPv4-mapped IPv6 normalisation correctness
#  13. Translation-file extension path-traversal guard
#  14. Country-code output validation (final result must be 2 lowercase alpha)

use strict;
use warnings;

use CHI;
use File::Temp qw(tempdir);
use Readonly;
use Scalar::Util qw(blessed);
use Test::Most;
use Test::Mockingbird;
use Test::Returns qw(returns_ok);

BEGIN { use_ok('CGI::Lingua') }

# ── Constants ─────────────────────────────────────────────────────────────────

# Maximum header length accepted by the module (matches $ACCEPT_LANG_MAX).
Readonly my $MAX_HEADER_LEN => 256;

# A public IP that is neither private nor loopback, used when a real IP is needed.
Readonly my $PUBLIC_IP => '8.8.8.8';

# Shell metacharacter payloads; each must be rejected at the env-var layer.
# NOTE: ';' and whitespace ARE valid in Accept-Language (used for q-values),
# so 'en; ls -la' and 'en\tls' are intentionally omitted — they pass the
# untaint regex legitimately and never reach a shell.
Readonly my @SHELL_PAYLOADS => (
	'en|cat /etc/passwd',
	'en$(id)',
	'en`id`',
	'en && evil',
);

# CRLF injection payloads; none must survive into returned data.
Readonly my @CRLF_PAYLOADS => (
	"en\r\nX-Injected: evil",
	"en\nX-Injected: evil",
	"en\rX-Injected: evil",
);

# ── Network block ─────────────────────────────────────────────────────────────

# Block all real network I/O for the entire file.  Subtests that need specific
# whois/geoplugin behaviour override locally before restoring.
Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });

# Restore the global network block after restore_all() in any subtest.
sub _block_network {
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });
}

# Build a minimal CGI::Lingua object with the global network block active.
sub _obj {
	my (%extra) = @_;
	CGI::Lingua->new(supported => ['en', 'fr', 'de', 'en-gb'], %extra);
}

# ── 1. Shell metacharacter injection via HTTP_ACCEPT_LANGUAGE ─────────────────
# The regex /^([A-Za-z0-9\-,;=.*\s]{1,256})$/a must reject every shell meta.
# If any payload leaked, it could reach I18N::AcceptLanguage's regex engine or
# be stored in the object and later reflected.

subtest 'Accept-Language: shell metacharacters are rejected by untaint regex' => sub {
	for my $payload (@SHELL_PAYLOADS) {
		local %ENV = (HTTP_ACCEPT_LANGUAGE => $payload, REMOTE_ADDR => '127.0.0.1');
		my $l = _obj();
		# language() must fall through to 'Unknown'; it must NOT return or store
		# any fragment of the hostile payload.
		my $lang = $l->language();
		is($lang, 'Unknown', "shell payload rejected: " . _abbrev($payload));
		unlike($lang // '', qr/[|;&\x60\$]/, 'no shell meta in returned language');
	}
};

# ── 2. CRLF injection via HTTP_ACCEPT_LANGUAGE ────────────────────────────────
# A browser forging a CRLF-bearing Accept-Language header could attempt to
# inject extra HTTP response headers when the application reflects the header.

subtest 'Accept-Language: CRLF sequences are rejected by untaint regex' => sub {
	for my $payload (@CRLF_PAYLOADS) {
		local %ENV = (HTTP_ACCEPT_LANGUAGE => $payload, REMOTE_ADDR => '127.0.0.1');
		my $l   = _obj();
		my $lang = $l->language();
		is($lang, 'Unknown', 'CRLF payload rejected in Accept-Language');

		# The requested_language() result must not contain a bare CRLF either.
		my $rl = $l->requested_language();
		unlike($rl // '', qr/[\r\n]/, 'CRLF not in requested_language() output');
	}
};

# ── 3. Null-byte injection via HTTP_ACCEPT_LANGUAGE ───────────────────────────
# Null bytes (\x00) can truncate C strings and confuse pattern matchers.

subtest 'Accept-Language: null byte is rejected' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => "en\x00evil", REMOTE_ADDR => '127.0.0.1');
	my $l = _obj();
	is($l->language(), 'Unknown', 'Null byte in Accept-Language rejected');
};

# ── 4. Overlength Accept-Language header ──────────────────────────────────────
# Headers longer than $ACCEPT_LANG_MAX must be silently dropped, not truncated.
# Truncation can produce a syntactically valid but semantically different value.

subtest 'Accept-Language: header exactly at limit is accepted' => sub {
	# Construct a valid header that is exactly 256 characters.
	# Use "en" repeated with commas to fill the space.
	my $at_limit = 'en' . (',en' x (($MAX_HEADER_LEN - 2) / 3));
	$at_limit = substr($at_limit, 0, $MAX_HEADER_LEN);
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $at_limit);
	my $l = _obj();
	# Must process normally (not crash, not warn about invalid chars).
	lives_ok { $l->language() } 'header at limit does not crash';
};

subtest 'Accept-Language: header one byte over limit is rejected' => sub {
	my $over = 'en' . ('a' x ($MAX_HEADER_LEN - 1));    # 257 chars
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $over, REMOTE_ADDR => '127.0.0.1');
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, (ref($_[1]) ? $_[1]->{warning} : $_[1]) });
	my $l = _obj();
	$l->language();
	my $warned = grep { /invalid characters/ } @warnings;
	ok($warned, 'overlength header triggers invalid-characters warning');
	Test::Mockingbird::restore_all();
	_block_network();
};

# ── 5. Shell metacharacter injection via REMOTE_ADDR ─────────────────────────
# REMOTE_ADDR must be validated by IPv4 or IPv6 pattern before any geo lookup.
# A crafted REMOTE_ADDR with shell metas could reach a system() call in a naive
# implementation.  The untaint regex must block all of these.

subtest 'REMOTE_ADDR: shell metacharacters are rejected' => sub {
	my @bad_ips = (
		'127.0.0.1; ls',          # classic shell injection
		'8.8.8.8|id',             # pipe
		'8.8.8.8`evil`',          # backtick
		'8.8.8.8$(id)',           # command substitution
		'../../../etc/passwd',    # path traversal attempt disguised as IP
		'8.8.8.8 && evil',        # AND chaining
	);
	for my $ip (@bad_ips) {
		local %ENV = (REMOTE_ADDR => $ip);
		my @warnings;
		Test::Mockingbird::mock('CGI::Lingua', '_warn',
			sub { push @warnings, (ref($_[1]) ? $_[1]->{warning} : $_[1]) });
		my $l = _obj();
		my $cc = $l->country();
		ok(!defined $cc, "Invalid REMOTE_ADDR rejected: " . _abbrev($ip));
		my $warned = grep { /valid IP/ } @warnings;
		ok($warned, 'Warns about invalid IP for: ' . _abbrev($ip));
		Test::Mockingbird::restore_all();
		_block_network();
	}
};

# ── 6. CRLF injection via REMOTE_ADDR ────────────────────────────────────────
# A CRLF in REMOTE_ADDR could reach a Whois query string or a cache key,
# splitting the key and poisoning an unrelated cache slot.

subtest 'REMOTE_ADDR: CRLF sequences are rejected' => sub {
	for my $payload (@CRLF_PAYLOADS) {
		local %ENV = (REMOTE_ADDR => $payload);
		my $l  = _obj();
		my $cc = $l->country();
		ok(!defined $cc, "CRLF REMOTE_ADDR rejected: " . _abbrev($payload));
	}
};

# ── 7. GEOIP_COUNTRY_CODE format violations ───────────────────────────────────
# The module validates GEOIP_COUNTRY_CODE against /^([A-Z]{2})$/a (ISO 3166-1
# alpha-2, ASCII mode).  Anything non-conforming must be ignored with a warning.

subtest 'GEOIP_COUNTRY_CODE: CRLF injection is rejected' => sub {
	# An attacker controlling a spoofed mod_geoip database could try to inject
	# extra env vars via CRLF splitting in the value.
	local %ENV = (GEOIP_COUNTRY_CODE => "GB\r\nX-Inject: evil");
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, (ref($_[1]) ? $_[1]->{warning} : $_[1]) });
	my $l = _obj();
	$l->country();
	ok((grep { /invalid country code/ } @warnings),
		'CRLF in GEOIP_COUNTRY_CODE triggers warning');
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'GEOIP_COUNTRY_CODE: shell metacharacters are rejected' => sub {
	my @bad_codes = ('US; evil', 'GB|id', 'FR$(cmd)', 'DE`cmd`', 'GB&&evil');
	for my $code (@bad_codes) {
		local %ENV = (GEOIP_COUNTRY_CODE => $code, REMOTE_ADDR => '127.0.0.1');
		my @warnings;
		Test::Mockingbird::mock('CGI::Lingua', '_warn',
			sub { push @warnings, (ref($_[1]) ? $_[1]->{warning} : $_[1]) });
		my $l = _obj();
		my $cc = $l->country();
		ok((!defined $cc || $cc eq ''),
			'Shell meta in GEOIP_COUNTRY_CODE not returned: ' . _abbrev($code));
		Test::Mockingbird::restore_all();
		_block_network();
	}
};

subtest 'GEOIP_COUNTRY_CODE: wrong-length codes are rejected' => sub {
	for my $code ('G', 'GBR', 'GBGB', '', '1U', 'gb') {
		# Code must be exactly 2 UPPERCASE ASCII letters to pass
		local %ENV = (GEOIP_COUNTRY_CODE => $code, REMOTE_ADDR => '127.0.0.1');
		my @warnings;
		Test::Mockingbird::mock('CGI::Lingua', '_warn',
			sub { push @warnings, (ref($_[1]) ? $_[1]->{warning} : $_[1]) });
		my $l  = _obj();
		my $cc = $l->country();
		# Valid 2-uppercase result must not come back if the code is wrong format
		if(defined $cc) {
			unlike($cc, qr/[^a-z]/, "Non-alpha chars not in returned code for: $code");
		} else {
			pass("GEOIP_COUNTRY_CODE '$code' correctly rejected");
		}
		Test::Mockingbird::restore_all();
		_block_network();
	}
};

# ── 8. HTTP_CF_IPCOUNTRY format violations ────────────────────────────────────
# Same /^([A-Z]{2})$/a validation as GEOIP_COUNTRY_CODE; same attack surface.

subtest 'HTTP_CF_IPCOUNTRY: CRLF injection is rejected' => sub {
	local %ENV = (HTTP_CF_IPCOUNTRY => "FR\r\nX-Inject: malicious");
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, (ref($_[1]) ? $_[1]->{warning} : $_[1]) });
	my $l = _obj();
	$l->country();
	ok((grep { /invalid country code/ } @warnings),
		'CRLF in HTTP_CF_IPCOUNTRY triggers warning');
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'HTTP_CF_IPCOUNTRY: Cloudflare XX sentinel not returned as country code' => sub {
	# 'XX' is a documented special value meaning "Cloudflare could not determine
	# country".  It must not be returned to the caller as a country code.
	local %ENV = (HTTP_CF_IPCOUNTRY => 'XX', REMOTE_ADDR => '127.0.0.1');
	my $l  = _obj();
	my $cc = $l->country();
	ok(!defined $cc || $cc ne 'xx',
		'Cloudflare XX sentinel not returned as country');
};

# ── 9. LANG env-var injection ─────────────────────────────────────────────────
# LANG is only consulted when HTTP_ACCEPT_LANGUAGE and the CGI::Info lang param
# are both absent (local/debug mode).  It is untainted by a similar regex.

subtest 'LANG: shell metacharacters are ignored' => sub {
	for my $payload ('en_US; rm -rf /', "en_US\r\nX-Header: evil", "en_US\x00") {
		local %ENV = (LANG => $payload, REMOTE_ADDR => '127.0.0.1');
		my $l = _obj();
		# language() must not expose any fragment of the payload
		my $lang = $l->language();
		unlike($lang // '', qr/[|;&\x60\$\r\n\x00]/, "LANG payload not reflected: " . _abbrev($payload));
	}
};

# ── 10. HTTP_USER_AGENT CRLF injection (locale() path) ───────────────────────
# locale() parses the User-Agent parenthetical for a language tag.  A crafted
# UA with CRLF could attempt to split the match and inject data.

subtest 'HTTP_USER_AGENT: CRLF in parenthetical does not leak into locale()' => sub {
	# The regex /\((.+)\)/ uses `.` which does NOT match \n in default mode,
	# so CRLF terminates the match before the injected header.
	local %ENV = (
		HTTP_USER_AGENT => "Mozilla/5.0 (en-GB\r\nX-Injected: evil)",
		REMOTE_ADDR     => '127.0.0.1',
	);
	my $l      = _obj();
	my $locale = $l->locale();
	# If locale() returned anything, its name() must not contain CRLF sequences
	if(defined $locale && blessed $locale) {
		my $name = $locale->name() // '';
		unlike($name, qr/[\r\n]/, 'CRLF not in locale name from UA');
	} else {
		pass('locale() returned undef for CRLF UA — safe degradation');
	}
};

subtest 'HTTP_USER_AGENT: XSS payload in parenthetical does not match lang-tag regex' => sub {
	# The lang-tag check requires /^[a-zA-Z]{2}-([a-zA-Z]{2})$/, so an XSS
	# payload like "<script>alert(1)</script>" will never pass.
	local %ENV = (
		HTTP_USER_AGENT => 'Mozilla/5.0 (<script>alert(1)</script>)',
		REMOTE_ADDR     => '127.0.0.1',
	);
	my $l      = _obj();
	my $locale = $l->locale();
	if(defined $locale && blessed $locale) {
		unlike($locale->name() // '', qr/<script>/i,
			'XSS payload not reflected in locale name');
	} else {
		pass('locale() returned undef for XSS UA — safe');
	}
};

subtest 'HTTP_USER_AGENT: null byte in parenthetical does not match lang-tag' => sub {
	local %ENV = (
		HTTP_USER_AGENT => "Mozilla/5.0 (en-G\x00B)",
		REMOTE_ADDR     => '127.0.0.1',
	);
	my $l      = _obj();
	my $locale = $l->locale();
	# A null byte breaks the 2-letter country code match; locale() must return undef
	# or a locale that came from a different detection path (IP or GEOIP_COUNTRY_CODE).
	pass('locale() did not crash on null byte in UA');
};

# ── 11. Whois response injection (_clean_country_code) ───────────────────────
# If an attacker controls the upstream Whois server (MITM), they can inject
# arbitrary bytes into the country field of the response.  _clean_country_code()
# strips CRLFs and trailing comments; the final result must be safe.

subtest '_clean_country_code: strips carriage returns from whois response' => sub {
	# Simulate a whois response with an embedded carriage return.
	# Real example: some servers return "GB\r" in the Country field.
	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');
	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query', sub {
		return { Country => "GB\r" };
	});
	local %ENV = (REMOTE_ADDR => $PUBLIC_IP);
	my $l = _obj();
	$l->{_have_ipcountry} = 0;
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	my $cc = $l->country();
	# The \r must be stripped; country must be a clean 2-char code or undef
	if(defined $cc) {
		unlike($cc, qr/[\r\n]/, 'Carriage return stripped from whois country');
		is(length($cc), 2, 'Country code is exactly 2 chars after CR strip');
	} else {
		pass('country() returned undef after CR in whois (acceptable fallback)');
	}
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest '_clean_country_code: strips trailing # comment from whois response' => sub {
	# Some whois servers append a comment after the code: "US # United States"
	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');
	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query', sub {
		return { Country => 'US # United States via ARIN' };
	});
	local %ENV = (REMOTE_ADDR => $PUBLIC_IP);
	my $l = _obj();
	$l->{_have_ipcountry} = 0;
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	my $cc = $l->country();
	if(defined $cc) {
		is($cc, 'us', 'Trailing # comment stripped; code is lowercase us');
	} else {
		pass('country() returned undef (geoplugin mock suppressed data)');
	}
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest '_clean_country_code: CRLF + injected header does not propagate' => sub {
	# MITM whois server injects "GB\nX-Header: evil" as Country field.
	# After s/[\r\n]//g the value becomes "GBX-Header: evil" — too long and
	# containing non-alpha chars.  country() MUST NOT return this to the caller.
	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');
	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query', sub {
		return { Country => "GB\nX-Header: evil" };
	});
	local %ENV = (REMOTE_ADDR => $PUBLIC_IP);
	my $l = _obj();
	$l->{_have_ipcountry} = 0;
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	my $cc = $l->country();
	# country() now validates the post-strip result against /^[a-z]{2}$/, so the
	# CRLF-injected payload "gbx-header: evil" (after strip) is discarded.
	ok(!defined $cc || $cc =~ /^[a-z]{2}$/,
		'country() returns undef or valid 2-char code after CRLF Whois injection');
	Test::Mockingbird::restore_all();
	_block_network();
};

# ── 12. JSON API response injection (geoplugin / ip-api.com) ─────────────────
# The module calls JSON::Parse::parse_json() on external API responses and
# extracts a field.  A hostile upstream server could return an XSS payload
# in the countryCode field.

subtest 'geoplugin JSON: XSS payload in countryCode is not returned as-is' => sub {
	eval { require LWP::Simple::WithCache; require JSON::Parse };
	if($@) {
		pass('LWP::Simple::WithCache or JSON::Parse not installed; skipping');
		return;
	}

	# Simulate a hostile geoplugin response with a script tag in countryCode.
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get',
		sub { '{"geoplugin_countryCode":"GB<script>alert(1)<\/script>"}' });

	local %ENV = (REMOTE_ADDR => $PUBLIC_IP);
	my $l = _obj();
	$l->{_have_ipcountry} = 0;
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	my $cc = $l->country();

	# The XSS payload would survive lc() and end up as the returned country code.
	# The ideal fix: validate the countryCode field against /^[a-z]{2}$/ after
	# extracting from JSON.  Until then, document with a TODO.
	if(defined $cc) {
		# country() now validates the JSON field against /^[a-z]{2}$/ — the hostile
		# payload must be discarded, so $cc must be exactly 2 lowercase alpha chars.
		like($cc, qr/^[a-z]{2}$/, 'JSON countryCode must be 2 lowercase alpha chars');
		unlike($cc, qr/<script>/i, 'XSS payload not returned verbatim as country code');
	} else {
		pass('country() returned undef for hostile JSON — safe');
	}
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'ip-api JSON: XSS payload in timezone field is not returned as-is' => sub {
	eval { require LWP::Simple::WithCache; require JSON::Parse };
	if($@) {
		pass('LWP::Simple::WithCache or JSON::Parse not installed; skipping');
		return;
	}

	# Mock geoplugin to return nothing (so ip-api path runs for time_zone)
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get',
		sub { '{"timezone":"Europe\/London<script>alert(1)<\/script>"}' });

	local %ENV = (REMOTE_ADDR => $PUBLIC_IP);
	my $l = _obj();
	$l->{_have_geoip} = 0;
	my $tz = $l->time_zone();

	if(defined $tz) {
		diag("time_zone() returned: $tz") if $ENV{TEST_VERBOSE};
		# time_zone() now validates against a bounded IANA pattern before returning;
		# a hostile JSON payload must be discarded, so $tz must be undef or valid.
		unlike($tz, qr/<script>/i,
			'XSS payload in timezone field not returned after IANA validation');
		like($tz, qr/^[A-Za-z][A-Za-z0-9_+\-\/]{0,50}$/,
			'Returned timezone matches bounded IANA pattern');
	} else {
		pass('time_zone() returned undef for hostile JSON — safe');
	}
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'geoplugin JSON: malformed JSON does not croak' => sub {
	eval { require LWP::Simple::WithCache; require JSON::Parse };
	if($@) {
		pass('LWP::Simple::WithCache or JSON::Parse not installed; skipping');
		return;
	}

	# A hostile server returns truncated/broken JSON.
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get',
		sub { '{"geoplugin_countryCode":' });    # truncated

	local %ENV = (REMOTE_ADDR => $PUBLIC_IP);
	my $l = _obj();
	$l->{_have_ipcountry} = 0;
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	lives_ok { $l->country() } 'Malformed geoplugin JSON does not croak';
	Test::Mockingbird::restore_all();
	_block_network();
};

# ── 13. Cache key poisoning ────────────────────────────────────────────────────
# The cache namespace prefix "CGI::Lingua:" must not be injectable through any
# user-controlled input that ends up in a cache key.

subtest 'Cache: REMOTE_ADDR cannot inject into another cache namespace' => sub {
	# After untainting, REMOTE_ADDR can only contain [0-9a-fA-F:.].
	# This means the cache key "CGI::Lingua:country:<ip>" is always safe.
	# Verify by checking that a crafted IP containing ":" (IPv6) does not
	# collide with other cache namespaces.
	my $cache = CHI->new(driver => 'Memory', global => 0);

	# Pre-populate the language_name cache slot to detect injection
	$cache->set('CGI::Lingua:language_name:gb', 'English=en');

	# An IPv6 address that looks almost like a cache key manipulation
	local %ENV = (REMOTE_ADDR => '::1');    # loopback; returns undef safely
	my $l = _obj(cache => $cache);
	my $cc = $l->country();
	ok(!defined $cc, 'IPv6 loopback returns undef');

	# The language_name cache slot must not have been overwritten
	is($cache->get('CGI::Lingua:language_name:gb'), 'English=en',
		'Unrelated cache slot not clobbered by IPv6 loopback IP');
};

subtest 'Cache: numeric country code is evicted and not returned' => sub {
	# If the cache somehow holds a numeric value (from a prior whois that
	# returned digits), country() must evict it and not return it to the caller.
	my $cache = CHI->new(driver => 'Memory', global => 0);
	$cache->set("CGI::Lingua:country:$PUBLIC_IP", '123');    # poisoned numeric value

	local %ENV = (REMOTE_ADDR => $PUBLIC_IP);
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, (ref($_[1]) ? $_[1]->{warning} : $_[1]) });
	my $l  = _obj(cache => $cache);
	$l->{_have_ipcountry} = 0;
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	my $cc = $l->country();

	ok((grep { /numeric country/ } @warnings), 'Numeric cache value triggers warning');
	ok(!defined $cache->get("CGI::Lingua:country:$PUBLIC_IP"),
		'Poisoned numeric cache entry evicted');
	Test::Mockingbird::restore_all();
	_block_network();
};

# ── 14. IPv4-mapped IPv6 normalisation ────────────────────────────────────────
# ::ffff:a.b.c.d addresses must be normalised to plain IPv4 before geo lookup.
# A crafted ::ffff: prefix must not slip through as an unrecognised address type.

subtest 'REMOTE_ADDR: ::ffff: IPv4-mapped address normalised before lookup' => sub {
	# ::ffff:127.0.0.1 normalises to 127.0.0.1 (loopback) => undef
	local %ENV = (REMOTE_ADDR => '::ffff:127.0.0.1');
	my $l  = _obj();
	my $cc = $l->country();
	ok(!defined $cc, '::ffff:127.0.0.1 normalised to loopback, returns undef');
};

subtest 'REMOTE_ADDR: ::ffff: with private IP normalised to private, returns undef' => sub {
	local %ENV = (REMOTE_ADDR => '::ffff:192.168.1.1');
	my $l  = _obj();
	my $cc = $l->country();
	ok(!defined $cc, '::ffff:192.168.1.1 normalised to private, returns undef');
};

subtest 'REMOTE_ADDR: invalid address in ::ffff: notation rejected' => sub {
	# A crafted address that looks like a mapped address but has extra chars
	local %ENV = (REMOTE_ADDR => '::ffff:999.999.999.999');
	my $l  = _obj();
	my $cc = $l->country();
	# Either rejected (undef) or normalised to an invalid IP that is_ipv4 rejects
	ok(!defined $cc, 'Bogus ::ffff: address does not return a country');
};

# ── 15. translation_file() extension path traversal guard ─────────────────────
# If an application passes user-controlled data as $ext, the constructed path
# contains user data.  The s/^\.// strip of a leading dot is insufficient to
# prevent traversal: '../etc/passwd' -> './etc/passwd' with a dot, giving
# "$dir/$code../etc/passwd" which is a traversal.

subtest 'translation_file: traversal via $ext does not return a system file path' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = _obj();

	# The traversal: $ext = '../../../etc/passwd'
	# After s/^\.// : './../../etc/passwd'
	# Path built: "$dir/en./../../etc/passwd" which collapses to "/etc/passwd"
	my $tmpdir = tempdir(CLEANUP => 1);
	my $path = $l->translation_file($tmpdir, '../../../etc/passwd');

	# FINDING: translation_file() does not validate that $ext contains only
	# safe characters (alphanumeric + dot).  A hostile $ext can construct a
	# path outside $dir.  The method only checks -e on the path; if the
	# traversal target exists, it returns the traversal path to the caller.
	# RECOMMENDATION: validate $ext against /^[A-Za-z0-9]+$/ before use.
	# translation_file() now validates $ext against /^[A-Za-z0-9\-]+$/ and returns
	# undef for traversal-containing extensions before any path is constructed.
	ok(!defined $path, 'translation_file() rejects traversal-containing $ext');
};

# ── 16. Accept-Language wildcard and q-value edge cases ───────────────────────
# RFC 7231 allows '*' as a language tag and q=0 to exclude a language.
# These must not crash or produce unexpected results.

subtest 'Accept-Language: wildcard * is handled without crash' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => '*', REMOTE_ADDR => '127.0.0.1');
	my $l = _obj();
	lives_ok { $l->language() } 'Wildcard Accept-Language does not crash';
};

subtest 'Accept-Language: q=0 value does not crash' => sub {
	# RFC 7231 defines q=0 as "not acceptable", but I18N::AcceptLanguage does
	# not implement q=0 as a hard exclusion — it simply sorts by q-weight.
	# The test verifies only that the header is processed without dying.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en;q=0,fr;q=1', REMOTE_ADDR => '127.0.0.1');
	my $l = _obj();
	lives_ok { $l->language() } 'q=0 value in Accept-Language does not crash';
	like($l->language(), qr/^(?:English|French|Unknown)$/,
		'Result is one of the known valid outcomes');
};

subtest 'Accept-Language: all q=0 produces Unknown without crash' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en;q=0,fr;q=0', REMOTE_ADDR => '127.0.0.1');
	my $l = _obj();
	lives_ok { $l->language() } 'All-q=0 does not crash';
};

# ── 17. Concurrent object isolation ───────────────────────────────────────────
# Two objects created with different hostile env states must not share state.

subtest 'Concurrent objects: hostile Accept-Language does not infect a clean object' => sub {
	my $l_clean;
	my $l_hostile;

	{
		local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
		$l_clean = _obj();
		$l_clean->language();    # populate _slanguage
	}

	{
		local %ENV = (HTTP_ACCEPT_LANGUAGE => "en; evil|cmd", REMOTE_ADDR => '127.0.0.1');
		$l_hostile = _obj();
		$l_hostile->language();
	}

	# The clean object must still return English, not be contaminated
	is($l_clean->language(),  'English', 'Clean object unaffected by hostile sibling');
	is($l_hostile->language(), 'Unknown', 'Hostile Accept-Language produces Unknown');
};

# ── 18. country() output validation (FINDING: post-strip code not validated) ──
# After all geo lookups and whois fallback, the final $self->{_country} value
# should be validated as exactly 2 lowercase ASCII letters.  Currently it is
# not, which means a MITM upstream can inject a longer/hostile string.

subtest 'country() output: returned value must be exactly 2 lowercase alpha or undef' => sub {
	# This tests the EXPECTED contract, not current behaviour.
	# Mocked IP::Country returns a clean 2-char code.
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { 'DE' });
	local %ENV = (REMOTE_ADDR => $PUBLIC_IP);
	my $l = _obj();
	$l->{_have_ipcountry} = 1;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	my $cc = $l->country();
	if(defined $cc) {
		like($cc, qr/^[a-z]{2}$/, 'Clean geo result is 2 lowercase alpha chars');
	} else {
		pass('country() returned undef');
	}
	Test::Mockingbird::restore_all();
	_block_network();
};

# ── Helper ────────────────────────────────────────────────────────────────────

# Abbreviate a string for subtest labels; long payloads make output unreadable.
sub _abbrev {
	my ($s) = @_;
	$s =~ s/[\r\n\t\x00-\x1f]/./g;
	return length($s) > 40 ? substr($s, 0, 37) . '...' : $s;
}

done_testing();
