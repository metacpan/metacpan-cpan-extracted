#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;
use JSON::MaybeXS qw( encode_json );

# k100: the engine type-checks a JSON request body and rejects a number where a
# boolean field is declared -- measured non-mutating, `POST
# /containers/no-such/exec` with {"AttachStdout":1} answered 400 on Docker
# 29.7.2 and 500 on Podman 5.8.4 with Go's "cannot unmarshal number into ... of
# type bool", while `true` was accepted. So a caller's 1/0 must reach the wire
# as JSON true/false. These tests encode the body exactly as the transport does
# (JSON::MaybeXS::encode_json, which turns \1/\0 into true/false) and assert on
# the bytes -- returning `1/0` on the wire (the old logic) makes them red.

subtest 'exec->create sends booleans as JSON true/false' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();
  my $body;
  my $docker = test_docker(
    'POST /containers/test/exec' => sub {
      my ($method, $path, %opts) = @_;
      $body = $opts{body};
      return { Id => 'exec123' };
    },
  );

  $docker->exec->create('test',
    Cmd          => ['true'],
    AttachStdout => 1,
    AttachStderr => 0,
    Tty          => 1,
  );

  my $json = encode_json($body);
  like($json, qr/"AttachStdout":true/,  'AttachStdout => 1 goes out as true');
  like($json, qr/"AttachStderr":false/, 'AttachStderr => 0 goes out as false');
  like($json, qr/"Tty":true/,           'Tty => 1 goes out as true');
  unlike($json, qr/"AttachStdout":[01]/, 'no bare 1/0 for a boolean field');
};

subtest 'containers->create sends booleans as JSON true/false' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();
  my $body;
  my $docker = test_docker(
    'POST /containers/create' => sub {
      my ($method, $path, %opts) = @_;
      $body = $opts{body};
      return { Id => 'c123', Warnings => [] };
    },
  );

  my %host_config = ( Privileged => 1, AutoRemove => 0 );
  $docker->containers->create(
    Image      => 'alpine:3',
    Tty        => 1,
    OpenStdin  => 0,
    HostConfig => \%host_config,
  );

  my $json = encode_json($body);
  like($json, qr/"Tty":true/,       'top-level Tty => 1 goes out as true');
  like($json, qr/"OpenStdin":false/, 'top-level OpenStdin => 0 goes out as false');
  like($json, qr/"Privileged":true/, 'nested HostConfig.Privileged => 1 goes out as true');
  like($json, qr/"AutoRemove":false/, 'nested HostConfig.AutoRemove => 0 goes out as false');
  unlike($json, qr/"(?:Tty|OpenStdin|Privileged|AutoRemove)":[01]/,
    'no bare 1/0 for any boolean field');

  # The caller's own nested HashRef must not be mutated by the normalisation.
  is($host_config{Privileged}, 1, "caller's HostConfig hashref is left untouched");
};

subtest 'a caller-supplied JSON boolean is passed through' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();
  my $body;
  my $docker = test_docker(
    'POST /containers/test/exec' => sub {
      my ($method, $path, %opts) = @_;
      $body = $opts{body};
      return { Id => 'exec123' };
    },
  );

  $docker->exec->create('test', Cmd => ['true'], Tty => JSON::MaybeXS::false());
  like(encode_json($body), qr/"Tty":false/, 'a JSON false stays false');
};

done_testing;
