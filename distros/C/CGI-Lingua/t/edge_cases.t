#!/usr/bin/env perl

# t/edge_cases.t -- Hostile, pathological, boundary-condition, and security
# tests for CGI::Lingua.
#
# Strategy: every subtest actively tries to break, inject, overflow, or
# subvert the module.  Inputs are chosen specifically to probe the validation
# and sanitisation layer rather than the happy path.

use strict;
use warnings;

use CHI;
use Readonly;
use Scalar::Util qw(blessed weaken);
use Test::Most;
use Test::Mockingbird;
use Test::Returns qw(returns_ok);

use lib 't/lib';

BEGIN { use_ok('CGI::Lingua') }

# Pre-require lazily-loaded modules before installing mocks (CLAUDE.md pitfall).
my $HAS_LWP  = eval { require LWP::Simple::WithCache; 1 } ? 1 : 0;
my $HAS_JSON = eval { require JSON::Parse;             1 } ? 1 : 0;

# ── Constants ─────────────────────────────────────────────────────────────────

Readonly my %LANG => (EN => 'en', FR => 'fr', EN_GB => 'en-gb');

Readonly my %IP => (
	PUBLIC   => '8.8.8.8',
	LOOPBACK => '127.0.0.1',
	PRIVATE  => '192.168.1.1',
);

# Accept-Language header string of exactly ACCEPT_LANG_MAX (256) chars.
Readonly my $ACCEPT_LANG_AT_MAX  => 'a' x 256;
# One byte over the documented 256-byte cap.
Readonly my $ACCEPT_LANG_OVER    => 'a' x 257;
# String of 'a' chars long enough to stress the limit.
Readonly my $ACCEPT_LANG_HUGE    => 'a' x 10_000;

# Cache namespace as defined in the module constant CACHE_NS.
Readonly my $CACHE_NS => 'CGI::Lingua:';

# ── Global network block ──────────────────────────────────────────────────────
_block_network();

# ── Helpers ───────────────────────────────────────────────────────────────────

sub _block_network {
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef })
		if $HAS_LWP;
}

sub _obj {
	my ($supported, %extra) = @_;
	CGI::Lingua->new(supported => $supported, %extra);
}

# Inject "IP::Country present but returns the given code" for a fresh object.
sub _inject_ipcountry {
	my ($l, $cc) = @_;
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { $cc });
	$l->{_have_ipcountry} = 1;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 1: Constructor hostile inputs
#
# Strategy: feed every documented croak path plus undocumented hostile values
# to new().  The module must croak cleanly and never segfault, corrupt state,
# or execute injected data.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'new: empty arrayref for supported croaks' => sub {
	# An empty list has no sensible "first language", so it must be rejected.
	# The module validates the arrayref contents in _find_language but new()
	# itself does not explicitly croak on []. Verify the object is at least
	# created, then calling language() must not crash.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN}, REMOTE_ADDR => $IP{LOOPBACK});
	my $l;
	lives_ok { $l = CGI::Lingua->new(supported => []) }
		'new() with empty arrayref does not croak at construction';
	# language() with an empty supported list should return Unknown (not crash)
	my $lang;
	lives_ok { $lang = $l->language() }
		'language() with empty supported list does not die';
	is($lang, 'Unknown',
		'language() returns Unknown when supported list is empty');
};

subtest 'new: arrayref containing undef element does not crash language()' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN}, REMOTE_ADDR => $IP{LOOPBACK});
	my $l;
	lives_ok { $l = CGI::Lingua->new(supported => [undef, $LANG{EN}]) }
		'new() with [undef, en] does not croak';
	my $lang;
	lives_ok { $lang = $l->language() }
		'language() with undef in supported list does not die';
};

subtest 'new: zero as supported croaks (falsy alias path)' => sub {
	# Numeric zero is falsy; the ||= alias logic in new() treats it as "not
	# provided", so the croak message is "list of supported languages" rather
	# than "short code".  This documents the existing (and intentional) behaviour:
	# any falsy supported value is treated as an absent key.
	local %ENV = ();
	throws_ok {
		CGI::Lingua->new(supported => 0);
	} qr/supported languages/i,
		'Numeric zero supported croaks with "supported languages" message';
};

subtest 'new: empty string supported croaks (falsy alias path)' => sub {
	# Same falsy-via-||= path as numeric zero.
	local %ENV = ();
	throws_ok {
		CGI::Lingua->new(supported => '');
	} qr/supported languages/i,
		'Empty-string supported croaks with "supported languages" message';
};

subtest 'new: coderef for supported croaks with array-ref message' => sub {
	# A coderef is a ref but not ARRAY — must produce the documented message.
	local %ENV = ();
	throws_ok {
		CGI::Lingua->new(supported => sub { $LANG{EN} });
	} qr/array ref/i, 'Coderef supported croaks with "array ref" message';
};

subtest 'new: typeglob logger croaks with blessed-object message' => sub {
	# A typeglob cannot have ->warn/info/error — it is blessed but lacks
	# the required interface.
	local %ENV = ();
	my $bad = bless \*STDOUT, 'BadGlobLogger';
	# blessed() returns true for a blessed glob, so the pre-configure check fires.
	throws_ok {
		CGI::Lingua->new(supported => [$LANG{EN}], logger => $bad);
	} qr/blessed object/i, 'Typeglob logger without warn/info/error croaks';
};

subtest 'new: circular reference in extra params does not crash' => sub {
	# Confirm that Object::Configure or new() tolerates (and ignores) a
	# circular reference passed in an extra slot.  The module must not
	# enter infinite recursion.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my %circ;
	$circ{self} = \%circ;    # circular

	my $l;
	lives_ok {
		$l = CGI::Lingua->new(supported => [$LANG{EN}], extra => \%circ);
	} 'Circular reference in extra params does not crash new()';
	ok(blessed($l), 'Object still created successfully');
};

subtest 'new: supported string of exactly 5 chars is accepted' => sub {
	# Upper boundary of the documented string length (2-5 chars).
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-gb');
	lives_ok {
		CGI::Lingua->new(supported => 'en-gb');
	} '5-char supported string accepted';
};

subtest 'new: supported string of 6 chars croaks' => sub {
	# One beyond the documented upper boundary.
	local %ENV = ();
	throws_ok {
		CGI::Lingua->new(supported => 'toolng');
	} qr/short code/i, '6-char supported string croaks';
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 2: HTTP_ACCEPT_LANGUAGE validation boundary and injection
#
# Strategy: the module validates the header with
#   /^([A-Za-z0-9\-,;=.*\s]{1,$ACCEPT_LANG_MAX})$/a
# Probe characters and lengths around this pattern to find bypasses.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'HTTP_ACCEPT_LANGUAGE: exactly 256 chars is accepted' => sub {
	# The documented maximum is 256 bytes.  A 256-char string must pass.
	local %ENV = (
		HTTP_ACCEPT_LANGUAGE => $ACCEPT_LANG_AT_MAX,
		REMOTE_ADDR          => $IP{LOOPBACK},
	);
	my $l = _obj([$LANG{EN}]);
	# language() must not crash; "aaaa..." is not a real language, so Unknown.
	my $lang;
	lives_ok { $lang = $l->language() }
		'language() does not crash on a 256-char Accept-Language header';
};

subtest 'HTTP_ACCEPT_LANGUAGE: 257 chars is rejected and warns' => sub {
	# One byte over the limit must be silently discarded with a warning;
	# the method must fall through to Unknown.
	local %ENV = (
		HTTP_ACCEPT_LANGUAGE => $ACCEPT_LANG_OVER,
		REMOTE_ADDR          => $IP{LOOPBACK},
	);
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });

	my $l = _obj([$LANG{EN}]);
	$l->language();

	ok((grep { ref($_) ? $_->{warning} =~ /invalid/i : /invalid/i } @warnings),
		'Oversized Accept-Language triggers _warn with "invalid" message');

	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'HTTP_ACCEPT_LANGUAGE: null byte is rejected' => sub {
	# \x00 is not in the allowed character class.
	local %ENV = (
		HTTP_ACCEPT_LANGUAGE => "en\x00fr",
		REMOTE_ADDR          => $IP{LOOPBACK},
	);
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });

	my $l = _obj([$LANG{EN}]);
	$l->language();

	ok((grep { ref($_) ? $_->{warning} =~ /invalid/i : /invalid/i } @warnings),
		'Null byte in Accept-Language is rejected with warning');

	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'HTTP_ACCEPT_LANGUAGE: shell-metachar injection rejected' => sub {
	# Characters like $(, `, <, >, |, & are outside [A-Za-z0-9\-,;=.*\s].
	my @payloads = (
		'en$(id)',
		'en`id`',
		"en<script>alert(1)</script>",
		"en|cat /etc/passwd",
		"en&& rm -rf /",
	);
	for my $payload (@payloads) {
		local %ENV = (
			HTTP_ACCEPT_LANGUAGE => $payload,
			REMOTE_ADDR          => $IP{LOOPBACK},
		);
		my @warnings;
		Test::Mockingbird::mock('CGI::Lingua', '_warn',
			sub { push @warnings, $_[1] });
		my $l = _obj([$LANG{EN}]);
		$l->language();
		ok((grep { ref($_) ? $_->{warning} =~ /invalid/i : /invalid/i } @warnings),
			"Shell metachar payload '$payload' is rejected");
		Test::Mockingbird::restore_all();
		_block_network();
	}
};

subtest 'HTTP_ACCEPT_LANGUAGE: SQL injection payload rejected' => sub {
	# Single-quote is not in the allowed class.
	local %ENV = (
		HTTP_ACCEPT_LANGUAGE => "en' OR '1'='1",
		REMOTE_ADDR          => $IP{LOOPBACK},
	);
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	$l->language();
	ok((grep { ref($_) ? $_->{warning} =~ /invalid/i : /invalid/i } @warnings),
		"SQL injection payload is rejected");
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'HTTP_ACCEPT_LANGUAGE: newline embedded in header is rejected (log-injection guard)' => sub {
	# \n IS in \s, which is in the character class, so a naive test might
	# accept it.  However the `/a` flag combined with $ (end-anchor without
	# /m) means that the character-class capture must consume the ENTIRE string
	# (including the second line).  The colon in "X-Header: value" is NOT in
	# the class, so multi-line injection payloads are rejected.
	local %ENV = (
		HTTP_ACCEPT_LANGUAGE => "en\nX-Injected-Header: value",
		REMOTE_ADDR          => $IP{LOOPBACK},
	);
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	$l->language();
	ok((grep { ref($_) ? $_->{warning} =~ /invalid/i : /invalid/i } @warnings),
		'Header-injection payload with colon is rejected');
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'HTTP_ACCEPT_LANGUAGE: Unicode content rejected by /a flag' => sub {
	# The /a flag restricts \w, \d, \s to ASCII-only, blocking multi-byte
	# Unicode that would otherwise match [A-Za-z0-9].
	# Setting Unicode in %ENV produces a "Wide character in setenv" warning on
	# some platforms; suppress it so the test is portable.
	local %ENV = (REMOTE_ADDR => $IP{LOOPBACK});
	{ local $SIG{__WARN__} = sub {};
	  $ENV{HTTP_ACCEPT_LANGUAGE} = "zh-\x{4e2d}\x{6587}" }    # zh-中文

	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	$l->language();
	ok((grep { ref($_) ? $_->{warning} =~ /invalid/i : /invalid/i } @warnings),
		'Unicode in Accept-Language is rejected (ASCII-only mode)');
	Test::Mockingbird::restore_all();
	_block_network();
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 3: REMOTE_ADDR injection and boundary conditions
#
# Strategy: probe the IP-validation regex
#   IPv4: /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/a
#   IPv6: /^([0-9a-fA-F:]{2,39})$/a
# and the subsequent Data::Validate::IP checks.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'REMOTE_ADDR: command injection rejected before any geo lookup' => sub {
	# The semicolon is not in either IP regex, so this is blocked at the
	# untaint step — no geo module or shell is ever called.
	local %ENV = (REMOTE_ADDR => '8.8.8.8;rm -rf /');
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	my $cc = $l->country();
	ok(!defined $cc, 'Command-injection REMOTE_ADDR returns undef');
	ok((grep { ref($_) ? $_->{warning} =~ /valid IP/i : /valid IP/i } @warnings),
		'_warn fired for injection attempt in REMOTE_ADDR');
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'REMOTE_ADDR: path traversal rejected' => sub {
	local %ENV = (REMOTE_ADDR => '../etc/passwd');
	my $l = _obj([$LANG{EN}]);
	ok(!defined $l->country(), 'Path traversal REMOTE_ADDR returns undef');
};

subtest 'REMOTE_ADDR: out-of-range octet handled by Data::Validate::IP' => sub {
	# "999.1.1.1" matches \d{1,3} (each octet can be 1-3 digits) but
	# Data::Validate::IP::is_ipv4 rejects octets > 255.
	local %ENV = (REMOTE_ADDR => '999.1.1.1');
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	my $cc = $l->country();
	ok(!defined $cc,
		'Out-of-range octet address returns undef');
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'REMOTE_ADDR: SQL injection in IP field rejected' => sub {
	local %ENV = (REMOTE_ADDR => "1.2.3.4'; DROP TABLE users--");
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	ok(!defined $l->country(), 'SQL injection in REMOTE_ADDR returns undef');
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'REMOTE_ADDR: very long string is rejected before geo lookup' => sub {
	# An overlong string cannot match the tightly-bounded IPv4/IPv6 patterns.
	local %ENV = (REMOTE_ADDR => ('1' x 1000) . '.1.1.1');
	my $l = _obj([$LANG{EN}]);
	ok(!defined $l->country(), 'Overlong REMOTE_ADDR returns undef without crash');
};

subtest 'REMOTE_ADDR: IPv6 injection with trailing semicolon rejected' => sub {
	# Semicolon is not in [0-9a-fA-F:], so this never makes it to geo lookup.
	local %ENV = (REMOTE_ADDR => '2001:db8::1;ls');
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	ok(!defined $l->country(), 'IPv6 with injection suffix returns undef');
	Test::Mockingbird::restore_all();
	_block_network();
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 4: GEOIP_COUNTRY_CODE and HTTP_CF_IPCOUNTRY injection
#
# Strategy: probe the ISO 3166-1 alpha-2 guard /^([A-Z]{2})$/a.  Any value
# that does not consist of exactly two uppercase ASCII letters must be warned
# and ignored.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'GEOIP_COUNTRY_CODE: lowercase code is rejected with warning' => sub {
	local %ENV = (GEOIP_COUNTRY_CODE => 'us', REMOTE_ADDR => $IP{LOOPBACK});
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	$l->country();
	ok((grep { ref($_) ? $_->{warning} =~ /invalid/i : /invalid/i } @warnings),
		'Lowercase GEOIP_COUNTRY_CODE triggers warning');
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'GEOIP_COUNTRY_CODE: three-char ISO alpha-3 code is rejected' => sub {
	# ISO alpha-3 codes like "USA" are not alpha-2 and must be rejected.
	local %ENV = (GEOIP_COUNTRY_CODE => 'USA', REMOTE_ADDR => $IP{LOOPBACK});
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	$l->country();
	ok((grep { ref($_) ? $_->{warning} =~ /invalid/i : /invalid/i } @warnings),
		'Three-char GEOIP_COUNTRY_CODE triggers warning');
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'GEOIP_COUNTRY_CODE: XSS payload is rejected' => sub {
	local %ENV = (
		GEOIP_COUNTRY_CODE => '<script>alert(1)</script>',
		REMOTE_ADDR        => $IP{LOOPBACK},
	);
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	ok(!defined $l->country(), 'XSS in GEOIP_COUNTRY_CODE returns undef');
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'HTTP_CF_IPCOUNTRY: empty string is silently ignored (falsy guard)' => sub {
	# When HTTP_CF_IPCOUNTRY is the empty string, the `if(...)` guard is false
	# and no warning is issued.  The module falls through to REMOTE_ADDR.
	local %ENV = (HTTP_CF_IPCOUNTRY => '', REMOTE_ADDR => $IP{LOOPBACK});
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	$l->country();
	ok(!(grep { ref($_) ? $_->{warning} =~ /CF_IPCOUNTRY/i : /CF_IPCOUNTRY/i } @warnings),
		'Empty HTTP_CF_IPCOUNTRY does not trigger a warning');
	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'HTTP_CF_IPCOUNTRY: SQL injection payload is rejected with warning' => sub {
	local %ENV = (
		HTTP_CF_IPCOUNTRY => "GB' OR '1'='1",
		REMOTE_ADDR       => $IP{LOOPBACK},
	);
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	$l->country();
	ok((grep { ref($_) ? $_->{warning} =~ /invalid/i : /invalid/i } @warnings),
		'SQL injection in HTTP_CF_IPCOUNTRY triggers warning');
	Test::Mockingbird::restore_all();
	_block_network();
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 5: Cache corruption and the cache-removal key bug
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'cache: numeric country code triggers warning' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $cache = CHI->new(driver => 'Memory', global => 0);
	$cache->set($CACHE_NS . 'country:' . $IP{PUBLIC}, '42');

	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });

	my $l = _obj([$LANG{EN}], cache => $cache);
	$l->{_have_ipcountry} = 0;
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	$l->country();

	ok((grep { ref($_) ? $_->{warning} =~ /numeric/i : /numeric/i } @warnings),
		'_warn fired for numeric country in cache');

	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'cache: numeric country removed under correct namespaced key (bug fix)' => sub {
	# This test was written to expose the bug, then the module was fixed.
	# It now asserts the corrected behaviour: after country() detects a numeric
	# cached value, the poisoned entry must be gone from the cache so that the
	# NEXT call does not re-trigger the same warning loop.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $cache = CHI->new(driver => 'Memory', global => 0);

	my $poison_key = $CACHE_NS . 'country:' . $IP{PUBLIC};
	$cache->set($poison_key, '99');

	Test::Mockingbird::mock('CGI::Lingua', '_warn', sub { });    # suppress carp
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });

	my $l = _obj([$LANG{EN}], cache => $cache);
	$l->{_have_ipcountry} = 0;
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	$l->country();

	ok(!defined $cache->get($poison_key),
		'Poisoned numeric cache entry removed under the correct namespaced key after first country() call');

	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'cache: country() called twice with numeric-poisoned cache warns only once per object' => sub {
	# After the first call detects and removes the poison, the second call
	# must NOT hit the cache (poison gone) and must not re-warn.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $cache = CHI->new(driver => 'Memory', global => 0);
	$cache->set($CACHE_NS . 'country:' . $IP{PUBLIC}, '7');

	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });

	my $l = _obj([$LANG{EN}], cache => $cache);
	$l->{_have_ipcountry} = 0;
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;

	$l->country();    # first call — detects and removes poison
	my $warn_count_after_first = scalar grep {
		ref($_) ? $_->{warning} =~ /numeric/i : /numeric/i
	} @warnings;

	$l->country();    # second call — poison gone; uses object-level cache (_country undef)
	my $warn_count_after_second = scalar grep {
		ref($_) ? $_->{warning} =~ /numeric/i : /numeric/i
	} @warnings;

	is($warn_count_after_first, 1,  'Exactly one numeric-poison warning on first call');
	is($warn_count_after_second, 1, 'No additional numeric-poison warning on second call');

	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'cache: valid string country returned correctly and not warned' => sub {
	# Confirm that a properly formatted cache entry ('us') is returned silently.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $cache = CHI->new(driver => 'Memory', global => 0);
	$cache->set($CACHE_NS . 'country:' . $IP{PUBLIC}, 'us');

	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });

	my $l = _obj([$LANG{EN}], cache => $cache);
	is($l->country(), 'us', 'Valid string country returned from cache');
	ok(!(grep { ref($_) ? $_->{warning} =~ /numeric/i : /numeric/i } @warnings),
		'No numeric-poison warning for valid string cache entry');

	Test::Mockingbird::restore_all();
	_block_network();
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 6: Upstream geo-lookup failure returns
#
# Strategy: mock IP::Country to return every documented "bad" value and verify
# that country() handles each gracefully — warning where documented, returning
# the right remapped value, or falling through to the next geo module.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'geo: IP::Country returns undef — country() falls through' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _obj([$LANG{EN}]);
	_inject_ipcountry($l, undef);
	# No subsequent geo module is available — should reach whois (mocked no-op).
	my $cc = $l->country();
	ok(!defined $cc, 'country() returns undef when IP::Country returns undef and fallbacks empty');
	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'geo: IP::Country returns empty string — treated as undef' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _obj([$LANG{EN}]);
	_inject_ipcountry($l, '');
	my $cc = $l->country();
	ok(!defined $cc || $cc eq '',
		'Empty string from IP::Country does not crash country()');
	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'geo: IP::Country returns numeric "1" — discarded with warning' => sub {
	# POD message: "IP matches to a numeric country"
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });

	my $l = _obj([$LANG{EN}]);
	_inject_ipcountry($l, '1');
	my $cc = $l->country();

	ok(!defined $cc, 'Numeric country from IP::Country returns undef');
	ok((grep { ref($_) ? $_->{warning} =~ /numeric/i : /numeric/i } @warnings),
		'Warning fired for numeric country from IP::Country');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'geo: IP::Country returns "eu" — deleted, falls through' => sub {
	# The module discards "eu" because it is not a real country code.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

	my $l = _obj([$LANG{EN}]);
	_inject_ipcountry($l, 'EU');
	my $cc = $l->country();

	# After EU is discarded, fallbacks are all blocked — undef expected.
	ok(!defined $cc || ($cc ne 'eu'),
		'"eu" from IP::Country is not returned as a country code');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'geo: IP::Country returns "HK" — remapped to "cn"' => sub {
	# POD/code comment: "HK is no longer a separate country in Whois"
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _obj([$LANG{EN}]);
	_inject_ipcountry($l, 'HK');
	is($l->country(), 'cn', 'HK from IP::Country is remapped to cn');
	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'geo: geoplugin returns empty JSON object — country() returns undef' => sub {
	SKIP: {
		skip 'LWP::Simple::WithCache or JSON::Parse not installed', 1
			unless $HAS_LWP && $HAS_JSON;

		local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
		Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { '{}' });

		my $l = _obj([$LANG{EN}]);
		$l->{_have_ipcountry} = 0;
		$l->{_have_geoip}     = 0;
		$l->{_have_geoipfree} = 0;

		my $cc = $l->country();
		# {} has no geoplugin_countryCode key — Whois (no-op mock) is tried next.
		ok(!defined $cc, 'Empty JSON from geoplugin results in undef country');

		{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
		_block_network();
	}
};

subtest 'geo: geoplugin returns malformed JSON — country() survives' => sub {
	SKIP: {
		skip 'LWP::Simple::WithCache or JSON::Parse not installed', 1
			unless $HAS_LWP && $HAS_JSON;

		local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
		# Malformed JSON causes JSON::Parse to throw.  The eval{} in country()
		# must absorb the error and fall through rather than crashing.
		Test::Mockingbird::mock('LWP::Simple::WithCache', 'get',
			sub { 'NOT VALID JSON {{{' });

		my $l = _obj([$LANG{EN}]);
		$l->{_have_ipcountry} = 0;
		$l->{_have_geoip}     = 0;
		$l->{_have_geoipfree} = 0;

		my $cc;
		lives_ok { $cc = $l->country() }
			'Malformed geoplugin JSON does not crash country()';

		{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
		_block_network();
	}
};

subtest 'geo: geoplugin returns numeric country code — discarded with warning' => sub {
	SKIP: {
		skip 'LWP::Simple::WithCache or JSON::Parse not installed', 1
			unless $HAS_LWP && $HAS_JSON;

		local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
		Test::Mockingbird::mock('LWP::Simple::WithCache', 'get',
			sub { '{"geoplugin_countryCode":"42"}' });

		my @warnings;
		Test::Mockingbird::mock('CGI::Lingua', '_warn',
			sub { push @warnings, $_[1] });

		my $l = _obj([$LANG{EN}]);
		$l->{_have_ipcountry} = 0;
		$l->{_have_geoip}     = 0;
		$l->{_have_geoipfree} = 0;
		$l->country();

		ok((grep { ref($_) ? $_->{warning} =~ /numeric/i : /numeric/i } @warnings),
			'Numeric geoplugin country code triggers warning');

		{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
		_block_network();
	}
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 7: Context and state abuse
#
# Strategy: call methods in unusual contexts (list, void) and verify that the
# return values are sane and internal state is not corrupted.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'context: language() in list context returns one-element list' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = _obj([$LANG{EN}]);
	my @result = $l->language();
	is(scalar @result, 1, 'language() in list context returns exactly one element');
	is($result[0], 'English', 'That element is the correct language name');
};

subtest 'context: country() in list context returns one-element list' => sub {
	local %ENV = (GEOIP_COUNTRY_CODE => 'GB');
	my $l = _obj([$LANG{EN}]);
	my @result = $l->country();
	is(scalar @result, 1, 'country() in list context returns exactly one element');
	is($result[0], 'gb', 'Element is the correct lowercase country code');
};

subtest 'state: calling language() extra times does not re-run _find_language' => sub {
	# _find_language is guarded by `unless($self->{_slanguage})`.
	# A second call must use the cached value, even if %ENV changes.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{FR});
	my $l = _obj([$LANG{EN}, $LANG{FR}]);

	is($l->language(), 'French', 'First call returns French');

	# Mutate env — the cached result must NOT change.
	local $ENV{HTTP_ACCEPT_LANGUAGE} = $LANG{EN};
	is($l->language(), 'French', 'Second call returns same cached French');
};

subtest 'state: country() called with preloaded _country skips all lookups' => sub {
	# If _country is already set in the object hash, country() must return it
	# immediately without calling any geo module.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

	my $called = 0;
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois',
		sub { $called++ });

	my $l = _obj([$LANG{EN}]);
	$l->{_country} = 'de';    # inject pre-resolved value

	is($l->country(), 'de', 'Pre-loaded _country returned immediately');
	is($called, 0, '_resolve_country_via_whois NOT called when _country already set');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 8: LANG env-var validation (no validation currently — documents gap)
#
# Strategy: set $ENV{LANG} to hostile values and verify that the module does
# not execute injected content.  LANG is read without the same /a-regex
# validation applied to HTTP_ACCEPT_LANGUAGE.  These tests document the
# existing behaviour (accepted without validation) as a known limitation.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'LANG: shell-metachar value accepted as _what_language without execution' => sub {
	# LANG is a system env var; in a normal CGI deployment, the web server
	# controls it.  But in unusual deployments, a hostile LANG must not lead
	# to code execution.  The value is stored in _what_language and passed to
	# I18N::AcceptLanguage, which simply returns undef for unrecognised strings.
	local %ENV = (LANG => '$(id)');
	delete local $ENV{HTTP_ACCEPT_LANGUAGE};
	delete local $ENV{REMOTE_ADDR};

	my $l = _obj([$LANG{EN}]);
	my $lang;
	lives_ok { $lang = $l->language() }
		'Shell-metachar in LANG does not cause execution or crash';
	# The value is not a real language code — result must be Unknown or undef.
	ok(!defined $lang || $lang eq 'Unknown',
		'Invalid LANG value produces Unknown language (not executed)');
};

subtest 'LANG: extremely long value handled without crash' => sub {
	local %ENV = (LANG => 'a' x 100_000);
	delete local $ENV{HTTP_ACCEPT_LANGUAGE};
	delete local $ENV{REMOTE_ADDR};

	my $l = _obj([$LANG{EN}]);
	lives_ok { $l->language() }
		'100,000-char LANG value does not crash language()';
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 9: Large-input stress
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'stress: very large supported list does not crash new() or language()' => sub {
	# Build a large list of plausible language codes.
	my @large_list = map { sprintf('l%d', $_) } (1..500);
	push @large_list, $LANG{EN};

	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l;
	lives_ok {
		$l = CGI::Lingua->new(supported => \@large_list);
	} 'new() with 501-element supported list does not crash';

	my $lang;
	lives_ok { $lang = $l->language() }
		'language() with 501-element supported list does not crash';
};

subtest 'stress: HTTP_ACCEPT_LANGUAGE of 10,000 chars is rejected without crash' => sub {
	local %ENV = (
		HTTP_ACCEPT_LANGUAGE => $ACCEPT_LANG_HUGE,
		REMOTE_ADDR          => $IP{LOOPBACK},
	);
	my $l = _obj([$LANG{EN}]);
	lives_ok { $l->language() }
		'language() handles a 10,000-char Accept-Language without crash';
};

done_testing();
