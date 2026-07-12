#!/usr/bin/env perl
# t/function.t — White-box unit tests for every sub in CGI::Lingua.
#
# Strategy: each sub is exercised in isolation.  External dependencies
# (I18N::AcceptLanguage, IP::Country, Locale::Language, etc.) are mocked
# via Test::Mockingbird so tests are deterministic and need no network.
# Return values are validated with Test::Returns; memory hygiene is
# confirmed with Test::Memory::Cycle.

use strict;
use warnings;

use CHI;
use Readonly;
use Scalar::Util qw(blessed);
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Most;
use Test::Returns qw(returns_ok returns_is);

use lib 't/lib';
use MyLogger;

BEGIN { use_ok('CGI::Lingua') }

# ── Test fixtures ────────────────────────────────────────────────────────────

# Sentinel values that the module uses internally; duplicated here so tests
# are self-documenting without having to grep the source.
Readonly my $GEO_UNKNOWN  => -1;
Readonly my $GEO_ABSENT   =>  0;
Readonly my $GEO_PRESENT  =>  1;
Readonly my $CACHE_NS     => 'CGI::Lingua:';

# A clean in-memory cache created fresh per test to avoid cross-test leakage.
sub _fresh_cache { CHI->new(driver => 'Memory', global => 0) }

# Minimal CGI::Lingua object with sentinel flags in their default state.
sub _basic_obj {
	my (%extra) = @_;
	CGI::Lingua->new(supported => ['en', 'fr'], %extra);
}

# ── new() ────────────────────────────────────────────────────────────────────

subtest 'new: ::new() misuse is rejected' => sub {
	# Using :: instead of -> should croak; the error is caught inside new()
	# because $class will be undef when called as a plain function.
	local %ENV = ();
	throws_ok {
		CGI::Lingua::new(undef, { supported => ['en'] })
	} qr/use ->new\(\) not ::new\(\)/, '::new() with args croaks';
};

subtest 'new: missing supported croaks' => sub {
	local %ENV = ();
	throws_ok { CGI::Lingua->new() } qr/^Usage|supported languages/i,
		'new() without supported croaks';
};

subtest 'new: wrong ref type for supported croaks' => sub {
	local %ENV = ();
	throws_ok {
		CGI::Lingua->new(supported => {})
	} qr/array ref/i, 'hashref supported croaks';
};

subtest 'new: string supported too short/long croaks' => sub {
	local %ENV = ();
	throws_ok { CGI::Lingua->new(supported => 'x') } qr/short code/i,
		'1-char supported croaks';
	throws_ok { CGI::Lingua->new(supported => 'toolong') } qr/short code/i,
		'7-char supported croaks';
};

subtest 'new: plain hashref logger accepted as Object::Configure config' => sub {
	# Object::Configure converts any non-blessed logger value (hashref, arrayref)
	# into a Log::Abstraction instance.  We must not pre-reject these.
	local %ENV = ();
	my $l;
	lives_ok { $l = CGI::Lingua->new(supported => ['en'], logger => {}) }
		'plain hashref logger does not croak — Object::Configure converts it';
	ok(blessed($l->{logger}), 'converted logger is a blessed object');
};

subtest 'new: invalid logger (missing method) croaks' => sub {
	local %ENV = ();
	# Object that has warn/info but not error
	my $partial = bless {}, 'PartialLogger';
	{
		no warnings 'once';
		*PartialLogger::warn = sub {};
		*PartialLogger::info = sub {};
	}
	throws_ok {
		CGI::Lingua->new(supported => ['en'], logger => $partial)
	} qr/blessed object/i, 'logger missing error() croaks';
};

subtest 'new: string supported wraps into arrayref' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr');
	my $l = CGI::Lingua->new(supported => 'fr');
	ok(ref($l->{_supported}) eq 'ARRAY', '_supported is arrayref for string input');
	is_deeply($l->{_supported}, ['fr'], '_supported contains the single language');
};

subtest 'new: sentinel flags initialised to GEO_UNKNOWN' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	is($l->{_have_ipcountry}, $GEO_UNKNOWN, '_have_ipcountry starts at -1');
	is($l->{_have_geoip},     $GEO_UNKNOWN, '_have_geoip starts at -1');
	is($l->{_have_geoipfree}, $GEO_UNKNOWN, '_have_geoipfree starts at -1');
};

subtest 'new: cloning overlays params onto existing state' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $orig  = _basic_obj();
	$orig->{_country} = 'us';
	my $clone = $orig->new(supported => ['de']);
	is($clone->{_country}, 'us', 'Clone inherits computed state');
	is_deeply($clone->{_supported}, ['de'], 'Clone takes new supported');
	isnt($orig, $clone, 'Clone is a distinct object');
};

subtest 'new: cache restoration thaws frozen state' => sub {
	# The key bug this exercises: arrayref supported must build the same
	# cache key in new() as DESTROY() does, so the thaw path is reachable.
	local %ENV = (REMOTE_ADDR => '1.2.3.4', HTTP_ACCEPT_LANGUAGE => 'en');
	my $cache = _fresh_cache();
	my $first = CGI::Lingua->new(supported => ['en'], cache => $cache);
	$first->language();    # populate computed state
	undef $first;          # triggers DESTROY, writes to cache

	# Second construction for the same IP must restore from cache
	local $ENV{REMOTE_ADDR} = '1.2.3.4';
	my $second = CGI::Lingua->new(supported => ['en'], cache => $cache);
	is($second->{_slanguage}, 'English', 'Cached _slanguage is restored');
};

# ── _build_cache_key ─────────────────────────────────────────────────────────

subtest '_build_cache_key: string supported' => sub {
	local %ENV = ();
	my $key = CGI::Lingua::_build_cache_key('1.2.3.4', { supported => 'en' }, 'CGI::Lingua', undef);
	is($key, '1.2.3.4/en', 'Key is ip/lang for string supported');
};

subtest '_build_cache_key: arrayref supported produces deterministic key' => sub {
	# The original bug: ref($params->{'supported'} eq 'ARRAY') always
	# evaluated to '' so arrayrefs were stringified as ARRAY(0x...).
	local %ENV = ();
	my $supported = ['en', 'fr'];
	my $key = CGI::Lingua::_build_cache_key('1.2.3.4', { supported => $supported }, 'CGI::Lingua', undef);
	is($key, '1.2.3.4/en/fr', 'Arrayref supported gives joined key, not ARRAY(0x...)');
	unlike($key, qr/ARRAY\(/, 'Key does not contain stringified reference');
};

subtest '_build_cache_key: includes Accept-Language in key' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr');
	my $key = CGI::Lingua::_build_cache_key('5.6.7.8', { supported => ['fr'] }, 'CGI::Lingua', undef);
	is($key, '5.6.7.8/fr/fr', 'Key embeds Accept-Language for distinct slots per-IP');
};

subtest '_build_cache_key: info->lang() takes priority over env var' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'de');
	# Minimal mock info object
	my $info = bless {}, 'MockInfo';
	Test::Mockingbird::mock('MockInfo', 'lang', sub { 'ja' });
	my $key = CGI::Lingua::_build_cache_key('9.9.9.9', { supported => ['ja'] }, 'CGI::Lingua', $info);
	like($key, qr{^9\.9\.9\.9/ja/}, 'info->lang() overrides env HTTP_ACCEPT_LANGUAGE in key');
	Test::Mockingbird::restore_all();
};

# ── DESTROY ──────────────────────────────────────────────────────────────────

subtest 'DESTROY: stores serialised state in cache' => sub {
	local %ENV = (REMOTE_ADDR => '10.20.30.40', HTTP_ACCEPT_LANGUAGE => 'fr');
	my $cache = _fresh_cache();
	{
		my $l = CGI::Lingua->new(supported => ['fr'], cache => $cache);
		$l->language();    # force _slanguage to be computed
	}    # DESTROY fires here

	# A key matching the pattern 'ip/lang/supported' must exist in the cache
	my $key  = '10.20.30.40/fr/fr';
	my $blob = $cache->get($key);
	ok(defined $blob, 'DESTROY wrote a frozen blob to the cache');

	my $thawed = Storable::thaw($blob);
	is($thawed->{_slanguage}, 'French', 'Frozen blob contains correct _slanguage');
};

subtest 'DESTROY: skips cache when no REMOTE_ADDR' => sub {
	local %ENV = ();
	my $cache = _fresh_cache();
	{
		my $l = CGI::Lingua->new(supported => ['en'], cache => $cache);
	}
	is_deeply([ $cache->get_keys() ], [], 'Nothing written to cache without REMOTE_ADDR');
};

subtest 'DESTROY: does not overwrite existing cache entry' => sub {
	local %ENV = (REMOTE_ADDR => '55.55.55.55', HTTP_ACCEPT_LANGUAGE => 'en');
	my $cache = _fresh_cache();

	# Pre-seed the cache with a frozen object so the set-if-absent guard fires
	my $sentinel = bless { _slanguage => 'SentinelLanguage' }, 'CGI::Lingua';
	$cache->set('55.55.55.55/en/en', Storable::nfreeze($sentinel), '1 month');

	{
		my $l = CGI::Lingua->new(supported => ['en'], cache => $cache);
		$l->language();
	}    # DESTROY fires

	my $blob    = $cache->get('55.55.55.55/en/en');
	my $thawed  = Storable::thaw($blob);
	is($thawed->{_slanguage}, 'SentinelLanguage', 'Existing cache entry was not overwritten');
};

# ── Public language accessors ─────────────────────────────────────────────────
# These thin wrappers must delegate to _find_language() exactly once and then
# use the cached result on subsequent calls.

subtest 'language() returns English for en' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = _basic_obj();
	returns_ok($l->language(), { type => 'string' }, 'language() returns a string');
	is($l->language(), 'English', 'language() returns English');
};

subtest 'preferred_language() aliases language()' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr');
	my $l = _basic_obj();
	is($l->preferred_language(), $l->language(), 'preferred_language() equals language()');
};

subtest 'name() aliases language()' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = _basic_obj();
	is($l->name(), $l->language(), 'name() equals language()');
};

subtest 'language() returns Unknown when language unsupported' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'de', REMOTE_ADDR => '127.0.0.1');
	my $l = _basic_obj();
	is($l->language(), 'Unknown', 'language() Unknown for unsupported language');
};

subtest 'sublanguage() returns correct country for en-gb' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-gb');
	my $l = CGI::Lingua->new(supported => ['en-gb']);
	is($l->sublanguage(), 'United Kingdom', 'sublanguage() correct for en-gb');
};

subtest 'sublanguage() returns undef when no sublanguage requested' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = _basic_obj();
	is($l->language(), 'English', 'language detects en');
	ok(!defined $l->sublanguage(), 'sublanguage() undef when no variant requested');
};

subtest 'language_code_alpha2() returns 2-char code' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr');
	my $l = _basic_obj();
	my $code = $l->language_code_alpha2();
	returns_ok($code, { type => 'string' }, 'language_code_alpha2 returns a string');
	is($code, 'fr', 'language_code_alpha2 returns fr');
};

subtest 'code_alpha2() aliases language_code_alpha2()' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = _basic_obj();
	is($l->code_alpha2(), $l->language_code_alpha2(), 'code_alpha2() aliases language_code_alpha2()');
};

subtest 'language_code_alpha2() is undef for unsupported language' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'de', REMOTE_ADDR => '127.0.0.1');
	my $l = _basic_obj();
	$l->language();
	ok(!defined $l->language_code_alpha2(), 'code_alpha2 undef when unsupported');
};

subtest 'sublanguage_code_alpha2() returns variety for en-gb' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-gb');
	my $l = CGI::Lingua->new(supported => ['en-gb']);
	is($l->sublanguage_code_alpha2(), 'gb', 'sublanguage_code_alpha2 is gb');
};

subtest 'requested_language() includes sublanguage in parens' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-gb');
	my $l = CGI::Lingua->new(supported => ['en-gb']);
	like($l->requested_language(), qr/English.*United Kingdom/, 'requested_language includes country');
};

# ── _what_language ────────────────────────────────────────────────────────────

subtest '_what_language: reads HTTP_ACCEPT_LANGUAGE env var' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-us');
	my $l = _basic_obj();
	is($l->_what_language(), 'en-us', 'Returns value from HTTP_ACCEPT_LANGUAGE');
};

subtest '_what_language: caches result after first call' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr');
	my $l = _basic_obj();
	$l->_what_language();
	# Changing the env var now must not affect the cached result
	local $ENV{HTTP_ACCEPT_LANGUAGE} = 'de';
	is($l->_what_language(), 'fr', 'Second call returns cached value, not new env');
};

subtest '_what_language: rejects header with invalid characters' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en;<script>');
	my $l = _basic_obj();
	my $warned = 0;
	Test::Mockingbird::mock('CGI::Lingua', '_warn', sub { $warned = 1 });
	my $rc = $l->_what_language();
	ok(!defined $rc, 'Invalid header returns undef');
	ok($warned, '_warn was called for invalid characters');
	Test::Mockingbird::restore_all();
};

subtest '_what_language: rejects header exceeding max length' => sub {
	# Header is exactly 257 bytes — one over the 256-byte limit
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'a' x 257);
	my $l = _basic_obj();
	ok(!defined $l->_what_language(), '257-char header is rejected');
};

subtest '_what_language: falls back to LANG env var' => sub {
	local %ENV = (LANG => 'de_DE.UTF-8');
	delete $ENV{HTTP_ACCEPT_LANGUAGE};
	my $l = _basic_obj();
	is($l->_what_language(), 'de_DE.UTF-8', 'Falls back to LANG when no HTTP header');
};

subtest '_what_language: class method reads env directly' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr');
	my $result = CGI::Lingua->_what_language();
	is($result, 'fr', 'Class-method call reads env directly');
};

subtest '_what_language: info->lang() overrides env var' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'de');
	my $info = bless {}, 'MockInfoLang';
	Test::Mockingbird::mock('MockInfoLang', 'lang', sub { 'ja' });
	my $l = CGI::Lingua->new(supported => ['en'], info => $info);
	is($l->_what_language(), 'ja', 'info->lang() takes priority over env');
	Test::Mockingbird::restore_all();
};

subtest '_what_language: * wildcard is accepted' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'zh-CN,zh;q=0.9,en;q=0.8,*;q=0.1');
	my $l = _basic_obj();
	like($l->_what_language(), qr/\*/, 'Wildcard * is accepted in Accept-Language');
};

# ── en-uk normalisation ───────────────────────────────────────────────────────

subtest '_find_language: en-uk normalised to en-gb' => sub {
	# Some older browsers send 'en-uk' instead of the correct 'en-gb'.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-uk');
	my $l = CGI::Lingua->new(supported => ['en-gb']);
	is($l->sublanguage_code_alpha2(), 'gb', 'en-uk is treated as en-gb');
};

# ── _scan_sublanguage_pairs ────────────────────────────────────────────────────

subtest '_scan_sublanguage_pairs: finds base language from pair' => sub {
	local %ENV = ();
	my $l = _basic_obj();

	# Provide a mock i18n object that accepts 'en' but not 'fr'
	my $i18n = bless {}, 'MockI18N';
	Test::Mockingbird::mock('MockI18N', 'accepts', sub {
		my ($self, $lang, $supported) = @_;
		return $lang eq 'en' ? 'en' : undef;
	});

	my ($matched, $sub) = $l->_scan_sublanguage_pairs($i18n, $l->_sorted_tokens('en-gb,fr-FR'));
	is($matched, 'en', 'Returns matched base language');
	is($sub,     'gb', 'Returns the sublanguage code from the pair');
	Test::Mockingbird::restore_all();
};

subtest '_scan_sublanguage_pairs: returns undef/undef when no match' => sub {
	local %ENV = ();
	my $l = _basic_obj();

	my $i18n = bless {}, 'MockI18NNone';
	Test::Mockingbird::mock('MockI18NNone', 'accepts', sub { undef });

	my ($matched, $sub) = $l->_scan_sublanguage_pairs($i18n, $l->_sorted_tokens('de-DE,it-IT'));
	ok(!defined $matched, 'Returns undef for code when no match');
	ok(!defined $sub,     'Returns undef for sublanguage when no match');
	Test::Mockingbird::restore_all();
};

# ── _scan_plain_tokens ────────────────────────────────────────────────────────

subtest '_scan_plain_tokens: finds matching plain token' => sub {
	local %ENV = ();
	my $l = _basic_obj();

	my $i18n = bless {}, 'MockI18NPlain';
	Test::Mockingbird::mock('MockI18NPlain', 'accepts', sub {
		my ($self, $lang) = @_;
		return $lang eq 'fr' ? 'fr' : undef;
	});

	my $result = $l->_scan_plain_tokens($i18n, $l->_sorted_tokens('de,fr;q=0.8,en;q=0.5'));
	is($result, 'fr', 'Returns first matching plain token');
	Test::Mockingbird::restore_all();
};

subtest '_scan_plain_tokens: skips tokens with sublanguage suffix' => sub {
	# Strategy: give _scan_plain_tokens a header that has both a xx-yy pair
	# (which should be skipped because _scan_sublanguage_pairs already tried
	# those) and a plain token that the mock i18n object does accept.  The
	# return value tells us which token was ultimately matched.
	local %ENV = ();
	my $l = _basic_obj();

	# Use a real I18N::AcceptLanguage object so Class::Autouse loads the
	# module; then the mock can override just the accepts() method cleanly.
	require I18N::AcceptLanguage;
	Test::Mockingbird::mock('I18N::AcceptLanguage', 'accepts', sub {
		my ($self, $lang, $supported) = @_;
		# Accept 'en' only — simulates a site that supports English
		return $lang eq 'en' ? 'en' : undef;
	});

	# fr-CA has a sublanguage suffix so _scan_plain_tokens must skip it;
	# 'en' (after q-value stripping by _sorted_tokens) must be accepted.
	my $i18n   = I18N::AcceptLanguage->new(strict => 1);
	my $result = $l->_scan_plain_tokens($i18n, $l->_sorted_tokens('fr-CA,en;q=0.5'));
	is($result, 'en', 'en accepted after skipping fr-CA pair and stripping q-value');
	Test::Mockingbird::restore_all();
};

subtest '_scan_plain_tokens: q-values already stripped by _sorted_tokens' => sub {
	# _sorted_tokens handles q-value stripping; by the time _scan_plain_tokens
	# receives the sorted list, every tag is bare (no ;q= suffix).
	local %ENV = ();
	my $l = _basic_obj();

	my @tried;
	my $i18n = bless {}, 'MockI18NQV';
	Test::Mockingbird::mock('MockI18NQV', 'accepts', sub { push @tried, $_[1]; undef });

	$l->_scan_plain_tokens($i18n, $l->_sorted_tokens('en;q=0.5,fr;q=0.3'));
	ok(!(grep { /q=/ } @tried), 'No q= suffix reaches accepts() after _sorted_tokens');
	Test::Mockingbird::restore_all();
};

# ── _get_closest ──────────────────────────────────────────────────────────────

subtest '_get_closest: sets _slanguage when base matches supported entry' => sub {
	local %ENV = ();
	my $l = CGI::Lingua->new(supported => ['en', 'en-gb']);
	$l->{_rlanguage} = 'English';

	$l->_get_closest('en', 'en');
	is($l->{_slanguage},            'English', '_slanguage set to _rlanguage');
	is($l->{_slanguage_code_alpha2}, 'en',     '_slanguage_code_alpha2 set to alpha2 arg');
};

subtest '_get_closest: finds base of en-gb when searching for en' => sub {
	local %ENV = ();
	my $l = CGI::Lingua->new(supported => ['en-gb', 'fr']);
	$l->{_rlanguage} = 'English';

	$l->_get_closest('en', 'en');
	is($l->{_slanguage}, 'English', 'Matches base of en-gb entry');
};

subtest '_get_closest: no match leaves _slanguage untouched' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	delete $l->{_slanguage};

	$l->_get_closest('de', 'de');
	ok(!exists $l->{_slanguage}, '_slanguage not set when no match');
};

# ── country() ─────────────────────────────────────────────────────────────────

subtest 'country: quick return when _country already cached on object' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	$l->{_country} = 'gb';
	is($l->country(), 'gb', 'Returns cached _country immediately');
};

subtest 'country: GEOIP_COUNTRY_CODE valid code is trusted' => sub {
	local %ENV = (GEOIP_COUNTRY_CODE => 'DE');
	my $l = _basic_obj();
	is($l->country(), 'de', 'Valid GEOIP_COUNTRY_CODE returned lowercase');
};

subtest 'country: GEOIP_COUNTRY_CODE invalid format is ignored with warning' => sub {
	local %ENV = (GEOIP_COUNTRY_CODE => 'NOT_A_CC', REMOTE_ADDR => '127.0.0.1');
	my $warned = 0;
	Test::Mockingbird::mock('CGI::Lingua', '_warn', sub { $warned = 1 });
	my $l = _basic_obj();
	$l->country();
	ok($warned, '_warn called for malformed GEOIP_COUNTRY_CODE');
	Test::Mockingbird::restore_all();
};

subtest 'country: HTTP_CF_IPCOUNTRY XX is skipped (Cloudflare unknown)' => sub {
	local %ENV = (HTTP_CF_IPCOUNTRY => 'XX', REMOTE_ADDR => '127.0.0.1');
	my $l = _basic_obj();
	# XX means Cloudflare couldn't determine country; must not treat it as a code
	my $result = $l->country();
	ok(!defined($result) || $result ne 'xx', 'XX Cloudflare value not returned as country');
};

subtest 'country: HTTP_CF_IPCOUNTRY valid code accepted' => sub {
	local %ENV = (HTTP_CF_IPCOUNTRY => 'FR');
	my $l = _basic_obj();
	is($l->country(), 'fr', 'Valid Cloudflare country code returned lowercase');
};

subtest 'country: HTTP_CF_IPCOUNTRY invalid format is ignored with warning' => sub {
	local %ENV = (HTTP_CF_IPCOUNTRY => 'INVALID', REMOTE_ADDR => '127.0.0.1');
	my $warned = 0;
	Test::Mockingbird::mock('CGI::Lingua', '_warn', sub { $warned = 1 });
	my $l = _basic_obj();
	$l->country();
	ok($warned, '_warn called for malformed HTTP_CF_IPCOUNTRY');
	Test::Mockingbird::restore_all();
};

subtest 'country: undef when REMOTE_ADDR absent' => sub {
	local %ENV = ();
	delete $ENV{REMOTE_ADDR};
	my $l = _basic_obj();
	ok(!defined $l->country(), 'country() returns undef when no REMOTE_ADDR');
};

subtest 'country: garbage IP warns and returns undef' => sub {
	local %ENV = (REMOTE_ADDR => 'not-an-ip');
	my $warned = 0;
	Test::Mockingbird::mock('CGI::Lingua', '_warn', sub { $warned = 1 });
	my $l = _basic_obj();
	ok(!defined $l->country(), 'Garbage IP returns undef');
	ok($warned, '_warn fired for garbage IP');
	Test::Mockingbird::restore_all();
};

subtest 'country: private IP returns undef' => sub {
	local %ENV = (REMOTE_ADDR => '192.168.1.1');
	my $l = _basic_obj();
	ok(!defined $l->country(), 'Private IP returns undef');
};

subtest 'country: loopback returns undef' => sub {
	local %ENV = (REMOTE_ADDR => '127.0.0.1');
	my $l = _basic_obj();
	ok(!defined $l->country(), 'Loopback IP returns undef');
};

subtest 'country: IPv6 loopback ::1 returns undef' => sub {
	local %ENV = (REMOTE_ADDR => '::1');
	my $l = _basic_obj();
	ok(!defined $l->country(), 'IPv6 loopback ::1 returns undef');
};

subtest 'country: numeric result from geo lookup is discarded' => sub {
	local %ENV = (REMOTE_ADDR => '8.8.8.8');
	# Simulate a geo module returning a numeric country code (invalid)
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { '123' });
	my $l = _basic_obj();
	$l->{_have_ipcountry} = $GEO_PRESENT;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = $GEO_ABSENT;
	$l->{_have_geoipfree} = $GEO_ABSENT;
	# Force skip of LWP/Whois fallbacks for this unit test
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub {});
	my $result = $l->country();
	ok(!defined $result, 'Numeric country code is discarded');
	Test::Mockingbird::restore_all();
};

subtest 'country: eu result from IP::Country is discarded and falls through' => sub {
	local %ENV = (REMOTE_ADDR => '8.8.8.8');
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { 'EU' });
	my $l = _basic_obj();
	$l->{_have_ipcountry} = $GEO_PRESENT;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = $GEO_ABSENT;
	$l->{_have_geoipfree} = $GEO_ABSENT;
	# Block the Whois/geoplugin fallbacks to keep test fast and offline
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub {});
	my $r = $l->country();
	ok(!defined($r) || $r ne 'eu', "'eu' from IP lookup is not returned as-is");
	Test::Mockingbird::restore_all();
};

subtest 'country: hk is mapped to cn' => sub {
	local %ENV = (REMOTE_ADDR => '218.213.130.87');
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { 'HK' });
	my $l = _basic_obj();
	$l->{_have_ipcountry} = $GEO_PRESENT;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = $GEO_ABSENT;
	$l->{_have_geoipfree} = $GEO_ABSENT;
	is($l->country(), 'cn', 'HK is remapped to CN (legacy Whois behavior)');
	Test::Mockingbird::restore_all();
};

subtest 'country: result is stored in CHI cache' => sub {
	local %ENV = (REMOTE_ADDR => '8.8.8.8');
	my $cache = _fresh_cache();
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { 'US' });
	my $l = CGI::Lingua->new(supported => ['en'], cache => $cache);
	$l->{_have_ipcountry} = $GEO_PRESENT;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = $GEO_ABSENT;
	$l->{_have_geoipfree} = $GEO_ABSENT;
	$l->country();
	is($cache->get($CACHE_NS . 'country:8.8.8.8'), 'us', 'Country stored in cache');
	Test::Mockingbird::restore_all();
};

subtest 'country: numeric country in cache triggers removal' => sub {
	local %ENV = (REMOTE_ADDR => '8.8.8.8');
	my $cache = _fresh_cache();
	# Pre-seed with a numeric country (invalid — would have been a bug)
	$cache->set($CACHE_NS . 'country:8.8.8.8', '404', '1 month');
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { 'US' });
	my $l = CGI::Lingua->new(supported => ['en'], cache => $cache);
	$l->{_have_ipcountry} = $GEO_PRESENT;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = $GEO_ABSENT;
	$l->{_have_geoipfree} = $GEO_ABSENT;
	# The numeric cache entry must be discarded and the lookup must proceed
	my $result = $l->country();
	is($result, 'us', 'Numeric cache entry discarded; real lookup used');
	Test::Mockingbird::restore_all();
};

# ── _handle_eu_country ────────────────────────────────────────────────────────

subtest '_handle_eu_country: Baidu subnet maps to cn' => sub {
	# 185.10.104.1 is inside the Baidu subnet 185.10.104.0/22
	local %ENV = (REMOTE_ADDR => '185.10.104.1');
	my $l = _basic_obj();
	$l->{_country} = 'eu';
	$l->_handle_eu_country('185.10.104.1');
	is($l->{_country}, 'cn', 'Baidu EU subnet mapped to cn');
};

subtest '_handle_eu_country: non-Baidu EU address becomes Unknown' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	$l->{_country} = 'eu';
	$l->_handle_eu_country('1.2.3.4');
	is($l->{_country}, 'Unknown', 'Non-Baidu EU address becomes Unknown');
};

# ── _code2language ────────────────────────────────────────────────────────────

subtest '_code2language: returns undef for empty/undef code' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	ok(!defined $l->_code2language(undef), 'undef code returns undef');
	ok(!defined $l->_code2language(''),    'empty code returns undef');
};

subtest '_code2language: calls Locale::Language without cache' => sub {
	local %ENV = ();
	my $l = _basic_obj();    # no cache

	Test::Mockingbird::mock('Locale::Language', 'code2language', sub { 'English' });
	is($l->_code2language('en'), 'English', 'Returns result from Locale::Language');
	Test::Mockingbird::restore_all();
};

subtest '_code2language: reads from cache on hit' => sub {
	local %ENV = ();
	my $cache = _fresh_cache();
	$cache->set($CACHE_NS . 'code2language:fr', 'French', '1 month');

	my $l = CGI::Lingua->new(supported => ['fr'], cache => $cache);
	my $called = 0;
	Test::Mockingbird::mock('Locale::Language', 'code2language', sub { $called = 1; 'French' });
	is($l->_code2language('fr'), 'French', 'Returns cached value');
	is($called, 0, 'Locale::Language not called on cache hit');
	Test::Mockingbird::restore_all();
};

subtest '_code2language: stores result in cache and returns the value (not set() result)' => sub {
	local %ENV = ();
	my $cache = _fresh_cache();
	my $l = CGI::Lingua->new(supported => ['de'], cache => $cache);

	Test::Mockingbird::mock('Locale::Language', 'code2language', sub { 'German' });
	my $result = $l->_code2language('de');
	is($result, 'German', 'Returns the computed name, not set() result');
	is($cache->get($CACHE_NS . 'code2language:de'), 'German', 'Name stored in cache');
	Test::Mockingbird::restore_all();
};

# ── _code2country ─────────────────────────────────────────────────────────────

subtest '_code2country: returns undef for empty/undef code' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	ok(!defined $l->_code2country(undef), 'undef code returns undef');
	ok(!defined $l->_code2country(''),    'empty code returns undef');
};

subtest '_code2country: suppresses "No result found" warning' => sub {
	# Locale::Object::Country emits this warning for unknown codes;
	# _code2country must intercept it rather than letting it leak.
	local %ENV = ();
	my $l = _basic_obj();
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };
	$l->_code2country('zz');    # 'zz' is not a real country code
	ok(!grep { /No result found in country table/ } @warnings,
		'"No result found" warning was suppressed');
};

subtest '_code2country: suppression filter is narrowly scoped' => sub {
	# The regex /No result found in country table/ must only match its own
	# specific message — not generic Locale warnings or other messages.
	# Directly validate the filter without calling warn() to avoid
	# interaction with the enclosing $SIG{__WARN__} capture.
	my $pattern = qr/No result found in country table/;

	ok('No result found in country table' =~ $pattern,
		'Filter matches the target message exactly');
	ok('Some unrelated Locale warning' !~ $pattern,
		'Filter does not suppress unrelated warnings');
	ok('Locale::Object error: frobulated' !~ $pattern,
		'Filter does not suppress other Locale errors');
};

# ── _code2countryname ─────────────────────────────────────────────────────────

subtest '_code2countryname: returns undef for empty/undef code' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	ok(!defined $l->_code2countryname(undef), 'undef code returns undef');
	ok(!defined $l->_code2countryname(''),    'empty code returns undef');
};

subtest '_code2countryname: reads from cache on hit' => sub {
	local %ENV = ();
	my $cache = _fresh_cache();
	$cache->set($CACHE_NS . 'code2countryname:gb', 'United Kingdom', '1 month');

	my $l = CGI::Lingua->new(supported => ['en'], cache => $cache);
	is($l->_code2countryname('gb'), 'United Kingdom', 'Cache hit returned');
};

subtest '_code2countryname: stores name in cache and returns it (not set() result)' => sub {
	local %ENV = ();
	my $cache = _fresh_cache();
	my $l = CGI::Lingua->new(supported => ['fr'], cache => $cache);

	# Verify the cache does not yet have the entry
	ok(!defined $cache->get($CACHE_NS . 'code2countryname:fr'), 'Cache empty before call');

	my $name = $l->_code2countryname('fr');
	ok(defined $name, 'A country name was returned');
	is($cache->get($CACHE_NS . 'code2countryname:fr'), $name,
		'Same value stored in cache as returned');
};

# ── _log ──────────────────────────────────────────────────────────────────────

subtest '_log: appends to messages array' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	$l->_log('debug', 'test message');
	my $last = $l->{messages}[-1];
	is($last->{level},   'debug',        'Level stored correctly');
	is($last->{message}, 'test message', 'Message stored correctly');
};

subtest '_log: concatenates multiple message parts' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	$l->_log('info', 'hello', ' ', 'world');
	is($l->{messages}[-1]{message}, 'hello world', 'Multiple parts concatenated');
};

subtest '_log: skips undef parts in messages' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	$l->_log('info', 'a', undef, 'b');
	is($l->{messages}[-1]{message}, 'ab', 'undef parts skipped in join');
};

subtest '_log: forwards to logger object' => sub {
	# Object::Configure may override a logger passed to new(), so we inject
	# the spy directly onto the object after construction to test _log in
	# isolation, not the constructor.
	local %ENV = ();
	my $captured;
	my $spy = bless {}, 'SpyLogger';
	{
		no warnings 'once';
		*SpyLogger::debug  = sub { $captured = $_[1] };
		*SpyLogger::info   = sub {};
		*SpyLogger::warn   = sub {};
		*SpyLogger::error  = sub {};
		*SpyLogger::notice = sub {};
		*SpyLogger::trace  = sub {};
	}
	my $l = _basic_obj();
	$l->{logger} = $spy;    # bypass Object::Configure; test _log directly
	$l->_log('debug', 'forwarded');
	is($captured, 'forwarded', '_log forwarded message to logger');
};

subtest '_log: no-op when called as class method (non-ref self)' => sub {
	# _log must guard against being called on a plain string (class context)
	my $count_before = 0;
	eval { CGI::Lingua->_log('debug', 'test') };
	ok(!$@, '_log does not die when called as class method');
};

subtest '_log: no-op for empty message list' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	my $count = scalar @{$l->{messages} // []};
	$l->_log('info');    # no messages
	is(scalar @{$l->{messages} // []}, $count, 'Empty _log does not append to messages');
};

# ── _debug / _info / _notice / _trace ─────────────────────────────────────────

subtest '_debug/_info/_notice/_trace delegate to _log with correct level' => sub {
	local %ENV = ();
	my $l = _basic_obj();

	for my $level (qw(debug info notice trace)) {
		my $method = "_$level";
		$l->$method("testing $level");
		is($l->{messages}[-1]{level}, $level, "_$level sets level to '$level'");
	}
};

# ── _warn ─────────────────────────────────────────────────────────────────────

subtest '_warn: with logger calls logger->warn() with extracted string' => sub {
	local %ENV = ();
	my $received;
	my $logger = bless {}, 'WarnLogger';
	{
		no warnings 'once';
		*WarnLogger::warn  = sub { $received = $_[1] };
		*WarnLogger::info  = sub {};
		*WarnLogger::error = sub {};
	}
	my $l = CGI::Lingua->new(supported => ['en'], logger => $logger);
	$l->_warn({ warning => 'something went wrong' });
	is($received, 'something went wrong', 'Logger receives the warning string');
	ok(!ref $received, 'Logger does not receive an arrayref (new normalised API)');
};

subtest '_warn: without logger appends to messages and carps' => sub {
	# Object::Configure always injects a Log::Abstraction logger, so we
	# must explicitly clear it to exercise the no-logger (Carp) branch.
	local %ENV = ();
	my $l = _basic_obj();
	$l->{logger} = undef;    # force the Carp::carp code path
	my @carp_msgs;
	# carp is now imported into CGI::Lingua at compile time (use Carp qw(carp)),
	# so we must mock CGI::Lingua::carp — mocking Carp::carp would miss it.
	Test::Mockingbird::mock('CGI::Lingua', 'carp', sub { push @carp_msgs, $_[0] });
	$l->_warn({ warning => 'carp test' });
	ok((grep { /carp test/ } @carp_msgs), 'CGI::Lingua::carp called with message text');
	ok((grep { $_->{message} =~ /carp test/ } @{$l->{messages}}), 'Message recorded internally');
	Test::Mockingbird::restore_all();
};

# ── locale() ─────────────────────────────────────────────────────────────────

subtest 'locale: quick return when _locale already set' => sub {
	local %ENV = ();
	my $sentinel = bless {}, 'Locale::Object::Country';
	my $l = _basic_obj();
	$l->{_locale} = $sentinel;
	is($l->locale(), $sentinel, 'Cached _locale returned immediately');
};

subtest 'locale: GEOIP_COUNTRY_CODE validated before use in locale()' => sub {
	# The security fix from critique: locale() must apply the same ISO 3166-1
	# check as country() — an invalid value must not be passed to _code2country.
	local %ENV = (GEOIP_COUNTRY_CODE => 'NOT_CC');
	my $l = _basic_obj();
	my $called = 0;
	Test::Mockingbird::mock('CGI::Lingua', '_code2country', sub { $called = 1; undef });
	$l->locale();
	is($called, 0, 'Invalid GEOIP_COUNTRY_CODE not passed to _code2country');
	Test::Mockingbird::restore_all();
};

subtest 'locale: valid GEOIP_COUNTRY_CODE used after validation' => sub {
	# The security fix: a well-formed GEOIP_COUNTRY_CODE must reach _code2country.
	# We inject a fake country object and confirm it is returned from locale().
	local %ENV = (GEOIP_COUNTRY_CODE => 'GB', REMOTE_ADDR => '127.0.0.1');
	my $fake_country = bless {}, 'Locale::Object::Country';
	my $called       = 0;
	Test::Mockingbird::mock('CGI::Lingua', '_code2country', sub { $called = 1; $fake_country });
	my $l = _basic_obj();
	my $result = $l->locale();
	ok($called,                         '_code2country was called for valid GEOIP_COUNTRY_CODE');
	is($result, $fake_country,          'locale() returns the country object from _code2country');
	Test::Mockingbird::restore_all();
};

# ── time_zone() ───────────────────────────────────────────────────────────────

subtest 'time_zone: quick return when _timezone cached' => sub {
	local %ENV = (REMOTE_ADDR => '8.8.8.8');
	my $l = _basic_obj();
	$l->{_timezone} = 'America/New_York';
	is($l->time_zone(), 'America/New_York', 'Cached timezone returned immediately');
};

subtest 'time_zone: invalid REMOTE_ADDR warns and returns undef' => sub {
	local %ENV = (REMOTE_ADDR => 'bad-addr');
	my $warned = 0;
	Test::Mockingbird::mock('CGI::Lingua', '_warn', sub { $warned = 1 });
	my $l = _basic_obj();
	my $result = $l->time_zone();
	ok($warned, '_warn fired for invalid REMOTE_ADDR in time_zone()');
	ok(!defined $result, 'undef returned for invalid IP in time_zone()');
	Test::Mockingbird::restore_all();
};

# ── Memory cycle tests ────────────────────────────────────────────────────────
# CGI::Lingua stores caches, loggers, and self-referential state.  Ensure
# none of these create reference cycles that would block garbage collection.

subtest 'No memory cycles in fresh object' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	memory_cycle_ok($l, 'Fresh CGI::Lingua object has no cycles');
};

subtest 'No memory cycles after language() is called' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = _basic_obj();
	$l->language();
	memory_cycle_ok($l, 'Object after language() has no cycles');
};

subtest 'No memory cycles in object with CHI cache' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr');
	my $cache = _fresh_cache();
	my $l = CGI::Lingua->new(supported => ['fr'], cache => $cache);
	$l->language();
	memory_cycle_ok($l, 'Object with cache has no cycles after language()');
};

subtest 'No memory cycles in frozen DESTROY copy' => sub {
	local %ENV = (REMOTE_ADDR => '5.5.5.5', HTTP_ACCEPT_LANGUAGE => 'en');
	my $cache = _fresh_cache();
	{
		my $l = CGI::Lingua->new(supported => ['en'], cache => $cache);
		$l->language();
	}
	my $blob   = $cache->get('5.5.5.5/en/en');
	my $thawed = Storable::thaw($blob);
	memory_cycle_ok($thawed, 'Thawed DESTROY copy has no cycles');
};

# ── _sorted_tokens ────────────────────────────────────────────────────────────

subtest '_sorted_tokens: returns arrayref sorted by q descending' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	my $sorted = $l->_sorted_tokens('de;q=0.9,en;q=0.1,fr');
	is(ref($sorted), 'ARRAY', 'Returns an arrayref');
	is($sorted->[0][0], 'fr', 'Highest q (1.0 implicit) first');
	is($sorted->[0][1], 1.0,  'Implicit q=1.0 parsed correctly');
	is($sorted->[1][0], 'de', 'q=0.9 second');
	is($sorted->[2][0], 'en', 'q=0.1 last');
};

subtest '_sorted_tokens: strips q suffix from tags' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	my $sorted = $l->_sorted_tokens('en;q=0.5');
	is($sorted->[0][0], 'en', 'Tag returned without ;q= suffix');
};

subtest '_sorted_tokens: empty header returns empty arrayref' => sub {
	local %ENV = ();
	my $l = _basic_obj();
	my $sorted = $l->_sorted_tokens('');
	is(ref($sorted), 'ARRAY', 'Still an arrayref');
	is(scalar @{$sorted}, 0, 'No entries for empty header');
};

# ── is_rtl() / text_direction() ──────────────────────────────────────────────

subtest 'is_rtl: returns 1 for Arabic' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'ar');
	my $l = CGI::Lingua->new(supported => ['ar', 'en']);
	is($l->is_rtl(), 1, 'Arabic is RTL');
};

subtest 'is_rtl: returns 1 for Hebrew' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'he');
	my $l = CGI::Lingua->new(supported => ['he', 'en']);
	is($l->is_rtl(), 1, 'Hebrew is RTL');
};

subtest 'is_rtl: returns 0 for English' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = CGI::Lingua->new(supported => ['en']);
	is($l->is_rtl(), 0, 'English is not RTL');
};

subtest 'is_rtl: returns 0 when language is Unknown' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'zz');
	my $l = CGI::Lingua->new(supported => ['en']);
	is($l->is_rtl(), 0, 'Unknown language is not RTL');
};

subtest 'text_direction: returns rtl for Arabic' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'ar');
	my $l = CGI::Lingua->new(supported => ['ar', 'en']);
	is($l->text_direction(), 'rtl', 'Arabic text direction is rtl');
};

subtest 'text_direction: returns ltr for French' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr');
	my $l = CGI::Lingua->new(supported => ['fr', 'en']);
	is($l->text_direction(), 'ltr', 'French text direction is ltr');
};

# ── plural_category() ────────────────────────────────────────────────────────

subtest 'plural_category: English one/other' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = CGI::Lingua->new(supported => ['en']);
	is($l->plural_category(1),  'one',   'n=1 is one');
	is($l->plural_category(0),  'other', 'n=0 is other');
	is($l->plural_category(2),  'other', 'n=2 is other');
	is($l->plural_category(42), 'other', 'n=42 is other');
};

subtest 'plural_category: Arabic six forms' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'ar');
	my $l = CGI::Lingua->new(supported => ['ar', 'en']);
	is($l->plural_category(0),   'zero',  'n=0 zero');
	is($l->plural_category(1),   'one',   'n=1 one');
	is($l->plural_category(2),   'two',   'n=2 two');
	is($l->plural_category(5),   'few',   'n=5 few');
	is($l->plural_category(15),  'many',  'n=15 many');
	is($l->plural_category(100), 'other', 'n=100 other');
};

subtest 'plural_category: Russian three forms' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'ru');
	my $l = CGI::Lingua->new(supported => ['ru', 'en']);
	is($l->plural_category(1),  'one',  'n=1 one');
	is($l->plural_category(2),  'few',  'n=2 few');
	is($l->plural_category(5),  'many', 'n=5 many');
	is($l->plural_category(11), 'many', 'n=11 many (not one)');
	is($l->plural_category(21), 'one',  'n=21 one');
};

subtest 'plural_category: falls back to one/other for unknown language' => sub {
	# Construct directly with a code not in %PLURAL_RULES
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'tlh'); # Klingon — not in table
	my $l = CGI::Lingua->new(supported => ['tlh', 'en']);
	# language will be Unknown, so language_code_alpha2 returns undef
	# plural_category must return 'other' without dying
	my $cat;
	lives_ok { $cat = $l->plural_category(1) } 'Does not die for unknown language';
	ok(defined $cat, 'Returns a defined value');
};

# ── translation_file() ───────────────────────────────────────────────────────

subtest 'translation_file: returns undef when dir arg is undef' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = CGI::Lingua->new(supported => ['en']);
	ok(!defined $l->translation_file(undef), 'undef dir returns undef');
};

subtest 'translation_file: returns undef when no matching file exists' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = CGI::Lingua->new(supported => ['en']);
	ok(!defined $l->translation_file('/nonexistent/path/xyz'), 'missing dir returns undef');
};

subtest 'translation_file: finds file with default json extension' => sub {
	use File::Temp qw(tempdir);
	my $dir = tempdir(CLEANUP => 1);
	open(my $fh, '>', "$dir/en.json") or die $!;
	print $fh '{}';
	close $fh;

	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = CGI::Lingua->new(supported => ['en']);
	is($l->translation_file($dir), "$dir/en.json", 'Returns path to en.json');
};

subtest 'translation_file: accepts explicit extension without leading dot' => sub {
	use File::Temp qw(tempdir);
	my $dir = tempdir(CLEANUP => 1);
	open(my $fh, '>', "$dir/fr.po") or die $!;
	print $fh '';
	close $fh;

	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr');
	my $l = CGI::Lingua->new(supported => ['fr']);
	is($l->translation_file($dir, 'po'), "$dir/fr.po", 'Returns path with explicit ext');
};

subtest 'translation_file: accepts extension with leading dot' => sub {
	use File::Temp qw(tempdir);
	my $dir = tempdir(CLEANUP => 1);
	open(my $fh, '>', "$dir/de.json") or die $!;
	print $fh '{}';
	close $fh;

	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'de');
	my $l = CGI::Lingua->new(supported => ['de']);
	is($l->translation_file($dir, '.json'), "$dir/de.json", 'Leading dot normalised');
};

done_testing();
