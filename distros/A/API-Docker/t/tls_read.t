#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Config;
use Path::Tiny;
use Time::HiRes qw( time sleep );
use API::Docker;
use API::Docker::Error::Timeout;

# karr k65. t/tls.t covers option assembly, certificate selection and the
# handshake; nothing in the suite ever reads a byte over TLS. This file is
# that read path, pinned against the three measurements taken by hand
# during the transport rebuild (karr k60), before and after, identical both
# times:
#
#   three writes 0.15s apart      -> 3 on_chunk calls, spaced apart
#   100000 bytes over many records -> every byte arrives, none lost
#   delivered, then silent, read_timeout 1 -> Error::Timeout after ~1s,
#     phase 'read', summary delivered=1, the bytes already with the callback
#
# It matters here specifically because TLS is the one transport where a
# short read is the normal case -- one plaintext record (<= 16384 bytes,
# RFC 8446 5.1) per sysread -- so the "a short read is not an end of
# stream" rule this role depends on (see _pull in
# API::Docker::Role::HTTP) has no margin to be wrong in. And
# IO::Socket::SSL's own read/sysread split -- ssl_read_all on a blocking
# socket for read(), a single Net::SSLeay::read for sysread() -- is exactly
# the distinction karr k60 is built on: get the wrong one and either every
# read blocks until the daemon closes, or a stall never times out.
#
# Certificate: generated fresh per run rather than checked in under t/, the
# same choice t/tls.t already made for the same reason -- a stored
# certificate is deterministic but expires, and CERT_create costs single-
# digit milliseconds. Gated on IO::Socket::SSL the same way t/tls.t gates
# it: a recommended, not a required, dependency, so its absence is
# skip_all rather than a failure.
#
# The server below is a forked, real TCP/TLS listener on 127.0.0.1 -- no
# Docker daemon, no network beyond loopback. Every child this file starts
# is reaped by the subtest that started it and, as a backstop for a test
# that dies before reaching that reap, by the END block at the bottom: a
# leaked server process left sleeping is worse than a missing test.

my $HAVE_SSL   = eval { require IO::Socket::SSL; 1 };
my $HAVE_UTILS = $HAVE_SSL && eval { require IO::Socket::SSL::Utils; 1 };

plan skip_all => 'IO::Socket::SSL is not installed (recommended, not '
  . 'required -- see API::Docker::Role::HTTP)' unless $HAVE_SSL;
plan skip_all => 'IO::Socket::SSL::Utils cannot generate certificates'
  unless $HAVE_UTILS;
plan skip_all => 'no fork on this platform' unless $Config{d_fork};

# ---------------------------------------------------------------------------
# One CA and one server leaf certificate, reused by every subtest below.
# ---------------------------------------------------------------------------

my $dir = Path::Tiny->tempdir;
my ($ca, $cakey) = IO::Socket::SSL::Utils::CERT_create(
  CA => 1, subject => { CN => 'API-Docker TLS-read test CA' });
my ($server_cert, $server_key) = IO::Socket::SSL::Utils::CERT_create(
  issuer          => [$ca, $cakey],
  subject         => { CN => 'localhost' },
  purpose         => 'server',
  subjectAltNames => [ [ DNS => 'localhost' ], [ IP => '127.0.0.1' ] ],
);
IO::Socket::SSL::Utils::PEM_cert2file($ca, $dir->child('ca.pem') . '');
IO::Socket::SSL::Utils::PEM_cert2file($server_cert, $dir->child('server.pem') . '');
IO::Socket::SSL::Utils::PEM_key2file($server_key, $dir->child('server-key.pem') . '');

# ---------------------------------------------------------------------------
# A TLS server that speaks whatever $respond->($conn) tells it to, once per
# connection. Forked so the parent's read is a real client of a real socket
# rather than a mock -- the whole point of this file.
# ---------------------------------------------------------------------------

my @CHILDREN;

sub start_server {
  my ($respond) = @_;

  my $listen = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1,
  ) or die "listen: $!";
  my $port = $listen->sockport;

  my $pid = fork;
  die "fork: $!" unless defined $pid;

  if (!$pid) {
    my $conn = $listen->accept;
    if ($conn && IO::Socket::SSL->start_SSL($conn,
      SSL_server    => 1,
      SSL_cert_file => $dir->child('server.pem') . '',
      SSL_key_file  => $dir->child('server-key.pem') . '',
    )) {
      $conn->autoflush(1);
      # Consume the request line and headers; every subtest below only
      # cares about what goes back, not what came in.
      while (my $line = <$conn>) { last if $line =~ /^\r?\n\z/ }
      eval { $respond->($conn) };
      close $conn;
    }
    close $listen;
    exit 0;
  }

  close $listen;
  push @CHILDREN, $pid;
  return ($port, $pid);
}

# Reaps one child immediately, so a sleeping or slow-closing server from an
# earlier subtest is never still running while a later one is measured.
sub reap {
  my ($pid) = @_;
  return unless defined $pid;
  kill 'TERM', $pid;
  waitpid $pid, 0;
  @CHILDREN = grep { $_ != $pid } @CHILDREN;
}

END {
  # The backstop for a subtest that dies before its own reap() runs: every
  # pid still in the list gets killed and waited on rather than left behind.
  for my $pid (@CHILDREN) {
    kill 'TERM', $pid;
    waitpid $pid, 0;
  }
}

sub client_for {
  my ($port, %opts) = @_;
  return API::Docker->new(
    host        => "tcp://localhost:$port",
    api_version => '1.41',
    tls         => 1,
    cert_path   => "$dir",
    %opts,
  );
}

# A response with no Content-Length and no chunked encoding: the "read
# until the daemon closes" body (API::Docker::Role::HTTP::_read_body's third
# branch), which is what an open-ended engine stream looks like on the wire
# and the one every scenario below needs -- it is the branch that hands
# on_chunk each sysread's bytes directly, one call per pull.
sub send_head {
  my ($conn) = @_;
  print $conn "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\n"
    . "Connection: close\r\n\r\n";
}

# ---------------------------------------------------------------------------
subtest 'on_chunk sees each write as it arrives, not once buffered' => sub {
  my ($port, $pid) = start_server(sub {
    my ($conn) = @_;
    send_head($conn);
    for my $n (1 .. 3) {
      sleep 0.15;
      print $conn "chunk-$n\n";
    }
  });

  my $docker = client_for($port);
  my @seen;
  my $t0 = time;
  my $summary = $docker->get('/probe',
    on_chunk     => sub { push @seen, { at => time() - $t0, bytes => $_[0] } },
    read_timeout => 10,
  );
  reap($pid);

  is scalar(@seen), 3, 'three separate on_chunk calls, one per write -- a '
    . 'transport that buffered the body whole would have delivered this as '
    . 'one call';
  is_deeply [ map { $_->{bytes} } @seen ], [ "chunk-1\n", "chunk-2\n", "chunk-3\n" ],
    'and each call carried exactly the bytes of its own write, in order';

  is $summary->{delivered}, 3, 'the summary agrees';
  is $summary->{stopped}, 0, 'the daemon ended the stream, not the callback';

  # Loose bounds throughout: this is a real socket and a real clock, and the
  # claim is "delivered incrementally, roughly on the writer's schedule" --
  # not a promise to the millisecond. A transport that reads the whole
  # response before calling back at all would show all three timestamps
  # within a few milliseconds of each other instead of ~0.15s apart.
  cmp_ok $seen[0]{at}, '>=', 0.05, 'the first chunk did not arrive before '
    . 'the server had even started waiting to send it';
  for my $i (1, 2) {
    my $gap = $seen[$i]{at} - $seen[$i - 1]{at};
    cmp_ok $gap, '>=', 0.05,
      "chunk $i and chunk " . ($i + 1) . ' are separated by a real wait, '
      . 'not delivered together (' . sprintf('%.3fs', $gap) . ')';
    cmp_ok $gap, '<', 2, 'and the wait is the one the server did, not '
      . 'something else stalling in between';
  }
  cmp_ok $seen[-1]{at}, '<', 5,
    'the whole exchange finished well inside the read_timeout';
};

# ---------------------------------------------------------------------------
subtest '100000 bytes over many TLS records arrive whole' => sub {
  my $payload = '0123456789' x 10_000;    # 100000 bytes, easy to verify
  is length($payload), 100_000, 'sanity: the payload really is 100000 bytes';

  my ($port, $pid) = start_server(sub {
    my ($conn) = @_;
    send_head($conn);
    print $conn $payload;
  });

  my $docker = client_for($port);
  my @chunks;
  my $summary = $docker->get('/probe',
    on_chunk     => sub { push @chunks, $_[0] },
    read_timeout => 10,
  );
  reap($pid);

  my $total = join '', @chunks;
  is length($total), 100_000, 'every byte arrived';
  is $total, $payload, 'and none were lost, reordered or duplicated';

  cmp_ok scalar(@chunks), '>', 1, 'delivered over more than one on_chunk '
    . 'call -- one 100000-byte write cannot be a single TLS record';
  diag(sprintf 'on_chunk called %d times for 100000 bytes (sizes: %s)',
    scalar(@chunks), join(',', map { length } @chunks));

  # RFC 8446 5.1 (and RFC 5246 6.2.1 before it): a TLS record's plaintext
  # is at most 2**14 bytes. sysread on an IO::Socket::SSL handle is a single
  # Net::SSLeay::read -- one record -- so every call this transport makes
  # must come back at or under that bound; a call larger than it would mean
  # the reader had somehow been handed more than one record's worth of
  # plaintext from a single sysread, which is not what TLS delivers.
  my $max = 0;
  $max = length($_) > $max ? length($_) : $max for @chunks;
  cmp_ok $max, '<=', 16384, 'no single on_chunk call exceeds a TLS record';

  is $summary->{delivered}, scalar(@chunks), 'the summary agrees';
  is $summary->{stopped}, 0, 'the daemon ended the stream, not the callback';
};

# ---------------------------------------------------------------------------
subtest 'read_timeout fires on an idle TLS connection, keeping what arrived' => sub {
  my ($port, $pid) = start_server(sub {
    my ($conn) = @_;
    send_head($conn);
    print $conn "first-chunk\n";
    # Deliberately never closes and never writes again: the connection goes
    # idle rather than ending, which is the case read_timeout exists for.
    sleep 5;
  });

  my $docker = client_for($port);
  my @seen;
  my $t0 = time;
  my $err = do {
    local $@;
    eval {
      $docker->get('/probe',
        on_chunk     => sub { push @seen, $_[0] },
        read_timeout => 1,
      );
    };
    $@;
  };
  my $elapsed = time - $t0;
  reap($pid);

  isa_ok $err, 'API::Docker::Error::Timeout';
  is $err && $err->phase, 'read', 'the read bound fired, not the connect one';
  is $err && $err->timeout, 1, 'naming the read_timeout that expired';

  is scalar(@seen), 1, 'the chunk that arrived before the stall reached the '
    . 'callback -- a short TLS read must not be mistaken for the end of the '
    . 'stream and swallowed';
  is $seen[0], "first-chunk\n", 'and it is the one the server actually sent';

  is $err && $err->summary && $err->summary->{delivered}, 1,
    'the exception\'s own summary agrees with what the callback saw';
  is $err && $err->partial, '',
    'a streamed request keeps no body of its own -- the bytes are with the '
    . 'callback, not duplicated onto the exception';

  cmp_ok $elapsed, '>=', 0.9, 'it waited close to the full second rather '
    . 'than giving up early';
  cmp_ok $elapsed, '<', 5, 'and it did not wait past the bound either -- '
    . 'the timer, not the 5s sleep on the other end, is what ended this '
    . '(' . sprintf('%.2fs', $elapsed) . ')';
};

done_testing;
