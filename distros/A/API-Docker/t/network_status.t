#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;

# GET /networks/{id} answers a Status object that v1.51 does not have: the
# runtime IPAM usage of each subnet. Until it was typed, it arrived in
# unknown_fields. Captured 2026-10-25 (karr k112) from Docker Engine
# Community 29.8.0 (API 1.56): GET /networks/bridge, unmodified.

# The assertions are about the captured fixture; under API_DOCKER_TEST_HOST the
# mock route table is bypassed and an engine without Status (Podman) has none.
plan skip_all => 'fixture-only: mock route table is bypassed in live mode'
  if is_live();

my $docker = test_docker(
  'GET /networks/bridge' => load_fixture('network_inspect_status'),
);

my $net = $docker->networks->inspect('bridge');
isa_ok $net, 'API::Docker::Type::Network';

my $status = $net->status;
isa_ok $status, 'API::Docker::Type::NetworkStatus', 'status is typed';
my $subnet = $status->ipam->subnets->{'172.17.0.0/16'};
isa_ok $subnet, 'API::Docker::Type::SubnetStatus', 'each subnet';
is $subnet->ips_in_use, 3, 'IPsInUse reads as ips_in_use';
is $subnet->dynamic_ips_available, 65533,
  'DynamicIPsAvailable reads as dynamic_ips_available';

is_deeply $net->rejected_fields, {}, 'nothing was rejected';
ok !exists $net->unknown_fields->{Status},
  'and Status is no longer an unknown field';

done_testing;
