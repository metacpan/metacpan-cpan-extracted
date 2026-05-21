use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;

check_live_access();

# --- Read Tests (always run) ---

subtest 'list containers' => sub {
  my $docker = test_docker(
    'GET /containers/json' => load_fixture('containers_list'),
  );

  my $containers = $docker->containers->list(all => 1);

  is(ref $containers, 'ARRAY', 'returns array');
  if (@$containers) {
    isa_ok($containers->[0], 'API::Docker::Container');
    ok($containers->[0]->Id, 'has Id');
  }

  unless (is_live()) {
    is(scalar @$containers, 2, 'two containers');

    my $first = $containers->[0];
    is($first->Id, 'abc123def456', 'container id');
    is_deeply($first->Names, ['/my-container'], 'container names');
    is($first->Image, 'nginx:latest', 'container image');
    is($first->State, 'running', 'container state');
    ok($first->is_running, 'is_running returns true for running container');

    my $second = $containers->[1];
    is($second->Id, 'def789ghi012', 'second container id');
    is($second->State, 'exited', 'second container state');
    ok(!$second->is_running, 'is_running returns false for exited container');
  }
};

# --- Write Tests (mock always, live only with WRITE) ---

subtest 'container lifecycle' => sub {
  skip_unless_write();

  my $docker = test_docker(
    'POST /containers/create'         => { Id => 'mock123', Warnings => [] },
    'POST /containers/mock123/start'  => undef,
    'GET /containers/mock123/json'    => load_fixture('container_inspect'),
    'GET /containers/mock123/top'     => {
      Titles    => ['UID', 'PID', 'PPID', 'C', 'STIME', 'TTY', 'TIME', 'CMD'],
      Processes => [
        ['root', '12345', '1', '0', '08:00', '?', '00:00:00', 'sleep'],
      ],
    },
    'GET /containers/mock123/stats'   => {
      cpu_stats    => { cpu_usage => { total_usage => 1000 } },
      memory_stats => { usage => 50000000 },
    },
    'POST /containers/mock123/pause'   => undef,
    'POST /containers/mock123/unpause' => undef,
    'POST /containers/mock123/stop'    => undef,
    'DELETE /containers/mock123'       => undef,
  );

  my $name = 'api-docker-test-' . $$;
  my $created = $docker->containers->create(
    name  => $name,
    Image => 'alpine:latest',
    Cmd   => ['sleep', '10'],
  );
  ok($created->{Id}, 'created container has Id');
  my $id = is_live() ? $created->{Id} : 'mock123';

  register_cleanup(sub { $docker->containers->remove($id, force => 1) }) if is_live();

  $docker->containers->start($id);
  pass('container started');

  my $container = $docker->containers->inspect($id);
  isa_ok($container, 'API::Docker::Container');
  ok($container->is_running, 'container is running');

  my $top = $docker->containers->top($id);
  is(ref $top->{Processes}, 'ARRAY', 'top has processes');

  my $stats = $docker->containers->stats($id);
  ok($stats->{cpu_stats}, 'has cpu_stats');
  ok($stats->{memory_stats}, 'has memory_stats');

  $docker->containers->pause($id);
  pass('container paused');
  $docker->containers->unpause($id);
  pass('container unpaused');

  $docker->containers->stop($id, timeout => 3);
  pass('container stopped');

  $docker->containers->remove($id);
  pass('container removed');
};

# --- Validation Tests (always run, no Docker needed) ---

subtest 'container ID required' => sub {
  my $docker = test_docker();

  eval { $docker->containers->inspect(undef) };
  like($@, qr/Container ID required/, 'croak on missing ID for inspect');

  eval { $docker->containers->start(undef) };
  like($@, qr/Container ID required/, 'croak on missing ID for start');

  eval { $docker->containers->stop(undef) };
  like($@, qr/Container ID required/, 'croak on missing ID for stop');
};

done_testing;
