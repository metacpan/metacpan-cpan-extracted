#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use JSON::MaybeXS qw( decode_json );
use API::Docker;
use Test::API::Docker::FakeTransport;

# POST /auth -- checking a set of registry credentials without pulling or
# pushing anything (karr k17).
#
# Nothing here performs a login, in either mode. No credential in this file
# is real and no request leaves the process: the daemon is faked below the
# socket so _request assembles a real request line, headers and body with
# nothing on the other end, and the assertions read what would have gone on
# the wire. That is the whole of what this method decides -- the outcome is
# the registry's to give.
#
# The canned success body is the Engine API reference's own example payload,
# and the canned failure bodies are captures from the rootless Podman socket
# (5.4.2, API 1.41), taken with an unreachable serveraddress so that no
# registry was ever asked about anyone's credentials:
#
#   POST /v1.41/auth {"username":"nobody","password":"nothing",
#                     "serveraddress":"127.0.0.1:1"}
#   -> 500 {"message":"login attempt to 127.0.0.1:1 failed with status:
#           authenticating creds for \"127.0.0.1:1\": pinging container
#           registry 127.0.0.1:1: Get \"https://127.0.0.1:1/v2/\": dial tcp
#           127.0.0.1:1: connect: connection refused"}
#
# Note the 500: Podman does not answer a failed check with Docker's 401. The
# croak is what both engines have in common, which is why this file asserts
# the croak and not the number.

# The socket is built lazily by the first request, so a call that croaked
# before sending has no sink at all -- which is itself the assertion in
# several subtests below. Test::API::Docker::FakeTransport's ->written
# guards for exactly that.
my $SUCCESS = '{"Status":"Login Succeeded","IdentityToken":""}';

sub fake_client {
  my ($body, $status) = @_;
  return Test::API::Docker::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    canned      => [$status // 200, 'OK', {}, $body // $SUCCESS],
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

my $CREDS = {
  username      => 'me',
  password      => 'secret',
  serveraddress => 'ghcr.io',
};

# ---------------------------------------------------------------------------
subtest 'the credentials go in the body, not in a header' => sub {
  my $c = fake_client();
  my $out = $c->system->auth(%$CREDS);

  is request_line($c->written), 'POST /v1.41/auth HTTP/1.1',
    'POST /auth, no query string';
  is_deeply decode_json(request_body($c->written)), $CREDS,
    'the AuthConfig is the JSON request body';

  # The same object push carries in X-Registry-Auth, but /auth is the one
  # endpoint that takes it unencoded -- a header here would be ignored.
  unlike $c->written, qr/X-Registry-Auth/i,
    'no X-Registry-Auth header on this endpoint';
  like $c->written, qr{Content-Type: application/json\r\n},
    'sent as JSON';

  is_deeply $out, { Status => 'Login Succeeded', IdentityToken => '' },
    'the decoded engine answer is returned unwrapped';
};

# ---------------------------------------------------------------------------
subtest 'the auth argument push takes is accepted here too' => sub {
  # The point of the second spelling: a caller can hand over exactly what it
  # was about to push with, without taking it apart first.
  my $c = fake_client();
  $c->system->auth(auth => $CREDS);
  is_deeply decode_json(request_body($c->written)), $CREDS,
    'a HashRef reaches the body as itself';

  my $encoded = $c->system->_registry_auth_header($CREDS);
  my $b = fake_client();
  $b->system->auth(auth => $encoded);
  is_deeply decode_json(request_body($b->written)), $CREDS,
    'and an already-encoded X-Registry-Auth value is decoded back into it';

  my $j = fake_client();
  $j->system->auth(auth => '{"identitytoken":"tok-123"}');
  is_deeply decode_json(request_body($j->written)), { identitytoken => 'tok-123' },
    'as is a raw JSON AuthConfig';
};

# ---------------------------------------------------------------------------
subtest 'the two spellings may not be mixed' => sub {
  # Not a style rule: picking one silently would be picking which of two sets
  # of credentials gets sent.
  my $c = fake_client();
  ok !eval { $c->system->auth(auth => $CREDS, username => 'other'); 1 },
    'auth => $config beside a credential key croaks';
  like $@, qr/not both/, 'and says which keys were seen';
  is $c->written, '', 'nothing was sent';
};

# ---------------------------------------------------------------------------
subtest 'a check with nothing to check croaks before the request' => sub {
  my $c = fake_client();
  ok !eval { $c->system->auth; 1 }, 'no arguments croaks';
  like $@, qr/requires credentials/, 'and says what is missing';
  is $c->written, '', 'nothing was sent';

  my $e = fake_client();
  ok !eval { $e->system->auth(auth => {}); 1 },
    'an empty AuthConfig croaks too';
  is $e->written, '', 'nothing was sent';

  # Stricter than the engine on purpose: Podman answers the empty body with
  # 500 'getting username and password: cannot prompt for username without
  # stdin', which describes the daemon's stdin rather than the caller's bug.
};

# ---------------------------------------------------------------------------
subtest 'only identitytoken is enough' => sub {
  my $c = fake_client();
  $c->system->auth(identitytoken => 'tok-123', serveraddress => 'ghcr.io');
  is_deeply decode_json(request_body($c->written)),
    { identitytoken => 'tok-123', serveraddress => 'ghcr.io' },
    'a token-only AuthConfig is a complete one';
};

# ---------------------------------------------------------------------------
subtest 'a rejected credential croaks, and the status is still readable' => sub {
  # Docker's answer: 401 with {"message":...}.
  my $c = fake_client('{"message":"Get \"https://ghcr.io/v2/\": unauthorized"}', 401);
  my %res;
  ok !eval { $c->system->auth(%$CREDS, response => \%res); 1 },
    'a 401 croaks rather than returning a false value';
  like $@, qr/unauthorized/, 'the registry message survives into the croak';
  is $res{status}, 401,
    'response is filled before the croak, so an eval-ing caller can tell '
    . 'a rejected credential from an unreachable registry';

  # Podman's answer to the same failure: 500, measured -- see the header
  # comment. A caller testing for 401 would call this a success.
  my $p = fake_client(
    '{"message":"login attempt to ghcr.io failed with status: '
    . 'authenticating creds for \"ghcr.io\": pinging container registry"}', 500);
  my %pres;
  ok !eval { $p->system->auth(%$CREDS, response => \%pres); 1 },
    'Podman 500 croaks the same way';
  is $pres{status}, 500, 'and reports its own status';
};

done_testing;
