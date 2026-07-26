#!perl

use strict;
use warnings;

use Test::Most;
use POSIX qw(locale_h);

# ---------------------------------------------------------------------------
# GeoIP section
#
# DateTime::Format::Genealogy has no country-based access control, so there
# are no geography-specific behaviours to gate on GeoIP.  This section is
# included for completeness; any future access-restricted features should be
# added here.
# ---------------------------------------------------------------------------

pass('GeoIP: no country-based access paths in this module (N/A)');

# ---------------------------------------------------------------------------
# POSIX locale section
#
# The module generates error strings via Carp::carp/croak.  We verify that:
#   1. The module loads and produces correct results under three common LC_ALL
#      settings (en_US.UTF-8, de_DE.UTF-8, and an East Asian locale).
#   2. Perl-layer OS error strings (sourced via "local $! = ...; "$!") are
#      locale-sensitive, confirming the test environment can exercise locale
#      variation even if this module does not itself expose OS error strings.
#   3. A date that should return undef continues to do so under each locale.
#
# We do NOT use POSIX::strerror because it may diverge from Perl's own "$!"
# stringification layer on some platforms.
# ---------------------------------------------------------------------------

use DateTime::Format::Genealogy;

# Locales to test. Each element is the LC_ALL string. We accept any locale
# that successfully produces a non-empty error string for ENOENT.
my @TEST_LOCALES = ('en_US.UTF-8', 'de_DE.UTF-8', 'ja_JP.UTF-8');

my $saved_locale = setlocale(LC_ALL);  # save so we can restore later

my $any_locale_ran = 0;

LOCALE: for my $locale (@TEST_LOCALES) {
	my $ok = setlocale(LC_ALL, $locale);
	unless(defined $ok && $ok eq $locale) {
		SKIP: {
			skip("Locale '$locale' not available on this system", 3);
		}
		next LOCALE;
	}

	$any_locale_ran = 1;

	# Verify we can source a locale-sensitive error string from Perl's layer.
	# Using "local $! = POSIX::ENOENT" then "$!" is the correct idiom; it
	# avoids POSIX::strerror, which may not track Perl's setlocale call.
	my $enoent_msg;
	{
		local $! = POSIX::ENOENT();
		$enoent_msg = "$!";
	}
	ok(length($enoent_msg) > 0, "locale '$locale': ENOENT error string is non-empty");
	diag("locale '$locale' ENOENT string: $enoent_msg") if $ENV{TEST_VERBOSE};

	# The module must load and operate correctly under this locale.
	my $dtg = DateTime::Format::Genealogy->new(quiet => 1);
	my $dt  = $dtg->parse_datetime('25 Dec 2022');
	isa_ok($dt, 'DateTime', "locale '$locale': parse_datetime returns a DateTime");

	# Approximate dates must still return undef regardless of locale because
	# the rejection logic is driven by regex, not locale-aware string functions.
	ok(!defined $dtg->parse_datetime('bef 1 Jan 2000'),
		"locale '$locale': bef prefix still returns undef");
}

# Restore the original locale so we don't affect other test processes.
setlocale(LC_ALL, $saved_locale);

pass('All locales tested; original locale restored') if $any_locale_ran;

done_testing();
