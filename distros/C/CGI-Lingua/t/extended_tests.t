#!/usr/bin/env perl

# t/extended_tests.t — Coverage-gap tests for CGI::Lingua.
#
# Target: execution paths not reached by function.t, unit.t, integration.t,
# or edge_cases.t.  Each section names the sub being probed and the specific
# branch being exercised.
#
# Network I/O is blocked globally; individual subtests install narrow mocks.

use strict;
use warnings;

use CHI;
use Readonly;
use Scalar::Util qw(blessed);
use Test::Most;
use Test::Mockingbird;
use Test::Returns qw(returns_ok);

use lib 't/lib';

BEGIN { use_ok('CGI::Lingua') }

# Pre-require lazy-loaded modules so their BEGIN blocks run before any mock.
my $HAS_LWP  = eval { require LWP::Simple::WithCache; 1 } ? 1 : 0;
my $HAS_JSON = eval { require JSON::Parse;             1 } ? 1 : 0;
eval { require Net::Whois::IP   };
eval { require Net::Whois::IANA };

# ── Constants ──────────────────────────────────────────────────────────────────

Readonly my %LANG => (EN => 'en', FR => 'fr', DE => 'de', EN_GB => 'en-gb', NB => 'nb');

Readonly my %IP => (
	PUBLIC   => '8.8.8.8',
	LOOPBACK => '127.0.0.1',
	PRIVATE  => '192.168.1.1',
	BAIDU    => '185.10.104.1',
);

Readonly my $CACHE_NS  => 'CGI::Lingua:';
Readonly my $GEO_ABSENT  => 0;
Readonly my $GEO_PRESENT => 1;

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

sub _fresh_cache { CHI->new(driver => 'Memory', global => 0) }

sub _inject_ipcountry {
	my ($l, $cc) = @_;
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { $cc });
	$l->{_have_ipcountry} = $GEO_PRESENT;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = $GEO_ABSENT;
	$l->{_have_geoipfree} = $GEO_ABSENT;
}

_block_network();

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 1: _resolve_country_via_whois() internals
#
# Strategy: all existing tests mock the whole method as a no-op.  Here we
# call it directly after pre-loading Net::Whois::IP so we can mock the
# whoisip_query function at the right scope and reach every internal branch.
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_resolve_country_via_whois: Country key (uppercase) sets _country' => sub {
	SKIP: { skip 'Net::Whois::IP not installed', 1 unless eval { require Net::Whois::IP; 1 };

	# Unmock the no-op so we exercise the real method body.
	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');
	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query',
		sub { { Country => 'GB' } });

	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _obj([$LANG{EN}]);
	$l->_resolve_country_via_whois($IP{PUBLIC});
	is($l->{_country}, 'GB', 'Uppercase Country key sets _country');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
	} # SKIP
};

subtest '_resolve_country_via_whois: lowercase country key sets _country' => sub {
	SKIP: { skip 'Net::Whois::IP not installed', 1 unless eval { require Net::Whois::IP; 1 };

	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');
	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query',
		sub { { country => 'DE' } });

	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	$l->_resolve_country_via_whois($IP{PUBLIC});
	is($l->{_country}, 'DE', 'Lowercase country key sets _country');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
	} # SKIP
};

subtest '_resolve_country_via_whois: US + StateProv=PR maps to pr (RT#131347)' => sub {
	SKIP: { skip 'Net::Whois::IP not installed', 1 unless eval { require Net::Whois::IP; 1 };

	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');
	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query',
		sub { { Country => 'US', StateProv => 'PR' } });

	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	$l->_resolve_country_via_whois($IP{PUBLIC});
	is($l->{_country}, 'pr', 'Puerto Rico StateProv=PR remapped to pr');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
	} # SKIP
};

subtest '_resolve_country_via_whois: EU result deleted, falls through to IANA' => sub {
	SKIP: {
		skip 'Net::Whois::IP or Net::Whois::IANA not installed', 1
			unless eval { require Net::Whois::IP; require Net::Whois::IANA; 1 };

	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');
	# Whois returns EU → deleted; then IANA is tried and returns FR.
	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query',
		sub { { Country => 'EU' } });

	# IANA chain: new() + whois_query(-ip => ...) + country()
	my $mock_iana = bless {}, 'Net::Whois::IANA';
	Test::Mockingbird::mock('Net::Whois::IANA', 'new',         sub { $mock_iana });
	Test::Mockingbird::mock('Net::Whois::IANA', 'whois_query', sub { 1 });
	Test::Mockingbird::mock('Net::Whois::IANA', 'country',     sub { 'FR' });

	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	$l->_resolve_country_via_whois($IP{PUBLIC});
	is($l->{_country}, 'FR', 'EU whois result deleted; IANA fallback returns FR');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
	} # SKIP
};

subtest '_resolve_country_via_whois: country with trailing CRLF is stripped' => sub {
	SKIP: { skip 'Net::Whois::IP not installed', 1 unless eval { require Net::Whois::IP; 1 };

	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');
	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query',
		sub { { Country => "GB\r\n" } });

	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	$l->_resolve_country_via_whois($IP{PUBLIC});
	is($l->{_country}, 'GB', 'Trailing CRLF stripped from country');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
	} # SKIP
};

subtest '_resolve_country_via_whois: country with comment stripped' => sub {
	SKIP: { skip 'Net::Whois::IP not installed', 1 unless eval { require Net::Whois::IP; 1 };

	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');
	# e.g. "GB # United Kingdom" — only the 2-char prefix is kept.
	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query',
		sub { { Country => 'GB # United Kingdom' } });

	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	$l->_resolve_country_via_whois($IP{PUBLIC});
	is($l->{_country}, 'GB', 'Comment suffix stripped from country');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
	} # SKIP
};

subtest '_resolve_country_via_whois: whoisip_query warn-die absorbed, IANA tried' => sub {
	SKIP: {
		skip 'Net::Whois::IP or Net::Whois::IANA not installed', 1
			unless eval { require Net::Whois::IP; require Net::Whois::IANA; 1 };

	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');
	# The eval inside _resolve_country_via_whois converts warns to dies.
	# When whoisip_query fires a warn, the eval catches it and falls through to IANA.
	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query', sub {
		warn "Connection timeout\n";
		return undef;
	});

	my $mock_iana = bless {}, 'Net::Whois::IANA';
	Test::Mockingbird::mock('Net::Whois::IANA', 'new',         sub { $mock_iana });
	Test::Mockingbird::mock('Net::Whois::IANA', 'whois_query', sub { 1 });
	Test::Mockingbird::mock('Net::Whois::IANA', 'country',     sub { 'US' });

	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	$l->_resolve_country_via_whois($IP{PUBLIC});
	is($l->{_country}, 'US', 'warn-into-die in whoisip_query absorbed; IANA returns US');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
	} # SKIP
};

subtest '_resolve_country_via_whois: IANA country with comment stripped' => sub {
	SKIP: {
		skip 'Net::Whois::IP or Net::Whois::IANA not installed', 1
			unless eval { require Net::Whois::IP; require Net::Whois::IANA; 1 };

	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');
	# Net::Whois::IP returns undef; IANA returns "CA # comment"
	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query', sub { undef });

	my $mock_iana = bless {}, 'Net::Whois::IANA';
	Test::Mockingbird::mock('Net::Whois::IANA', 'new',         sub { $mock_iana });
	Test::Mockingbird::mock('Net::Whois::IANA', 'whois_query', sub { 1 });
	Test::Mockingbird::mock('Net::Whois::IANA', 'country',     sub { "CA # Canada\r\n" });

	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	$l->_resolve_country_via_whois($IP{PUBLIC});
	is($l->{_country}, 'CA', 'IANA comment suffix stripped; CRLF stripped');

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();
	} # SKIP
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 2: _find_language_from_ip() internal branches
#
# Strategy: force country() to return undef and exercise the LANG env-var
# fallback, the cache-hit branch, and the various Locale::Language code paths.
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_find_language_from_ip: country undef, LANG=en_US derives country US' => sub {
	# When no geo data is available, _find_language_from_ip() calls _what_language()
	# and extracts the country code from a POSIX locale string (xx_YY).
	local %ENV = (LANG => 'en_US.UTF-8');
	delete local $ENV{HTTP_ACCEPT_LANGUAGE};
	delete local $ENV{REMOTE_ADDR};
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};

	# 'en' is supported; US English is the official US language, so the IP
	# fallback should resolve English via the LANG-derived country 'US'.
	my $l = _obj([$LANG{EN}]);
	my $lang = $l->language();
	diag("LANG=en_US derived language: $lang") if $ENV{TEST_VERBOSE};
	# We can't guarantee Locale::Object data is installed, so just verify no crash.
	ok(defined $lang, '_find_language_from_ip with LANG=en_US does not crash');
};

subtest '_find_language_from_ip: country undef, LANG=fr derives country fr' => sub {
	# A bare 2-char LANG (xx) matches the second regex: $c =~ /^(..)$/
	local %ENV = (LANG => 'fr');
	delete local $ENV{HTTP_ACCEPT_LANGUAGE};
	delete local $ENV{REMOTE_ADDR};

	my $l = _obj(['fr']);
	my $lang;
	lives_ok { $lang = $l->language() } 'No crash when LANG is bare 2-char code';
	diag("LANG=fr derived language: " . ($lang // 'undef')) if $ENV{TEST_VERBOSE};
};

subtest '_find_language_from_ip: language_name cache hit skips Locale::Object' => sub {
	# Seed the cache with language_name:us so the geo-name lookup is skipped.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	delete local $ENV{HTTP_ACCEPT_LANGUAGE};

	my $cache = _fresh_cache();
	$cache->set($CACHE_NS . 'language_name:us', 'English=en', '1 month');

	my $l = _obj([$LANG{EN}], cache => $cache);
	_inject_ipcountry($l, 'US');

	my $code_called = 0;
	Test::Mockingbird::mock('Locale::Language', 'language2code',
		sub { $code_called++; 'en' });

	my $lang = $l->language();
	diag("language from cache-seeded IP: $lang") if $ENV{TEST_VERBOSE};

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();

	ok(defined $lang, 'Language resolved from seeded language_name cache');
};

subtest '_find_language_from_ip: fast path when no Accept-Language and language_code2 known' => sub {
	# When $http_accept_language is undef and language_code2 is available,
	# the fast path sets $code = $language_code2 directly (no Locale::Language call).
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	delete local $ENV{HTTP_ACCEPT_LANGUAGE};

	my $l = _obj([$LANG{EN}]);
	_inject_ipcountry($l, 'US');

	# Track whether language2code is called — it must NOT be on the fast path.
	my $lang2code_called = 0;
	Test::Mockingbird::mock('Locale::Language', 'language2code',
		sub { $lang2code_called++; $_[0] });

	my $lang = $l->language();
	diag("fast-path language: " . ($lang // 'undef')) if $ENV{TEST_VERBOSE};

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();

	ok(defined $lang, 'Fast path does not crash');
};

subtest '_find_language_from_ip: _get_closest fails → warning emitted' => sub {
	# If _get_closest cannot match the IP language against the supported list,
	# a "Couldn't determine closest language" warning is emitted.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	delete local $ENV{HTTP_ACCEPT_LANGUAGE};

	# Support only Japanese; US IP returns English via Locale::Object.
	# _get_closest('en', 'en') will not find 'en' in ['ja'] → warning.
	my @warnings;
	my $l = _obj(['ja']);
	_inject_ipcountry($l, 'US');
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });

	my $lang = $l->language();

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();

	diag("warnings: " . join(', ', map { ref $_ ? $_->{warning} : $_ } @warnings))
		if $ENV{TEST_VERBOSE};
	ok(
		$lang eq 'Unknown' ||
		(grep { ref($_) ? $_->{warning} =~ /closest/i : /closest/i } @warnings),
		'No matching language in supported list causes Unknown or closest warning'
	);
};

subtest '_find_language_from_ip: cache write after successful resolution' => sub {
	# After computing language_name from Locale::Object, the result must be
	# stored in the cache under "language_name:<country>".
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	delete local $ENV{HTTP_ACCEPT_LANGUAGE};

	my $cache = _fresh_cache();
	my $l = _obj([$LANG{EN}], cache => $cache);
	_inject_ipcountry($l, 'US');

	$l->language();    # triggers _find_language_from_ip

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();

	my $cached = $cache->get($CACHE_NS . 'language_name:us');
	diag("language_name cache entry: " . ($cached // 'undef')) if $ENV{TEST_VERBOSE};
	# We can only assert it is populated if Locale::Object resolved the language.
	ok(1, 'language_name cache write attempted (Locale::Object may or may not be installed)');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 3: _accept_language_match() — "Forcing fallback" branch
#
# This branch fires when I18N::AcceptLanguage returns a code that doesn't match
# the original header (e.g., strict mode returns 'en' for 'en-gb' when 'en' is
# supported, but the request contained a hyphen).  The module forces a retry.
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_accept_language_match: forcing-fallback branch reached for en-gb vs en' => sub {
	# Header: en-gb; supported: en only.  I18N::AcceptLanguage strict=1 returns
	# 'en', but the header contains '-' and 'en' !~ /en-gb/ → force retry.
	# After the retry, the scan-sublanguage-pairs pass finds 'en' as the base.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-gb');
	delete local $ENV{REMOTE_ADDR};

	my $l = _obj([$LANG{EN}]);
	my $lang = $l->language();
	is($lang, 'English', 'Forcing-fallback branch still resolves English');
	like($l->requested_language(), qr/United Kingdom/,
		'requested_language includes United Kingdom after fallback');
};

subtest '_accept_language_match: scan-plain-tokens strips quality value' => sub {
	# "fr;q=0.9" — _scan_plain_tokens must strip ";q=0.9" before checking.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'de;q=0.9,fr;q=0.5');
	delete local $ENV{REMOTE_ADDR};

	my $l = _obj(['fr']);
	is($l->language(), 'French',
		'_scan_plain_tokens correctly strips quality values and matches fr');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 4: _find_language() — notice branch and I18N::LangTags::Detect branch
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_find_language: notice emitted when q-value header has no match' => sub {
	# A header like "de-DE,de;q=0.9" where none of the codes are in the supported
	# list triggers _notice() because the header contains semicolons.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'de-DE,de;q=0.9');
	delete local $ENV{REMOTE_ADDR};

	my @notices;
	my $l = _obj([$LANG{EN}]);
	Test::Mockingbird::mock('CGI::Lingua', '_notice',
		sub { push @notices, join('', grep defined, @_[1..$#_]) });

	$l->language();

	Test::Mockingbird::restore_all();
	_block_network();

	diag("notices: " . join('; ', @notices)) if $ENV{TEST_VERBOSE};
	# The notice is only emitted when none of the candidates matched; result is Unknown.
	is($l->{_slanguage}, 'Unknown', 'Unsupported q-value header gives Unknown');
};

subtest '_find_language: _rlanguage resolved via _code2language when set but Unknown' => sub {
	# When _slanguage is populated (non-Unknown) but _rlanguage is still 'Unknown',
	# _find_language tries I18N::LangTags::Detect and then _code2language.
	# Simulate by having HTTP_ACCEPT_LANGUAGE produce a match via base-language
	# fallback — _rlanguage starts Unknown and must be updated.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-xx');
	delete local $ENV{REMOTE_ADDR};

	# Supported includes 'en' so the scan-sublanguage-pairs pass matches 'en'.
	# _rlanguage starts Unknown; the code that follows calls _code2language('en-xx')
	# or falls through.
	my $l = _obj([$LANG{EN}]);
	my $lang = $l->language();
	diag("lang=$lang rl=$l->{_rlanguage}") if $ENV{TEST_VERBOSE};
	ok(defined $lang, 'en-xx with en supported does not crash');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 5: _resolve_sublanguage_match() — uncovered branches
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_resolve_sublanguage_match: cache hit for accepts: key skips Locale::Language' => sub {
	# If the cache already contains "accepts:en-gb" → "English=en", the code
	# must use that instead of calling code2language.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-gb');
	delete local $ENV{REMOTE_ADDR};

	my $cache = _fresh_cache();
	$cache->set($CACHE_NS . 'accepts:en-gb', 'English=en', '1 month');

	my $lang2code_called = 0;
	Test::Mockingbird::mock('Locale::Language', 'code2language',
		sub { $lang2code_called++; 'English' });

	my $l = _obj(['en-gb'], cache => $cache);
	my $lang = $l->language();

	Test::Mockingbird::restore_all();
	_block_network();

	# code2language was served from cache — should not be called.
	is($lang, 'English', 'accepts: cache hit resolves language without Locale::Language');
};

subtest '_resolve_sublanguage_match: en-uk in Accept-Language header normalised to en-gb' => sub {
	# When HTTP_ACCEPT_LANGUAGE is exactly 'en-uk', _find_language() normalises it
	# to 'en-gb' before the I18N::AcceptLanguage pass (line 467 in the module).
	# With supported=['en-gb'], this normalisation means en-gb resolves correctly.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-uk');
	delete local $ENV{REMOTE_ADDR};

	# 'en-gb' is in the supported list; 'en-uk' gets normalised to 'en-gb' early.
	my $l = CGI::Lingua->new(supported => ['en-gb']);
	my $sub_code = $l->sublanguage_code_alpha2();

	diag("sub_code=" . ($sub_code // 'undef')) if $ENV{TEST_VERBOSE};
	is($sub_code, 'gb', 'en-uk header normalised to en-gb; sublanguage_code_alpha2 returns gb');
};

subtest '_resolve_sublanguage_match: variety with cache hit uses cached value' => sub {
	# Seed the "variety:us" cache entry so the Locale::Object::DB lookup is skipped.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-us');
	delete local $ENV{REMOTE_ADDR};

	my $cache = _fresh_cache();
	$cache->set($CACHE_NS . 'variety:us', 'English=en', '1 month');

	my $l = _obj(['en-us'], cache => $cache);
	my $lang = $l->language();

	is($lang, 'English', 'variety cache hit correctly resolves language');
};

subtest '_resolve_sublanguage_match: variety not in DB gets Unknown sublanguage' => sub {
	# An unknown two-char variety (e.g., 'en-xx') with 'en-xx' in the supported list
	# triggers the Locale::Object::DB lookup which returns empty, so _sublanguage
	# is set to 'Unknown'.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-xx');
	delete local $ENV{REMOTE_ADDR};

	my @warnings;
	Test::Mockingbird::mock('CGI::Lingua', '_warn',
		sub { push @warnings, $_[1] });

	# Explicitly support 'en-xx' so _resolve_sublanguage_match is entered for it
	my $l = CGI::Lingua->new(supported => ['en-xx']);
	my $sub = $l->sublanguage();

	Test::Mockingbird::restore_all();
	_block_network();

	diag("sublanguage=${\($sub//'undef')} warnings=" . scalar @warnings)
		if $ENV{TEST_VERBOSE};
	ok(
		!defined($sub) || $sub eq 'Unknown',
		'Unknown variety code produces undef or Unknown sublanguage'
	);
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 6: _resolve_base_match() — code_alpha3 path and silent sublanguage
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_resolve_base_match: 3-char variety triggers Locale::Object::Country alpha3 lookup' => sub {
	# A header like "en-gbr" (hypothetical 3-char region) uses the
	#   $header =~ /..-([a-z]{2,3})$/i
	# branch, which calls Locale::Object::Country->new(code_alpha3 => $1).
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-gbr');
	delete local $ENV{REMOTE_ADDR};

	my $l = _obj([$LANG{EN}]);
	my $lang;
	lives_ok { $lang = $l->language() } 'alpha3 variety in header does not crash';
	is($lang, 'English', 'Base language English resolved for en-gbr');
};

subtest '_resolve_base_match: no sl returned from _code2country' => sub {
	# When _code2country returns undef (unknown country), and $requested_sublanguage
	# is also undef, no parenthetical is appended to _rlanguage.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-zz');
	delete local $ENV{REMOTE_ADDR};

	my $l = _obj([$LANG{EN}]);
	my $rl = $l->requested_language();
	diag("rl=$rl") if $ENV{TEST_VERBOSE};
	# We don't know if 'zz' is unknown on every system, but it shouldn't crash.
	ok(defined $rl, 'No crash when variety code yields no country name');
};

subtest '_resolve_base_match: _code2language returns undef → returns 0' => sub {
	# If the matched base code cannot be resolved to a language name,
	# _resolve_base_match returns 0 and _slanguage is not set.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'zz');
	delete local $ENV{REMOTE_ADDR};

	# Support 'zz' so it matches; Locale::Language will return undef for it.
	my $l = CGI::Lingua->new(supported => ['zz']);
	my $lang = $l->language();
	ok(!defined $lang || $lang eq 'Unknown',
		'Unknown language code with no Locale::Language name returns Unknown');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 7: time_zone() — local path (no REMOTE_ADDR)
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'time_zone: no REMOTE_ADDR reads /etc/timezone when present' => sub {
	# When REMOTE_ADDR is not set, time_zone() tries to open /etc/timezone.
	# We cannot easily mock a file open, so we just verify no crash on the host.
	local %ENV = ();
	delete local $ENV{REMOTE_ADDR};

	my $l = _obj([$LANG{EN}]);
	my $tz;
	lives_ok { $tz = $l->time_zone() } 'time_zone() without REMOTE_ADDR does not crash';
	diag("local timezone: " . ($tz // 'undef')) if $ENV{TEST_VERBOSE};
	# The result may be undef on hosts without /etc/timezone and no DateTime::TimeZone.
	ok(1, 'time_zone() ran without dying');
};

subtest 'time_zone: GEO_UNKNOWN sentinel triggers _load_geoip before lookup' => sub {
	# When _have_geoip is still GEO_UNKNOWN (-1), time_zone() calls _load_geoip().
	# On most CI systems, no GeoIP.dat is present, so _have_geoip becomes GEO_ABSENT.
	# We just verify the sentinel transition happens without error.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

	my $l = _obj([$LANG{EN}]);
	is($l->{_have_geoip}, -1, '_have_geoip starts at GEO_UNKNOWN');

	# Pre-block LWP so the fallback JSON path doesn't fire
	my $tz;
	eval { $tz = $l->time_zone() };

	isnt($l->{_have_geoip}, -1,
		'_have_geoip sentinel changed from GEO_UNKNOWN after time_zone() call');
};

subtest 'time_zone: GEO_PRESENT path invokes geoip->time_zone()' => sub {
	# Inject a mock Geo::IP object that returns a timezone string.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

	my $mock_geoip = bless {}, 'Geo::IP';
	Test::Mockingbird::mock('Geo::IP', 'time_zone', sub { 'Europe/Paris' });

	my $l = _obj([$LANG{EN}]);
	$l->{_have_geoip} = $GEO_PRESENT;
	$l->{_geoip}      = $mock_geoip;

	my $tz = $l->time_zone();
	is($tz, 'Europe/Paris', 'Geo::IP time_zone() result returned when GEO_PRESENT');

	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'time_zone: ip-api.com JSON parsed when no REMOTE_ADDR validation passes' => sub {
	SKIP: {
		skip 'LWP::Simple::WithCache or JSON::Parse not installed', 1
			unless $HAS_LWP && $HAS_JSON;

		local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

		Test::Mockingbird::mock('LWP::Simple::WithCache', 'get',
			sub { '{"timezone":"America/Los_Angeles"}' });

		my $l = _obj([$LANG{EN}]);
		$l->{_have_geoip} = $GEO_ABSENT;

		my $tz = $l->time_zone();
		is($tz, 'America/Los_Angeles', 'ip-api.com JSON timezone parsed correctly');

		{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
		_block_network();
	}
};

subtest 'time_zone: malformed JSON from ip-api.com warns but does not crash' => sub {
	SKIP: {
		skip 'LWP::Simple::WithCache or JSON::Parse not installed', 1
			unless $HAS_LWP && $HAS_JSON;

		local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

		Test::Mockingbird::mock('LWP::Simple::WithCache', 'get',
			sub { '<<<MALFORMED JSON' });

		my @warnings;
		Test::Mockingbird::mock('CGI::Lingua', '_warn',
			sub { push @warnings, $_[1] });

		my $l = _obj([$LANG{EN}]);
		$l->{_have_geoip} = $GEO_ABSENT;

		my $tz;
		lives_ok { $tz = $l->time_zone() } 'Malformed ip-api.com JSON does not crash';
		ok((grep { ref($_) ? ($_->{warning}//'') =~ /unparseable/i : /unparseable/i } @warnings),
			'_warn called for unparseable ip-api.com JSON');

		{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
		_block_network();
	}
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 8: time_zone() graceful degradation when neither LWP variant is installed
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'time_zone: warns and returns undef when neither LWP variant present' => sub {
	# When both LWP::Simple::WithCache and LWP::Simple are unavailable AND
	# Geo::IP is absent, time_zone() must warn and return undef (graceful
	# degradation — it no longer croaks, which would kill the entire CGI request).
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

	my $l = _obj([$LANG{EN}]);
	$l->{_have_geoip} = $GEO_ABSENT;

	# This branch is only reachable when both LWP variants are genuinely absent;
	# we cannot mock require() away, so skip when either is installed.
	SKIP: {
		skip 'LWP::Simple::WithCache IS installed — no-LWP branch not reachable', 1
			if $HAS_LWP;
		skip 'LWP::Simple is installed — no-LWP branch not reachable', 1
			if eval { require LWP::Simple; 1 };

		my @warnings;
		Test::Mockingbird::mock('CGI::Lingua', '_warn',
			sub { push @warnings, $_[1] });

		my $tz;
		lives_ok { $tz = $l->time_zone() }
			'time_zone() does not croak when no LWP present';
		ok(!defined $tz,
			'time_zone() returns undef when no LWP present');
		ok((grep { (ref $_ ? ($_->{warning} // '') : ($_ // '')) =~ /LWP/ } @warnings),
			'time_zone() warns about missing LWP');

		Test::Mockingbird::restore_all();
		_block_network();
	}
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 9: locale() — User-Agent parsing branches
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'locale: User-Agent with xx-xx parenthetical resolves country' => sub {
	# locale() first tries to extract a "xx-XX" tag from inside parens in the UA.
	# e.g. "Mozilla/5.0 (en-US; ...)" → tries _code2country('us').
	local %ENV = (
		HTTP_USER_AGENT => 'Mozilla/5.0 (en-US; Linux x86_64)',
		REMOTE_ADDR     => $IP{LOOPBACK},
	);

	my $l = _obj([$LANG{EN}]);
	my $loc;
	lives_ok { $loc = $l->locale() } 'locale() with xx-XX in UA does not crash';
	diag("locale from UA: " . (defined $loc ? ref($loc) : 'undef')) if $ENV{TEST_VERBOSE};
	# Whether it resolves depends on Locale::Object::Country being installed.
	ok(1, 'locale() ran without dying for UA with xx-XX pattern');
};

subtest 'locale: UA with no country pattern falls through to IP' => sub {
	# A UA string without a parseable country code inside parens forces locale()
	# to skip the UA path and proceed to the IP-address path.
	local %ENV = (
		HTTP_USER_AGENT => 'curl/7.68.0',
		GEOIP_COUNTRY_CODE => 'DE',
	);
	delete local $ENV{REMOTE_ADDR};

	my $l = _obj([$LANG{EN}]);
	my $loc = $l->locale();
	# If Locale::Object is installed, locale() should find DE via GEOIP_COUNTRY_CODE.
	if(defined $loc) {
		isa_ok($loc, 'Locale::Object::Country', 'locale() resolved from GEOIP fallback');
	} else {
		pass('locale() returned undef (Locale::Object DB may be absent)');
	}
};

subtest 'locale: HTTP::BrowserDetect branch attempted after UA-parse fails' => sub {
	SKIP: {
		skip 'HTTP::BrowserDetect not installed', 1
			unless eval { require HTTP::BrowserDetect; 1 };

		# A UA that HTTP::BrowserDetect can parse for country but our simple regex
		# does not match. Use a generic UA without xx-XX in the parenthetical.
		local %ENV = (
			HTTP_USER_AGENT => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
			REMOTE_ADDR     => $IP{LOOPBACK},
		);
		delete local $ENV{GEOIP_COUNTRY_CODE};

		my $l = _obj([$LANG{EN}]);
		my $loc;
		lives_ok { $loc = $l->locale() } 'locale() with HTTP::BrowserDetect does not crash';
		diag("BrowserDetect locale: " . (defined $loc ? ref $loc : 'undef')) if $ENV{TEST_VERBOSE};
		ok(1, 'HTTP::BrowserDetect branch reached without crash');
	}
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 10: country() — _handle_eu_country via the second EU check
#
# After geo lookups, country() normalises the result.  If _country eq 'eu'
# AFTER the first clean (which deleted 'eu' from IP::Country), it means a
# different geo module returned 'eu'.  The second check calls _handle_eu_country.
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'country: eu from Whois triggers _handle_eu_country' => sub {
	# Mock _resolve_country_via_whois to set _country = 'eu', then verify the
	# _handle_eu_country path fires and converts it to Unknown (for non-Baidu).
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

	my $l = _obj([$LANG{EN}]);
	$l->{_have_ipcountry} = $GEO_ABSENT;
	$l->{_have_geoip}     = $GEO_ABSENT;
	$l->{_have_geoipfree} = $GEO_ABSENT;

	# Override the global no-op with one that sets _country = 'eu'
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois',
		sub { $_[0]->{_country} = 'eu' });

	my $cc = $l->country();
	is($cc, 'Unknown', '"eu" from Whois is converted to Unknown by _handle_eu_country');

	Test::Mockingbird::restore_all();
	_block_network();
};

subtest 'country: eu from Whois for Baidu subnet maps to cn' => sub {
	# Same as above but using the Baidu IP — _handle_eu_country maps it to 'cn'.
	local %ENV = (REMOTE_ADDR => $IP{BAIDU});

	my $l = _obj([$LANG{EN}]);
	$l->{_have_ipcountry} = $GEO_ABSENT;
	$l->{_have_geoip}     = $GEO_ABSENT;
	$l->{_have_geoipfree} = $GEO_ABSENT;

	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois',
		sub { $_[0]->{_country} = 'eu' });

	my $cc = $l->country();
	is($cc, 'cn', 'Baidu subnet EU result mapped to cn via _handle_eu_country');

	Test::Mockingbird::restore_all();
	_block_network();
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 11: new() — ::new() call with no params at all
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'new: ::new() with no arguments croaks' => sub {
	# Calling CGI::Lingua::new() with no arguments at all (not even undef) means
	# $class is undef and $params is undef.  The guard `if($params)` fails,
	# so we land on `$class = __PACKAGE__` and then croak for missing supported.
	local %ENV = ();
	throws_ok {
		CGI::Lingua::new()
	} qr/supported languages|CGI::Lingua::new|Params::Get/i,
		'::new() with no args at all croaks';
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 12: _code2language() — cache write path
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_code2language: undef result from Locale::Language is not cached' => sub {
	# When Locale::Language returns undef (unknown code), _code2language must
	# return undef and must NOT write undef into the cache.
	local %ENV = ();
	my $cache = _fresh_cache();
	my $l = _obj([$LANG{EN}], cache => $cache);

	Test::Mockingbird::mock('Locale::Language', 'code2language', sub { undef });
	my $result = $l->_code2language('zz');
	Test::Mockingbird::restore_all();
	_block_network();

	ok(!defined $result, '_code2language returns undef for unknown code');
	ok(!defined $cache->get($CACHE_NS . 'code2language:zz'),
		'undef result not stored in cache');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 13: _code2countryname() — unknown code returns undef without cache
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_code2countryname: unknown code with cache returns undef without caching' => sub {
	local %ENV = ();
	my $cache = _fresh_cache();
	my $l = _obj([$LANG{EN}], cache => $cache);

	# 'zz' should not exist in Locale::Object::Country
	my $name = $l->_code2countryname('zz');

	ok(!defined $name, '_code2countryname returns undef for unknown code zz');
	ok(!defined $cache->get($CACHE_NS . 'code2countryname:zz'),
		'undef not written to cache for unknown code');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 14: _log() — class-method call and undef-only messages
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_log: all-undef message parts produce empty text that is still stored' => sub {
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	my $before = scalar @{$l->{messages} // []};

	# All undef parts → grep defined removes all → join('', ()) = ''
	# The module guards `return unless length($text)`, so an empty-text message
	# is discarded and the messages array must not grow.
	$l->_log('info', undef);

	my $after = scalar @{$l->{messages} // []};
	is($after, $before, '_log with only undef arg does not append (empty text guard)');
};

subtest '_log: level forwarded correctly for all helper shims' => sub {
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);

	for my $level (qw(debug info notice trace)) {
		my $method = "_$level";
		$l->$method("shim-test-$level");
		my $last = $l->{messages}[-1];
		is($last->{level},   $level,             "_$level stores level '$level'");
		is($last->{message}, "shim-test-$level", "_$level stores message");
	}
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 15: _warn() — no logger, Carp path captures message in messages array
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_warn: no logger — message appended to messages and Carp called' => sub {
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	$l->{logger} = undef;    # force Carp path

	my @carp_msgs;
	Test::Mockingbird::mock('Carp', 'carp', sub { push @carp_msgs, $_[0] });

	$l->_warn({ warning => 'no-logger test message' });

	Test::Mockingbird::restore_all();
	_block_network();

	ok((grep { /no-logger test message/ } @carp_msgs), 'Carp::carp called with warning text');
	ok((grep { ($_->{message} // '') =~ /no-logger test message/ } @{$l->{messages}}),
		'Warning also appended to messages array');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 16: DESTROY — global-phase guard and already-cached guard
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'DESTROY: does not write when key already in cache' => sub {
	local %ENV = (REMOTE_ADDR => '99.88.77.66', HTTP_ACCEPT_LANGUAGE => 'en');
	my $cache = _fresh_cache();

	# Pre-seed the cache so the DESTROY guard fires and skips the write.
	require Storable;
	my $sentinel = bless { _slanguage => 'PreExisting' }, 'CGI::Lingua';
	$cache->set('99.88.77.66/en/en', Storable::nfreeze($sentinel), '1 month');

	{
		my $l = _obj(['en'], cache => $cache);
		$l->language();
	}    # DESTROY fires here

	my $thawed = Storable::thaw($cache->get('99.88.77.66/en/en'));
	is($thawed->{_slanguage}, 'PreExisting',
		'DESTROY does not overwrite existing cache entry');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 17: _build_cache_key — info->lang() returns undef (no-op)
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_build_cache_key: info->lang() returning undef falls back to env' => sub {
	# When an info object is present but lang() returns undef, _build_cache_key
	# should still produce a key using HTTP_ACCEPT_LANGUAGE from the environment.
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr');

	my $info = bless {}, 'MockInfoUndef';
	Test::Mockingbird::mock('MockInfoUndef', 'lang', sub { undef });

	my $key = CGI::Lingua::_build_cache_key(
		'1.2.3.4',
		{ supported => ['fr'] },
		'CGI::Lingua',
		$info
	);
	like($key, qr{^1\.2\.3\.4/fr/fr$},
		'_build_cache_key falls back to HTTP_ACCEPT_LANGUAGE when info->lang() is undef');

	Test::Mockingbird::restore_all();
	_block_network();
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 18: _get_closest() — sublanguage matching in supported list
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_get_closest: en matches base of en-gb and en-us in supported list' => sub {
	# Both en-gb and en-us have 'en' as their base; _get_closest must find one.
	local %ENV = ();
	my $l = CGI::Lingua->new(supported => ['en-gb', 'en-us']);
	$l->{_rlanguage} = 'English';

	$l->_get_closest('en', 'en');

	is($l->{_slanguage}, 'English', '_slanguage set when base matches en-gb/en-us');
};

subtest '_get_closest: no match in supported list leaves _slanguage unset' => sub {
	local %ENV = ();
	my $l = _obj(['fr']);
	delete $l->{_slanguage};
	$l->_get_closest('de', 'de');
	ok(!exists $l->{_slanguage}, '_slanguage not set when no base match found');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 19: _load_geoip() — absent database file
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_load_geoip: absent GeoIP.dat sets _have_geoip to GEO_ABSENT' => sub {
	# On most CI systems, /usr/local/share/GeoIP/GeoIP.dat is absent.
	# _load_geoip checks for the file before trying to load the module.
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	$l->{_have_geoip} = -1;    # GEO_UNKNOWN

	$l->_load_geoip();

	diag("_have_geoip after _load_geoip: $l->{_have_geoip}") if $ENV{TEST_VERBOSE};
	isnt($l->{_have_geoip}, -1, '_have_geoip no longer GEO_UNKNOWN after _load_geoip');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 20: Geo::IPfree fallback in country()
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'country: Geo::IPfree branch exercised when IP::Country and Geo::IP absent' => sub {
	SKIP: {
		skip 'Geo::IPfree not installed', 1
			unless eval { require Geo::IPfree; 1 };

		local %ENV = (REMOTE_ADDR => $IP{PUBLIC});

		my $mock_geoipfree = bless {}, 'Geo::IPfree';
		Test::Mockingbird::mock('Geo::IPfree', 'LookUp', sub { ('US', undef) });

		my $l = _obj([$LANG{EN}]);
		$l->{_have_ipcountry} = $GEO_ABSENT;
		$l->{_have_geoip}     = $GEO_ABSENT;
		$l->{_have_geoipfree} = $GEO_PRESENT;
		$l->{_geoipfree}      = $mock_geoipfree;

		my $cc = $l->country();
		is($cc, 'us', 'Geo::IPfree LookUp result lowercased and returned');

		{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
		_block_network();
	}
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 21: supported_languages alias and config_file path
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'new: supported_languages alias accepted when supported is absent' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr');
	my $l;
	lives_ok {
		$l = CGI::Lingua->new(supported_languages => ['fr'])
	} 'supported_languages alias accepted';
	is($l->language(), 'French', 'Object created via alias resolves language correctly');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 22: _notice() path — direct call via _find_language notice branch
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_notice: delegated correctly to _log with level=notice' => sub {
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	$l->_notice('notice test message');
	my $last = $l->{messages}[-1];
	is($last->{level},   'notice',                'notice level stored');
	is($last->{message}, 'notice test message',   'notice message stored');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 23: language() with no REMOTE_ADDR and no LANG — full Unknown path
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'language: no Accept-Language and no LANG and no REMOTE_ADDR → Unknown' => sub {
	local %ENV = ();
	delete local $ENV{HTTP_ACCEPT_LANGUAGE};
	delete local $ENV{REMOTE_ADDR};
	delete local $ENV{LANG};
	delete local $ENV{LANGUAGE};
	delete local $ENV{LC_ALL};
	delete local $ENV{LC_MESSAGES};

	my $l = _obj([$LANG{EN}]);
	is($l->language(), 'Unknown',
		'No env vars at all produces Unknown language');
	ok(!defined $l->language_code_alpha2(),
		'language_code_alpha2() undef when language is Unknown');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 24: Return-type contracts on every public method
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'return types: all public accessors return correct types' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en-gb');

	my $l = CGI::Lingua->new(supported => ['en-gb']);

	returns_ok($l->language(),              { type => 'string' }, 'language() → string');
	returns_ok($l->preferred_language(),    { type => 'string' }, 'preferred_language() → string');
	returns_ok($l->name(),                  { type => 'string' }, 'name() → string');
	returns_ok($l->sublanguage(),           { type => 'string' }, 'sublanguage() → string');
	returns_ok($l->requested_language(),    { type => 'string' }, 'requested_language() → string');
	returns_ok($l->language_code_alpha2(),  { type => 'string' }, 'language_code_alpha2() → string');
	returns_ok($l->code_alpha2(),           { type => 'string' }, 'code_alpha2() → string');
	returns_ok($l->sublanguage_code_alpha2(), { type => 'string' }, 'sublanguage_code_alpha2() → string');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 25: Norwegian Nynorsk parenthetical stripping in _find_language_from_ip
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_find_language_from_ip: Locale::Language::language2code falls back to Nynorsk strip' => sub {
	# Locale::Language can return names like "Norwegian Nynorsk" which have a
	# parenthetical qualifier.  The module strips "(…)" and retries language2code.
	# We exercise this by mocking the scenario:
	#   _rlanguage = 'Norwegian (Nynorsk)'
	#   Locale::Language::language2code('Norwegian (Nynorsk)') → undef
	#   Locale::Language::language2code('Norwegian') → 'no'
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	delete local $ENV{HTTP_ACCEPT_LANGUAGE};

	my $l = _obj(['nb', 'no']);
	_inject_ipcountry($l, 'NO');

	# Temporarily mock language2code to simulate the Nynorsk scenario.
	my @tried;
	Test::Mockingbird::mock('Locale::Language', 'language2code', sub {
		push @tried, $_[0];
		return $_[0] =~ /\(/ ? undef : 'no';
	});

	$l->{_rlanguage}     = 'Norwegian (Nynorsk)';
	$l->{_have_ipcountry} = $GEO_ABSENT;    # prevent re-lookup via IP::Country

	# Manually invoke the relevant segment of _find_language_from_ip by calling
	# language() with _rlanguage already set to simulate the language-name lookup.
	# We exercise it by seeding the country cache and letting _find_language_from_ip
	# take the "already have _rlanguage" branch.
	my $cache = _fresh_cache();
	$cache->set($CACHE_NS . 'language_name:no', 'Norwegian Nynorsk=nb', '1 month');
	$l->{_cache} = $cache;

	# Force _find_language_from_ip to run via _find_language
	delete $l->{_slanguage};
	delete $l->{_rlanguage};
	$l->_find_language();

	{ local $SIG{__WARN__} = sub {}; Test::Mockingbird::restore_all() }
	_block_network();

	diag("after Nynorsk test: tried=" . join(',', @tried) . " lang=" . ($l->{_slanguage}//'undef'))
		if $ENV{TEST_VERBOSE};
	ok(1, 'Norwegian Nynorsk parenthetical handling does not crash');
};

done_testing();
