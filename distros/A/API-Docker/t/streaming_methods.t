#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw( encode_json decode_json );
use Path::Tiny;
use API::Docker;

use lib 't/lib';
use Test::API::Docker::Mock;

# The resource methods that hand a callback to the transport: the follow modes
# named in karr k21, and what each method returns once it is not collecting a
# body any more.
#
# t/streaming_callback.t proves the transport's half -- on_event, on_frame,
# on_chunk, the $stop closure, the summary. This file is about the wiring: that
# system->events, containers->logs/stats, exec->start, images->build/pull/push/
# load/get/get_all and plugins->install/upgrade/push pass a callback through at
# all, that the query parameters those modes need go out with it, and that the
# buffered call each of them used to be is unchanged.
#
# Nothing here opens a socket. The subtests that exercise the real transport
# script the response as bytes served by a tied handle, which the client's
# _build__socket hands back in place of a connection; the rest go through the
# route table of Test::API::Docker::Mock. Neither reaches a daemon, and
# images->push and plugins->push are exercised through the mock alone, which
# has no socket at all.
#
# The handle can be told to *die* rather than report EOF once its script runs
# out. That is what makes a follow mode testable: an unterminated chunked body
# is a stream the daemon has not finished, and a transport that asks for what
# comes after the callback said stop gets an exception instead of a wait. Every
# assertion below therefore fails in milliseconds where it would otherwise hang
# the suite.

my $FIXTURES = path('t/fixtures');

# ---------------------------------------------------------------------------
# The scripted socket. A copy of the one in t/streaming_callback.t rather than
# a shared helper: that file belongs to the transport work, and t/lib is where
# the mock harness lives, not a second one.
package Test::Method::Stream::Handle;

sub TIEHANDLE {
  my ($class, %args) = @_;
  return bless {
    buf     => $args{data},
    pos     => 0,
    step    => $args{step} || 0,
    at_end  => $args{at_end} || 'eof',
    written => '',
  }, $class;
}

sub PRINT { my $self = shift; $self->{written} .= join('', @_); return 1 }

sub _exhausted {
  my ($self) = @_;
  die "Test::Method::Stream::Handle: the transport read past the end of the "
    . "scripted stream\n" if $self->{at_end} eq 'die';
  return;
}

sub READLINE {
  my ($self) = @_;
  if ($self->{pos} >= length $self->{buf}) {
    $self->_exhausted;
    return undef;
  }
  my $idx = index($self->{buf}, "\n", $self->{pos});
  my $end = $idx == -1 ? length($self->{buf}) : $idx + 1;
  my $line = substr($self->{buf}, $self->{pos}, $end - $self->{pos});
  $self->{pos} = $end;
  return $line;
}

sub READ {
  my $self   = $_[0];
  my $len    = $_[2];
  my $offset = $_[3] || 0;
  my $avail  = length($self->{buf}) - $self->{pos};
  if ($avail <= 0) {
    $self->_exhausted;
    return 0;
  }
  my $n = $len;
  $n = $self->{step} if $self->{step} && $n > $self->{step};
  $n = $avail        if $n > $avail;
  my $chunk = substr($self->{buf}, $self->{pos}, $n);
  if ($offset) {
    substr($_[1], $offset, $n) = $chunk;
  }
  else {
    $_[1] = $chunk;
  }
  $self->{pos} += $n;
  return $n;
}

sub EOF   { my ($self) = @_; return $self->{pos} >= length $self->{buf} }
sub CLOSE { 1 }

# ---------------------------------------------------------------------------
package Test::Method::Stream::Client;
use Moo;
extends 'API::Docker';

has script     => (is => 'rw', required => 1);
has step       => (is => 'rw', default  => sub { 0 });
has at_end     => (is => 'rw', default  => sub { 'eof' });
# The last handle built, kept so a test can read the request that went out --
# which is the only way to see that `follow=1` or `stream=1` reached the wire.
has sent       => (is => 'rw');

sub _build__socket {
  my ($self) = @_;
  my $fh = \do { no warnings 'once'; local *HANDLE };
  my $obj = tie *$fh, 'Test::Method::Stream::Handle',
    data   => $self->script,
    step   => $self->step,
    at_end => $self->at_end;
  $self->sent($obj);
  return $fh;
}

sub request_line {
  my ($self) = @_;
  my ($line) = split /\r\n/, $self->sent->{written}, 2;
  return $line // '';
}

# ---------------------------------------------------------------------------
package main;

sub client {
  my ($script, %args) = @_;
  return Test::Method::Stream::Client->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    script      => $script,
    %args,
  );
}

# One HTTP chunk per element, and by default no terminating zero chunk: a
# stream the daemon has not finished.
sub chunked {
  my ($chunks, %args) = @_;
  my $raw = "HTTP/1.1 200 OK\r\n"
    . "Transfer-Encoding: chunked\r\n"
    . "\r\n";
  $raw .= sprintf("%x\r\n%s\r\n", length($_), $_) for @$chunks;
  $raw .= "0\r\n\r\n" if $args{closed};
  return $raw;
}

sub sized {
  my ($body, %args) = @_;
  return "HTTP/1.1 200 OK\r\n"
    . "Content-Type: " . ($args{type} // 'application/json') . "\r\n"
    . "Content-Length: " . length($body) . "\r\n"
    . "\r\n"
    . $body;
}

sub ndjson_lines {
  my ($name) = @_;
  return grep { /\S/ } split /(?<=\n)/, $FIXTURES->child($name)->slurp_raw;
}

# ---------------------------------------------------------------------------
# The ticket, method by method: a stream the daemon has not finished, and a
# call that comes back anyway.

subtest 'containers->logs: follow returns through on_frame' => sub {
  my $body = $FIXTURES->child('containers_logs_multiplexed.bin')->slurp_raw;
  my $docker = client(chunked([$body]), step => 5, at_end => 'die');

  my @got;
  my $summary = eval {
    $docker->containers->logs('abc',
      follow   => 1,
      tail     => 0,
      on_frame => sub {
        my ($frame, $stop) = @_;
        push @got, $frame;
        $stop->();
      },
    );
  };

  is $@, '', 'the call returned instead of reading on for what never comes';
  is_deeply \@got, [ { stream => 'stdout', data => "OUT\n" } ],
    'the frame was demultiplexed and handed over as it arrived';
  is_deeply $summary, { delivered => 1, stopped => 1 },
    'and the return value is the transport summary, not an ArrayRef of '
    . 'frames: with a callback nothing is collected to return';
  like $docker->request_line, qr/[?&]follow=1(&|\s)/,
    'follow=1 went out -- the method took no follow parameter at all before';
};

subtest 'containers->logs: follow without a callback still runs to the end' => sub {
  my $body = $FIXTURES->child('containers_logs_multiplexed.bin')->slurp_raw;
  my $docker = client(chunked([$body]), step => 5, at_end => 'die');

  eval { $docker->containers->logs('abc', follow => 1) };
  like $@, qr/read past the end of the scripted stream/,
    'the buffered path consumed the whole script and asked for more, which '
    . 'against a followed log is a process that never comes back';
};

subtest 'containers->logs: the buffered call is unchanged' => sub {
  my $body = $FIXTURES->child('containers_logs_multiplexed.bin')->slurp_raw;
  my $docker = client(chunked([$body], closed => 1), step => 5);

  my $frames = $docker->containers->logs('abc', tail => 100);
  is_deeply $frames, [
    { stream => 'stdout', data => "OUT\n" },
    { stream => 'stderr', data => "ERR\n" },
  ], 'no callback, no follow: the ArrayRef of frames as before';
  unlike $docker->request_line, qr/follow/,
    'and follow is not sent unless it was asked for';
};

subtest 'system->events: unbounded, and it comes back' => sub {
  my @lines = ndjson_lines('system_events_stream.ndjson');
  my $docker = client(chunked(\@lines), step => 17, at_end => 'die');

  my @got;
  my $summary = eval {
    $docker->system->events(
      since    => 1787541900,
      on_event => sub {
        my ($event, $stop) = @_;
        push @got, $event;
        $stop->() if @got >= 2;
      },
    );
  };

  is $@, '', 'no until, no hang';
  is scalar(@got), 2, 'two events, then the callback said stop';
  ok !grep({ ref $_ ne 'HASH' } @got), 'each one decoded';
  is_deeply $summary, { delivered => 2, stopped => 1 }, 'summary, not events';
  my $line = $docker->request_line;
  like $line, qr/[?&]since=1787541900/, 'since went out';
  unlike $line, qr/until=/, 'and nothing bounded the window';
};

subtest 'system->events: unbounded without a callback is the old hang' => sub {
  my @lines = ndjson_lines('system_events_stream.ndjson');
  my $docker = client(chunked(\@lines), step => 17, at_end => 'die');

  eval { $docker->system->events(since => 1787541900) };
  like $@, qr/read past the end of the scripted stream/,
    'which is why the POD tells an unbounded caller to pass on_event';
};

subtest 'system->events: buffered, an ArrayRef as before' => sub {
  my @lines = ndjson_lines('system_events_stream.ndjson');
  my $docker = client(chunked(\@lines, closed => 1), step => 17);

  my $events = $docker->system->events(since => 1, until => 2);
  is ref $events, 'ARRAY', 'the bounded call still returns the event list';
  is scalar(@$events), scalar(@lines), 'one element per line of the stream';
};

subtest 'containers->stats: stream => 1 through on_event' => sub {
  my @lines = map { encode_json({ read => $_, cpu_stats => {} }) . "\n" } 1 .. 4;
  my $docker = client(chunked(\@lines), step => 6, at_end => 'die');

  my @got;
  my $summary = eval {
    $docker->containers->stats('abc',
      stream   => 1,
      on_event => sub {
        my ($stats, $stop) = @_;
        push @got, $stats;
        $stop->() if @got >= 3;
      },
    );
  };

  is $@, '', 'a streaming stats call returns';
  is scalar(@got), 3, 'three readings went to the callback';
  is_deeply $summary, { delivered => 3, stopped => 1 }, 'summary back';
  my $line = $docker->request_line;
  like $line, qr/[?&]stream=1/, 'stream=1 went out -- it was hardcoded to 0';
  unlike $line, qr/one-shot/,
    'and one-shot is not sent beside it: it asks the engine not to wait for a '
    . 'second sampling cycle, which only means anything to a single reading';
};

subtest 'containers->stats: the one-shot call is unchanged' => sub {
  my $reading = { read => '2026-08-27T00:00:00Z', memory_stats => { usage => 42 } };
  my $docker = client(sized(encode_json($reading)));

  is_deeply $docker->containers->stats('abc'), $reading,
    'no options: the single decoded reading it always returned';
  my $line = $docker->request_line;
  like $line, qr/[?&]stream=0/,  'stream=0 as before';
  like $line, qr/[?&]one-shot=1/, 'and one-shot=1 with it';
};

subtest 'exec->start: output while the command is still running' => sub {
  my $body = $FIXTURES->child('exec_start_multiplexed.bin')->slurp_raw;
  my $docker = client(chunked([$body]), step => 7, at_end => 'die');

  my @got;
  my $summary = eval {
    $docker->exec->start('e1',
      on_frame => sub {
        my ($frame, $stop) = @_;
        push @got, $frame;
        $stop->();
      },
    );
  };

  is $@, '', 'returned at the first frame instead of waiting for the exit';
  is scalar(@got), 1, 'one frame';
  ok $got[0]{stream} =~ /\A(?:stdout|stderr|stdin)\z/,
    'demultiplexed, so the 8-byte headers did not reach the caller';
  is_deeply $summary, { delivered => 1, stopped => 1 }, 'summary back';
};

subtest 'images->build: progress as it arrives, and the failure croaks early' => sub {
  my @lines = ndjson_lines('images_build_error_stream.ndjson');
  # at_end => 'die': a transport that kept collecting after the failing event
  # would run off the end of the script rather than croaking on the spot.
  my $docker = client(chunked(\@lines), step => 9, at_end => 'die');

  my @got;
  my $summary = eval {
    $docker->images->build(
      context  => 'not-really-a-tar',
      t        => 'x:1',
      on_event => sub { push @got, $_[0] },
    );
  };
  my $err = $@;

  ok ref $err && $err->isa('API::Docker::Error::Stream'),
    'the same exception class the buffered build raises';
  is $summary, undef, 'and no summary came back, because it croaked';
  is scalar(@got), scalar(@lines) - 1,
    'every event before the failure was delivered as it arrived';
  is_deeply $err->events, [ decode_json($lines[-1]) ],
    'the exception carries the failing event alone -- a callback stream keeps '
    . 'no history, where the buffered path hands over the whole list';
};

subtest 'images->build: the buffered call is unchanged' => sub {
  my @lines = ndjson_lines('images_build_stream.ndjson');
  my $docker = client(chunked(\@lines, closed => 1), step => 13);

  my $events = $docker->images->build(context => 'tar', t => 'x:1');
  is ref $events, 'ARRAY', 'still the ArrayRef of build events';
  is scalar(@$events), scalar(@lines), 'one per object in the stream';
};

subtest 'images->get: an export that does not cost its own size in RAM' => sub {
  my $tar = $FIXTURES->child('images_get.tar')->slurp_raw;
  my $docker = client(sized($tar, type => 'application/x-tar'), step => 1024);

  my $written = '';
  my $summary = $docker->images->get('alpine:3',
    on_chunk => sub { $written .= $_[0] });

  ok $summary->{delivered} > 1,
    'the archive arrived in pieces, not as one buffered body';
  is length($written), length($tar), 'and all of it arrived';
  is $written, $tar, 'byte for byte what the buffered call returns';
  is $summary->{stopped}, 0, 'the announced length ended it, not the caller';
};

subtest 'images->get: the buffered call is unchanged' => sub {
  my $tar = $FIXTURES->child('images_get.tar')->slurp_raw;
  my $docker = client(sized($tar, type => 'application/x-tar'), step => 1024);

  is $docker->images->get('alpine:3'), $tar,
    'no callback: the whole archive as raw bytes';
};

subtest 'images->get_all: options ride behind the ArrayRef of names' => sub {
  my $tar = $FIXTURES->child('images_get.tar')->slurp_raw;
  my $docker = client(sized($tar, type => 'application/x-tar'), step => 4096);

  my $written = '';
  my $summary = $docker->images->get_all([ 'alpine:3', 'registry:2' ],
    on_chunk => sub { $written .= $_[0] });

  is $written, $tar, 'the archive streamed out whole';
  ok $summary->{delivered} > 1, 'in more than one piece';
  my $line = $docker->request_line;
  like $line, qr/names=alpine:3/,   'both names still go out';
  like $line, qr/names=registry:2/, 'as repeated parameters';

  my $listed = client(sized($tar, type => 'application/x-tar'));
  is $listed->images->get_all('alpine:3', 'registry:2'), $tar,
    'and the list form is untouched: names all the way down, buffered';

  eval { $docker->images->get_all([ 'alpine:3' ], 'on_chunk') };
  like $@, qr/odd number/,
    'an unpaired option after the ArrayRef is a caller bug, not an extra name';
};

subtest 'an unset callback is refused, not quietly buffered' => sub {
  my @lines = ndjson_lines('system_events_stream.ndjson');
  my $docker = client(chunked(\@lines), at_end => 'die');

  eval { $docker->system->events(since => 1, on_event => undef) };
  like $@, qr/on_event option must be a CodeRef/,
    'passing an unset callback falls back to nothing: silently buffering it '
    . 'would answer an unbounded feed by hanging';
};

# ---------------------------------------------------------------------------
# The rest of the wiring, through the route table. What is under test here is
# that each method hands its callback to the transport and returns what the
# transport returns -- the transport's own behaviour is t/streaming_callback.t.

subtest 'every remaining method passes its callback through' => sub {
  plan skip_all => 'live mode ignores the route table' if is_live();

  my @progress = ( { status => 'a' }, { status => 'b' }, { status => 'c' } );

  my %case = (
    'images->pull' => sub {
      my ($cb) = @_;
      test_docker('POST /images/create' => \@progress)
        ->images->pull(fromImage => 'alpine', tag => '3', on_event => $cb);
    },
    'images->push' => sub {
      my ($cb) = @_;
      test_docker('POST /images/x/push' => \@progress)
        ->images->push('x', on_event => $cb);
    },
    'images->load' => sub {
      my ($cb) = @_;
      test_docker('POST /images/load' => \@progress)
        ->images->load('tar-bytes', on_event => $cb);
    },
    'plugins->install' => sub {
      my ($cb) = @_;
      test_docker('POST /plugins/pull' => \@progress)
        ->plugins->install('vieux/sshfs', privileges => [], on_event => $cb);
    },
    'plugins->upgrade' => sub {
      my ($cb) = @_;
      test_docker('POST /plugins/sshfs/upgrade' => \@progress)
        ->plugins->upgrade('sshfs', privileges => [], on_event => $cb);
    },
    'plugins->push' => sub {
      my ($cb) = @_;
      test_docker('POST /plugins/sshfs/push' => \@progress)
        ->plugins->push('sshfs', on_event => $cb);
    },
    'containers->attach' => sub {
      my ($cb) = @_;
      test_docker('POST /containers/abc/attach' => [
        { stream => 'stdout', data => "one\n" },
        { stream => 'stdout', data => "two\n" },
        { stream => 'stderr', data => "three\n" },
      # require_running => 0: this case is about the callback contract, not
      # about attach's running-container check, and opting out keeps the route
      # table down to the one endpoint under test.
      ])->containers->attach('abc', on_frame => $cb, require_running => 0);
    },
  );

  for my $name (sort keys %case) {
    my @got;
    my $summary = $case{$name}->(sub {
      my ($unit, $stop) = @_;
      push @got, $unit;
      $stop->() if @got >= 2;
    });

    is scalar(@got), 2, "$name delivered units one at a time";
    is_deeply $summary, { delivered => 2, stopped => 1 },
      "$name returned the summary and stopped where the callback said";
  }
};

subtest 'the entity classes forward the callback too' => sub {
  plan skip_all => 'live mode ignores the route table' if is_live();

  # containers_list (karr k101 follow-up): a real capture -- see t/containers.t.
  # The logs route names the fixture's own container id exactly, rather than
  # a [^/]+ wildcard: Test::API::Docker::Mock's fallback tier used to
  # interpolate a route key as an unescaped regex, which is what made a
  # wildcard like that "work" here by accident (karr k109, t/mock_harness.t)
  # -- now that it is quotemeta'd, a route key means the literal path it
  # looks like.
  my $docker = test_docker(
    'GET /containers/json' => load_fixture('containers_list'),
    'GET /containers/b20ac7508d80182ba3cd1cbd006ac10c8a15f4f7590fa89c2078d146caf96555/logs' => [
      { stream => 'stdout', data => "one\n" },
      { stream => 'stdout', data => "two\n" },
    ],
  );

  my ($container) = @{ $docker->containers->list };
  my @got;
  my $summary = $container->logs(follow => 1, on_frame => sub { push @got, $_[0] });

  is scalar(@got), 2, 'the container entity->logs streams like the API class';
  is_deeply $summary, { delivered => 2, stopped => 0 },
    'and hands the same summary back rather than an ArrayRef of frames';
};

# ---------------------------------------------------------------------------
subtest 'live: a callback against the daemon itself' => sub {
  plan skip_all => 'set API_DOCKER_TEST_HOST for the live path' unless is_live();
  check_live_access();

  my $docker = test_docker();

  my @got;
  # Bounded on purpose. An unbounded feed with no traffic in it would deliver
  # nothing and never end, which is a hung suite rather than a failed
  # assertion -- the unbounded case is the one to run by hand, under timeout.
  my $summary = $docker->system->events(
    since    => time - 3600,
    until    => time,
    on_event => sub {
      my ($event, $stop) = @_;
      push @got, $event;
      $stop->() if @got >= 3;
    },
  );

  is ref $summary, 'HASH', 'a summary came back from a real daemon';
  is $summary->{delivered}, scalar(@got), 'counting what the callback saw';
  ok !grep({ ref $_ ne 'HASH' } @got), 'every unit is a decoded event';
};

done_testing;
