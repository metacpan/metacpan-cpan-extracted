#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use JSON::MaybeXS qw( decode_json );
use API::Docker;
use Test::API::Docker::FakeTransport;
use Test::API::Docker::Mock;

# GET /distribution/{name}/json -- asking a registry for an image manifest
# without pulling it (karr k15).
#
# Nothing here opens a socket or reaches a daemon, and nothing is gated on
# is_live() except the one subtest that says so. Test::API::Docker::Mock is
# deliberately not used for the bulk of this file: under API_DOCKER_TEST_HOST
# it ignores its route table and returns a real client, and the only engine
# reachable here is Podman, which serves no route for this endpoint at all --
# measured, rootless Podman 5.4.2 (API 1.41):
#
#   GET /v1.41/distribution/nginx:latest/json
#   -> 404 {"cause":"","message":"Path /v1.41/distribution/nginx:latest/json
#           is not supported","response":0}
#
# and the same for a bare name and for a percent-escaped reference. That
# version number just echoes the requested path prefix, not a fixed daemon
# constant -- re-measured live on 5.8.4 / API 1.44 the same request gets
# "/v1.44/distribution/..." back instead (karr k62). $PODMAN_404 below reads
# "/v1.41/..." because fake_client() always negotiates api_version 1.41; no
# assertion matches the number either way, only qr/is not supported/. So the
# daemon is faked below the socket instead, and the real _request runs. The
# success payload is the Engine API reference's own example descriptor.
#
# The one exception is the karr k38 subtest near the end, which drives the
# same ->exists 404-handling through Mock's route table instead of the real
# transport, now that Mock honours a >= 400 mock_response the way _request
# does. It is skipped live for the same reason as the rest of this file would
# be if it used Mock: no engine reachable here serves the route to check it
# against.

my $DESCRIPTOR = <<'JSON';
{"Descriptor":{"MediaType":"application/vnd.docker.distribution.manifest.v2+json","digest":"sha256:c0537ff6a5218ef531ece93d4984efc99bbf3f7497c0a7726c88e2bb7584dc96","size":3987},"Platforms":[{"architecture":"amd64","os":"linux"}]}
JSON

sub fake_client {
  my ($body, $status) = @_;
  return Test::API::Docker::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    canned      => [$status // 200, 'Not Found', {}, $body // $DESCRIPTOR],
  );
}

sub request_line {
  my ($raw) = @_;
  my ($line) = $raw =~ /\A([^\r\n]*)/;
  return $line;
}

# The two 404s this endpoint can give. Only the message tells them apart.
my $REGISTRY_404 = '{"message":"manifest unknown"}';
my $PODMAN_404   = '{"cause":"","message":"Path /v1.41/distribution/'
  . 'nginx:latest/json is not supported","response":0}';
my $DOCKER_404   = '{"message":"page not found"}';

# ---------------------------------------------------------------------------
subtest 'the reference keeps its slashes and its tag in the path' => sub {
  # Percent-encoding them breaks the reference: the daemon parses the path
  # segment as a docker reference, and %2F is not a repository separator.
  my $c = fake_client();
  $c->distribution->inspect('myrepo/app:1.0');
  is request_line($c->written),
    'GET /v1.41/distribution/myrepo/app:1.0/json HTTP/1.1',
    'slashes and the colon survive into the request line';

  my $plain = fake_client();
  $plain->distribution->inspect('nginx:latest');
  is request_line($plain->written),
    'GET /v1.41/distribution/nginx:latest/json HTTP/1.1',
    'and so does a plain library reference';

  ok !eval { fake_client()->distribution->inspect; 1 },
    'no reference croaks';
  like $@, qr/image reference/, 'and says what was missing';
};

# ---------------------------------------------------------------------------
subtest 'inspect returns the descriptor as the engine gave it' => sub {
  my $c = fake_client();
  my $d = $c->distribution->inspect('nginx:latest');

  is_deeply $d, decode_json($DESCRIPTOR),
    'the decoded response, not an entity object -- there is no '
    . 'API::Docker::Distribution class to wrap it in';
  is $d->{Descriptor}{size}, 3987, 'the descriptor is reachable';
};

# ---------------------------------------------------------------------------
subtest 'inspect croaks on 404, like every other endpoint method' => sub {
  my $c = fake_client($REGISTRY_404, 404);
  my %res;
  ok !eval { $c->distribution->inspect('nginx:latest', response => \%res); 1 },
    'a reference the registry does not have croaks';
  like $@, qr/manifest unknown/, 'with the registry message';
  is $res{status}, 404,
    'and response is filled before the croak, so an eval-ing caller reaches '
    . 'the status';
};

# ---------------------------------------------------------------------------
subtest 'exists answers the question without an eval' => sub {
  my $yes = fake_client();
  is $yes->distribution->exists('nginx:latest'), 1, '200 is yes';

  my $no = fake_client($REGISTRY_404, 404);
  ok !$no->distribution->exists('nginx:latest'),
    'the registry saying 404 is no, not an exception';

  # The property the whole predicate exists for. Podman has no route, so a
  # naive "404 means no" would answer no for every image there is --
  # which is the constant "no" the consumer's remote_tag_exists stub already
  # had, reintroduced one layer down where it looks like an answer.
  my $unsupported = fake_client($PODMAN_404, 404);
  ok !eval { $unsupported->distribution->exists('nginx:latest'); 1 },
    'an engine with no such route croaks rather than answering no';
  like $@, qr/cannot ask this engine/, 'and says the engine could not ask';
  like $@, qr/is not supported/, 'quoting what the engine said';

  my $docker_404 = fake_client($DOCKER_404, 404);
  ok !eval { $docker_404->distribution->exists('nginx:latest'); 1 },
    "Docker's own unknown-route 404 croaks too";

  # Anything that is not a 404 is not this method's to interpret.
  my $boom = fake_client('{"message":"server error"}', 500);
  ok !eval { $boom->distribution->exists('nginx:latest'); 1 },
    'a 500 propagates';
  like $@, qr/server error/, 'unchanged';
};

# ---------------------------------------------------------------------------
subtest 'exists fills a response HashRef the caller passed through' => sub {
  # It uses one internally; a caller's own must not be shadowed by it.
  my $c = fake_client($REGISTRY_404, 404);
  my %res;
  ok !$c->distribution->exists('nginx:latest', response => \%res), 'no';
  is $res{status}, 404, 'the caller sees the status behind the answer';
};

# ---------------------------------------------------------------------------
# karr k38: before Mock honoured a >= 400 mock_response, a route table could
# not exercise ->exists's status-driven branching at all -- mock_response
# set the status but the mock returned $response->{data} unconditionally, so
# every mocked call looked like success. This is the same three outcomes as
# the FakeTransport subtests above, driven through the route table instead of
# the real transport.
subtest 'exists through a mocked route table (karr k38)' => sub {
  plan skip_all => 'fixture-only: no engine reachable from this repo serves '
    . '/distribution at all (see the file header)'
    if is_live();

  my $found = test_docker(
    'GET /distribution/nginx:latest/json' => decode_json($DESCRIPTOR),
  );
  is $found->distribution->exists('nginx:latest'), 1,
    'a mocked 200 is yes, through the route table';

  my $no = test_docker(
    'GET /distribution/nginx:latest/json' =>
      mock_response(status => 404, data => decode_json($REGISTRY_404)),
  );
  ok !$no->distribution->exists('nginx:latest'),
    'a mocked registry 404 is no, not an exception -- the mock croaks and '
    . '->exists catches it, same as it does over the real transport';

  my $unsupported = test_docker(
    'GET /distribution/nginx:latest/json' =>
      mock_response(status => 404, data => decode_json($PODMAN_404)),
  );
  ok !eval { $unsupported->distribution->exists('nginx:latest'); 1 },
    'a mocked "not supported" 404 still croaks rather than answering no';
  like $@, qr/cannot ask this engine/, 'same message as the transport-level '
    . 'test above';
  like $@, qr/is not supported/, 'quoting what the mocked engine said';

  my $boom = test_docker(
    'GET /distribution/nginx:latest/json' =>
      mock_response(status => 500, data => { message => 'server error' }),
  );
  ok !eval { $boom->distribution->exists('nginx:latest'); 1 },
    'a mocked 500 propagates too';
  my $err = $@;
  like $err, qr/server error/,
    'and carries the message the mock croak now extracts from the body';
  # karr k50: the mock raises the exception class as well, not only the text.
  # If it went back to croaking a plain string, every ->status assertion in
  # the suite would have to be gated on is_live() to keep passing.
  isa_ok $err, 'API::Docker::Error::HTTP';
  is $err->status, 500, 'with the status the mocked route answered';
  is $err->reason, 'Internal Server Error', 'and that status line\'s reason';
};

done_testing;
