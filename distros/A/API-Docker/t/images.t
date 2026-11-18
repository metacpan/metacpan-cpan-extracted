#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;
use JSON::MaybeXS qw( decode_json );
# The role, not the type class: it is what composes the entity methods onto
# the generated classes, and constructing one before that has happened inlines
# its constructor and makes the composition impossible ("has been inlined and
# cannot be updated"). Loading API::Docker gets there too, through
# API::Docker::API::Images -- but the first subtest below builds an
# ImageSummary before any client exists.
use API::Docker::Role::Entity::Image;

# The engine's build stream, as captured from a real daemon. build/pull/push
# hand the caller one event per line, always as an ArrayRef.
sub build_events {
  my $body = load_fixture_raw('images_build_stream.ndjson');
  return [ map { decode_json($_) } grep { /\S/ } split /\n/, $body ];
}

# Live picks a name out of whatever `list` handed back. repo_tags on an
# untagged image is `[]` -- true in Perl -- so testing the ref for truth
# (as this used to) takes the tag branch for an untagged image and hands
# inspect()/history() an undef name. Walk the list for the first image that
# actually HAS a tag; fall back to an id only when none do -- both engines
# accept either as a name, so either is correct, but the ref-as-boolean
# check was right for neither. See karr k75.
sub _live_image_name {
  my ($images) = @_;
  for my $image (@$images) {
    my $tags = $image->repo_tags;
    return $tags->[0] if ref $tags eq 'ARRAY' && @$tags;
  }
  return $images->[0]->id;
}

check_live_access();

subtest '_live_image_name picks a tag, falling back to id' => sub {
  my $SUMMARY = 'API::Docker::Type::ImageSummary';
  my $untagged_1 = $SUMMARY->new(Id => 'sha256:untagged1', RepoTags => []);
  my $untagged_2 = $SUMMARY->new(Id => 'sha256:untagged2', RepoTags => []);
  my $tagged     = $SUMMARY->new(Id => 'sha256:tagged', RepoTags => ['alpine:3', 'alpine:latest']);

  is(
    _live_image_name([ $untagged_1, $untagged_2, $tagged ]),
    'alpine:3',
    'untagged images sorted first are skipped in favour of the first tag',
  );

  is(
    _live_image_name([ $tagged, $untagged_1 ]),
    'alpine:3',
    'a tagged image still wins when it is already first',
  );

  is(
    _live_image_name([ $untagged_1, $untagged_2 ]),
    'sha256:untagged1',
    q{falls back to the first image's id when nothing in the store is tagged},
  );
};

# --- Read Tests (always run) ---

# Captured 2026-08-28 (karr k101) against Podman 5.8.4 (Docker-compat API
# 1.44): GET /images/json on this host's real engine, unmodified -- five
# entries because that engine had five images at capture time, two of them
# untagged buildah layers with no RepoTags. See
# t/type_fixture_passthrough.t's "unknown-field regression" subtest for what
# this engine sends beyond the swagger (Digest/History/Names/Dangling).
subtest 'list images' => sub {
  my $docker = test_docker(
    'GET /images/json' => load_fixture('images_list'),
  );

  my $images = $docker->images->list;

  is(ref $images, 'ARRAY', 'returns array');
  if (@$images) {
    isa_ok($images->[0], 'API::Docker::Type::ImageSummary');
    ok($images->[0]->id, 'has id');
  }

  unless (is_live()) {
    is(scalar @$images, 5, 'five images');

    my ($alpine) = grep { grep { /alpine/ } @{ $_->repo_tags } } @$images;
    ok $alpine, 'the tagged alpine image is in the list';
    like($alpine->id, qr/^sha256:d529dd0c/, 'image id');
    is_deeply($alpine->repo_tags,
      ['docker.io/library/alpine:3', 'docker.io/library/alpine:latest'],
      'repo tags');
    is($alpine->size, 8709729, 'image size');
    is($alpine->containers, 0, 'container count');
  }
};

subtest 'inspect image' => sub {
  my $docker = test_docker(
    'GET /images/nginx:latest/json' => {
      Id           => 'sha256:abc123',
      RepoTags     => ['nginx:latest'],
      Architecture => 'amd64',
      Os           => 'linux',
      Size         => 187654321,
      Config       => {
        Cmd => ['nginx', '-g', 'daemon off;'],
      },
    },
  );

  my $image;
  if (is_live()) {
    my $images = $docker->images->list;
    if (@$images) {
      my $name = _live_image_name($images);
      $image = $docker->images->inspect($name);
    } else {
      plan skip_all => 'No images available for inspect test';
      return;
    }
  } else {
    $image = $docker->images->inspect('nginx:latest');
  }

  isa_ok($image, 'API::Docker::Type::ImageInspect');
  ok($image->id, 'has id');

  unless (is_live()) {
    is($image->id, 'sha256:abc123', 'image id');
    is($image->architecture, 'amd64', 'architecture');
    is($image->os, 'linux', 'os');
    is_deeply($image->config->cmd, ['nginx', '-g', 'daemon off;'],
      'and a nested field is inflated into its own generated class');
  }
};

subtest 'image history' => sub {
  my $docker = test_docker(
    'GET /images/nginx:latest/history' => [
      {
        Id        => 'sha256:abc123',
        Created   => 1705300000,
        CreatedBy => '/bin/sh -c #(nop) CMD ["nginx" "-g" "daemon off;"]',
        Size      => 0,
      },
      {
        Id        => 'sha256:def456',
        Created   => 1705299000,
        CreatedBy => '/bin/sh -c apt-get update',
        Size      => 50000000,
      },
    ],
  );

  my $history;
  if (is_live()) {
    my $images = $docker->images->list;
    if (@$images) {
      my $name = _live_image_name($images);
      $history = $docker->images->history($name);
    } else {
      plan skip_all => 'No images available for history test';
      return;
    }
  } else {
    $history = $docker->images->history('nginx:latest');
  }

  is(ref $history, 'ARRAY', 'history is array');

  unless (is_live()) {
    is(scalar @$history, 2, 'two history entries');
  }
};

subtest 'search images' => sub {
  my $docker = test_docker(
    'GET /images/search' => [
      {
        name         => 'nginx',
        description  => 'Official nginx image',
        star_count   => 19000,
        is_official  => 1,
        is_automated => 0,
      },
    ],
  );

  my $results = $docker->images->search('nginx');

  is(ref $results, 'ARRAY', 'search returns array');

  unless (is_live()) {
    is($results->[0]{name}, 'nginx', 'found nginx');
  }
};

# --- Write Tests (mock always, live only with WRITE) ---

subtest 'image build and pull lifecycle' => sub {
  skip_unless_write();

  my ($pull_params, $tag_params);
  my $docker = test_docker(
    'POST /build' => sub {
      my ($method, $path, %opts) = @_;
      ok(defined $opts{raw_body}, 'raw_body present in request');
      is($opts{content_type}, 'application/x-tar', 'content type is tar');
      ok($opts{ndjson}, 'build asks for stream decoding');
      # Never asserted before: build() only ever proved its own params by
      # inspection of the code, not of what actually reached the mock route.
      is($opts{params}{t}, 'myapp:latest',
        'the build tag reaches the query string') unless is_live();
      is($opts{params}{dockerfile}, 'Dockerfile',
        'and so does the dockerfile path') unless is_live();
      return build_events();
    },
    'POST /images/create' => sub {
      my ($method, $path, %opts) = @_;
      $pull_params = $opts{params};
      return '';
    },
    'POST /images/nginx:latest/tag'  => sub {
      my ($method, $path, %opts) = @_;
      $tag_params = $opts{params};
      return undef;
    },
    'DELETE /images/nginx:latest'    => [
      { Untagged => 'nginx:latest' },
      { Deleted  => 'sha256:abc123' },
    ],
  );

  if (is_live()) {
    my $dockerfile = "FROM alpine:latest\nRUN echo 'hello from api-docker-test'\n";

    my $filename = 'Dockerfile';
    my $size = length($dockerfile);

    my $header = pack('a100', $filename);
    $header .= pack('a8', sprintf('%07o', 0644));
    $header .= pack('a8', sprintf('%07o', 0));
    $header .= pack('a8', sprintf('%07o', 0));
    $header .= pack('a12', sprintf('%011o', $size));
    $header .= pack('a12', sprintf('%011o', time()));
    $header .= '        ';
    $header .= '0';
    $header .= pack('a100', '');
    $header .= pack('a6', 'ustar');
    $header .= pack('a2', '00');
    $header .= pack('a32', '');
    $header .= pack('a32', '');
    $header .= pack('a8', '');
    $header .= pack('a8', '');
    $header .= pack('a155', '');
    $header .= "\0" x (512 - length($header));

    my $checksum = 0;
    $checksum += ord(substr($header, $_, 1)) for 0..511;
    substr($header, 148, 8, sprintf('%06o', $checksum) . "\0 ");

    my $tar = $header;
    $tar .= $dockerfile;
    $tar .= "\0" x (512 - ($size % 512)) if $size % 512;
    $tar .= "\0" x 1024;

    my $tag = 'api-docker-test-build:latest';
    # q => 1 makes the engine emit exactly one event -- the case that used
    # to come back as a HashRef instead of an ArrayRef.
    my $result = $docker->images->build(context => $tar, t => $tag, q => 1);
    is(ref $result, 'ARRAY', 'a single-event build stream is still an ArrayRef');
    register_cleanup(sub { eval { $docker->images->remove($tag, force => 1) } });
  } else {
    my $result = $docker->images->build(
      context    => 'fake-tar-data',
      t          => 'myapp:latest',
      dockerfile => 'Dockerfile',
    );
    is(ref $result, 'ARRAY', 'build returns an ArrayRef of events');
    like(
      join('', map { $_->{stream} // '' } @$result),
      qr/Successfully built/,
      'build output contains success',
    );

    $docker->images->pull(fromImage => 'nginx', tag => 'latest');
    is_deeply($pull_params, { fromImage => 'nginx', tag => 'latest' },
      'pull sent fromImage and tag as query params');

    $docker->images->tag('nginx:latest', repo => 'myrepo/nginx', tag => 'v1');
    is_deeply($tag_params, { repo => 'myrepo/nginx', tag => 'v1' },
      'tag sent repo and tag as query params, on the nginx:latest path');

    my $removed = $docker->images->remove('nginx:latest');
    is(ref $removed, 'ARRAY', 'remove returns array of actions');
  }
};

# --- Validation Tests (always run, no Docker needed) ---

subtest 'build requires context' => sub {
  my $docker = test_docker();

  eval { $docker->images->build(t => 'myapp:latest') };
  like($@, qr/Build context required/, 'croak on missing context');
};

subtest 'image name required' => sub {
  my $docker = test_docker();

  eval { $docker->images->inspect(undef) };
  like($@, qr/Image name required/, 'croak on missing name for inspect');

  eval { $docker->images->remove(undef) };
  like($@, qr/Image name required/, 'croak on missing name for remove');
};

# k99: `tag` must not be defaulted onto a reference that already carries one.
# The engine appends it -- Docker rewrites nginx:1.25 to nginx:latest and
# reports success, Podman 500s on nginx:1.25:latest. Prove which query goes out
# for each case by capturing the params off the mock route table. Returning ''
# gives pull's ndjson decode an empty stream, which comes back as [].
subtest 'pull only defaults tag when the reference has none' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();
  my $captured;
  my $docker = test_docker(
    'POST /images/create' => sub {
      my ($method, $path, %opts) = @_;
      $captured = $opts{params};
      return '';
    },
  );

  # (c) bare name -> tag=latest kept
  $docker->images->pull(fromImage => 'nginx');
  is($captured->{tag}, 'latest', 'bare name defaults tag to latest');

  # (a) name already tagged -> no tag appended
  $docker->images->pull(fromImage => 'nginx:1.25');
  ok(!exists $captured->{tag}, 'tagged reference sends no tag param');
  is($captured->{fromImage}, 'nginx:1.25', 'tagged reference passes through');

  # (b) digest reference -> no tag appended
  $docker->images->pull(fromImage => 'alpine@sha256:'.('0' x 64));
  ok(!exists $captured->{tag}, 'digest reference sends no tag param');

  # (d) explicit tag is respected even on a bare name
  $docker->images->pull(fromImage => 'nginx', tag => 'x');
  is($captured->{tag}, 'x', 'explicit tag is respected');

  # registry host:port/ prefix is not a tag -> still defaults to latest
  $docker->images->pull(fromImage => 'localhost:5000/foo');
  is($captured->{tag}, 'latest', 'registry port colon is not mistaken for a tag');

  # a tag after the registry port still suppresses the default
  $docker->images->pull(fromImage => 'localhost:5000/foo:1.25');
  ok(!exists $captured->{tag}, 'tag after a registry port sends no tag param');
};

done_testing;
