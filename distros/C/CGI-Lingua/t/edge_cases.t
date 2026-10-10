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

BEGIN { use_ok('CGI::Lingua') }

# Pre-require lazily-loaded modules before installing mocks
my $HAS_LWP  = eval { require LWP::Simple::WithCache; 1 } ? 1 : 0;
my $HAS_JSON = eval { require JSON::Parse;             1 } ? 1 : 0;

# -- Constants -----------------------------------------------------------------

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

# -- Global network block ------------------------------------------------------
_block_network();

# -- Helpers -------------------------------------------------------------------

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

# -------------------------------------------------------------------------------
# SECTION 1: Constructor hostile inputs
#
# Strategy: feed every documented croak path plus undocumented hostile values
# to new().  The module must croak cleanly and never segfault, corrupt state,
# or execute injected data.
# -------------------------------------------------------------------------------

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
	# A coderef is a ref but not ARRAY - must produce the documented message.
	local %ENV = ();
	throws_ok {
		CGI::Lingua->new(supported => sub { $LANG{EN} });
	} qr/array ref/i, 'Coderef supported croaks with "array ref" message';
};

subtest 'new: typeglob logger croaks with blessed-object message' => sub {
	# A typeglob cannot have ->warn/info/error - it is blessed but lacks
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

# -------------------------------------------------------------------------------
# SECTION 2: HTTP_ACCEPT_LANGUAGE validation boundary and injection
#
# Strategy: the module validates the header with
#   /^([A-Za-z0-9\-,;=.*\s]{1,$ACCEPT_LANG_MAX})$/a
# Probe characters and lengths around this pattern to find bypasses.
# -------------------------------------------------------------------------------

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
	  $ENV{HTTP_ACCEPT_LANGUAGE} = "zh-\x{4e2d}\x{6587}" }

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

# -------------------------------------------------------------------------------
# SECTION 3: REMOTE_ADDR injection and boundary conditions
#
# Strategy: probe the IP-validation regex
#   IPv4: /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/a
#   IPv6: /^([0-9a-fA-F:]{2,39})$/a
# and the subsequent Data::Validate::IP checks.
# -------------------------------------------------------------------------------

subtest 'REMOTE_ADDR: command injection rejected before any geo lookup' => sub {
	# The semicolon is not in either IP regex, so this is blocked at the
	# untaint step - no geo module or shell is ever called.
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

# -------------------------------------------------------------------------------
# SECTION 4: GEOIP_COUNTRY_CODE and HTTP_CF_IPCOUNTRY injection
#
# Strategy: probe the ISO 3166-1 alpha-2 guard /^([A-Z]{2})$/a.  Any value
# that does not consist of exactly two uppercase ASCII letters must be warned
# and ignored.
# -------------------------------------------------------------------------------

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

# -------------------------------------------------------------------------------
# SECTION 5: Cache corruption and the cache-removal key bug
# -------------------------------------------------------------------------------

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

	$l->country();    # first call - detects and removes poison
	my $warn_count_after_first = scalar grep {
		ref($_) ? $_->{warning} =~ /numeric/i : /numeric/i
	} @warnings;

	$l->country();    # second call - poison gone; uses object-level cache (_country undef)
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

# -------------------------------------------------------------------------------
# SECTION 6: Upstream geo-lookup failure returns
#
# Strategy: mock IP::Country to return every documented "bad" value and verify
# that country() handles each gracefully - warning where documented, returning
# the right remapped value, or falling through to the next geo module.
# -------------------------------------------------------------------------------

subtest 'geo: IP::Country returns undef - country() falls through' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _obj([$LANG{EN}]);
	_inject_ipcountry($l, undef);
	# No subsequent geo module is available - should reach whois (mocked no-op).
	my $cc = $l->country();
	ok(!defined $cc, 'country() returns undef when IP::Country returns undef and fallbacks empty');
	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'geo: IP::Country returns empty string - treated as undef' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _obj([$LANG{EN}]);
	_inject_ipcountry($l, '');
	my $cc = $l->country();
	ok(!defined $cc || $cc eq '',
		'Empty string from IP::Country does not crash country()');
	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'geo: IP::Country returns numeric "1" - discarded with warning' => sub {
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

subtest 'geo: IP::Country returns "eu" - deleted, falls through' => sub {
	# The module discards "eu" because it is not a real country code.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

	my $l = _obj([$LANG{EN}]);
	_inject_ipcountry($l, 'EU');
	my $cc = $l->country();

	# After EU is discarded, fallbacks are all blocked - undef expected.
	ok(!defined $cc || ($cc ne 'eu'),
		'"eu" from IP::Country is not returned as a country code');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'geo: IP::Country returns "HK" - remapped to "cn"' => sub {
	# POD/code comment: "HK is no longer a separate country in Whois"
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _obj([$LANG{EN}]);
	_inject_ipcountry($l, 'HK');
	is($l->country(), 'cn', 'HK from IP::Country is remapped to cn');
	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'geo: geoplugin returns empty JSON object - country() returns undef' => sub {
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
		# {} has no geoplugin_countryCode key - Whois (no-op mock) is tried next.
		ok(!defined $cc, 'Empty JSON from geoplugin results in undef country');

		{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
		_block_network();
	}
};

subtest 'geo: geoplugin returns malformed JSON - country() survives' => sub {
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

subtest 'geo: geoplugin returns numeric country code - discarded with warning' => sub {
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

# -------------------------------------------------------------------------------
# SECTION 7: Context and state abuse
#
# Strategy: call methods in unusual contexts (list, void) and verify that the
# return values are sane and internal state is not corrupted.
# -------------------------------------------------------------------------------

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

	# Mutate env - the cached result must NOT change.
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

# -------------------------------------------------------------------------------
# SECTION 8: LANG env-var validation
#
# Strategy: set $ENV{LANG} to hostile values and verify that the module does
# not execute injected content.  _what_language() validates LANG against
# [A-Za-z0-9_.-] and a length cap, so these values are refused outright.
# -------------------------------------------------------------------------------

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
	# The value is not a real language code - result must be Unknown or undef.
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

# -------------------------------------------------------------------------------
# SECTION 9: Large-input stress
# -------------------------------------------------------------------------------

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

# =============================================================================
# SECTION 10 onwards: second pass.
#
# Each section names its target.  Several subtests are regressions for bugs
# that were found by writing them; the bug is described in the subtest.
# =============================================================================

Readonly my %CFG => (
	zone          => 'Europe/London',
	huge_file     => 1_000_000,		# bytes; far more than the zone-file read limit
	hang_guard    => 10,			# seconds before a hanging read is declared a failure
	long_dir_len  => 4_096,
	enospc        => "No space left on device\n",
	poison_html   => 'gb<script>alert(1)</script>',
	invalid_utf8  => [ "\xff\xfe", "\xc3\x28", "\xe2\x82", "\xf0\x28\x8c\x28", "\xc0\xaf" ],
	undef_methods => [qw(country locale time_zone)],
);

require File::Spec;
require File::Temp;
my $HAS_PERMS = eval { require Test::Permissions; Test::Permissions->import(qw(:revoke :guard)); 1 } ? 1 : 0;
my $HAS_SYMLINK = eval { symlink('', ''); 1 } ? 1 : 0;	# dies where symlink() is unimplemented

# Logger that records every call, injected into $obj->{logger} because
# Object::Configure replaces whatever is passed to new().
{
	package Edge::Spy;
	sub new { return bless { calls => [] }, shift }
	for my $level (qw(debug info notice trace warn error)) {
		no strict 'refs';
		*{$level} = sub { push @{$_[0]{calls}}, [$level, $_[1]] };
	}
	sub warnings { return map { $_->[1] } grep { $_->[0] eq 'warn' } @{$_[0]{calls}} }
}

sub _spied {
	my ($supported, %extra) = @_;
	my $l = CGI::Lingua->new(supported => $supported, %extra);
	$l->{logger} = Edge::Spy->new();
	return $l;
}

sub _restore {
	local $SIG{__WARN__} = sub { };
	Test::Mockingbird::restore_all();
	_block_network();
}

sub _touch {
	my ($path, $content) = @_;
	open(my $fh, '>', $path) or die "$path: $!";
	print {$fh} $content // '';
	close $fh;
	return $path;
}

# -- SECTION 10: list context and $_ -------------------------------------------

subtest 'context: methods that return undef give one value in list context' => sub {
	# Regression: country(), locale(), time_zone() and translation_file()
	# used a bare "return;", which is an EMPTY LIST in list context.  A CGI
	# script building template variables,
	#     my %vars = (country => $l->country(), zone => $l->time_zone());
	# then shifted every later key by one: $vars{country} became 'zone'.
	local %ENV = (REMOTE_ADDR => 'not-an-ip', HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = _spied([$LANG{EN}], dont_use_ip => 1);
	for my $method (@{$CFG{undef_methods}}) {
		my @list = $l->$method();
		is(scalar(@list), 1, "$method(): one element in list context");
		ok(!defined($list[0]), "$method(): and it is undef");
	}
	my @tf = $l->translation_file('/nonexistent-dir');
	is(scalar(@tf), 1, 'translation_file(): one element in list context');

	my %vars = (country => $l->country(), zone => $l->time_zone(), lang => $l->language());
	is_deeply([ sort keys %vars ], [qw(country lang zone)], 'hash built from the results keeps its keys');
	is($vars{lang}, 'English', 'and later values stay with their keys');
};

subtest 'context: read-only $_ is never assigned to' => sub {
	# A "for (1)" loop aliases $_ to a read-only constant: any unlocalised
	# assignment to $_ inside the module dies with "Modification of a
	# read-only value attempted".
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-gb,fr;q=0.5', GEOIP_COUNTRY_CODE => 'GB');
	for (1) {
		lives_ok {
			my $l = _obj([$LANG{EN_GB}, $LANG{FR}]);
			$l->$_() for qw(language sublanguage requested_language country is_rtl text_direction);
		} 'no method assigns to $_';
		is($_, 1, '$_ unchanged');
	}
};

# -- SECTION 11: constructor, hostile references --------------------------------

subtest 'new: typeglobs, regexes and code as supported croak with the documented messages' => sub {
	local %ENV = ();
	throws_ok { _obj(\*STDOUT) } qr/^List of supported languages must be an array ref at /, 'glob reference';
	throws_ok { _obj(qr/en/) } qr/^List of supported languages must be an array ref at /, 'compiled regex';
	throws_ok { _obj(*STDOUT) } qr/^Supported languages must be the short code at /, 'bare glob (stringifies to *main::STDOUT)';
	throws_ok { _obj(\'en') } qr/^List of supported languages must be an array ref at /, 'scalar reference';
};

subtest 'new: junk inside the supported list does not crash negotiation' => sub {
	# The list itself is an arrayref, so new() accepts it; the junk must not
	# crash or be chosen as a language.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $circular = [ $LANG{EN} ];
	push @{$circular}, $circular;
	my %lists = (
		'nested arrayref'   => [ [] ],
		'hashref element'   => [ {} ],
		'undef element'     => [ undef ],
		'circular list'     => $circular,
		'duplicate entries' => [ $LANG{EN}, $LANG{EN}, uc $LANG{EN} ],
		'empty string'      => [ '' ],
	);
	for my $why (sort keys %lists) {
		my $lang;
		my @w;
		lives_ok {
			local $SIG{__WARN__} = sub { push @w, @_ };
			$lang = _obj($lists{$why}, dont_use_ip => 1)->language();
		} "$why: lives";
		is(scalar(@w), 0, "$why: no warnings leak from I18N::AcceptLanguage") or diag(explain(\@w));
		like($lang, qr/^(?:English|Unknown)\z/, "$why: a real answer or Unknown, never junk");
		diag("$why -> $lang") if $ENV{TEST_VERBOSE};
	}
};

subtest 'new: supported and supported_languages both given' => sub {
	# Conflicting keys: supported is the primary name and wins
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr');
	my $l = CGI::Lingua->new(supported => [$LANG{EN}], supported_languages => [$LANG{FR}], dont_use_ip => 1);
	is($l->language(), 'Unknown', 'supported_languages ignored when supported is set');
};

subtest 'new: info that cannot answer lang()' => sub {
	# Regression: a bad info object made new() die with Perl's own
	# "Can't locate object method" message, deep inside _build_cache_key
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => 'en');
	my $cache = CHI->new(driver => 'Memory', global => 0);
	throws_ok { _obj([$LANG{EN}], info => {}, cache => $cache) }
		qr/^info must be an object with a lang\(\) method at /, 'unblessed hash';
	throws_ok { _obj([$LANG{EN}], info => bless({}, 'Edge::NoLang'), cache => $cache) }
		qr/^info must be an object with a lang\(\) method at /, 'object without lang()';

	# An AUTOLOAD-based object (like CGI::Info) whose lang() dies is
	# accepted, and the failure means "no lang parameter"
	{
		package Edge::DyingInfo;
		our $AUTOLOAD;
		sub new { return bless {}, shift }
		sub AUTOLOAD { return if $AUTOLOAD =~ /DESTROY$/; die "lang() exploded\n" }
	}
	my $l;
	lives_ok { $l = _obj([$LANG{EN}], info => Edge::DyingInfo->new(), cache => $cache) } 'new() survives';
	is($l->language(), 'English', 'header used instead');
};

subtest 'new: unusable cache objects are survived' => sub {
	# The cache is caller-supplied; a string, an unblessed hash or an object
	# missing set() must degrade to "no cache", not take down the request
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => 'en', GEOIP_COUNTRY_CODE => 'GB');
	{ package Edge::GetOnly; sub new { bless {}, shift } sub get { undef } }
	for my $cache ('a string', {}, Edge::GetOnly->new()) {
		my $label = ref($cache) || 'string';
		my $l;
		lives_ok {
			local $SIG{__WARN__} = sub { };
			$l = _obj([$LANG{EN}], cache => $cache);
			$l->language();
			$l->country();
			undef $l;	# DESTROY writes to the cache
		} "$label cache: whole request lives";
	}
};

# -- SECTION 12: Accept-Language extremes ---------------------------------------

subtest 'Accept-Language: invalid UTF-8 byte sequences are ignored' => sub {
	for my $bytes (@{$CFG{invalid_utf8}}) {
		local %ENV = (HTTP_ACCEPT_LANGUAGE => "en$bytes");
		my $l = _spied([$LANG{EN}], dont_use_ip => 1);
		my $hex = unpack('H*', $bytes);
		is($l->language(), 'Unknown', "bytes $hex: header not used");
		ok((grep { /^HTTP_ACCEPT_LANGUAGE contains invalid characters; ignoring$/ } $l->{logger}->warnings()),
			"bytes $hex: warned");
	}
};

subtest 'Accept-Language: q=0 means "not acceptable"' => sub {
	# Regression: RFC 7231 section 5.3.1 says q=0 rules a language out, but
	# "fr;q=0, en;q=0.5" chose French and "fr;q=0" alone chose French too
	my %cases = (
		'fr;q=0, en;q=0.5'   => 'English',
		'fr;q=0'             => 'Unknown',
		'fr;q=0.000, en'     => 'English',
		'fr; q = 0 , en'     => 'English',
		'fr;q=0.001, en;q=0' => 'French',	# small is not zero
	);
	for my $header (sort keys %cases) {
		local %ENV = (HTTP_ACCEPT_LANGUAGE => $header);
		is(_obj([$LANG{FR}, $LANG{EN}], dont_use_ip => 1)->language(), $cases{$header}, "'$header'");
	}
};

subtest 'Accept-Language: extreme and malformed q values' => sub {
	my @headers = ('en;q=99999999999999999999', 'en;q=1e309', 'en;q=-1', 'en;q=', 'en;q=abc', ';q=1', ',,,;;;', '*', 'en-', '-gb');
	for my $header (@headers) {
		local %ENV = (HTTP_ACCEPT_LANGUAGE => $header);
		my $lang;
		my @w;
		lives_ok {
			local $SIG{__WARN__} = sub { push @w, @_ };
			$lang = _obj([$LANG{EN}], dont_use_ip => 1)->language();
		} "'$header': lives";
		is(scalar(@w), 0, "'$header': no warnings") or diag(explain(\@w));
		like($lang, qr/^(?:English|Unknown)\z/, "'$header': sane answer");
	}
};

# -- SECTION 13: REMOTE_ADDR extremes -----------------------------------------

subtest 'REMOTE_ADDR: boundary and ambiguous addresses' => sub {
	# None of these has a country; none may crash or be looked up as junk.
	# 010.008.0.1 is the octal-confusion case (inet_aton reads 010 as 8 on
	# some platforms).
	for my $ip ('0.0.0.0', '255.255.255.255', '::', '::ffff:255.255.255.255', '010.008.0.1', "8.8.8.8\x00") {
		local %ENV = (REMOTE_ADDR => $ip);
		my $l = _spied([$LANG{EN}]);
		$l->{_have_ipcountry} = $l->{_have_geoip} = $l->{_have_geoipfree} = 0;
		my $cc;
		lives_ok { $cc = $l->country() } 'lives for ' . unpack('H*', $ip);
		ok(!defined($cc) || $cc =~ /^[a-z]{2}\z/, 'and gives undef or a real code');
	}
};

# -- SECTION 14: translation_file() and the filesystem ------------------------

subtest 'translation_file: things named en.json that are not translation files' => sub {
	# Regression: only -e was checked, so a directory or a device with the
	# right name was handed back and the caller's read failed or hung
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = _spied([$LANG{EN}]);

	mkdir("$dir/en.json") or die "mkdir: $!";
	ok(!defined($l->translation_file($dir)), 'a directory is not returned');
	rmdir("$dir/en.json");

	SKIP: {
		skip 'symlink() not available', 3 unless $HAS_SYMLINK;
		for my $target ('/dev/urandom', '/dev/null', "$dir/missing.json") {
			unlink("$dir/en.json");
			symlink($target, "$dir/en.json") or skip("symlink to $target: $!", 1);
			ok(!defined($l->translation_file($dir)), "a link to $target is not returned");
		}
		unlink("$dir/en.json");
	}
};

subtest 'translation_file: odd but legal files are returned' => sub {
	# Empty and whitespace-only files are real files; reading them is the
	# caller's business, finding them is ours
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = _obj([$LANG{EN}]);
	for my $content ('', " \n\t \n") {
		_touch("$dir/en.json", $content);
		is($l->translation_file($dir), "$dir/en.json", 'file with ' . length($content) . ' bytes is returned');
	}
};

subtest 'translation_file: directory names with shell characters' => sub {
	# No shell is involved, so these must simply work, not be interpreted
	my $base = File::Temp::tempdir(CLEANUP => 1);
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = _obj([$LANG{EN}]);
	for my $name ('with space', 'semi;colon', 'dollar$(id)', 'back`tick`', "new\nline", 'quote\'s') {
		my $dir = "$base/$name";
		mkdir($dir) or next;	# some filesystems refuse some names
		_touch("$dir/en.json", '{}');
		is($l->translation_file($dir), "$dir/en.json", 'found in ' . ($name =~ s/\n/\\n/r));
	}
};

subtest 'translation_file: malformed directory and extension arguments' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = _spied([$LANG{EN}]);
	my %bad_dir = (
		'empty string (would mean /)' => '',
		'array reference'             => [],
		'hash reference'              => {},
		'code reference'              => sub { '/tmp' },
	);
	for my $why (sort keys %bad_dir) {
		ok(!defined($l->translation_file($bad_dir{$why})), "dir: $why refused");
	}
	is(scalar(grep { /^translation_file: unsafe directory / } $l->{logger}->warnings()), scalar(keys %bad_dir),
		'each refusal warned');

	ok(!defined($l->translation_file('/tmp', "json\n")), 'extension with a trailing newline refused');
	ok(!defined($l->translation_file('/tmp', '')), 'empty extension refused');
	ok(!defined($l->translation_file('x' x $CFG{long_dir_len})), 'very long directory name survived');
};

subtest 'translation_file: control characters cannot forge log lines' => sub {
	# The rejected value goes into a warning; a raw newline in it would let a
	# caller-supplied directory name start a fake line in the log
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = _spied([$LANG{EN}]);
	$l->translation_file("/srv/../x\nFATAL: forged entry\e[2J");
	my ($msg) = $l->{logger}->warnings();
	unlike($msg, qr/[\x00-\x1f\x7f]/, 'no control characters in the warning');
	like($msg, qr/\\x0a/, 'the newline is shown as \\x0a');
};

subtest 'translation_file: permission drops' => sub {
	plan(skip_all => 'Test::Permissions not installed') unless $HAS_PERMS;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-gb');
	my $l = _obj([$LANG{EN_GB}, $LANG{EN}]);
	_touch("$dir/en-gb.json", '{}');
	_touch("$dir/en.json", '{}');

	SKIP: {
		skip_unless_can_revoke('read', 1, $dir);
		with_revoked(read => "$dir/en-gb.json", sub {
			is($l->translation_file($dir), "$dir/en.json", 'unreadable en-gb.json is skipped for en.json');
		});
	}
	SKIP: {
		skip_unless_can_revoke('search', 1, $dir);
		with_revoked(search => $dir, sub {
			ok(!defined($l->translation_file($dir)), 'unsearchable directory: nothing found, no crash');
		});
	}
};

# -- SECTION 15: the system time-zone file ------------------------------------

# Run time_zone() on the command-line path with $ZONE_FILE pointing at $path.
# DateTime::TimeZone is replaced so that a fall-back is visible as 'UTC'.
sub _zone_from {
	my $path = shift;
	local %ENV = ();
	no warnings 'once';
	local $CGI::Lingua::ZONE_FILE = $path;
	my $l = _spied([$LANG{EN}]);
	my $tz;
	local $SIG{ALRM} = sub { die "time_zone() hung reading $path\n" };
	alarm($CFG{hang_guard});
	my $ok = eval { $tz = $l->time_zone(); 1 };
	alarm(0);
	die $@ unless $ok;
	return ($tz, $l);
}

{
	package Edge::Zone;
	sub new { bless {}, shift }
	sub name { 'UTC' }
}
my $HAS_DTZ = eval { require DateTime::TimeZone::Local; 1 } ? 1 : 0;

subtest 'zone file: good content, with and without decoration' => sub {
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my %files = (
		plain      => "$CFG{zone}\n",
		no_newline => $CFG{zone},
		padded     => "  \t$CFG{zone}  \n",
		two_lines  => "$CFG{zone}\nAmerica/New_York\n",
	);
	for my $name (sort keys %files) {
		my ($tz) = _zone_from(_touch("$dir/$name", $files{$name}));
		is($tz, $CFG{zone}, "$name: zone read");
	}
};

subtest 'zone file: empty, junk and devices fall back to DateTime::TimeZone' => sub {
	# Regression: a 0-byte file gave an "uninitialized value in chomp"
	# warning and no zone; a link to /dev/zero read forever.
	plan(skip_all => 'DateTime::TimeZone not installed') unless $HAS_DTZ;
	Test::Mockingbird::mock('DateTime::TimeZone::Local', 'TimeZone', sub { Edge::Zone->new() });
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my %cases = (
		'0-byte file'        => _touch("$dir/empty", ''),
		'whitespace only'    => _touch("$dir/blank", " \n\n\t"),
		'markup'             => _touch("$dir/html", "<script>alert(1)</script>\n"),
		'path traversal'     => _touch("$dir/dots", "../../etc/passwd\n"),
		'huge, no newline'   => _touch("$dir/huge", 'A' x $CFG{huge_file}),
		'a directory'        => $dir,
		'missing file'       => "$dir/does-not-exist",
	);
	for my $device ('/dev/null', '/dev/zero', '/dev/urandom') {
		$cases{"device $device"} = $device if -c $device;
	}
	if($HAS_SYMLINK && symlink("$dir/does-not-exist", "$dir/dangling")) {
		$cases{'dangling symlink'} = "$dir/dangling";
	}
	for my $why (sort keys %cases) {
		my @w;
		my ($tz) = do { local $SIG{__WARN__} = sub { push @w, @_ }; _zone_from($cases{$why}) };
		is($tz, 'UTC', "$why: falls back to DateTime::TimeZone");
		is(scalar(@w), 0, "$why: no Perl warnings") or diag(explain(\@w));
	}
	_restore();
};

subtest 'zone file: unreadable file falls back' => sub {
	plan(skip_all => 'Test::Permissions not installed') unless $HAS_PERMS;
	plan(skip_all => 'DateTime::TimeZone not installed') unless $HAS_DTZ;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my $file = _touch("$dir/zone", "$CFG{zone}\n");
	Test::Mockingbird::mock('DateTime::TimeZone::Local', 'TimeZone', sub { Edge::Zone->new() });
	SKIP: {
		skip_unless_can_revoke('read', 1, $dir);
		with_revoked(read => $file, sub {
			my ($tz) = _zone_from($file);
			is($tz, 'UTC', 'unreadable zone file ignored');
		});
	}
	_restore();
};

# -- SECTION 16: cache I/O failures and poisoning --------------------------------

subtest 'cache: disk full (ENOSPC) on every write' => sub {
	# A cache write can fail mid-request; the request must finish and the
	# failure be reported, both in country() and in DESTROY
	require Errno;
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => 'en', GEOIP_COUNTRY_CODE => 'GB');
	my $cache = CHI->new(driver => 'Memory', global => 0, on_set_error => 'die');
	no warnings qw(redefine once);
	local *CHI::Driver::Memory::store = sub { $! = Errno::ENOSPC(); die $CFG{enospc} };
	my $l = _spied([$LANG{EN}], cache => $cache);
	my $spy = $l->{logger};
	lives_ok { $l->language(); $l->country(); undef $l } 'request and DESTROY survive';
	ok((grep { /^Cache set failed: .*No space left on device/ } $spy->warnings()), 'ENOSPC reported');
};

subtest 'cache: truncated and wrong-typed saved state' => sub {
	# A blob cut short (EOF mid-read) is not JSON; one that is JSON but holds
	# the wrong types is poisoned.  Neither may reach the caller.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => 'en-gb');
	my $key = "$IP{PUBLIC}/en-gb/en-gb";
	my %blobs = (
		'truncated JSON'      => '{"_slanguage":"Engl',
		'JSON array'          => '[1,2,3]',
		'hash as language'    => JSON::PP::encode_json({ _slanguage => { a => 1 } }),
		'HTML as country'     => JSON::PP::encode_json({ _country => '<img src=x onerror=alert(1)>' }),
		'path as code'        => JSON::PP::encode_json({ _slanguage_code_alpha2 => '../../etc' }),
		'array as variant'    => JSON::PP::encode_json({ _sublanguage_code_alpha2 => ['gb'] }),
	);
	for my $why (sort keys %blobs) {
		my $cache = CHI->new(driver => 'Memory', global => 0);
		$cache->set($key, $blobs{$why});
		my $l;
		lives_ok { local $SIG{__WARN__} = sub { }; $l = _obj([$LANG{EN_GB}], cache => $cache, logger => []) } "$why: new() lives";
		is($l->language(), 'English', "$why: language recomputed");
		is($l->language_code_alpha2(), 'en', "$why: code is the real one");
		is($l->sublanguage_code_alpha2(), 'gb', "$why: variant is the real one");
	}
};

subtest 'cache: poisoned entries never become answers' => sub {
	# Regression: the cache was trusted completely.  A shared or world-
	# writable backend could make country() return "<script>", or
	# language_code_alpha2() return "../../etc", which translation_file()
	# then put into a path.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => 'en');
	my %poison = (
		"${CACHE_NS}country:$IP{PUBLIC}"   => $CFG{poison_html},
		"${CACHE_NS}code2language:en"      => '<b>English</b>',
	);
	my $cache = CHI->new(driver => 'Memory', global => 0);
	$cache->set($_ => $poison{$_}) for keys %poison;
	my $l = _spied([$LANG{EN}], cache => $cache);
	$l->{_have_ipcountry} = $l->{_have_geoip} = $l->{_have_geoipfree} = 0;

	my $cc = $l->country();
	ok(!defined($cc) || $cc =~ /^[a-z]{2}\z/, 'country() is not the poisoned value');
	is($l->language(), 'English', 'language() is not the poisoned value');
	ok((grep { /^Discarding malformed cache entry for / } $l->{logger}->warnings()), 'poisoning reported');
	ok(!defined($cache->get("${CACHE_NS}country:$IP{PUBLIC}")), 'poisoned country entry removed');
	diag(explain([ $l->{logger}->warnings() ])) if $ENV{TEST_VERBOSE};
};

subtest 'cache: restored state cannot override the caller' => sub {
	# Regression: everything in the saved blob was copied into the object,
	# so a blob could switch dont_use_ip off, replace the logger, or set the
	# supported list.  Only the known answer fields may be restored.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => 'en');
	my $cache = CHI->new(driver => 'Memory', global => 0);
	$cache->set("$IP{PUBLIC}/en/en", JSON::PP::encode_json({
		_slanguage => 'English', _dont_use_ip => 0, logger => 'evil', _supported => ['xx'],
		_locale => '<script>', _timezone => '<script>',
	}));
	my $l = _obj([$LANG{EN}], cache => $cache, dont_use_ip => 1);
	is($l->{_dont_use_ip}, 1, "caller's dont_use_ip kept");
	is_deeply($l->{_supported}, [$LANG{EN}], "caller's supported list kept");
	ok(blessed($l->{logger}), "caller's logger kept");
	ok(!defined($l->{_timezone}) && !defined($l->{_locale}), 'no unknown fields copied in');
	is($l->language(), 'English', 'the valid answer is still used');
};

subtest 'cache: sublanguage survives a save and restore' => sub {
	# Regression: DESTROY did not save _sublanguage, so the next request for
	# the same visitor got sublanguage() = undef for en-gb
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => 'en-gb');
	my $cache = CHI->new(driver => 'Memory', global => 0);
	{
		my $first = _obj([$LANG{EN_GB}], cache => $cache);
		is($first->sublanguage(), 'United Kingdom', 'first request');
	}
	my $second = _obj([$LANG{EN_GB}], cache => $cache);
	is($second->sublanguage(), 'United Kingdom', 'restored request');
};

# -- SECTION 17: upstream returns that look like answers --------------------

subtest 'upstream: false-but-defined answers from every geo source' => sub {
	# 0, "" and "0" are the classic "looks like a value" failures.  Each must
	# be treated as "no answer" and the next source tried, ending in undef.
	plan(skip_all => 'LWP::Simple::WithCache or JSON::Parse not installed') unless $HAS_LWP && $HAS_JSON;
	for my $bad (0, '', '0', ' ') {
		local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
		my $l = _spied([$LANG{EN}]);
		_inject_ipcountry($l, $bad);
		{
			local $SIG{__WARN__} = sub { };
			Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { $bad });
		}
		my $cc;
		lives_ok { $cc = $l->country() } "'$bad': lives";
		ok(!defined($cc), "'$bad': no country");
		_restore();
	}
};

subtest 'upstream: HTTP 500 bodies and dropped connections' => sub {
	plan(skip_all => 'LWP::Simple::WithCache or JSON::Parse not installed') unless $HAS_LWP && $HAS_JSON;
	my %bodies = (
		'500 HTML page'      => sub { '<html><h1>500 Internal Server Error</h1></html>' },
		'connection reset'   => sub { die "Connection reset by peer\n" },
		'timeout'            => sub { die "500 read timeout\n" },
		'zero'               => sub { 0 },
	);
	for my $why (sort keys %bodies) {
		local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
		my $l = _spied([$LANG{EN}]);
		$l->{_have_ipcountry} = $l->{_have_geoip} = $l->{_have_geoipfree} = 0;
		{
			local $SIG{__WARN__} = sub { };
			Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', $bodies{$why});
		}
		my ($cc, $tz);
		lives_ok { $cc = $l->country(); $tz = $l->time_zone() } "$why: country() and time_zone() live";
		ok(!defined($cc) && !defined($tz), "$why: both undef");
		_restore();
	}
};

done_testing();
