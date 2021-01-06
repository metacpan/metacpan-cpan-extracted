#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use DNS::Hetzner;

my $dns = DNS::Hetzner->new(
    token => $ENV{HETZNER_DNS_TOKEN} // '123536',
);

isa_ok $dns, 'DNS::Hetzner';
is $dns->token, $ENV{HETZNER_DNS_TOKEN} // '123536';

my $zones = $dns->zones;
isa_ok $zones, 'DNS::Hetzner::API::Zones';

my $records = $dns->records;
isa_ok $records, 'DNS::Hetzner::API::Records';

done_testing();
