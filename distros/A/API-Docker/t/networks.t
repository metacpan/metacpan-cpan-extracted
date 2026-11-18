#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;

check_live_access();

# --- Read Tests (always run) ---

# Captured 2026-08-28 (karr k101) against Docker Engine Community 29.7.2
# (API 1.55): GET /networks on this host's real engine, unmodified -- three
# entries (none/host/bridge) because that is the whole list a fresh install
# starts with; none were created for this capture.
subtest 'list networks' => sub {
  my $docker = test_docker(
    'GET /networks' => load_fixture('networks_list'),
  );

  my $networks = $docker->networks->list;

  is(ref $networks, 'ARRAY', 'returns array');
  if (@$networks) {
    isa_ok($networks->[0], 'API::Docker::Type::Network');
    ok($networks->[0]->name, 'has name');
  }

  unless (is_live()) {
    is(scalar @$networks, 3, 'three networks');

    my ($bridge) = grep { $_->name eq 'bridge' } @$networks;
    ok $bridge, 'the bridge network is in the list';
    is($bridge->driver, 'bridge', 'network driver');
    is($bridge->scope, 'local', 'network scope');
    ok(!$bridge->internal, 'not internal');
    is($bridge->ipam->config->[0]->subnet, '172.17.0.0/16',
      'and IPAM is inflated into its own generated classes rather than '
      . 'staying the raw HashRef the old entity kept');
  }
};

# --- Write Tests (mock always, live only with WRITE) ---

subtest 'network lifecycle' => sub {
  skip_unless_write();

  my ($connect_body, $disconnect_body);
  my $docker = test_docker(
    'POST /networks/create' => sub {
      my ($method, $path, %opts) = @_;
      is_deeply($opts{body}, { Name => 'test-net', Driver => 'bridge' },
        'the full create body reached the daemon') unless is_live();
      return { Id => 'mock-net-123', Warning => '' };
    },
    'GET /networks/mock-net-123'             => {
      Name   => 'test-net',
      Id     => 'mock-net-123',
      Driver => 'bridge',
      Scope  => 'local',
      Labels => {},
    },
    'POST /networks/mock-net-123/connect'    => sub {
      my ($method, $path, %opts) = @_;
      $connect_body = $opts{body};
      return undef;
    },
    'POST /networks/mock-net-123/disconnect' => sub {
      my ($method, $path, %opts) = @_;
      $disconnect_body = $opts{body};
      return undef;
    },
    'DELETE /networks/mock-net-123'          => undef,
  );

  my $name = 'api-docker-test-net-' . $$;
  my $result = $docker->networks->create(
    Name   => is_live() ? $name : 'test-net',
    Driver => 'bridge',
  );
  ok($result->{Id}, 'created network has Id');
  my $id = is_live() ? $result->{Id} : 'mock-net-123';

  register_cleanup(sub { eval { $docker->networks->remove($id) } }) if is_live();

  my $network = $docker->networks->inspect($id);
  isa_ok($network, 'API::Docker::Type::Network');
  ok($network->name, 'has name');

  unless (is_live()) {
    $docker->networks->connect($id, Container => 'abc123');
    is_deeply($connect_body, { Container => 'abc123' },
      'connect posted the container id in the request body');

    $docker->networks->disconnect($id, Container => 'abc123', Force => 1);
    is_deeply($disconnect_body, { Container => 'abc123', Force => \1 },
      'disconnect posted its body too, with Force normalised to a JSON boolean');
  }

  $docker->networks->remove($id);
  pass('network removed');
};

# --- Validation Tests (always run, no Docker needed) ---

subtest 'network ID required' => sub {
  my $docker = test_docker();

  eval { $docker->networks->inspect(undef) };
  like($@, qr/Network ID required/, 'croak on missing ID for inspect');

  eval { $docker->networks->remove(undef) };
  like($@, qr/Network ID required/, 'croak on missing ID for remove');
};

subtest 'connect requires container' => sub {
  my $docker = test_docker();

  eval { $docker->networks->connect('net1') };
  like($@, qr/Container required/, 'croak on missing container for connect');
};

subtest 'prune sends its filters and returns the daemon response' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();

  my $params;
  my $docker = test_docker(
    'POST /networks/prune' => sub {
      my ($method, $path, %opts) = @_;
      $params = $opts{params};
      return { NetworksDeleted => ['unused-net'] };
    },
  );

  my $result = $docker->networks->prune(filters => { until => ['24h'] });
  is_deeply($result, { NetworksDeleted => ['unused-net'] },
    'the daemon response is returned unwrapped');
  is_deeply($params->{filters}, { until => ['24h'] },
    'the filters reached the query string, shape-normalised');
};

done_testing;
