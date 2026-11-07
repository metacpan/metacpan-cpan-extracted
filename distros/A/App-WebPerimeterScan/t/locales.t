use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Errno qw(ENOENT ECONNREFUSED ETIMEDOUT);
use File::Temp qw(tempdir);
use IO::Socket::INET;
use POSIX qw(setlocale LC_ALL);
use Test::More;

use App::WebPerimeterScan::HTTP;
use App::WebPerimeterScan::I18N;
use App::WebPerimeterScan::Scope;

# ---------------------------------------------------------------------------
# Geographic (GeoIP)
#
# App::WebPerimeterScan makes no decision based on where an address is: it
# does not look up countries, and neither the scope nor any rule depends on
# one.  There is therefore no country mapping to sanity-check and nothing for
# a GB/US/FR/DE/CN test to exercise.  The subtest is kept, skipped, so that
# adding a geographic feature later has an obvious place for its tests; it
# must start with a BAIL_OUT sanity check of the mapping when it does.
# ---------------------------------------------------------------------------

subtest 'geographic (GeoIP)' => sub {
	plan skip_all => 'the scanner has no country-based behaviour to test';
};

# ---------------------------------------------------------------------------
# System (POSIX) locales
#
# The operating system's reason for a failure reaches the user inside our
# messages.  Under each locale, the error must still be thrown, must carry
# exactly the text Perl itself gives for that errno, and must be wrapped in
# the catalogue's text (English until a catalogue exists for the language).
#
# The expected text is taken from Perl's own $! - never POSIX::strerror -
# so this test and the code under test read the same layer and cannot
# disagree because of the C library.
# ---------------------------------------------------------------------------

my @LOCALES = (
	[ 'en_US.UTF-8', 'English' ],
	[ 'de_DE.UTF-8', 'German' ],
	[ 'ja_JP.UTF-8', 'Japanese (East Asian)' ],
);

my $original_locale = setlocale(LC_ALL);
my $missing = tempdir(CLEANUP => 1) . '/no-such-scope.txt';

for my $locale (@LOCALES) {
	my ($name, $label) = @{$locale};

	subtest "$label ($name)" => sub {
		local $ENV{LC_ALL} = $name;
		local $ENV{LANGUAGE};

		# Not every machine has every locale; the checks still hold in
		# the C locale, which is what Perl falls back to.
		my $installed = defined setlocale(LC_ALL, $name);
		note($installed ? "locale $name is active" : "locale $name is not installed; using the fallback");

		my $enoent = do { local $! = ENOENT; "$!" };

		my $error = do { local $@; eval { App::WebPerimeterScan::Scope->new->load_file($missing) }; $@ };
		ok(length $error, 'a missing scope file still throws');
		like($error, qr/\QCannot read scope file '$missing': $enoent\E/,
			"the operating system's reason is the one Perl reports for ENOENT");
		is(App::WebPerimeterScan::I18N->language, 'en', 'the catalogue falls back to English');

		my $clean = App::WebPerimeterScan::I18N::clean_error($error);
		unlike($clean, qr/ line \d+\.?\z/, 'clean_error removes the location in this locale too');

		SKIP: {
			skip 'connection-failure behaviour differs on Windows', 2 if $^O eq 'MSWin32';
			my $closed = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp')
				or skip 'cannot bind a port', 2;

			# A port that is bound but not listening is refused on Linux,
			# but macOS drops the SYN and the connect times out.  Either
			# way the reason must be Perl's own text for that errno.
			my @reasons = map { local $! = $_; "$!" } ECONNREFUSED, ETIMEDOUT;
			my $res = App::WebPerimeterScan::HTTP->new(delay => 0, timeout => 2)
				->fetch('http://127.0.0.1:' . $closed->sockport . '/');
			ok($res->{error}, 'a failed connection is reported, not thrown');
			like($res->{error}, qr/\Aconnect failed: (?:\Q$reasons[0]\E|\Q$reasons[1]\E)\z/,
				"... with Perl's text for ECONNREFUSED or ETIMEDOUT")
				or diag "expected one of: @reasons";
		}

		# Concurrent objects in one process see the same locale.
		my @scopes = map { App::WebPerimeterScan::Scope->new } 1 .. 3;
		is(scalar(grep { $_->source eq '(none)' } @scopes), 3, 'several instances render the same text');
	};
}

setlocale(LC_ALL, $original_locale);

done_testing();
