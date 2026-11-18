#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('API::Docker');
use_ok('API::Docker::Role::HTTP');
use_ok('API::Docker::API::System');
use_ok('API::Docker::API::Containers');
use_ok('API::Docker::API::Images');
use_ok('API::Docker::API::Networks');
use_ok('API::Docker::API::Volumes');
use_ok('API::Docker::API::Exec');
use_ok('API::Docker::API::Distribution');
use_ok('API::Docker::API::Secrets');
use_ok('API::Docker::API::Configs');
use_ok('API::Docker::API::Plugins');
use_ok('API::Docker::Role::Entity');
use_ok('API::Docker::Role::Entity::Container');
use_ok('API::Docker::Role::Entity::Image');
use_ok('API::Docker::Role::Entity::Network');
use_ok('API::Docker::Role::Entity::Volume');
use_ok('API::Docker::Role::Entity::Plugin');
use_ok('API::Docker::Role::Entity::Secret');
use_ok('API::Docker::Role::Entity::Config');

# Test default construction. host resolves DOCKER_HOST before the socket path,
# so the socket default is only observable with that variable gone -- any
# machine pointing at rootless Podman has it set, and this test used to read it.
my $docker;
{
  delete local $ENV{DOCKER_HOST};
  $docker = API::Docker->new(api_version => '1.47');
}
isa_ok($docker, 'API::Docker');
is($docker->host, 'unix:///var/run/docker.sock', 'default host');

# The other half of that resolution, which nothing covered.
{
  local $ENV{DOCKER_HOST} = 'tcp://from-env:2375';
  is(
    API::Docker->new(api_version => '1.47')->host,
    'tcp://from-env:2375',
    'DOCKER_HOST outranks the socket default',
  );
}
is($docker->api_version, '1.47', 'api_version set');
is($docker->tls, 0, 'tls off by default');

# Test custom host
my $docker_tcp = API::Docker->new(
  host        => 'tcp://remote:2375',
  api_version => '1.47',
);
is($docker_tcp->host, 'tcp://remote:2375', 'custom host');

# Test API accessors exist
can_ok($docker, qw(
  system containers images networks volumes exec
  distribution secrets configs plugins
));

# Test API accessor types
isa_ok($docker->system, 'API::Docker::API::System');
isa_ok($docker->containers, 'API::Docker::API::Containers');
isa_ok($docker->images, 'API::Docker::API::Images');
isa_ok($docker->networks, 'API::Docker::API::Networks');
isa_ok($docker->volumes, 'API::Docker::API::Volumes');
isa_ok($docker->exec, 'API::Docker::API::Exec');
isa_ok($docker->distribution, 'API::Docker::API::Distribution');
isa_ok($docker->secrets, 'API::Docker::API::Secrets');
isa_ok($docker->configs, 'API::Docker::API::Configs');
isa_ok($docker->plugins, 'API::Docker::API::Plugins');

done_testing;
