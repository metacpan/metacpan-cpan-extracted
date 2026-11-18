#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use JSON::MaybeXS qw( decode_json is_bool );
use MIME::Base64 qw( decode_base64 );
use API::Docker;
use Test::API::Docker::FakeTransport;

# Nothing here opens a socket or reaches a daemon, and nothing here is gated
# on is_live().
#
# Test::API::Docker::Mock is deliberately not used: under
# API_DOCKER_TEST_HOST it ignores its route table and hands back a real
# client, and the only engine this repo can reach is Podman, which serves
# none of /plugins -- measured, 2026-08-27, rootless Podman 5.4.2 (API 1.41):
# GET /v1.41/plugins answers 404 with
# {"cause":"","message":"Path /v1.41/plugins is not supported","response":0}
# (that version number just echoes the requested path prefix, not a fixed
# daemon constant -- re-measured live on 5.8.4 / API 1.44 the same message
# reads "/v1.44/plugins", karr k62) and every other path in the family
# answers a bare text/plain 404, i.e. the compat layer has no route for them
# at all. A live run of this file would therefore be red, and a skip_all
# would leave the whole class untested on the machine that actually runs the
# suite.
#
# So the daemon is faked below the socket instead, in both modes. Most of
# what is worth pinning about this endpoint family is in the request rather
# than the response -- a privilege list in a POST body, a query parameter
# that must not be omitted, a path that must not be escaped -- and that is
# what these assertions read.
#
# The canned responses are the Engine API reference's own example payloads,
# not daemon captures, which is why they are inline rather than in
# t/fixtures: a hand-rolled file there would claim a provenance it does not
# have.

sub fake_client {
  my ($body, $status) = @_;
  return Test::API::Docker::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    canned      => [$status // 200, 'OK', {}, $body // ''],
  );
}

sub request_line {
  my ($raw) = @_;
  my ($line) = $raw =~ /\A([^\r\n]*)/;
  return $line;
}

sub request_body {
  my ($raw) = @_;
  my ($body) = $raw =~ /\r\n\r\n(.*)\z/s;
  return $body;
}

sub query_param {
  my ($raw, $name) = @_;
  my ($qs) = request_line($raw) =~ /\?([^ ]*) HTTP/;
  return undef unless defined $qs;
  for my $pair (split /&/, $qs) {
    my ($k, $v) = split /=/, $pair, 2;
    next unless $k eq $name;
    $v =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
    return $v;
  }
  return undef;
}

sub b64url_decode {
  my ($s) = @_;
  $s =~ tr{-_}{+/};
  return decode_base64($s);
}

# The two example privilege sets below are the ones the Engine API reference
# ships for PluginPrivilege.
my $PRIVILEGES = [
  { Name => 'network', Description => '', Value => ['host'] },
  { Name => 'mount',   Description => '', Value => ['/data'] },
];

# One engine Plugin object, as JSON rather than as a Perl structure, so the
# wrapping is fed exactly what the transport decodes -- Enabled included,
# which reaches the entity as a decoded JSON boolean and must stay one.
#
# Synthesized, and not copied from an example either: the Engine API
# reference ships no example response for GET /plugins or for
# GET /plugins/{name}/json, both being a bare $ref to the Plugin definition.
# What comes from the reference is the field set and the types, checked
# against moby v20.10.24's swagger.yaml (which declares API 1.41) and the Go
# struct it describes: these six keys are exactly the struct's members, there
# is no Tag/Active pair (that is a stale pre-1.25 example block, deleted by
# 1.41) and no top-level Description; Enabled is a required boolean; Settings
# always carries Mounts, Env, Args and Devices, with Env and Args as plain
# KEY=value strings rather than the HashRefs the same two names hold under
# Config. The values are shaped the way the daemon builds them -- Name
# familiar and tagged, PluginReference fully qualified. No daemon reachable
# from this repo serves /plugins, so they are not a capture.
my $PLUGIN_JSON = '{'
  . '"Id":"5724e2c8652da337ab2eedd19fc6fc0ec908e4bd907c7421bf6a8dfc70c4c078",'
  . '"Name":"vieux/sshfs:latest",'
  . '"Enabled":true,'
  . '"PluginReference":"docker.io/vieux/sshfs:latest",'
  . '"Settings":{"Mounts":[],"Env":["DEBUG=0"],"Args":[],"Devices":[]},'
  . '"Config":{"Description":"sshFS plugin for Docker",'
  . '"Interface":{"Types":["docker.volumedriver/1.0"],"Socket":"sshfs.sock"}}'
  . '}';

# ---------------------------------------------------------------------------
subtest 'list: filters are JSON-encoded, and the filter name is "enabled"' => sub {
  my $c = fake_client('[]');
  $c->plugins->list(filters => { enabled => ['true'] });

  like request_line($c->written), qr{\AGET /v1\.41/plugins\?}, 'GET /plugins';
  is_deeply decode_json(query_param($c->written, 'filters')),
    { enabled => ['true'] },
    'the filters HashRef reaches the wire as a JSON map of string to array '
    . 'of string';

  # Not "enable". The Engine API reference documents that spelling, but the
  # daemon validates plugin filter names against {enabled, capability} and
  # refuses an unknown one outright, so copying the reference is a hard
  # error rather than a silently empty list.
  like query_param($c->written, 'filters'), qr/"enabled"/,
    'the name sent is enabled, not enable';
};

subtest 'list: no filters means no query string' => sub {
  my $c = fake_client('[]');
  my $got = $c->plugins->list;
  is request_line($c->written), 'GET /v1.41/plugins HTTP/1.1',
    'an empty params hash appends nothing';
  is_deeply $got, [], 'an engine with no plugins wraps to an empty ArrayRef';
};

# ---------------------------------------------------------------------------
subtest 'list wraps into API::Docker::Type::Plugin entities' => sub {
  my $c = fake_client('[' . $PLUGIN_JSON . ']');
  my $plugins = $c->plugins->list;

  is ref $plugins, 'ARRAY', 'an ArrayRef, one entry per plugin';
  my $plugin = $plugins->[0];
  isa_ok $plugin, 'API::Docker::Type::Plugin';

  is $plugin->id,
    '5724e2c8652da337ab2eedd19fc6fc0ec908e4bd907c7421bf6a8dfc70c4c078',
    'id';
  is $plugin->name, 'vieux/sshfs:latest', 'name';
  is $plugin->plugin_reference, 'docker.io/vieux/sshfs:latest',
    'plugin_reference -- the remote the plugin came from, which is not the '
    . 'local name once a plugin is installed under one';
  # Settings and Config used to be handed through as the HashRefs the engine
  # sent; the generated model inflates them into classes of their own, so
  # what they carry is reached by accessor a level down rather than by key.
  is_deeply $plugin->settings->env, ['DEBUG=0'],
    'settings is an API::Docker::Type::Plugin::Settings, and its env is the '
    . 'list of KEY=value strings configure() takes';
  is $plugin->config->interface->socket, 'sshfs.sock',
    'config likewise, two levels of generated class down';
  # The canned payload above is the Engine API reference's example and carries
  # no Config.Env, so the two shapes of that one key are asserted on the model
  # rather than on a payload invented to show them.
  my $settings_env = 'API::Docker::Type::Plugin::Settings'
    ->docker_attributes->{env}{isa}->display_name;
  my $config_env = 'API::Docker::Type::Plugin::Config'
    ->docker_attributes->{env}{isa}->display_name;
  like $settings_env, qr/Str/, 'Settings.Env is declared as strings';
  like $config_env, qr/PluginEnv/,
    'and Config.Env as PluginEnv objects -- same wire name, two shapes, one '
    . 'level apart';

  # This claim is the reverse of the one the hand-written entity carried.
  # API::Docker::Plugin mirrored the daemon verbatim, so Enabled stayed the
  # decoded JSON boolean and the test asserted is_bool on it. The generated
  # class declares the field as Bool and normalises it on the way in, so the
  # accessor is a plain 1/0 -- and TO_JSON turns it back into a JSON boolean,
  # which is where "nothing is lost" now lives.
  is $plugin->enabled, 1, 'enabled is 1 for an enabled plugin';
  ok !is_bool($plugin->enabled),
    'a plain Perl 1, not the decoded JSON boolean -- the model normalises a '
    . 'declared Bool rather than passing it through';
  ok is_bool($plugin->TO_JSON->{Enabled}),
    'and it goes back to the engine as a JSON boolean, so the round trip '
    . 'still says what the daemon said';

  # Without this the entity is inert: every method below reaches the engine
  # through the client, and a wrapper built without one dies on an
  # undefined invocant at the first call.
  is $plugin->client, $c, 'the client is threaded into the entity';
};

# ---------------------------------------------------------------------------
subtest 'the plugin name reaches the path unescaped' => sub {
  my $c = fake_client('{"Name":"docker.io/vieux/sshfs:latest"}');
  $c->plugins->inspect('docker.io/vieux/sshfs:latest');

  is request_line($c->written),
    'GET /v1.41/plugins/docker.io/vieux/sshfs:latest/json HTTP/1.1',
    'registry host, repository slashes and the tag colon all survive raw';

  # The daemon routes this family as /plugins/{name:.*}/json, so the slashes
  # are part of the captured name and percent-encoding them would not match.
  unlike $c->written, qr/%2F|%3A/i, 'nothing in the name got percent-encoded';
};

subtest 'inspect wraps too' => sub {
  my $c = fake_client($PLUGIN_JSON);
  my $plugin = $c->plugins->inspect('vieux/sshfs:latest');

  isa_ok $plugin, 'API::Docker::Type::Plugin';
  is $plugin->name, 'vieux/sshfs:latest', 'the single object is wrapped, '
    . 'not returned as the HashRef it arrived as';
  ok $plugin->enabled, 'and its fields are reachable as accessors';

  my $again = $plugin->inspect;
  is request_line($c->written),
    'GET /v1.41/plugins/vieux/sshfs:latest/json HTTP/1.1',
    'the entity re-inspects itself by name';
  isa_ok $again, 'API::Docker::Type::Plugin';
};

subtest 'the entity threads its name back through the resource class' => sub {
  my $c = fake_client('[' . $PLUGIN_JSON . ']');
  my $plugin = $c->plugins->list->[0];

  # Each request writes to a fresh sink, so ->written is always the last one.
  $plugin->enable(timeout => 30);
  is request_line($c->written),
    'POST /v1.41/plugins/vieux/sshfs:latest/enable?timeout=30 HTTP/1.1',
    'enable: the name goes into the path and the option is passed on';

  $plugin->disable(force => 1);
  is request_line($c->written),
    'POST /v1.41/plugins/vieux/sshfs:latest/disable?force=1 HTTP/1.1',
    'disable';

  $plugin->configure(['DEBUG=1']);
  is request_line($c->written),
    'POST /v1.41/plugins/vieux/sshfs:latest/set HTTP/1.1', 'configure';
  is_deeply decode_json(request_body($c->written)), ['DEBUG=1'],
    'and the settings survive the extra hop as an array';

  $plugin->upgrade(privileges => $PRIVILEGES);
  is request_line($c->written),
    'POST /v1.41/plugins/vieux/sshfs:latest/upgrade?remote=vieux/sshfs:latest'
    . ' HTTP/1.1',
    'upgrade: remote defaults to the local name, which is why the entity '
    . 'carries plugin_reference for the renamed case';
  is_deeply decode_json(request_body($c->written)), $PRIVILEGES,
    'the privilege body is not swallowed by the delegation';

  # The socket is an in-memory sink; this reaches no registry, and there is
  # no live variant of this call anywhere in the suite.
  $plugin->push;
  is request_line($c->written),
    'POST /v1.41/plugins/vieux/sshfs:latest/push HTTP/1.1',
    'push, which shadows the builtin in both packages and is only ever '
    . 'called as a method';

  $plugin->remove(force => 1);
  is request_line($c->written),
    'DELETE /v1.41/plugins/vieux/sshfs:latest?force=1 HTTP/1.1', 'remove';
};

subtest 'remove: force is normalised to 1/0 and omitted when unset' => sub {
  my $c = fake_client('');
  $c->plugins->remove('vieux/sshfs:latest');
  is request_line($c->written),
    'DELETE /v1.41/plugins/vieux/sshfs:latest HTTP/1.1',
    'no force parameter when the caller passed none';

  $c->plugins->remove('vieux/sshfs:latest', force => 1);
  is query_param($c->written, 'force'), '1', 'force => 1';

  $c->plugins->remove('vieux/sshfs:latest', force => 0);
  is query_param($c->written, 'force'), '0',
    'an explicit false is still sent, as 0';
};

# ---------------------------------------------------------------------------
subtest 'enable: timeout is always sent' => sub {
  my $c = fake_client('');
  $c->plugins->enable('vieux/sshfs:latest');

  is request_line($c->written),
    'POST /v1.41/plugins/vieux/sshfs:latest/enable?timeout=0 HTTP/1.1',
    'timeout=0 is sent even though the caller passed no timeout';

  # This is not tidiness. The daemon reads the raw query value and parses it
  # with Go's strconv.Atoi, with no default: an absent timeout is parsed as
  # the empty string and the request fails with
  # `strconv.Atoi: parsing "": invalid syntax`. Making this parameter
  # conditional, the way force and filters are, would break every enable.
  $c->plugins->enable('vieux/sshfs:latest', timeout => 30);
  is query_param($c->written, 'timeout'), '30', 'an explicit timeout is used';

  $c->plugins->enable('vieux/sshfs:latest', timeout => 0);
  is query_param($c->written, 'timeout'), '0', 'an explicit 0 stays 0';
};

subtest 'disable: force is optional' => sub {
  my $c = fake_client('');
  $c->plugins->disable('vieux/sshfs:latest');
  is request_line($c->written),
    'POST /v1.41/plugins/vieux/sshfs:latest/disable HTTP/1.1',
    'no force parameter by default';

  $c->plugins->disable('vieux/sshfs:latest', force => 1);
  is query_param($c->written, 'force'), '1', 'force => 1';
};

# ---------------------------------------------------------------------------
subtest 'privileges: remote in the query, list in the response' => sub {
  my $c = fake_client(JSON::MaybeXS->new->encode($PRIVILEGES));
  my $got = $c->plugins->privileges('vieux/sshfs');

  is request_line($c->written),
    'GET /v1.41/plugins/privileges?remote=vieux/sshfs HTTP/1.1',
    'remote is a query parameter, and its slash is not escaped';
  is_deeply $got, $PRIVILEGES, 'the privilege list comes back as an ArrayRef';
  unlike $c->written, qr/X-Registry-Auth/i,
    'no auth header without auth: the plugin router discards an '
    . 'undecodable one, so anonymous needs none';
};

subtest 'privileges: a plugin that demands nothing answers null' => sub {
  # computePrivileges starts from `var privileges types.PluginPrivileges` and
  # appends only what the config asks for, so a plugin needing nothing sends
  # a nil Go slice, which marshals to a bare `null`.
  my $c = fake_client('null');

  # karr k30 (fixed): the transport used to decode a body only when it
  # started with { or [, so a bare JSON scalar came back as its own bytes --
  # the four-character string 'null'. It now decodes any JSON body, scalars
  # included, so this comes back as undef, same as decode_json('null') would.
  is $c->get('/plugins/privileges', params => { remote => 'x' }), undef,
    'the transport decodes the bare null to undef (karr k30)';

  # Unguarded, that undef would be POSTed to /plugins/pull as a JSON null
  # where the engine expects an array.
  is_deeply $c->plugins->privileges('vieux/sshfs'), [],
    'privileges normalises it to the empty list it means';
};

subtest 'privileges: auth is sent as padded base64url X-Registry-Auth' => sub {
  my $c = fake_client('[]');
  $c->plugins->privileges('private.example.com/p/sshfs',
    auth => { username => 'me', password => 'secret' });

  my ($hdr) = $c->written =~ /^X-Registry-Auth: (\S+)\r$/m;
  ok defined $hdr, 'header present when auth was given';
  is length($hdr) % 4, 0, 'padded, as Go base64.URLEncoding requires';
  is_deeply decode_json(b64url_decode($hdr)),
    { username => 'me', password => 'secret' },
    'header decodes to the credentials passed';
};

# ---------------------------------------------------------------------------
subtest 'install: the privilege list is the request body' => sub {
  my $c = fake_client(qq({"status":"Pulling plugin"}\n));
  my $events = $c->plugins->install('vieux/sshfs:latest',
    privileges => $PRIVILEGES);

  like request_line($c->written), qr{\APOST /v1\.41/plugins/pull\?},
    'install is POST /plugins/pull';
  is query_param($c->written, 'remote'), 'vieux/sshfs:latest',
    'remote is a query parameter';
  like $c->written, qr{^Content-Type: application/json\r$}m,
    'the body is JSON, not a tarball';
  is_deeply decode_json(request_body($c->written)), $PRIVILEGES,
    'the privileges go back to the engine verbatim -- it compares them '
    . 'against what the plugin demands and refuses a mismatch';

  is_deeply $events, [ { status => 'Pulling plugin' } ],
    'the NDJSON progress stream comes back as an ArrayRef of events';
};

subtest 'install: local name and auth' => sub {
  my $c = fake_client(qq({"status":"Pulling plugin"}\n));
  $c->plugins->install('vieux/sshfs:latest',
    privileges => [],
    name       => 'sshfs',
    auth       => { identitytoken => 'tok-123' },
  );

  is query_param($c->written, 'name'), 'sshfs', 'local name sent';
  is request_body($c->written), '[]',
    'an empty privilege list is sent as an empty JSON array, not omitted';
  my ($hdr) = $c->written =~ /^X-Registry-Auth: (\S+)\r$/m;
  is_deeply decode_json(b64url_decode($hdr)), { identitytoken => 'tok-123' },
    'identitytoken auth reaches the header';
};

subtest 'install: a failure inside the 200 stream croaks' => sub {
  my $c = fake_client(
    qq({"status":"Pulling plugin"}\n)
    . qq({"errorDetail":{"message":"incorrect privileges"},"error":"incorrect privileges"}\n)
  );

  eval {
    $c->plugins->install('vieux/sshfs:latest', privileges => []);
    1;
  };
  my $err = $@;
  ok $err, 'a failed install does not return quietly';
  like "$err", qr/incorrect privileges/,
    'the engine reason survives into the exception';
  isa_ok $err, 'API::Docker::Error::Stream';
  is_deeply [ map { $_->{status} } grep { $_->{status} } @{ $err->events } ],
    ['Pulling plugin'], 'the progress that preceded the failure is kept';
};

subtest 'install: accept_privileges resolves both calls' => sub {
  my $docker = API::Docker->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  my @calls;
  no warnings 'redefine';
  local *API::Docker::_request = sub {
    my ($self, $method, $path, %opts) = @_;
    push @calls, { method => $method, path => $path, %opts };
    return $PRIVILEGES if $path eq '/plugins/privileges';
    return [];
  };

  $docker->plugins->install('vieux/sshfs:latest', accept_privileges => 1);

  is scalar @calls, 2, 'two requests, not one';
  is $calls[0]{path}, '/plugins/privileges', 'privileges are fetched first';
  is $calls[0]{params}{remote}, 'vieux/sshfs:latest',
    'for the reference being installed';
  is $calls[1]{path}, '/plugins/pull', 'then the install';
  is_deeply $calls[1]{body}, $PRIVILEGES,
    'and exactly what the engine reported is what gets granted';
};

subtest 'install: privileges are required, and the croak says how' => sub {
  my $docker = API::Docker->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  # No transport is faked here on purpose: nothing may reach the socket.
  eval { $docker->plugins->install('vieux/sshfs:latest') };
  my $err = $@;
  like $err, qr/requires privileges/, 'a blind install is refused';
  like $err, qr/->privileges\(/, 'the croak names the call that supplies them';
  like $err, qr/accept_privileges/, 'and the explicit blanket grant';

  eval { $docker->plugins->install('vieux/sshfs:latest', privileges => 'all') };
  like $@, qr/privileges must be an ArrayRef/,
    'a scalar is refused rather than JSON-encoded as a string';

  eval { $docker->plugins->install() };
  like $@, qr/remote reference required/, 'and the reference is required';
};

# ---------------------------------------------------------------------------
subtest 'upgrade: remote defaults to the plugin name' => sub {
  my $c = fake_client(qq({"status":"Upgrading"}\n));
  $c->plugins->upgrade('vieux/sshfs:latest', privileges => $PRIVILEGES);

  like request_line($c->written),
    qr{\APOST /v1\.41/plugins/vieux/sshfs:latest/upgrade\?},
    'POST /plugins/{name}/upgrade';
  is query_param($c->written, 'remote'), 'vieux/sshfs:latest',
    'remote defaults to the name, as the CLI does';
  is_deeply decode_json(request_body($c->written)), $PRIVILEGES,
    'the same privilege body as install';
};

subtest 'upgrade: a locally renamed plugin upgrades from its remote' => sub {
  my $c = fake_client(qq({"status":"Upgrading"}\n));
  $c->plugins->upgrade('sshfs',
    remote     => 'vieux/sshfs:v2',
    privileges => [],
  );

  like request_line($c->written), qr{\APOST /v1\.41/plugins/sshfs/upgrade\?},
    'the local name is in the path';
  is query_param($c->written, 'remote'), 'vieux/sshfs:v2',
    'the remote reference is in the query';
};

subtest 'upgrade: accept_privileges asks about the remote, not the local name' => sub {
  my $docker = API::Docker->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  my @calls;
  no warnings 'redefine';
  local *API::Docker::_request = sub {
    my ($self, $method, $path, %opts) = @_;
    push @calls, { path => $path, %opts };
    return $PRIVILEGES if $path eq '/plugins/privileges';
    return [];
  };

  $docker->plugins->upgrade('sshfs', remote => 'vieux/sshfs:v2',
    accept_privileges => 1);

  is $calls[0]{params}{remote}, 'vieux/sshfs:v2',
    'an upgrade is where the demands can change, so the new reference is '
    . 'what gets asked about';
};

subtest 'upgrade: privileges are required too' => sub {
  my $docker = API::Docker->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );
  eval { $docker->plugins->upgrade('vieux/sshfs:latest') };
  like $@, qr/upgrade requires privileges/, 'refused, naming the method';
};

# ---------------------------------------------------------------------------
subtest 'push: request assembly only' => sub {
  # This never reaches a registry -- the socket is an in-memory sink. There
  # is no live variant of this subtest and there must not be one.
  my $c = fake_client(qq({"status":"Pushing"}\n));
  $c->plugins->push('myrepo/sshfs:v1', auth => { username => 'u', password => 'p' });

  is request_line($c->written),
    'POST /v1.41/plugins/myrepo/sshfs:v1/push HTTP/1.1',
    'POST /plugins/{name}/push, no query string';
  my ($hdr) = $c->written =~ /^X-Registry-Auth: (\S+)\r$/m;
  is_deeply decode_json(b64url_decode($hdr)), { username => 'u', password => 'p' },
    'credentials in X-Registry-Auth, which the reference does not document '
    . 'on this endpoint but the daemon reads';
};

subtest 'push: anonymous sends no auth header' => sub {
  my $c = fake_client(qq({"status":"Pushing"}\n));
  $c->plugins->push('myrepo/sshfs:v1');
  unlike $c->written, qr/X-Registry-Auth/i,
    'unlike images->push, which must always send one';
};

# ---------------------------------------------------------------------------
subtest 'configure: settings are a JSON array of strings' => sub {
  my $c = fake_client('');
  $c->plugins->configure('vieux/sshfs:latest', ['DEBUG=1', 'sshkey.source=/tmp']);

  is request_line($c->written),
    'POST /v1.41/plugins/vieux/sshfs:latest/set HTTP/1.1',
    'POST /plugins/{name}/set';
  is_deeply decode_json(request_body($c->written)),
    ['DEBUG=1', 'sshkey.source=/tmp'], 'body is the settings array';

  $c->plugins->configure('vieux/sshfs:latest', 'DEBUG=1');
  is_deeply decode_json(request_body($c->written)), ['DEBUG=1'],
    'a bare list is accepted and still sent as an array, so a single '
    . 'setting cannot become a JSON string by accident';
};

subtest 'configure: validation' => sub {
  my $docker = API::Docker->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  eval { $docker->plugins->configure('vieux/sshfs:latest') };
  like $@, qr/requires at least one setting/, 'no settings is refused';

  eval { $docker->plugins->configure('vieux/sshfs:latest', []) };
  like $@, qr/requires at least one setting/, 'an empty ArrayRef too';

  eval { $docker->plugins->configure('vieux/sshfs:latest', { DEBUG => 1 }) };
  like $@, qr/settings must be plain strings/,
    'a HashRef is refused rather than encoded as an object';

  eval { $docker->plugins->configure() };
  like $@, qr/plugin name required/, 'and the name is required';
};

# ---------------------------------------------------------------------------
subtest 'every name-taking method croaks without a name' => sub {
  my $docker = API::Docker->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  for my $method (qw( inspect remove enable disable push )) {
    eval { $docker->plugins->$method(undef) };
    like $@, qr/plugin name required/, "$method croaks on an undefined name";
  }

  eval { $docker->plugins->upgrade(undef, privileges => []) };
  like $@, qr/plugin name required/, 'upgrade croaks on an undefined name';

  eval { $docker->plugins->privileges(undef) };
  like $@, qr/remote reference required/,
    'privileges croaks on an undefined remote';
};

done_testing;
