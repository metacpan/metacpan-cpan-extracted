#!/usr/bin/env perl

# t/geoip.t -- country() against a real legacy MaxMind GeoIP.dat database.
#
# t/integration.t covers the Geo::IP code path with a mocked lookup; this file
# exercises the real module and database file, so it is skipped unless both are
# present.  The database is found in the same places _load_geoip() looks
# (/usr/share/GeoIP/GeoIP.dat, /usr/local/share/GeoIP/GeoIP.dat), or can be
# given explicitly with GEOIP_DAT=/path/to/GeoIP.dat.  On Debian/Ubuntu,
# "apt install geoip-database" provides one.
#
# Legacy GeoIP.dat files are frozen (Debian's is dated 2019-12-24) and some
# allocations have moved since -- e.g. 45.128.139.41 is 'GP' in that file but
# GB today -- so country() is compared with Geo::IP's own answer rather than
# with ground truth, plus a few long-standing allocations that are unlikely
# to change.
#
# No network I/O: IP::Country and Geo::IPfree are disabled on each object, and
# geoplugin / Whois are mocked out in case the database has no entry.

use strict;
use warnings;

use Test::Most;
use Test::Needs 'Geo::IP';
use Test::Mockingbird;

use CGI::Lingua;

my ($dat) = grep { defined && -r } (
	$ENV{GEOIP_DAT},
	'/usr/share/GeoIP/GeoIP.dat',
	'/usr/local/share/GeoIP/GeoIP.dat',
);
plan(skip_all => 'No GeoIP.dat database found (set GEOIP_DAT to use one)') unless $dat;

my $geoip = Geo::IP->open($dat, 0)
	or plan(skip_all => "Can't open $dat");

# Pre-require before mocking so a later lazy require can't clobber the mock
my $HAS_LWP = eval { require LWP::Simple::WithCache; 1 } ? 1 : 0;
Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef }) if $HAS_LWP;

# Long-standing allocations: Google DNS, RIPE NCC, University of Tokyo
my %STABLE = (
	'8.8.8.8'     => 'us',
	'193.0.6.139' => 'nl',
	'133.11.0.1'  => 'jp',
);

sub _country {
	my $ip = shift;

	local %ENV = (REMOTE_ADDR => $ip);
	my $l = CGI::Lingua->new(supported => ['en']);
	$l->{_have_ipcountry} = 0;
	$l->{_have_geoipfree} = 0;
	unless($dat eq '/usr/share/GeoIP/GeoIP.dat' || $dat eq '/usr/local/share/GeoIP/GeoIP.dat') {
		# GEOIP_DAT points elsewhere; _load_geoip() wouldn't find it
		$l->{_have_geoip} = 1;
		$l->{_geoip} = $geoip;
	}
	return ($l->country(), $l);
}

diag("Using $dat") if $ENV{TEST_VERBOSE};

for my $ip (sort keys %STABLE) {
	my $expected = $geoip->country_code_by_addr($ip);

	SKIP: {
		skip "$dat has no entry for $ip", 3 unless defined $expected;

		my ($cc, $l) = _country($ip);
		is($l->{_have_geoip}, 1, "$ip: Geo::IP was used");
		is($cc, lc $expected, "$ip: country() agrees with Geo::IP");
		is($cc, $STABLE{$ip}, "$ip: resolves to $STABLE{$ip}");
	}
}

done_testing();
