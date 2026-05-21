use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;

check_live_access();

subtest 'system info' => sub {
  my $docker = test_docker(
    'GET /info' => load_fixture('system_info'),
  );

  my $info = $docker->system->info;

  ok(defined $info->{Containers}, 'has Containers');
  ok(defined $info->{Images}, 'has Images');
  ok($info->{ServerVersion}, 'has ServerVersion');
  ok($info->{OperatingSystem}, 'has OperatingSystem');
  ok($info->{Architecture}, 'has Architecture');

  unless (is_live()) {
    is($info->{Containers}, 14, 'container count');
    is($info->{ContainersRunning}, 3, 'running containers');
    is($info->{ContainersPaused}, 1, 'paused containers');
    is($info->{ContainersStopped}, 10, 'stopped containers');
    is($info->{Images}, 25, 'image count');
    is($info->{Driver}, 'overlay2', 'storage driver');
    is($info->{Name}, 'test-host', 'hostname');
    is($info->{ServerVersion}, '27.4.1', 'server version');
    is($info->{OperatingSystem}, 'Debian GNU/Linux 12 (bookworm)', 'os');
    is($info->{Architecture}, 'x86_64', 'architecture');
    is($info->{NCPU}, 4, 'cpu count');
  }
};

subtest 'system version' => sub {
  my $docker = test_docker(
    'GET /version' => load_fixture('system_version'),
  );

  my $version = $docker->system->version;

  ok($version->{Version}, 'has Version');
  ok($version->{ApiVersion}, 'has ApiVersion');
  ok($version->{Os}, 'has Os');
  ok($version->{Arch}, 'has Arch');

  unless (is_live()) {
    is($version->{Version}, '27.4.1', 'docker version');
    is($version->{ApiVersion}, '1.47', 'api version');
    is($version->{MinAPIVersion}, '1.24', 'min api version');
    is($version->{Os}, 'linux', 'os');
    is($version->{Arch}, 'amd64', 'arch');
  }
};

subtest 'ping' => sub {
  my $docker = test_docker(
    'GET /_ping' => 'OK',
  );

  my $result = $docker->system->ping;
  is($result, 'OK', 'ping returns OK');
};

subtest 'system df' => sub {
  my $docker = test_docker(
    'GET /system/df' => {
      LayersSize => 1000000000,
      Images     => [
        { Id => 'sha256:abc', Size => 500000000, SharedSize => 200000000 },
      ],
      Containers => [
        { Id => 'abc123', SizeRw => 10000, SizeRootFs => 500000000 },
      ],
      Volumes => [
        { Name => 'my-data', UsageData => { Size => 100000000 } },
      ],
    },
  );

  my $df = $docker->system->df;

  ok(defined $df->{LayersSize}, 'has LayersSize');
  is(ref $df->{Images}, 'ARRAY', 'has Images array');
  is(ref $df->{Containers}, 'ARRAY', 'has Containers array');
  is(ref $df->{Volumes}, 'ARRAY', 'has Volumes array');

  unless (is_live()) {
    is($df->{LayersSize}, 1000000000, 'layers size');
    is(scalar @{$df->{Images}}, 1, 'one image');
    is(scalar @{$df->{Containers}}, 1, 'one container');
    is(scalar @{$df->{Volumes}}, 1, 'one volume');
  }
};

subtest 'events' => sub {
  my $docker = test_docker(
    'GET /events' => [
      {
        Type   => 'container',
        Action => 'start',
        Actor  => { ID => 'abc123' },
        time   => 1705300000,
      },
    ],
  );

  my $events = $docker->system->events(since => 1705290000, until => 1705310000);

  is(ref $events, 'ARRAY', 'events is array');

  unless (is_live()) {
    is($events->[0]{Type}, 'container', 'event type');
    is($events->[0]{Action}, 'start', 'event action');
  }
};

done_testing;
