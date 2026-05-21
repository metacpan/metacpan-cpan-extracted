use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;

check_live_access();

subtest 'version info' => sub {
  my $docker = test_docker(
    'GET /version' => load_fixture('system_version'),
  );

  my $version = $docker->system->version;

  ok($version->{ApiVersion}, 'has ApiVersion');
  ok($version->{Version}, 'has Version');
  ok($version->{Os}, 'has Os');
  ok($version->{Arch}, 'has Arch');

  unless (is_live()) {
    is($version->{ApiVersion}, '1.47', 'ApiVersion correct');
    is($version->{Version}, '27.4.1', 'Version correct');
    is($version->{Os}, 'linux', 'Os correct');
    is($version->{Arch}, 'amd64', 'Arch correct');
    is($version->{GoVersion}, 'go1.22.10', 'GoVersion correct');
    is($version->{MinAPIVersion}, '1.24', 'MinAPIVersion correct');
  }
};

subtest 'explicit version skips negotiation' => sub {
  my $docker = API::Docker->new(api_version => '1.45');
  is($docker->api_version, '1.45', 'explicit version preserved');
};

subtest 'auto-negotiate version' => sub {
  if (is_live()) {
    my $docker = API::Docker->new(host => $ENV{API_DOCKER_TEST_HOST});
    $docker->negotiate_version;
    ok(defined $docker->api_version, 'api_version negotiated');
    like($docker->api_version, qr/^\d+\.\d+$/, 'version looks valid');
  } else {
    my $docker = test_docker(
      'GET /version' => load_fixture('system_version'),
    );
    is($docker->api_version, '1.47', 'api_version matches fixture');
  }
};

done_testing;
