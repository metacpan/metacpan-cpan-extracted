#!perl
# The geoip_country munger against MaxMind's GeoLite2-Country test database
# (t/mmdb/GeoLite2-Country-Test.mmdb). Skips when IP::Geolocation::MMDB is
# not installed -- the munger loads it lazily, so it is purely a test-time
# dependency here.
use 5.006;
use strict;
use warnings;
use Test::More;
use FindBin;

BEGIN {
	eval { require IP::Geolocation::MMDB; 1 }
		or plan skip_all => 'IP::Geolocation::MMDB not available';
}

use Algorithm::ToNumberMunger;
my $M = 'Algorithm::ToNumberMunger';

my $mmdb = "$FindBin::Bin/mmdb/GeoLite2-Country-Test.mmdb";

# The tests own this process's environment; clear the env override so only
# the sources each block sets are in play.
delete $ENV{TONUMBERMUNGER_GEOIP_MMDB};

# The emitted number is (letter1 * 26) + letter2 of the alpha-2 code, A = 0.
sub cc_num {
	my ( $a, $b ) = split //, uc $_[0];
	return ( ord($a) - 65 ) * 26 + ( ord($b) - 65 );
}

ok( $M->has_munger('geoip_country'), 'geoip_country is a known munger' );

# ---- build-time errors ------------------------------------------------------
{
	eval { $M->build( { munger => 'geoip_country', mmdb => "$mmdb.nope" } ) };
	like( $@, qr/does not exist/,     'build croaks on a nonexistent mmdb path' );
	like( $@, qr/'mmdb' in the spec/, 'the croak names the source of the bad path' );

	eval { $M->build( { munger => 'geoip_country', mmdb => "$FindBin::Bin/mmdb/README.md" } ) };
	like( $@, qr/could not open mmdb file/, 'build croaks on a file that is not a MaxMind db' );

	eval { $M->build( { munger => 'geoip_country', mmdb => $mmdb, default => 'x' } ) };
	like( $@, qr/'default' must be numeric/, 'build croaks on a non-numeric default' );

	local $ENV{TONUMBERMUNGER_GEOIP_MMDB} = "$mmdb.nope";
	eval { $M->build( { munger => 'geoip_country' } ) };
	like( $@, qr/TONUMBERMUNGER_GEOIP_MMDB env variable/, 'a bad env path croaks naming the env variable' );
}

# ---- database resolution order ----------------------------------------------
{
	# spec beats the env variable: a garbage env path must not even be looked at.
	local $ENV{TONUMBERMUNGER_GEOIP_MMDB} = "$mmdb.nope";
	my $c = eval { $M->build( { munger => 'geoip_country', mmdb => $mmdb } ) };
	ok( $c, 'spec mmdb wins over the env variable' );
	is( $c->('81.2.69.160'), cc_num('GB'), 'and the spec-resolved db answers' );
}
{
	# env variable alone resolves the db.
	local $ENV{TONUMBERMUNGER_GEOIP_MMDB} = $mmdb;
	my $c = eval { $M->build( { munger => 'geoip_country' } ) };
	ok( $c, 'the env variable alone resolves the db' );
	is( $c->('81.2.69.160'), cc_num('GB'), 'and the env-resolved db answers' );
}
{
	# env beats the package variable: package var pointing nowhere is not
	# consulted when the env variable names a good db.
	local $ENV{TONUMBERMUNGER_GEOIP_MMDB} = $mmdb;
	local $Algorithm::ToNumberMunger::GEOIP_COUNTRY_MMDB = "$mmdb.nope";
	my $c = eval { $M->build( { munger => 'geoip_country' } ) };
	ok( $c, 'the env variable wins over the package variable' );
}
{
	# package variable alone resolves the db.
	local $Algorithm::ToNumberMunger::GEOIP_COUNTRY_MMDB = $mmdb;
	my $c = eval { $M->build( { munger => 'geoip_country' } ) };
	ok( $c, 'the package variable alone resolves the db' );
	is( $c->('89.160.20.128'), cc_num('SE'), 'and the package-var-resolved db answers' );
}

SKIP: {
	# With no source naming a db, the build must croak -- unless this host
	# genuinely has one in a well-known geoipupdate location, in which case
	# that fallback (correctly) resolves and the croak cannot be observed.
	my $host_has_system_db = grep { -f "$_/GeoIP2-Country.mmdb" || -f "$_/GeoLite2-Country.mmdb" }
		qw(/var/db/GeoIP /var/lib/GeoIP /usr/share/GeoIP /usr/local/share/GeoIP);
	skip 'host has a system GeoIP db in a well-known path', 1 if $host_has_system_db;
	eval { $M->build( { munger => 'geoip_country' } ) };
	like( $@, qr/no mmdb database found/, 'build croaks when nothing names a db' );
} ## end SKIP:

# ---- lookups ----------------------------------------------------------------
{
	my $c = $M->build( { munger => 'geoip_country', mmdb => $mmdb } );
	is( $c->('2.125.160.216'),        cc_num('GB'), 'IPv4 in GB nets -> GB' );
	is( $c->('89.160.20.128'),        cc_num('SE'), 'IPv4 in SE nets -> SE' );
	is( $c->('217.65.48.1'),          cc_num('GI'), 'IPv4 in GI nets -> GI' );
	is( $c->('2001:218::'),           cc_num('JP'), 'IPv6 in JP nets -> JP' );
	is( $c->('::ffff:2.125.160.216'), cc_num('GB'), 'v4-mapped IPv6 -> the embedded v4 country' );

	# 67.43.156.0/24 is geolocated BT but registered RO in the test data;
	# country must win over registered_country.
	is( $c->('67.43.156.1'),   cc_num('BT'), 'geolocated country beats registered_country' );
	is( $c->('216.160.83.56'), cc_num('US'), 'US-geolocated, GB-registered net -> US' );
}

# ---- unresolvable inputs ----------------------------------------------------
{
	my $c = $M->build( { munger => 'geoip_country', mmdb => $mmdb } );
	eval { $c->('212.47.235.81') };
	like( $@, qr/resolves to no country/, 'an address not in the db croaks without default' );
	eval { $c->('10.0.0.1') };
	like( $@, qr/resolves to no country/, 'private space croaks without default' );
	eval { $c->('not-an-ip') };
	like( $@, qr/not a parseable IP address/, 'garbage croaks as unparseable' );
	eval { $c->(undef) };
	like( $@, qr/resolves to no country/, 'undef croaks without default' );

	my $d = $M->build( { munger => 'geoip_country', mmdb => $mmdb, default => -1 } );
	is( $d->('212.47.235.81'), -1,           'default for an address not in the db' );
	is( $d->('10.0.0.1'),      -1,           'default for private space' );
	is( $d->('not-an-ip'),     -1,           'default for garbage' );
	is( $d->(undef),           -1,           'default for undef' );
	is( $d->('89.160.20.128'), cc_num('SE'), 'default does not disturb a real lookup' );
}

# ---- through compile --------------------------------------------------------
{
	my $plan = $M->compile(
		tags    => [qw(src_country bytes)],
		mungers => {
			src_country => { munger => 'geoip_country', from => 'src_ip', mmdb => $mmdb, default => -1 },
		},
	);
	is_deeply(
		$plan->apply_named( { src_ip => '89.160.20.128', bytes => 42 } ),
		[ cc_num('SE'), 42 ],
		'geoip_country via compile with a from alias'
	);
	is_deeply(
		$plan->apply_named( { src_ip => '192.168.0.5', bytes => 7 } ),
		[ -1, 7 ],
		'internal address falls to the default via compile'
	);
}

done_testing();
