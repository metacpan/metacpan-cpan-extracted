use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempdir);
use Path::Tiny;
use POSIX qw(LC_ALL setlocale ENOENT);
use App::makefilepl2cpanfile;

# -----------------------------------------------------------------------
# GeoIP subtests
# -----------------------------------------------------------------------
# App::makefilepl2cpanfile has no geographic access control.  GeoIP testing
# is not applicable to this module and is intentionally omitted.

# -----------------------------------------------------------------------
# POSIX locale subtests
# -----------------------------------------------------------------------
# Verify that generate() throws a structured Carp error (matching
# "Cannot read") regardless of the active system locale.  We source the
# ENOENT message directly from Perl's own error layer rather than calling
# POSIX::strerror() to prevent C-library divergence under locale switches.

# Sanity subtest: bail out early if ENOENT is not usable on this platform.
subtest 'POSIX sanity — ENOENT is accessible' => sub {
	my $enoent_str;
	{
		local $! = ENOENT;
		$enoent_str = "$!";
	}
	ok defined ENOENT,          'ENOENT constant is defined';
	ok length($enoent_str) > 0, 'ENOENT yields a non-empty error string';
	BAIL_OUT('Cannot source ENOENT error message — aborting locale tests')
		unless length($enoent_str) > 0;
};

# Helper: return true only when the locale is actually supported by this OS.
sub _locale_available {
	my ($locale) = @_;
	my $saved = setlocale(LC_ALL);
	my $result = setlocale(LC_ALL, $locale);
	setlocale(LC_ALL, $saved);
	return defined $result && $result eq $locale;
}

my @locales = (
	'en_US.UTF-8',
	'de_DE.UTF-8',
	'ja_JP.UTF-8',    # representative East Asian locale
);

for my $locale (@locales) {
	SKIP: {
		skip "locale $locale not available on this system", 1
			unless _locale_available($locale);

		subtest "error path under LC_ALL=$locale" => sub {
			local $ENV{LC_ALL} = $locale;
			setlocale(LC_ALL, $locale);

			# Source the ENOENT message from Perl's layer — do NOT use
			# POSIX::strerror(), which can diverge from Perl under some locales.
			my $enoent_str;
			{
				local $! = ENOENT;
				$enoent_str = "$!";
			}
			ok length($enoent_str) > 0,
				"ENOENT string is non-empty under $locale";

			# generate() must croak with its own structured message regardless
			# of the underlying OS error string for the locale.
			eval {
				App::makefilepl2cpanfile::generate(
					makefile => '/no/such/path/Makefile.PL'
				);
			};
			my $err = $@;
			ok $err, "generate() throws under $locale";
			like $err, qr/Cannot read/,
				"error matches 'Cannot read' pattern under $locale";
		};

		# Restore the default locale after each subtest.
		setlocale(LC_ALL, 'C');
	}
}

done_testing;
