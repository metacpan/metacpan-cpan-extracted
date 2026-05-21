use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;

check_live_access();

# --- Read Tests (always run) ---

subtest 'list networks' => sub {
  my $docker = test_docker(
    'GET /networks' => load_fixture('networks_list'),
  );

  my $networks = $docker->networks->list;

  is(ref $networks, 'ARRAY', 'returns array');
  if (@$networks) {
    isa_ok($networks->[0], 'API::Docker::Network');
    ok($networks->[0]->Name, 'has Name');
  }

  unless (is_live()) {
    is(scalar @$networks, 2, 'two networks');

    my $first = $networks->[0];
    is($first->Name, 'bridge', 'network name');
    is($first->Driver, 'bridge', 'network driver');
    is($first->Scope, 'local', 'network scope');
    ok(!$first->Internal, 'not internal');
  }
};

# --- Write Tests (mock always, live only with WRITE) ---

subtest 'network lifecycle' => sub {
  skip_unless_write();

  my $docker = test_docker(
    'POST /networks/create' => sub {
      my ($method, $path, %opts) = @_;
      is($opts{body}{Name}, 'test-net', 'network name in body') unless is_live();
      return { Id => 'mock-net-123', Warning => '' };
    },
    'GET /networks/mock-net-123'             => {
      Name   => 'test-net',
      Id     => 'mock-net-123',
      Driver => 'bridge',
      Scope  => 'local',
      Labels => {},
    },
    'POST /networks/mock-net-123/connect'    => undef,
    'POST /networks/mock-net-123/disconnect' => undef,
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
  isa_ok($network, 'API::Docker::Network');
  ok($network->Name, 'has Name');

  unless (is_live()) {
    $docker->networks->connect($id, Container => 'abc123');
    pass('connect completed');

    $docker->networks->disconnect($id, Container => 'abc123');
    pass('disconnect completed');
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

done_testing;
