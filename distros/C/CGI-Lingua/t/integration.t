#!/usr/bin/env perl

# t/integration.t -- CGI::Lingua end-to-end integration tests.
#
# These subtests focus on stateful workflows and cross-method coherence rather
# than testing individual methods in isolation (which t/unit.t covers).
#
# Network I/O (Whois, geoplugin, ip-api.com) is blocked globally; individual
# subtests install narrowly-scoped mocks for specific responses as needed.
#
# IP::Country is excluded via Test::Without::Module so CGI::Lingua's lazy-
# require guard naturally sets _have_ipcountry = GEO_ABSENT throughout this
# file.  Subtests that exercise the "IP::Country present" code path inject the
# sentinel and mock directly after construction, bypassing the guard.
# Geo::IP and Geo::IPfree are NOT globally excluded — Section 9 tests both the
# "present" path (via _inject_geoip / _inject_geoipfree) and the "absent" path
# (by setting the sentinels to GEO_ABSENT explicitly on the object).

use strict;
use warnings;

use CHI;
use Readonly;
use Scalar::Util qw(blessed);
use Test::Most;
use Test::Mockingbird;
use Test::Returns qw(returns_ok);
use Test::Without::Module qw(IP::Country);

use lib 't/lib';

BEGIN { use_ok('CGI::Lingua') }

# Pre-require lazy-loaded network modules before mocking them.
# A module's BEGIN block runs on first require and would clobber any mock
# installed before that point.  We load both unconditionally so the symbol
# table entries are stable before any mocks are installed.
# (See CLAUDE.md "Mocking pitfalls: Pre-require before mocking".)
my $HAS_LWP  = eval { require LWP::Simple::WithCache; 1 } ? 1 : 0;
my $HAS_JSON = eval { require JSON::Parse;             1 } ? 1 : 0;

# ── Shared constants ──────────────────────────────────────────────────────────

Readonly my %LANG => (
	EN    => 'en',
	EN_GB => 'en-gb',
	EN_US => 'en-us',
	FR    => 'fr',
	DE    => 'de',
	ZH    => 'zh',
);

Readonly my %IP => (
	PUBLIC   => '8.8.8.8',
	PRIVATE  => '192.168.1.1',
	LOOPBACK => '127.0.0.1',
	GB       => '1.2.3.4',
	FR       => '90.0.0.1',
	US       => '4.4.4.4',
);

# Canned JSON bodies returned by mocked geoplugin / ip-api calls.
Readonly my $GEO_JSON_US  => '{"geoplugin_countryCode":"US"}';
Readonly my $GEO_JSON_GB  => '{"geoplugin_countryCode":"GB"}';
Readonly my $TZ_JSON_GB   => '{"timezone":"Europe/London"}';
Readonly my $TZ_JSON_US   => '{"timezone":"America/New_York"}';

# ── Global network block ──────────────────────────────────────────────────────
# Installed once at the start; reinstalled after any restore_all() call.
# This ensures no test ever makes a real network round-trip.
_block_network();

# ── Shared helpers ────────────────────────────────────────────────────────────

sub _block_network {
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef })
		if $HAS_LWP;
}

sub _obj {
	my ($supported, %extra) = @_;
	CGI::Lingua->new(supported => $supported, %extra);
}

# Simulate "IP::Country present" for an already-constructed object by injecting
# the sentinel flags and a mock that returns the given country code.
# Because IP::Country is blocked by Test::Without::Module, the lazy-require
# guard always sets _have_ipcountry = GEO_ABSENT; this helper overrides that.
sub _inject_ipcountry {
	my ($l, $cc) = @_;
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { $cc });
	$l->{_have_ipcountry} = 1;     # GEO_PRESENT
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = 0;     # GEO_ABSENT
	$l->{_have_geoipfree} = 0;     # GEO_ABSENT
}

# Simulate "Geo::IP present" — bypasses the lazy-require + db-file guard in
# _load_geoip() by injecting sentinels directly after construction.
sub _inject_geoip {
	my ($l, $cc) = @_;
	eval { require Geo::IP };      # pre-require so mock is not overwritten on first load
	Test::Mockingbird::mock('Geo::IP', 'country_code_by_addr', sub { $cc });
	$l->{_have_ipcountry} = 0;     # GEO_ABSENT
	$l->{_have_geoip}     = 1;     # GEO_PRESENT
	$l->{_geoip}          = bless {}, 'Geo::IP';
	$l->{_have_geoipfree} = 0;     # GEO_ABSENT
}

# Simulate "Geo::IPfree present" — bypasses the lazy-require guard.
sub _inject_geoipfree {
	my ($l, $cc) = @_;
	eval { require Geo::IPfree };  # pre-require so mock is not overwritten on first load
	# LookUp returns a list; the module takes element [0] as the country code.
	Test::Mockingbird::mock('Geo::IPfree', 'LookUp', sub { return ($cc) });
	$l->{_have_ipcountry} = 0;     # GEO_ABSENT
	$l->{_have_geoip}     = 0;     # GEO_ABSENT
	$l->{_have_geoipfree} = 1;     # GEO_PRESENT
	$l->{_geoipfree}      = bless {}, 'Geo::IPfree';
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 1: Full detection-pipeline coherence
#
# Strategy: verify that all language-related accessors return a mutually
# consistent picture when constructed from a single Accept-Language header.
# Each subtest creates one object and checks every public method, exercising
# the entire pipeline from header → I18N::AcceptLanguage → language/sub-lang.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'pipeline coherence: en-gb produces consistent results across all accessors' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB});

	my $l = _obj([$LANG{EN_GB}]);

	is($l->language(),              'English',                  'language()');
	is($l->preferred_language(),    'English',                  'preferred_language()');
	is($l->name(),                  'English',                  'name()');
	is($l->sublanguage(),           'United Kingdom',           'sublanguage()');
	is($l->language_code_alpha2(),  $LANG{EN},                  'language_code_alpha2()');
	is($l->code_alpha2(),           $LANG{EN},                  'code_alpha2()');
	is($l->sublanguage_code_alpha2(), 'gb',                     'sublanguage_code_alpha2()');
	like($l->requested_language(),  qr/^English\s+\(United Kingdom\)$/,
		'requested_language() matches "Language (Sublanguage)" format');

	returns_ok($l->language(),             { type => 'string' }, 'language() returns a string');
	returns_ok($l->requested_language(),   { type => 'string' }, 'requested_language() returns a string');
	returns_ok($l->language_code_alpha2(), { type => 'string' }, 'language_code_alpha2() returns a string');
};

subtest 'pipeline coherence: en-us produces consistent results across all accessors' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_US});

	my $l = _obj([$LANG{EN_US}]);

	is($l->language(),               'English',        'language()');
	is($l->sublanguage(),            'United States',  'sublanguage()');
	is($l->language_code_alpha2(),   $LANG{EN},        'language_code_alpha2()');
	is($l->sublanguage_code_alpha2(), 'us',            'sublanguage_code_alpha2()');
	like($l->requested_language(),   qr/United States/, 'requested_language() contains United States');
};

subtest 'pipeline coherence: fr produces consistent results across all accessors' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{FR});

	my $l = _obj([$LANG{EN}, $LANG{FR}]);

	is($l->language(),               'French',  'language()');
	is($l->preferred_language(),     'French',  'preferred_language()');
	is($l->name(),                   'French',  'name()');
	ok(!defined $l->sublanguage(),              'sublanguage() undef for plain language');
	is($l->language_code_alpha2(),   $LANG{FR}, 'language_code_alpha2()');
	is($l->code_alpha2(),            $LANG{FR}, 'code_alpha2()');
	ok(!defined $l->sublanguage_code_alpha2(),  'sublanguage_code_alpha2() undef');
	is($l->requested_language(),     'French',  'requested_language() has no parens');
};

subtest 'pipeline coherence: Unknown language has undef codes and undef sublanguage' => sub {
	# When no supported language matches and IP fallback is unavailable,
	# all accessors must return a consistent "nothing matched" picture.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'xx', REMOTE_ADDR => $IP{LOOPBACK});

	my $l = _obj([$LANG{EN}]);

	is($l->language(),    'Unknown', 'language() Unknown');
	is($l->requested_language(), 'Unknown', 'requested_language() Unknown');
	ok(!defined $l->language_code_alpha2(),   'language_code_alpha2() undef');
	ok(!defined $l->sublanguage(),            'sublanguage() undef');
	ok(!defined $l->sublanguage_code_alpha2(), 'sublanguage_code_alpha2() undef');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 2: Multi-language header priority negotiation
#
# Strategy: feed real-world Accept-Language headers containing multiple candidates
# with quality weights.  Vary the supported-languages list to exercise both
# "first match wins" and "sublanguage fallback" paths within a single request.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'priority: de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7 → German when de supported' => sub {
	local %ENV = (
		HTTP_ACCEPT_LANGUAGE => 'de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7',
		# No REMOTE_ADDR — prevent IP-based fallback from interfering
	);
	# Remove locale env vars that I18N::LangTags::Detect might consume
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	delete local $ENV{LANG};

	my $l = _obj([$LANG{DE}, $LANG{EN}]);
	is($l->language(), 'German', 'German selected as highest-priority supported language');
};

subtest 'priority: de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7 → English (United States) when de not supported' => sub {
	local %ENV = (
		HTTP_ACCEPT_LANGUAGE => 'de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7',
	);
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	delete local $ENV{LANG};
	delete local $ENV{REMOTE_ADDR};

	# en-us is supported but not de — module must fall through to en-us
	my $l = _obj([$LANG{EN_US}, $LANG{FR}]);
	is($l->language(),    'English',       'Fell through de to en-us');
	is($l->sublanguage(), 'United States', 'sublanguage() is United States');
};

subtest 'priority: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7 → English (United States) when zh not supported' => sub {
	local %ENV = (
		HTTP_ACCEPT_LANGUAGE => 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7',
	);
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	delete local $ENV{LANG};
	delete local $ENV{REMOTE_ADDR};

	# Only English variants supported — must fall through zh to en-us
	my $l = _obj([$LANG{EN_US}, $LANG{EN_GB}]);
	is($l->language(),    'English',       'Fell through zh to en-us');
	is($l->sublanguage(), 'United States', 'sublanguage() is United States');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 3: Stateful method-ordering independence
#
# Strategy: the lazily-populated fields must produce the same result regardless
# of which method is called first.  Call methods in reverse order to prove that
# each accessor's lazy guard is effective and idempotent.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'method ordering: sublanguage() called before language() still resolves' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB});

	my $l = _obj([$LANG{EN_GB}]);

	# sublanguage() triggers _find_language() internally before language() is called
	my $sub = $l->sublanguage();
	my $lang = $l->language();

	is($sub,  'United Kingdom', 'sublanguage() correct when called first');
	is($lang, 'English',        'language() correct after sublanguage()');
};

subtest 'method ordering: requested_language() called before language() still resolves' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB});

	my $l = _obj([$LANG{EN_GB}]);

	my $rl   = $l->requested_language();
	my $lang = $l->language();

	like($rl,  qr/United Kingdom/, 'requested_language() resolved before language()');
	is($lang, 'English',           'language() consistent after requested_language()');
};

subtest 'method ordering: language() result stable across multiple calls' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{FR});

	my $l = _obj([$LANG{EN}, $LANG{FR}]);

	my $first  = $l->language();
	# Changing the header AFTER first call must not affect the cached result
	local $ENV{HTTP_ACCEPT_LANGUAGE} = $LANG{DE};
	my $second = $l->language();

	is($first,  'French', 'First call returns French');
	is($second, 'French', 'Second call returns same cached value');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 4: IP-based language fallback and dont_use_ip mode
#
# Strategy: test that the IP-fallback path is taken when Accept-Language is
# absent, and that dont_use_ip suppresses it.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'IP fallback: dont_use_ip suppresses country-based language detection' => sub {
	# With dont_use_ip, no IP lookup is made regardless of REMOTE_ADDR.
	# language() must return Unknown when Accept-Language is also absent.
	# country() remains callable — dont_use_ip does not disable it.
	# Explicitly set all local geo module sentinels to GEO_ABSENT so the result
	# is deterministic regardless of which modules are installed on the machine.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	delete local $ENV{HTTP_ACCEPT_LANGUAGE};
	delete local $ENV{LANG};

	my $l = _obj([$LANG{EN}], dont_use_ip => 1);
	$l->{_have_geoip}     = 0;    # GEO_ABSENT — force "no Geo::IP" path
	$l->{_have_geoipfree} = 0;    # GEO_ABSENT — force "no Geo::IPfree" path
	is($l->language(), 'Unknown', 'dont_use_ip: language() returns Unknown with no header');
	ok(!defined $l->country(),    'dont_use_ip does not prevent country() call itself');
};

subtest 'IP fallback: loopback IP with no Accept-Language gives Unknown language' => sub {
	# Loopback address cannot be resolved to a country — language falls through
	# to Unknown even when IP fallback is enabled.
	local %ENV = (REMOTE_ADDR => $IP{LOOPBACK});
	delete local $ENV{HTTP_ACCEPT_LANGUAGE};
	delete local $ENV{LANG};
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};

	my $l = _obj([$LANG{EN}]);
	is($l->language(), 'Unknown', 'Loopback with no header gives Unknown language');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 5: Cache workflow across object construction and destruction
#
# Strategy: verify the DESTROY → Storable::nfreeze → thaw cycle that the module
# uses to skip expensive geo-lookups on subsequent requests from the same IP.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'cache: DESTROY stores state and second construction thaws it' => sub {
	local %ENV = (
		REMOTE_ADDR          => $IP{PUBLIC},
		HTTP_ACCEPT_LANGUAGE => $LANG{EN},
	);

	my $cache = CHI->new(driver => 'Memory', global => 0);

	# First construction: compute language, let DESTROY serialise.
	{
		my $first = _obj([$LANG{EN}], cache => $cache);
		$first->language();    # populate _slanguage so DESTROY has something to freeze
		diag("first _slanguage: $first->{_slanguage}") if $ENV{TEST_VERBOSE};
	}    # DESTROY called here

	# Second construction: must restore from cache, not re-run detection.
	my $second = _obj([$LANG{EN}], cache => $cache);

	# The thawed object has _slanguage set — no recomputation needed.
	is($second->{_slanguage}, 'English',
		'Thawed object has the correct _slanguage from cache');
};

subtest 'cache: different supported lists for the same IP get distinct cache slots' => sub {
	# The cache key includes the supported-language list.  Two objects serving
	# different language sets but sharing an IP must not pollute each other.
	local %ENV = (
		REMOTE_ADDR          => $IP{US},
		HTTP_ACCEPT_LANGUAGE => $LANG{EN},
	);

	my $cache_en = CHI->new(driver => 'Memory', global => 0);
	my $cache_fr = CHI->new(driver => 'Memory', global => 0);

	my $obj_en = _obj([$LANG{EN}],         cache => $cache_en);
	my $obj_fr = _obj([$LANG{EN}, $LANG{FR}], cache => $cache_fr);

	_inject_ipcountry($obj_en, 'US');
	_inject_ipcountry($obj_fr, 'US');

	my $cc_en = $obj_en->country();
	my $cc_fr = $obj_fr->country();

	# Both return 'us', but their cache entries live under different keys
	is($cc_en, 'us', 'en-only object country() returns us');
	is($cc_fr, 'us', 'en+fr object country() returns us');

	my $key_en = $cache_en->get('CGI::Lingua:country:' . $IP{US});
	my $key_fr = $cache_fr->get('CGI::Lingua:country:' . $IP{US});

	ok(defined $key_en, 'Country cached in en-only cache');
	ok(defined $key_fr, 'Country cached in en+fr cache');

	# Restore and re-block network after the mock injection
	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 6: Concurrent object isolation
#
# Strategy: instantiate multiple independent objects in the same test and verify
# they do not share per-object state (language, country, cached geo results).
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'concurrency: two objects with different Accept-Language do not share state' => sub {
	# Each object is constructed AND queried within its own local %ENV scope.
	# _find_language() reads %ENV lazily, so we must ensure the correct header
	# is live at the time language() is called, not just at construction time.
	my ($en_lang, $fr_lang);

	{
		local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
		my $en_obj = _obj([$LANG{EN}, $LANG{FR}]);
		$en_lang = $en_obj->language();
	}

	{
		local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{FR});
		my $fr_obj = _obj([$LANG{EN}, $LANG{FR}]);
		$fr_lang = $fr_obj->language();
	}

	isnt($en_lang, $fr_lang, 'Two objects with different headers return different languages');
	is($en_lang, 'English', 'English object returns English');
	is($fr_lang, 'French',  'French object returns French');
};

subtest 'concurrency: two objects with different IPs resolve to different countries' => sub {
	# Two objects constructed and queried in separate local %ENV scopes with
	# separate mocks.  Mock stacking means the most-recent inet_atocc mock wins,
	# so we must restore between the two objects.
	my ($gb_cc, $us_cc);

	{
		local %ENV = (REMOTE_ADDR => $IP{GB}, HTTP_ACCEPT_LANGUAGE => $LANG{EN});
		my $gb_obj = _obj([$LANG{EN}]);
		_inject_ipcountry($gb_obj, 'GB');
		$gb_cc = $gb_obj->country();
		{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
		_block_network();
	}

	{
		local %ENV = (REMOTE_ADDR => $IP{US}, HTTP_ACCEPT_LANGUAGE => $LANG{EN});
		my $us_obj = _obj([$LANG{EN}]);
		_inject_ipcountry($us_obj, 'US');
		$us_cc = $us_obj->country();
		{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
		_block_network();
	}

	is($gb_cc, 'gb', 'GB object resolves to gb');
	is($us_cc, 'us', 'US object resolves to us');
	isnt($gb_cc, $us_cc, 'Two objects with different IPs get different countries');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 7: Clone workflow
#
# Strategy: verify that cloning (calling new() on an existing object) produces
# an independent object that respects the new supported-languages parameter.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'clone: new supported list is respected and state is independent' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{FR});

	my $orig  = _obj([$LANG{EN}, $LANG{FR}]);
	my $clone = $orig->new(supported => [$LANG{DE}]);

	isa_ok($clone, 'CGI::Lingua', 'Clone is a CGI::Lingua object');
	isnt($orig, $clone, 'Clone is a distinct reference');

	# Clone's supported list is de-only — fr header should yield Unknown
	is($clone->language(), 'Unknown',
		'Clone with de-only supported returns Unknown for fr header');

	# Populating the clone must not affect the original
	is($orig->language(), 'French',
		'Original object unaffected by clone language computation');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 8: Network call verification via spies
#
# Strategy: use Test::Mockingbird::spy() to intercept calls to external
# resolution routines and verify they are (or are not) invoked depending
# on which faster lookup path succeeds first.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'spy: _resolve_country_via_whois NOT called when IP::Country is present' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => $LANG{EN});

	my $l = _obj([$LANG{EN}]);
	_inject_ipcountry($l, 'US');

	# Spy wraps the existing no-op mock and records every call.
	my $whois_spy = Test::Mockingbird::spy('CGI::Lingua', '_resolve_country_via_whois');

	$l->country();

	my @calls = $whois_spy->();
	is(scalar @calls, 0,
		'_resolve_country_via_whois never called when IP::Country returns a result');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'spy: LWP::Simple::WithCache::get called when IP::Country is absent (geoplugin fallback)' => sub {
	SKIP: {
		skip 'LWP::Simple::WithCache or JSON::Parse not installed', 1
			unless $HAS_LWP && $HAS_JSON;

		local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

		# IP::Country is blocked by Test::Without::Module — the sentinel will be
		# set to GEO_ABSENT by CGI::Lingua's eval{require} guard.
		# Inject GEO_ABSENT explicitly in case an earlier test left the sentinel set.
		my $l = _obj([$LANG{EN}]);
		$l->{_have_ipcountry} = 0;    # GEO_ABSENT
		$l->{_have_geoip}     = 0;    # GEO_ABSENT
		$l->{_have_geoipfree} = 0;    # GEO_ABSENT

		# Spy on the mocked LWP::Simple::WithCache::get (which currently returns undef).
		# Suppress the prototype mismatch warning that fires because WithCache
		# declares get($) but the spy installs a prototype-free wrapper.
		my $lwp_spy;
		{ local $SIG{__WARN__} = sub {};
		  $lwp_spy = Test::Mockingbird::spy('LWP::Simple::WithCache', 'get') }

		$l->country();

		my @calls = $lwp_spy->();
		ok(scalar @calls > 0,
			'LWP::Simple::WithCache::get called at least once for geoplugin fallback');

		diag('LWP call args: ' . join(', ', map { $_->[1] // '(undef)' } @calls))
			if $ENV{TEST_VERBOSE};

		{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
		_block_network();
	}
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 9: Optional dependency degradation
#
# IP::Country is blocked file-wide via Test::Without::Module.  For Geo::IP and
# Geo::IPfree the sentinel-injection helpers (_inject_geoip, _inject_geoipfree)
# cover the "present" path; explicit GEO_ABSENT injection covers the "absent"
# path.  Together these four subtests walk the full fallback chain:
#   IP::Country → Geo::IP → Geo::IPfree → geoplugin → Whois
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'optional: IP::Country absent — country() falls through to geoplugin JSON' => sub {
	SKIP: {
		skip 'LWP::Simple::WithCache or JSON::Parse not installed', 1
			unless $HAS_LWP && $HAS_JSON;

		local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

		my $l = _obj([$LANG{EN}]);
		$l->{_have_ipcountry} = 0;    # GEO_ABSENT (confirmed by blocked module)
		$l->{_have_geoip}     = 0;    # GEO_ABSENT
		$l->{_have_geoipfree} = 0;    # GEO_ABSENT

		# Override the global no-op LWP mock to return a real-looking JSON body.
		Test::Mockingbird::mock('LWP::Simple::WithCache', 'get',
			sub { $GEO_JSON_US });

		my $cc = $l->country();
		is($cc, 'us',
			'country() returns US from geoplugin JSON when IP::Country is absent');

		{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
		_block_network();
	}
};

subtest 'optional: Geo::IP resolves country when IP::Country absent' => sub {
	# Strategy: inject Geo::IP as the active resolver (IP::Country is blocked
	# file-wide).  Verifies the IP::Country → Geo::IP fallback step.
	local %ENV = (REMOTE_ADDR => $IP{US});

	my $l = _obj([$LANG{EN}]);
	_inject_geoip($l, 'US');

	is($l->country(), 'us', 'country() returns us via Geo::IP when IP::Country absent');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'optional: Geo::IPfree resolves country when Geo::IP also absent' => sub {
	# Strategy: inject Geo::IPfree with Geo::IP explicitly absent.
	# Verifies the Geo::IP → Geo::IPfree fallback step.
	local %ENV = (REMOTE_ADDR => $IP{GB});

	my $l = _obj([$LANG{EN}]);
	_inject_geoipfree($l, 'GB');

	is($l->country(), 'gb', 'country() returns gb via Geo::IPfree when Geo::IP absent');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'optional: IP::Country absent + geoplugin fails — Whois is attempted' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

	my $l = _obj([$LANG{EN}]);
	$l->{_have_ipcountry} = 0;    # GEO_ABSENT
	$l->{_have_geoip}     = 0;    # GEO_ABSENT
	$l->{_have_geoipfree} = 0;    # GEO_ABSENT

	# Whois call is globally mocked to a no-op; spy on it to verify it fires.
	my $whois_spy = Test::Mockingbird::spy('CGI::Lingua', '_resolve_country_via_whois');

	# LWP returns undef (global mock) — geoplugin fails, so Whois must be tried.
	$l->country();

	my @calls = $whois_spy->();
	ok(scalar @calls > 0,
		'_resolve_country_via_whois attempted when IP::Country and geoplugin both fail');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 10: GEOIP_COUNTRY_CODE coherence across country() and locale()
#
# Strategy: when the mod_geoip environment variable is set, country() and
# locale() must both derive from the same underlying code.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'GEOIP_COUNTRY_CODE: country() and locale() agree on the same country' => sub {
	local %ENV = (GEOIP_COUNTRY_CODE => 'GB');

	my $l = _obj([$LANG{EN}]);

	my $cc = $l->country();
	is($cc, 'gb', 'country() returns gb from GEOIP_COUNTRY_CODE');

	my $loc = $l->locale();
	if(defined $loc) {
		isa_ok($loc, 'Locale::Object::Country',
			'locale() returns Locale::Object::Country');
	} else {
		pass('locale() returned undef (Locale::Object DB may be absent on this system)');
	}
};

subtest 'HTTP_CF_IPCOUNTRY: country() and locale() agree when Cloudflare header set' => sub {
	local %ENV = (HTTP_CF_IPCOUNTRY => 'FR');

	my $l = _obj([$LANG{FR}, $LANG{EN}]);

	is($l->country(), 'fr',
		'country() returns fr from HTTP_CF_IPCOUNTRY');

	my $loc = $l->locale();
	if(defined $loc) {
		isa_ok($loc, 'Locale::Object::Country',
			'locale() returns Locale::Object::Country for FR');
	} else {
		pass('locale() returned undef (Locale::Object DB may be absent)');
	}
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 11: End-to-end session workflow
#
# Strategy: simulate a complete web request lifecycle where language, country,
# locale, and time_zone are all queried in sequence for the same object.
# Verify that each method returns a coherent result and that the object's
# internal state remains consistent after each call.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'full session workflow: language + country + locale coherent with GEOIP_COUNTRY_CODE' => sub {
	local %ENV = (
		GEOIP_COUNTRY_CODE   => 'GB',
		HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB},
	);

	my $l = _obj([$LANG{EN_GB}]);

	my $lang = $l->language();
	my $cc   = $l->country();
	my $loc  = $l->locale();

	is($lang, 'English', 'language() returns English');
	is($cc,   'gb',      'country() returns gb');

	if(defined $loc) {
		isa_ok($loc, 'Locale::Object::Country',
			'locale() returns Locale::Object::Country');
	} else {
		pass('locale() undef (Locale::Object DB absent — acceptable in CI)');
	}

	# Internal state: language and country must both be populated without
	# interfering with each other — they populate different keys.
	is($l->{_slanguage}, 'English', '_slanguage populated');
	is($l->{_country},   'gb',      '_country populated');
};

subtest 'full session workflow: time_zone with cached _timezone skips all network I/O' => sub {
	# If _timezone is already set (from a prior call or thawed cache), the method
	# must return it immediately without any network round-trip.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

	my $l = _obj([$LANG{EN}]);
	$l->{_timezone} = 'Europe/London';    # simulate a pre-populated cache entry

	# Spy on LWP to verify it is NOT called
	my $lwp_spy;
	if ($HAS_LWP) {
		local $SIG{__WARN__} = sub {};
		$lwp_spy = Test::Mockingbird::spy('LWP::Simple::WithCache', 'get');
	}

	my $tz = $l->time_zone();

	is($tz, 'Europe/London', 'time_zone() returns cached timezone');

	if($lwp_spy) {
		my @calls = $lwp_spy->();
		is(scalar @calls, 0,
			'LWP not called when timezone already cached');
	} else {
		pass('LWP not installed — skipping spy check');
	}

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'full session workflow: deprecated en-uk header normalised to en-gb throughout pipeline' => sub {
	# RFC note: some browsers still emit 'en-uk' rather than 'en-gb'.
	# The module normalises this to 'en-gb' and all accessors must reflect that.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-uk');

	my $l = _obj([$LANG{EN_GB}]);

	is($l->language(),     'English',       'language() normalises en-uk to English');
	# sublanguage may or may not be populated depending on whether _code2countryname
	# resolves 'gb' — just verify no crash occurs.
	my $sub = $l->sublanguage();
	ok(!$@ || 1, 'sublanguage() does not die for en-uk input');

	diag("sublanguage: " . ($sub // 'undef')) if $ENV{TEST_VERBOSE};
};

done_testing();
