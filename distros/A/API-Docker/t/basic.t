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
use_ok('API::Docker::Container');
use_ok('API::Docker::Image');
use_ok('API::Docker::Network');
use_ok('API::Docker::Volume');

# Test default construction
my $docker = API::Docker->new(api_version => '1.47');
isa_ok($docker, 'API::Docker');
is($docker->host, 'unix:///var/run/docker.sock', 'default host');
is($docker->api_version, '1.47', 'api_version set');
is($docker->tls, 0, 'tls off by default');

# Test custom host
my $docker_tcp = API::Docker->new(
  host        => 'tcp://remote:2375',
  api_version => '1.47',
);
is($docker_tcp->host, 'tcp://remote:2375', 'custom host');

# Test API accessors exist
can_ok($docker, qw(system containers images networks volumes exec));

# Test API accessor types
isa_ok($docker->system, 'API::Docker::API::System');
isa_ok($docker->containers, 'API::Docker::API::Containers');
isa_ok($docker->images, 'API::Docker::API::Images');
isa_ok($docker->networks, 'API::Docker::API::Networks');
isa_ok($docker->volumes, 'API::Docker::API::Volumes');
isa_ok($docker->exec, 'API::Docker::API::Exec');

done_testing;
