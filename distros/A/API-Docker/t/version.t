#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;

check_live_access();

# Captured 2026-08-28 (karr k101) against Docker Engine Community 29.7.2
# (API 1.55): GET /version, unversioned as the client itself sends it,
# unmodified.
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
    is($version->{ApiVersion}, '1.55', 'ApiVersion correct');
    is($version->{Version}, '29.7.2', 'Version correct');
    is($version->{Os}, 'linux', 'Os correct');
    is($version->{Arch}, 'amd64', 'Arch correct');
    is($version->{GoVersion}, 'go1.26.5', 'GoVersion correct');
    is($version->{MinAPIVersion}, '1.40', 'MinAPIVersion correct');
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
    # Not a negotiation exercise in mock mode: _mock_docker pins
    # api_version at construction (see t/lib/Test/API/Docker/Mock.pm),
    # which is exactly what makes negotiate_version's own guard skip it, so
    # this route is never actually consulted for the client's api_version.
    # What this checks is that the mock's fixed default and the fixture's
    # real ApiVersion stay coordinated, deliberately, rather than agreeing
    # by coincidence the way '1.47' on both sides used to.
    my $docker = test_docker(
      'GET /version' => load_fixture('system_version'),
    );
    is($docker->api_version, '1.55',
      "mock client's fixed api_version matches the system_version fixture");
  }
};

# negotiate_version reads GET /version and puts its ApiVersion straight into
# every later request path (/v1.44/...). A body that is not a JSON object
# carrying an ApiVersion of the form N.N used to fail in three measured ways
# against a fake daemon: a non-object body died deep in strict refs ('garbage'
# -> "Can't use string as a HASH ref", [1] -> "Not a HASH reference"); an
# object with no ApiVersion silently left the client sending every request
# unversioned; and an ApiVersion copied verbatim let 'v1.44/../x' become
# GET /vv1.44/../x/info. All four now croak, naming the endpoint and the shape.
{
  package Test::Version::Canned;
  use Moo;
  extends 'API::Docker';
  has canned => (is => 'ro');
  sub _request { return $_[0]->canned }
}

sub negotiate_with {
  my ($canned) = @_;
  my $c = Test::Version::Canned->new(
    host   => 'unix:///nonexistent.sock',
    canned => $canned,
  );
  my $ok = eval { $c->negotiate_version; 1 };
  return ($ok ? undef : $@, $c);
}

subtest 'a /version body that is not a versioned object croaks' => sub {
  return plan skip_all => 'not a negotiation exercise against a live daemon'
    if is_live();

  for my $case (
    [ 'a bare string',            'garbage',                  qr/HASH ref|strict refs/ ],
    [ 'an array reference',       [1],                        qr/Not a HASH reference/ ],
    [ 'undef',                    undef,                      undef ],
    [ 'an object with no ApiVersion', { Version => '29.7.2' }, undef ],
    [ 'an ApiVersion that is not N.N', { ApiVersion => 'v1.44/../x' }, undef ],
  ) {
    my ($label, $body, $old_pattern) = @$case;
    my ($err) = negotiate_with($body);
    ok $err, "$label: negotiate_version croaks rather than proceeding";
    like $err, qr{GET /version}, "$label: the message names the endpoint";
    like $err, qr/ApiVersion/, "$label: and the shape it expected";
    unlike $err, $old_pattern, "$label: not the old strict-refs death"
      if defined $old_pattern;
  }
};

subtest 'a well-formed /version body negotiates as before' => sub {
  return plan skip_all => 'pinned api_version short-circuits under live'
    if is_live();

  my ($err, $c) = negotiate_with({ ApiVersion => '1.44' });
  is $err, undef, 'a JSON object with an N.N ApiVersion raises nothing'
    or diag "raised: $err";
  is $c->api_version, '1.44', 'and the version is adopted';
};

done_testing;
