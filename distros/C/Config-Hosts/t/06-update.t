#!perl

use strict;
use warnings;

use Test::More tests => 21;
use Config::Hosts;

my $hosts = Config::Hosts->new();
$hosts->read_hosts('t/hosts');
my $test_ip = '1.1.1.1';
my $test_hosts = [ 'test', 'test.localdomain' ];
my $updated_hosts = [ 'update', 'update.localdomain' ];
my $updated_ip = '2.2.2.2';
$hosts->insert_host(
	ip => $test_ip,
	hosts => $test_hosts
);
my $res;
$hosts->update_host(
	$test_ip,
	hosts => $updated_hosts,
);
$res = $hosts->query_host($test_ip);
isa_ok($res, 'HASH', "ip preserved");
foreach my $host (@{$test_hosts}) {
	$res = $hosts->query_host($host);
	is($res, undef, "host updated by ip");
}
foreach my $host (@{$updated_hosts}) {
	$res = $hosts->query_host($host);
	isa_ok($res, 'HASH', "new hosts registered");
}
$hosts->update_host(
	$updated_hosts->[0],
	ip => $updated_ip,
);
$res = $hosts->query_host($test_ip);
is($res, undef, "ip updated");
$res = $hosts->query_host($updated_ip);
isa_ok($res, 'HASH', "ip updated");
foreach my $host (@{$updated_hosts}) {
	$res = $hosts->query_host($host);
	isa_ok($res, 'HASH', "hosts preserved");
}
$hosts->update_host(
	$updated_hosts->[0],
	ip => $test_ip,
	hosts => $test_hosts,
);
$res = $hosts->query_host($updated_ip);
is($res, undef, "ip updated");
$res = $hosts->query_host($test_ip);
isa_ok($res, 'HASH', "ip updated");
foreach my $host (@{$test_hosts}) {
	$res = $hosts->query_host($host);
	isa_ok($res, 'HASH', "hosts preserved");
}
foreach my $host (@{$updated_hosts}) {
	$res = $hosts->query_host($host);
	is($res, undef, "host updated by ip");
}
$hosts->update_host(
	$test_ip,
	ip => $updated_ip,
	hosts => $updated_hosts,
);
$res = $hosts->query_host($test_ip);
is($res, undef, "ip updated");
$res = $hosts->query_host($updated_ip);
isa_ok($res, 'HASH', "ip updated");
foreach my $host (@{$updated_hosts}) {
	$res = $hosts->query_host($host);
	isa_ok($res, 'HASH', "hosts preserved");
}
foreach my $host (@{$test_hosts}) {
	$res = $hosts->query_host($host);
	is($res, undef, "host updated by ip");
}

