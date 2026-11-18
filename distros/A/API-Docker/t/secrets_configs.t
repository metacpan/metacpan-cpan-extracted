#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use MIME::Base64 qw( decode_base64 );
use API::Docker::Role::Entity::Config;
use API::Docker::Role::Entity::Secret;
use API::Docker::Error::HTTP;
use lib 't/lib';
use Test::API::Docker::Mock;

check_live_access();

# Most of what this file asserts is the shape of the *outgoing* request --
# that Data leaves as base64 and that Version.Index leaves as the `version`
# query parameter. Neither is visible from a response, so those subtests are
# mock-only and say so rather than passing vacuously against a daemon.
my $REQUEST_SHAPE = 'asserts the outgoing request; only the mock can see it';

# The Engine API reference's shape for a config, kept inline instead of in
# t/fixtures/: the files there are captured from a real daemon, and no engine
# reachable from this repo serves /configs. Podman answers the collection GET
# (/configs) with a plain-text "Not Found" 404, unchanged since it was first
# measured on 5.4.2 / API 1.41 -- but every item-scoped route under it
# (create, inspect, update, remove) answers 503 JSON instead, not the same
# 404 (re-measured live, Podman 5.8.4 / API 1.44, karr k62; see the
# $CONFIGS_UNSERVED comment below for the detail). No engine serving
# /configs was at hand when this was written, so there is no
# configs_list.json: a hand-rolled file dressed up as a capture would be
# worse than none.
my $CONFIG = {
  ID        => 'ktnbjxoalbkvbvedmg1urrz8h',
  Version   => { Index => 11 },
  CreatedAt => '2016-11-05T01:20:17.327670065Z',
  UpdatedAt => '2016-11-05T01:20:17.327670065Z',
  Spec      => {
    Name   => 'server.conf',
    Labels => { 'com.example.some-label' => 'some-value' },
    Data   => 'bGlzdGVuIDgwODA7Cg==',
  },
};

# --- Read paths -------------------------------------------------------------

subtest 'secrets list' => sub {
  my $docker  = test_docker('GET /secrets' => load_fixture('secrets_list'));
  my $secrets = eval { $docker->secrets->list };
  if (my $err = $@) {
    die $err unless is_live() && ref($err) && $err->isa('API::Docker::Error::HTTP')
      && $err->status == 503;

    # Docker serves /secrets only on an initialised swarm manager; a plain
    # single-node install -- the normal state of a development machine, and
    # what this daemon is -- answers 503 "This node is not a swarm manager"
    # here instead of a list (measured live, Docker 29.7.2 / API 1.55).
    # `docker swarm init` would clear it, but that is a real change to the
    # host's networking (an overlay network, a firewall rule) that no test
    # may make, so this is a skip and not a workaround. Reacting to the
    # status rather than pre-checking GET /info's Swarm.LocalNodeState is
    # deliberate: Podman answers "inactive" there too, despite serving
    # /secrets from its own local secret store with no swarm involved --
    # a pre-check on that field would skip the one live engine this subtest
    # actually covers (measured live, Podman 5.4.2 / API 1.41).
    plan skip_all => "daemon refuses /secrets outside a swarm (503): $err";
  }

  is(ref $secrets, 'ARRAY', 'list returns an ArrayRef');
  return if is_live();

  is(scalar @$secrets, 2, 'two secrets in the fixture');
  isa_ok($secrets->[0], 'API::Docker::Type::Secret', 'entries are wrapped and the first one');
  isa_ok($secrets->[1], 'API::Docker::Type::Secret', 'so is the second');

  is($secrets->[0]->id, '28497238e77f873904ff31cb2', 'id off the entity');
  is($secrets->[0]->spec->name, 'db-password', 'first secret name');
  is($secrets->[0]->version_index, 1, 'version_index reaches the Version.Index that update needs');
  is($secrets->[0]->created_at, '2026-08-27T05:01:40.791536705Z', 'created_at is carried');
  is($secrets->[0]->updated_at, '2026-08-27T05:01:40.791536705Z', 'updated_at is carried');

  # The old entity kept Spec as the raw HashRef, so `!exists ...->{Data}` was
  # the whole claim. SecretSpec declares `data` whether the daemon sent it or
  # not, so the accessor now always exists and the claim moves to what it
  # reads -- plus TO_JSON, which is the level where "the key was never there"
  # is still observable.
  is($secrets->[0]->spec->data, undef, 'a secret never comes back with its value');
  ok(!exists $secrets->[0]->spec->TO_JSON->{Data},
    'and the round trip does not invent the key either');
  ok(!API::Docker::Type::Secret->can('decoded_data'),
    'the class has no decoded_data -- there is nothing on a secret to decode');

  is($secrets->[1]->spec->labels, undef,
    'Podman sends Labels: null for an empty label set, and it is passed through as undef');

  is($secrets->[0]->client, $docker, 'the entity carries the client that produced it');
};

subtest 'a secret entity delegates by ID, and defaults the version from itself' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my ($deleted, $update_path, $update_params, $update_body);
  my $docker = test_docker(
    'GET /secrets' => load_fixture('secrets_list'),
    'GET /secrets/28497238e77f873904ff31cb2' => load_fixture('secrets_list')->[0],
    'DELETE /secrets/28497238e77f873904ff31cb2' => sub { $deleted = 1; return undef },
    'POST /secrets/28497238e77f873904ff31cb2/update' => sub {
      my ($method, $path, %opts) = @_;
      ($update_path, $update_params, $update_body) = ($path, $opts{params}, $opts{body});
      return undef;
    },
  );

  my $secret = $docker->secrets->list->[0];

  my $fresh = $secret->inspect;
  isa_ok($fresh, 'API::Docker::Type::Secret', 'inspect on the entity returns a fresh entity, and it');
  is($fresh->spec->name, 'db-password', 'holding the same secret');

  # The spec is an object now, so the "send the whole spec back" idiom goes
  # through TO_JSON, which renders it in the daemon's own spelling.
  my %spec = %{ $secret->spec->TO_JSON };
  $spec{Labels} = { env => 'staging' };
  $secret->update(%spec);

  is($update_path, '/secrets/28497238e77f873904ff31cb2/update',
    'update addresses the secret by id, not by Spec.Name');
  is_deeply($update_params, { version => 1 },
    'and fills the version in from the entity own Version.Index');
  is_deeply($update_body->{Labels}, { env => 'staging' }, 'the spec is the request body');
  ok(!exists $update_body->{version},
    'the defaulted version is a query parameter, not smuggled into the spec');

  $secret->update(version => 9, %spec);
  is_deeply($update_params, { version => 9 },
    'an explicit version wins over the entity own -- nothing the caller passes is overwritten');
  ok(!exists $update_body->{version}, 'and it is stripped out of the spec before it goes out');

  $secret->remove;
  ok($deleted, 'remove deletes by ID');
};

subtest 'secrets list forwards filters as a HashRef' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $params;
  my $docker = test_docker('GET /secrets' => sub {
    my ($method, $path, %opts) = @_;
    $params = $opts{params};
    return [];
  });

  $docker->secrets->list(filters => { label => ['env=prod'] });

  is_deeply($params->{filters}, { label => ['env=prod'] },
    'filters reach the transport as a HashRef -- encoding them here would double-encode');
};

subtest 'secrets list without filters sends no filters parameter' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $params;
  my $docker = test_docker('GET /secrets' => sub {
    my ($method, $path, %opts) = @_;
    $params = $opts{params};
    return [];
  });

  $docker->secrets->list;
  is_deeply($params, {}, 'no filters key invented');
};

subtest 'secrets inspect' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $docker = test_docker(
    'GET /secrets/db-password' => load_fixture('secrets_list')->[0],
  );

  my $secret = $docker->secrets->inspect('db-password');
  isa_ok($secret, 'API::Docker::Type::Secret', 'inspect wraps the daemon response and it');
  is($secret->spec->name, 'db-password', 'carrying the spec');
  is($secret->version_index, 1, 'with the Version.Index');
};

# --- create: the base64 contract --------------------------------------------

subtest 'secrets create encodes Data for the caller' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $body;
  my $docker = test_docker('POST /secrets/create' => sub {
    my ($method, $path, %opts) = @_;
    $body = $opts{body};
    return { ID => 'abc123' };
  });

  my $created = $docker->secrets->create(
    Name   => 'db-password',
    Data   => "hunter2\n",
    Labels => { env => 'prod' },
  );

  is($created->{ID}, 'abc123', 'returns the daemon response unwrapped');
  is($body->{Name}, 'db-password', 'Name goes out untouched');
  is_deeply($body->{Labels}, { env => 'prod' }, 'Labels go out untouched');

  isnt($body->{Data}, "hunter2\n",
    'the raw bytes are not what goes on the wire -- the daemon would store garbage and answer 200');
  is($body->{Data}, 'aHVudGVyMgo=', 'Data is base64 of exactly what the caller passed');
  is(decode_base64($body->{Data}), "hunter2\n", 'and decodes back to it');
};

subtest 'secrets create uses the alphabet the engine accepts' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $body;
  my $docker = test_docker('POST /secrets/create' => sub {
    my ($method, $path, %opts) = @_;
    $body = $opts{body};
    return { ID => 'abc123' };
  });

  # Measured: the engine takes +v/++w== for these four bytes and rejects the
  # URL-safe -v_--w== with 500, despite the reference calling the field
  # "base64-url-safe-encoded".
  $docker->secrets->create(Name => 'bytes', Data => "\xfa\xff\xfe\xfb");
  is($body->{Data}, '+v/++w==', 'standard base64 alphabet, + and / rather than - and _');

  # encode_base64 wraps at 76 characters unless told otherwise, and a wrapped
  # value is a JSON string with newlines in it that the engine will not decode.
  my $long = 'x' x 300;
  $docker->secrets->create(Name => 'big', Data => $long);
  unlike($body->{Data}, qr/\n/, '300 bytes of Data goes out unwrapped');
  is(decode_base64($body->{Data}), $long, 'and still round-trips');
};

subtest 'secrets create validates before it opens a socket' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $requests = 0;
  my $docker = test_docker('POST /secrets/create' => sub { $requests++; return { ID => 'x' } });

  eval { $docker->secrets->create(Data => "x") };
  like($@, qr/Name required/, 'a missing Name croaks');

  eval { $docker->secrets->create(Name => 'n') };
  like($@, qr/Data required/, 'a missing Data croaks');

  eval { $docker->secrets->create(Name => 'n', Data => '') };
  like($@, qr/Data required/, 'an empty Data croaks -- the engine rejects it with 500 anyway');

  eval { $docker->secrets->create(Name => 'n', Data => "\x{263A}") };
  like($@, qr/must be a byte string/,
    'decoded characters croak here instead of dying inside MIME::Base64');

  is($requests, 0, 'none of them reached the daemon');
};

# --- update: the version query parameter ------------------------------------

subtest 'secrets update sends Version.Index as the version parameter' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my ($path, $params, $body);
  my $docker = test_docker(
    'GET /secrets/db-password'         => load_fixture('secrets_list')->[0],
    'POST /secrets/db-password/update' => sub {
      my ($method, $req_path, %opts) = @_;
      ($path, $params, $body) = ($req_path, $opts{params}, $opts{body});
      return undef;
    },
  );

  my $secret = $docker->secrets->inspect('db-password');
  is($secret->version_index, 1, 'the version the caller is meant to pass comes from inspect');

  my %spec = %{ $secret->spec->TO_JSON };
  $spec{Labels} = { env => 'staging' };
  my $result = $docker->secrets->update('db-password', $secret->version_index, %spec);

  is($path, '/secrets/db-password/update', 'update posts to the right path');
  is_deeply($params, { version => 1 },
    'Version.Index rides in the version query parameter, and it is the only parameter');
  is_deeply($body->{Labels}, { env => 'staging' }, 'the spec is the request body');
  is($body->{Name}, 'db-password', 'the rest of the spec goes back unchanged');
  ok(!exists $body->{version}, 'version is not also smuggled into the body');
  is($result, undef, 'update returns nothing -- the daemon answers with an empty body');
};

subtest 'secrets update will not go out without a usable version' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $requests = 0;
  my $docker = test_docker(
    'POST /secrets/db-password/update' => sub { $requests++; return undef },
  );

  eval { $docker->secrets->update('db-password', undef, Labels => {}) };
  my $missing = $@;
  like($missing, qr/version/, 'a missing version croaks about the version');
  like($missing, qr/Version\.Index/, 'and names the field it comes from');
  like($missing, qr/inspect/, 'and the call that produces it');

  eval { $docker->secrets->update('db-password', 'latest', Labels => {}) };
  like($@, qr/must be the numeric Version\.Index/, 'a non-numeric version croaks');

  eval { $docker->secrets->update(undef, 1, Labels => {}) };
  like($@, qr/ID or name required/, 'a missing id croaks');

  is($requests, 0,
    'the guard is client-side: no request was made for any of them');
};

subtest 'secrets update encodes a Data it is given' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $body;
  my $docker = test_docker('POST /secrets/s/update' => sub {
    my ($method, $path, %opts) = @_;
    $body = $opts{body};
    return undef;
  });

  $docker->secrets->update('s', 7, Name => 's', Data => "hunter2\n");
  is($body->{Data}, 'aHVudGVyMgo=', 'Data is encoded on update just as on create');

  $docker->secrets->update('s', 7, Name => 's', Labels => { a => 'b' });
  ok(!exists $body->{Data}, 'and no Data key is invented when none was passed');
};

subtest 'secrets remove' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $method_seen;
  my $docker = test_docker('DELETE /secrets/db-password' => sub {
    my ($method) = @_;
    $method_seen = $method;
    return undef;
  });

  my $result = $docker->secrets->remove('db-password');
  is($method_seen, 'DELETE', 'remove uses DELETE');
  is($result, undef, 'and returns nothing -- the daemon answers 204');

  eval { $docker->secrets->remove('') };
  like($@, qr/ID or name required/, 'an empty id croaks');
};

# --- configs: the same five endpoints, one different return -----------------
#
# Podman has no /configs route: GET /configs (the collection) answers the
# same blanket 404 Not Found, plain text body "Not Found", that any
# unimplemented path gets (measured live, Podman 5.4.2 / API 1.41, and
# unchanged on 5.8.4 / API 1.44 -- karr k62). Every item-scoped route under
# it -- create, inspect, update, remove -- instead answers 503 with a JSON
# body, {"cause":"Podman does not support service: <path>","message":"...",
# "response":503} (re-measured live on 5.8.4 / API 1.44, karr k62; not
# checked against 5.4.2). Docker does serve /configs, but only inside an
# initialised swarm manager; outside one it answers 503 with a JSON body,
# "This node is not a swarm manager. Use \"docker swarm init\" or \"docker
# swarm join\" to connect this node to swarm and try again." -- the same
# gate /secrets sits behind (measured live, Docker 29.7.2 / API 1.55).
# Unlike /secrets, which Podman serves from its own local store with no
# swarm involved, /configs has no swarm-free path on either engine, and
# swarm orchestration is out of scope for this distribution (see
# API::Docker's own POD, and `docker swarm init` is a real change to the
# host's networking that no test may make besides). So neither live engine
# reachable from this suite ever actually answers /configs with data, and
# both subtests below skip unconditionally on is_live() for that reason --
# not because of a Podman-specific gap.
my $CONFIGS_UNSERVED = 'no live engine here serves /configs: Podman has no route for it '
  . '(404 on the collection, 503 on everything else), Docker gates it behind swarm (503) '
  . 'and swarm is out of scope for this distribution';

subtest 'configs list' => sub {
  plan skip_all => $CONFIGS_UNSERVED if is_live();

  my $docker  = test_docker('GET /configs' => [$CONFIG]);
  my $configs = $docker->configs->list;

  is(ref $configs, 'ARRAY', 'list returns an ArrayRef');
  isa_ok($configs->[0], 'API::Docker::Type::Config', 'entries are wrapped and the first one');
  is($configs->[0]->id, 'ktnbjxoalbkvbvedmg1urrz8h', 'id off the entity');
  is($configs->[0]->spec->name, 'server.conf', 'config name');
  is($configs->[0]->version_index, 11, 'version_index reaches the Version.Index');
  is($configs->[0]->created_at, '2016-11-05T01:20:17.327670065Z', 'created_at is carried');
  is($configs->[0]->client, $docker, 'the entity carries the client that produced it');
};

subtest 'decoded_data decodes spec->data and leaves the spec alone' => sub {
  plan skip_all => $CONFIGS_UNSERVED if is_live();

  my $docker = test_docker('GET /configs' => [$CONFIG]);
  my $config = $docker->configs->list->[0];

  is($config->spec->data, 'bGlzdGVuIDgwODA7Cg==',
    'spec->data is the base64 the daemon sent, not rewritten by the entity');
  is($config->decoded_data, "listen 8080;\n",
    'decoded_data is that known base64 value decoded');
  isnt($config->decoded_data, $config->spec->data,
    'the two are not the same string -- an accessor that just handed spec->data back would pass everything else here');
  is($config->spec->data, 'bGlzdGVuIDgwODA7Cg==',
    'and reading it did not consume or replace the field');

  # A secret carries no payload at all, so the accessor exists on exactly one
  # of the two generated classes. That asymmetry is the ticket, not an
  # omission -- and it is now a property of which entity role was composed
  # onto which class, since SecretSpec declares a `data` field of its own.
  ok(API::Docker::Type::Config->can('decoded_data'), 'a config has the accessor');
  ok(!API::Docker::Type::Secret->can('decoded_data'), 'a secret deliberately does not');

  my $bare = API::Docker::Type::Config->new(ID => 'x');
  is($bare->decoded_data, undef, 'an object with no Spec decodes to nothing rather than dying');
  is($bare->version_index, undef, 'and has no version_index either');

  my $dataless = API::Docker::Type::Config->new(ID => 'x', Spec => { Name => 'n' });
  is($dataless->decoded_data, undef, 'nor does a Spec without a Data key');
};

subtest 'configs create encodes Data, inspect does not decode it' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $body;
  my $docker = test_docker(
    'POST /configs/create'      => sub {
      my ($method, $path, %opts) = @_;
      $body = $opts{body};
      return { ID => 'ktnbjxoalbkvbvedmg1urrz8h' };
    },
    'GET /configs/server.conf'  => $CONFIG,
  );

  $docker->configs->create(Name => 'server.conf', Data => "listen 8080;\n");
  is($body->{Data}, 'bGlzdGVuIDgwODA7Cg==', 'Data goes out base64, like secrets');
  is(decode_base64($body->{Data}), "listen 8080;\n", 'round-trips');

  my $config = $docker->configs->inspect('server.conf');
  isa_ok($config, 'API::Docker::Type::Config', 'inspect wraps the daemon response and it');
  is($config->spec->data, 'bGlzdGVuIDgwODA7Cg==',
    'hands the spec back untouched -- spec->data stays base64');
  is(decode_base64($config->spec->data), "listen 8080;\n",
    'so decoding stays an explicit step, visible rather than silent');
  is($config->decoded_data, "listen 8080;\n",
    'and decoded_data is that step, spelled once');
};

subtest 'configs update sends Version.Index as the version parameter' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my ($path, $params, $body);
  my $docker = test_docker(
    'GET /configs/server.conf'         => $CONFIG,
    'POST /configs/server.conf/update' => sub {
      my ($method, $req_path, %opts) = @_;
      ($path, $params, $body) = ($req_path, $opts{params}, $opts{body});
      return undef;
    },
  );

  my $config = $docker->configs->inspect('server.conf');
  my %spec   = %{ $config->spec->TO_JSON };
  delete $spec{Data};                        # already base64 -- see the POD
  $spec{Labels} = { 'com.example.some-label' => 'other-value' };

  $docker->configs->update('server.conf', $config->version_index, %spec);

  is($path, '/configs/server.conf/update', 'update posts to the right path');
  is_deeply($params, { version => 11 },
    'Version.Index rides in the version query parameter, and it is the only parameter');
  is_deeply($body->{Labels}, { 'com.example.some-label' => 'other-value' },
    'the spec is the request body');
};

subtest 'a config entity delegates by ID, and defaults the version from itself' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my ($deleted, $path, $params, $body);
  my $docker = test_docker(
    'GET /configs' => [$CONFIG],
    'DELETE /configs/ktnbjxoalbkvbvedmg1urrz8h' => sub { $deleted = 1; return undef },
    'POST /configs/ktnbjxoalbkvbvedmg1urrz8h/update' => sub {
      my ($method, $req_path, %opts) = @_;
      ($path, $params, $body) = ($req_path, $opts{params}, $opts{body});
      return undef;
    },
  );

  my $config = $docker->configs->list->[0];

  my %spec = %{ $config->spec->TO_JSON };
  $spec{Data}   = $config->decoded_data;     # decoded, so it encodes once on the way out
  $spec{Labels} = { 'com.example.some-label' => 'other-value' };
  $config->update(%spec);

  is($path, '/configs/ktnbjxoalbkvbvedmg1urrz8h/update',
    'update addresses the config by id, not by Spec.Name');
  is_deeply($params, { version => 11 },
    'and fills the version in from the entity own Version.Index');
  is($body->{Data}, 'bGlzdGVuIDgwODA7Cg==',
    'a decoded_data round-trip re-encodes to exactly the base64 it came from');

  $config->update(version => 12, %spec);
  is_deeply($params, { version => 12 },
    'an explicit version wins over the entity own -- nothing the caller passes is overwritten');
  ok(!exists $body->{version}, 'and it is stripped out of the spec before it goes out');

  $config->remove;
  ok($deleted, 'remove deletes by ID');
};

subtest 'configs update will not go out without a usable version' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $requests = 0;
  my $docker = test_docker(
    'POST /configs/server.conf/update' => sub { $requests++; return undef },
  );

  eval { $docker->configs->update('server.conf', undef, Labels => {}) };
  like($@, qr/Version\.Index/, 'a missing version croaks naming where the value comes from');

  eval { $docker->configs->update('server.conf', '11.0', Labels => {}) };
  like($@, qr/must be the numeric Version\.Index/, 'a non-integer version croaks');

  is($requests, 0, 'the guard is client-side: nothing reached the daemon');
};

subtest 'configs create validates and configs remove' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $requests = 0;
  my $docker = test_docker(
    'POST /configs/create'     => sub { $requests++; return { ID => 'x' } },
    'DELETE /configs/server.conf' => undef,
  );

  eval { $docker->configs->create(Data => 'x') };
  like($@, qr/Name required/, 'a missing Name croaks');

  eval { $docker->configs->create(Name => 'n') };
  like($@, qr/Data required/, 'a missing Data croaks');

  is($requests, 0, 'neither reached the daemon');
  is($docker->configs->remove('server.conf'), undef, 'remove returns nothing');
};

# --- the swarm decision is documented, not merely absent ---------------------

subtest 'the excluded Swarm endpoints are named as a decision in the POD' => sub {
  require API::Docker;
  my $pod = do {
    open my $fh, '<', $INC{'API/Docker.pm'} or die "$INC{'API/Docker.pm'}: $!";
    local $/;
    <$fh>;
  };

  like($pod, qr/Swarm orchestration is out of scope/,
    'API::Docker says so under its own heading');
  like($pod, qr{C</swarm>.*C</nodes>.*C</services>.*C</tasks>}s,
    'and names all four excluded endpoint groups');

  # Matched by paragraph rather than by directive: under `dzil test` this file
  # has already been through PodWeaver, which turns `=attr secrets` into
  # `=head2 secrets`. The prose is what the reader gets either way.
  #
  # Only these two paragraphs are this ticket's -- the other =attr entries are
  # still scaffolding, and other agents own them.
  my @paragraphs = split /\n\n/, $pod;
  for my $class (qw( Secrets Configs )) {
    my ($para) = grep { /L<API::Docker::API::$class> instance/ } @paragraphs;
    ok($para, "API::Docker documents its $class accessor");
    unlike($para, qr/Scaffolding/, "and no longer calls $class scaffolding");
    like($para, qr/C<update>/, "and names the methods it now has");
  }
};

done_testing;
