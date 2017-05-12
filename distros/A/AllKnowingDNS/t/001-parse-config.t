#!perl
# vim:ts=4:sw=4:expandtab
#
# Verify that the parser correctly turns plain text fragments into
# App::AllKnowingDNS::Zone objects with correct properties.

use Test::More;
use Data::Dumper;
use strict;
use warnings;
use lib qw(lib);

use_ok('App::AllKnowingDNS::Config');
use_ok('App::AllKnowingDNS::Zone');
use_ok('App::AllKnowingDNS::Util');

my $input;
my $config;

$config = App::AllKnowingDNS::Util::parse_config('');
ok(!$config->has_zones, 'Empty config leads to no zones');

$config = App::AllKnowingDNS::Util::parse_config('# meh');
ok(!$config->has_zones, 'Config with comment leads to no zones');

$input = <<'EOT';
# RaumZeitLabor
network 2001:4d88:100e:ccc0::/64
	resolves to ipv6-%DIGITS%.nutzer.raumzeitlabor.de
	with upstream 2001:4d88:100e:1::2
EOT
$config = App::AllKnowingDNS::Util::parse_config($input);
is($config->count_zones, 1, 'Real config leads to one zone');
my ($zone) = $config->all_zones;
is($zone->network, '2001:4d88:100e:ccc0::/64', 'network ok');
is($zone->upstream_dns, '2001:4d88:100e:1::2', 'upstream dns ok');
is($zone->resolves_to, 'ipv6-%DIGITS%.nutzer.raumzeitlabor.de', 'resolves to ok');

$input = <<'EOT';
# RaumZeitLabor
network 2001:4d88:100e:ccc0::/64
	resolves to ipv6-%DIGITS%.nutzer.raumzeitlabor.de
	with upstream 2001:4d88:100e:1::2

# Chaostreff (spaces instead of tabs, uppercase keywords)
NETWORK 2001:4D88:100E:CD1::/64
        ReSoLvEs tO IPV6-%DIGITS%.treff.noname-ev.de
        WiTh UpStReAm 2001:4d88:100e:1::2
EOT
$config = App::AllKnowingDNS::Util::parse_config($input);
is($config->count_zones, 2, 'Real config leads to multiple zone');

my ($zone1, $zone2) = $config->all_zones;
is($zone1->network, '2001:4d88:100e:ccc0::/64', 'network ok');
is($zone1->upstream_dns, '2001:4d88:100e:1::2', 'upstream dns ok');
is($zone1->resolves_to, 'ipv6-%DIGITS%.nutzer.raumzeitlabor.de', 'resolves to ok');

is($zone2->network, '2001:4d88:100e:cd1::/64', 'network ok');
is($zone2->upstream_dns, '2001:4d88:100e:1::2', 'upstream dns ok');
is($zone2->resolves_to, 'IPV6-%DIGITS%.treff.noname-ev.de', 'resolves to ok');

$input = <<'EOT';
listen 2001:4d88:100e:1::3
listen 79.140.39.197
EOT
$config = App::AllKnowingDNS::Util::parse_config($input);
is($config->count_listen_addresses, 2, 'Real config has two listen addresses');
is_deeply([ $config->all_listen_addresses ], [
    '2001:4d88:100e:1::3',
    '79.140.39.197',
], 'Listen addresses properly parsed');

done_testing;
