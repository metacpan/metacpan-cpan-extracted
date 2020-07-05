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

#my $zones = $dns->zones->list;
#my $records = $dns->records->list;

done_testing();