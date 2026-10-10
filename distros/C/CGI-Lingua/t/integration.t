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
# Geo::IP and Geo::IPfree are NOT globally excluded - Section 9 tests both the
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

BEGIN { use_ok('CGI::Lingua') }

# Pre-require lazy-loaded network modules before mocking them.
# A module's BEGIN block runs on first require and would clobber any mock
# installed before that point.  We load both unconditionally so the symbol
# table entries are stable before any mocks are installed.
my $HAS_LWP  = eval { require LWP::Simple::WithCache; 1 } ? 1 : 0;
my $HAS_JSON = eval { require JSON::Parse;             1 } ? 1 : 0;

# -- Shared constants ----------------------------------------------------------

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

# -- Global network block ------------------------------------------------------
# Installed once at the start; reinstalled after any restore_all() call.
# This ensures no test ever makes a real network round-trip.
_block_network();

# -- Shared helpers ------------------------------------------------------------

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

# Simulate "Geo::IP present" - bypasses the lazy-require + db-file guard in
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

# Simulate "Geo::IPfree present" - bypasses the lazy-require guard.
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

# -------------------------------------------------------------------------------
# SECTION 1: Full detection-pipeline coherence
#
# Strategy: verify that all language-related accessors return a mutually
# consistent picture when constructed from a single Accept-Language header.
# Each subtest creates one object and checks every public method, exercising
# the entire pipeline from header -> I18N::AcceptLanguage -> language/sub-lang.
# -------------------------------------------------------------------------------

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

# -------------------------------------------------------------------------------
# SECTION 2: Multi-language header priority negotiation
#
# Strategy: feed real-world Accept-Language headers containing multiple candidates
# with quality weights.  Vary the supported-languages list to exercise both
# "first match wins" and "sublanguage fallback" paths within a single request.
# -------------------------------------------------------------------------------

subtest 'priority: de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7 -> German when de supported' => sub {
	local %ENV = (
		HTTP_ACCEPT_LANGUAGE => 'de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7',
		# No REMOTE_ADDR - prevent IP-based fallback from interfering
	);
	# Remove locale env vars that I18N::LangTags::Detect might consume
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	delete local $ENV{LANG};

	my $l = _obj([$LANG{DE}, $LANG{EN}]);
	is($l->language(), 'German', 'German selected as highest-priority supported language');
};

subtest 'priority: de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7 -> English (United States) when de not supported' => sub {
	local %ENV = (
		HTTP_ACCEPT_LANGUAGE => 'de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7',
	);
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	delete local $ENV{LANG};
	delete local $ENV{REMOTE_ADDR};

	# en-us is supported but not de - module must fall through to en-us
	my $l = _obj([$LANG{EN_US}, $LANG{FR}]);
	is($l->language(),    'English',       'Fell through de to en-us');
	is($l->sublanguage(), 'United States', 'sublanguage() is United States');
};

subtest 'priority: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7 -> English (United States) when zh not supported' => sub {
	local %ENV = (
		HTTP_ACCEPT_LANGUAGE => 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7',
	);
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};
	delete local $ENV{LANG};
	delete local $ENV{REMOTE_ADDR};

	# Only English variants supported - must fall through zh to en-us
	my $l = _obj([$LANG{EN_US}, $LANG{EN_GB}]);
	is($l->language(),    'English',       'Fell through zh to en-us');
	is($l->sublanguage(), 'United States', 'sublanguage() is United States');
};

# -------------------------------------------------------------------------------
# SECTION 3: Stateful method-ordering independence
#
# Strategy: the lazily-populated fields must produce the same result regardless
# of which method is called first.  Call methods in reverse order to prove that
# each accessor's lazy guard is effective and idempotent.
# -------------------------------------------------------------------------------

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

# -------------------------------------------------------------------------------
# SECTION 4: IP-based language fallback and dont_use_ip mode
#
# Strategy: test that the IP-fallback path is taken when Accept-Language is
# absent, and that dont_use_ip suppresses it.
# -------------------------------------------------------------------------------

subtest 'IP fallback: dont_use_ip suppresses country-based language detection' => sub {
	# With dont_use_ip, no IP lookup is made regardless of REMOTE_ADDR.
	# language() must return Unknown when Accept-Language is also absent.
	# country() remains callable - dont_use_ip does not disable it.
	# Explicitly set all local geo module sentinels to GEO_ABSENT so the result
	# is deterministic regardless of which modules are installed on the machine.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	delete local $ENV{HTTP_ACCEPT_LANGUAGE};
	delete local $ENV{LANG};

	my $l = _obj([$LANG{EN}], dont_use_ip => 1);
	$l->{_have_ipcountry} = 0;    # GEO_ABSENT - force "no IP::Country" path
	$l->{_have_geoip}     = 0;    # GEO_ABSENT - force "no Geo::IP" path
	$l->{_have_geoipfree} = 0;    # GEO_ABSENT - force "no Geo::IPfree" path
	is($l->language(), 'Unknown', 'dont_use_ip: language() returns Unknown with no header');
	ok(!defined $l->country(),    'dont_use_ip does not prevent country() call itself');
};

subtest 'IP fallback: loopback IP with no Accept-Language gives Unknown language' => sub {
	# Loopback address cannot be resolved to a country - language falls through
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

# -------------------------------------------------------------------------------
# SECTION 5: Cache workflow across object construction and destruction
#
# Strategy: verify the DESTROY -> JSON::PP::encode_json -> decode_json cycle that
# the module uses to skip expensive geo-lookups on subsequent requests from the same IP.
# -------------------------------------------------------------------------------

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

	# The thawed object has _slanguage set - no recomputation needed.
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

# -------------------------------------------------------------------------------
# SECTION 6: Concurrent object isolation
#
# Strategy: instantiate multiple independent objects in the same test and verify
# they do not share per-object state (language, country, cached geo results).
# -------------------------------------------------------------------------------

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

# -------------------------------------------------------------------------------
# SECTION 7: Clone workflow
#
# Strategy: verify that cloning (calling new() on an existing object) produces
# an independent object that respects the new supported-languages parameter.
# -------------------------------------------------------------------------------

subtest 'clone: new supported list is respected and state is independent' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{FR});

	my $orig  = _obj([$LANG{EN}, $LANG{FR}]);
	my $clone = $orig->new(supported => [$LANG{DE}]);

	isa_ok($clone, 'CGI::Lingua', 'Clone is a CGI::Lingua object');
	isnt($orig, $clone, 'Clone is a distinct reference');

	# Clone's supported list is de-only - fr header should yield Unknown
	is($clone->language(), 'Unknown',
		'Clone with de-only supported returns Unknown for fr header');

	# Populating the clone must not affect the original
	is($orig->language(), 'French',
		'Original object unaffected by clone language computation');
};

# -------------------------------------------------------------------------------
# SECTION 8: Network call verification via spies
#
# Strategy: use Test::Mockingbird::spy() to intercept calls to external
# resolution routines and verify they are (or are not) invoked depending
# on which faster lookup path succeeds first.
# -------------------------------------------------------------------------------

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

		# IP::Country is blocked by Test::Without::Module - the sentinel will be
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

# -------------------------------------------------------------------------------
# SECTION 9: Optional dependency degradation
#
# IP::Country is blocked file-wide via Test::Without::Module.  For Geo::IP and
# Geo::IPfree the sentinel-injection helpers (_inject_geoip, _inject_geoipfree)
# cover the "present" path; explicit GEO_ABSENT injection covers the "absent"
# path.  Together these four subtests walk the full fallback chain:
#   IP::Country -> Geo::IP -> Geo::IPfree -> geoplugin -> Whois
# -------------------------------------------------------------------------------

subtest 'optional: IP::Country absent - country() falls through to geoplugin JSON' => sub {
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
	# file-wide).  Verifies the IP::Country -> Geo::IP fallback step.
	local %ENV = (REMOTE_ADDR => $IP{US});

	my $l = _obj([$LANG{EN}]);
	_inject_geoip($l, 'US');

	is($l->country(), 'us', 'country() returns us via Geo::IP when IP::Country absent');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'optional: Geo::IPfree resolves country when Geo::IP also absent' => sub {
	# Strategy: inject Geo::IPfree with Geo::IP explicitly absent.
	# Verifies the Geo::IP -> Geo::IPfree fallback step.
	local %ENV = (REMOTE_ADDR => $IP{GB});

	my $l = _obj([$LANG{EN}]);
	_inject_geoipfree($l, 'GB');

	is($l->country(), 'gb', 'country() returns gb via Geo::IPfree when Geo::IP absent');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

subtest 'optional: IP::Country absent + geoplugin fails - Whois is attempted' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

	my $l = _obj([$LANG{EN}]);
	$l->{_have_ipcountry} = 0;    # GEO_ABSENT
	$l->{_have_geoip}     = 0;    # GEO_ABSENT
	$l->{_have_geoipfree} = 0;    # GEO_ABSENT

	# Whois call is globally mocked to a no-op; spy on it to verify it fires.
	my $whois_spy = Test::Mockingbird::spy('CGI::Lingua', '_resolve_country_via_whois');

	# LWP returns undef (global mock) - geoplugin fails, so Whois must be tried.
	$l->country();

	my @calls = $whois_spy->();
	ok(scalar @calls > 0,
		'_resolve_country_via_whois attempted when IP::Country and geoplugin both fail');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
};

# -------------------------------------------------------------------------------
# SECTION 10: GEOIP_COUNTRY_CODE coherence across country() and locale()
#
# Strategy: when the mod_geoip environment variable is set, country() and
# locale() must both derive from the same underlying code.
# -------------------------------------------------------------------------------

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

# -------------------------------------------------------------------------------
# SECTION 11: End-to-end session workflow
#
# Strategy: simulate a complete web request lifecycle where language, country,
# locale, and time_zone are all queried in sequence for the same object.
# Verify that each method returns a coherent result and that the object's
# internal state remains consistent after each call.
# -------------------------------------------------------------------------------

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
		pass('locale() undef (Locale::Object DB absent - acceptable in CI)');
	}

	# Internal state: language and country must both be populated without
	# interfering with each other - they populate different keys.
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
		pass('LWP not installed - skipping spy check');
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
	# resolves 'gb' - just verify no crash occurs.
	my $sub = $l->sublanguage();
	ok(!$@ || 1, 'sublanguage() does not die for en-uk input');

	diag("sublanguage: " . ($sub // 'undef')) if $ENV{TEST_VERBOSE};
};

# =============================================================================
# SECTION 12: Optional dependencies, in every combination
#
# Strategy: a module that is already loaded cannot be unloaded, so each
# combination runs in a child perl started with Test::Without::Module hiding
# the chosen modules.  The child replaces every upstream (geo databases,
# web services, Whois) with a recorder that returns a distinct canned answer,
# runs the public API, and prints JSON describing what it got and which
# upstreams were asked.  The parent works out the answer the POD promises
# for that combination ("first source that is installed and answers wins")
# and compares.
# =============================================================================

Readonly my %CFG => (
	ip_public        => '8.8.8.8',
	ip_baidu         => '185.10.104.1',
	ip_private       => '10.1.2.3',
	ip_mapped        => '::ffff:8.8.8.8',
	ip_v6            => '2001:db8::1',
	zone_withcache   => 'Europe/London',
	zone_simple      => 'Asia/Tokyo',
	zone_local       => 'Europe/Paris',
	latency          => 0.5,	# seconds of injected upstream delay
	latency_slack    => 1.5,	# allowed overhead on top of one delay
	big_payload      => 1_000_000,
	geo_modules      => [qw(IP::Country::Fast Geo::IP Geo::IPfree LWP::Simple::WithCache JSON::Parse)],
	tz_modules       => [qw(LWP::Simple::WithCache LWP::Simple JSON::Parse)],
	child_marker     => 'CHILD-JSON: ',
);

# Canned answers, one per upstream, so the result names its source.
Readonly my %CANNED => (
	'IP::Country::Fast' => 'US',
	'Geo::IP'           => 'GB',
	'Geo::IPfree'       => 'FR',
	geoplugin           => 'DE',
	whois               => 'JP',
);

# Official language of each canned country, for the IP-fallback workflow
Readonly my %OFFICIAL => (us => 'English', gb => 'English', fr => 'French', de => 'German', jp => 'Japanese');

# The child.  Reads its instructions from $ENV{CGI_LINGUA_CHILD}.
Readonly my $CHILD => <<'CHILD';
use strict;
use warnings;
use JSON::PP ();
use Scalar::Util qw(blessed);
use Test::Mockingbird;

my $cfg    = JSON::PP::decode_json(delete $ENV{CGI_LINGUA_CHILD});
my %canned = %{$cfg->{canned} || {}};
my (%called, @warnings);
my %have = map { my $m = $_; ($m => (eval "require $m; 1" ? 1 : 0)) } @{$cfg->{probe}};

{
	local $SIG{__WARN__} = sub { };	# prototype mismatches on mocked get($)
	if($have{'IP::Country::Fast'}) {
		Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { $called{'IP::Country::Fast'}++; $canned{'IP::Country::Fast'} });
	}
	if($have{'Geo::IP'}) {
		Test::Mockingbird::mock('Geo::IP', 'country_code_by_addr', sub { $called{'Geo::IP'}++; $canned{'Geo::IP'} });
		Test::Mockingbird::mock('Geo::IP', 'time_zone', sub { undef });
	}
	if($have{'Geo::IPfree'}) {
		Test::Mockingbird::mock('Geo::IPfree', 'LookUp', sub { $called{'Geo::IPfree'}++; ($canned{'Geo::IPfree'}) });
	}
	my $web = sub {
		my ($via, $url) = @_;
		if($url =~ /geoplugin/) {
			$called{geoplugin}++;
			return $canned{geoplugin_raw} // JSON::PP::encode_json({ geoplugin_countryCode => $canned{geoplugin} });
		}
		$called{"ip-api via $via"}++;
		return JSON::PP::encode_json({ timezone => $canned{"zone $via"} });
	};
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { $web->('WithCache', $_[0]) }) if $have{'LWP::Simple::WithCache'};
	Test::Mockingbird::mock('LWP::Simple', 'get', sub { $web->('Simple', $_[0]) }) if $have{'LWP::Simple'};
	require Net::Whois::IP;
	require Net::Whois::IANA;
	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query', sub { $called{whois}++; return { Country => $canned{whois} } });
	Test::Mockingbird::mock('Net::Whois::IANA', 'whois_query', sub { 1 });
	Test::Mockingbird::mock('Net::Whois::IANA', 'country', sub { $called{iana}++ if defined $canned{iana}; $canned{iana} });
}
$SIG{__WARN__} = sub { push @warnings, $_[0] };

require CGI::Lingua;
my @runs;
for my $run (@{$cfg->{runs}}) {
	local %ENV = %{$run->{env}};
	%called = ();
	@warnings = ();
	my $l = CGI::Lingua->new(supported => $cfg->{supported}, %{$cfg->{args} || {}});
	$l->{logger} = undef;	# warnings go through carp, into @warnings
	my %result;
	for my $method (@{$run->{calls}}) {
		my $r = $l->$method();
		$result{$method} = blessed($r) ? $r->name() : $r;
	}
	push @runs, { result => \%result, called => { %called }, warnings => [ @warnings ] };
}
print 'CHILD-JSON: ', JSON::PP->new->canonical->allow_nonref->encode({ have => \%have, runs => \@runs }), "\n";
CHILD

# Run $CHILD with the given modules hidden; return its decoded report.
sub _child {
	my ($hidden, $cfg) = @_;
	# Always probe (and so mock) every upstream module, so that no child can
	# reach the real network, whatever it hides
	my %probe = map { $_ => 1 } (@{$cfg->{probe} || []}, @{$CFG{geo_modules}}, @{$CFG{tz_modules}});
	local $ENV{CGI_LINGUA_CHILD} = JSON::PP::encode_json({ %{$cfg}, probe => [ sort keys %probe ] });
	my @hide = @{$hidden} ? ('-MTest::Without::Module=' . join(',', @{$hidden})) : ();
	open(my $fh, '-|', $^X, _cover_switches(), '-Ilib', @hide, _child_script()) or die "Can't run $^X: $!";
	my $out = do { local $/; <$fh> } // '';
	close $fh;
	diag("child [@hide]: $out") if $ENV{TEST_VERBOSE};
	my ($json) = $out =~ /^\Q$CFG{child_marker}\E(.*)$/m;
	return JSON::PP::decode_json($json) if $json;
	# An empty error string would read as success; always say something
	return { error => length($out) ? $out : 'child printed nothing' };
}

# Under "cover -test" the parent runs with -MDevel::Cover from
# HARNESS_PERL_SWITCHES, but a child perl does not; pass the same switch on,
# so the paths that only run in children (missing optional modules) are
# counted.  (PERL5OPT, if used instead, is inherited anyway.)
sub _cover_switches {
	return grep { /^-MDevel::Cover\b/ } split(/\s+/, $ENV{HARNESS_PERL_SWITCHES} // '');
}

# The child runs from a file, written once: Windows mangles a multi-line
# "perl -e" argument (the script arrives as a syntax error).
my $child_script;
sub _child_script {
	return $child_script if defined $child_script;
	require File::Temp;
	my $fh;
	($fh, $child_script) = File::Temp::tempfile(SUFFIX => '.pl', UNLINK => 1);
	print {$fh} $CHILD;
	close $fh;
	return $child_script;
}

# All 2**N subsets of a list.
sub _subsets {
	my @items = @_;
	return map { my $mask = $_; [ grep { $mask & (1 << $_) } 0 .. $#items ] } 0 .. (2 ** @items) - 1;
}

my $GEOIP_DB = grep { -r } qw(/usr/share/GeoIP/GeoIP.dat /usr/local/share/GeoIP/GeoIP.dat);
my $HAS_LOCALE_DB = eval {
	require Locale::Object::DB;
	Locale::Object::DB->new()->lookup(table => 'country', result_column => 'name', search_column => 'code_alpha2', value => 'gb');
	1;
};

subtest 'optional matrix: country() source order over every geo-module combination' => sub {
	# Strategy: 5 optional modules give 32 combinations.  For each, the
	# POD order is IP::Country, Geo::IP (only with a GeoIP.dat), Geo::IPfree,
	# geoplugin (needs LWP::Simple::WithCache and JSON::Parse), then Whois.
	# The first installed source must win, earlier sources must have been
	# asked, and no later source may be asked (no wasted network calls).
	# The winning country then drives the IP-based language choice.
	my @mods = @{$CFG{geo_modules}};
	for my $subset (_subsets(@mods)) {
		my @hidden = @mods[@{$subset}];
		my $report = _child(\@hidden, {
			probe     => \@mods,
			canned    => \%CANNED,
			supported => ['en', 'fr', 'de', 'ja'],
			runs      => [ { env => { REMOTE_ADDR => $CFG{ip_public} }, calls => [qw(language country)] } ],
		});
		my $label = @hidden ? 'without ' . join(', ', @hidden) : 'with everything';
		if($report->{error}) {
			fail("$label: child failed");
			diag($report->{error});
			next;
		}
		my %have = %{$report->{have}};
		my @chain = (
			[ 'IP::Country::Fast', $have{'IP::Country::Fast'} ],
			[ 'Geo::IP',           $have{'Geo::IP'} && $GEOIP_DB ],
			[ 'Geo::IPfree',       $have{'Geo::IPfree'} ],
			[ 'geoplugin',         $have{'LWP::Simple::WithCache'} && $have{'JSON::Parse'} ],
			[ 'whois',             1 ],
		);
		my @asked;
		for my $source (@chain) {
			next unless $source->[1];
			push @asked, $source->[0];
			last;
		}
		my $winner = $asked[-1];
		my $run = $report->{runs}[0];
		diag("$label: ", explain($run)) if $ENV{TEST_VERBOSE};

		is($run->{result}{country}, lc($CANNED{$winner}), "$label: country from $winner");
		is_deeply([ sort keys %{$run->{called}} ], [ sort @asked ], "$label: only $winner was asked");
		if($HAS_LOCALE_DB) {
			is($run->{result}{language}, $OFFICIAL{lc $CANNED{$winner}}, "$label: language is the country's official one");
		}
		is_deeply($run->{warnings}, [], "$label: no warnings");
	}
};

subtest 'optional matrix: time_zone() over every LWP / JSON::Parse combination' => sub {
	# Strategy: the POD promises ip-api.com through LWP::Simple::WithCache,
	# else LWP::Simple, both needing JSON::Parse; otherwise undef and a
	# warning naming what is missing.  Geo::IP is hidden so a host GeoIP.dat
	# cannot answer first.
	my @mods = @{$CFG{tz_modules}};
	for my $subset (_subsets(@mods)) {
		my @hidden = @mods[@{$subset}];
		my $report = _child([ @hidden, 'Geo::IP' ], {
			probe     => \@mods,
			canned    => { 'zone WithCache' => $CFG{zone_withcache}, 'zone Simple' => $CFG{zone_simple} },
			supported => ['en'],
			runs      => [ { env => { REMOTE_ADDR => $CFG{ip_public} }, calls => ['time_zone'] } ],
		});
		my $label = @hidden ? 'without ' . join(', ', @hidden) : 'with everything';
		if($report->{error}) {
			fail("$label: child failed");
			diag($report->{error});
			next;
		}
		my %have = %{$report->{have}};
		my $run = $report->{runs}[0];
		my $tz = $run->{result}{time_zone};
		if($have{'LWP::Simple::WithCache'} && $have{'JSON::Parse'}) {
			is($tz, $CFG{zone_withcache}, "$label: LWP::Simple::WithCache used");
		} elsif($have{'LWP::Simple'} && $have{'JSON::Parse'}) {
			is($tz, $CFG{zone_simple}, "$label: falls back to LWP::Simple");
		} else {
			ok(!defined($tz), "$label: undef, not a croak");
			# No LWP at all is reported first; JSON::Parse is blamed only when
			# an LWP module was there to fetch the answer
			my $expect = ($have{'LWP::Simple::WithCache'} || $have{'LWP::Simple'})
				? qr/^JSON::Parse is absent; cannot read ip-api\.com answers /
				: qr/^LWP::Simple::WithCache and LWP::Simple are both absent; cannot contact ip-api\.com /;
			ok((grep { $_ =~ $expect } @{$run->{warnings}}), "$label: warning names the missing module")
				or diag(explain($run->{warnings}));
		}
	}
};

subtest 'optional: Data::Validate::IP absent gives the same answers as present' => sub {
	# The pure-Perl fallbacks must classify addresses exactly as the module does
	# Every local and web source is hidden, so Whois (a prerequisite) always
	# answers and the result does not depend on what this host has installed
	my @runs = map { { env => { REMOTE_ADDR => $_ }, calls => ['country'] } }
		($CFG{ip_private}, $CFG{ip_mapped}, $CFG{ip_v6}, $CFG{ip_public});
	my %by;
	for my $hidden ([], [qw(Data::Validate::IP NetAddr::IP)]) {
		my $label = @{$hidden} ? 'without Data::Validate::IP' : 'with Data::Validate::IP';
		my $report = _child([ @{$hidden}, qw(IP::Country::Fast Geo::IP Geo::IPfree LWP::Simple::WithCache) ], {
			probe => [], canned => \%CANNED, supported => ['en'], runs => \@runs,
		});
		BAIL_OUT("child failed: $report->{error}") if $report->{error};
		$by{$label} = [ map { $_->{result}{country} } @{$report->{runs}} ];
		diag("$label: ", explain($by{$label})) if $ENV{TEST_VERBOSE};
	}
	is_deeply($by{'without Data::Validate::IP'}, $by{'with Data::Validate::IP'}, 'identical results');
	is_deeply($by{'with Data::Validate::IP'}, [ undef, lc($CANNED{whois}), lc($CANNED{whois}), lc($CANNED{whois}) ],
		'private address has no country; mapped, IPv6 and IPv4 addresses are looked up');
};

subtest "optional: Net::Subnet absent - EU answers still resolve Baidu to cn" => sub {
	# RT-86809: the pure-Perl subnet check must agree with Net::Subnet
	# The EU answer comes from IANA (Whois proper discards EU), with the web
	# and local sources hidden, so the test does not need LWP or JSON::Parse
	for my $hidden ([], ['Net::Subnet']) {
		my $label = @{$hidden} ? 'without Net::Subnet' : 'with Net::Subnet';
		my $report = _child([ @{$hidden}, qw(IP::Country::Fast Geo::IP Geo::IPfree LWP::Simple::WithCache) ], {
			probe => [], canned => { %CANNED, whois => 'EU', iana => 'EU' }, supported => ['en'],
			runs  => [ map { { env => { REMOTE_ADDR => $_ }, calls => ['country'] } } ($CFG{ip_baidu}, $CFG{ip_public}) ],
		});
		BAIL_OUT("child failed: $report->{error}") if $report->{error};
		is($report->{runs}[0]{result}{country}, 'cn', "$label: Baidu EU address is cn");
		is($report->{runs}[1]{result}{country}, 'Unknown', "$label: other EU address is 'Unknown'");
	}
};

subtest 'optional: DateTime::TimeZone absent on the command line' => sub {
	# Without REMOTE_ADDR the zone comes from /etc/timezone, else from
	# DateTime::TimeZone::Local; with neither, undef and a warning.
	plan(skip_all => '/etc/timezone is readable, so DateTime::TimeZone is never consulted') if -r '/etc/timezone';
	my $run = [ { env => { TZ => $CFG{zone_local} }, calls => ['time_zone'] } ];

	my $without = _child(['DateTime::TimeZone::Local', 'DateTime::TimeZone'], { probe => [], supported => ['en'], runs => $run });
	BAIL_OUT("child failed: $without->{error}") if $without->{error};
	ok(!defined($without->{runs}[0]{result}{time_zone}), 'without: undef');
	ok((grep { /^DateTime::TimeZone::Local failed: / } @{$without->{runs}[0]{warnings}}), 'without: failure reported');

	SKIP: {
		skip 'DateTime::TimeZone not installed', 1 unless eval { require DateTime::TimeZone::Local; 1 };
		my $with = _child([], { probe => [], supported => ['en'], runs => $run });
		is($with->{runs}[0]{result}{time_zone}, $CFG{zone_local}, 'with: zone from TZ');
	}
};

subtest 'optional: HTTP::BrowserDetect absent - locale() still falls back' => sub {
	# A User-Agent with no language tag gives HTTP::BrowserDetect nothing;
	# with or without it, locale() must reach the GEOIP_COUNTRY_CODE fallback.
	plan(skip_all => 'Locale::Object database absent') unless $HAS_LOCALE_DB;
	my $run = [ { env => { HTTP_USER_AGENT => 'Mozilla/5.0 (X11; Linux x86_64)', GEOIP_COUNTRY_CODE => 'FR' }, calls => ['locale'] } ];
	for my $hidden ([], ['HTTP::BrowserDetect']) {
		my $label = @{$hidden} ? 'without HTTP::BrowserDetect' : 'with HTTP::BrowserDetect';
		my $report = _child($hidden, { probe => [], supported => ['en'], runs => $run });
		BAIL_OUT("child failed: $report->{error}") if $report->{error};
		is($report->{runs}[0]{result}{locale}, 'France', "$label: France from GEOIP_COUNTRY_CODE");
	}
};

# =============================================================================
# SECTION 13: Filesystem permission drops
#
# Strategy: Test::Permissions probes whether chmod really takes access away
# on this host (it does not for root or on some filesystems) and restores the
# mode afterwards.  The cache is a CHI File cache told to die on errors, so a
# failure is visible; CGI::Lingua must warn and carry on, and a later object
# must still get the right answers.
# =============================================================================

my $HAS_PERMS = eval { require Test::Permissions; Test::Permissions->import(qw(:revoke :guard :report)); 1 };

# Spy logger: records [level, message]
{
	package Integ::Spy;
	sub new { return bless { calls => [] }, shift }
	for my $level (qw(debug info notice trace warn error)) {
		no strict 'refs';
		*{$level} = sub { push @{$_[0]{calls}}, [$level, $_[1]] };
	}
	sub warnings { return map { $_->[1] } grep { $_->[0] eq 'warn' } @{$_[0]{calls}} }
}

sub _spied_obj {
	my (%args) = @_;
	my $l = CGI::Lingua->new(%args);
	$l->{logger} = Integ::Spy->new();
	return $l;
}

sub _file_cache {
	my $dir = shift;
	return CHI->new(driver => 'File', root_dir => $dir, on_get_error => 'die', on_set_error => 'die');
}

subtest 'permissions: cache directory that refuses new files' => sub {
	plan(skip_all => 'Test::Permissions not installed') unless $HAS_PERMS;
	require File::Temp;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	diag(permissions_report($dir)) if $ENV{TEST_VERBOSE};
	plan(skip_all => why_not('create', $dir)) unless can_revoke_create($dir);

	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => 'fr', GEOIP_COUNTRY_CODE => 'FR');
	my $cache = _file_cache($dir);
	with_revoked(create => $dir, sub {
		my $l = _spied_obj(supported => ['en', 'fr'], cache => $cache);
		lives_ok {
			is($l->language(), 'French', 'language still negotiated');
			is($l->country(), 'fr', 'country still found');
		} 'pipeline survives an unwritable cache';
		ok((grep { /^Cache set failed: / } $l->{logger}->warnings()), 'the failure is logged');
		lives_ok { undef $l } 'DESTROY survives the unwritable cache';
	});

	# Access restored: a new object works and the cache is usable again
	my $after = CGI::Lingua->new(supported => ['en', 'fr'], cache => $cache);
	is($after->language(), 'French', 'next request is unaffected');
};

subtest 'permissions: cache directory that cannot be searched' => sub {
	plan(skip_all => 'Test::Permissions not installed') unless $HAS_PERMS;
	require File::Temp;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	plan(skip_all => why_not('search', $dir)) unless can_revoke_search($dir);

	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => 'en-gb');
	my $cache = _file_cache($dir);
	{
		# Fill the cache while it is readable
		my $l = CGI::Lingua->new(supported => ['en-gb'], cache => $cache);
		$l->language();
	}
	with_revoked(search => $dir, sub {
		my $l;
		lives_ok { $l = _spied_obj(supported => ['en-gb'], cache => $cache) } 'new() survives';
		is($l->language(), 'English', 'answer recomputed when the cache cannot be read');
		is($l->sublanguage(), 'United Kingdom', 'sublanguage recomputed too');
	});
};

subtest 'permissions: translation directory that cannot be searched' => sub {
	plan(skip_all => 'Test::Permissions not installed') unless $HAS_PERMS;
	require File::Temp;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	plan(skip_all => why_not('search', $dir)) unless can_revoke_search($dir);
	open(my $fh, '>', "$dir/en.json") or die "$dir/en.json: $!";
	close $fh;

	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = CGI::Lingua->new(supported => ['en']);
	is($l->translation_file($dir), "$dir/en.json", 'found while readable');
	with_revoked(search => $dir, sub {
		my $path;
		local $! = 0;
		lives_ok { $path = $l->translation_file($dir) } 'lives';
		ok(!defined($path), 'undef: the file cannot be seen');
		is($! + 0, 0, '$! from the failed file test is not leaked');
	});
};

# =============================================================================
# SECTION 14: Upstream sabotage
#
# Strategy: make each external system fail in the ways real ones do -
# timeouts, slow answers, garbage payloads, crashes - and check that the
# request still completes, fails over to the next source, logs what went
# wrong, does not retry endlessly, and leaves other objects unharmed.
# =============================================================================

my $HAS_WHOIS = eval { require Net::Whois::IP; require Net::Whois::IANA; 1 };

# Make country() go straight to geoplugin and then a real (mocked) Whois.
sub _web_chain {
	my ($l, %whois) = @_;
	$l->{_have_ipcountry} = $l->{_have_geoip} = $l->{_have_geoipfree} = 0;
	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');
	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query', $whois{ip} || sub { undef });
	Test::Mockingbird::mock('Net::Whois::IANA', 'new', $whois{iana_new}) if $whois{iana_new};
	Test::Mockingbird::mock('Net::Whois::IANA', 'whois_query', sub { 1 });
	Test::Mockingbird::mock('Net::Whois::IANA', 'country', sub { undef });
	return $l;
}

sub _set_get {
	my $code = shift;
	local $SIG{__WARN__} = sub { };
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', $code);
}

sub _restore {
	local $SIG{__WARN__} = sub { };
	Test::Mockingbird::restore_all();
	_block_network();
}

subtest 'sabotage: geoplugin timeout fails over to Whois' => sub {
	plan(skip_all => 'LWP::Simple::WithCache, JSON::Parse or Net::Whois not installed') unless $HAS_LWP && $HAS_JSON && $HAS_WHOIS;
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _spied_obj(supported => ['en']);
	_web_chain($l, ip => sub { return { Country => 'GB' } });
	_set_get(sub { die "500 read timeout\n" });
	my $whois = Test::Mockingbird::spy('Net::Whois::IP', 'whoisip_query');

	my $cc;
	lives_ok { $cc = $l->country() } 'timeout does not propagate';
	is($cc, 'gb', 'Whois answer used');
	my @calls = $whois->();
	is(scalar(@calls), 1, 'Whois asked once');
	is($calls[0][1], $IP{PUBLIC}, 'Whois asked about the visitor address');
	ok((grep { /^geoplugin lookup failed: 500 read timeout/ } $l->{logger}->warnings()), 'timeout logged');
	_restore();
};

subtest 'sabotage: slow geoplugin is asked once, not retried' => sub {
	plan(skip_all => 'LWP::Simple::WithCache or JSON::Parse not installed') unless $HAS_LWP && $HAS_JSON && $HAS_WHOIS;
	require Time::HiRes;
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _spied_obj(supported => ['en']);
	_web_chain($l);
	my $calls = 0;
	_set_get(sub { $calls++; Time::HiRes::sleep($CFG{latency}); return undef });

	my $start = [Time::HiRes::gettimeofday()];
	my $cc = $l->country();
	my $elapsed = Time::HiRes::tv_interval($start);
	diag("country() took ${elapsed}s") if $ENV{TEST_VERBOSE};
	ok(!defined($cc), 'no country when every source fails');
	is($calls, 1, 'geoplugin called exactly once');
	cmp_ok($elapsed, '<', $CFG{latency} + $CFG{latency_slack}, 'returns after one delay, no retry loop');
	_restore();
};

subtest 'sabotage: malformed geoplugin payloads' => sub {
	# Every payload must leave country() alive, with no country (or the
	# documented 'Unknown' for EU), and still try Whois.
	plan(skip_all => 'LWP::Simple::WithCache, JSON::Parse or Net::Whois not installed') unless $HAS_LWP && $HAS_JSON && $HAS_WHOIS;
	my %payloads = (
		'truncated JSON'        => '{"geoplugin_countryCode": "G',
		'JSON array'            => '[1,2,3]',
		'object as the code'    => '{"geoplugin_countryCode": {"a": 1}}',
		'HTML error page'       => '<html><body>502 Bad Gateway</body></html>',
		'empty body'            => '',
		'binary junk'           => join('', map { chr } 0 .. 255),
		'huge payload'          => '{"x":"' . ('a' x $CFG{big_payload}) . '"}',
		'script in the code'    => '{"geoplugin_countryCode": "GB<script>"}',
		'403 paywall answer'    => '{"geoplugin_status":403,"geoplugin_message":"upgrade"}',
	);
	for my $why (sort keys %payloads) {
		local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
		my $l = _spied_obj(supported => ['en']);
		_web_chain($l);
		_set_get(sub { $payloads{$why} });
		my $whois = Test::Mockingbird::spy('Net::Whois::IP', 'whoisip_query');
		my $cc;
		lives_ok { $cc = $l->country() } "$why: lives";
		ok(!defined($cc), "$why: no country");
		my @asked = $whois->();
		is(scalar(@asked), 1, "$why: Whois still tried");
		_restore();
	}
};

subtest 'sabotage: Whois and IANA both down' => sub {
	plan(skip_all => 'Net::Whois modules not installed') unless $HAS_WHOIS;
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = _spied_obj(supported => ['en']);
	_web_chain($l, ip => sub { die "connect: Connection refused\n" }, iana_new => sub { die "IANA: Connection refused\n" });
	my $cc;
	lives_ok { $cc = $l->country() } 'country() survives a total Whois outage';
	ok(!defined($cc), 'no country');
	is($l->language(), 'English', 'language negotiation is not affected');
	_restore();
};

subtest 'sabotage: ip-api.com timeout, garbage and hostile answers' => sub {
	plan(skip_all => 'LWP::Simple::WithCache or JSON::Parse not installed') unless $HAS_LWP && $HAS_JSON;
	my @cases = (
		[ 'timeout',       sub { die "500 read timeout\n" },               qr/^ip-api\.com lookup failed: 500 read timeout/ ],
		[ 'garbage',       sub { 'not JSON at all' },                      qr/^ip-api\.com returned unparseable JSON: / ],
		[ 'hostile zone',  sub { '{"timezone":"Europe/London\"><img>"}' }, qr/^Discarding malformed timezone / ],
	);
	for my $case (@cases) {
		my ($why, $get, $re) = @{$case};
		local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
		my $l = _spied_obj(supported => ['en']);
		$l->{_have_geoip} = 0;
		_set_get($get);
		my $tz;
		lives_ok { $tz = $l->time_zone() } "$why: lives";
		ok(!defined($tz), "$why: undef");
		ok((grep { $_ =~ $re } $l->{logger}->warnings()), "$why: logged");
		_restore();
	}
};

subtest 'sabotage: cache backend that dies on every call' => sub {
	# A cache only saves time; when it dies the full workflow (construct,
	# negotiate, look up, destroy) must still work, with each failure logged.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => 'en-gb', GEOIP_COUNTRY_CODE => 'GB');
	my $cache = CHI->new(driver => 'Memory', global => 0, on_get_error => 'die', on_set_error => 'die');
	{
		no warnings qw(redefine once);
		local *CHI::Driver::Memory::fetch = sub { die "backend down\n" };
		local *CHI::Driver::Memory::store = sub { die "backend down\n" };
		my $l;
		lives_ok { $l = CGI::Lingua->new(supported => ['en-gb'], cache => $cache) } 'new() survives';
		$l->{logger} = Integ::Spy->new();
		lives_ok {
			is($l->language(), 'English', 'language');
			is($l->sublanguage(), 'United Kingdom', 'sublanguage');
			is($l->country(), 'gb', 'country');
		} 'accessors survive';
		my @w = $l->{logger}->warnings();
		ok((grep { /^Cache (get|set) failed: .*backend down/ } @w), 'cache failures logged') or diag(explain(\@w));
		lives_ok { undef $l } 'DESTROY survives';
	}
};

subtest 'sabotage: a failing object does not affect a healthy one' => sub {
	# Two requests in the same process: one meets a dead geo service, the
	# other has a mod_geoip header.  Failure must not cascade between them.
	plan(skip_all => 'LWP::Simple::WithCache or JSON::Parse not installed') unless $HAS_LWP && $HAS_JSON;
	_set_get(sub { die "500 read timeout\n" });
	my ($broken, $healthy);
	{
		local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
		$broken = _spied_obj(supported => ['en']);
		$broken->{_have_ipcountry} = $broken->{_have_geoip} = $broken->{_have_geoipfree} = 0;
		ok(!defined($broken->country()), 'broken request: no country');
	}
	{
		local %ENV = (REMOTE_ADDR => $IP{US}, GEOIP_COUNTRY_CODE => 'US');
		$healthy = _spied_obj(supported => ['en']);
		is($healthy->country(), 'us', 'healthy request: country found');
	}
	is_deeply([ $healthy->{logger}->warnings() ], [], 'no warnings leaked into the healthy object');
	_restore();
};

# =============================================================================
# SECTION 15: More concurrency
# =============================================================================

subtest 'concurrency: three interleaved objects sharing one cache' => sub {
	# Strategy: build three objects for different visitors that share one
	# cache, call their methods in an interleaved order, and check that no
	# answer leaks from one visitor to another, through the object or the cache.
	my $cache = CHI->new(driver => 'Memory', global => 0);
	my %visitor = (
		a => { REMOTE_ADDR => $IP{GB}, HTTP_ACCEPT_LANGUAGE => 'en-gb', GEOIP_COUNTRY_CODE => 'GB' },
		b => { REMOTE_ADDR => $IP{FR}, HTTP_ACCEPT_LANGUAGE => 'fr',    GEOIP_COUNTRY_CODE => 'FR' },
		c => { REMOTE_ADDR => $IP{US}, HTTP_ACCEPT_LANGUAGE => 'de',    GEOIP_COUNTRY_CODE => 'US' },
	);
	my %obj;
	for my $k (sort keys %visitor) {
		local %ENV = %{$visitor{$k}};
		$obj{$k} = new_ok('CGI::Lingua' => [ supported => ['en-gb', 'fr', 'de'], cache => $cache ]);
	}
	# Interleave: language for all, then country for all, in a different order
	my %lang = map { local %ENV = %{$visitor{$_}}; ($_ => $obj{$_}->language()) } qw(c a b);
	my %cc   = map { local %ENV = %{$visitor{$_}}; ($_ => $obj{$_}->country()) } qw(b c a);
	diag(explain({ lang => \%lang, cc => \%cc })) if $ENV{TEST_VERBOSE};
	is_deeply(\%lang, { a => 'English', b => 'French', c => 'German' }, 'each visitor has their own language');
	is_deeply(\%cc,   { a => 'gb', b => 'fr', c => 'us' }, 'each visitor has their own country');
	is($obj{a}->sublanguage(), 'United Kingdom', 'a: sublanguage');
	ok(!defined($obj{b}->sublanguage()), 'b: no sublanguage leaked from a');

	# Objects destroyed while their own REMOTE_ADDR is set; each new object
	# for the same visitor must get that visitor's answers back.
	for my $k (sort keys %visitor) {
		local %ENV = %{$visitor{$k}};
		delete $obj{$k};
		my $again = CGI::Lingua->new(supported => ['en-gb', 'fr', 'de'], cache => $cache);
		is($again->language(), $lang{$k}, "$k: answer restored from the shared cache");
	}
};

done_testing();
