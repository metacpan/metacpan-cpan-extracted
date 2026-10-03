#!/usr/bin/env perl

# Locale-sensitive behaviour.
#
# 1. Geographic: the web viewer's country blacklist (VWF::Blacklist, which
#    feeds CGI::ACL) against real GeoIP lookups.
# 2. System: OS error strings embedded in App::Syslogd's messages under
#    different LC_ALL settings.  The expected text is always taken from
#    Perl's own "$!" (never POSIX::strerror), so the test cannot disagree
#    with the code about which C library string is used.

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib", "$Bin/../www/lib";

use Errno qw(ENOENT EADDRINUSE);
use File::Temp qw(tempdir);
use POSIX qw(setlocale LC_ALL);
use Test::Most;

use App::Syslogd;

# The geographic tests cover the web viewer, which is only in the git
# checkout (www/ is not in the CPAN distribution), and need a GeoIP
# database.  Without them only the system-locale tests run.
my $have_geo = eval {
	require VWF::Blacklist;
	require IP::Country::Fast;
	require CGI::ACL;
	1;
};

SKIP: {
	skip('GeoIP tests need www/ (git checkout only), IP::Country::Fast and CGI::ACL', 6) unless($have_geo);

	# Addresses whose country has been stable for many years.  If the bundled
	# database ever disagrees, every result below would be meaningless.
	my %KNOWN = (
		GB => '81.2.69.160',
		US => '8.8.8.8',
		FR => '193.51.224.1',
		DE => '194.25.2.129',
		CN => '202.106.0.20',
	);

	my $geo = IP::Country::Fast->new();

	# Map a country back to its known address's GeoIP result
	my $country_of = sub { return $geo->inet_atocc($KNOWN{$_[0]}) };

	subtest 'GeoIP sanity' => sub {
		foreach my $cc (sort keys %KNOWN) {
			my $got = $country_of->($cc) // 'undef';
			is($got, $cc, "$KNOWN{$cc} maps to $cc")
				or BAIL_OUT("GeoIP drift: $KNOWN{$cc} is now $got, not $cc; update %KNOWN");
		}
	};

	subtest 'default blacklist: country-based access' => sub {
		my $bl = VWF::Blacklist->new();

		foreach my $cc (qw(GB US FR DE)) {
			ok(!$bl->is_blocked($country_of->($cc)), "$cc allowed");
		}
		ok($bl->is_blocked($country_of->('CN')), 'CN blocked');
		ok(!$bl->is_blocked(undef), 'unknown country (GeoIP miss) allowed');
		ok(!$bl->is_blocked(''), 'empty country allowed');
	};

	subtest 'case-insensitivity' => sub {
		my $bl = VWF::Blacklist->new(countries => 'fr, De');

		foreach my $cc (qw(FR fr Fr DE de dE)) {
			ok($bl->is_blocked($cc), "$cc blocked");
		}
		ok(!$bl->is_blocked('gb'), 'gb allowed');
		is_deeply($bl->countries(), ['DE', 'FR'], 'stored upper-case');
	};

	subtest 'concurrent instances do not interfere' => sub {
		my $us_only = VWF::Blacklist->new(countries => ['US']);
		my $gb_cn = VWF::Blacklist->new(countries => [qw(GB CN)]);
		my $empty = VWF::Blacklist->new(countries => []);

		my %expect = (
			GB => [0, 1, 0],
			US => [1, 0, 0],
			FR => [0, 0, 0],
			DE => [0, 0, 0],
			CN => [0, 1, 0],
		);
		foreach my $cc (sort keys %expect) {
			my $country = $country_of->($cc);
			is_deeply(
				[map { $_->is_blocked($country) } ($us_only, $gb_cn, $empty)],
				$expect{$cc},
				"$cc: each instance answers from its own list",
			);
		}
	};

	subtest 'CGI::ACL integration (as page.fcgi uses it)' => sub {
		# A stand-in for CGI::Lingua, which would do the same GeoIP lookup
		{
			package StubLingua;
			sub new { return bless { country => $_[1] }, $_[0] }
			sub country { return $_[0]{country} }
		}

		my $acl = CGI::ACL->new()->deny_country(country => VWF::Blacklist->new()->countries());
		foreach my $cc (sort keys %KNOWN) {
			local $ENV{REMOTE_ADDR} = $KNOWN{$cc};
			my $denied = $acl->all_denied(lingua => StubLingua->new(lc $country_of->($cc))) ? 1 : 0;
			is($denied, ($cc eq 'CN') ? 1 : 0, "$cc " . ($denied ? 'denied' : 'allowed'));
		}
	};

	subtest 'invalid configuration is rejected' => sub {
		throws_ok { VWF::Blacklist->new(countries => ['GBR']) } qr/Invalid country code 'GBR'/, 'three letters';
		throws_ok { VWF::Blacklist->new(countries => 'C1') } qr/Invalid country code 'C1'/, 'digit';
	};
}

# ---------------------------------------------------------------------------
# System locales
# ---------------------------------------------------------------------------

my $dir = tempdir(CLEANUP => 1);
my $original = setlocale(LC_ALL);

foreach my $locale ('en_US.UTF-8', 'de_DE.UTF-8', 'ja_JP.UTF-8') {
	subtest "OS errors under LC_ALL=$locale" => sub {
		local $ENV{LC_ALL} = $locale;
		my $installed = defined(setlocale(LC_ALL, $locale));
		note($installed ? "$locale is installed" : "$locale is not installed; the C library will use C messages");

		# Missing directory: ENOENT from sysopen
		my $enoent = do { local $! = ENOENT; "$!" };
		my $missing = "$dir/no/such/dir/log.csv";
		throws_ok { App::Syslogd->new(file => $missing)->reopen_log() }
			qr/\A\QCould not open log file $missing: $enoent\E/, "ENOENT: '$enoent'";

		# Port in use: EADDRINUSE from bind
		my $in_use = do { local $! = EADDRINUSE; "$!" };
		my $first = App::Syslogd->new(port => 0, address => '127.0.0.1')->open_socket();
		my $port = $first->port();
		throws_ok { App::Syslogd->new(port => $port, address => '127.0.0.1')->open_socket() }
			qr/\QCould not create a UDP socket on 127.0.0.1 port $port\E.*\Q$in_use\E/, "EADDRINUSE: '$in_use'";

		# Our own text falls back to English: no de or ja lexicon ships
		like(App::Syslogd->new()->i18n('shutdown', { count => 2 }), qr/2 messages/, 'catalogue falls back to English');
	};
}

setlocale(LC_ALL, $original);

done_testing();
