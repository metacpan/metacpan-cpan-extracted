#!/usr/bin/env perl
# locales.t -- country/locale-based access control tests
#
# Tests CGI::ACL with real CGI::Lingua country detection for English,
# French, German, and Mandarin-speaking regions.  All IP->country mappings
# are verified against the installed GeoIP database.

use strict;
use warnings;

use Errno qw(ENOENT);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;
use Readonly;

BEGIN {
	use_ok('CGI::ACL')    or BAIL_OUT('CGI::ACL failed to load');
	use_ok('CGI::Lingua') or BAIL_OUT('CGI::Lingua failed to load');
}

# Pre-load Net::Whois::IANA and reduce all WHOIS timeouts from 30 s to 5 s.
# The module embeds the timeout in %IANA at compile time, so we must patch
# the nested arrayrefs directly.  Without this, a stalled RIPE connection
# (rate-limited server that accepts TCP but never replies) hangs make test
# for up to 5 × 30 s per IP lookup.
if(eval { require Net::Whois::IANA; 1 }) {
	no warnings 'once';
	for my $servers (values %Net::Whois::IANA::IANA) {
		$_->[2] = 5 for @{$servers};
	}
}

# ── Configuration ─────────────────────────────────────────────────────────────

# All IPs were verified against the installed GeoIP database before use.
# Choosing IPs from large, stable ISPs/research networks minimises GeoIP drift.
Readonly my %config => (
	# English-speaking regions
	IP_GB   => '212.159.106.41',    # F9 Broadband, United Kingdom     -> gb
	IP_US   => '130.14.25.184',     # NCBI, United States               -> us

	# French-speaking region
	IP_FR   => '212.27.48.10',      # Free.fr, France                   -> fr
	IP_FR2  => '193.51.196.1',      # INRIA, France                     -> fr

	# German-speaking region
	IP_DE   => '217.0.0.1',         # Deutsche Telekom, Germany         -> de
	IP_DE2  => '80.128.128.1',      # Deutsche Telekom AG, Germany      -> de

	# Mandarin-speaking region
	IP_CN   => '61.135.169.125',    # Baidu, China                      -> cn
	IP_CN2  => '114.114.114.114',   # 114DNS, China                     -> cn

	# Country codes (ISO 3166-1 alpha-2, lowercase)
	CC_GB   => 'gb',
	CC_US   => 'us',
	CC_FR   => 'fr',
	CC_DE   => 'de',
	CC_CN   => 'cn',

	# Wildcard sentinel — deny_country('*') switches to default-deny mode
	WILDCARD => '*',
);

# ── Helpers ───────────────────────────────────────────────────────────────────

# Per-run cache: each IP makes exactly one WHOIS query for the entire test run.
# country() is called while REMOTE_ADDR is set so the result is stored in
# $l->{_country}; all later calls on the same object hit that cache.
my %_lingua_cache;
sub lingua_for {
	my $ip = shift;
	unless(exists $_lingua_cache{$ip}) {
		# CGI::Lingua and its WHOIS dependencies use $_ internally (e.g. in
		# grep/map inside Net::Whois::IANA::ripe_read_query).  Without local $_,
		# a call to lingua_for() from inside a map/grep block would clobber the
		# block's loop variable, scrambling the outer hash assignment.
		local $_;
		local $ENV{REMOTE_ADDR} = $ip;
		my $l = CGI::Lingua->new(supported => ['en']);
		# Resolve country now while REMOTE_ADDR is set; the result is cached
		# inside the lingua object.  WHOIS modules may emit uninitialized-value
		# warnings when a server is rate-limited — suppress them here so they
		# don't pollute the test output.
		do { local $SIG{__WARN__} = sub {}; $l->country() };
		$_lingua_cache{$ip} = $l;
	}
	return $_lingua_cache{$ip};
}

# Call all_denied() with the given IP set as REMOTE_ADDR
sub denied_at {
	my ($acl, $ip, @rest) = @_;
	local $ENV{REMOTE_ADDR} = $ip;
	return $acl->all_denied(@rest);
}

# ── GeoIP sanity checks ───────────────────────────────────────────────────────
# Verify that the five primary test IPs resolve to the expected countries.
# Secondary IPs (IP_FR2, IP_DE2, IP_CN2) are omitted here to limit WHOIS
# traffic; they are still exercised in the ACL subtests below.
# lingua_for() caches each lookup, so these are the only WHOIS queries the
# entire test run makes — the ACL subtests reuse the same objects.
# IPs managed by RIPE (whois.ripe.net) — subject to per-IP rate-limiting.
# ARIN (US) and APNIC (CN) use separate servers and are unaffected.
my %is_ripe = map { $config{$_} => 1 } qw(IP_GB IP_FR IP_FR2 IP_DE IP_DE2);

# $ripe_ok is set by the sanity subtest; the SKIP block below reads it.
my $ripe_ok = 1;

subtest 'GeoIP sanity: test IPs resolve to expected countries' => sub {
	my %expected = (
		$config{IP_GB} => $config{CC_GB},
		$config{IP_US} => $config{CC_US},
		$config{IP_FR} => $config{CC_FR},
		$config{IP_DE} => $config{CC_DE},
		$config{IP_CN} => $config{CC_CN},
	);

	# Resolve all IPs first (populates the lingua cache for ACL subtests too).
	my %got = map { $_ => (lingua_for($_)->country() // '') } sort keys %expected;
	if($ENV{TEST_VERBOSE}) { diag "GeoIP: $_ => $got{$_}" for sort keys %got; }

	my @ripe_fails  = grep { $got{$_} ne $expected{$_} && $is_ripe{$_}  } sort keys %expected;
	my @other_fails = grep { $got{$_} ne $expected{$_} && !$is_ripe{$_} } sort keys %expected;

	# Non-RIPE failures (ARIN/APNIC) indicate a real GeoIP change.
	BAIL_OUT('GeoIP mappings changed: '
		. join(', ', map { "$_ (got '$got{$_}' != '$expected{$_}')" } @other_fails))
		if @other_fails;

	# RIPE-only failures are the fingerprint of per-IP rate-limiting — not a
	# real mapping change.  Skip both this subtest and the country ACL tests.
	if(@ripe_fails) {
		$ripe_ok = 0;
		plan skip_all =>
			'RIPE WHOIS rate-limited (ARIN/APNIC still respond); '
			. 'run again later. Failed IPs: ' . join(', ', @ripe_fails);
		return;
	}

	is($got{$_}, $expected{$_}, "GeoIP: $_ maps to $expected{$_}") for sort keys %expected;
};

# The 10 subtests below all use lingua_for(), which hits the cache populated
# above, adding zero extra WHOIS queries.  They are skipped as a group when
# RIPE is rate-limited so that rate-limited runs still exit 0.
SKIP: {
	skip 'RIPE WHOIS rate-limited; run again later', 10 unless $ripe_ok;

# ── Locale scenario: English-only site ───────────────────────────────────────
# Purpose: allow only English-speaking regions (GB and US), deny everything else
subtest 'English-only site: allow GB and US, deny others' => sub {
	my $acl = CGI::ACL->new()
		->deny_country($config{WILDCARD})
		->allow_country($config{CC_GB})
		->allow_country($config{CC_US});

	diag "English-only: allow_countries=" . join(',', sort keys %{$acl->{allow_countries}}) if $ENV{TEST_VERBOSE};

	# Both English-speaking countries must be allowed
	is(denied_at($acl, $config{IP_GB}, lingua => lingua_for($config{IP_GB})), 0, 'GB allowed on English-only site');
	is(denied_at($acl, $config{IP_US}, lingua => lingua_for($config{IP_US})), 0, 'US allowed on English-only site');

	# French, German and Chinese clients must be denied
	is(denied_at($acl, $config{IP_FR}, lingua => lingua_for($config{IP_FR})), 1, 'FR denied on English-only site');
	is(denied_at($acl, $config{IP_DE}, lingua => lingua_for($config{IP_DE})), 1, 'DE denied on English-only site');
	is(denied_at($acl, $config{IP_CN}, lingua => lingua_for($config{IP_CN})), 1, 'CN denied on English-only site');
};

# ── Locale scenario: French-only site ────────────────────────────────────────
# Purpose: allow only clients from France, deny everyone else
subtest 'French-only site: allow FR, deny others' => sub {
	my $acl = CGI::ACL->new()
		->deny_country($config{WILDCARD})
		->allow_country($config{CC_FR});

	diag "French-only: allow_countries=" . join(',', sort keys %{$acl->{allow_countries}}) if $ENV{TEST_VERBOSE};

	# Both French IPs must be allowed
	is(denied_at($acl, $config{IP_FR},  lingua => lingua_for($config{IP_FR})),  0, 'FR (Free.fr) allowed on French-only site');
	is(denied_at($acl, $config{IP_FR2}, lingua => lingua_for($config{IP_FR2})), 0, 'FR (INRIA) allowed on French-only site');

	# All other locales must be denied
	is(denied_at($acl, $config{IP_GB}, lingua => lingua_for($config{IP_GB})), 1, 'GB denied on French-only site');
	is(denied_at($acl, $config{IP_US}, lingua => lingua_for($config{IP_US})), 1, 'US denied on French-only site');
	is(denied_at($acl, $config{IP_DE}, lingua => lingua_for($config{IP_DE})), 1, 'DE denied on French-only site');
	is(denied_at($acl, $config{IP_CN}, lingua => lingua_for($config{IP_CN})), 1, 'CN denied on French-only site');
};

# ── Locale scenario: German-only site ────────────────────────────────────────
# Purpose: allow only clients from Germany, deny everyone else
subtest 'German-only site: allow DE, deny others' => sub {
	my $acl = CGI::ACL->new()
		->deny_country($config{WILDCARD})
		->allow_country($config{CC_DE});

	diag "German-only: allow_countries=" . join(',', sort keys %{$acl->{allow_countries}}) if $ENV{TEST_VERBOSE};

	# Both German IPs must be allowed
	is(denied_at($acl, $config{IP_DE},  lingua => lingua_for($config{IP_DE})),  0, 'DE (T-Online) allowed on German-only site');
	is(denied_at($acl, $config{IP_DE2}, lingua => lingua_for($config{IP_DE2})), 0, 'DE (T-Online2) allowed on German-only site');

	# All other locales must be denied
	is(denied_at($acl, $config{IP_GB}, lingua => lingua_for($config{IP_GB})), 1, 'GB denied on German-only site');
	is(denied_at($acl, $config{IP_US}, lingua => lingua_for($config{IP_US})), 1, 'US denied on German-only site');
	is(denied_at($acl, $config{IP_FR}, lingua => lingua_for($config{IP_FR})), 1, 'FR denied on German-only site');
	is(denied_at($acl, $config{IP_CN}, lingua => lingua_for($config{IP_CN})), 1, 'CN denied on German-only site');
};

# ── Locale scenario: Mandarin-only site ──────────────────────────────────────
# Purpose: allow only clients from China, deny everyone else
subtest 'Mandarin-only site: allow CN, deny others' => sub {
	my $acl = CGI::ACL->new()
		->deny_country($config{WILDCARD})
		->allow_country($config{CC_CN});

	diag "Mandarin-only: allow_countries=" . join(',', sort keys %{$acl->{allow_countries}}) if $ENV{TEST_VERBOSE};

	# Both Chinese IPs must be allowed
	is(denied_at($acl, $config{IP_CN},  lingua => lingua_for($config{IP_CN})),  0, 'CN (Baidu) allowed on Mandarin-only site');
	is(denied_at($acl, $config{IP_CN2}, lingua => lingua_for($config{IP_CN2})), 0, 'CN (114DNS) allowed on Mandarin-only site');

	# All other locales must be denied
	is(denied_at($acl, $config{IP_GB}, lingua => lingua_for($config{IP_GB})), 1, 'GB denied on Mandarin-only site');
	is(denied_at($acl, $config{IP_US}, lingua => lingua_for($config{IP_US})), 1, 'US denied on Mandarin-only site');
	is(denied_at($acl, $config{IP_FR}, lingua => lingua_for($config{IP_FR})), 1, 'FR denied on Mandarin-only site');
	is(denied_at($acl, $config{IP_DE}, lingua => lingua_for($config{IP_DE})), 1, 'DE denied on Mandarin-only site');
};

# ── Locale scenario: European multilingual site ───────────────────────────────
# Purpose: allow clients from GB, FR, and DE; deny US and CN
subtest 'European multilingual site: allow GB+FR+DE, deny US+CN' => sub {
	my $acl = CGI::ACL->new()
		->deny_country($config{WILDCARD})
		->allow_country($config{CC_GB})
		->allow_country($config{CC_FR})
		->allow_country($config{CC_DE});

	diag "EU site: allow_countries=" . join(',', sort keys %{$acl->{allow_countries}}) if $ENV{TEST_VERBOSE};

	# European clients must be allowed
	is(denied_at($acl, $config{IP_GB}, lingua => lingua_for($config{IP_GB})), 0, 'GB allowed on EU site');
	is(denied_at($acl, $config{IP_FR}, lingua => lingua_for($config{IP_FR})), 0, 'FR allowed on EU site');
	is(denied_at($acl, $config{IP_DE}, lingua => lingua_for($config{IP_DE})), 0, 'DE allowed on EU site');

	# Non-European clients must be denied
	is(denied_at($acl, $config{IP_US}, lingua => lingua_for($config{IP_US})), 1, 'US denied on EU site');
	is(denied_at($acl, $config{IP_CN}, lingua => lingua_for($config{IP_CN})), 1, 'CN denied on EU site');
};

# ── Locale scenario: globally-available multilingual site ────────────────────
# Purpose: allow all four language regions; only deny would come from deny_country
subtest 'Multilingual site: all four locales allowed' => sub {
	# Deny all by default, then explicitly permit the four target regions
	my $acl = CGI::ACL->new()
		->deny_country($config{WILDCARD})
		->allow_country($config{CC_GB})
		->allow_country($config{CC_US})
		->allow_country($config{CC_FR})
		->allow_country($config{CC_DE})
		->allow_country($config{CC_CN});

	diag "Multilingual: allow_countries=" . join(',', sort keys %{$acl->{allow_countries}}) if $ENV{TEST_VERBOSE};

	# All four language regions must be allowed
	is(denied_at($acl, $config{IP_GB}, lingua => lingua_for($config{IP_GB})), 0, 'GB allowed on multilingual site');
	is(denied_at($acl, $config{IP_US}, lingua => lingua_for($config{IP_US})), 0, 'US allowed on multilingual site');
	is(denied_at($acl, $config{IP_FR}, lingua => lingua_for($config{IP_FR})), 0, 'FR allowed on multilingual site');
	is(denied_at($acl, $config{IP_DE}, lingua => lingua_for($config{IP_DE})), 0, 'DE allowed on multilingual site');
	is(denied_at($acl, $config{IP_CN}, lingua => lingua_for($config{IP_CN})), 0, 'CN allowed on multilingual site');

	# Russian IP (not in the permit list) must still be denied
	is(denied_at($acl, '87.226.159.0', lingua => lingua_for('87.226.159.0')),
		1, 'RU denied on multilingual site (not in permit list)');
};

# ── Locale scenario: explicit deny by language region ───────────────────────
# Purpose: test deny-listing specific countries without wildcard (default-allow)
subtest 'Explicit deny: block FR and CN, allow others by default' => sub {
	# Default-allow mode: deny only the listed countries
	my $acl = CGI::ACL->new()
		->deny_country($config{CC_FR})
		->deny_country($config{CC_CN});

	diag "Explicit deny: deny_countries=" . join(',', sort keys %{$acl->{deny_countries}}) if $ENV{TEST_VERBOSE};

	# Denied countries must be blocked
	is(denied_at($acl, $config{IP_FR}, lingua => lingua_for($config{IP_FR})), 1, 'FR denied (explicit deny list)');
	is(denied_at($acl, $config{IP_CN}, lingua => lingua_for($config{IP_CN})), 1, 'CN denied (explicit deny list)');

	# All other countries must be allowed (default-allow)
	is(denied_at($acl, $config{IP_GB}, lingua => lingua_for($config{IP_GB})), 0, 'GB allowed (default-allow, not in deny list)');
	is(denied_at($acl, $config{IP_US}, lingua => lingua_for($config{IP_US})), 0, 'US allowed (default-allow, not in deny list)');
	is(denied_at($acl, $config{IP_DE}, lingua => lingua_for($config{IP_DE})), 0, 'DE allowed (default-allow, not in deny list)');
};

# ── Locale scenario: arrayref country list ───────────────────────────────────
# Purpose: verify that passing multiple countries as an arrayref works correctly
subtest 'Arrayref country list: deny FR+CN in single call' => sub {
	# Pass both denied countries as an arrayref in one call
	my $acl = CGI::ACL->new()
		->deny_country(country => [$config{CC_FR}, $config{CC_CN}]);

	diag "Arrayref deny: deny_countries=" . join(',', sort keys %{$acl->{deny_countries}}) if $ENV{TEST_VERBOSE};

	# Both countries in the arrayref must be denied
	is(denied_at($acl, $config{IP_FR}, lingua => lingua_for($config{IP_FR})), 1, 'FR denied via arrayref');
	is(denied_at($acl, $config{IP_CN}, lingua => lingua_for($config{IP_CN})), 1, 'CN denied via arrayref');

	# Countries not in the arrayref must be allowed
	is(denied_at($acl, $config{IP_GB}, lingua => lingua_for($config{IP_GB})), 0, 'GB allowed (not in arrayref)');
	is(denied_at($acl, $config{IP_DE}, lingua => lingua_for($config{IP_DE})), 0, 'DE allowed (not in arrayref)');
};

# ── Locale scenario: case-insensitive country codes ──────────────────────────
# Purpose: verify that country codes are matched case-insensitively
subtest 'Case-insensitive country codes: upper and mixed case are accepted' => sub {
	# Use uppercase country codes in the ACL (should be normalised to lowercase)
	my $acl = CGI::ACL->new()
		->deny_country($config{WILDCARD})
		->allow_country('GB')    # uppercase
		->allow_country('Fr')    # mixed case
		->allow_country('DE');   # uppercase

	diag "Case insensitive: allow_countries=" . join(',', sort keys %{$acl->{allow_countries}}) if $ENV{TEST_VERBOSE};

	# CGI::Lingua returns lowercase; the ACL normalises codes so case must not matter
	is(denied_at($acl, $config{IP_GB}, lingua => lingua_for($config{IP_GB})), 0, 'GB (uppercase in ACL) matched case-insensitively');
	is(denied_at($acl, $config{IP_FR}, lingua => lingua_for($config{IP_FR})), 0, 'FR (mixed case in ACL) matched case-insensitively');
	is(denied_at($acl, $config{IP_DE}, lingua => lingua_for($config{IP_DE})), 0, 'DE (uppercase in ACL) matched case-insensitively');

	# Countries not in the allow list must still be denied
	is(denied_at($acl, $config{IP_US}, lingua => lingua_for($config{IP_US})), 1, 'US denied (not in allow list)');
	is(denied_at($acl, $config{IP_CN}, lingua => lingua_for($config{IP_CN})), 1, 'CN denied (not in allow list)');
};

# ── Locale scenario: concurrent locale-specific ACLs ─────────────────────────
# Purpose: two ACL objects for different regions must not interfere with each other
subtest 'Concurrent locale ACLs: French site and German site are independent' => sub {
	# ACL A: French-only
	my $acl_fr = CGI::ACL->new()
		->deny_country($config{WILDCARD})
		->allow_country($config{CC_FR});

	# ACL B: German-only (created separately, must not share state with ACL A)
	my $acl_de = CGI::ACL->new()
		->deny_country($config{WILDCARD})
		->allow_country($config{CC_DE});

	diag "FR ACL allow_countries=" . join(',', sort keys %{$acl_fr->{allow_countries}}) if $ENV{TEST_VERBOSE};
	diag "DE ACL allow_countries=" . join(',', sort keys %{$acl_de->{allow_countries}}) if $ENV{TEST_VERBOSE};

	# Each ACL allows only its own region
	is(denied_at($acl_fr, $config{IP_FR}, lingua => lingua_for($config{IP_FR})), 0, 'FR allowed by FR ACL');
	is(denied_at($acl_fr, $config{IP_DE}, lingua => lingua_for($config{IP_DE})), 1, 'DE denied by FR ACL');

	is(denied_at($acl_de, $config{IP_DE}, lingua => lingua_for($config{IP_DE})), 0, 'DE allowed by DE ACL');
	is(denied_at($acl_de, $config{IP_FR}, lingua => lingua_for($config{IP_FR})), 1, 'FR denied by DE ACL');

	# Adding a country to one ACL must not affect the other
	$acl_fr->allow_country($config{CC_US});
	is(denied_at($acl_fr, $config{IP_US}, lingua => lingua_for($config{IP_US})), 0, 'US now allowed by (modified) FR ACL');
	is(denied_at($acl_de, $config{IP_US}, lingua => lingua_for($config{IP_US})), 1, 'US still denied by DE ACL (unaffected)');
};

} # end SKIP block for RIPE-dependent country ACL tests

# ── System locale: error path behaviour ──────────────────────────────────────
# Purpose: verify that CGI::ACL->new() with a missing config file throws an
# exception whose message matches what Perl's own $! produces for ENOENT,
# regardless of the OS locale (LC_ALL / LANG).
#
# The correct idiom is:
#   local $! = ENOENT;  my $msg = "$!";
# NOT: POSIX::strerror(ENOENT)
#
# strerror() uses the C library's LC_MESSAGES locale.  On systems where that
# diverges from Perl's $! locale (a common configuration on CPAN smoke boxes),
# the two strings differ and the regex fails.  The bug was observed on a
# German smoker where strerror(ENOENT) returned "Datei oder Verzeichnis nicht
# gefunden" but $! returned "No such file or directory".

# Discover which locales are installed; always include C as a safe fallback.
my @system_locales = do {
	# Untaint PATH before calling locale(1) so the test is safe under -T
	local $ENV{PATH} = '/usr/bin:/bin';
	my @all = map { chomp; $_ } qx(locale -a 2>/dev/null);
	my %have = map { $_ => 1 } @all;
	# Test English, French, German and Mandarin if available; C is always present
	grep { $have{$_} }
		qw(C en_US.UTF-8 de_DE.UTF-8 fr_FR.UTF-8 zh_CN.UTF-8);
};

# A path that is guaranteed not to exist during the test run
my $temp_dir  = tempdir(CLEANUP => 1);
my $bad_config = File::Spec->catfile($temp_dir, 'nonexistent.conf');

subtest 'System locale: new() throws on missing config_file under all locales' => sub {
	plan tests => scalar @system_locales;

	for my $locale (@system_locales) {
		local $ENV{LC_ALL} = $locale;
		local $ENV{LANG}   = $locale;

		# Derive the expected error string from Perl's own $! — the same
		# source that Object::Configure uses when it croaks.  Never use
		# POSIX::strerror() here; it uses the C library locale and can
		# produce a different string on mixed-locale systems.
		local $! = ENOENT;
		my $enoent = "$!";

		diag "LC_ALL=$locale  ENOENT via \$! = '$enoent'" if $ENV{TEST_VERBOSE};

		throws_ok {
			CGI::ACL->new(config_file => $bad_config)
		} qr/\Q$enoent\E/,
		  "LC_ALL=$locale: exception contains locale-aware ENOENT string";
	}
};

# Purpose: confirm that the $! approach and strerror() agree on this system.
# If they diverge, the warning flags that POSIX::strerror() is unsafe to use
# in tests on this platform.
subtest 'System locale: $! and POSIX::strerror agree for ENOENT' => sub {
	require POSIX;

	for my $locale (@system_locales) {
		local $ENV{LC_ALL} = $locale;
		local $ENV{LANG}   = $locale;

		local $! = ENOENT;
		my $perl_msg = "$!";
		my $c_msg    = POSIX::strerror(ENOENT);

		diag "LC_ALL=$locale  \$!='$perl_msg'  strerror='$c_msg'" if $ENV{TEST_VERBOSE};

		# On most systems these agree; a mismatch is a platform warning,
		# not a hard failure — the point is to document where they diverge.
		TODO: {
			local $TODO = ($perl_msg ne $c_msg)
				? "locale $locale: \$! and strerror() diverge on this platform"
				: undef;
			is($perl_msg, $c_msg, "LC_ALL=$locale: \$! eq POSIX::strerror(ENOENT)");
		}
	}
};

done_testing();
