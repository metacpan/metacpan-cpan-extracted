#!perl -T
use lib qw(t/lib);
use DBICTest;
use Test::More tests => 10;
use NetAddr::IP;

my $schema = DBICTest->init_schema();

my $host_rs = $schema->resultset('Host');

my $localhost = $host_rs->find('localhost');

isa_ok($localhost->address, 'NetAddr::IP', 'numeric address inflated to right class');
is($localhost->address, '127.0.0.1/32', 'numeric address correctly inflated');

SKIP: {
    skip "DBIx::Class doesn't support find by object yet" => 1;

    $localhost = $host_rs->find(NetAddr::IP->new('127.0.0.1'), { key => 'address' });

    ok($localhost, 'find by object returned a row');
}

SKIP: {
    skip 'no object to check' => 1 unless $localhost;

    is($localhost->hostname, 'localhost', 'find by object returned the right row');
}

my $ip = NetAddr::IP->new('192.168.0.1');
my $host = $host_rs->create({ hostname => 'foo', address => $ip });

isa_ok($host, 'DBICTest::Schema::Host', 'create with object');
is($host->get_column('address'), $ip->numeric, 'numeric address correctly deflated');

my $net_rs = $schema->resultset('Network');

my $localnet = $net_rs->find('localnet');

isa_ok($localnet->address, 'NetAddr::IP', 'CIDR address inflated to right class');
is($localnet->address, '127.0.0.0/8', 'CIDR address correctly inflated');

my $net_ip = NetAddr::IP->new('192.168.0.42/24');
my $net = $net_rs->create({ netname => 'foo', address => $net_ip });

isa_ok($net, 'DBICTest::Schema::Network', 'create with object');
is($net->get_column('address'), '192.168.0.42/24', 'CIDR address correctly deflated');
