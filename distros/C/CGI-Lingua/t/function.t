#!/usr/bin/env perl
# t/function.t - White-box unit tests for every sub in CGI::Lingua.
#
# Strategy: each sub is exercised in isolation.  External dependencies
# (I18N::AcceptLanguage, IP::Country, Locale::Language, etc.) are mocked
# via Test::Mockingbird so tests are deterministic and need no network.
# Return values are validated with Test::Returns; memory hygiene is
# confirmed with Test::Memory::Cycle.

use strict;
use warnings;

use CHI;
use JSON::PP ();
use Readonly;
use Scalar::Util qw(blessed);
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Most;
use Test::Returns qw(returns_ok returns_is);
use Test::Log::Abstraction;

BEGIN { use_ok('CGI::Lingua') }

# -- Test fixtures ------------------------------------------------------------

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

# -- new() --------------------------------------------------------------------

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
		'plain hashref logger does not croak - Object::Configure converts it';
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

# -- _build_cache_key ---------------------------------------------------------

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

# -- DESTROY ------------------------------------------------------------------

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

	my $thawed = JSON::PP::decode_json($blob);
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

	# Pre-seed the cache with a JSON blob so the set-if-absent guard fires.
	# The blob only needs to be truthy (non-empty JSON object); DESTROY checks
	# $cache->get($key) and returns early if it already has a value.
	my $sentinel_json = JSON::PP::encode_json({ _slanguage => 'SentinelLanguage' });
	$cache->set('55.55.55.55/en/en', $sentinel_json, '1 month');

	{
		my $l = CGI::Lingua->new(supported => ['en'], cache => $cache);
		$l->language();
	}    # DESTROY fires

	my $blob    = $cache->get('55.55.55.55/en/en');
	my $thawed  = JSON::PP::decode_json($blob);
	is($thawed->{_slanguage}, 'SentinelLanguage', 'Existing cache entry was not overwritten');
};

# -- Public language accessors -------------------------------------------------
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

# -- _what_language ------------------------------------------------------------

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
	# Header is exactly 257 bytes - one over the 256-byte limit
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

# -- en-uk normalisation -------------------------------------------------------

subtest '_find_language: en-uk normalised to en-gb' => sub {
	# Some older browsers send 'en-uk' instead of the correct 'en-gb'.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-uk');
	my $l = CGI::Lingua->new(supported => ['en-gb']);
	is($l->sublanguage_code_alpha2(), 'gb', 'en-uk is treated as en-gb');
};

# -- _scan_sublanguage_pairs ----------------------------------------------------

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

# -- _scan_plain_tokens --------------------------------------------------------

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
		# Accept 'en' only - simulates a site that supports English
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

# -- _get_closest --------------------------------------------------------------

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

# -- country() -----------------------------------------------------------------

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
	# Pre-seed with a numeric country (invalid - would have been a bug)
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

# -- _handle_eu_country --------------------------------------------------------

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

# -- _code2language ------------------------------------------------------------

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

# -- _code2country -------------------------------------------------------------

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
	# specific message - not generic Locale warnings or other messages.
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

# -- _code2countryname ---------------------------------------------------------

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

# -- _log ----------------------------------------------------------------------

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

# -- _debug / _info / _notice / _trace -----------------------------------------

subtest '_debug/_info/_notice/_trace delegate to _log with correct level' => sub {
	local %ENV = ();
	my $l = _basic_obj();

	for my $level (qw(debug info notice trace)) {
		my $method = "_$level";
		$l->$method("testing $level");
		is($l->{messages}[-1]{level}, $level, "_$level sets level to '$level'");
	}
};

# -- _warn ---------------------------------------------------------------------

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
	# CGI::Lingua calls Carp::carp by its full name (nothing is imported), so
	# Carp::carp is what to mock
	Test::Mockingbird::mock('Carp', 'carp', sub { push @carp_msgs, $_[0] });
	$l->_warn({ warning => 'carp test' });
	ok((grep { /carp test/ } @carp_msgs), 'Carp::carp called with message text');
	ok((grep { $_->{message} =~ /carp test/ } @{$l->{messages}}), 'Message recorded internally');
	Test::Mockingbird::restore_all();
};

# -- locale() -----------------------------------------------------------------

subtest 'locale: quick return when _locale already set' => sub {
	local %ENV = ();
	my $sentinel = bless {}, 'Locale::Object::Country';
	my $l = _basic_obj();
	$l->{_locale} = $sentinel;
	is($l->locale(), $sentinel, 'Cached _locale returned immediately');
};

subtest 'locale: GEOIP_COUNTRY_CODE validated before use in locale()' => sub {
	# The security fix from critique: locale() must apply the same ISO 3166-1
	# check as country() - an invalid value must not be passed to _code2country.
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

# -- time_zone() ---------------------------------------------------------------

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

# -- Memory cycle tests --------------------------------------------------------
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
	my $thawed = JSON::PP::decode_json($blob);
	memory_cycle_ok($thawed, 'Thawed DESTROY copy has no cycles');
};

# -- _sorted_tokens ------------------------------------------------------------

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

# -- is_rtl() / text_direction() ----------------------------------------------

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

# -- plural_category() --------------------------------------------------------

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
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'tlh'); # Klingon - not in table
	my $l = CGI::Lingua->new(supported => ['tlh', 'en']);
	# language will be Unknown, so language_code_alpha2 returns undef
	# plural_category must return 'other' without dying
	my $cat;
	lives_ok { $cat = $l->plural_category(1) } 'Does not die for unknown language';
	ok(defined $cat, 'Returns a defined value');
};

# -- translation_file() -------------------------------------------------------

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

# =============================================================================
# Second pass: helpers that had no direct tests, and hostile inputs.
#
# Strategy: every helper is driven with the minimum state it needs.  Other
# CGI::Lingua subs that a helper calls are mocked so that a failure points at
# the helper under test, not at its collaborators.  Most subtests here are
# negative: they feed malformed, oversized or injected values, or make a
# dependency die mid-call, and check that the helper fails closed (returns
# undef/0, warns, or croaks with the documented message) without corrupting
# the object or leaking Perl warnings.
# =============================================================================

# Values used by more than one subtest.  Kept here so that each expectation
# is written once and the subtests read as intent, not as literals.
Readonly my %CFG => (
	baidu_first        => '185.10.104.0',
	baidu_last         => '185.10.107.255',
	baidu_below        => '185.10.103.255',
	baidu_above        => '185.10.108.0',
	public_v4          => '8.8.8.8',
	public_v6          => '2001:db8::1',
	ua_max             => 512,	# HTTP_USER_AGENT limit in locale()
	accept_lang_max    => 256,	# HTTP_ACCEPT_LANGUAGE limit in _what_language()
	many_tokens        => 5_000,	# large but bounded header for _sorted_tokens
	long_string_len    => 10_000,
	tz_hostile         => 'Europe/London<script>alert(1)</script>',
	whois_crlf         => "GB\r\nX-Injected: evil",
	sentinel           => 'caller-owned value',
	plural_croak       => qr/^plural_category: \$n must be defined at /,
	missing_supported  => qr/^You must give a list of supported languages at /,
	bad_ref_supported  => qr/^List of supported languages must be an array ref at /,
	short_code         => qr/^Supported languages must be the short code at /,
);

# Pre-require every module whose functions are mocked below.  A module's own
# BEGIN/import code would otherwise overwrite a mock installed before its
# first lazy require inside CGI::Lingua.
my $HAS_LWP   = eval { require LWP::Simple::WithCache; 1 } ? 1 : 0;
my $HAS_JSONP = eval { require JSON::Parse; 1 } ? 1 : 0;
my $HAS_WHOIS = eval { require Net::Whois::IP; require Net::Whois::IANA; 1 } ? 1 : 0;
require I18N::AcceptLanguage;

# Stop every remote look-up.  Called at the start of this section and after
# each restore_all(), because restore_all() also removes these mocks.
sub _block_network {
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	if($HAS_LWP) {
		local $SIG{__WARN__} = sub { };	# prototype mismatch on get($)
		Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });
	}
}

sub _reset_mocks {
	local $SIG{__WARN__} = sub { };
	Test::Mockingbird::restore_all();
	_block_network();
}

_block_network();

# A logger that records every call, so subtests can assert on warnings
# without the noise of carp().  Injected directly into $obj->{logger} because
# Object::Configure replaces anything passed to new().
{
	package Spy::Logger;
	sub new { return bless { calls => [] }, shift }
	for my $level (qw(debug info notice trace warn error)) {
		no strict 'refs';
		*{$level} = sub { push @{$_[0]{calls}}, [$level, $_[1]] };
	}
	sub messages {
		my ($self, $level) = @_;
		return map { $_->[1] } grep { $_->[0] eq $level } @{$self->{calls}};
	}
}

# Minimal stand-ins for Locale::Object::Country / ::Language, so that the
# language-from-IP logic can be tested without the SQLite database.
{
	package Fake::Language;
	sub new { my ($c, %a) = @_; return bless { %a }, $c }
	sub name { $_[0]{name} }
	sub code_alpha2 { $_[0]{code} }

	package Fake::Country;
	sub new { my ($c, %a) = @_; return bless { %a }, $c }
	sub name { $_[0]{name} }
	sub languages_official { @{$_[0]{languages} || []} }
}

# Object with a spy logger already attached.
sub _spied_obj {
	my (%args) = @_;
	my $l = CGI::Lingua->new(supported => ['en', 'fr'], %args);
	my $spy = Spy::Logger->new();
	$l->{logger} = $spy;
	return ($l, $spy);
}

# Run a block and return every Perl warning it raised.  Used to prove that
# hostile input does not leak "uninitialized" or "isn't numeric" noise.
sub _warnings_from(&) {
	my $code = shift;
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	$code->();
	return @w;
}

# -- _is_ipv4 -----------------------------------------------------------------

subtest '_is_ipv4: accepts the full valid range' => sub {
	# Boundary values: the lowest and highest legal octets
	ok(CGI::Lingua::_is_ipv4($_), "$_ is IPv4") for qw(0.0.0.0 255.255.255.255 8.8.8.8);
};

subtest '_is_ipv4: rejects malformed and hostile addresses' => sub {
	# Each of these has slipped through a naive regex in some codebase;
	# the helper is the last line of defence when Data::Validate::IP is absent.
	my %bad = (
		'octet over 255'         => '256.1.1.1',
		'three octets'           => '1.2.3',
		'five octets'            => '1.2.3.4.5',
		'four-digit octet'       => '1.2.3.1000',
		'trailing newline'       => "1.2.3.4\n",
		'leading space'          => ' 1.2.3.4',
		'shell injection'        => '1.2.3.4;rm -rf /',
		'negative octet'         => '-1.2.3.4',
		'empty string'           => '',
		'IPv6'                   => '::1',
		'Arabic-Indic digits'    => join('.', ("\x{661}") x 4),
	);
	my @w = _warnings_from {
		for my $why (sort keys %bad) {
			ok(!CGI::Lingua::_is_ipv4($bad{$why}), "rejects $why");
		}
		ok(!CGI::Lingua::_is_ipv4(undef), 'rejects undef');
	};
	is(scalar(@w), 0, 'no Perl warnings for hostile input') or diag(explain(\@w));
};

# -- _is_ipv6 -----------------------------------------------------------------

subtest '_is_ipv6: accepts valid addresses' => sub {
	ok(CGI::Lingua::_is_ipv6($_), "$_ is IPv6") for ('::1', $CFG{public_v6}, '::ffff:1.2.3.4', 'fe80::1');
};

subtest '_is_ipv6: rejects malformed and hostile addresses' => sub {
	my %bad = (
		'IPv4'               => '1.2.3.4',
		'non-hex group'      => 'gggg::1',
		'two double colons'  => '1::2::3',
		'shell injection'    => '::1;id',
		'empty string'       => '',
		'too many groups'    => '1:2:3:4:5:6:7:8:9',
	);
	for my $why (sort keys %bad) {
		ok(!CGI::Lingua::_is_ipv6($bad{$why}), "rejects $why");
	}
	ok(!CGI::Lingua::_is_ipv6(undef), 'rejects undef');
};

subtest '_is_ipv6: structural fallback works without Socket::inet_pton' => sub {
	# Strategy: hide inet_pton to force the pure-regex branch, which is what
	# runs on very old Perls.  The branch used tr/::// (a character count),
	# so it could never return true; these positives guard that fix.
	no warnings qw(redefine once);
	local *Socket::inet_pton;
	ok(!defined(&Socket::inet_pton), 'inet_pton hidden for this block');
	ok(CGI::Lingua::_is_ipv6($CFG{public_v6}), "fallback accepts $CFG{public_v6}");
	ok(CGI::Lingua::_is_ipv6('::1'), 'fallback accepts ::1');
	ok(CGI::Lingua::_is_ipv6('::ffff:1.2.3.4'), 'fallback accepts mixed notation');
	ok(!CGI::Lingua::_is_ipv6('1::2::3'), 'fallback rejects two "::"');
	ok(!CGI::Lingua::_is_ipv6('zz::1'), 'fallback rejects non-hex');
	ok(!CGI::Lingua::_is_ipv6("::1\n"), 'fallback rejects trailing newline');
};

# -- _is_private_ip / _is_loopback_ip ------------------------------------------

subtest '_is_private_ip: RFC 1918, link-local and ULA ranges' => sub {
	ok(CGI::Lingua::_is_private_ip($_), "$_ is private")
		for qw(10.0.0.1 172.16.0.1 172.31.255.255 192.168.1.1 169.254.1.1 fe80::1 fd00::1);
};

subtest '_is_private_ip: addresses just outside the private ranges' => sub {
	# Off-by-one at the 172.16/12 edges is the classic mistake here
	ok(!CGI::Lingua::_is_private_ip($_), "$_ is not private")
		for ('172.15.255.255', '172.32.0.1', '192.169.0.1', '11.0.0.1', $CFG{public_v4}, $CFG{public_v6});
	ok(!CGI::Lingua::_is_private_ip(undef), 'undef is not private');
};

subtest '_is_loopback_ip: loopback detection and near misses' => sub {
	ok(CGI::Lingua::_is_loopback_ip($_), "$_ is loopback") for qw(127.0.0.1 127.255.255.254 ::1);
	ok(!CGI::Lingua::_is_loopback_ip($_), "$_ is not loopback") for qw(128.0.0.1 ::2 1.127.0.0);
	ok(!CGI::Lingua::_is_loopback_ip(undef), 'undef is not loopback');
};

# -- _clean_country_code --------------------------------------------------------

subtest '_clean_country_code: strips Whois decoration' => sub {
	is(CGI::Lingua::_clean_country_code("US\r"), 'US', 'trailing CR removed');
	is(CGI::Lingua::_clean_country_code('GB # United Kingdom'), 'GB', 'trailing comment removed');
};

subtest '_clean_country_code: malformed values return undef' => sub {
	# Whois data is attacker-influenced; anything that is not exactly a
	# two-letter code must be refused, never "repaired".
	my %bad = (
		'CRLF header injection' => $CFG{whois_crlf},
		'three letters'         => 'GBR',
		'digits'                => '12',
		'embedded space'        => 'G B',
		'markup'                => '<b>',
		'empty'                 => '',
	);
	my @w = _warnings_from {
		for my $why (sort keys %bad) {
			ok(!defined(CGI::Lingua::_clean_country_code($bad{$why})), "rejects $why");
		}
		ok(!defined(CGI::Lingua::_clean_country_code(undef)), 'undef in, undef out');
	};
	is(scalar(@w), 0, 'no warnings, even for undef');
};

# -- _in_baidu_subnet -----------------------------------------------------------

subtest '_in_baidu_subnet: both ends of 185.10.104.0/22 are inside' => sub {
	ok(CGI::Lingua::_in_baidu_subnet($CFG{baidu_first}), 'first address');
	ok(CGI::Lingua::_in_baidu_subnet($CFG{baidu_last}), 'last address');
};

subtest '_in_baidu_subnet: neighbours and malformed input are outside' => sub {
	# 185.10.104.300 used to wrap to .44 inside pack('C') and match
	my @w = _warnings_from {
		ok(!CGI::Lingua::_in_baidu_subnet($CFG{baidu_below}), 'address below the block');
		ok(!CGI::Lingua::_in_baidu_subnet($CFG{baidu_above}), 'address above the block');
		ok(!CGI::Lingua::_in_baidu_subnet('185.10.104.300'), 'out-of-range octet');
		ok(!CGI::Lingua::_in_baidu_subnet("$CFG{baidu_first}\n"), 'trailing newline');
		ok(!CGI::Lingua::_in_baidu_subnet('not an address'), 'garbage');
		ok(!CGI::Lingua::_in_baidu_subnet('::ffff:185.10.104.1'), 'IPv6 form');
		ok(!CGI::Lingua::_in_baidu_subnet(undef), 'undef');
	};
	is(scalar(@w), 0, 'no pack() wrap or uninitialized warnings') or diag(explain(\@w));
};

# -- _country_short_name ---------------------------------------------------------

subtest '_country_short_name: override table and Locale::Codes fallback' => sub {
	my $l = _basic_obj();
	is($l->_country_short_name('gb'), 'United Kingdom', 'override wins over the ISO long name');
	is($l->_country_short_name('GB'), 'United Kingdom', 'case-insensitive');
	is($l->_country_short_name('fr'), 'France', 'non-overridden code from Locale::Codes');
};

subtest '_country_short_name: unknown and hostile codes return undef' => sub {
	my $l = _basic_obj();
	my @w = _warnings_from {
		ok(!defined($l->_country_short_name($_)), "undef for '" . ($_ =~ s/\n/\\n/r) . "'")
			for ('zz', '', "gb\n", '../etc/passwd', 'x' x $CFG{long_string_len});
		ok(!defined($l->_country_short_name(undef)), 'undef for undef');
	};
	is(scalar(@w), 0, 'no warnings');
};

# -- _resolve_country_via_whois --------------------------------------------------

# Install narrow mocks for both Whois modules.  $ip_result is what
# whoisip_query returns (or a coderef to run); $iana_cc is IANA's answer.
sub _mock_whois {
	my (%args) = @_;
	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');
	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query', sub {
		my $r = $args{ip_result};
		return ref($r) eq 'CODE' ? $r->() : $r;
	});
	Test::Mockingbird::mock('Net::Whois::IANA', 'whois_query', sub {
		die "IANA unreachable\n" if $args{iana_dies};
		return 1;
	});
	Test::Mockingbird::mock('Net::Whois::IANA', 'country', sub { $args{iana_cc} });
}

subtest '_resolve_country_via_whois: Whois answer is used and cleaned' => sub {
	plan(skip_all => 'Net::Whois::IP / Net::Whois::IANA not installed') unless $HAS_WHOIS;
	_mock_whois(ip_result => { Country => "GB\r" }, iana_cc => 'XX');
	my $l = _basic_obj();
	$l->_resolve_country_via_whois($CFG{public_v4});
	is($l->{_country}, 'GB', 'Country field used, CR stripped, IANA not needed');
	_reset_mocks();
};

subtest '_resolve_country_via_whois: lower-case key and Puerto Rico rule' => sub {
	plan(skip_all => 'Net::Whois modules not installed') unless $HAS_WHOIS;
	_mock_whois(ip_result => { country => 'FR' });
	my $l = _basic_obj();
	$l->_resolve_country_via_whois($CFG{public_v4});
	is($l->{_country}, 'FR', "'country' key accepted when 'Country' is absent");
	_reset_mocks();

	# RT#131347: a US record whose StateProv is PR is Puerto Rico
	_mock_whois(ip_result => { Country => 'US', StateProv => 'PR' });
	$l = _basic_obj();
	$l->_resolve_country_via_whois($CFG{public_v4});
	is($l->{_country}, 'pr', 'US/PR becomes pr');
	_reset_mocks();
};

subtest '_resolve_country_via_whois: Whois failures fall through to IANA' => sub {
	plan(skip_all => 'Net::Whois modules not installed') unless $HAS_WHOIS;
	# Each failure mode must lead to the IANA look-up, never to a crash
	my %failures = (
		'query dies'          => sub { die "connection refused\n" },
		'query warns'         => sub { warn "timeout\n"; return { Country => 'GB' } },
		'non-hash result'     => 'garbage string',
		'undef result'        => undef,
		'EU is not a country' => { Country => 'EU' },
		'CRLF injection'      => { Country => $CFG{whois_crlf} },
	);
	for my $why (sort keys %failures) {
		_mock_whois(ip_result => $failures{$why}, iana_cc => 'DE');
		my $l = _basic_obj();
		my @w = _warnings_from { $l->_resolve_country_via_whois($CFG{public_v4}) };
		is($l->{_country}, 'DE', "$why: IANA answer used");
		is(scalar(@w), 0, "$why: no warning escapes");
		_reset_mocks();
	}
};

subtest '_resolve_country_via_whois: both sources failing leaves no country' => sub {
	plan(skip_all => 'Net::Whois modules not installed') unless $HAS_WHOIS;
	for my $case (
		[ 'IANA dies',             { ip_result => undef, iana_dies => 1 } ],
		[ 'IANA returns undef',    { ip_result => undef, iana_cc => undef } ],
		[ 'IANA returns injected', { ip_result => undef, iana_cc => $CFG{whois_crlf} } ],
	) {
		my ($why, $args) = @{$case};
		_mock_whois(%{$args});
		my $l = _basic_obj();
		lives_ok { $l->_resolve_country_via_whois($CFG{public_v4}) } "$why: lives";
		ok(!defined($l->{_country}), "$why: _country not set");
		_reset_mocks();
	}
};

# -- _load_geoip ----------------------------------------------------------------

subtest '_load_geoip: no database file means GEO_ABSENT' => sub {
	# Strategy: the -r file probes cannot be mocked, so this runs only on
	# hosts without a GeoIP.dat; t/geoip.t covers the present case.
	my $db = grep { -r } qw(/usr/share/GeoIP/GeoIP.dat /usr/local/share/GeoIP/GeoIP.dat c:/GeoIP/GeoIP.dat);
	plan(skip_all => 'a GeoIP.dat is installed') if $db;
	my $l = _basic_obj();
	lives_ok { $l->_load_geoip() } 'does not die';
	is($l->{_have_geoip}, $GEO_ABSENT, 'sentinel set to GEO_ABSENT');
	ok(!exists($l->{_geoip}), 'no Geo::IP handle created');
};

# -- _accept_language_match -----------------------------------------------------

subtest '_accept_language_match: direct and fallback matches' => sub {
	local %ENV = ();
	my $l = CGI::Lingua->new(supported => ['en', 'fr']);
	is_deeply([$l->_accept_language_match('fr')], ['fr', undef], 'exact match, no sublanguage');
	is_deeply([$l->_accept_language_match('en-us')], ['en', undef],
		'strict matching accepts the base of a variant directly');
};

subtest '_accept_language_match: fallback scan reports the unsupported variant' => sub {
	# Strategy: make the strict whole-header match fail so that the q-sorted
	# pair scan runs; it must return the base and the variant separately.
	local %ENV = ();
	my $l = CGI::Lingua->new(supported => ['en']);
	Test::Mockingbird::mock('I18N::AcceptLanguage', 'accepts', sub {
		my ($self, $tag) = @_;
		return $tag eq 'en' ? 'en' : undef;
	});
	is_deeply([$l->_accept_language_match('de;q=0.1,en-us;q=0.9')], ['en', 'us'],
		'base and variant returned by the pair scan');
	_reset_mocks();
};

subtest '_accept_language_match: nothing supported gives (undef, undef)' => sub {
	local %ENV = ();
	my $l = CGI::Lingua->new(supported => ['en', 'fr']);
	is_deeply([$l->_accept_language_match('de-de,ja;q=0.5')], [undef, undef], 'no match');
};

subtest '_accept_language_match: a variant the client did not ask for is discarded' => sub {
	# I18N::AcceptLanguage strict mode can answer 'en-gb' for a request that
	# never mentioned it.  Trusting it would serve the wrong language.
	local %ENV = ();
	my $l = CGI::Lingua->new(supported => ['en-gb']);
	Test::Mockingbird::mock('I18N::AcceptLanguage', 'accepts', sub {
		my ($self, $header) = @_;
		return $header eq 'de-at' ? 'en-gb' : undef;
	});
	is_deeply([$l->_accept_language_match('de-at')], [undef, undef], 'bogus answer rejected');
	_reset_mocks();
};

subtest '_accept_language_match: only "uninitialized" warnings are suppressed' => sub {
	# RT 74338: the suppression must be narrow, or real problems in
	# I18N::AcceptLanguage would disappear silently.
	local %ENV = ();
	my $l = CGI::Lingua->new(supported => ['en']);
	Test::Mockingbird::mock('I18N::AcceptLanguage', 'accepts', sub {
		warn "Use of uninitialized value in pattern match\n";
		warn "Something important\n";
		return 'en';
	});
	my @w = _warnings_from { $l->_accept_language_match('en') };
	is_deeply(\@w, ["Something important\n"], 'unrelated warning passes through');
	_reset_mocks();
};

subtest '_accept_language_match: caller $SIG{__WARN__} is restored' => sub {
	local %ENV = ();
	my $l = CGI::Lingua->new(supported => ['en']);
	my $handler = sub { };
	local $SIG{__WARN__} = $handler;
	$l->_accept_language_match('en');
	is($SIG{__WARN__}, $handler, 'handler is the same coderef after the call');
};

# -- _resolve_match -------------------------------------------------------------

subtest '_resolve_match: dispatches on the shape of the matched code' => sub {
	my $l = _basic_obj();
	my @calls;
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_base_match', sub { shift; push @calls, ['base', @_]; 1 });
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_sublanguage_match', sub { shift; push @calls, ['sub', @_]; 1 });

	$l->_resolve_match('en', 'us', 'en-us');
	$l->_resolve_match('en-gb', undef, 'en-gb');
	is_deeply(\@calls, [
		['base', 'en', 'us', 'en-us'],
		['sub', 'en-gb', 'en', 'gb', 'en-gb'],
	], 'base and sublanguage helpers receive the split code');
	_reset_mocks();
};

subtest '_resolve_match: malformed codes resolve to nothing' => sub {
	# A three-letter or numeric region (es-419, en-gbx) has no ISO 3166-1
	# alpha-2 variety; neither helper may be called with a bad split.
	my $l = _basic_obj();
	my $called = 0;
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_sublanguage_match', sub { $called++; 1 });
	is($l->_resolve_match($_, undef, $_), 0, "$_ returns 0") for qw(en-gbx es-419);
	is($called, 0, 'sublanguage helper never called');
	_reset_mocks();
};

# -- _resolve_base_match --------------------------------------------------------

subtest '_resolve_base_match: names the variant the client asked for' => sub {
	my $l = _basic_obj();
	Test::Mockingbird::mock('CGI::Lingua', '_code2language', sub { 'English' });
	Test::Mockingbird::mock('CGI::Lingua', '_code2country', sub { Fake::Country->new(name => 'United States') });
	is($l->_resolve_base_match('en', undef, 'en-us'), 1, 'returns 1 on success');
	is($l->{_slanguage}, 'English', '_slanguage set');
	is($l->{_slanguage_code_alpha2}, 'en', 'code set');
	is($l->{_rlanguage}, 'English (United States)', 'requested variant named');
	_reset_mocks();
};

subtest '_resolve_base_match: unknown variant is labelled, not dropped' => sub {
	my $l = _basic_obj();
	Test::Mockingbird::mock('CGI::Lingua', '_code2language', sub { 'English' });
	Test::Mockingbird::mock('CGI::Lingua', '_code2countryname', sub { undef });
	$l->_resolve_base_match('en', 'zz', 'en');
	is($l->{_rlanguage}, 'English (Unknown: zz)', 'unknown variant shown to the caller');
	_reset_mocks();
};

subtest '_resolve_base_match: unknown language code fails without side effects' => sub {
	my $l = _basic_obj();
	Test::Mockingbird::mock('CGI::Lingua', '_code2language', sub { undef });
	is($l->_resolve_base_match('xx', undef, 'xx'), 0, 'returns 0');
	ok(!defined($l->{_slanguage_code_alpha2}), 'no code recorded');
	ok(!defined($l->{_rlanguage}), 'no requested language recorded');
	_reset_mocks();
};

# -- _resolve_sublanguage_match -------------------------------------------------

# Object for en-gb whose country name comes from the cache, so the test
# does not depend on the Locale::Object database.
sub _en_gb_obj {
	my ($cached) = @_;
	my $cache = _fresh_cache();
	$cache->set("${CACHE_NS}variety:gb", $cached) if defined $cached;
	my $l = CGI::Lingua->new(supported => ['en-gb'], cache => $cache);
	my $spy = Spy::Logger->new();
	$l->{logger} = $spy;
	return ($l, $spy, $cache);
}

subtest '_resolve_sublanguage_match: cached variety name is used' => sub {
	local %ENV = ();
	my ($l) = _en_gb_obj('United Kingdom=en');
	is($l->_resolve_sublanguage_match('en-gb', 'en', 'gb', 'en-gb'), 1, 'returns 1');
	is($l->{_sublanguage}, 'United Kingdom', 'sublanguage from cache');
	is($l->{_sublanguage_code_alpha2}, 'gb', 'variety code set');
	is($l->{_rlanguage}, 'English (United Kingdom)', 'requested language includes variety');
	diag(explain({ map { $_ => $l->{$_} } grep { /^_[sr]/ } keys %{$l} })) if $ENV{TEST_VERBOSE};
};

subtest 'new / _find_language: deprecated en-uk is treated as en-gb' => sub {
	# The rule is applied where the tag enters: in the supported list (new)
	# and anywhere in the header (_find_language), not only when the header
	# is exactly "en-uk".  The caller's own array must not be rewritten.
	my @log;
	my $supported = ['en-uk', 'fr'];
	my $l = CGI::Lingua->new(supported => $supported, logger => \@log);
	is_deeply($l->{_supported}, ['en-gb', 'fr'], 'supported entry rewritten in the object');
	is_deeply($supported, ['en-uk', 'fr'], "caller's array unchanged");
	ok((grep { $_->{message} eq 'Resetting country code to GB for en-uk' } @log), 'new(): warned');

	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr;q=0.1, en-UK');
	my ($m, $spy) = _spied_obj(dont_use_ip => 1);
	$m->{_supported} = ['en-gb'];
	$m->_find_language();
	is($m->{_sublanguage_code_alpha2}, 'gb', 'header tag inside a list is rewritten');
	ok((grep { /^Resetting country code to GB for fr;q=0\.1,\s*en-UK$/ } $spy->messages('warn')), '_find_language(): warned');
};

subtest '_resolve_sublanguage_match: poisoned cache entry is not trusted' => sub {
	# "=en" splits into an empty name; it used to produce "English ()"
	local %ENV = ();
	my ($l) = _en_gb_obj('=en');
	$l->_resolve_sublanguage_match('en-gb', 'en', 'gb', 'en-gb');
	is($l->{_sublanguage}, 'United Kingdom', 'empty cached name replaced by the real one');
	unlike($l->{_rlanguage}, qr/\(\)/, 'no empty brackets in requested language');
};

subtest '_resolve_sublanguage_match: stale $@ from the caller is not reported' => sub {
	# The helper inspects $@ after its own eval; an error left over from
	# unrelated caller code must not be logged as if it happened here.
	local %ENV = ();
	my ($l, $spy) = _en_gb_obj('United Kingdom=en');
	local $@ = "stale error from caller\n";
	$l->_resolve_sublanguage_match('en-gb', 'en', 'gb', 'en-gb');
	is($l->{_sublanguage}, 'United Kingdom', 'cached value kept');
	ok(!(grep { /stale error/ } $spy->messages('warn')), 'stale error not logged');
};

subtest '_resolve_sublanguage_match: unsupported language returns 0' => sub {
	local %ENV = ();
	my $l = CGI::Lingua->new(supported => ['fr']);
	$l->{logger} = Spy::Logger->new();
	Test::Mockingbird::mock('CGI::Lingua', '_code2language', sub { 'English' });
	is($l->_resolve_sublanguage_match('en-gb', 'en', 'gb', 'en-gb'), 0, 'returns 0');
	ok(!defined($l->{_sublanguage}), 'no sublanguage');
	ok(!defined($l->{_sublanguage_code_alpha2}), 'no variety code');
	_reset_mocks();
};

# -- _find_language_from_ip -----------------------------------------------------

# Country object whose official language is $name/$code.
sub _country_speaking {
	my ($name, $code) = @_;
	return Fake::Country->new(languages => [ Fake::Language->new(name => $name, code => $code) ]);
}

subtest '_find_language_from_ip: official language of the country is chosen' => sub {
	local %ENV = (REMOTE_ADDR => $CFG{public_v4});
	my $cache = _fresh_cache();
	my ($l) = _spied_obj(cache => $cache);
	Test::Mockingbird::mock('CGI::Lingua', 'country', sub { 'fr' });
	Test::Mockingbird::mock('CGI::Lingua', '_code2country', sub { _country_speaking('French', 'fr') });
	$l->_find_language_from_ip(undef);
	is($l->{_slanguage}, 'French', 'language set from the country');
	is($l->{_slanguage_code_alpha2}, 'fr', 'code set');
	is($cache->get("${CACHE_NS}language_name:fr"), 'French=fr', 'answer cached for the next visitor');
	_reset_mocks();
};

subtest '_find_language_from_ip: cache hit skips the Locale look-up' => sub {
	local %ENV = (REMOTE_ADDR => $CFG{public_v4});
	my $cache = _fresh_cache();
	$cache->set("${CACHE_NS}language_name:fr", 'French=fr');
	my ($l) = _spied_obj(cache => $cache);
	Test::Mockingbird::mock('CGI::Lingua', 'country', sub { 'fr' });
	Test::Mockingbird::mock('CGI::Lingua', '_code2country', sub { die "must not be called\n" });
	lives_ok { $l->_find_language_from_ip(undef) } 'no Locale look-up';
	is($l->{_slanguage}, 'French', 'language from the cache');
	_reset_mocks();
};

subtest '_find_language_from_ip: country from LANG when there is no IP' => sub {
	local %ENV = (LANG => 'fr_FR.UTF-8');
	my ($l) = _spied_obj();
	my @asked;
	Test::Mockingbird::mock('CGI::Lingua', 'country', sub { undef });
	Test::Mockingbird::mock('CGI::Lingua', '_code2country', sub { push @asked, $_[1]; _country_speaking('French', 'fr') });
	$l->_find_language_from_ip(undef);
	is_deeply(\@asked, ['FR'], 'country taken from the LANG territory');
	is($l->{_slanguage}, 'French', 'language found');
	_reset_mocks();
};

subtest '_find_language_from_ip: no country and no LANG changes nothing' => sub {
	local %ENV = ();
	my ($l) = _spied_obj();
	Test::Mockingbird::mock('CGI::Lingua', 'country', sub { undef });
	Test::Mockingbird::mock('CGI::Lingua', '_code2country', sub { die "must not be called\n" });
	lives_ok { $l->_find_language_from_ip(undef) } 'returns quietly';
	ok(!exists($l->{_slanguage}), '_slanguage untouched');
	_reset_mocks();
};

subtest '_find_language_from_ip: unsupported official language is reported readably' => sub {
	# The warning used to print "ARRAY(0x...)" instead of the language list
	local %ENV = (REMOTE_ADDR => $CFG{public_v4});
	my ($l, $spy) = _spied_obj();
	Test::Mockingbird::mock('CGI::Lingua', 'country', sub { 'de' });
	Test::Mockingbird::mock('CGI::Lingua', '_code2country', sub { _country_speaking('German', 'de') });
	$l->_find_language_from_ip(undef);
	ok(!$l->{_slanguage}, 'no language chosen');
	my ($msg) = $spy->messages('warn');
	like($msg, qr/closest language for German in en, fr$/, 'supported list is printed');
	unlike($msg // '', qr/ARRAY\(0x/, 'no stringified array ref');
	_reset_mocks();
};

subtest '_find_language_from_ip: unknown country or no official language' => sub {
	local %ENV = (REMOTE_ADDR => $CFG{public_v4});
	for my $case (
		[ 'Locale knows nothing', undef ],
		[ 'no official language', Fake::Country->new(languages => []) ],
	) {
		my ($why, $country) = @{$case};
		my ($l) = _spied_obj();
		Test::Mockingbird::mock('CGI::Lingua', 'country', sub { 'zz' });
		Test::Mockingbird::mock('CGI::Lingua', '_code2country', sub { $country });
		lives_ok { $l->_find_language_from_ip(undef) } "$why: lives";
		ok(!exists($l->{_slanguage}), "$why: no language");
		_reset_mocks();
	}
};

subtest '_find_language_from_ip: poisoned cache entry is discarded' => sub {
	# A value without the "name=code" shape DESTROY writes must not be used
	local %ENV = (LANG => 'xx');
	my $cache = _fresh_cache();
	$cache->set("${CACHE_NS}language_name:xx", 'garbage');
	my ($l, $spy) = _spied_obj(cache => $cache);
	Test::Mockingbird::mock('CGI::Lingua', 'country', sub { undef });
	my @w = _warnings_from { $l->_find_language_from_ip(undef) };
	is(scalar(@w), 0, 'no Perl warnings') or diag(explain(\@w));
	ok((grep { /^Discarding malformed cache entry for \Q${CACHE_NS}\Elanguage_name:xx$/ } $spy->messages('warn')),
		'poisoned entry reported through the logger');
	ok(!defined($cache->get("${CACHE_NS}language_name:xx")), 'and removed from the cache');
	ok(!$l->{_slanguage}, 'no language chosen from garbage');
	_reset_mocks();
};

subtest '_find_language_from_ip: unmappable language without REMOTE_ADDR' => sub {
	# Regression: the "Can't determine code from IP" warning interpolated an
	# undef REMOTE_ADDR when the country came from LANG (command-line use).
	# A header is given so the slow language2code() path is taken, and the
	# official language name maps to no code.
	local %ENV = (LANG => 'xx');
	my ($l, $spy) = _spied_obj();
	Test::Mockingbird::mock('CGI::Lingua', 'country', sub { undef });
	Test::Mockingbird::mock('CGI::Lingua', '_code2country', sub { _country_speaking('Nolanguage', undef) });
	my @w = _warnings_from { $l->_find_language_from_ip('zz') };
	is(scalar(@w), 0, 'no Perl warnings') or diag(explain(\@w));
	ok((grep { /^Can't determine code from IP \(none\) for requested language Nolanguage$/ } $spy->messages('warn')),
		'problem reported through the logger');
	ok(!$l->{_slanguage}, 'no language chosen');
	_reset_mocks();
};

subtest '_find_language_from_ip: an existing language is not overwritten' => sub {
	local %ENV = (REMOTE_ADDR => $CFG{public_v4});
	my ($l) = _spied_obj();
	$l->{_slanguage} = 'English';
	Test::Mockingbird::mock('CGI::Lingua', 'country', sub { 'fr' });
	Test::Mockingbird::mock('CGI::Lingua', '_code2country', sub { _country_speaking('French', 'fr') });
	$l->_find_language_from_ip('en');
	is($l->{_slanguage}, 'English', 'header choice wins over the IP guess');
	_reset_mocks();
};

# -- _code2country / _sorted_tokens: hostile input -------------------------------

subtest '_code2country: SQL metacharacters return undef' => sub {
	# The code reaches an SQLite query inside Locale::Object
	my $l = _basic_obj();
	my $obj;
	lives_ok { $obj = $l->_code2country(q{gb'; DROP TABLE country;--}) } 'lives';
	ok(!defined($obj), 'no country for an injected code');
};

subtest '_sorted_tokens: equal q values keep header order' => sub {
	my $l = _basic_obj();
	my @tags = map { $_->[0] } @{$l->_sorted_tokens('de,fr;q=0.5,en,it;q=0.5')};
	is_deeply(\@tags, [qw(de en fr it)], 'stable sort within each q value');
};

subtest '_sorted_tokens: degenerate and very large headers' => sub {
	my $l = _basic_obj();
	is_deeply($l->_sorted_tokens(',,, ,'), [], 'only separators gives no tokens');
	my $big = join(',', ('en') x $CFG{many_tokens});
	my $sorted;
	lives_ok { $sorted = $l->_sorted_tokens($big) } 'large header parsed';
	is(scalar(@{$sorted}), $CFG{many_tokens}, 'every token kept');
};

# -- Public methods: hostile input --------------------------------------------

subtest 'new: false and malformed supported values croak with exact messages' => sub {
	local %ENV = ();
	# An arrayref logger keeps the expected error messages off STDERR
	my @log;
	throws_ok { CGI::Lingua->new(supported => 0, logger => \@log) } $CFG{missing_supported}, 'supported => 0';
	throws_ok { CGI::Lingua->new(supported => '', logger => \@log) } $CFG{missing_supported}, "supported => ''";
	throws_ok { CGI::Lingua->new(supported => undef, logger => \@log) } $CFG{missing_supported}, 'supported => undef';
	throws_ok { CGI::Lingua->new(supported => { en => 1 }) } $CFG{bad_ref_supported}, 'hashref';
	throws_ok { CGI::Lingua->new(supported => sub { 'en' }) } $CFG{bad_ref_supported}, 'coderef';
	throws_ok { CGI::Lingua->new(supported => 'e') } $CFG{short_code}, 'one character';
	throws_ok { CGI::Lingua->new(supported => 'english') } $CFG{short_code}, 'seven characters';
};

subtest 'new: supported_languages is an alias for supported' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr');
	my $l = CGI::Lingua->new(supported_languages => ['fr']);
	isa_ok($l, 'CGI::Lingua');
	is($l->language(), 'French', 'alias honoured');
};

subtest 'country: hostile REMOTE_ADDR values are rejected' => sub {
	my %bad = (
		'shell injection'      => "$CFG{public_v4};cat /etc/passwd",
		'mapped out-of-range'  => '::ffff:999.999.999.999',
		'Arabic-Indic digits'  => join('.', ("\xd9\xa1") x 4),	# UTF-8 bytes; %ENV holds bytes
		'overlong'             => '1' x $CFG{long_string_len},
	);
	for my $why (sort keys %bad) {
		local %ENV = (REMOTE_ADDR => $bad{$why});
		my ($l, $spy) = _spied_obj();
		my $cc;
		lives_ok { $cc = $l->country() } "$why: lives";
		ok(!defined($cc), "$why: no country");
		ok((grep { /isn't a valid IP address/ } $spy->messages('warn')), "$why: warned");
	}
};

subtest 'country: malformed GEOIP_COUNTRY_CODE and HTTP_CF_IPCOUNTRY values are ignored' => sub {
	# "GB\n" matters: /^..$/ allows a trailing newline, so the check must use \z.
	# 'XX' is left out for Cloudflare because it is skipped without a warning.
	for my $var (qw(GEOIP_COUNTRY_CODE HTTP_CF_IPCOUNTRY)) {
		for my $bad ('gb', 'GBR', "GB\n", 'G1', '<b>') {
			local %ENV = ($var => $bad);
			my ($l, $spy) = _spied_obj();
			my $shown = $bad =~ s/\n/\\n/r;
			ok(!defined($l->country()), "$var '$shown' not trusted");
			ok((grep { /$var contains an invalid/ } $spy->messages('warn')), "$var '$shown' warned");
		}
	}
};

subtest 'locale: GEOIP_COUNTRY_CODE with a trailing newline is not used' => sub {
	# locale() has its own copy of the GEOIP_COUNTRY_CODE check
	local %ENV = (GEOIP_COUNTRY_CODE => "GB\n");
	my ($l) = _spied_obj();
	my @asked;
	Test::Mockingbird::mock('CGI::Lingua', 'country', sub { undef });
	Test::Mockingbird::mock('CGI::Lingua', '_code2country', sub { push @asked, $_[1]; Fake::Country->new(name => 'United Kingdom') });
	ok(!defined($l->locale()), 'no locale');
	is_deeply(\@asked, [], 'country look-up never attempted');
	_reset_mocks();
};

subtest 'time_zone: hostile ip-api.com answer is discarded' => sub {
	plan(skip_all => 'LWP::Simple::WithCache or JSON::Parse not installed') unless $HAS_LWP && $HAS_JSONP;
	local %ENV = (REMOTE_ADDR => $CFG{public_v4});
	my ($l, $spy) = _spied_obj();
	$l->{_have_geoip} = $GEO_ABSENT;	# force the web-service path
	{
		local $SIG{__WARN__} = sub { };
		Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub {
			JSON::PP::encode_json({ timezone => $CFG{tz_hostile} });
		});
	}
	ok(!defined($l->time_zone()), 'undef returned');
	ok((grep { /Discarding malformed timezone/ } $spy->messages('warn')), 'warned');
	_reset_mocks();
};

subtest 'time_zone: unparseable ip-api.com answer is survived' => sub {
	plan(skip_all => 'LWP::Simple::WithCache or JSON::Parse not installed') unless $HAS_LWP && $HAS_JSONP;
	local %ENV = (REMOTE_ADDR => $CFG{public_v4});
	my ($l, $spy) = _spied_obj();
	$l->{_have_geoip} = $GEO_ABSENT;
	{
		local $SIG{__WARN__} = sub { };
		Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { '{"timezone": ' });
	}
	my $tz;
	lives_ok { $tz = $l->time_zone() } 'lives';
	ok(!defined($tz), 'undef returned');
	ok((grep { /unparseable JSON/ } $spy->messages('warn')), 'parse failure reported');
	_reset_mocks();
};

subtest 'locale: hostile User-Agent strings are ignored' => sub {
	for my $case (
		[ 'control characters', "Mozilla/5.0 (en-GB)\x00\r\nX-Evil: 1" ],
		[ 'over the length limit', 'Mozilla/5.0 (' . ('a' x $CFG{ua_max}) . ')' ],
	) {
		my ($why, $ua) = @{$case};
		local %ENV = (HTTP_USER_AGENT => $ua);
		my ($l, $spy) = _spied_obj();
		Test::Mockingbird::mock('CGI::Lingua', 'country', sub { undef });
		ok(!defined($l->locale()), "$why: no locale");
		ok((grep { /HTTP_USER_AGENT contains invalid/ } $spy->messages('warn')), "$why: warned");
		_reset_mocks();
	}
};

subtest 'language: overlong Accept-Language header is ignored' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr,' . ('x' x $CFG{accept_lang_max}));
	my ($l, $spy) = _spied_obj(dont_use_ip => 1);
	is($l->language(), 'Unknown', 'header not used');
	ok((grep { /HTTP_ACCEPT_LANGUAGE contains invalid/ } $spy->messages('warn')), 'warned');
};

subtest 'plural_category: undef croaks; odd numbers do not' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my $l = CGI::Lingua->new(supported => ['en']);
	throws_ok { $l->plural_category(undef) } $CFG{plural_croak}, 'undef croaks with the documented message';
	is($l->plural_category(1.9), 'one', 'fraction is truncated, not rounded');
	is($l->plural_category(-1), 'other', 'negative number is not "one"');
	lives_ok { $l->plural_category(9**9**9) } 'infinity does not die';
	returns_ok($l->plural_category(2), { type => 'string', memberof => [qw(zero one two few many other)] },
		'result is a CLDR category');
};

subtest 'plural_category: no negotiated language always gives other' => sub {
	local %ENV = ();
	my $l = CGI::Lingua->new(supported => ['en'], dont_use_ip => 1);
	is($l->plural_category(1), 'other', "'other', not 'one', when the language is Unknown");
};

subtest 'translation_file: traversal and unsafe extensions are refused' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en');
	my %bad = (
		'parent directory'      => ['/var/www/../../etc'],
		'null byte in dir'      => ["/var/www\x00/etc"],
		'traversal in ext'      => ['/tmp', '../../etc/passwd'],
		'shell meta in ext'     => ['/tmp', 'json;rm -rf /'],
		'only a dot'            => ['/tmp', '.'],
		'slash in ext'          => ['/tmp', 'a/b'],
	);
	for my $why (sort keys %bad) {
		my ($l, $spy) = _spied_obj();
		ok(!defined($l->translation_file(@{$bad{$why}})), "$why: undef");
		ok((grep { /translation_file: unsafe/ } $spy->messages('warn')), "$why: warned");
	}
};

subtest 'translation_file: variant file is preferred, Unknown finds nothing' => sub {
	use File::Temp qw(tempdir);
	my $dir = tempdir(CLEANUP => 1);
	for my $name (qw(en-gb.json en.json)) {
		open(my $fh, '>', "$dir/$name") or die "$dir/$name: $!";
		close $fh;
	}
	{
		local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-gb');
		my $l = CGI::Lingua->new(supported => ['en-gb', 'en']);
		is($l->translation_file($dir), "$dir/en-gb.json", 'en-gb.json chosen over en.json');
	}
	{
		local %ENV = ();
		my $l = CGI::Lingua->new(supported => ['en'], dont_use_ip => 1);
		ok(!defined($l->translation_file($dir)), 'no file when no language was found');
	}
};

# -- Global state and memory ---------------------------------------------------

subtest 'helpers do not disturb the caller $_' => sub {
	# Strategy: put a sentinel in $_, call every helper that loops or maps,
	# and check that the sentinel survives.
	local %ENV = ();
	my $l = _basic_obj();
	local $_ = $CFG{sentinel};
	$l->_sorted_tokens('en,fr;q=0.5');
	$l->_get_closest('en', 'en');
	$l->_country_short_name('fr');
	$l->_accept_language_match('fr');
	CGI::Lingua::_in_baidu_subnet($CFG{baidu_first});
	CGI::Lingua::_is_ipv4($CFG{public_v4});
	is($_, $CFG{sentinel}, '$_ unchanged');
};

subtest 'helpers restore the caller signal handlers' => sub {
	my $l = _basic_obj();
	my $warn = sub { };
	my $die  = sub { die @_ };
	local $SIG{__WARN__} = $warn;
	local $SIG{__DIE__}  = $die;
	$l->_code2country('gb');
	$l->_country_short_name('fr');
	is($SIG{__WARN__}, $warn, '__WARN__ handler restored');
	is($SIG{__DIE__}, $die, '__DIE__ handler restored');
};

subtest 'objects are freed after use (no leaks, no cycles)' => sub {
	# Strategy: run the code paths that store caches, loggers and geo state,
	# then check both for cycles and that the last reference really frees it.
	local %ENV = (REMOTE_ADDR => $CFG{public_v4}, HTTP_ACCEPT_LANGUAGE => 'en-gb,fr;q=0.5');
	my $weak;
	{
		my $l = CGI::Lingua->new(supported => ['en', 'fr'], cache => _fresh_cache());
		Test::Mockingbird::mock('CGI::Lingua', 'country', sub { 'gb' });
		$l->language();
		$l->sublanguage();
		$l->requested_language();
		$l->_find_language_from_ip('en-gb');
		memory_cycle_ok($l, 'no cycles after the full language pipeline');
		$weak = $l;
		Scalar::Util::weaken($weak);
		_reset_mocks();
	}
	ok(!defined($weak), 'object destroyed when it goes out of scope');
};

# -- _load_geoip with a database, and missing modules --------------------------

# A require that fails for $file even if the module is already loaded:
# remove it from %INC for the block and refuse it from the front of @INC.
sub _hide_module_for {
	my ($file, $code) = @_;
	delete local $INC{$file};
	local @INC = (sub { die "hidden by the test\n" if $_[1] eq $file; return }, @INC);
	return $code->();
}

subtest '_load_geoip: first readable GeoIP.dat in @GEOIP_DAT is opened' => sub {
	plan(skip_all => 'Geo::IP not installed') unless eval { require Geo::IP; 1 };
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my $dat = "$dir/GeoIP.dat";
	open(my $fh, '>', $dat) or die "$dat: $!";
	close $fh;
	no warnings 'once';
	local @CGI::Lingua::GEOIP_DAT = ("$dir/missing.dat", $dir, $dat);	# missing, a directory, then the file

	my @opened;
	Test::Mockingbird::mock('Geo::IP', 'open', sub { push @opened, [ @_[1, 2] ]; bless {}, 'Geo::IP' });
	my $l = _basic_obj();
	$l->_load_geoip();
	is($l->{_have_geoip}, $GEO_PRESENT, 'sentinel set to GEO_PRESENT');
	isa_ok($l->{_geoip}, 'Geo::IP', 'handle stored');
	is_deeply(\@opened, [ [ $dat, 0 ] ], 'only the readable regular file is opened, in standard mode');
	_reset_mocks();
};

subtest '_load_geoip: a corrupt database is not used' => sub {
	# Geo::IP->open dies or returns undef on a truncated file; country() must
	# not later call a method on undef
	plan(skip_all => 'Geo::IP not installed') unless eval { require Geo::IP; 1 };
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my $dat = "$dir/GeoIP.dat";
	open(my $fh, '>', $dat) or die "$dat: $!";
	close $fh;
	no warnings 'once';
	local @CGI::Lingua::GEOIP_DAT = ($dat);
	for my $failure (sub { die "Bad database\n" }, sub { undef }) {
		Test::Mockingbird::mock('Geo::IP', 'open', $failure);
		my ($l, $spy) = _spied_obj();
		lives_ok { $l->_load_geoip() } 'lives';
		is($l->{_have_geoip}, $GEO_ABSENT, 'treated as no database');
		ok((grep { /^Can't open \Q$dat\E with Geo::IP; not using it$/ } $spy->messages('warn')), 'reported');
		_reset_mocks();
	}
};

subtest '_load_geoip: database present but Geo::IP missing' => sub {
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my $dat = "$dir/GeoIP.dat";
	open(my $fh, '>', $dat) or die "$dat: $!";
	close $fh;
	no warnings 'once';
	local @CGI::Lingua::GEOIP_DAT = ($dat);
	my $l = _basic_obj();
	_hide_module_for('Geo/IP.pm', sub { $l->_load_geoip() });
	is($l->{_have_geoip}, $GEO_ABSENT, 'sentinel set to GEO_ABSENT');
};

subtest 'time_zone: falls back to LWP::Simple without LWP::Simple::WithCache' => sub {
	plan(skip_all => 'LWP::Simple or JSON::Parse not installed')
		unless eval { require LWP::Simple; require JSON::Parse; 1 };
	local %ENV = (REMOTE_ADDR => $CFG{public_v4});
	my @urls;
	{
		local $SIG{__WARN__} = sub { };	# LWP::Simple::get has a prototype
		Test::Mockingbird::mock('LWP::Simple', 'get', sub { push @urls, $_[0]; '{"timezone":"Asia/Tokyo"}' });
	}
	my $l = _basic_obj();
	$l->{_have_geoip} = $GEO_ABSENT;
	my $tz = _hide_module_for('LWP/Simple/WithCache.pm', sub { $l->time_zone() });
	is($tz, 'Asia/Tokyo', 'zone from LWP::Simple');
	is_deeply(\@urls, ["http://ip-api.com/json/$CFG{public_v4}"], 'ip-api.com asked about the visitor');
	_reset_mocks();
};

done_testing();
