#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;
use API::Docker;

# What the `filters` query parameter looks like on the wire, and what shapes
# API::Docker::Role::Filters refuses to put there.
#
# Nothing here opens a socket or reaches a daemon, in either mode.
# Test::API::Docker::Mock is deliberately not used: under API_DOCKER_TEST_HOST
# it ignores its route table and hands back a real client, and almost
# everything asserted below is a property of the *outgoing* request, which no
# response can show. The daemon is faked under the socket instead, so the
# assertions hold on a machine with a daemon and on one without.
#
# The shapes come from measuring rootless Podman 5.4.2 (API 1.41) on
# 2026-08-27, GET /v1.41/images/json with a hand-built query string:
#
#   {"dangling":["true"]}   200, the dangling images
#   {"dangling":"true"}     500 json: cannot unmarshal string into Go value
#                               of type []string
#   {"dangling":true}       500 json: cannot unmarshal bool into Go value of
#                               type []string
#   {"dangling":[true]}     500 json: cannot unmarshal bool into Go value of
#                               type string
#   {"dangling":[1]}        500 json: cannot unmarshal number into Go value
#                               of type string
#   {"dangling":[null]}     500 non-boolean value ... strconv.ParseBool:
#                               parsing "" -- Go reads a JSON null into a
#                               string as ""
#   {"dangling":[""]}       500, the same message
#   {"dangling":["1"]}      200, and so do "0", "true" and "false"

# ---------------------------------------------------------------------------
# A client whose socket is an in-memory sink and whose response is canned, so
# _request assembles a real request line and query string with nothing on the
# other end. Same pattern as t/plugins.t and t/role_http.t.
package Test::Filters::FakeTransport;
use Moo;
extends 'API::Docker';

has canned => (is => 'rw', default => sub { [200, 'OK', {}, '[]'] });
has _sink  => (is => 'rw');

sub _build__socket {
  my ($self) = @_;
  my $sink = '';
  $self->_sink(\$sink);
  open my $fh, '>', \$sink or die "open: $!";
  return $fh;
}

sub _read_response { return $_[0]->canned }

# The socket is lazy, so an unbuilt sink is the literal "no request was ever
# assembled" -- which is what the croak subtests below assert.
sub written {
  my ($self) = @_;
  my $sink = $self->_sink;
  return defined $sink ? $$sink : '';
}

package main;

sub fake_client {
  my ($body) = @_;
  return Test::Filters::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    canned      => [200, 'OK', {}, $body // '[]'],
  );
}

sub query_param {
  my ($raw, $name) = @_;
  my ($line) = $raw =~ /\A([^\r\n]*)/;
  my ($qs)   = $line =~ /\?([^ ]*) HTTP/;
  return undef unless defined $qs;
  for my $pair (split /&/, $qs) {
    my ($k, $v) = split /=/, $pair, 2;
    next unless $k eq $name;
    $v =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
    return $v;
  }
  return undef;
}

# The JSON *text* of the filters parameter, not a decoded structure: a decoded
# ["1"] and a decoded [1] are the same Perl scalar, and the difference between
# them is the whole point of this file.
sub sent_filters {
  my ($client) = @_;
  return query_param($client->written, 'filters');
}

# ---------------------------------------------------------------------------
# The shape that reaches the wire

subtest 'the correct shape travels unchanged' => sub {
  my $c = fake_client();
  $c->images->list(filters => { dangling => ['true'] });
  is sent_filters($c), '{"dangling":["true"]}',
    'a map of string to array of string is what the engine wants, and is left alone';
};

subtest 'a bare value is wrapped into the array the engine insists on' => sub {
  my $c = fake_client();
  $c->images->list(filters => { dangling => 'true' });
  is sent_filters($c), '{"dangling":["true"]}',
    'dangling => \'true\' meant one value; before this it went out as a bare '
    . 'string and the daemon answered 500 cannot unmarshal string into []string';
};

subtest 'a JSON boolean becomes the string the engine parses' => sub {
  my $c = fake_client();
  $c->images->list(filters => { dangling => JSON->true });
  is sent_filters($c), '{"dangling":["true"]}',
    'JSON->true would otherwise be encoded as a JSON true -- 500 cannot '
    . 'unmarshal bool into []string';

  my $f = fake_client();
  $f->images->list(filters => { dangling => JSON->false });
  is sent_filters($f), '{"dangling":["false"]}', 'and JSON->false likewise';

  my $s = fake_client();
  $s->images->list(filters => { dangling => [\1, \0] });
  is sent_filters($s), '{"dangling":["true","false"]}',
    '\\1 and \\0 -- the ScalarRef form this distribution uses for JSON request '
    . 'bodies -- are read as booleans here too';
};

subtest 'a number is stringified, never rewritten as a boolean' => sub {
  my $c = fake_client();
  $c->images->search('nginx', filters => { stars => [3] });
  is sent_filters($c), '{"stars":["3"]}',
    'a number would be encoded as a JSON number -- 500 cannot unmarshal '
    . 'number into Go value of type string';

  # The reason the boolean rewrite is bound to the value's type and not to its
  # truthiness. Every one of these is a legitimate filter whose value happens
  # to look boolean, and rewriting it would silently ask a different question.
  my $e = fake_client();
  $e->containers->list(all => 1, filters => { exited => [0] });
  is sent_filters($e), '{"exited":["0"]}',
    'exited => [0] asks for containers that exited with status 0, not for false';

  my $l = fake_client();
  $l->images->list(filters => { label => [1] });
  is sent_filters($l), '{"label":["1"]}',
    'a label whose value is 1 is not the boolean true';
};

subtest 'an empty value list is a shape the engine accepts, and travels' => sub {
  my $c = fake_client();
  $c->images->list(filters => { label => [] });
  is sent_filters($c), '{"label":[]}',
    'measured: Podman answers 200 and filters nothing, so it is not this '
    . 'role\'s place to refuse it';
};

subtest 'no filters option means no filters parameter' => sub {
  my $c = fake_client();
  $c->images->list(all => 1);
  is sent_filters($c), undef, 'no key invented';
  like $c->written, qr/\?all=1 HTTP/, 'and the rest of the query string is untouched';
};

subtest 'the caller\'s HashRef is not modified' => sub {
  my $c = fake_client();
  my $filters = { dangling => 'true', stars => [3] };
  $c->images->list(filters => $filters);
  is_deeply $filters, { dangling => 'true', stars => [3] },
    'normalisation builds a new HashRef; the caller keeps what they passed';
};

# ---------------------------------------------------------------------------
# The shapes that now croak
#
# The headline case: each of these used to be assembled into a query string
# and sent, and the canned 200 below is a perfectly plausible answer. The
# caller got that answer back with no signal that the filter had not been
# applied. Now the call never happens.

my $PLAUSIBLE = '[{"Id":"sha256:aaa","RepoTags":["alpine:3"]},'
  . '{"Id":"sha256:bbb","RepoTags":["nginx:latest"]}]';

subtest 'a shape the daemon cannot read is refused before the request' => sub {
  for my $case (
    [ 'a HashRef value',       { dangling => {} },        qr/HASH reference as a value/ ],
    [ 'a nested ArrayRef',     { label => [['a']] },      qr/ARRAY reference as a value/ ],
    [ 'undef',                 { dangling => undef },     qr/undefined value/ ],
    [ 'undef inside the list', { dangling => [undef] },   qr/undefined value/ ],
    [ 'the empty string',      { dangling => '' },        qr/empty value/ ],
    [ 'a ScalarRef that is not \\1 or \\0', { dangling => \'maybe' },
      qr/ScalarRef to something other than 1 or 0/ ],
    [ 'an empty filter name',  { '' => ['x'] },           qr/name must not be empty/ ],
  ) {
    my ($what, $filters, $like) = @$case;
    my $c = fake_client($PLAUSIBLE);
    my $result = eval { $c->images->list(filters => $filters) };
    like $@, $like, $what . ' croaks, naming what is wrong';
    is $result, undef, $what . ': nothing plausible comes back instead';
    is $c->written, '', $what . ': and nothing was sent';
  }
};

subtest 'filters itself must be a HashRef' => sub {
  for my $bad ('dangling=true', ['dangling'], \1) {
    my $c = fake_client($PLAUSIBLE);
    eval { $c->images->list(filters => $bad) };
    like $@, qr/filters must be a HashRef/,
      'a ' . (ref($bad) ? ref($bad) . 'Ref' : 'plain string') . ' is not a filter map';
    is $c->written, '', 'and nothing was sent';
  }
};

# ---------------------------------------------------------------------------
# One helper, every call site
#
# The point of putting this in a role rather than in each method: the twelve
# places that accept `filters` normalise it the same way. A method added later
# that forwards $opts{filters} raw shows up here as a test that does not croak.

subtest 'every method that takes filters goes through the role' => sub {
  my $c = fake_client('{}');
  my $bad = { dangling => undef };

  my @calls = (
    [ 'containers->list'  => sub { $c->containers->list(filters => $bad) } ],
    [ 'containers->prune' => sub { $c->containers->prune(filters => $bad) } ],
    [ 'images->list'      => sub { $c->images->list(filters => $bad) } ],
    [ 'images->search'    => sub { $c->images->search('nginx', filters => $bad) } ],
    [ 'images->prune'     => sub { $c->images->prune(filters => $bad) } ],
    [ 'images->build_prune' => sub { $c->images->build_prune(filters => $bad) } ],
    [ 'networks->list'    => sub { $c->networks->list(filters => $bad) } ],
    [ 'networks->prune'   => sub { $c->networks->prune(filters => $bad) } ],
    [ 'volumes->list'     => sub { $c->volumes->list(filters => $bad) } ],
    [ 'volumes->prune'    => sub { $c->volumes->prune(filters => $bad) } ],
    [ 'system->events'    => sub { $c->system->events(until => 1, filters => $bad) } ],
    [ 'secrets->list'     => sub { $c->secrets->list(filters => $bad) } ],
    [ 'configs->list'     => sub { $c->configs->list(filters => $bad) } ],
    [ 'plugins->list'     => sub { $c->plugins->list(filters => $bad) } ],
  );

  for my $call (@calls) {
    my ($name, $code) = @$call;
    eval { $code->() };
    like $@, qr/_normalise_filters/, $name . ' normalises its filters';
  }
};

subtest 'the role is composed, not copied' => sub {
  for my $resource (qw( containers images networks volumes system secrets configs plugins )) {
    my $class = 'API::Docker::API::' . ucfirst $resource;
    ok $class->DOES('API::Docker::Role::Filters'),
      $class . ' composes API::Docker::Role::Filters';
  }
};

done_testing;
