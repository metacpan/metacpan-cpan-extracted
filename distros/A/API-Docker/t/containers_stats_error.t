#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;
use API::Docker;
use API::Docker::Error::HTTP;

# Regression coverage for karr k45: GET /containers/{id}/stats for a container
# that is not running is answered by Podman with an error object inside a
# response already committed to 200 --
#
#   {"cause":"container is stopped","message":"container is stopped",
#    "response":500}
#
# -- which neither guard in the transport sees (the >= 400 croak reads the
# status line, the stream check triggers on errorDetail). The one-shot call
# returned that HashRef where a reading was expected and an on_event callback
# was handed it as though it were one. containers->stats now croaks with an
# API::Docker::Error::HTTP instead.
#
# The rule is endpoint-local and deliberately narrow; this file exists to keep
# it that way. The counter-examples below are the point of it as much as the
# positive cases are: POST /containers/{id}/wait answers its SUCCESS case with
# a top-level Error key, so a case-insensitive rule would turn every
# successful wait into a failure, and Podman's own GET /plugins 404 carries
# the same three keys with response => 0.
#
# Measured 2026-08-27 against rootless Podman 5.4.2 (API 1.41) and Docker
# 29.7.2 (API 1.55) on one machine. Nothing here opens a socket: the route
# table of Test::API::Docker::Mock stands in for the daemon, and the live
# subtest at the end runs only with API_DOCKER_TEST_WRITE=1.

check_live_access();

my $STOPPED = {
  cause    => 'container is stopped',
  message  => 'container is stopped',
  response => 500,
};

my $READING = {
  read         => '2026-08-27T00:00:00Z',
  cpu_stats    => { cpu_usage => { total_usage => 1000 } },
  memory_stats => { usage => 50_000_000 },
};

SKIP: {
  skip 'mock routes are bypassed in live mode', 7 if is_live();

  subtest 'the one-shot call croaks instead of returning the error object' => sub {
    my $docker = test_docker('GET /containers/abc/stats' => $STOPPED);

    my $stats = eval { $docker->containers->stats('abc') };
    my $err = $@;

    ok !defined $stats, 'nothing is returned -- the failure is not a value';
    isa_ok $err, 'API::Docker::Error::HTTP';
    is $err->status, 500,
      'the status is the one Podman named in `response`, not the 200 it sent';
    is_deeply $err->data, $STOPPED,
      'the whole object is carried, so ->data->{cause} is still readable';
    like "$err", qr/container is stopped/, 'the engine\'s own reason';
    like "$err", qr{\Qinside a 200 response to GET /containers/abc/stats\E},
      'and the fact that makes it hard to find otherwise';
    like "$err", qr/ at \S+ line \d+\.?/,
      'with Carp\'s location suffix, as every other croak here has';
    ok $err, 'boolean-true, so if ($@) detects it';
  };

  subtest 'stream => 1 without a callback croaks on the same body' => sub {
    # The buffered ndjson path: the same body arrives as a one-element list.
    my $docker = test_docker('GET /containers/abc/stats' => [$STOPPED]);

    my $stats = eval { $docker->containers->stats('abc', stream => 1) };
    isa_ok $@, 'API::Docker::Error::HTTP';
    ok !defined $stats, 'no ArrayRef with an error object in it comes back';
  };

  subtest 'on_event: the callback never sees the error object' => sub {
    my $docker = test_docker('GET /containers/abc/stats' => $STOPPED);

    my @got;
    my $summary = eval {
      $docker->containers->stats('abc',
        stream   => 1,
        on_event => sub { push @got, $_[0] },
      );
    };
    my $err = $@;

    isa_ok $err, 'API::Docker::Error::HTTP';
    is scalar(@got), 0,
      'the guard runs in front of the callback, not after it';
    ok !defined $summary, 'and no summary is returned either';
    is $err->status, 500, 'same exception as on the buffered path';
  };

  subtest 'a real reading is untouched on all three paths' => sub {
    my $docker = test_docker('GET /containers/abc/stats' => $READING);
    is_deeply $docker->containers->stats('abc'), $READING,
      'one-shot: the decoded reading, exactly as before';

    $docker = test_docker('GET /containers/abc/stats' => [$READING, $READING]);
    is_deeply $docker->containers->stats('abc', stream => 1),
      [$READING, $READING], 'stream => 1 buffered: the list of readings';

    $docker = test_docker(
      'GET /containers/abc/stats' => mock_response(
        data   => $READING,
        stream => [$READING, $READING, $READING],
      ),
    );
    my @got;
    my $summary = $docker->containers->stats('abc',
      stream   => 1,
      on_event => sub {
        my ($reading, $stop) = @_;
        push @got, $reading;
        $stop->() if @got >= 2;
      },
    );
    is scalar(@got), 2, 'on_event: the readings reach the callback';
    is_deeply $summary, { delivered => 2, stopped => 1 },
      'and $stop still reaches the transport through the wrapper';
  };

  subtest 'what must not trigger it' => sub {
    # Every one of these is a body that a looser rule would have croaked on.
    my %harmless = (
      'a bare message, which is Docker\'s ordinary error shape'
        => { message => 'container is stopped' },
      'cause and message without response'
        => { cause => 'x', message => 'x' },
      'a response below 400'
        => { cause => 'x', message => 'x', response => 200 },
      'Podman\'s own /plugins shape, response => 0'
        => { cause => '', message => 'Path /v1.41/plugins is not supported',
             response => 0 },
      'the same keys capitalised'
        => { Cause => 'x', Message => 'x', Response => 500 },
      'a response that is not a scalar'
        => { cause => 'x', message => 'x', response => { code => 500 } },
      'a response that does not read as an integer'
        => { cause => 'x', message => 'x', response => 'Internal Error' },
      'a reading that happens to mention the words'
        => { read => '2026-08-27T00:00:00Z', message => 'cause: response' },
    );

    for my $why (sort keys %harmless) {
      my $body = $harmless{$why};
      my $docker = test_docker('GET /containers/abc/stats' => $body);
      my $stats = eval { $docker->containers->stats('abc') };
      is $@, '', "no croak: $why";
      is_deeply $stats, $body, "  ... and it comes back as data";
    }
  };

  subtest 'the counter-example: a successful wait is not a failure' => sub {
    # Podman answers every wait with a top-level Error key. A rule matching
    # /error/i, or one reaching past this endpoint, would kill all of them.
    my $podman = { StatusCode => 4, Error => undef };
    my $docker = test_docker('POST /containers/abc/wait' => $podman);
    is_deeply $docker->containers->wait('abc'), $podman,
      'Podman\'s shape passes through untouched';

    $docker = test_docker('POST /containers/abc/wait' => { StatusCode => 4 });
    is_deeply $docker->containers->wait('abc'), { StatusCode => 4 },
      'and so does Docker\'s, which omits the key';
  };

  subtest 'the check is local to stats, not a transport rule' => sub {
    # Deliberate: the shape is one engine's on one endpoint. Anything else
    # answering with it is a question for that endpoint, not for this guard.
    my $docker = test_docker('GET /containers/abc/top' => $STOPPED);
    my $top = eval { $docker->containers->top('abc') };
    is $@, '', 'another endpoint does not croak on the same body';
    is_deeply $top, $STOPPED, 'it is handed back as data';
  };
}

SKIP: {
  skip 'live write tests disabled (API_DOCKER_TEST_WRITE=1 to enable)', 1
    unless can_write();

  subtest 'live: stats on a container that is not running' => sub {
    my $docker = API::Docker->new(host => $ENV{API_DOCKER_TEST_HOST});

    my $name = 'apidocker-stats-error-' . $$;
    my $created = $docker->containers->create(
      Image => 'alpine:latest',
      name  => $name,
      Cmd   => ['sh', '-c', 'exit 4'],
    );
    register_cleanup(sub {
      eval { $docker->containers->remove($created->{Id}, force => 1) };
    });

    $docker->containers->start($created->{Id});
    $docker->containers->wait($created->{Id});

    my $stats = eval { $docker->containers->stats($created->{Id}) };
    my $err = $@;

    if (live_engine() eq 'podman') {
      ok !defined $stats, 'podman: no reading is returned';
      isa_ok $err, 'API::Docker::Error::HTTP';
      is $err->status, 500, 'the code from the error object, not the 200';
      like "$err", qr/container is stopped/, 'the engine\'s reason';
    }
    else {
      is $err, '', 'docker: the same call does not croak';
      is ref $stats, 'HASH', 'a structurally valid reading comes back';
      is $stats->{read}, '0001-01-01T00:00:00Z',
        'zero-filled -- Go\'s zero time is the only marker in it';
      is $stats->{num_procs}, 0, 'and no processes';
    }
  };
}

done_testing;
