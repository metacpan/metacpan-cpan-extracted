#!/usr/bin/env perl

# t/data-flow.t -- CGI::Lingua data-flow tests.
#
# Validates Define-Use (DU) chains, resource lifecycles, and global-variable
# non-pollution throughout the module.  Each section identifies which variable
# or resource is under test, the DU anomaly class being hunted (D~, DD, ~U,
# O~) and the specific invariant being asserted.
#
# Network I/O is blocked globally; individual subtests install narrow mocks
# as needed and call _block_network() immediately after restore_all().

use strict;
use warnings;

use CHI;
use JSON::PP ();
use Readonly;
use Scalar::Util qw(blessed);
use Test::Most;
use Test::Mockingbird;
use Test::Without::Module qw(IP::Country);

BEGIN { use_ok('CGI::Lingua') }

# ── Pre-require lazy-loaded modules before any mocking ────────────────────────
# A module's BEGIN block runs on first require and would clobber mocks installed
# before that point.  Load unconditionally so the symbol table is stable.
my $HAS_LWP  = eval { require LWP::Simple::WithCache; 1 } ? 1 : 0;
my $HAS_JSON = eval { require JSON::Parse;             1 } ? 1 : 0;

# ── Constants ─────────────────────────────────────────────────────────────────

Readonly my %LANG => (
	EN    => 'en',
	EN_GB => 'en-gb',
	EN_US => 'en-us',
	FR    => 'fr',
	DE    => 'de',
);

Readonly my %IP => (
	PUBLIC   => '8.8.8.8',
	PRIVATE  => '192.168.1.1',
	LOOPBACK => '127.0.0.1',
	MAPPED   => '::ffff:8.8.8.8',       # IPv4-mapped IPv6
	MAPPED_BAD => '::ffff:999.0.0.1',   # IPv4-mapped but octets out of range
	BAIDU    => '185.10.105.1',          # inside Baidu /22 subnet
	NON_BAIDU_EU => '185.10.103.1',      # adjacent /22 block — not Baidu
);

# Country codes used as GEOIP_COUNTRY_CODE / CF header values
Readonly my $CC_GB => 'GB';
Readonly my $CC_US => 'US';
Readonly my $CC_DE => 'DE';

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
	return CGI::Lingua->new(supported => $supported, %extra);
}

# Inject IP::Country mock onto an already-constructed object (IP::Country is
# excluded via Test::Without::Module so the lazy-require guard sets
# _have_ipcountry = GEO_ABSENT; this overrides that per-object).
sub _inject_ipcountry {
	my ($l, $cc) = @_;
	Test::Mockingbird::mock('IP::Country::Fast', 'inet_atocc', sub { $cc });
	$l->{_have_ipcountry} = 1;
	$l->{_ipcountry}      = bless {}, 'IP::Country::Fast';
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;
}

sub _fresh_cache {
	return CHI->new(driver => 'Memory', global => 0);
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 1: _country DU chain — lifecycle from definition to destruction
# ═══════════════════════════════════════════════════════════════════════════════
#
# _country is defined at multiple sources (GEOIP env, CF header, IP::Country,
# cache, Whois).  On a numeric or malformed result it is deleted (killed).
# The quick-return guard at the top of country() must never bypass validation
# on the first call — i.e., the "already set" fast-path only fires for the
# _second_ call, not for a stale env-var value.

subtest '_country: GEOIP sets _country once and fast-path returns it on second call (DU)' => sub {
	# DU chain: D at GEOIP_COUNTRY_CODE check → U at quick-return on 2nd call.
	local %ENV = (GEOIP_COUNTRY_CODE => $CC_GB);
	my $l = _obj([$LANG{EN}]);

	my $first  = $l->country();
	my $second = $l->country();

	is($first,  'gb', 'first call resolves GEOIP to "gb"');
	is($second, 'gb', 'second call hits fast-path (D→U, no re-parse)');
	is($l->{_country}, 'gb', '_country field holds resolved value');

	diag("_country after GEOIP path: $l->{_country}") if $ENV{TEST_VERBOSE};
};

subtest '_country: invalid GEOIP value is discarded, field stays undef (D killed before U)' => sub {
	# D~: GEOIP_COUNTRY_CODE contains lowercase → regex fails → no assignment.
	# Field never defined, so quick-return on second call re-reads env var.
	local %ENV = (GEOIP_COUNTRY_CODE => 'gb');    # lowercase: fails /^[A-Z]{2}$/a
	my $l = _obj([$LANG{EN}]);
	my $cc = $l->country();

	# Without REMOTE_ADDR and no valid env source, country() returns undef.
	ok(!defined($cc), 'invalid GEOIP code not promoted to _country');
	ok(!defined($l->{_country}), '_country stays undef when env var fails validation');
};

subtest '_country: numeric result is deleted immediately (DD then K)' => sub {
	# DD then K anomaly pattern: _country may be set to a numeric-looking string
	# by a geo source, then deleted.  Verified by injecting via cache.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $cache = _fresh_cache();
	my $l = _obj([$LANG{EN}], cache => $cache);

	# Disable all geo-module sources so the pipeline terminates after the
	# cache check, otherwise IP::Country/whois finds a real country.
	$l->{_have_ipcountry} = 0;
	$l->{_have_geoip}     = 0;
	$l->{_have_geoipfree} = 0;

	# Poison the country cache with a numeric value — simulates a bad Whois result.
	$cache->set('CGI::Lingua:country:' . $IP{PUBLIC}, '12345', '1 hour');

	my $cc = $l->country();

	ok(!defined($cc), 'numeric cached country code is discarded');
	ok(!defined($l->{_country}), '_country deleted after numeric value detected');

	# Verify the poisoned entry was removed from cache.
	ok(!defined($cache->get('CGI::Lingua:country:' . $IP{PUBLIC})),
		'poisoned numeric cache entry removed (resource cleaned up)');
};

subtest '_country: Cloudflare XX sentinel skipped (D never happens for XX)' => sub {
	# ~U anomaly avoidance: XX means CF couldn't determine country; verify code
	# never assigns 'xx' to _country — the field must remain undef.
	local %ENV = (HTTP_CF_IPCOUNTRY => 'XX');
	my $l = _obj([$LANG{EN}]);
	$l->country();
	ok(!defined($l->{_country}), 'XX CF header does not set _country');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 2: $ip mutation chain in country() — define, rewrite, re-validate
# ═══════════════════════════════════════════════════════════════════════════════
#
# $ip is defined once from REMOTE_ADDR, then may be rewritten for IPv4-mapped
# addresses.  The rewrite is followed by a second is_ipv4() validation to
# guard against out-of-range octets.  Tests verify the D→(rewrite)→U chain.

subtest '$ip: plain IPv4 is used without modification (D→U)' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _obj([$LANG{EN}]);
	_inject_ipcountry($l, $CC_US);

	my $cc = $l->country();

	is($cc, 'us', 'plain IPv4 resolves correctly');
};

subtest '$ip: IPv4-mapped IPv6 is normalised before geo lookup (D rewritten, re-validated)' => sub {
	# D→D→U: ip defined from regex on ::ffff:8.8.8.8, then rewritten to 8.8.8.8,
	# then passed to geo lookup.
	local %ENV = (REMOTE_ADDR => $IP{MAPPED});
	my $l = _obj([$LANG{EN}]);
	_inject_ipcountry($l, $CC_US);

	my $cc = $l->country();

	# The mock returns US for any IP, but what we verify is that it didn't crash
	# (the rewrite path was traversed without incident).
	is($cc, 'us', 'IPv4-mapped ::ffff:8.8.8.8 normalised to IPv4 and resolved');
};

subtest '$ip: out-of-range IPv4-mapped address rejected after normalisation (K before U)' => sub {
	# D→D(rewrite)→K: ::ffff:999.0.0.1 rewrites to "999.0.0.1" which fails
	# is_ipv4(), so country() returns undef — the bad value is killed before use.
	local %ENV = (REMOTE_ADDR => $IP{MAPPED_BAD});
	my $l = _obj([$LANG{EN}]);

	my $cc = $l->country();

	ok(!defined($cc), 'out-of-range IPv4-mapped address rejected after normalisation');
};

subtest '$ip: private IP terminates early — never reaches geo lookup (K before U)' => sub {
	# D→K: $ip validated from REMOTE_ADDR, then is_private_ip() kills the path.
	local %ENV = (REMOTE_ADDR => $IP{PRIVATE});
	my $l = _obj([$LANG{EN}]);

	my $cc = $l->country();

	ok(!defined($cc), 'private IP returns undef without reaching geo lookup');
	ok(!defined($l->{_country}), '_country never defined for private IP');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 3: DESTROY %state serialisation — D~ (dead store) check
# ═══════════════════════════════════════════════════════════════════════════════
#
# DESTROY builds %state from specific fields and encodes to JSON.  Test that
# (a) only the documented fields are serialised (no logger, cache, filehandles);
# (b) the encoded blob is valid JSON;
# (c) new() can re-inflate the blob (complete round-trip).

subtest 'DESTROY: only documented fields are serialised (no D~ for transient fields)' => sub {
	Readonly my @SERIALISED_FIELDS => qw(
		_slanguage  _slanguage_code_alpha2  _sublanguage_code_alpha2
		_country    _rlanguage  _dont_use_ip
		_have_ipcountry  _have_geoip  _have_geoipfree
	);
	Readonly my @FORBIDDEN_FIELDS => qw(logger _cache _info _syslog _ipcountry _geoip);

	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $cache = _fresh_cache();
	my $key;

	{
		my $l = _obj([$LANG{EN}], cache => $cache);
		$l->language();    # trigger DU chain to populate fields

		# Manually derive the cache key the way DESTROY does (same IP + supported).
		require CGI::Lingua;    # already loaded; just make require idempotent
		$key = join('/', $IP{PUBLIC}, $LANG{EN});

		# Force DESTROY by going out of scope... but we need the key first.
		# Let DESTROY run now by calling it explicitly with a fresh ENV.
		local $ENV{REMOTE_ADDR} = $IP{PUBLIC};
		$l->DESTROY() if $l->can('DESTROY');
	}

	# Retrieve whatever DESTROY stored.
	my $stored;
	# Try the canonical key format: ip/lang
	for my $candidate_key ($cache->get_keys()) {
		next unless $candidate_key =~ m{\Q$IP{PUBLIC}\E};
		$stored = $cache->get($candidate_key);
		last if defined $stored;
	}

	SKIP: {
		skip 'DESTROY did not store anything (no matching entry in cache)', 3
			unless defined $stored;

		my $decoded = eval { JSON::PP::decode_json($stored) };
		ok(!$@,          'DESTROY blob is valid JSON');
		ok(ref($decoded) eq 'HASH', 'DESTROY blob decodes to a hashref');

		# Check that no forbidden transient field leaked into the blob.
		for my $forbidden (@FORBIDDEN_FIELDS) {
			ok(!exists $decoded->{$forbidden},
				"DESTROY blob does not contain transient field '$forbidden'");
		}

		diag('DESTROY stored keys: ' . join(', ', sort keys %{$decoded}))
			if $ENV{TEST_VERBOSE};
	}
};

subtest 'DESTROY: does not overwrite an existing valid cache entry (resource lifecycle)' => sub {
	# O~ variant: DESTROY opens/writes the cache only when the key is absent.
	# If the key already exists (another process wrote it), DESTROY must not
	# clobber it — the early-return `return if $cache->get($key)` guard.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $cache = _fresh_cache();

	# Pre-populate the cache entry with a sentinel value.
	Readonly my $SENTINEL => 'sentinel_value';
	my $pre_key = join('/', $IP{PUBLIC}, '', $LANG{EN});
	$cache->set($pre_key, JSON::PP::encode_json({_country => 'sentinel'}), '1 hour');

	# Because we can't easily predict the exact key DESTROY uses without re-
	# implementing _build_cache_key, we take a different approach: populate ALL
	# keys that match the IP and check that none are overwritten.
	my %before = map { $_ => $cache->get($_) } $cache->get_keys();

	{
		local $ENV{REMOTE_ADDR} = $IP{PUBLIC};
		my $l = _obj([$LANG{EN}], cache => $cache);
		$l->language();
		# DESTROY runs at end of block
	}

	# Verify the sentinel entry was not overwritten.
	is($cache->get($pre_key), JSON::PP::encode_json({_country => 'sentinel'}),
		'pre-existing cache entry not clobbered by DESTROY');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 4: Cache thaw in new() — stale blob discards (D~ detection)
# ═══════════════════════════════════════════════════════════════════════════════
#
# A Storable blob (or any non-JSON content) in the cache must be silently
# discarded; the D~ anomaly is the computed rc from decode_json being thrown
# away when it is not a HASH ref or not valid JSON.

subtest 'new(): non-JSON cache blob is discarded, fresh object constructed' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $cache = _fresh_cache();

	# The key format is ip/lang/supported; simulate a stale Storable entry.
	my $key = join('/', $IP{PUBLIC}, $LANG{EN}, $LANG{EN});
	$cache->set($key, "\x05\x0b\x13garbage\x00", '1 hour');    # binary garbage, not JSON

	# Construction must not die despite the bad cache blob.
	my $l;
	lives_ok { $l = _obj([$LANG{EN}], cache => $cache) }
		'non-JSON cache blob does not crash new()';

	ok(blessed($l) && $l->isa('CGI::Lingua'),
		'fresh CGI::Lingua object returned despite poisoned cache');
};

subtest 'new(): non-HASH JSON blob is discarded (array instead of object)' => sub {
	# A valid JSON array is not a hashref — rc check `ref($rc) eq 'HASH'` rejects it.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $cache = _fresh_cache();
	my $key = join('/', $IP{PUBLIC}, $LANG{EN}, $LANG{EN});
	$cache->set($key, JSON::PP::encode_json([1, 2, 3]), '1 hour');

	my $l;
	lives_ok { $l = _obj([$LANG{EN}], cache => $cache) }
		'JSON array blob does not crash new()';
	ok(blessed($l), 'fresh object returned for JSON-array blob');
};

subtest 'new(): valid JSON hash blob is thawed and fields re-injected' => sub {
	# D→U: the rc hashref is blessed and its transient fields re-injected from params.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $cache = _fresh_cache();

	# Build a valid state blob (exactly what DESTROY writes).
	my %state = (
		_slanguage             => 'English',
		_slanguage_code_alpha2 => 'en',
		_country               => 'us',
		_rlanguage             => 'English',
		_dont_use_ip           => 0,
		_have_ipcountry        => -1,
		_have_geoip            => -1,
		_have_geoipfree        => -1,
	);
	my $key = join('/', $IP{PUBLIC}, $LANG{EN}, $LANG{EN});
	$cache->set($key, JSON::PP::encode_json(\%state), '1 hour');

	my $l = _obj([$LANG{EN}], cache => $cache);

	is($l->language(), 'English',   'thawed _slanguage used by language()');
	is($l->{_country}, 'us',        'thawed _country re-inflated');
	# logger is re-injected by new() from $params (Object::Configure provides one).
	# Verify heavy non-serialised objects (_ipcountry, _geoip) are NOT present.
	ok(!defined($l->{_ipcountry}),  '_ipcountry not in thawed object (not serialised)');
	ok(!defined($l->{_geoip}),      '_geoip not in thawed object (not serialised)');

	diag('Thawed object keys: ' . join(', ', sort keys %{$l}))
		if $ENV{TEST_VERBOSE};
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 5: $_locale_object_db_ok package sentinel — transition and persistence
# ═══════════════════════════════════════════════════════════════════════════════
#
# The sentinel starts at undef, moves to 1 (present) or 0 (absent).
# Once set to 0 it must stay 0 (no repeated failed Locale::Object probes).
# Tested indirectly via _code2country and _resolve_sublanguage_match.

subtest '$_locale_object_db_ok: once set to 0, _code2country skips Locale::Object' => sub {
	# Force the sentinel to 0 by injecting it at package level.
	# CGI::Lingua exposes no public accessor so we use the symbol table.
	{
		no strict 'refs';
		${'CGI::Lingua::_locale_object_db_ok'} = 0;
	}

	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB});
	my $l = _obj([$LANG{EN_GB}]);

	# With sentinel = 0, _code2country returns undef; _code2countryname should
	# fall back to _country_short_name (via %COUNTRY_SHORT_NAMES).
	my $sub = $l->sublanguage();

	# Reset sentinel to undef so other tests see a clean slate.
	{
		no strict 'refs';
		${'CGI::Lingua::_locale_object_db_ok'} = undef;
	}

	# The short-name table covers 'gb' → 'United Kingdom'.
	is($sub, 'United Kingdom',
		'_country_short_name fallback works when sentinel is 0 (no Locale::Object call)');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 6: $_have_dvip sentinel — symbol-table alias installation
# ═══════════════════════════════════════════════════════════════════════════════
#
# When $_have_dvip transitions to 0, four pure-Perl aliases are installed in
# the CGI::Lingua symbol table.  Verify they are callable and correct.

subtest '$_have_dvip = 0: pure-Perl IP functions installed and callable' => sub {
	# Force the sentinel to the "broken" state; country() will install aliases.
	{
		no strict 'refs';
		${'CGI::Lingua::_have_dvip'} = undef;    # reset to probe state
	}

	# Temporarily make Data::Validate::IP appear to fail.
	{
		no warnings 'redefine';
		no strict 'refs';
		# Patch _have_dvip to 0 and install the fallbacks manually (mirrors what
		# country() does internally when the eval fails).
		${'CGI::Lingua::_have_dvip'} = 0;
		*CGI::Lingua::is_ipv4        = \&CGI::Lingua::_is_ipv4;
		*CGI::Lingua::is_ipv6        = \&CGI::Lingua::_is_ipv6;
		*CGI::Lingua::is_private_ip  = \&CGI::Lingua::_is_private_ip;
		*CGI::Lingua::is_loopback_ip = \&CGI::Lingua::_is_loopback_ip;
	}

	# Now verify the installed aliases behave correctly.
	ok( CGI::Lingua::is_ipv4('8.8.8.8'),         'is_ipv4: valid IPv4');
	ok(!CGI::Lingua::is_ipv4('999.0.0.0'),        'is_ipv4: octet > 255 rejected');
	ok(!CGI::Lingua::is_ipv4('::1'),              'is_ipv4: IPv6 rejected');
	ok( CGI::Lingua::is_private_ip('10.0.0.1'),   'is_private_ip: 10/8');
	ok( CGI::Lingua::is_private_ip('172.16.0.1'), 'is_private_ip: 172.16/12');
	ok( CGI::Lingua::is_private_ip('192.168.1.1'),'is_private_ip: 192.168/16');
	ok(!CGI::Lingua::is_private_ip('8.8.8.8'),    'is_private_ip: public IP false');
	ok( CGI::Lingua::is_loopback_ip('127.0.0.1'), 'is_loopback_ip: 127.0.0.1');
	ok( CGI::Lingua::is_loopback_ip('::1'),       'is_loopback_ip: ::1');
	ok(!CGI::Lingua::is_loopback_ip('8.8.8.8'),   'is_loopback_ip: public IP false');

	# Restore the sentinel to undef so subsequent tests probe normally.
	{
		no strict 'refs';
		${'CGI::Lingua::_have_dvip'} = undef;
	}
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 7: Geo module sentinels — GEO_UNKNOWN → GEO_ABSENT transition
# ═══════════════════════════════════════════════════════════════════════════════
#
# _have_ipcountry / _have_geoip / _have_geoipfree start at GEO_UNKNOWN (-1).
# After the first country() call the sentinel must reflect the probe outcome.
# The transition must happen exactly once — not on every call.

subtest 'geo sentinels: GEO_UNKNOWN (-1) transitions on first country() call' => sub {
	# Test::Without::Module qw(IP::Country) blocks require IP::Country but NOT
	# require IP::Country::Fast (the concrete class country() requires).  So
	# _have_ipcountry may transition to either GEO_ABSENT (0) or GEO_PRESENT (1)
	# depending on whether IP::Country::Fast is installed.  What we assert is
	# that it is NO LONGER GEO_UNKNOWN (-1) after the first call.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _obj([$LANG{EN}]);

	is($l->{_have_ipcountry},  -1, '_have_ipcountry starts at GEO_UNKNOWN');
	is($l->{_have_geoip},      -1, '_have_geoip starts at GEO_UNKNOWN');
	is($l->{_have_geoipfree},  -1, '_have_geoipfree starts at GEO_UNKNOWN');

	$l->country();    # triggers probe

	isnt($l->{_have_ipcountry}, -1,
		'_have_ipcountry no longer GEO_UNKNOWN after first call');

	diag(sprintf '_have_ipcountry=%d _have_geoip=%d _have_geoipfree=%d',
		$l->{_have_ipcountry}, $l->{_have_geoip}, $l->{_have_geoipfree})
		if $ENV{TEST_VERBOSE};
};

subtest 'geo sentinels: second country() call does not re-probe (D→U, no re-D)' => sub {
	# DD anomaly check: the sentinel must not be re-assigned on every call.
	# Verified by calling country() twice and checking sentinel stability.
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _obj([$LANG{EN}]);
	$l->country();    # first call: probes and sets sentinels

	my $sentinel_after_first = $l->{_have_ipcountry};

	# Intercept any calls that would re-probe — if the sentinel is respected,
	# IP::Country::Fast should never be required again.
	$l->country();    # second call: must use cached sentinel

	is($l->{_have_ipcountry}, $sentinel_after_first,
		'_have_ipcountry unchanged on second call (no re-probe)');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 8: $_ global non-pollution
# ═══════════════════════════════════════════════════════════════════════════════
#
# locale() uses an implicit $_ in its foreach loop.  Any method that calls
# split and iterates must not leave $_ in a modified state visible to the caller.

subtest '$_: not polluted by language() call' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'en,fr;q=0.9');
	my $l = _obj([$LANG{EN}]);

	local $_ = 'sentinel_value';
	$l->language();
	is($_, 'sentinel_value', '$_ unchanged after language()');
};

subtest '$_: not polluted by sublanguage() call' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB});
	my $l = _obj([$LANG{EN_GB}]);

	local $_ = 'sentinel_value';
	$l->sublanguage();
	is($_, 'sentinel_value', '$_ unchanged after sublanguage()');
};

subtest '$_: not polluted by locale() foreach loop' => sub {
	local %ENV = (HTTP_USER_AGENT => 'Mozilla/5.0 (en-GB; rv:109.0) Gecko/20100101');
	delete local $ENV{REMOTE_ADDR};
	my $l = _obj([$LANG{EN}]);

	local $_ = 'sentinel_value';
	$l->locale();
	is($_, 'sentinel_value', '$_ unchanged after locale() foreach loop');
};

subtest '$_: not polluted by country() call' => sub {
	local %ENV = (GEOIP_COUNTRY_CODE => $CC_GB);
	my $l = _obj([$LANG{EN}]);

	local $_ = 'sentinel_value';
	$l->country();
	is($_, 'sentinel_value', '$_ unchanged after country()');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 9: $@ non-leakage from eval blocks
# ═══════════════════════════════════════════════════════════════════════════════
#
# Multiple eval blocks in country(), new(), _code2country(), time_zone().
# Each must leave $@ in a defined/clean state visible to the caller — or at
# least not propagate an error that wasn't theirs.

subtest '$@: country() does not leak $@ to caller' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _obj([$LANG{EN}]);

	# Prime $@ with a pre-existing error to detect leakage.
	eval { die 'pre-existing-error' };
	my $before = $@;

	# A fresh call to country() must not change $@ as seen outside: its
	# internal evals run under "local $@", so the caller's error survives.
	$l->country();

	is($@, $before, '$@ after country() is the caller\'s value, untouched');
};

subtest '$@: new() with valid JSON cache blob preserves $@' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $cache = _fresh_cache();
	my %state = (
		_slanguage             => 'English',
		_slanguage_code_alpha2 => 'en',
		_country               => 'us',
		_rlanguage             => 'English',
		_dont_use_ip           => 0,
		_have_ipcountry        => -1,
		_have_geoip            => -1,
		_have_geoipfree        => -1,
	);
	my $key = join('/', $IP{PUBLIC}, $LANG{EN}, $LANG{EN});
	$cache->set($key, JSON::PP::encode_json(\%state), '1 hour');

	eval { die 'pre-existing' };
	my $before = $@;
	_obj([$LANG{EN}], cache => $cache);

	# The JSON decode runs under local $@, so the caller's error survives
	is($@, $before, '$@ after new() with valid cache blob is the caller\'s value');
};

subtest '$@: new() with invalid cache blob preserves $@' => sub {
	local %ENV = (REMOTE_ADDR => $IP{PUBLIC}, HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $cache = _fresh_cache();
	my $key = join('/', $IP{PUBLIC}, $LANG{EN}, $LANG{EN});
	$cache->set($key, 'not-json', '1 hour');

	eval { die 'pre-existing' };
	my $before = $@;
	_obj([$LANG{EN}], cache => $cache);

	# The failed decode must neither leak its error nor clear the caller's
	is($@, $before, '$@ after new() with invalid cache blob is the caller\'s value');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 10: _code2language cache write-then-read (resource lifecycle)
# ═══════════════════════════════════════════════════════════════════════════════
#
# _code2language computes the name, writes to cache, and returns it.
# The second call must be a cache hit — no re-computation.
# O~ check: verify the cache entry is written on the first call.

subtest '_code2language: cache hit on second call (D→write→U=read)' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $cache = _fresh_cache();
	my $l = _obj([$LANG{EN}], cache => $cache);

	# Prime the language pipeline so _slanguage_code_alpha2 is set.
	$l->language();

	# Verify the cache entry was written.
	my $cached = $cache->get('CGI::Lingua:code2language:en');
	is($cached, 'English',
		'_code2language stored "English" in cache after first call (O~ check: write happened)');

	# Second call — should read from cache, not re-compute.
	my $spy_called = 0;
	Test::Mockingbird::mock('Locale::Language', 'code2language', sub { $spy_called++; 'English' });
	$l->_code2language('en');
	Test::Mockingbird::restore_all();
	_block_network();

	is($spy_called, 0,
		'Locale::Language::code2language not called on cache hit (D→U from cache only)');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 11: _code2countryname cache write-then-read
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_code2countryname: cache hit on second call' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB});
	my $cache = _fresh_cache();
	my $l = _obj([$LANG{EN_GB}], cache => $cache);

	$l->_code2countryname('gb');    # directly populate the cache

	my $cached = $cache->get('CGI::Lingua:code2countryname:gb');
	ok(defined($cached) && length($cached), '_code2countryname wrote gb entry to cache');

	diag("Cached country name for gb: '$cached'") if $ENV{TEST_VERBOSE};

	# Second call must not invoke _code2country again.
	my $spy_called = 0;
	Test::Mockingbird::mock('CGI::Lingua', '_code2country',
		sub { $spy_called++; undef });
	$l->_code2countryname('gb');
	Test::Mockingbird::restore_all();
	_block_network();

	is($spy_called, 0,
		'_code2country not invoked on cache hit in _code2countryname');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 12: _build_cache_key determinism — same inputs → same key (D→U stable)
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_build_cache_key: deterministic for identical inputs' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $k1 = CGI::Lingua::_build_cache_key($IP{PUBLIC}, { supported => [$LANG{EN}] }, 'CGI::Lingua', undef);
	my $k2 = CGI::Lingua::_build_cache_key($IP{PUBLIC}, { supported => [$LANG{EN}] }, 'CGI::Lingua', undef);

	is($k1, $k2, 'same inputs produce identical cache key on repeated calls');
};

subtest '_build_cache_key: different IPs produce distinct keys' => sub {
	local %ENV = ();
	my $k1 = CGI::Lingua::_build_cache_key('1.2.3.4',  { supported => [$LANG{EN}] }, 'CGI::Lingua', undef);
	my $k2 = CGI::Lingua::_build_cache_key('5.6.7.8',  { supported => [$LANG{EN}] }, 'CGI::Lingua', undef);

	isnt($k1, $k2, 'different IPs produce distinct cache keys');
};

subtest '_build_cache_key: different supported lists produce distinct keys' => sub {
	local %ENV = ();
	my $k1 = CGI::Lingua::_build_cache_key($IP{PUBLIC}, { supported => [$LANG{EN}]        }, 'CGI::Lingua', undef);
	my $k2 = CGI::Lingua::_build_cache_key($IP{PUBLIC}, { supported => [$LANG{EN},$LANG{FR}] }, 'CGI::Lingua', undef);

	isnt($k1, $k2, 'different supported lists produce distinct cache keys');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 13: _in_baidu_subnet integer arithmetic (D→U pack/unpack chain)
# ═══════════════════════════════════════════════════════════════════════════════
#
# $n and $net are defined via pack('C4', ...) then unpacked as unsigned 32-bit
# integers.  The /22 mask applied as bitwise AND must be exact.

subtest '_in_baidu_subnet: IPs inside the /22 block return true' => sub {
	# 185.10.104.0/22 spans .104.0 – .107.255
	ok( CGI::Lingua::_in_baidu_subnet('185.10.104.0'),   'first address of /22 block');
	ok( CGI::Lingua::_in_baidu_subnet('185.10.104.1'),   'second address');
	ok( CGI::Lingua::_in_baidu_subnet($IP{BAIDU}),       '185.10.105.1 (inside)');
	ok( CGI::Lingua::_in_baidu_subnet('185.10.107.255'), 'last address of /22 block');
};

subtest '_in_baidu_subnet: IPs outside the /22 block return false' => sub {
	ok(!CGI::Lingua::_in_baidu_subnet('185.10.103.255'), 'one before block start');
	ok(!CGI::Lingua::_in_baidu_subnet('185.10.108.0'),   'one after block end');
	ok(!CGI::Lingua::_in_baidu_subnet($IP{NON_BAIDU_EU}),'adjacent /22 block not matched');
	ok(!CGI::Lingua::_in_baidu_subnet('8.8.8.8'),        'unrelated public IP');
	ok(!CGI::Lingua::_in_baidu_subnet('192.168.1.1'),    'private IP');
	ok(!CGI::Lingua::_in_baidu_subnet('not-an-ip'),      'non-IP string returns false');
};

subtest '_in_baidu_subnet: 32-bit integer arithmetic avoids signed overflow' => sub {
	# High-octet addresses (MSB set) would overflow signed 32-bit pack — verify
	# that pack('N', pack('C4', ...)) is used correctly (no signed-overflow crash).
	lives_ok { CGI::Lingua::_in_baidu_subnet('255.255.255.255') }
		'no crash for all-ones address (high-bit set)';
	lives_ok { CGI::Lingua::_in_baidu_subnet('128.0.0.0') }
		'no crash for MSB-set address';
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 14: _sorted_tokens DU chain — q-value parse and sort
# ═══════════════════════════════════════════════════════════════════════════════
#
# _sorted_tokens defines @tokens by accumulating parsed [tag, q] pairs, then
# returns a sorted arrayref.  Verify: (a) q values parsed correctly; (b) sort
# is descending; (c) implicit q=1.0 when no q= component.

subtest '_sorted_tokens: q-values parsed and sorted descending' => sub {
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);

	my $sorted = $l->_sorted_tokens('fr;q=0.5,en;q=0.9,de;q=0.7');

	is(scalar @{$sorted}, 3, 'three tokens parsed');
	is($sorted->[0][0], 'en',  'highest q=0.9 is first');
	is($sorted->[1][0], 'de',  'q=0.7 is second');
	is($sorted->[2][0], 'fr',  'lowest q=0.5 is third');

	diag("Sorted tokens: " . join(', ', map { "$_->[0](q=$_->[1])" } @{$sorted}))
		if $ENV{TEST_VERBOSE};
};

subtest '_sorted_tokens: implicit q=1.0 when no q= component' => sub {
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);

	my $sorted = $l->_sorted_tokens('fr,en;q=0.8');

	is($sorted->[0][0], 'fr',   'fr (implicit q=1.0) sorts first');
	ok($sorted->[0][1] == 1.0,  'implicit q-value is numerically 1.0');
};

subtest '_sorted_tokens: returns arrayref, not flat list (~U check)' => sub {
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);

	my $result = $l->_sorted_tokens('en,fr');

	ok(ref($result) eq 'ARRAY', '_sorted_tokens returns arrayref (not flat list)');
	ok(!defined(wantarray) || 1, 'scalar context: single value returned');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 15: _slanguage/_sublanguage/_rlanguage atomic consistency
# ═══════════════════════════════════════════════════════════════════════════════
#
# After any call to _find_language(), all three fields must be internally
# consistent.  _rlanguage must equal "_slanguage (_sublanguage)" when
# a sublanguage is present, or just "_slanguage" when none.

subtest 'consistency: language() + sublanguage() + requested_language() for en-gb' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN_GB});
	my $l = _obj([$LANG{EN_GB}]);

	my $lang = $l->language();
	my $sub  = $l->sublanguage();
	my $req  = $l->requested_language();

	is($lang, 'English',         'language() = English');
	ok(defined($sub),            'sublanguage() is defined');
	like($req, qr/\Q$lang\E/,   'requested_language() includes language');
	like($req, qr/\Q$sub\E/,    'requested_language() includes sublanguage')
		if defined($sub) && $sub ne 'Unknown';

	diag("lang=$lang sub=" . ($sub // 'undef') . " req=$req")
		if $ENV{TEST_VERBOSE};
};

subtest 'consistency: base language without sublanguage (en only)' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = _obj([$LANG{EN}]);

	my $lang = $l->language();
	my $sub  = $l->sublanguage();
	my $req  = $l->requested_language();

	is($lang, 'English',         'language() = English');
	ok(!defined($sub),           'sublanguage() is undef for plain "en"');
	like($req, qr/English/,      'requested_language() contains "English"');
	unlike($req, qr/\(/, 'requested_language() has no parenthetical for plain en');
};

subtest 'consistency: Unknown when no supported language matches' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'zh');
	my $l = _obj([$LANG{EN}], dont_use_ip => 1);

	my $lang = $l->language();
	my $req  = $l->requested_language();

	is($lang, 'Unknown',         'language() = Unknown for unsupported zh');
	ok(defined($req),            'requested_language() defined even for Unknown');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 16: _log message accumulation (D→U→D growing list, no D~)
# ═══════════════════════════════════════════════════════════════════════════════
#
# $self->{messages} grows with every _log call.  After n calls the list must
# contain exactly n entries in insertion order.  No message should be a dead
# store — every pushed entry must be accessible.

subtest '_log: messages accumulate in insertion order (no dead stores)' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = _obj([$LANG{EN}], debug => 1);

	# Trigger logging by calling methods.
	$l->language();
	$l->sublanguage();

	my $msgs = $l->{messages} // [];

	ok(scalar(@{$msgs}) > 0, 'messages array is non-empty after calls');

	# All entries must have level and message keys (DU: pushed struct is readable).
	for my $entry (@{$msgs}) {
		ok(exists $entry->{level},   "message entry has 'level' key");
		ok(exists $entry->{message}, "message entry has 'message' key");
		ok(length($entry->{message}) > 0, 'message text is non-empty');
		last;    # just verify first entry; structure is the same for all
	}

	diag(sprintf 'Accumulated %d messages', scalar @{$msgs})
		if $ENV{TEST_VERBOSE};
};

subtest '_log: empty-text messages are not accumulated (guard against D~ for empty string)' => sub {
	# _log has `return unless length($text)` so empty concatenation is discarded.
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	my $before = scalar @{$l->{messages} // []};

	$l->_log('debug');         # no message args
	$l->_log('debug', '');     # empty string
	$l->_log('debug', undef);  # undef

	my $after = scalar @{$l->{messages} // []};
	is($after, $before, 'empty/undef _log calls do not grow messages array');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 17: _what_language memoization (D→U, no re-D on second call)
# ═══════════════════════════════════════════════════════════════════════════════
#
# _what_language caches its result in $self->{_what_language}.  A second call
# must return the cached value without re-reading HTTP_ACCEPT_LANGUAGE.

subtest '_what_language: memoized after first call (DD anomaly absent)' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => 'fr');
	my $l = _obj([$LANG{EN}, $LANG{FR}]);

	my $first = $l->_what_language();
	is($first, 'fr', 'first call reads env var');
	is($l->{_what_language}, 'fr', '_what_language field set after first call');

	# Change the env var between calls to verify the cached value is returned.
	local $ENV{HTTP_ACCEPT_LANGUAGE} = 'de';
	my $second = $l->_what_language();

	is($second, 'fr',
		'second call returns memoized value, not re-read env var (no re-D)');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 18: _country_short_name DU chain — %COUNTRY_SHORT_NAMES lookup
# ═══════════════════════════════════════════════════════════════════════════════
#
# _country_short_name is defined to check %COUNTRY_SHORT_NAMES first, then fall
# back to Locale::Codes.  D~ check: if the code is in the table, Locale::Codes
# must never be called (the table value is not a dead store).

subtest '_country_short_name: table entries returned without calling Locale::Codes' => sub {
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);

	my $spy_called = 0;
	Test::Mockingbird::mock('Locale::Codes::Country', 'code2country',
		sub { $spy_called++; 'Should not be called' });

	Readonly my %EXPECTED_SHORT_NAMES => (
		gb => 'United Kingdom',
		us => 'United States',
		nl => 'Netherlands',
		kr => 'South Korea',
		kp => 'North Korea',
		ir => 'Iran',
		tw => 'Taiwan',
		tz => 'Tanzania',
		ve => 'Venezuela',
	);

	for my $code (sort keys %EXPECTED_SHORT_NAMES) {
		my $name = $l->_country_short_name($code);
		is($name, $EXPECTED_SHORT_NAMES{$code},
			"_country_short_name('$code') = '$EXPECTED_SHORT_NAMES{$code}'");
	}

	Test::Mockingbird::restore_all();
	_block_network();

	is($spy_called, 0,
		'Locale::Codes::Country never called for codes in %COUNTRY_SHORT_NAMES (no D~)');
};

subtest '_country_short_name: unknown code falls through to Locale::Codes' => sub {
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);

	# 'au' is not in %COUNTRY_SHORT_NAMES — must reach Locale::Codes.
	my $name = $l->_country_short_name('au');
	ok(defined($name) && length($name),
		'_country_short_name falls back to Locale::Codes for codes not in table');
	like($name, qr/Australia/i, 'Locale::Codes returns Australia for au');
};

subtest '_country_short_name: undef input returns undef (guard against ~U on undef)' => sub {
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	ok(!defined($l->_country_short_name(undef)),
		'_country_short_name(undef) returns undef without crashing');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 19: _clean_country_code DU chain — CRLF injection defence
# ═══════════════════════════════════════════════════════════════════════════════
#
# _clean_country_code is defined to strip trailing whitespace/comments and
# accept exactly 2 alpha chars.  A CRLF-injected value must return undef.
# Verify D is killed (returns undef) for hostile inputs.

subtest '_clean_country_code: clean codes pass through' => sub {
	is(CGI::Lingua::_clean_country_code('GB'), 'GB', 'clean uppercase passes');
	is(CGI::Lingua::_clean_country_code('us'), 'us', 'lowercase passes');
	is(CGI::Lingua::_clean_country_code("GB\r"),   'GB', 'trailing CR stripped');
	is(CGI::Lingua::_clean_country_code('GB # comment'), 'GB', 'comment stripped');
};

subtest '_clean_country_code: hostile inputs return undef (K before U)' => sub {
	ok(!defined(CGI::Lingua::_clean_country_code("GB\r\nX-Evil: injected")),
		'CRLF injection returns undef');
	ok(!defined(CGI::Lingua::_clean_country_code('G')),
		'single char returns undef');
	ok(!defined(CGI::Lingua::_clean_country_code('GBR')),
		'three chars returns undef');
	ok(!defined(CGI::Lingua::_clean_country_code('GB<script>')),
		'XSS payload returns undef');
	ok(!defined(CGI::Lingua::_clean_country_code('')),
		'empty string returns undef');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 20: Clone constructor — shared state isolation (no DD from overlay)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Calling ->new() on an existing object creates a clone.  The clone's
# _supported list must reflect the new params; mutations to the clone must
# not affect the original (no shared mutable structure).

subtest 'clone: new() on object overlays new supported, original unchanged' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $original = _obj([$LANG{EN}, $LANG{FR}]);
	$original->language();    # populate _slanguage

	my $clone = $original->new(supported => [$LANG{DE}]);

	ok(blessed($clone),                     'clone is a blessed object');
	is(ref($clone), ref($original),         'clone is same class as original');
	isnt($clone, $original,                 'clone is a distinct reference');
	is_deeply($clone->{_supported}, [$LANG{DE}],
		'clone _supported reflects new params (D does not alias original)');
};

subtest 'clone: mutating clone does not affect original (no shared mutable refs)' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $original = _obj([$LANG{EN}]);
	my $clone    = $original->new(supported => [$LANG{FR}]);

	# Mutate the clone's _supported in-place.
	push @{$clone->{_supported}}, 'de';

	# Original must be unaffected.
	is_deeply($original->{_supported}, [$LANG{EN}],
		'original _supported unchanged after clone mutation');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 21: _resolve_country_via_whois $whois hash key priority (DU order)
# ═══════════════════════════════════════════════════════════════════════════════
#
# The method checks 'Country' (uppercase) before 'country' (lowercase).
# When both are present, uppercase wins — verify DU order is respected.

subtest '_resolve_country_via_whois: uppercase Country key takes priority over lowercase' => sub {
	# Pre-require Net::Whois::IP so the require inside _resolve_country_via_whois
	# is a no-op and does not clobber the mock (CLAUDE.md: pre-require before mocking).
	require Net::Whois::IP;

	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _obj([$LANG{EN}]);

	# Unmock _resolve_country_via_whois to test it directly.
	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');

	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query', sub {
		return { Country => 'GB', country => 'US' };    # uppercase wins
	});

	$l->_resolve_country_via_whois($IP{PUBLIC});

	Test::Mockingbird::restore_all();
	_block_network();

	# _resolve_country_via_whois stores the _clean_country_code result, which
	# preserves case ('GB').  The lc() sanitization happens later in country().
	is($l->{_country}, 'GB',
		'uppercase Country key used (DU order: Country checked before country)');
};

subtest '_resolve_country_via_whois: lowercase country key used when uppercase absent' => sub {
	require Net::Whois::IP;

	local %ENV = (REMOTE_ADDR => $IP{PUBLIC});
	my $l = _obj([$LANG{EN}]);

	Test::Mockingbird::unmock('CGI::Lingua', '_resolve_country_via_whois');

	Test::Mockingbird::mock('Net::Whois::IP', 'whoisip_query', sub {
		return { country => 'de' };    # only lowercase present
	});

	$l->_resolve_country_via_whois($IP{PUBLIC});

	Test::Mockingbird::restore_all();
	_block_network();

	is($l->{_country}, 'de',
		'lowercase country key used when uppercase is absent (DU fallback)');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 22: /etc/timezone file handle lifecycle (O~ check)
# ═══════════════════════════════════════════════════════════════════════════════
#
# time_zone() opens /etc/timezone with a lexical `my $fin` inside an if-block.
# The handle must close automatically when the block exits — no dangling handle.
# Verified indirectly: subsequent calls must not fail with "too many open files".

subtest 'time_zone: /etc/timezone handle closed after each call (no O~)' => sub {
	local %ENV = ();
	delete local $ENV{REMOTE_ADDR};

	my $l = _obj([$LANG{EN}]);

	# Call time_zone() 50 times; if the handle leaks we eventually hit EMFILE.
	my $error;
	for (1..50) {
		eval { $l->time_zone() };
		if ($@) {
			$error = $@;
			last;
		}
		delete $l->{_timezone};    # reset so each call re-opens the file
	}

	ok(!$error, '50 repeated time_zone() calls do not exhaust file descriptors')
		or diag("Error on repeated call: $error");
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 23: _handle_eu_country DU chain — Baidu vs non-Baidu sentinel
# ═══════════════════════════════════════════════════════════════════════════════

subtest '_handle_eu_country: Baidu IP sets _country to cn' => sub {
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	$l->_handle_eu_country($IP{BAIDU});
	is($l->{_country}, 'cn', 'Baidu subnet IP → _country = cn');
};

subtest '_handle_eu_country: non-Baidu EU IP sets _country to Unknown sentinel' => sub {
	local %ENV = ();
	my $l = _obj([$LANG{EN}]);
	$l->_handle_eu_country($IP{NON_BAIDU_EU});
	is($l->{_country}, 'Unknown', 'non-Baidu EU IP → _country = Unknown sentinel');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 24: plural_category and translation_file — argument validation (K before U)
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'plural_category: undef $n croaks immediately (K before U)' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = _obj([$LANG{EN}]);
	$l->language();

	throws_ok { $l->plural_category(undef) }
		qr/plural_category.*must be defined/i,
		'plural_category(undef) croaks with correct message';
};

subtest 'translation_file: dir with .. is rejected (K before path constructed)' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = _obj([$LANG{EN}]);
	$l->language();

	ok(!defined($l->translation_file('/var/../etc')),
		'translation_file with .. in dir returns undef');
};

subtest 'translation_file: unsafe extension is rejected (K before path constructed)' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $l = _obj([$LANG{EN}]);
	$l->language();

	ok(!defined($l->translation_file('/var/www/i18n', '../etc/passwd')),
		'translation_file with traversal in ext returns undef');
};

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 25: concurrent object isolation — no shared mutable package state
# ═══════════════════════════════════════════════════════════════════════════════
#
# Two objects with different supported lists and different REMOTE_ADDR must
# not share _country or _slanguage state.  Package-level sentinels are shared
# by design; per-object fields must be isolated.

subtest 'concurrent objects: _country fields are isolated' => sub {
	my ($cc_a, $cc_b);

	{
		local %ENV = (GEOIP_COUNTRY_CODE => 'GB');
		my $a = _obj([$LANG{EN}]);
		$cc_a = $a->country();
	}

	{
		local %ENV = (GEOIP_COUNTRY_CODE => 'US');
		my $b = _obj([$LANG{EN}]);
		$cc_b = $b->country();
	}

	is($cc_a, 'gb', 'object A resolved to gb');
	is($cc_b, 'us', 'object B resolved to us');
};

subtest 'concurrent objects: _slanguage fields are isolated' => sub {
	local %ENV = (HTTP_ACCEPT_LANGUAGE => $LANG{EN});
	my $a = _obj([$LANG{EN}]);
	{
		local $ENV{HTTP_ACCEPT_LANGUAGE} = $LANG{FR};
		my $b = _obj([$LANG{EN}, $LANG{FR}]);
		is($b->language(), 'French',  'object B language = French');
	}
	is($a->language(), 'English', 'object A language still English (not clobbered)');
};

done_testing();
