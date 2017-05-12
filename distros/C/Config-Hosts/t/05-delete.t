#!perl

use strict;
use warnings;

use Test::More tests => 9;
use Config::Hosts;

my $hosts = Config::Hosts->new();
$hosts->read_hosts('t/hosts');
my $test_ip = '1.1.1.1';
my $test_host = 'test-host';
my $test_hosts = [ 'test', 'test.localdomain' ];
$hosts->insert_host(
	ip => $test_ip,
	hosts => $test_hosts
);
$hosts->delete_host($test_ip);
my $res = $hosts->query_host('1.1.1.1');
is($res, undef, "ip deleted by ip");
foreach my $host (@{$test_hosts}) {
	$res = $hosts->query_host($host);
	is($res, undef, "host deleted by ip");
}
foreach my $host (@{$test_hosts}) {
	$hosts->insert_host(
		ip => $test_ip,
		hosts => $test_hosts,
	);
	$hosts->delete_host($host);
	foreach my $host (@{$test_hosts}) {
		$res = $hosts->query_host($host);
		is($res, undef, "$host host deleted by host");
	}
	$res = $hosts->query_host($test_ip);
	is($res, undef, "ip deleted by host");
}
