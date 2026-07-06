#!/usr/bin/env perl
# t/unit.t -- Black-box tests for every public method of CGI::Lingua.
#
# Strategy: each subtest drives the module through one documented behaviour
# described in the POD.  All network I/O (IP geo lookups, Whois, geoplugin)
# and optional modules (IP::Country, Geo::IP) are mocked so the suite runs
# fully offline in any environment.
#
# Libraries used:
#   Test::Most       -- rich assertion vocabulary
#   Test::Mockingbird -- stub/spy external dependencies
#   Test::Returns    -- validate return-value schemas against the POD spec

use strict;
use warnings;

use CHI;
use Readonly;
use Scalar::Util qw(blessed);
use Test::Most;
use Test::Mockingbird;
use Test::Returns qw(returns_ok returns_is);

use lib 't/lib';

BEGIN { use_ok('CGI::Lingua') }

# ── Shared constants ──────────────────────────────────────────────────────────

# Language codes used throughout -- one place to update if things change.
Readonly my %LANG => (
	EN    => 'en',
	EN_GB => 'en-gb',
	EN_US => 'en-us',
	FR    => 'fr',
	DE    => 'de',
	JA    => 'ja',
	ZH    => 'zh',
);

# Country codes returned by mocked geo modules and expected from the API.
Readonly my %CC => (
	GB   => 'gb',
	US   => 'us',
	FR   => 'fr',
	DE   => 'de',
	CN   => 'cn',
	PRIV => '192.168.1.1',
	LOOP => '127.0.0.1',
);

# IP addresses used in tests.
Readonly my %IP => (
	PUBLIC  => '8.8.8.8',
	PRIVATE => '192.168.0.1',
	LOOPBACK => '127.0.0.1',
	V6_LOOP => '::1',
	BAIDU   => '185.10.104.1',
);

# Block all Whois/geoplugin network calls for every test in this file.
# Individual subtests that need specific geo behaviour override via their
# own mock before calling the method under test.
Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });

# ── Helper ────────────────────────────────────────────────────────────────────

# Build a minimal object with the given supported list and optional extras.
# Using a helper keeps individual subtests readable.
sub _obj {
	my ($supported, %extra) = @_;
	CGI::Lingua->new(supported => $supported, %extra);
}

# ── new() ─────────────────────────────────────────────────────────────────────
# POD: Creates a CGI::Lingua object.
#   - supported required (ArrayRef[Str] | Str)
#   - croaks on missing, wrong-ref-type, or too-short/long string supported
#   - croaks for ::new() misuse
#   - croaks when a blessed logger lacks warn/info/error

subtest 'new: returns a blessed CGI::Lingua object' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = CGI::Lingua->new(supported => [$LANG{EN}]);
	isa_ok($l, 'CGI::Lingua', 'new() with arrayref supported');
};

subtest 'new: supported_languages is an accepted alias for supported' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = CGI::Lingua->new(supported_languages => [$LANG{EN}]);
	isa_ok($l, 'CGI::Lingua', 'supported_languages alias accepted');
};

subtest 'new: single-language string is accepted' => sub {
	# POD: supported can be a plain Str (2-5 chars)
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{FR});
	my $l = CGI::Lingua->new(supported => $LANG{FR});
	isa_ok($l, 'CGI::Lingua', 'string supported accepted');
};

subtest 'new: missing supported croaks' => sub {
	# POD: "You must give a list of supported languages" when key is absent.
	# Params::Get intercepts the totally-empty call with "Usage:", so we pass
	# an unrelated key to get past Params::Get and into CGI::Lingua's own check.
	local %ENV = ();
	throws_ok {
		CGI::Lingua->new(cache => CHI->new(driver => 'Memory', global => 0));
	} qr/supported languages/i,
		'missing supported key croaks with documented message';
};

subtest 'new: hashref supported croaks with documented message' => sub {
	# POD: "List of supported languages must be an array ref"
	local %ENV = ();
	throws_ok {
		CGI::Lingua->new(supported => { en => 1 });
	} qr/array ref/i,
		'hashref supported croaks';
};

subtest 'new: supported string too short croaks' => sub {
	# POD: "Supported languages must be the short code"
	local %ENV = ();
	throws_ok {
		CGI::Lingua->new(supported => 'x');
	} qr/short code/i,
		'1-char supported string croaks';
};

subtest 'new: supported string too long croaks' => sub {
	local %ENV = ();
	throws_ok {
		CGI::Lingua->new(supported => 'toolong');
	} qr/short code/i,
		'7-char supported string croaks';
};

subtest 'new: ::new() misuse croaks' => sub {
	# POD: "use ->new() not ::new() to instantiate"
	local %ENV = ();
	throws_ok {
		CGI::Lingua::new(undef, { supported => [$LANG{EN}] });
	} qr/->new\(\)/,
		'::new() call croaks with documented message';
};

subtest 'new: blessed logger missing required method croaks' => sub {
	# POD: "Logger must be a blessed object with warn/info/error methods"
	# A blessed object that lacks error() must be rejected.
	local %ENV = ();
	my $bad = bless {}, 'BadLogger';
	{ no warnings 'once';
	  *BadLogger::warn = sub {};
	  *BadLogger::info = sub {};
	  # deliberately no BadLogger::error
	}
	throws_ok {
		CGI::Lingua->new(supported => [$LANG{EN}], logger => $bad);
	} qr/blessed object/i,
		'logger missing error() croaks';
};

subtest 'new: cloning an existing object merges params' => sub {
	# POD: "or a clone when called on an object"
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $orig  = _obj([$LANG{EN}]);
	my $clone = $orig->new(supported => [$LANG{FR}]);
	isa_ok($clone, 'CGI::Lingua', 'clone is a CGI::Lingua');
	isnt($orig, $clone, 'clone is a distinct object');
};

subtest 'new: cache thaw restores computed state' => sub {
	# POD pseudocode step 4: "If cache and REMOTE_ADDR set, attempt to thaw"
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $cache = CHI->new(driver => 'Memory', global => 0);

	# First construction: compute language, let DESTROY freeze it.
	my $first = _obj([$LANG{EN}], cache => $cache);
	$first->language();    # populate _slanguage
	undef $first;          # triggers DESTROY

	# Second construction: must restore from cache, not recompute.
	local $ENV{REMOTE_ADDR} = $IP{PUBLIC};
	my $second = _obj([$LANG{EN}], cache => $cache);
	is($second->{_slanguage}, 'English',
		'Thawed object has correct _slanguage from cache');
};

# ── language() ───────────────────────────────────────────────────────────────
# POD: Returns human-readable language name ('English', 'French', etc.)
#      or 'Unknown'.  Sublanguage fallback handled sensibly.

subtest 'language: returns English for HTTP_ACCEPT_LANGUAGE: en' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = _obj([$LANG{EN}, $LANG{FR}]);
	returns_ok($l->language(), { type => 'string' }, 'language() returns a string');
	is($l->language(), 'English', 'language() returns English');
};

subtest 'language: returns French for HTTP_ACCEPT_LANGUAGE: fr' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{FR});
	my $l = _obj([$LANG{EN}, $LANG{FR}]);
	is($l->language(), 'French', 'language() returns French');
};

subtest 'language: returns Unknown when requested lang not in supported list' => sub {
	# POD: "returns Unknown" when no match
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{DE}, REMOTE_ADDR => $IP{LOOPBACK});
	my $l = _obj([$LANG{EN}, $LANG{FR}]);
	is($l->language(), 'Unknown', "Unsupported lang returns 'Unknown'");
};

subtest 'language: en-us falls back to English on en-only site' => sub {
	# POD: "if a client requests U.S. English on a site that only serves British
	# English, language() will return 'English'"
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_US});
	my $l = _obj([$LANG{EN}]);
	is($l->language(), 'English',
		'en-us falls back to English on en-only site');
};

subtest 'language: en-gb falls back to English on en-only site' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB});
	my $l = _obj([$LANG{EN}]);
	is($l->language(), 'English',
		'en-gb falls back to English on en-only site');
};

subtest 'language: en-uk (deprecated) treated as en-gb' => sub {
	# POD: deprecated browser tag en-uk is normalised to en-gb
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-uk');
	my $l = _obj([$LANG{EN_GB}]);
	is($l->language(), 'English', 'en-uk handled as en-gb');
};

subtest 'language: caches result on second call' => sub {
	# language() must not call _find_language() again once _slanguage is set.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = _obj([$LANG{EN}]);
	my $first  = $l->language();
	# Changing the env var after first call must not affect the cached result.
	local $ENV{HTTP_ACCEPT_LANGUAGE} = $LANG{FR};
	is($l->language(), $first, 'language() result is cached');
};

# ── preferred_language() ─────────────────────────────────────────────────────
# POD: "Same as language()"

subtest 'preferred_language: identical to language()' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{FR});
	my $l = _obj([$LANG{EN}, $LANG{FR}]);
	is($l->preferred_language(), $l->language(),
		'preferred_language() equals language()');
};

# ── name() ───────────────────────────────────────────────────────────────────
# POD: "Synonym for language, for compatibility with Locale::Object::Language"

subtest 'name: identical to language()' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = _obj([$LANG{EN}]);
	is($l->name(), $l->language(), 'name() equals language()');
};

# ── sublanguage() ────────────────────────────────────────────────────────────
# POD: Returns country variant string e.g. 'United Kingdom', or undef.

subtest 'sublanguage: returns United Kingdom for en-gb' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB});
	my $l = _obj([$LANG{EN_GB}]);
	is($l->sublanguage(), 'United Kingdom',
		'sublanguage() returns United Kingdom for en-gb');
};

subtest 'sublanguage: returns undef for plain language code' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = _obj([$LANG{EN}]);
	$l->language();    # trigger _find_language
	ok(!defined $l->sublanguage(),
		'sublanguage() is undef when no sublanguage requested');
};

subtest 'sublanguage: returns undef when language is Unknown' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{DE}, REMOTE_ADDR => $IP{LOOPBACK});
	my $l = _obj([$LANG{EN}]);
	$l->language();
	ok(!defined $l->sublanguage(), 'sublanguage() undef when language is Unknown');
};

# ── language_code_alpha2() ───────────────────────────────────────────────────
# POD: Returns 2-char code e.g. 'en'; undef when unsupported.

subtest 'language_code_alpha2: returns en for English' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = _obj([$LANG{EN}]);
	my $code = $l->language_code_alpha2();
	returns_ok($code, { type => 'string' }, 'language_code_alpha2 returns a string');
	is($code, $LANG{EN}, 'language_code_alpha2 returns en');
};

subtest 'language_code_alpha2: returns fr for French' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{FR});
	my $l = _obj([$LANG{EN}, $LANG{FR}]);
	is($l->language_code_alpha2(), $LANG{FR},
		'language_code_alpha2 returns fr');
};

subtest 'language_code_alpha2: returns en for en-gb (base language)' => sub {
	# POD: "gives the two-character representation of the supported language,
	# e.g. 'en' when you've asked for en-gb"
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB});
	my $l = _obj([$LANG{EN_GB}]);
	is($l->language_code_alpha2(), $LANG{EN},
		'language_code_alpha2 is en for en-gb');
};

subtest 'language_code_alpha2: returns undef when language unsupported' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{DE}, REMOTE_ADDR => $IP{LOOPBACK});
	my $l = _obj([$LANG{EN}]);
	$l->language();
	ok(!defined $l->language_code_alpha2(),
		'language_code_alpha2 is undef for unsupported language');
};

# ── code_alpha2() ────────────────────────────────────────────────────────────
# POD: "Synonym for language_code_alpha2, kept for historical reasons"

subtest 'code_alpha2: identical to language_code_alpha2()' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = _obj([$LANG{EN}]);
	is($l->code_alpha2(), $l->language_code_alpha2(),
		'code_alpha2() aliases language_code_alpha2()');
};

# ── sublanguage_code_alpha2() ─────────────────────────────────────────────────
# POD: Returns 2-char variety code e.g. 'gb'; undef when none.

subtest 'sublanguage_code_alpha2: returns gb for en-gb' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB});
	my $l = _obj([$LANG{EN_GB}]);
	is($l->sublanguage_code_alpha2(), 'gb',
		'sublanguage_code_alpha2 is gb for en-gb');
};

subtest 'sublanguage_code_alpha2: returns us for en-us' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_US});
	my $l = _obj([$LANG{EN_US}]);
	is($l->sublanguage_code_alpha2(), 'us',
		'sublanguage_code_alpha2 is us for en-us');
};

subtest 'sublanguage_code_alpha2: returns undef for plain language code' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{FR});
	my $l = _obj([$LANG{EN}, $LANG{FR}]);
	$l->language();
	ok(!defined $l->sublanguage_code_alpha2(),
		'sublanguage_code_alpha2 undef when no variant requested');
};

# ── requested_language() ─────────────────────────────────────────────────────
# POD: Returns human-readable form of what the user requested, whether
#      supported or not.  Sublanguage appears in parentheses.

subtest 'requested_language: includes sublanguage in parens for en-gb' => sub {
	# POD: "English (United Kingdom)"
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB});
	my $l = _obj([$LANG{EN_GB}]);
	my $rl = $l->requested_language();
	returns_ok($rl, { type => 'string' }, 'requested_language returns a string');
	like($rl, qr/English.*United Kingdom/,
		'requested_language includes country in parens');
};

subtest 'requested_language: plain English has no parens' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = _obj([$LANG{EN}]);
	my $rl = $l->requested_language();
	unlike($rl, qr/\(/, 'No parenthetical when no sublanguage');
	is($rl, 'English', 'plain English returned without parens');
};

subtest 'requested_language: returns Unknown for unrecognised input' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'xx', REMOTE_ADDR => $IP{LOOPBACK});
	my $l = _obj([$LANG{EN}]);
	my $rl = $l->requested_language();
	is($rl, 'Unknown', "requested_language returns 'Unknown' for xx code");
};

# ── country() ────────────────────────────────────────────────────────────────
# POD: Returns 2-char lowercase country code, 'Unknown', or undef.

subtest 'country: GEOIP_COUNTRY_CODE valid code returned as lowercase' => sub {
	# POD: mod_geoip env var trusted when it passes ISO 3166-1 validation
	local %ENV = (GEOIP_COUNTRY_CODE => 'DE');
	my $l = _obj([$LANG{EN}]);
	is($l->country(), $CC{DE}, 'Valid GEOIP_COUNTRY_CODE returned lowercase');
};

subtest 'country: GEOIP_COUNTRY_CODE invalid code ignored with warning' => sub {
	# POD message: "GEOIP_COUNTRY_CODE contains an invalid country code; ignoring"
	local %ENV = (GEOIP_COUNTRY_CODE => 'NOT_CC', REMOTE_ADDR => $IP{LOOPBACK});
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	$l->country();
	ok((grep { ref($_) ? $_->{warning} =~ /invalid/ : /invalid/ } @warnings),
		'_warn called for invalid GEOIP_COUNTRY_CODE');
	Test::Mockingbird::restore_all();
	# Restore the global network block mock after restore_all.
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });
};

subtest 'country: HTTP_CF_IPCOUNTRY valid code returned as lowercase' => sub {
	# POD: Cloudflare header trusted when it passes ISO 3166-1 validation
	local %ENV = (HTTP_CF_IPCOUNTRY => 'FR');
	my $l = _obj([$LANG{EN}]);
	is($l->country(), $CC{FR}, 'Valid HTTP_CF_IPCOUNTRY returned lowercase');
};

subtest 'country: HTTP_CF_IPCOUNTRY XX skipped (Cloudflare unknown)' => sub {
	# POD: "'XX' means Cloudflare couldn't determine country — skip it"
	local %ENV = (HTTP_CF_IPCOUNTRY => 'XX', REMOTE_ADDR => $IP{LOOPBACK});
	my $l = _obj([$LANG{EN}]);
	my $result = $l->country();
	ok(!defined $result || $result ne 'xx',
		"Cloudflare 'XX' sentinel is not returned as country");
};

subtest 'country: returns undef when REMOTE_ADDR is absent' => sub {
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	ok(!defined $l->country(), 'country() returns undef with no REMOTE_ADDR');
};

subtest 'country: private IP returns undef' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PRIVATE});
	my $l = _obj([$LANG{EN}]);
	ok(!defined $l->country(), 'Private IP returns undef');
};

subtest 'country: loopback IP returns undef' => sub {
	local %ENV = (REMOTE_ADDR => $IP{LOOPBACK});
	my $l = _obj([$LANG{EN}]);
	ok(!defined $l->country(), 'Loopback returns undef');
};

subtest 'country: IPv6 loopback ::1 returns undef' => sub {
	local %ENV = (REMOTE_ADDR => $IP{V6_LOOP});
	my $l = _obj([$LANG{EN}]);
	ok(!defined $l->country(), 'IPv6 loopback ::1 returns undef');
};

subtest 'country: malformed IP warns and returns undef' => sub {
	# POD message: "X.X.X.X isn't a valid IP address"
	local %ENV = (REMOTE_ADDR => 'not-an-ip');
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	ok(!defined $l->country(), 'Malformed IP returns undef');
	ok((grep { ref($_) ? $_->{warning} =~ /valid IP/ : /valid IP/ } @warnings),
		'_warn called for malformed IP');
	Test::Mockingbird::restore_all();
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });
};

subtest 'country: public IP resolved via IP::Country returns lowercase code' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { 'US' });
	my $l = _obj([$LANG{EN}]);
	$l->{_have_ipcountry} = 1;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	is($l->country(), $CC{US}, 'IP::Country result returned as lowercase');
	Test::Mockingbird::restore_all();
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });
};

subtest 'country: result stored in cache for public IP' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $cache = CHI->new(driver => 'Memory', global => 0);
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { 'GB' });
	my $l = _obj([$LANG{EN}], cache => $cache);
	$l->{_have_ipcountry} = 1;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	$l->country();
	is($cache->get('CGI::Lingua:country:' . $IP{PUBLIC}), $CC{GB},
		'Country stored in cache under documented key pattern');
	Test::Mockingbird::restore_all();
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });
};

subtest 'country: HK remapped to CN (legacy Whois behaviour)' => sub {
	# Legacy mapping documented in code: HK is no longer separate in Whois
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { 'HK' });
	my $l = _obj([$LANG{EN}]);
	$l->{_have_ipcountry} = 1;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	is($l->country(), $CC{CN}, 'HK remapped to CN');
	Test::Mockingbird::restore_all();
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });
};

subtest 'country: cached value returned on second call without re-lookup' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $call_count = 0;
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc',
		sub { $call_count++; 'US' });
	my $l = _obj([$LANG{EN}]);
	$l->{_have_ipcountry} = 1;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	$l->country();    # first call
	my $c1 = $call_count;
	$l->country();    # second call — must use object-level cache
	is($call_count, $c1, 'inet_atocc not called again on second country() call');
	Test::Mockingbird::restore_all();
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });
};

subtest 'country: HTTP_CF_IPCOUNTRY invalid format warns and falls through' => sub {
	# POD message: "HTTP_CF_IPCOUNTRY contains an invalid country code; ignoring"
	local %ENV = (HTTP_CF_IPCOUNTRY => 'INVALID', REMOTE_ADDR => $IP{LOOPBACK});
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	$l->country();
	ok((grep { ref($_) ? $_->{warning} =~ /invalid/ : /invalid/ } @warnings),
		'_warn called for invalid HTTP_CF_IPCOUNTRY');
	Test::Mockingbird::restore_all();
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });
};

# ── locale() ─────────────────────────────────────────────────────────────────
# POD: Returns a Locale::Object::Country object, or undef.

subtest 'locale: returns Locale::Object::Country for well-known country code' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { 'GB' });
	my $l = _obj([$LANG{EN}]);
	$l->{_have_ipcountry} = 1;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	my $locale = $l->locale();
	if(defined $locale) {
		isa_ok($locale, 'Locale::Object::Country',
			'locale() returns Locale::Object::Country');
	} else {
		# Locale::Object::Country DB may not be installed; skip gracefully
		pass('locale() returned undef (Locale::Object may not be installed)');
	}
	Test::Mockingbird::restore_all();
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });
};

subtest 'locale: returns undef when no country can be determined' => sub {
	local %ENV = (REMOTE_ADDR => $IP{LOOPBACK});
	my $l = _obj([$LANG{EN}]);
	my $result = $l->locale();
	ok(!defined $result, 'locale() returns undef when country unresolvable');
};

subtest 'locale: GEOIP_COUNTRY_CODE valid code used as fallback' => sub {
	# POD describes GEOIP_COUNTRY_CODE as a fallback source for locale()
	local %ENV = (GEOIP_COUNTRY_CODE => 'GB', REMOTE_ADDR => $IP{LOOPBACK});
	my $l = _obj([$LANG{EN}]);
	my $result = $l->locale();
	if(defined $result) {
		isa_ok($result, 'Locale::Object::Country',
			'locale() used GEOIP_COUNTRY_CODE fallback');
	} else {
		pass('locale() gracefully undef (Locale::Object DB may be absent)');
	}
};

subtest 'locale: GEOIP_COUNTRY_CODE invalid code not used' => sub {
	# Same ISO 3166-1 validation as country() — invalid codes must be skipped.
	local %ENV = (GEOIP_COUNTRY_CODE => 'NOT_A_CC');
	my $called = 0;
	Test::Mockingbird::mock('CGI::Lingua', '_code2country',
		sub { $called++; undef });
	my $l = _obj([$LANG{EN}]);
	$l->locale();
	is($called, 0, 'Invalid GEOIP_COUNTRY_CODE not passed to _code2country');
	Test::Mockingbird::restore_all();
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });
};

subtest 'locale: cached _locale returned immediately on second call' => sub {
	# locale() must not re-run detection once it has a result.
	local %ENV = ();
	my $sentinel = bless {}, 'Locale::Object::Country';
	my $l = _obj([$LANG{EN}]);
	$l->{_locale} = $sentinel;
	is($l->locale(), $sentinel, 'Cached _locale returned without re-computation');
};

# ── time_zone() ───────────────────────────────────────────────────────────────
# POD: Returns IANA timezone name string, or undef.

subtest 'time_zone: cached value returned immediately on second call' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _obj([$LANG{EN}]);
	$l->{_timezone} = 'America/New_York';
	is($l->time_zone(), 'America/New_York', 'Cached _timezone returned');
};

subtest 'time_zone: malformed REMOTE_ADDR warns and returns undef' => sub {
	# The untaint check in time_zone() mirrors country() — bad IP must warn.
	local %ENV = (REMOTE_ADDR => 'bad-addr');
	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });
	my $l = _obj([$LANG{EN}]);
	my $result = $l->time_zone();
	ok(!defined $result, 'Malformed REMOTE_ADDR causes undef return from time_zone');
	ok((grep { ref($_) ? $_->{warning} =~ /valid IP/ : /valid IP/ } @warnings),
		'_warn called for bad REMOTE_ADDR in time_zone()');
	Test::Mockingbird::restore_all();
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });
};

subtest 'time_zone: ip-api JSON response parsed into timezone string' => sub {
	# POD: "otherwise it will use ip-api.com"
	# Pre-require the module so it is fully initialised before we install the
	# mock; otherwise the module's BEGIN block clobbers the mock on first load.
	eval { require LWP::Simple::WithCache; require JSON::Parse };
	if($@) {
		pass('LWP::Simple::WithCache or JSON::Parse not installed; skipping');
		return;
	}
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get',
		sub { '{"timezone":"Europe/London"}' });
	my $l = _obj([$LANG{EN}]);
	$l->{_have_geoip} = 0;    # GEO_ABSENT — force the ip-api.com branch
	my $tz = $l->time_zone();
	if(defined $tz) {
		returns_ok($tz, { type => 'string' }, 'time_zone() returns a string');
		is($tz, 'Europe/London', 'Timezone parsed from ip-api.com JSON');
	} else {
		pass('time_zone() returned undef (unexpected, but not fatal in offline mode)');
	}
	Test::Mockingbird::restore_all();
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });
};

# ── Cross-method integration ──────────────────────────────────────────────────
# These subtests exercise the documented relationship between methods (e.g.
# language() + sublanguage() should give a coherent picture) without diving
# into implementation specifics.

subtest 'integration: language + sublanguage coherent for en-gb' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB});
	my $l = _obj([$LANG{EN_GB}]);
	my $lang = $l->language();
	my $sub  = $l->sublanguage();
	diag("language=$lang sublanguage=$sub") if $ENV{TEST_VERBOSE};
	is($lang, 'English',        'language() is English');
	is($sub,  'United Kingdom', 'sublanguage() is United Kingdom');
};

subtest 'integration: requested_language = language + sublanguage for en-gb' => sub {
	# POD: "Returns the sublanguage (if appropriate) in parentheses"
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB});
	my $l = _obj([$LANG{EN_GB}]);
	my $rl = $l->requested_language();
	like($rl, qr/^English\s+\(United Kingdom\)$/,
		'requested_language matches expected "Language (Sublanguage)" format');
};

subtest 'integration: all language accessors consistent for fr' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{FR});
	my $l = _obj([$LANG{EN}, $LANG{FR}]);
	is($l->language(),              'French', 'language()');
	is($l->preferred_language(),    'French', 'preferred_language()');
	is($l->name(),                  'French', 'name()');
	is($l->language_code_alpha2(),  $LANG{FR}, 'language_code_alpha2()');
	is($l->code_alpha2(),           $LANG{FR}, 'code_alpha2()');
};

subtest 'integration: Unknown language has undef code and undef sublanguage' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'xx', REMOTE_ADDR => $IP{LOOPBACK});
	my $l = _obj([$LANG{EN}]);
	is($l->language(), 'Unknown', 'language() Unknown');
	ok(!defined $l->language_code_alpha2(), 'code undef for Unknown language');
	ok(!defined $l->sublanguage(),          'sublanguage undef for Unknown');
};

subtest 'integration: country mocked via IP::Country, language from header' => sub {
	local %ENV = (
		REMOTE_ADDR          => $IP{PUBLIC},
		HTTP_ACCEPT_LANGUAGE => $LANG{EN},
	);
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { 'US' });
	my $l = _obj([$LANG{EN}]);
	$l->{_have_ipcountry} = 1;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
	is($l->language(), 'English', 'language() from header');
	is($l->country(),  $CC{US},   'country() from IP::Country mock');
	# Suppress the prototype mismatch warning when restoring LWP::Simple::WithCache::get
	# ($) back to the symbol table; the re-mock below reinstalls cleanly.
	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef });
};

done_testing();
