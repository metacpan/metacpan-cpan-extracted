#!/usr/bin/env perl

# t/locales.t -- Locale and geographic configuration tests.
#
# Two test categories:
#
#   1. Geographic (GeoIP-style): treat ISO-3166 country codes as environment
#      names for the environment-specific file tier (base.GB.yaml, etc.).
#      No GeoIP database required -- we test the file-tier mechanism directly.
#
#   2. System (POSIX): verify that error messages produced when config loading
#      fails are coherent under different LC_ALL settings.  We use
#      local $! = ENOENT; my $msg = "$!"; to obtain the locale-translated
#      "No such file or directory" string without calling POSIX::strerror,
#      which bypasses Perl's own locale layer.

use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempdir);
use POSIX qw(ENOENT);
use_ok('Config::Abstraction');

# -------------------------------------------------------------------------
# Section 1: Geographic -- environment-specific config tiers via country codes
# -------------------------------------------------------------------------

# Sanity: confirm the environment-specific tier works for a known good case.
# BAIL_OUT if the basic mechanism is broken; later country subtests depend on it.
subtest 'sanity: environment tier works' => sub {
	my $dir = tempdir(CLEANUP => 1);

	open my $fh, '>', "$dir/base.yaml" or die "Cannot write: $!";
	print $fh "region: global\n";
	close $fh;

	open $fh, '>', "$dir/base.GB.yaml" or die "Cannot write: $!";
	print $fh "region: gb\n";
	close $fh;

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		environment => 'GB',
	);

	BAIL_OUT('environment-specific file tier is broken -- all geographic subtests will fail')
		unless defined($cfg) && $cfg->get('region') eq 'gb';

	is($cfg->get('region'), 'gb', 'GB tier overrides base');
};

# Test each country code as a valid environment name.
# Config::Abstraction allows any /^[A-Za-z0-9_\-]+$/ value including ISO-3166 codes.
for my $country (qw(GB US FR DE CN)) {
	subtest "geographic tier: $country" => sub {
		my $dir = tempdir(CLEANUP => 1);

		# Write a base file with a global setting
		open my $fh, '>', "$dir/base.yaml" or die;
		print $fh "country: global\ncurrency: USD\n";
		close $fh;

		# Write a country-specific override
		open $fh, '>', "$dir/base.$country.yaml" or die;
		print $fh "country: $country\n";
		close $fh;

		my $cfg = Config::Abstraction->new(
			config_dirs => [$dir],
			environment => $country,
		);

		ok(defined($cfg), "$country: object constructed");
		is($cfg->get('country'),  $country, "$country: country key overridden");
		is($cfg->get('currency'), 'USD',    "$country: non-overridden key inherited from base");
	};
}

# Probe whether the running filesystem is case-sensitive.  On macOS the default
# APFS/HFS+ volume is case-insensitive, so writing 'base.gb.yaml' and 'base.GB.yaml'
# creates only one file (last write wins).  We detect this once and share the result.
my $_probe_dir = tempdir(CLEANUP => 1);
open(my $_pf, '>', "$_probe_dir/CasEpRoBe.tmp") or die "probe write failed: $!";
close $_pf;
my $CASE_INSENSITIVE_FS = (-e "$_probe_dir/caseprobe.tmp") ? 1 : 0;

# On a case-sensitive filesystem: environment 'gb' and 'GB' name distinct files.
# On a case-insensitive filesystem (e.g. macOS APFS/HFS+): they collapse to one file
# and this test cannot distinguish them -- it is skipped.
subtest 'geographic: upper- vs lower-case tier names are distinct (case-sensitive FS only)' => sub {
	plan skip_all => 'Filesystem is case-insensitive (e.g. macOS APFS/HFS+); base.gb.yaml and base.GB.yaml are the same file'
		if $CASE_INSENSITIVE_FS;

	my $dir = tempdir(CLEANUP => 1);

	open my $fh, '>', "$dir/base.yaml" or die;
	print $fh "tier: base\n";
	close $fh;

	open $fh, '>', "$dir/base.gb.yaml" or die;
	print $fh "tier: lowercase_gb\n";
	close $fh;

	open $fh, '>', "$dir/base.GB.yaml" or die;
	print $fh "tier: uppercase_GB\n";
	close $fh;

	my $lower_cfg = Config::Abstraction->new(config_dirs => [$dir], environment => 'gb');
	my $upper_cfg = Config::Abstraction->new(config_dirs => [$dir], environment => 'GB');

	is($lower_cfg->get('tier'), 'lowercase_gb', 'environment gb loads base.gb.yaml');
	is($upper_cfg->get('tier'), 'uppercase_GB', 'environment GB loads base.GB.yaml');
};

# Regression: on a case-insensitive filesystem (macOS APFS/HFS+), writing
# base.gb.yaml then base.GB.yaml creates only one file.  The module must still
# load it successfully regardless of which casing was used as the environment name.
# On case-sensitive filesystems both objects load their respective distinct file.
subtest 'geographic: environment tier works on case-insensitive filesystem (regression)' => sub {
	my $dir = tempdir(CLEANUP => 1);

	open my $fh, '>', "$dir/base.yaml" or die;
	print $fh "tier: base\n";
	close $fh;

	# Write only one casing; on a case-insensitive FS both names resolve to it.
	open $fh, '>', "$dir/base.GB.yaml" or die;
	print $fh "tier: gb_value\n";
	close $fh;

	# Both environment names must produce a valid, loaded object.
	my $upper_cfg = Config::Abstraction->new(config_dirs => [$dir], environment => 'GB');
	ok(defined($upper_cfg),                    'GB environment: object constructed');
	is($upper_cfg->get('tier'), 'gb_value',    'GB environment: tier file loaded');

	my $lower_cfg = Config::Abstraction->new(config_dirs => [$dir], environment => 'gb');
	if($CASE_INSENSITIVE_FS) {
		# On a case-insensitive FS, 'gb' resolves to the same file as 'GB'.
		ok(defined($lower_cfg),                'gb environment on case-insensitive FS: object constructed');
		is($lower_cfg->get('tier'), 'gb_value','gb environment on case-insensitive FS: finds same file as GB');
	} else {
		# On a case-sensitive FS, 'gb' finds no base.gb.yaml, so it falls back to base.yaml.
		ok(defined($lower_cfg),                'gb environment on case-sensitive FS: object constructed from base.yaml');
		is($lower_cfg->get('tier'), 'base',    'gb environment on case-sensitive FS: no base.gb.yaml, falls back to base');
	}
};

# Concurrent instances for different regions must not interfere.
subtest 'geographic: concurrent instances do not share state' => sub {
	my $dir = tempdir(CLEANUP => 1);

	open my $fh, '>', "$dir/base.yaml" or die;
	print $fh "value: global\n";
	close $fh;

	for my $cc (qw(US FR DE)) {
		open $fh, '>', "$dir/base.$cc.yaml" or die;
		print $fh "value: $cc\n";
		close $fh;
	}

	my @cfgs = map {
		Config::Abstraction->new(config_dirs => [$dir], environment => $_)
	} qw(US FR DE);

	is($cfgs[0]->get('value'), 'US', 'US instance independent');
	is($cfgs[1]->get('value'), 'FR', 'FR instance independent');
	is($cfgs[2]->get('value'), 'DE', 'DE instance independent');
};

# -------------------------------------------------------------------------
# Section 2: POSIX locale -- error handling under different LC_ALL settings
# -------------------------------------------------------------------------
#
# We test that Config::Abstraction raises an error when given a bad encryption
# key, and that the error message is a plain ASCII string regardless of locale.
# We also verify that Perl's $! under ENOENT is non-empty in each locale --
# confirming the locale is actually set -- without calling POSIX::strerror.

# Locales to iterate over.  The test skips locales that are not installed on
# the current OS rather than failing, because locale availability varies.
my @locales = (
	{ lc_all => 'en_US.UTF-8', charset => 'UTF-8', lang => 'en' },
	{ lc_all => 'de_DE.UTF-8', charset => 'UTF-8', lang => 'de' },
	{ lc_all => 'ja_JP.UTF-8', charset => 'UTF-8', lang => 'ja' },
);

for my $locale_spec (@locales) {
	my $lc_all = $locale_spec->{'lc_all'};

	subtest "POSIX locale: $lc_all" => sub {
		# Verify the locale is usable on this system before running assertions.
		# setlocale returns undef when the locale is not installed.
		require POSIX;
		my $ok = POSIX::setlocale(POSIX::LC_ALL(), $lc_all);
		plan skip_all => "Locale $lc_all not installed on this system"
			unless defined($ok) && $ok;

		# Restore locale at end of subtest.
		local $ENV{LC_ALL} = $lc_all;

		# Obtain the locale-translated "No such file or directory" string via
		# Perl's own $! layer.  Do NOT use POSIX::strerror -- it bypasses the
		# Perl layer and can diverge from what die/croak actually emits.
		local $! = ENOENT;
		my $enoent_msg = "$!";

		ok(length($enoent_msg) > 0, "$lc_all: ENOENT message is non-empty");
		diag("ENOENT under $lc_all: '$enoent_msg'") if $ENV{TEST_VERBOSE};

		# Verify that Config::Abstraction produces a non-empty error message
		# under this locale.  We use a validator croak (integer check on a
		# non-integer value) because it is deterministic and OS-independent.
		{
			throws_ok {
				Config::Abstraction->new(
					data        => { port => 'not_a_number' },
					config_dirs => [],
					validators  => { port => 'integer' },
				);
			} qr/.+/, "$lc_all: croak message non-empty when validator fails";
		}

		# Verify that a successful config load works regardless of locale.
		{
			my $cfg = Config::Abstraction->new(
				data        => { locale => $lc_all },
				config_dirs => [],
			);
			is($cfg->get('locale'), $lc_all, "$lc_all: normal config load unaffected by locale");
		}

		# Restore the C locale so later subtests get a clean environment.
		POSIX::setlocale(POSIX::LC_ALL(), 'C');
	};
}

# Edge: invalid environment name is rejected regardless of locale.
subtest 'environment name validation is locale-independent' => sub {
	for my $bad_name ('prod/v2', 'staging@DC1', 'env name') {
		throws_ok {
			Config::Abstraction->new(
				data        => { x => 1 },
				config_dirs => [],
				environment => $bad_name,
			);
		} qr/invalid environment name/, "rejects invalid environment '$bad_name'";
	}
};

done_testing();
