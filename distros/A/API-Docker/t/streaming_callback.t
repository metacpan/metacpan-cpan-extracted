#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw( encode_json decode_json );
use Path::Tiny;
use API::Docker;

use lib 't/lib';
use Test::API::Docker::Mock;

# The per-request streaming callbacks of API::Docker::Role::HTTP: on_event,
# on_frame and on_chunk, the $stop closure they are handed, and the summary
# _request returns instead of a body.
#
# Nothing here opens a socket or reaches a daemon. The response is a scripted
# byte string served by a tied handle that the client's _build__socket hands
# back in place of a real connection, so the whole of _request runs -- request
# assembly, _read_head, the incremental body reader, the close -- against
# bytes chosen by the test.
#
# The handle can be told to *die* rather than report EOF once the script runs
# out. That is what makes the central case of this file testable at all: a
# stream that keeps going is scripted as a chunked body with no terminating
# chunk, and a transport that asks for what comes after the callback said stop
# gets an exception instead of a wait. Without the fix this file fails in
# seconds; it can never hang the suite.

my $FIXTURES = path('t/fixtures');

# ---------------------------------------------------------------------------
package Test::Stream::Handle;

sub TIEHANDLE {
  my ($class, %args) = @_;
  return bless {
    buf     => $args{data},
    pos     => 0,
    # 0 means "hand over as much as was asked for". A small step makes every
    # read() partial, so an ndjson line and an 8-byte frame header both
    # straddle read boundaries -- which is where a carry buffer earns its
    # keep, and where a naive per-read decoder breaks.
    step    => $args{step} || 0,
    at_end  => $args{at_end} || 'eof',
    written => '',
  }, $class;
}

sub PRINT { my $self = shift; $self->{written} .= join('', @_); return 1 }

sub _exhausted {
  my ($self) = @_;
  die "Test::Stream::Handle: the transport read past the end of the scripted "
    . "stream\n" if $self->{at_end} eq 'die';
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
package Test::Stream::Transport;
use Moo;
extends 'API::Docker';

has script => (is => 'rw', required => 1);
has step   => (is => 'rw', default  => sub { 0 });
has at_end => (is => 'rw', default  => sub { 'eof' });

sub _build__socket {
  my ($self) = @_;
  my $fh = \do { no warnings 'once'; local *HANDLE };
  tie *$fh, 'Test::Stream::Handle',
    data   => $self->script,
    step   => $self->step,
    at_end => $self->at_end;
  return $fh;
}

# ---------------------------------------------------------------------------
package main;

sub transport {
  my ($script, %args) = @_;
  return Test::Stream::Transport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    script      => $script,
    %args,
  );
}

# One HTTP chunk per element, and by default no terminating zero chunk: a
# stream the daemon has not finished. Pass a true $closed for one it has.
sub chunked {
  my ($chunks, %args) = @_;
  my $raw = "HTTP/1.1 200 OK\r\n"
    . "Content-Type: application/json\r\n"
    . "Transfer-Encoding: chunked\r\n"
    . "\r\n";
  $raw .= sprintf("%x\r\n%s\r\n", length($_), $_) for @$chunks;
  $raw .= "0\r\n\r\n" if $args{closed};
  return $raw;
}

sub sized {
  my ($body, %args) = @_;
  return "HTTP/1.1 " . ($args{status} // 200) . " " . ($args{reason} // 'OK') . "\r\n"
    . "Content-Type: " . ($args{type} // 'application/json') . "\r\n"
    . "Content-Length: " . length($body) . "\r\n"
    . "\r\n"
    . $body;
}

my @EVENT_LINES = map { encode_json($_) . "\n" } (
  { status => 'create', id => 'a' },
  { status => 'start',  id => 'a' },
  { status => 'die',    id => 'a' },
);

# ---------------------------------------------------------------------------
# The whole point of the ticket. An unbounded feed, a callback that stops
# partway, and a transport that must return.
subtest 'on_event: the callback stops an unfinished stream' => sub {
  my $client = transport(chunked(\@EVENT_LINES), step => 5, at_end => 'die');

  my @got;
  my $summary = eval {
    $client->get('/events',
      croak_on_error => 0,
      on_event       => sub {
        my ($event, $stop) = @_;
        push @got, $event;
        $stop->() if $event->{status} eq 'die';
      },
    );
  };

  is $@, '', 'the request returned instead of reading on past the stop';
  is_deeply [ map { $_->{status} } @got ], [qw( create start die )],
    'every event up to the stop was delivered, in order, decoded';
  is_deeply $summary, { delivered => 3, stopped => 1 },
    'the return value says how many units went out and that the callback '
    . 'ended it, not the daemon';
};

# The same script down the buffered path, so this file carries its own proof
# that the assertion above can fail. Before the callback existed this was the
# only path there was, and it is what an unbounded /events call still does: it
# asks for the next chunk, and the next, until the daemon closes -- which for
# a live feed is never. Here that shows up as the handle's exception; against
# a daemon it is a process that never comes back.
subtest 'the buffered path reads on until the stream ends' => sub {
  my $client = transport(chunked(\@EVENT_LINES), step => 5, at_end => 'die');

  eval { $client->get('/events', ndjson => 1, croak_on_error => 0) };
  like $@, qr/read past the end of the scripted stream/,
    'with no callback the transport consumed the whole script and asked for '
    . 'more -- the exact shape of the hang the callback avoids';
};

# ---------------------------------------------------------------------------
subtest 'on_event: the daemon ending the stream is reported as such' => sub {
  my $client = transport(chunked(\@EVENT_LINES, closed => 1), step => 3);

  my @got;
  my $summary = $client->get('/events',
    croak_on_error => 0,
    on_event       => sub { push @got, $_[0] },
  );

  is scalar(@got), 3, 'every event was delivered';
  is_deeply $summary, { delivered => 3, stopped => 0 },
    'stopped is false: this stream ran out, it was not cut short';
};

subtest 'on_event: a line split across chunks and reads is reassembled' => sub {
  # One event, torn into pieces that are neither chunk- nor line-aligned, and
  # read three bytes at a time on top of that. A decoder without a carry
  # buffer sees a series of JSON fragments here and delivers nothing.
  my $line = encode_json({ status => 'start', id => 'split-me' }) . "\n";
  my @pieces = ($line =~ /(.{1,7})/gs);
  my $client = transport(chunked(\@pieces, closed => 1), step => 3);

  my @got;
  my $summary = $client->get('/events',
    croak_on_error => 0,
    on_event       => sub { push @got, $_[0] },
  );

  is scalar(@pieces) > 3, 1, 'the event really was torn into several chunks';
  is_deeply \@got, [ { status => 'start', id => 'split-me' } ],
    'it arrives as one decoded event';
  is $summary->{delivered}, 1, 'delivered once, not once per fragment';
};

subtest 'on_event: a final event with no trailing newline is not dropped' => sub {
  my $last = encode_json({ status => 'destroy', id => 'a' });
  my $client = transport(
    chunked([ $EVENT_LINES[0], $last ], closed => 1), step => 4);

  my @got;
  my $summary = $client->get('/events',
    croak_on_error => 0,
    on_event       => sub { push @got, $_[0] },
  );

  is_deeply [ map { $_->{status} } @got ], [qw( create destroy )],
    'the daemon closing is what ended the last event; it is complete, not '
    . 'truncated, so it is flushed rather than discarded with the carry';
  is $summary->{delivered}, 2, 'counted like any other event';
};

subtest 'on_event: the real /events fixture, event for event' => sub {
  my $raw = $FIXTURES->child('system_events_stream.ndjson')->slurp_raw;
  my @lines = grep { /\S/ } split /(?<=\n)/, $raw;

  my $client = transport(chunked([$raw], closed => 1), step => 11);

  my @got;
  $client->get('/events',
    croak_on_error => 0,
    on_event       => sub { push @got, $_[0] },
  );

  is scalar(@got), scalar(@lines),
    'one delivered event per line of the captured stream';
  is_deeply \@got, [ map { decode_json($_) } @lines ],
    'and each one decodes to what the daemon actually sent';
};

# ---------------------------------------------------------------------------
subtest 'on_event: errorDetail croaks at the event that reports it' => sub {
  my $raw = $FIXTURES->child('images_build_error_stream.ndjson')->slurp_raw;
  my @lines = grep { /\S/ } split /(?<=\n)/, $raw;

  # at_end => 'die': if the transport carried on collecting after the failing
  # event it would run off the end of the script. The buffered path has to
  # read the whole stream before it can scan it; this one croaks on the spot.
  my $client = transport(chunked(\@lines), step => 9, at_end => 'die');

  my @got;
  eval {
    $client->post('/build', undef, on_event => sub { push @got, $_[0] });
  };
  my $err = $@;

  ok ref $err && $err->isa('API::Docker::Error::Stream'),
    'the same error class the buffered path raises';
  like "$err", qr/Docker API stream error \(POST \/v1\.41\/build\)/,
    'named by endpoint, as before';
  is_deeply $err->events, [ decode_json($lines[-1]) ],
    'the object carries the failing event alone: a callback stream keeps no '
    . 'history, the caller was handed all of it as it arrived';
  is scalar(@got), scalar(@lines) - 1,
    'the events before the failure were delivered; the failing one was not';
};

subtest 'on_event: croak_on_error => 0 hands the error event over as data' => sub {
  my $raw = $FIXTURES->child('images_build_error_stream.ndjson')->slurp_raw;
  my @lines = grep { /\S/ } split /(?<=\n)/, $raw;
  my $client = transport(chunked(\@lines, closed => 1), step => 9);

  my @got;
  my $summary = $client->get('/events',
    croak_on_error => 0,
    on_event       => sub { push @got, $_[0] },
  );

  is scalar(@got), scalar(@lines), 'nothing was withheld';
  ok $got[-1]{errorDetail}, 'the errorDetail event arrived as an ordinary one';
  is $summary->{stopped}, 0, 'and the stream ran to the end';
};

# ---------------------------------------------------------------------------
subtest 'on_frame: frames are reassembled across chunk boundaries' => sub {
  my $body = $FIXTURES->child('containers_logs_multiplexed.bin')->slurp_raw;
  # Split at 5 bytes: the first frame's 8-byte header straddles two chunks,
  # so a reader that expected a header to arrive whole gets nothing right.
  my @pieces = ($body =~ /(.{1,5})/gs);
  my $client = transport(chunked(\@pieces, closed => 1), step => 3);

  my @got;
  my $summary = $client->stream_frames('GET', '/containers/x/logs',
    on_frame => sub { push @got, $_[0] });

  is_deeply \@got, [
    { stream => 'stdout', data => "OUT\n" },
    { stream => 'stderr', data => "ERR\n" },
  ], 'demultiplexed exactly as the buffered path demultiplexes it';
  is_deeply $summary, { delivered => 2, stopped => 0 }, 'two frames, ran out';
};

subtest 'on_frame: the callback stops between frames' => sub {
  my $body = $FIXTURES->child('containers_logs_multiplexed.bin')->slurp_raw;
  my $client = transport(chunked([$body]), step => 4, at_end => 'die');

  my @got;
  my $summary = eval {
    $client->stream_frames('GET', '/containers/x/logs',
      on_frame => sub {
        my ($frame, $stop) = @_;
        push @got, $frame;
        $stop->();
      });
  };

  is $@, '', 'returned without reading for the chunk that never comes';
  is scalar(@got), 1, 'one frame, and the second was never delivered';
  is_deeply $summary, { delivered => 1, stopped => 1 }, 'summary says so';
};

subtest 'on_frame: a stream cut off mid-frame croaks' => sub {
  my $body = $FIXTURES->child('containers_logs_multiplexed.bin')->slurp_raw;
  # 12 bytes is the first frame whole; 22 leaves the second one's header
  # complete and its 4-byte payload two bytes short -- the case where a reader
  # knows exactly how much it is waiting for and never gets it.
  my $client = transport(
    chunked([ substr($body, 0, 22) ], closed => 1), step => 4);

  my @got;
  eval {
    $client->stream_frames('GET', '/containers/x/logs',
      on_frame => sub { push @got, $_[0] });
  };
  is scalar(@got), 1, 'the frame that did arrive whole was delivered';
  like $@, qr/closed mid-frame, leaving 10 bytes/,
    'the daemon closing in the middle of a frame is an error, not an empty '
    . 'tail: the buffered path can fall back to raw, this one cannot';
};

subtest 'on_frame: an unframed body croaks rather than inventing frames' => sub {
  my $body = $FIXTURES->child('containers_logs_tty.bin')->slurp_raw;
  my $client = transport(chunked([$body], closed => 1), step => 4);

  eval {
    $client->stream_frames('GET', '/containers/x/logs',
      on_frame => sub { });
  };
  like $@, qr/not a framed stream/,
    'framing cannot be sniffed without the whole body, so an undeclared one '
    . 'that is not framed is refused';
  like $@, qr/tty => 1/, 'and the message names the way to declare it';
};

subtest 'stream_frames: tty => 1 delivers raw frames per chunk' => sub {
  my $body = $FIXTURES->child('containers_logs_tty.bin')->slurp_raw;
  my @pieces = ($body =~ /(.{1,4})/gs);
  my $client = transport(chunked(\@pieces, closed => 1));

  my @got;
  my $summary = $client->stream_frames('GET', '/containers/x/logs',
    tty      => 1,
    on_frame => sub { push @got, $_[0] });

  is_deeply [ map { $_->{stream} } @got ], [ ('raw') x scalar(@pieces) ],
    'the frame shape is kept so a caller need not branch on tty';
  is join('', map { $_->{data} } @got), $body, 'and the bytes are verbatim';
  is $summary->{delivered}, scalar(@pieces), 'one unit per chunk';
};

# ---------------------------------------------------------------------------
subtest 'on_chunk: bytes as they arrive, nothing decoded' => sub {
  my $body = join '', map { encode_json({ n => $_ }) . "\n" } 1 .. 4;
  my $client = transport(
    chunked([ substr($body, 0, 20), substr($body, 20) ], closed => 1));

  my @got;
  my $summary = $client->get('/images/x/get', on_chunk => sub { push @got, $_[0] });

  is scalar(@got) >= 2, 1, 'delivered in pieces, not as one buffered body';
  is join('', @got), $body,
    'and the pieces concatenate to the body byte for byte -- JSON lines in '
    . 'it are bytes, not events';
  is $summary->{delivered}, scalar(@got), 'counted per unit';
};

subtest 'on_chunk: a Content-Length body streams too' => sub {
  my $body = 'x' x 300;
  my $client = transport(sized($body, type => 'application/x-tar'), step => 64);

  my @got;
  my $summary = $client->get('/images/x/get', on_chunk => sub { push @got, $_[0] });

  is scalar(@got) > 1, 1, 'a sized body is read in slices, not in one gulp';
  is join('', @got), $body, 'and arrives whole';
  is $summary->{stopped}, 0, 'the announced length is what ended it';
};

subtest 'on_chunk: stopping leaves the rest of a sized body unread' => sub {
  my $client = transport(sized('y' x 300, type => 'application/x-tar'),
    step => 64, at_end => 'die');

  my @got;
  my $summary = $client->get('/images/x/get',
    on_chunk => sub { my ($bytes, $stop) = @_; push @got, $bytes; $stop->() });

  is scalar(@got), 1, 'one slice';
  is_deeply $summary, { delivered => 1, stopped => 1 },
    'the remaining bytes were never asked for';
};

# ---------------------------------------------------------------------------
subtest 'a failure is not a stream: >= 400 croaks with the daemon message' => sub {
  my $client = transport(
    sized(encode_json({ message => 'no such container: x' }),
      status => 404, reason => 'Not Found'));

  my $called = 0;
  my %res;
  eval {
    $client->get('/containers/x/logs',
      response => \%res,
      on_chunk => sub { $called++ },
    );
  };

  like $@, qr/Docker API error \(404\): no such container: x/,
    'the error body is read whole and croaked with, exactly as before';
  is $called, 0, 'the callback never saw an error body';
  is $res{status}, 404, 'and the response out-parameter is still filled';
};

subtest 'option validation' => sub {
  my $client = transport(chunked([], closed => 1));

  eval {
    $client->get('/events', on_event => sub { }, on_chunk => sub { })
  };
  like $@, qr/takes one of on_event, on_frame, on_chunk, not on_event and on_chunk/,
    'two units for one stream has no answer, so it is refused before the '
    . 'request is sent';

  eval { $client->get('/events', on_event => 'nope') };
  like $@, qr/on_event option must be a CodeRef/, 'and so is a non-callback';
};

subtest 'an empty stream still returns a summary' => sub {
  my $client = transport(chunked([], closed => 1));

  my $called = 0;
  my $summary = $client->get('/events',
    croak_on_error => 0,
    on_event       => sub { $called++ },
  );

  is $called, 0, 'nothing to deliver';
  is_deeply $summary, { delivered => 0, stopped => 0 },
    'and the caller is told that, rather than getting undef and guessing';
};

# ---------------------------------------------------------------------------
subtest 'the mock harness speaks the same contract' => sub {
  plan skip_all => 'live mode ignores the route table' if is_live();

  my $docker = test_docker(
    'GET /events' => [
      { status => 'create' },
      { status => 'start'  },
      { status => 'die'    },
    ],
  );

  my @got;
  my $summary = $docker->get('/events',
    on_event => sub {
      my ($event, $stop) = @_;
      push @got, $event;
      $stop->() if $event->{status} eq 'start';
    },
  );

  is_deeply [ map { $_->{status} } @got ], [qw( create start )],
    'a route whose value is the event list streams it one at a time';
  is_deeply $summary, { delivered => 2, stopped => 1 },
    'and returns the summary shape the transport returns';

  my $raw = test_docker(
    'GET /images/x/get' => mock_response(
      data   => 'whole-tarball',
      stream => [ 'whole-', 'tarball' ],
    ),
  );

  my @chunks;
  $raw->get('/images/x/get', on_chunk => sub { push @chunks, $_[0] });
  is_deeply \@chunks, [ 'whole-', 'tarball' ],
    'and mock_response(stream => ...) says what the units are where they are '
    . 'not the buffered value';
};

# ---------------------------------------------------------------------------
subtest 'live: a bounded /events feed through a callback' => sub {
  plan skip_all => 'set API_DOCKER_TEST_HOST for the live path' unless is_live();
  check_live_access();

  my $docker = test_docker();

  my @got;
  # Bounded, so the buffered path would return too -- what is under test here
  # is that the callback path speaks to a real daemon at all: real chunked
  # framing, real socket reads, real close.
  my $summary = $docker->get('/events',
    params         => { since => time - 3600, until => time },
    croak_on_error => 0,
    on_event       => sub {
      my ($event, $stop) = @_;
      push @got, $event;
      $stop->() if @got >= 3;
    },
  );

  is ref $summary, 'HASH', 'a summary came back';
  is $summary->{delivered}, scalar(@got), 'counting what the callback saw';
  ok !grep({ ref $_ ne 'HASH' } @got), 'every unit is a decoded event';
};

done_testing;
