#!perl

# Locale tests.
#
# 1. Message language: how App::Access2CSV::I18N picks a catalog from the
#    locale, including case-insensitivity and independent instances.
# 2. System (POSIX) locale: error paths that embed an operating-system
#    error string must still throw, with the right text, whatever LC_ALL
#    is.  The expected text is taken from Perl's own $! (not
#    POSIX::strerror) so that it matches what the module sees.
#
# Geographic (GeoIP) tests are deliberately absent: App::Access2CSV has
# no country-dependent behaviour, so there is nothing to map or test.

use strict;
use warnings;

use Test::Most;

use Errno qw(ENOENT);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX qw(LC_ALL setlocale);

use App::Access2CSV;
use App::Access2CSV::Exporter;

# The UTF-8 locales to try: English, German and an East Asian language
my @LOCALES = qw(en_US.UTF-8 de_DE.UTF-8 ja_JP.UTF-8);

local @ENV{qw(LANGUAGE LC_ALL LC_MESSAGES LANG)} = (undef) x 4;

subtest 'message language sanity' => sub {
	# If the fallback language is wrong, every later check is meaningless
	is(App::Access2CSV::I18N->i18n('dry_run_title'), 'DRY RUN', 'default catalog is English')
		or BAIL_OUT('default message catalog is not English');
};

subtest 'message language follows the locale' => sub {
	local $App::Access2CSV::I18N::MESSAGES{de} = { dry_run_title => 'PROBELAUF' };

	foreach my $case (
		['de_DE.UTF-8', 'PROBELAUF', 'German'],
		['DE_de.utf8',  'PROBELAUF', 'language code is case-insensitive'],
		['de',          'PROBELAUF', 'bare language code'],
		['en_US.UTF-8', 'DRY RUN',   'English'],
		['ja_JP.UTF-8', 'DRY RUN',   'no Japanese catalog: English'],
		['zh_CN.UTF-8', 'DRY RUN',   'no Chinese catalog: English'],
		['POSIX',       'DRY RUN',   'POSIX locale'],
	) {
		my ($locale, $expected, $name) = @{$case};
		local $ENV{LC_ALL} = $locale;
		is(App::Access2CSV::I18N->i18n('dry_run_title'), $expected, $name);
	}
};

subtest 'instances with different languages do not interfere' => sub {
	local $App::Access2CSV::I18N::MESSAGES{de} = { dry_run_title => 'PROBELAUF' };
	local $ENV{LC_ALL} = 'de_DE.UTF-8';

	my $german  = App::Access2CSV::Exporter->new();
	my $english = App::Access2CSV::Exporter->new(language => 'en');

	# Interleave the calls to show there is no shared, sticky state
	is($german->i18n('dry_run_title'), 'PROBELAUF', 'German from the environment');
	is($english->i18n('dry_run_title'), 'DRY RUN', 'English from the constructor');
	is($german->i18n('dry_run_title'), 'PROBELAUF', 'German again');
};

subtest 'OS error messages in each POSIX locale' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $missing = File::Spec->catfile($dir, 'missing.accdb');
	my $bad_log = File::Spec->catfile($dir, 'no', 'such', 'dir', 'x.log');
	my $original = setlocale(LC_ALL);

	foreach my $locale (@LOCALES) {
		subtest $locale => sub {
			# Not every system has every locale installed
			local $ENV{LC_ALL} = $locale;
			if(!defined setlocale(LC_ALL, $locale)) {
				plan(skip_all => "locale $locale is not installed");
			}

			# The OS text for "no such file", straight from Perl's $!
			my $enoent = do { local $! = ENOENT; "$!" };
			ok(length($enoent), "ENOENT text: $enoent");

			my $e = App::Access2CSV::Exporter->new(progress => 0);
			throws_ok { $e->run($missing) } qr/\QCannot read database $missing: $enoent\E/, 'missing database';

			my $status;
			my $stderr = do {
				local *STDERR;
				open STDERR, '>', \my $buffer or die $!;
				$status = App::Access2CSV->run('--log', $bad_log, $missing);
				$buffer;
			};
			is($status, 3, 'unopenable log is fatal');
			like($stderr, qr/\QCannot open log file $bad_log: $enoent\E/, 'log error carries the OS text');
		};
	}

	setlocale(LC_ALL, $original);
};

done_testing();
