#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;
use JSON::MaybeXS qw( decode_json encode_json );
use MIME::Base64 qw( encode_base64 decode_base64 );

use API::Docker;

# pull carries X-Registry-Auth (single AuthConfig), build carries
# X-Registry-Config (a base64url map of registry hostname -> AuthConfig), and
# both go through the one encoder in API::Docker::Role::RegistryAuth. This file
# proves the two headers reach the wire correctly encoded, and pins the
# base64url-alphabet fix: a value pre-encoded in *standard* base64 must be
# respelled into the URL-safe alphabet before it goes out, because the engine
# decodes with Go's base64.URLEncoding and a leftover '+' or '/' makes it fail
# with 'failed to parse ... header ... unexpected EOF'.

# No padding is added back, and the standard alphabet is deliberately NOT mapped
# to URL-safe here -- decode exactly what the engine would receive, so an
# unconverted '+'/'/' on the wire is a decode failure the test can see.
sub b64url_decode {
  my ($s) = @_;
  $s =~ tr{-_}{+/};
  return decode_base64($s);
}

my $CREDS = { username => 'me', password => 'secret', serveraddress => 'ghcr.io' };

# ---------------------------------------------------------------------------
# The :63 fix, at the encoder. A pre-encoded standard-base64 string (with '+'
# and '/') used to pass through untouched; it must now be respelled URL-safe.
# This subtest goes red the moment the tr{+/}{-_} is dropped and the old
# `return $auth if ... base64-like` is restored.
subtest 'a pre-encoded standard-base64 auth is respelled URL-safe' => sub {
  my $images = API::Docker->new(
    host        => 'unix:///dev/null',
    api_version => '1.47',
  )->images;

  # Bytes 0..255 guarantee the standard alphabet's '+' and '/' appear.
  my $raw = pack('C*', 0 .. 255);
  my $std = encode_base64($raw, '');
  like $std, qr{[+/]}, 'the sample payload really contains + or /';

  my $out = $images->_registry_auth_header($std);
  unlike $out, qr{[+/]},
    'no standard-base64 character reaches the wire';

  (my $expected = $std) =~ tr{+/}{-_};
  is $out, $expected,
    'the header is exactly the URL-safe respelling of the input';
  is b64url_decode($out), $raw,
    'and it still decodes back to the original bytes';

  # X-Registry-Config's encoder shares the same body and the same fix.
  is $images->_registry_config_header($std), $expected,
    'the config-header encoder respells a standard-base64 string too';
};

# ---------------------------------------------------------------------------
subtest 'pull sends X-Registry-Auth only when auth is given' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();

  my $captured;
  my $docker = test_docker(
    'POST /images/create' => sub {
      my ($method, $path, %opts) = @_;
      $captured = \%opts;
      return '';
    },
  );

  # With credentials: header present, correctly encoded, no +// on the wire.
  $docker->images->pull(fromImage => 'private.example/app', tag => 'v1', auth => $CREDS);
  my $hdr = $captured->{headers}{'X-Registry-Auth'};
  ok defined $hdr, 'X-Registry-Auth present when auth given';
  unlike $hdr, qr{[+/]}, 'header uses the URL-safe alphabet only';
  is_deeply decode_json(b64url_decode($hdr)), $CREDS,
    'header decodes to the passed credentials';

  # Without credentials: no header at all -- the anonymous case.
  $captured = undef;
  $docker->images->pull(fromImage => 'alpine', tag => '3');
  ok !exists $captured->{headers}, 'no X-Registry-Auth header on an anonymous pull';
};

# ---------------------------------------------------------------------------
subtest 'build sends X-Registry-Config only when registry_config is given' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();

  my $captured;
  my $docker = test_docker(
    'POST /build' => sub {
      my ($method, $path, %opts) = @_;
      $captured = \%opts;
      return [ { stream => 'Successfully built deadbeef\n' } ];
    },
  );

  my $map = {
    'registry.example:5000' => { username => 'me', password => 'secret' },
    'ghcr.io'               => { identitytoken => 'tok-123' },
  };

  $docker->images->build(
    context         => 'fake-tar-data',
    t               => 'myapp:latest',
    registry_config => $map,
  );
  my $hdr = $captured->{headers}{'X-Registry-Config'};
  ok defined $hdr, 'X-Registry-Config present when registry_config given';
  unlike $hdr, qr{[+/]}, 'header uses the URL-safe alphabet only';
  is_deeply decode_json(b64url_decode($hdr)), $map,
    'header decodes to the hostname -> AuthConfig map';
  ok !exists $captured->{headers}{'X-Registry-Auth'},
    'a build carries the map header, not the single-AuthConfig one';

  # Without it: no header at all.
  $captured = undef;
  $docker->images->build(context => 'fake-tar-data', t => 'myapp:latest');
  ok !exists $captured->{headers}, 'no X-Registry-Config header on an anonymous build';
};

done_testing;
