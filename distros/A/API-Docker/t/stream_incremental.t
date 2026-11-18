#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Socket;
use Time::HiRes qw( time sleep );
use API::Docker;

# karr k60: on a raw stream the callback has to be called as the bytes arrive,
# not when the daemon closes.
#
# The endpoints this is about -- attach, logs(follow), exec/start, all
# application/vnd.docker.raw-stream -- answer with neither a Content-Length nor
# chunked encoding, so the body is "whatever comes until the connection is
# closed". The reader asks for $READ_SIZE (64K) per read there. With perl's
# read(), which is fread-shaped and loops until it has what it asked for or the
# stream ends, that meant the callback saw nothing until 64K had piled up or
# the daemon hung up -- and on a stream that never ends, nothing at all. The
# POD promised those callbacks the bytes as they arrive; it was not true.
#
# Measured before the fix, on an AF_UNIX socketpair with no daemon involved:
# a peer writing 6 bytes, waiting half a second, writing 6 more and closing
# gave read($sock, $buf, 65536) 12 bytes after 0.90s -- it waited for the close
# -- where sysread gave 6 bytes in 0.00s.
#
# Two tiers here. The first drives the reader over a tied handle, which pins
# the loop: one delivery per read, no coalescing, whatever the timing. The
# second is the one a tied handle cannot make -- that this survives a real
# socket and a real writer -- and costs about half a second.
#
# Nothing here reaches a Docker daemon and nothing here touches the network, so
# there is no is_live()/can_write() gating.

# ---------------------------------------------------------------------------
# A tied handle that delivers one scripted burst per read, exactly as a socket
# hands over what has arrived.
package Test::Incremental::Handle;

sub TIEHANDLE {
  my ($class, $bursts) = @_;
  return bless { bursts => $bursts, i => 0 }, $class;
}

sub READ {
  my $self = $_[0];
  my $data = $self->{bursts}[ $self->{i}++ ];
  return 0 unless defined $data;    # the end of the response
  $! = 0;
  $_[1] = $data;
  return length $data;
}

sub CLOSE { 1 }

package main;

sub burst_handle {
  my (@bursts) = @_;
  my $fh = \do { no warnings 'once'; local *HANDLE };
  tie *$fh, 'Test::Incremental::Handle', \@bursts;
  return $fh;
}

my $client = API::Docker->new(
  host        => 'unix:///nonexistent.sock',
  api_version => '1.41',
);

my $HEAD = "HTTP/1.1 200 OK\r\n"
  . "Content-Type: application/vnd.docker.raw-stream\r\n"
  . "\r\n";

# One 8-byte-framed stdout frame, as logs and attach send them.
sub frame {
  my ($text) = @_;
  return pack('C4 N', 1, 0, 0, 0, length $text) . $text;
}

# ---------------------------------------------------------------------------
subtest 'a raw stream delivers one call per arrival, not one per 64K' => sub {
  my @got;
  my $fh = burst_handle($HEAD, 'first ', 'second ', 'third');
  my $handler = $client->_stream_handler('GET /v1.41/probe', 'on_chunk',
    sub { push @got, $_[0] }, 1);

  $client->_read_streaming_response($fh, 'GET', $handler, {});

  is_deeply \@got, ['first ', 'second ', 'third'],
    'three arrivals, three calls -- under a filling read() this was one call '
    . 'with all of it, delivered when the daemon closed';
  is_deeply $handler->{summary}->(), { delivered => 3, stopped => 0 },
    'and the summary counts three units rather than one';
};

subtest 'the header block and the first bytes of the body in one arrival'
  => sub {
  # The case that made this a whole-transport change rather than a local one.
  # The head used to be read with <$sock>, which reads ahead: the bytes past
  # the blank line were already inside PerlIO's buffer, where nothing could
  # get at them. A body reader switched to sysread on its own would have
  # dropped exactly this.
  my @got;
  my $fh = burst_handle($HEAD . 'body starts here', ' and continues');
  my $handler = $client->_stream_handler('GET /v1.41/probe', 'on_chunk',
    sub { push @got, $_[0] }, 1);

  $client->_read_streaming_response($fh, 'GET', $handler, {});

  is_deeply \@got, ['body starts here', ' and continues'],
    'the read-ahead past the headers is the start of the body, and it is '
    . 'neither dropped nor delivered twice';
};

subtest 'a frame split across two arrivals is delivered once, whole' => sub {
  # The carry buffer's job, asserted here because karr k60 changes how often
  # it is asked to do it: it now sees the split the daemon actually made
  # rather than 64K blocks.
  my @got;
  my $whole = frame('hello world');
  my $fh = burst_handle($HEAD, substr($whole, 0, 5), substr($whole, 5));
  my $handler = $client->_stream_handler('GET /v1.41/probe', 'on_frame',
    sub { push @got, $_[0] }, 1);

  $client->_read_streaming_response($fh, 'GET', $handler, {});

  is_deeply \@got, [ { stream => 'stdout', data => 'hello world' } ],
    'the 8-byte header was split too, and the frame still came out once';
};

subtest 'a chunked stream still delivers per read, not per chunk' => sub {
  # The chunked path was never the broken one -- it asks for exactly the chunk
  # size, which is exactly what is there -- but it must not have regressed:
  # the engine is free to send an hour of log output as one chunk, so waiting
  # for a whole chunk would be the same bug in a different place.
  my @got;
  my $head = "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n";
  my $fh = burst_handle($head . "12\r\nfirst ", 'second ', "third\r\n",
    "0\r\n\r\n");
  my $handler = $client->_stream_handler('GET /v1.41/probe', 'on_chunk',
    sub { push @got, $_[0] }, 1);

  $client->_read_streaming_response($fh, 'GET', $handler, {});

  is join('', @got), 'first second third', 'the whole chunk arrived';
  cmp_ok scalar @got, '>=', 3,
    'in at least as many calls as it arrived in (' . scalar(@got) . ')';
};

subtest 'one byte per read: every structure boundary is fragmented' => sub {
  # The cheapest way to say "no reader assumes anything arrives whole". At one
  # byte per read the status line, each header line, the blank line, the chunk
  # header, the chunk data, the CRLF after it and the terminating zero chunk
  # are each split across several reads -- and the 8-byte frame header inside
  # the payload is split eight ways.
  my $wire = "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n";
  my $body = frame('one') . frame('two');
  $wire .= sprintf("%x\r\n", length $body) . $body . "\r\n0\r\n\r\n";

  my @got;
  my $fh = burst_handle(split //, $wire);
  my $handler = $client->_stream_handler('GET /v1.41/probe', 'on_frame',
    sub { push @got, $_[0] }, 1);

  $client->_read_streaming_response($fh, 'GET', $handler, {});

  is_deeply \@got,
    [ { stream => 'stdout', data => 'one' },
      { stream => 'stdout', data => 'two' } ],
    'both frames come out whole';

  # And the same wire read whole, so the buffered path is held to it too.
  my $buffered = $client->_read_response(burst_handle(split //, $wire), 'GET');
  is $buffered->[3], $body, 'the buffered reader reassembles it as well';
  is $buffered->[0], 200, 'and got the status line out of one-byte reads too';
};

subtest 'the caller can stop mid-stream with bytes still buffered' => sub {
  my @got;
  my $fh = burst_handle($HEAD, 'first', 'second', 'third');
  my $handler = $client->_stream_handler('GET /v1.41/probe', 'on_chunk',
    sub { push @got, $_[0]; $_[1]->() if @got == 2 }, 1);

  $client->_read_streaming_response($fh, 'GET', $handler, {});

  is_deeply \@got, ['first', 'second'], 'it stopped where it said to';
  is_deeply $handler->{summary}->(), { delivered => 2, stopped => 1 },
    'and said so';
};

# ---------------------------------------------------------------------------
# The real socket. A tied handle proves the loop; only a writer on the other
# end of a real socket proves that a read comes back with what has arrived
# rather than waiting for the rest.
#
# Runs the same scenario -- a peer that answers, writes three framed messages
# 0.15s apart and then closes -- and reports what the callback saw and when.
sub paced_writer {
  my ($option, $cb) = @_;

  socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or return;
  my $pid = fork();
  return unless defined $pid;

  unless ($pid) {
    # The daemon side. The pauses are what a coalescing reader swallows.
    close $ours;
    syswrite $theirs, $HEAD;
    for my $text ('one', 'two', 'three') {
      sleep 0.15;
      syswrite $theirs, frame($text);
    }
    close $theirs;
    exit 0;
  }

  close $theirs;
  my (@got, @at);
  my $t0 = time;
  my $handler = $client->_stream_handler('GET /v1.41/probe', $option,
    sub { push @got, $cb->($_[0]); push @at, time - $t0 }, 1);

  $client->_read_streaming_response($ours, 'GET', $handler, {});
  close $ours;
  waitpid $pid, 0;

  return (\@got, \@at);
}

subtest 'the real socket: a writer that pauses is delivered as it writes'
  => sub {
  my ($got, $at) = paced_writer('on_chunk', sub { $_[0] });
  plan skip_all => 'socketpair or fork unavailable here' unless $got;

  # This is the whole of karr k60 in one measurement, and it was taken both
  # ways round against this same scenario:
  #
  #   before (read):    1 callback call  at 0.45s
  #   after  (sysread): 3 callback calls at 0.15s, 0.30s, 0.45s
  #
  # The peer wrote at 0.15, 0.30 and 0.45 and closed. Under read() the reader
  # asked for 64K and did not come back until the close, so the caller was
  # handed the whole stream at the end of it -- on a stream that never ends,
  # never.
  is scalar @$at, 3, 'three writes, three calls -- it was one before this';
  is join('', @$got), frame('one') . frame('two') . frame('three'),
    'and between them they carry every byte, in order';

  cmp_ok $at->[0], '<', $at->[2] - 0.1,
    'the first arrived well before the last (' . sprintf('%.2fs', $at->[0])
    . ' vs ' . sprintf('%.2fs', $at->[2]) . '), so the callback ran while the '
    . 'daemon was still writing rather than after it hung up';
};

subtest 'the real socket: the same, decoded into frames' => sub {
  my ($got, $at) = paced_writer('on_frame', sub { $_[0]{data} });
  plan skip_all => 'socketpair or fork unavailable here' unless $got;

  # on_frame delivered three units before this change too -- the carry buffer
  # cut the one 64K read into three -- so the count is not what moved here.
  # The timing is: all three used to be handed over at 0.45s, when the daemon
  # closed. A caller following a live log got its output in one lump at the
  # end.
  is_deeply $got, ['one', 'two', 'three'], 'all three frames arrived';
  cmp_ok $at->[0], '<', $at->[2] - 0.1,
    'each one as it was written (' . join(', ',
      map { sprintf '%.2fs', $_ } @$at) . '), not all of them at the close';
};

done_testing;
