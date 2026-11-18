#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Socket;
use Errno;
use Time::HiRes qw( time );
use API::Docker;
use API::Docker::Error::Timeout;

# The read timeout of API::Docker::Role::HTTP (karr k59), in two tiers.
#
# Tier one -- everything down to "the real socket" below -- is the loop logic,
# which is where the risk is. SO_RCVTIMEO does not poison the handle and does
# not end the stream: a read that delivered nothing because the clock ran out
# comes back looking exactly like one that reached the end of the response, and
# errno is the only thing that tells them apart. Every `last unless $n` in the
# readers would otherwise take a timeout for the end of the body and hand back
# a truncated response as a whole one -- turning the hang this option removes
# into silent data loss, which is worse than the hang. So each read site is
# driven twice, once for each meaning of the same empty read, and the two have
# to come out differently. A tied handle can produce both exactly, with no
# socket and no waiting.
#
# Tier two is the one assertion a tied handle cannot make: that the setsockopt
# is really in force on a real socket. That one costs about a fifth of a
# second and needs a socketpair, no daemon and no network.
#
# What karr k60 changed here. The transport used to read with PerlIO's read()
# and readline, which fill: a read could come back with *part* of what it was
# asked for and EAGAIN at the same time, and an interrupted readline handed
# back the part of the line it had. Both of those were scripted below as one
# entry carrying data and `timeout => 1` together. sysread has no such state --
# a call that received anything returns it and leaves errno alone; only a call
# that received nothing fails with EAGAIN -- so those entries are now two: the
# delivery, and then the expiry. The scenarios and their claims are unchanged;
# what changed is that the transport can no longer be in the position of
# holding bytes it has not passed on when the clock runs out, so the entries
# that said otherwise had to be split rather than kept.
#
# What karr k64 changed here. The non-timeout half of each pair used to assert
# that a short read at a real end of response was returned as the body, and
# named that as silent loss the errno check does not address -- correctly, it
# being a close rather than a stall. Eight of those sites now croak with an
# API::Docker::Error::Truncated instead, so eight of the pairs are now
# timeout-vs-truncation rather than timeout-vs-value. The claim that carried
# over is the one this file exists for: the two meanings of an empty read
# still come out differently, and only one of them is a timeout. What went
# with it is the assumption that "not a timeout" means "returned"; site_ok now
# has each site declare which, because four of them could not otherwise fail.
# The close-delimited sites are untouched -- there an EOF is the end.
#
# What karr k73 changed here. The same again, one level up: the three
# _read_head sites below. Two of them were `returns` and are now `raises`, on
# the reasoning written out where they stand, and a third was added for the
# header block that ends on a line boundary -- the shape the old loop could
# not distinguish from a finished head at all. The close-delimited sites are
# still untouched, and still for the same reason.
#
# Nothing here reaches a Docker daemon, so there is no is_live()/can_write()
# gating: it is unconditionally safe with no engine installed.

# ---------------------------------------------------------------------------
# A tied handle scripted with what each read is to do, so both meanings of a
# read that delivers nothing can be produced on demand. One entry per sysread:
#
#   { line  => "text\n" }   a whole line arrives
#   { line  => "half" }     part of one, with the rest still to come
#   { bytes => "abc" }      three bytes
#   { bytes => '' }         the clean end of the response
#   { }                     the same, which is what running off the end gives
#   { timeout => 1 }        the clock ran out: undef, with EAGAIN in errno
#   { eintr => 1 }          a signal interrupted it: undef, with EINTR
#   { fail => 1 }           undef with errno untouched, which is what a handle
#                           that reports nothing looks like
#
# `line` and `bytes` are the same delivery -- to sysread a line and a run of
# bytes are both just bytes -- and are kept apart only so a script reads as the
# wire it stands for.
#
# Running off the end of the script is the clean end, so a scenario only has to
# script as far as the site under test. Every one of these shapes was measured
# on a real socketpair with SO_RCVTIMEO set before being written down here,
# including the one that matters most: a clean end leaves errno untouched and
# returns 0, while an expiry sets EAGAIN and returns undef.
package Test::ReadTimeout::Handle;

sub TIEHANDLE {
  my ($class, $script) = @_;
  return bless { script => $script, i => 0 }, $class;
}

sub _next {
  my ($self) = @_;
  return $self->{script}[ $self->{i}++ ] || {};
}

# sysread reaches a tied handle through READ, so this is the whole interface
# the transport uses now -- READLINE is gone from here because nothing calls
# it any more: _read_line finds its terminator in the transport's own buffer.
sub READ {
  my $self = $_[0];
  my $act  = $self->_next;

  # sysread cannot deliver and expire in the same call, unlike the PerlIO
  # read() this harness was first written against. An entry that tries to be
  # both is a script that was not translated when karr k60 landed, and saying
  # so here is cheaper than the silent near-miss it would otherwise be.
  die "a scripted read cannot both deliver and expire\n"
    if ($act->{timeout} || $act->{eintr} || $act->{fail})
      && (defined $act->{line} || defined $act->{bytes});

  # Set last and read first: errno is only meaningful straight after the
  # operation that failed, which is exactly the discipline the code under
  # test has to keep. With keep_errno it is left exactly as the caller left
  # it, which is how a stale value gets in front of the check.
  unless ($act->{keep_errno}) {
    $! = $act->{timeout} ? Errno::EAGAIN()
      : $act->{eintr}    ? Errno::EINTR()
      : 0;
  }
  return undef if $act->{timeout} || $act->{eintr} || $act->{fail};

  my $data = defined $act->{line} ? $act->{line}
    : defined $act->{bytes} ? $act->{bytes} : '';
  $_[1] = $data;
  # 0 is the clean end of the response, and is the only thing that means it.
  return length $data;
}

sub CLOSE { 1 }

package main;

my $client = API::Docker->new(
  host        => 'unix:///nonexistent.sock',
  api_version => '1.41',
);

my $ENDPOINT = 'GET /v1.41/probe';

sub scripted {
  my (@script) = @_;
  no warnings "once";
  my $glob = \do { local *HANDLE };
  tie *$glob, 'Test::ReadTimeout::Handle', \@script;
  return $glob;
}

# A context with the clock running, and one without. The second is what every
# call made before this option existed passes, and it must leave every read
# site behaving exactly as it did.
sub ctx      { return { endpoint => $ENDPOINT, timeout => 2 } }
sub ctx_off  { return { endpoint => $ENDPOINT } }

# Run $code and report whether it raised a timeout, so the two meanings of one
# short read can be asserted side by side.
sub timed_out {
  my ($code) = @_;
  my @out = eval { $code->() };
  my $err = $@;
  return (undef, $err) if $err && ref $err
    && $err->isa('API::Docker::Error::Timeout');
  return (\@out, undef) unless $err;
  return (undef, undef, $err);
}

# Reading an attribute off whatever was raised, so a mutation that stops
# raising one fails the assertion it belongs to instead of dying and taking
# the rest of the file with it -- a red test has to stay readable.
sub attr {
  my ($err, $name) = @_;
  return ref $err && $err->can($name) ? $err->$name : undef;
}

# The pair of assertions every read site gets: with EAGAIN it croaks with a
# timeout, without it it does whatever a real end of the response means at
# that site. A test that only made the first half would pass just as well
# against a transport that croaked on every end of response.
#
# The second half is declared, not merely inspected. Each site says which of
# the two shapes it has -- `returns => sub {...}` for a site where the close
# really is the end of the response, `raises => sub {...}` for one where it is
# not -- and site_ok asserts that it is that shape and not the other one. The
# earlier version took a single check sub and ran it either way, so a site
# that started croaking where it used to return still passed as long as the
# check itself did not look at the return value. Four of the streaming sites
# below were in exactly that position when karr k64 landed: the check asserted
# what had reached the callback, which a croak does not change, so the change
# in outcome went unseen. Declaring the shape is what makes those four able to
# fail.
sub site_ok {
  my ($name, $make_handle, $drive, %eof) = @_;

  die "site_ok $name: declare exactly one of returns/raises\n"
    unless 1 == grep { $eof{$_} } qw( returns raises );

  subtest $name => sub {
    my ($out, $err, $other) = timed_out(
      sub { $drive->($make_handle->(1), ctx()) });
    ok !$other, 'the expiry raised nothing but a timeout'
      or diag "raised instead: $other";
    ok $err, 'ran out of time -> API::Docker::Error::Timeout';
    is $err && attr($err, "timeout"), 2, 'the error names the timeout that expired'
      if $err;
    is $err && attr($err, "endpoint"), $ENDPOINT, 'and the request it belongs to'
      if $err;

    my ($eof_out, $eof_err, $eof_other) = timed_out(
      sub { $drive->($make_handle->(0), ctx()) });
    ok !$eof_err, 'the same short read at the end of the response is not a '
      . 'timeout';
    if ($eof{raises}) {
      ok $eof_other, 'it raises something else instead'
        or diag 'returned instead of raising';
      $eof{raises}->($eof_other) if $eof_other;
    }
    else {
      ok !$eof_other, 'and raises nothing at all'
        or diag "raised: $eof_other";
      $eof{returns}->($eof_out) unless $eof_other;
    }

    # And with no timeout armed, the EAGAIN case is not a timeout either --
    # the option is what turns the check on, not the errno.
    my ($off_out, $off_err, $off_other) = timed_out(
      sub { $drive->($make_handle->(1), ctx_off()) });
    ok !$off_err, 'with no read_timeout set, EAGAIN is not consulted at all';
  };
}

# What a site that is cut short has to raise. The phase says which piece of
# the framing ended early, so a check that only asked for the class would pass
# against a transport that noticed the wrong one.
sub truncated_ok {
  my (%want) = @_;

  return sub {
    my ($err) = @_;
    isa_ok $err, 'API::Docker::Error::Truncated';
    is attr($err, 'phase'), $want{phase},
      'and says where the response was cut: ' . $want{phase};
    is attr($err, 'endpoint'), $ENDPOINT, 'and the request it belongs to';
    is attr($err, 'partial'), $want{partial},
      'carrying the bytes that did arrive'
      if exists $want{partial};
    is_deeply attr($err, 'summary'), $want{summary},
      'and the units the callback was handed'
      if exists $want{summary};
    # Where one phase covers two distinct ways of running out -- 'header-block'
    # is both "cut inside a field" and "the blank line never came" -- the phase
    # alone cannot fail when only one of the two checks is removed. The message
    # is what separates them, so a site that has two halves pins it.
    like "$err", $want{message}, 'and which of them ran out'
      if exists $want{message};
  };
}

my $HEAD_OK = { line => "HTTP/1.1 200 OK\r\n" };
my $BLANK   = { line => "\r\n" };

# ---------------------------------------------------------------------------
# _read_head -- the status line and the header block
# ---------------------------------------------------------------------------
site_ok '_read_head: the status line never arrives',
  sub { scripted({ timeout => $_[0] }) },
  sub { $client->_read_head($_[0], $_[1]) },
  raises => sub {
    like $_[0], qr/No response from Docker daemon/,
      'a daemon that closed without answering still says so, and says '
      . 'something else than a timeout';
  };

# The head, which karr k73 brought under the same check. These two sites used
# to be `returns` -- the first asserting that 'HTTP/1.1 20' came back as the
# status '20', the second that the headers arriving before the cut were kept
# -- on the reading that nothing in a head announces its own length, so there
# was no announcement to hold a short one against. What replaces that claim is
# not a softer version of it but its opposite: a head is framed by its
# terminators rather than by a length, so an end of stream where one belongs
# is decidable without anything to compare, exactly as it is for a chunk
# header one level down. Both are now `raises`.
#
# The claim these sites carry over is the one the file exists for, and it is
# untouched: the two meanings of the same empty read still come out
# differently, and only EAGAIN is a timeout. That distinction lives in _pull,
# below the new check, so nothing about it moved.
site_ok '_read_head: half a status line',
  sub { scripted({ line => 'HTTP/1.1 20' }, { timeout => $_[0] }) },
  sub { $client->_read_head($_[0], $_[1]) },
  raises => truncated_ok(phase => 'status-line', partial => '',
    message => qr/inside the status line, after 11 bytes of one/);

site_ok '_read_head: the header block stops halfway',
  sub {
    scripted($HEAD_OK, { line => "Content-Type: application/json\r\n" },
      { line => 'X-Half' }, { timeout => $_[0] });
  },
  sub { $client->_read_head($_[0], $_[1]) },
  raises => truncated_ok(phase => 'header-block', partial => '',
    message => qr/inside a header line, after 6 bytes of one/);

# The other half of the same phase, and the one the old header loop could not
# tell from a finished head at all: the block ends on a line boundary with the
# blank line never sent. `while (my $line = ...)` ended there silently, so a
# cut landing before Content-Length and Transfer-Encoding left neither, and
# _read_body then took the close-delimited branch where an EOF is the
# legitimate end.
site_ok '_read_head: the header block is never closed',
  sub {
    scripted($HEAD_OK, { line => "Content-Type: application/json\r\n" },
      { timeout => $_[0] });
  },
  sub { $client->_read_head($_[0], $_[1]) },
  raises => truncated_ok(phase => 'header-block', partial => '',
    message => qr/where a header line belongs, with no blank line/);

# ---------------------------------------------------------------------------
# _read_body -- the three shapes a buffered body comes in
# ---------------------------------------------------------------------------
# The four sites karr k64 changed. Each of them used to assert that the short
# read at a real end of response was RETURNED -- 'hello wor', 'hello' -- and
# named that as the silent loss the errno check could not prevent, the errno
# check being about a timeout and this being about a close. The claim that
# survives is the one those assertions were making about the timeout: the two
# meanings of an empty read still come out differently, and only one of them
# is a timeout. What is replaced is the other half of each pair, which is now
# an API::Docker::Error::Truncated instead of a value.
site_ok '_read_body: a content-length body stops short',
  sub {
    scripted({ bytes => 'hello ' }, { bytes => 'wor' },
      { timeout => $_[0] });
  },
  sub {
    $client->_read_body($_[0], { 'content-length' => 11 }, 'GET', $_[1]);
  },
  raises => truncated_ok(phase => 'content-length', partial => 'hello wor');

# The one body shape where an EOF is the end and must stay one: nothing was
# announced, so there is nothing to be short of.
site_ok '_read_body: a close-delimited body stops short',
  sub { scripted({ bytes => 'partial frames' }, { timeout => $_[0] }) },
  sub { $client->_read_body($_[0], {}, 'GET', $_[1]) },
  returns => sub {
    my ($out) = @_;
    is $out->[0], 'partial frames', 'the bytes are the body at a real close';
  };

site_ok '_read_chunked: the chunk header stops halfway',
  sub {
    scripted({ line => "5\r\n" }, { bytes => 'hello' }, { line => "\r\n" },
      { line => '1a' }, { timeout => $_[0] });
  },
  sub { $client->_read_chunked($_[0], $_[1]) },
  raises => truncated_ok(phase => 'chunk-header', partial => 'hello',
    message => qr/inside a chunk header, after 2 bytes of one/);

# The other half of the same phase (karr k77), the one _read_head's
# header-block already pins (karr k73): the stream ends where the next chunk
# header would start, with no terminating zero chunk ever sent. Undecidable
# from 'stops halfway' by phase alone -- both raise 'chunk-header' -- so only
# the message tells them apart, and only a script that never sends a byte of
# the next header exercises this half rather than the other one.
site_ok '_read_chunked: the chunk header never arrives',
  sub {
    scripted({ line => "5\r\n" }, { bytes => 'hello' }, { line => "\r\n" },
      { timeout => $_[0] });
  },
  sub { $client->_read_chunked($_[0], $_[1]) },
  raises => truncated_ok(phase => 'chunk-header', partial => 'hello',
    message => qr/where a chunk header belongs, with no terminating zero chunk/);

site_ok '_read_chunked: the chunk data stops short',
  sub {
    scripted({ line => "5\r\n" }, { bytes => 'hello' }, { line => "\r\n" },
      { line => "6\r\n" }, { bytes => ' wor' }, { timeout => $_[0] });
  },
  sub { $client->_read_chunked($_[0], $_[1]) },
  raises => truncated_ok(phase => 'chunk-data', partial => 'hello wor');

site_ok '_read_chunked: the CRLF after the chunk data never arrives',
  sub {
    scripted({ line => "5\r\n" }, { bytes => 'hello' },
      { timeout => $_[0] });
  },
  sub { $client->_read_chunked($_[0], $_[1]) },
  raises => truncated_ok(phase => 'chunk-terminator', partial => 'hello');

# ---------------------------------------------------------------------------
# _read_streaming_response -- the same three shapes, one callback at a time
# ---------------------------------------------------------------------------
sub chunk_handler {
  my ($got) = @_;
  return $client->_stream_handler($ENDPOINT, 'on_chunk',
    sub { push @$got, $_[0] }, 1);
}

sub drive_stream {
  my ($got) = @_;
  return sub {
    my ($fh, $c) = @_;
    return $client->_read_streaming_response($fh, 'GET', chunk_handler($got), $c);
  };
}

# The claim these four make about the callback is unchanged and is the reason
# they are still driven twice: every byte that arrived reaches it before
# either exception is raised, so both runs deliver the same units. What karr
# k64 changed is only which exception the second run raises. Until then their
# checks looked at @got alone -- which a croak does not disturb -- so all four
# went on passing when the transport started croaking, which is the hole
# site_ok's declared shape closes.
{
  my @got;
  site_ok 'streaming, chunked: the chunk header stops halfway',
    sub {
      scripted($HEAD_OK, { line => "Transfer-Encoding: chunked\r\n" }, $BLANK,
        { line => "5\r\n" }, { bytes => 'hello' }, { line => "\r\n" },
        { line => '1a' }, { timeout => $_[0] });
    },
    drive_stream(\@got),
    raises => sub {
      truncated_ok(phase => 'chunk-header', partial => '',
        summary => { delivered => 1, stopped => 0 },
        message => qr/inside a chunk header, after 2 bytes of one/)->(@_);
      is_deeply \@got, ['hello', 'hello'],
        'both runs delivered the completed chunk';
    };
}

# The third site sharing this phase (karr k77), and the other half of it: the
# stream ends where the next chunk header would start rather than inside one.
# A third site is what made it worth re-checking the whole file for the same
# gap header-block had already closed at three sites of its own (karr k73) --
# this is the second phase found with two ways to run out and only one
# pinned, and it turned up twice over (buffered and streamed), not once.
{
  my @got;
  site_ok 'streaming, chunked: the chunk header never arrives',
    sub {
      scripted($HEAD_OK, { line => "Transfer-Encoding: chunked\r\n" }, $BLANK,
        { line => "5\r\n" }, { bytes => 'hello' }, { line => "\r\n" },
        { timeout => $_[0] });
    },
    drive_stream(\@got),
    raises => sub {
      truncated_ok(phase => 'chunk-header', partial => '',
        summary => { delivered => 1, stopped => 0 },
        message => qr/where a chunk header belongs, with no terminating zero chunk/)
        ->(@_);
      is_deeply \@got, ['hello', 'hello'],
        'both runs delivered the completed chunk';
    };
}

{
  my @got;
  site_ok 'streaming, chunked: the chunk data stops short',
    sub {
      scripted($HEAD_OK, { line => "Transfer-Encoding: chunked\r\n" }, $BLANK,
        { line => "6\r\n" }, { bytes => ' wor' }, { timeout => $_[0] });
    },
    drive_stream(\@got),
    raises => sub {
      truncated_ok(phase => 'chunk-data', partial => '',
        summary => { delivered => 1, stopped => 0 })->(@_);
      is_deeply \@got, [' wor', ' wor'],
        'every byte that arrived reached the callback before the exception '
        . 'was raised, so both runs deliver the same units and only the '
        . 'reason for stopping differs';
    };
}

{
  my @got;
  site_ok 'streaming, chunked: the CRLF after the chunk data never arrives',
    sub {
      scripted($HEAD_OK, { line => "Transfer-Encoding: chunked\r\n" }, $BLANK,
        { line => "5\r\n" }, { bytes => 'hello' }, { timeout => $_[0] });
    },
    drive_stream(\@got),
    raises => sub {
      truncated_ok(phase => 'chunk-terminator', partial => '',
        summary => { delivered => 1, stopped => 0 })->(@_);
      is_deeply \@got, ['hello', 'hello'], 'the chunk was delivered';
    };
}

{
  my @got;
  site_ok 'streaming, content-length: the body stops short',
    sub {
      scripted($HEAD_OK, { line => "Content-Length: 11\r\n" }, $BLANK,
        { bytes => 'hello ' }, { bytes => 'wor' }, { timeout => $_[0] });
    },
    drive_stream(\@got),
    raises => sub {
      truncated_ok(phase => 'content-length', partial => '',
        summary => { delivered => 2, stopped => 0 })->(@_);
      is_deeply \@got, ['hello ', 'wor', 'hello ', 'wor'],
        'same on the content-length path: nothing that arrived is dropped '
        . 'because the rest of it did not';
    };
}

# And the streamed half of the one shape with no announcement to fall short
# of. This is the raw-stream path -- attach, logs(follow), exec/start -- where
# a close is how every one of them finishes.
{
  my @got;
  site_ok 'streaming, close-delimited: the body stops short',
    sub {
      scripted($HEAD_OK, $BLANK,
        { bytes => 'frame one' }, { bytes => 'fra' }, { timeout => $_[0] });
    },
    drive_stream(\@got),
    returns => sub {
      is_deeply \@got, ['frame one', 'fra', 'frame one', 'fra'],
        'and on the raw-stream path, which is the one karr k52 hangs on and '
        . 'where it matters most -- and where the two bursts are two calls '
        . 'rather than one 64K read, which is karr k60';
    };
}

# ---------------------------------------------------------------------------
# What the exception carries
# ---------------------------------------------------------------------------
subtest 'the bytes that did arrive come out with the exception' => sub {
  subtest 'a content-length body' => sub {
    my $fh = scripted({ bytes => 'hello ' }, { bytes => 'wor' },
      { timeout => 1 });
    eval { $client->_read_body($fh, { 'content-length' => 11 }, 'GET', ctx()) };
    my $err = $@;
    isa_ok $err, 'API::Docker::Error::Timeout';
    is attr($err, "partial"), 'hello wor',
      'everything read so far, the bytes of the read that expired included';
    is attr($err, "summary"), undef, 'no summary: nothing was streamed';
  };

  subtest 'a chunked body keeps the chunk it stalled inside' => sub {
    my $fh = scripted({ line => "5\r\n" }, { bytes => 'hello' },
      { line => "\r\n" }, { line => "6\r\n" }, { bytes => ' wor' },
      { timeout => 1 });
    eval { $client->_read_chunked($fh, ctx()) };
    my $err = $@;
    isa_ok $err, 'API::Docker::Error::Timeout';
    is attr($err, "partial"), 'hello wor',
      'the completed chunk and the part of the one still arriving';
  };

  subtest 'a close-delimited body' => sub {
    my $fh = scripted({ bytes => 'partial frames' }, { timeout => 1 });
    eval { $client->_read_body($fh, {}, 'GET', ctx()) };
    isa_ok $@, 'API::Docker::Error::Timeout';
    is attr($@, "partial"), 'partial frames', 'the bytes the slurp had collected';
  };

  subtest 'a streamed request carries the summary instead' => sub {
    my @got;
    my $fh = scripted($HEAD_OK, { line => "Transfer-Encoding: chunked\r\n" },
      $BLANK,
      { line => "5\r\n" }, { bytes => 'hello' }, { line => "\r\n" },
      { line => "5\r\n" }, { bytes => 'there' }, { line => "\r\n" },
      { timeout => 1 });
    eval {
      $client->_read_streaming_response($fh, 'GET', chunk_handler(\@got), ctx());
    };
    my $err = $@;
    isa_ok $err, 'API::Docker::Error::Timeout';
    is_deeply attr($err, "summary"), { delivered => 2, stopped => 0 },
      'the units the callback did get, counted the way a clean end counts them';
    is attr($err, "partial"), '',
      'and no body: a streamed request keeps none by design';
    like attr($err, "message"), qr/2 units/, 'the message says so too';
  };

  subtest 'everything that arrived is delivered before the expiry' => sub {
    # This is the shape karr k52 actually has: everything the daemon had to
    # say arrives, and the socket then stays open and silent. Measured against
    # Podman 5.8.4 on an attach to an exited container: two frames, 42 bytes,
    # delivered 0 before karr k59 and 2 after.
    #
    # Under read() those 42 bytes and the expiry were one call, and k59 had to
    # rescue them out of it. Under sysread they are two -- the delivery, then
    # the silence -- and the property holds without a rescue, which is why the
    # script below has two entries where it used to have one. What is asserted
    # is the property, not the mechanism: at the moment the exception is
    # raised, the caller is holding everything the daemon sent.
    my @got;
    my $fh = scripted($HEAD_OK, $BLANK,
      { bytes => 'frame one and two' }, { timeout => 1 });
    eval {
      $client->_read_streaming_response($fh, 'GET', chunk_handler(\@got), ctx());
    };
    my $err = $@;
    isa_ok $err, 'API::Docker::Error::Timeout';
    is_deeply \@got, ['frame one and two'],
      'the callback got every byte that arrived';
    is_deeply attr($err, 'summary'), { delivered => 1, stopped => 0 },
      'and the summary counts them, so it says what happened rather than '
      . 'undercounting it';
  };

  subtest 'an error body on the way to a >= 400 croak is counted in bytes' => sub {
    # The summary is only armed past the status line, so a timeout while
    # reading the short JSON body of a failure is not reported as units that
    # nothing delivered.
    my @got;
    my $fh = scripted({ line => "HTTP/1.1 500 Internal Server Error\r\n" },
      { line => "Content-Length: 40\r\n" }, $BLANK,
      { bytes => '{"message":"bo' }, { timeout => 1 });
    eval {
      $client->_read_streaming_response($fh, 'GET', chunk_handler(\@got), ctx());
    };
    my $err = $@;
    isa_ok $err, 'API::Docker::Error::Timeout';
    is attr($err, "summary"), undef, 'no summary for a body that was never a stream';
    is attr($err, "partial"), '{"message":"bo', 'the bytes of the error body';
  };

  subtest 'nothing at all is said so, not reported as zero bytes' => sub {
    my $fh = scripted($HEAD_OK, { line => "Content-Length: 11\r\n" }, $BLANK,
      { timeout => 1 });
    eval { $client->_read_response($fh, 'GET', ctx()) };
    my $err = $@;
    isa_ok $err, 'API::Docker::Error::Timeout';
    is attr($err, "partial"), '', 'partial is empty';
    like attr($err, "message"), qr/nothing arrived at all/, 'and the message says so';
  };
};

subtest 'the exception is still the string it replaces' => sub {
  my $fh = scripted({ timeout => 1 });
  eval { $client->_read_head($fh, ctx()) };
  my $err = $@;
  isa_ok $err, 'API::Docker::Error::Timeout';
  ok overload::Overloaded($err),
    'stringification is in place -- namespace::clean before use overload';
  unlike "$err", qr/=HASH\(0x/,
    "stringifies to the reason, not to a reference address";
  like "$err", qr/\Q$ENDPOINT\E/, 'the request is named in the string';
  like "$err", qr/ at \S+ line \d+/, 'with Carp\'s own location suffix';
  ok !!$err, 'and it is true as an exception';
};

# ---------------------------------------------------------------------------
# A real socket: that the setsockopt is in force, and that _request arms it
# ---------------------------------------------------------------------------
subtest 'the real socket: SO_RCVTIMEO is actually set' => sub {
  socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or plan skip_all => "socketpair unavailable: $!";

  $client->_apply_read_timeout($ours, 0.2);

  # The peer is open and silent, so without the option in force this read
  # blocks forever and the test never finishes.
  my $t0 = time;
  eval { $client->_read_line($ours, ctx()) };
  my $err     = $@;
  my $elapsed = time - $t0;

  isa_ok $err, 'API::Docker::Error::Timeout';
  cmp_ok $elapsed, '>=', 0.15,
    'it waited for the timeout rather than returning at once ('
    . sprintf('%.2fs', $elapsed) . ')';
  cmp_ok $elapsed, '<', 5, 'and gave up rather than hanging';

  # Not poisoned: the same handle keeps working afterwards, which is what
  # makes this an idle timeout per read rather than a dead connection.
  syswrite $theirs, "still here\n";
  is $client->_read_line($ours, ctx()), "still here\n",
    'and the handle still reads after an expiry';

  close $ours;
  close $theirs;
};

subtest 'a stale errno cannot be mistaken for this read timing out' => sub {
  socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or plan skip_all => "socketpair unavailable: $!";
  $client->_apply_read_timeout($ours, 5);

  syswrite $theirs, "a whole line\nand 12 bytes";
  close $theirs;   # the clean end of the response, with no waiting involved

  # errno is only meaningful straight after the operation that failed, and
  # nothing clears it on success -- so whatever the process did before this
  # request is still sitting in it. The read sites zero it immediately before
  # each read for exactly this reason: without that, every clean end of a
  # response that happened to follow an unrelated EAGAIN would be reported as
  # this request timing out, and the option would break working code.
  $! = Errno::EAGAIN();
  is $client->_read_line($ours, ctx()), "a whole line\n",
    'a complete line still arrives';

  $! = Errno::EAGAIN();
  my ($n, $buf) = $client->_read_bytes($ours, 4096, ctx());
  is $buf, 'and 12 bytes', 'a short read at the end of the response is not '
    . 'turned into a timeout by an errno left over from before it';

  $! = Errno::EAGAIN();
  my $out = eval { $client->_read_line($ours, ctx()) };
  ok !$@, 'nor is the end of the response itself' or diag "raised: $@";
  is $out, undef, 'which is simply undef, as it always was';

  close $ours;
};

subtest 'the read sites clear errno rather than trusting what they find'
  => sub {
  # The socketpair above cannot show this on its own: perl's own read paths
  # happen to zero errno on a socket, so removing the zeroing there changes
  # nothing. A handle that leaves errno alone is the only way to pin that the
  # check reads the errno of *this* read and not one from before it -- and
  # _pull is the primitive every reader is built out of, so its correctness
  # must not rest on a perl internal that is documented nowhere.
  #
  # The case that can go wrong is a read that fails while saying nothing about
  # why. Without the zeroing an unrelated EAGAIN from earlier in the process is
  # still sitting in errno, and the end of this response is reported as this
  # request timing out -- which is the option breaking working code.
  my $fh = scripted({ fail => 1, keep_errno => 1 });
  $! = Errno::EAGAIN();
  my ($n, $buf) = eval { $client->_read_bytes($fh, 4096, ctx()) };
  ok !$@, 'a read that failed silently is not a timeout because of an older '
    . 'EAGAIN' or diag "raised: $@";
  is $n, 0, 'it is the end of the response, as it always was';

  my $lh = scripted({ fail => 1, keep_errno => 1 });
  $! = Errno::EAGAIN();
  my $line = eval { $client->_read_line($lh, ctx()) };
  ok !$@, 'nor is one on the line path' or diag "raised: $@";
  is $line, undef, 'which is simply undef';

  # And a read that delivered is never asked about errno at all: a short
  # positive count is the normal case over TLS, one record at a time.
  my $dh = scripted({ bytes => 'twelve bytes', keep_errno => 1 });
  $! = Errno::EAGAIN();
  my ($dn, $dbuf) = eval { $client->_read_bytes($dh, 4096, ctx()) };
  ok !$@, 'a short delivery is not a timeout either' or diag "raised: $@";
  is $dbuf, 'twelve bytes', 'and the bytes come back';

  my $th = scripted({ line => 'no terminator' });
  my $tline = eval { $client->_read_line($th, ctx()) };
  ok !$@, 'nor is an unterminated final line' or diag "raised: $@";
  is $tline, 'no terminator', 'which is returned as the line it is';
};

subtest 'a signal is retried, not mistaken for either meaning' => sub {
  # perl's read() retried on EINTR of its own accord (PerlIOUnix_read loops
  # while errno is EINTR); _pull calls sysread, which does not, so the retry
  # had to be written out. Without it a SIGCHLD arriving mid-read would end
  # the response early -- and with a read_timeout armed it would not even be
  # reported as a timeout, so the caller would get a truncated body and no
  # sign that anything happened.
  my $fh = scripted({ eintr => 1 }, { bytes => 'after the signal' },
    { eintr => 1 }, { bytes => ' and another' });
  my ($n, $buf) = eval { $client->_read_bytes($fh, 4096, ctx()) };
  ok !$@, 'an interrupted read raises nothing' or diag "raised: $@";
  is $buf, 'after the signal', 'it is retried and the data comes back';

  my ($n2, $buf2) = eval { $client->_read_bytes($fh, 4096, ctx()) };
  is $buf2, ' and another', 'and again, so it is a loop rather than one retry';

  # With no timeout armed too: the retry is not part of the timeout check.
  my $off = scripted({ eintr => 1 }, { bytes => 'still read' });
  my ($n3, $buf3) = eval { $client->_read_bytes($off, 4096, ctx_off()) };
  ok !$@, 'and with no read_timeout set' or diag "raised: $@";
  is $buf3, 'still read', 'the retry happens there as well';
};

subtest 'a socket that cannot take a timeout is refused, not ignored' => sub {
  # A real, open handle that is simply not a socket -- so setsockopt fails
  # with ENOTSOCK rather than with "unopened", which is the shape a wrong
  # transport would actually have.
  open my $fh, '<', '/dev/null' or die $!;

  eval { $client->_apply_read_timeout($fh, 1) };
  like $@, qr/cannot set a read timeout/,
    'setsockopt failing croaks: a caller waiting on a bound that is not in '
    . 'force is the very failure this option exists to end';

  is $client->_apply_read_timeout($fh, undef), undef,
    'with no timeout asked for, nothing is attempted and nothing complains';
  close $fh;
};

# ---------------------------------------------------------------------------
# _request: which value ends up on the socket
# ---------------------------------------------------------------------------
{
  package Test::ReadTimeout::Recorder;
  use Moo;
  extends 'API::Docker';

  # A client whose socket is one end of a socketpair with the whole response
  # already in it, so the real _request runs against a real socket -- and
  # whose peer is held open and never written to again, so anything reading
  # past the response is a genuine wait.
  has canned => (is => 'rw', default => sub { '' });
  has peer   => (is => 'rw');
  has armed  => (is => 'rw', default => sub { [] });

  sub _build__socket {
    my ($self) = @_;
    socketpair(my $ours, my $theirs, Socket::AF_UNIX(), Socket::SOCK_STREAM(),
      Socket::PF_UNSPEC()) or die "socketpair: $!";
    syswrite $theirs, $self->canned;
    $self->peer($theirs);
    return $ours;
  }

  around _apply_read_timeout => sub {
    my ($orig, $self, $sock, $timeout) = @_;
    push @{ $self->armed }, $timeout;
    return $self->$orig($sock, $timeout);
  };
}

sub recorder {
  my (%args) = @_;
  return Test::ReadTimeout::Recorder->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    canned      => "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n{}",
    %args,
  );
}

subtest '_request: the per-call option and the client attribute' => sub {
  subtest 'neither set -- nothing is armed, which is the old behaviour' => sub {
    my $c = recorder();
    is_deeply $c->get('/probe'), {}, 'the request still works';
    is_deeply $c->armed, [undef], 'no timeout reached the socket';
  };

  subtest 'the attribute applies to every request' => sub {
    my $c = recorder(read_timeout => 7);
    $c->get('/probe');
    $c->get('/probe');
    is_deeply $c->armed, [7, 7], 'both requests armed it';
  };

  subtest 'the option overrides the attribute' => sub {
    my $c = recorder(read_timeout => 7);
    $c->get('/probe', read_timeout => 1.5);
    is_deeply $c->armed, [1.5], 'the call wins';
  };

  subtest '0 turns a client default off for one call' => sub {
    my $c = recorder(read_timeout => 7);
    $c->get('/probe', read_timeout => 0);
    is_deeply $c->armed, [undef],
      'an explicit 0 is "wait as long as it takes", not "no opinion" -- '
      . 'which is why the option is resolved with exists rather than //';
  };

  subtest 'undef turns it off too' => sub {
    my $c = recorder(read_timeout => 7);
    $c->get('/probe', read_timeout => undef);
    is_deeply $c->armed, [undef], 'passing undef explicitly is the same as 0';
  };

  subtest 'a value that is not a timeout is refused before connecting' => sub {
    my $c = recorder();
    for my $bad (-1, 'soon', {}) {
      eval { $c->get('/probe', read_timeout => $bad) };
      like $@, qr/read_timeout must be a non-negative number/,
        'refused: ' . (ref $bad ? 'a reference' : $bad);
    }
    is_deeply $c->armed, [], 'and nothing was armed, so nothing was sent';
  };
};

subtest '_request: end to end on a real socket, with the response cut short'
  => sub {
  # Content-Length promises 40 bytes and 14 arrive; the peer stays open and
  # silent, which is karr k52's hang exactly.
  my $c = recorder(
    canned       => "HTTP/1.1 200 OK\r\nContent-Length: 40\r\n\r\nhalf a body!!!",
    read_timeout => 0.2,
  );

  my $t0 = time;
  eval { $c->get('/probe') };
  my $err     = $@;
  my $elapsed = time - $t0;

  isa_ok $err, 'API::Docker::Error::Timeout';
  is attr($err, "partial"), 'half a body!!!',
    'the bytes that did arrive are on the exception rather than returned as '
    . 'though they were the whole body';
  is attr($err, "endpoint"), 'GET /v1.41/probe', 'the endpoint, without a query string';
  is attr($err, "timeout"), 0.2, 'the timeout that expired';
  cmp_ok $elapsed, '<', 5, 'it gave up instead of hanging';
  close $c->peer;
};

subtest '_request: a response that is complete is not affected by a timeout'
  => sub {
  my $c = recorder(read_timeout => 0.2);
  my $got = $c->get('/probe');
  is_deeply $got, {}, 'a whole body comes back as it always did';
  close $c->peer;
};

done_testing;
