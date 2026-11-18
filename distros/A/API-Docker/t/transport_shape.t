#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw( decode_json );
use API::Docker;

# What _request hands back, and what it puts on the wire, for the three cases
# the buffered path used to get wrong:
#
#   karr k30  a body that is a bare JSON scalar came back as its own bytes,
#             so `null` was the four-character string 'null'
#   karr k33  a params value could only ever be one k=v pair, so an ArrayRef
#             stringified to ARRAY(0x...) and `names=a&names=b` was unsayable
#   karr k34  an empty body returned undef above the raw and ndjson branches,
#             breaking both of their documented shapes -- and raw_body was
#             tested for truth, so an empty archive and the string '0' were
#             dropped from the request entirely
#
# Nothing here connects: the socket is an in-memory sink and the response is
# canned, so this file is safe with no daemon and needs no live gating.

package Test::TransportShape::FakeTransport;
use Moo;
extends 'API::Docker';

has canned => (is => 'rw', default => sub { [200, 'OK', {}, ''] });
has _sink  => (is => 'rw');

sub _build__socket {
  my ($self) = @_;
  my $sink = '';
  $self->_sink(\$sink);
  open my $fh, '>', \$sink or die "open: $!";
  return $fh;
}

sub _read_response { return $_[0]->canned }

sub written { return ${ $_[0]->_sink } }

sub request_line {
  my ($line) = $_[0]->written =~ /\A([^\r\n]*)/;
  return $line;
}

sub request_body {
  my ($body) = $_[0]->written =~ /\r\n\r\n(.*)\z/s;
  return $body;
}

package main;

sub fake_client {
  my ($body, $status) = @_;
  return Test::TransportShape::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    canned      => [$status // 200, $status && $status == 204 ? 'No Content' : 'OK',
      {}, $body],
  );
}

# ===========================================================================
# karr k30 -- a bare JSON scalar is a JSON value like any other
# ===========================================================================

subtest 'a body that is a JSON scalar is decoded, not returned as bytes' => sub {
  is fake_client('null')->get('/x'), undef,
    'null decodes to undef, not to the string "null"';

  my $true = fake_client('true')->get('/x');
  ok $true, 'true is true';
  is "$true", '1', 'and is the JSON boolean, which stringifies to 1';

  my $false = fake_client('false')->get('/x');
  ok defined $false, 'false is a value, not an absence';
  ok !$false, 'and it is false';

  is fake_client('42')->get('/x'), 42, 'a bare number';
  is fake_client('-1.5')->get('/x'), -1.5, 'a negative one';
  is fake_client('"hello"')->get('/x'), 'hello',
    'a quoted string, without its quotes';
  is fake_client(qq{  null\n})->get('/x'), undef,
    'leading whitespace and a trailing newline do not stop it';
};

subtest 'the two endpoints that send a bare null' => sub {
  # computePrivileges starts from a `var privileges types.PluginPrivileges`
  # and appends only what the plugin config asks for, so a plugin needing
  # nothing marshals a nil Go slice. GET /containers/{id}/changes does the
  # same for a container that changed nothing. Both are documented as
  # returning an ArrayRef, and both used to hand over 'null' instead -- which
  # /plugins/pull would then have been POSTed as a JSON string where the
  # engine expects an array.
  is fake_client('null')->get('/plugins/privileges', params => { remote => 'x' }),
    undef, 'GET /plugins/privileges: null is undef, which is not iterable-looking';
  is fake_client('null')->get('/containers/deadbeef/changes'), undef,
    'GET /containers/{id}/changes: the same';
};

subtest 'a body that is not JSON is still returned as itself' => sub {
  # GET /_ping answers with the two bytes OK and no JSON anywhere.
  is fake_client('OK')->get('/_ping'), 'OK', 'the ping body survives';

  # The eval decides, not the pattern: these start with a character the
  # pattern lets through and are not JSON.
  is fake_client('null pointer dereference')->get('/x'),
    'null pointer dereference', 'a sentence starting with null';
  is fake_client('42 things happened')->get('/x'), '42 things happened',
    'a sentence starting with a digit';
  is fake_client('{not json')->get('/x'), '{not json',
    'and a body that only looks like an object';
};

subtest 'raw is still bytes, whatever they spell' => sub {
  is fake_client('null')->get('/x', raw => 1), 'null',
    'raw => 1 hands back the four characters, decoding nothing';
};

# ===========================================================================
# karr k33 -- an ArrayRef param is the same parameter given more than once
# ===========================================================================

subtest 'an ArrayRef param expands to repeated pairs' => sub {
  my $c = fake_client('');
  $c->get('/images/get', params => { names => ['alpine:3', 'registry:2'] });

  is $c->request_line,
    'GET /v1.41/images/get?names=alpine:3&names=registry:2 HTTP/1.1',
    'one names= pair per element, and the reference colon is left raw';
};

subtest 'element order is the caller\'s, key order is sorted' => sub {
  my $c = fake_client('');
  $c->get('/x', params => { z => 1, names => ['b', 'a'], a => 2 });

  is $c->request_line, 'GET /v1.41/x?a=2&names=b&names=a&z=1 HTTP/1.1',
    'keys sorted, but b still precedes a inside the list';
};

subtest 'the elements are escaped the way a single value is' => sub {
  my $c = fake_client('');
  $c->get('/images/get', params => { names => ['my repo/img:1', 'a&b=c'] });

  is $c->request_line,
    'GET /v1.41/images/get?names=my%20repo/img:1&names=a%26b%3Dc HTTP/1.1',
    'a space, an ampersand and an equals sign are encoded; / and : are not';
};

subtest 'the empty and undef corners of a list' => sub {
  my $c = fake_client('');
  $c->get('/images/get', params => { names => [] });
  is $c->request_line, 'GET /v1.41/images/get HTTP/1.1',
    'an empty ArrayRef appends no query string at all, not a bare ?';

  $c = fake_client('');
  $c->get('/x', params => { names => ['a', undef, 'b'] });
  is $c->request_line, 'GET /v1.41/x?names=a&names=b HTTP/1.1',
    'an undef element is skipped, like an undef value is';
};

subtest 'a scalar and a HashRef param are unchanged' => sub {
  my $c = fake_client('');
  $c->get('/containers/json', params => { all => 1, filters => { status => ['running'] } });

  is $c->request_line,
    'GET /v1.41/containers/json?all=1&filters=%7B%22status%22:%5B%22running%22%5D%7D HTTP/1.1',
    'a scalar stays one pair and a HashRef is still JSON-encoded; the colon in the JSON is left raw, like every other colon';

  $c = fake_client('');
  $c->get('/x', params => { f => [ { a => 1 }, { b => 2 } ] });
  my ($qs) = $c->request_line =~ /\?(\S+) HTTP/;
  my @encoded = map { my ($v) = /^f=(.*)$/; $v =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge; $v }
    split /&/, $qs;
  is_deeply [ map { decode_json($_) } @encoded ], [ { a => 1 }, { b => 2 } ],
    'a HashRef inside a list is JSON-encoded per element, same rule';
};

# ===========================================================================
# karr k34 -- zero bytes is a different answer in each shape
# ===========================================================================

subtest 'an empty body keeps the shape the caller asked for' => sub {
  my $raw = fake_client('')->get('/images/get', raw => 1);
  is $raw, '', 'raw => 1 returns the empty string, not undef';
  is length($raw), 0, 'so length() reads 0 instead of warning on undef';

  my $events = fake_client('')->post('/images/load', undef, ndjson => 1);
  is ref $events, 'ARRAY', 'ndjson => 1 returns an ArrayRef';
  is scalar @$events, 0, 'an empty one, for a stream that carried nothing';

  is fake_client('')->get('/x'), undef,
    'with neither option there is nothing to hand back, so undef';
};

subtest 'a 204 is taken at its word' => sub {
  is fake_client('', 204)->post('/containers/deadbeef/start'), undef,
    'no body, no option: undef';
  is fake_client('should not be here', 204)->get('/x'), undef,
    'and bytes after a 204 do not change that';

  is fake_client('', 204)->get('/x', raw => 1), '',
    'raw => 1 answers before the status check, so zero bytes is ""';
};

subtest 'an undef body is the same as an empty one' => sub {
  # _read_body can hand back undef where a daemon closes with nothing at all.
  my $c = Test::TransportShape::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    canned      => [200, 'OK', {}, undef],
  );
  is $c->get('/x', raw => 1), '', 'raw => 1 still returns a string';

  $c->canned([200, 'OK', {}, undef]);
  is_deeply $c->get('/x', ndjson => 1), [], 'ndjson => 1 still returns a list';

  $c->canned([200, 'OK', {}, undef]);
  is $c->get('/x'), undef, 'and the plain path still returns undef';
};

subtest 'raw_body is sent when it is defined, not when it is true' => sub {
  my $c = fake_client('');
  $c->post('/build', undef, raw_body => '', content_type => 'application/x-tar');

  like $c->written, qr/^Content-Length: 0\r$/m,
    'an empty archive announces its length';
  like $c->written, qr{^Content-Type: application/x-tar\r$}m,
    'and its content type, rather than falling through to the JSON branch';
  is $c->request_body, '', 'with no payload after the blank line';

  $c = fake_client('');
  $c->post('/build', undef, raw_body => '0');
  like $c->written, qr/^Content-Length: 1\r$/m, 'a body of "0" is one byte';
  is $c->request_body, '0', 'and the byte actually goes out';
};

subtest 'a request with no body announces none' => sub {
  my $c = fake_client('');
  $c->get('/containers/json');
  unlike $c->written, qr/^Content-Length:/m, 'no Content-Length';
  unlike $c->written, qr/^Content-Type:/m, 'no Content-Type';
  is $c->request_body, '', 'and nothing after the blank line';
};

done_testing;
