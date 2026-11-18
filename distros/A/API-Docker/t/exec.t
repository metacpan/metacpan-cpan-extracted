#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;

# API::Docker::API::Exec had no per-resource test file of its own (karr
# k109): create's boolean normalisation is covered in t/json_body_booleans.t
# (k100), and resize's query string is covered at the wire level in
# t/containers_endpoints.t, but create's full request shape and inspect's
# forwarding were never asserted anywhere -- t/timeout_forwarding.t only
# proves that a read_timeout/connect_timeout bound reaches inspect's
# request, not that inspect does anything sensible with what it gets back.

check_live_access();

subtest 'create posts to the container\'s own endpoint with the full config body' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();

  my ($method_seen, $body);
  my $docker = test_docker(
    'POST /containers/deadbeef/exec' => sub {
      my ($method, $path, %opts) = @_;
      $method_seen = $method;
      $body        = $opts{body};
      return { Id => 'exec1' };
    },
  );

  my $result = $docker->exec->create('deadbeef',
    Cmd          => ['/bin/sh', '-c', 'echo hi'],
    Env          => ['FOO=bar'],
    User         => 'root',
    AttachStdout => 1,
    AttachStderr => 1,
  );

  is($method_seen, 'POST', 'create posts');
  is_deeply($result, { Id => 'exec1' }, 'the daemon response is returned unwrapped');
  is_deeply($body->{Cmd}, ['/bin/sh', '-c', 'echo hi'], 'Cmd reached the body');
  is_deeply($body->{Env}, ['FOO=bar'], 'and Env beside it');
  is($body->{User}, 'root', 'and a plain scalar field');
};

subtest 'create requires a container id and a Cmd' => sub {
  my $docker = test_docker();

  eval { $docker->exec->create(undef, Cmd => ['true']) };
  like($@, qr/Container ID required/, 'croak on missing container id');

  eval { $docker->exec->create('deadbeef') };
  like($@, qr/Cmd required/, 'croak on missing Cmd');
};

subtest 'inspect forwards to /exec/{id}/json and returns the raw response' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();

  my $docker = test_docker(
    'GET /exec/exec1/json' => {
      ID       => 'exec1',
      Running  => 0,
      ExitCode => 0,
    },
  );

  my $info = $docker->exec->inspect('exec1');
  is_deeply($info, { ID => 'exec1', Running => 0, ExitCode => 0 },
    'exec->inspect hands back the daemon response unwrapped, unlike '
    . 'containers/images inspect which wrap into a generated type');
};

subtest 'exec ID required' => sub {
  my $docker = test_docker();

  eval { $docker->exec->inspect(undef) };
  like($@, qr/Exec ID required/, 'croak on missing id for inspect');

  eval { $docker->exec->resize(undef, h => 1, w => 1) };
  like($@, qr/Exec ID required/, 'croak on missing id for resize');
};

done_testing;
