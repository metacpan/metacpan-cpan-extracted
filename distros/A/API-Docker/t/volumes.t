#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;

check_live_access();

# --- Read Tests (always run) ---

# volumes_list (karr k101 follow-up): a real capture, taken 2026-08-29
# against Docker 29.7.2 (API 1.55) from a disposable
# apidocker-fixture-probe-<random> volume created for the purpose and
# removed again once captured (filtered to that one volume so the fixture
# stays small and deterministic) -- see the header of
# t/type_fixture_passthrough.t.
subtest 'list volumes' => sub {
  my $docker = test_docker(
    'GET /volumes' => load_fixture('volumes_list'),
  );

  my $volumes = $docker->volumes->list;

  is(ref $volumes, 'ARRAY', 'returns array');
  if (@$volumes) {
    isa_ok($volumes->[0], 'API::Docker::Type::Volume');
    ok($volumes->[0]->name, 'has name');
  }

  unless (is_live()) {
    is(scalar @$volumes, 1, 'one volume');

    my $first = $volumes->[0];
    is($first->name, 'apidocker-fixture-probe-39a25e34', 'volume name');
    is($first->driver, 'local', 'volume driver');
    is($first->scope, 'local', 'volume scope');
    is_deeply($first->labels, { 'apidocker-fixture-probe' => '1' },
      'volume labels');
    like($first->mountpoint,
      qr{/var/lib/docker/volumes/apidocker-fixture-probe-39a25e34}, 'mountpoint');
  }
};

# --- Write Tests (mock always, live only with WRITE) ---

subtest 'volume lifecycle' => sub {
  skip_unless_write();

  my $docker = test_docker(
    'POST /volumes/create' => sub {
      my ($method, $path, %opts) = @_;
      is_deeply($opts{body}, { Name => 'test-vol' }, 'the full create body reached the daemon')
        unless is_live();
      return {
        Name       => 'test-vol',
        Driver     => 'local',
        Mountpoint => '/var/lib/docker/volumes/test-vol/_data',
        CreatedAt  => '2025-01-15T12:00:00Z',
        Labels     => {},
        Scope      => 'local',
        Options    => {},
      };
    },
    'GET /volumes/test-vol' => {
      Name       => 'test-vol',
      Driver     => 'local',
      Mountpoint => '/var/lib/docker/volumes/test-vol/_data',
      CreatedAt  => '2025-01-10T08:00:00Z',
      Labels     => {},
      Scope      => 'local',
      Options    => {},
    },
    'DELETE /volumes/test-vol' => undef,
  );

  my $name = is_live() ? 'api-docker-test-vol-' . $$ : 'test-vol';
  my $volume = $docker->volumes->create(Name => $name);
  isa_ok($volume, 'API::Docker::Type::Volume');
  ok($volume->name, 'created volume has a name');

  register_cleanup(sub { eval { $docker->volumes->remove($name, force => 1) } }) if is_live();

  my $inspected = $docker->volumes->inspect($name);
  isa_ok($inspected, 'API::Docker::Type::Volume');
  is($inspected->driver, 'local', 'volume driver is local');

  $docker->volumes->remove($name);
  pass('volume removed');
};

# --- Validation Tests (always run, no Docker needed) ---

subtest 'volume name required' => sub {
  my $docker = test_docker();

  eval { $docker->volumes->inspect(undef) };
  like($@, qr/Volume name required/, 'croak on missing name for inspect');

  eval { $docker->volumes->remove(undef) };
  like($@, qr/Volume name required/, 'croak on missing name for remove');
};

subtest 'prune sends its filters and returns the daemon response' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();

  my $params;
  my $docker = test_docker(
    'POST /volumes/prune' => sub {
      my ($method, $path, %opts) = @_;
      $params = $opts{params};
      return { VolumesDeleted => ['unused-vol'], SpaceReclaimed => 42 };
    },
  );

  my $result = $docker->volumes->prune(filters => { label => ['stage=build'] });
  is_deeply($result, { VolumesDeleted => ['unused-vol'], SpaceReclaimed => 42 },
    'the daemon response is returned unwrapped');
  is_deeply($params->{filters}, { label => ['stage=build'] },
    'the filters reached the query string, shape-normalised');
};

done_testing;
