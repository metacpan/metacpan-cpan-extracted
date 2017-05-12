use Test::More;
use Algorithm::Closest::NetworkAddress;

my $o = Algorithm::Closest::NetworkAddress->new;

my @network_addresses = qw(mon.der.altinity mon.lon.altinity mon.hub.altinity 10.20.30.40 10.22.33.44);
$o->network_address_list([@network_addresses]);

my @tests = (
	[qw(ops1.der.altinity mon.der.altinity)],
	[qw(ops2.der.altinity mon.der.altinity)],
	[qw(ops1.lon.altinity mon.lon.altinity)],
	[qw(excaliber.hub.altinity mon.hub.altinity)],
	[qw(ignored.altinity.com 0)],
	[qw(10.20.65.83 10.20.30.40)],
	[qw(11.98.98.98 0)],
	[qw(10.21.33.44 10.20.30.40)],
	[qw(10.22.30.40 10.22.33.44)],
	[qw(unknown.altinity mon.der.altinity)],
	);


plan tests => scalar @tests;

foreach my $test (@tests) {
	my ($a, $expected) = @$test;
	my $res = $o->compare($a);
	is( $res, $expected, "$a should return $expected");
}
