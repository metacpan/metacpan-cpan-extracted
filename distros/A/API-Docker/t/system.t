#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;

check_live_access();

# Captured 2026-08-28 (karr k101) against Docker Engine Community 29.7.2
# (API 1.55): GET /info on this host's real engine. The one edit is the
# "Name" field (the daemon's hostname), redacted to "docker-host" so a real
# machine name does not ship in the tarball; every other value is verbatim.
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
    is($info->{Containers}, 0, 'container count');
    is($info->{ContainersRunning}, 0, 'running containers');
    is($info->{ContainersPaused}, 0, 'paused containers');
    is($info->{ContainersStopped}, 0, 'stopped containers');
    is($info->{Images}, 2, 'image count');
    is($info->{Driver}, 'overlayfs', 'storage driver');
    is($info->{Name}, 'docker-host', 'hostname');
    is($info->{ServerVersion}, '29.7.2', 'server version');
    is($info->{OperatingSystem}, 'Debian GNU/Linux 13 (trixie)', 'os');
    is($info->{Architecture}, 'x86_64', 'architecture');
    is($info->{NCPU}, 4, 'cpu count');
  }
};

# Captured 2026-08-28 (karr k101) against Docker Engine Community 29.7.2
# (API 1.55): GET /version, unversioned as the client itself sends it,
# unmodified.
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
    is($version->{Version}, '29.7.2', 'docker version');
    is($version->{ApiVersion}, '1.55', 'api version');
    is($version->{MinAPIVersion}, '1.40', 'min api version');
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

  if (is_live()) {
    # A real daemon may legitimately have no events in the requested
    # window, in which case the body is empty and _request's ndjson
    # branch returns [] for it, not undef -- the assertion below still
    # tolerates undef too, a shape this call no longer produces.
    ok(!defined($events) || ref($events) eq 'ARRAY',
      'events is array or undef (empty window is a valid live response)');
  }
  else {
    is(ref $events, 'ARRAY', 'events is array');
    is($events->[0]{Type}, 'container', 'event type');
    is($events->[0]{Action}, 'start', 'event action');
  }
};

done_testing;
