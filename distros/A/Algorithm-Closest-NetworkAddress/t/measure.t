use Test::More;
use Algorithm::Closest::NetworkAddress;

my @tests = (
	[qw(ops1.der.altinity ops2.der.altinity 2)],
	[qw(ops1.der.altinity ops2.lon.altinity 1)],
	[qw(ops1.der.altinity altinity.com 0)],
	[qw(ops1.der.altinity host.ops1.der.altinity 3)],
	[qw(ops1.der.altinity ops1.lon.altinity 1)],
	[qw(alpha.beta.gamma.delta zeta.beta.gamma.delta 3)],
	[qw(alpha.beta.gamma.delta ops2.der.altinity.com 0)],
	[qw(10.20.30.40 10.20.30.41 3)],
	[qw(10.20.30.40 10.40.30.40 1)],
	[qw(10.20.30.40 11.20.30.40 0)],
	[qw(ops1.der.altinity 10.20.30.40 0)],
	);

my $o = Algorithm::Closest::NetworkAddress->new;

plan tests => scalar @tests;

foreach my $test (@tests) {
	my ($a, $b, $expected) = @$test;
	my $res = $o->measure($a, $b);
	is( $res, $expected, "$a => $b should return $expected");
}
