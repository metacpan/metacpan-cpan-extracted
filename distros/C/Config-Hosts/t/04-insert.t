#!perl

use strict;
use warnings;

use Test::More tests => 10;
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

my $res = $hosts->query_host($test_ip);
ok(ref $res && ref $res eq 'HASH', 'Queried inserted');
is_deeply(
	$res->{hosts},
	$test_hosts,
	'Test hosts inserted ok',
);
$res = $hosts->query_host($test_hosts->[0]);
ok(ref $res && ref $res eq 'HASH', 'Queried inserted');
is($res->{ip}, $test_ip, 'test ip inserted ok');
$res = $hosts->query_host($test_hosts->[1]);
ok(ref $res && ref $res eq 'HASH', 'Queried inserted');
is($res->{ip}, $test_ip, 'test ip inserted ok');
$hosts->insert_host(
	ip => $test_ip,
	hosts => $test_host
);
$res = $hosts->query_host($test_ip);
ok(ref $res && ref $res eq 'HASH', 'Queried inserted');
is_deeply(
	$res->{hosts},
	[ $test_host ],
	'Test hosts inserted ok',
);
$res = $hosts->query_host($test_host);
ok(ref $res && ref $res eq 'HASH', 'Queried inserted');
is($res->{ip}, $test_ip, 'test ip inserted ok');
