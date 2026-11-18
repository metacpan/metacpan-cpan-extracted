#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use JSON::MaybeXS qw( decode_json encode_json );
use MIME::Base64 qw( decode_base64 );
use API::Docker;
use Test::API::Docker::FakeTransport;

# API::Docker::Role::RegistryAuth: one AuthConfig encoding, shared by every
# class that talks to a registry. It used to exist twice -- a bare sub
# _build_registry_auth_header in Images.pm, called as a function, and a
# _registry_auth_header method in Plugins.pm with the same body.
#
# What the merge could break is not the encoding, which is pinned in
# t/images_push_auth.t, but the two *policies* around it. They differ on
# purpose:
#
#   /images/{name}/push       always sends X-Registry-Auth, because the
#                             engine rejects an image push without it, and
#                             an anonymous push sends the encoding of {}
#   /plugins/*                sends it only when credentials were given: the
#   /distribution/{name}/json plugin and distribution routers decode the
#                             header and discard the error ("Ignore invalid
#                             AuthConfig to increase compatibility with the
#                             existing API"), so no header is the anonymous
#                             case rather than a failure
#
# Nothing here opens a socket or reaches a daemon, in either mode: the
# daemon is faked below the socket so that _request assembles a real request
# and the assertions read what would have gone on the wire. Podman serves
# neither /plugins nor /distribution, so a live run of this file could only
# be red or skipped.

sub fake_client {
  my ($body, $status) = @_;
  return Test::API::Docker::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    canned      => [$status // 200, 'OK', {}, $body // ''],
  );
}

sub auth_header {
  my ($raw) = @_;
  my ($hdr) = $raw =~ /^X-Registry-Auth: (\S+)\r$/m;
  return $hdr;
}

sub b64url_decode {
  my ($s) = @_;
  $s =~ tr{-_}{+/};
  return decode_base64($s);
}

my $CREDS = { username => 'me', password => 'secret', serveraddress => 'ghcr.io' };

# ---------------------------------------------------------------------------
subtest 'the encoder lives in one place and every registry class sees it' => sub {
  my $docker = API::Docker->new(
    host        => 'unix:///dev/null',
    api_version => '1.47',
  );

  my @consumers = (
    [ images       => $docker->images ],
    [ plugins      => $docker->plugins ],
    [ distribution => $docker->distribution ],
    [ system       => $docker->system ],
  );

  my %header;
  for my $c (@consumers) {
    my ($name, $obj) = @$c;
    ok $obj->does('API::Docker::Role::RegistryAuth'), "$name does the role";
    $header{$name} = $obj->_registry_auth_header($CREDS);
  }

  is scalar(keys %{ { map { $_ => 1 } values %header } }), 1,
    'all four classes produce byte-identical headers for the same credentials';

  # The bare sub is gone rather than kept as a wrapper: a second entry point
  # is how the two copies drifted apart in the first place.
  ok !API::Docker::API::Images->can('_build_registry_auth_header'),
    'Images no longer carries its own encoder';
};

# ---------------------------------------------------------------------------
subtest '_registry_auth_config reads back every shape the header accepts' => sub {
  my $docker = API::Docker->new(
    host        => 'unix:///dev/null',
    api_version => '1.47',
  );
  my $system = $docker->system;

  is_deeply $system->_registry_auth_config($CREDS), $CREDS,
    'a HashRef comes back as itself';
  isnt $system->_registry_auth_config($CREDS), $CREDS,
    'and as a copy, so a caller cannot be mutated through it';

  is_deeply $system->_registry_auth_config(encode_json($CREDS)), $CREDS,
    'a JSON object is decoded';

  # The round trip that makes POST /auth able to take what push was given.
  my $header = $system->_registry_auth_header($CREDS);
  is_deeply $system->_registry_auth_config($header), $CREDS,
    'a header value decodes back to the AuthConfig it was built from';

  # base64url, not plain base64: a payload with a '/' or '+' in its base64
  # would not survive the wrong alphabet.
  my $slashy = { password => join('', map { chr } 0xfb, 0xff, 0xbf, 0xfe) };
  my $slashy_header = $system->_registry_auth_header($slashy);
  like $slashy_header, qr/[-_]/,
    'this payload really does exercise the substituted characters';
  is_deeply $system->_registry_auth_config($slashy_header), $slashy,
    'the -_ alphabet round trips';

  is $system->_registry_auth_config(undef), undef,
    'undef stays undef -- whether that is an error is the endpoint\'s call';

  ok !eval { $system->_registry_auth_config('not base64 at all !!'); 1 },
    'a value that is not an AuthConfig croaks';
  like $@, qr/AuthConfig/, 'and says so';
};

# ---------------------------------------------------------------------------
subtest 'images->push sends X-Registry-Auth even with no credentials' => sub {
  my $c = fake_client('{"status":"done"}');
  $c->images->push('myrepo/app', tag => 'v1');

  my $hdr = auth_header($c->written);
  is $hdr, 'e30=',
    'the anonymous push carries the padded encoding of {} -- the engine '
    . 'rejects an image push with no header at all';

  my $with = fake_client('{"status":"done"}');
  $with->images->push('myrepo/app', tag => 'v1', auth => $CREDS);
  is_deeply decode_json(b64url_decode(auth_header($with->written))), $CREDS,
    'and the credentials when they were given';
};

# ---------------------------------------------------------------------------
subtest 'plugins send X-Registry-Auth only when credentials were given' => sub {
  my $none = fake_client('[]');
  $none->plugins->privileges('vieux/sshfs:latest');
  unlike $none->written, qr/X-Registry-Auth/i,
    'no header at all on an anonymous plugin lookup';

  my $with = fake_client('[]');
  $with->plugins->privileges('vieux/sshfs:latest', auth => $CREDS);
  is_deeply decode_json(b64url_decode(auth_header($with->written))), $CREDS,
    'the header appears once credentials are passed';
};

# ---------------------------------------------------------------------------
subtest 'distribution sends X-Registry-Auth only when credentials were given' => sub {
  my $none = fake_client('{"Descriptor":{}}');
  $none->distribution->inspect('nginx:latest');
  unlike $none->written, qr/X-Registry-Auth/i,
    'a public image is looked up anonymously, with no header';

  my $with = fake_client('{"Descriptor":{}}');
  $with->distribution->inspect('private/app:1.0', auth => $CREDS);
  is_deeply decode_json(b64url_decode(auth_header($with->written))), $CREDS,
    'the header appears once credentials are passed';
};

done_testing;
