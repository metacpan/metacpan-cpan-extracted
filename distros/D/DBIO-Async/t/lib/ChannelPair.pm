package ChannelPair;
# Test helpers that have to behave the same on every system.
#
#   use lib 't/lib';
#   use ChannelPair;
#   my ($r, $w) = channel();   # r reads, w writes, close($w) is EOF on $r
#   get_within($future, 15);   # ->get, but red after 15 seconds, not a hang
#   within(15, sub { ... });   # run a block with a deadline (alarm's job)
#
# Why not pipe(): Future::IO's built-in loop waits with select(), and on
# Windows select() waits for sockets only -- a pipe is never reported ready
# and blocking(0) does not take on one. A fake server built on pipe() then
# tests something else than it does elsewhere, and a blocking sysread hangs.
# socketpair() hands out a real (loopback) socket pair on Windows, which
# select() does wait on, and a plain Unix socket pair elsewhere. A test that
# only needs a file descriptor to poll takes it from here too.
#
# Why no alarm(): it does not interrupt anything on Windows. A deadline here is
# a Future::IO timer: while the code waits in a loop, the timer fires, and
# its die comes out of the ->get that drives the loop (the same way any
# callback's death does). A hang outside a loop -- a blocking read -- is not
# caught; the tests read the channel with sysread only after the loop
# reported it readable.

use strict;
use warnings;

use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use IO::Handle;
use Future;
use Future::IO;
use Exporter 'import';

our @EXPORT = qw(channel get_within within);

sub channel {
  socketpair(my $r, my $w, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
  $w->autoflush(1);
  return ($r, $w);
}

# $future->get, or a failure once $secs have gone by. A Future that is ready
# already is read without a timer: a timer makes the built-in loop select()
# instead of presuming a lone read poll ready, which is nothing to change for
# a Future that needs no loop.
sub get_within {
  my ($future, $secs) = @_;
  return $future->get if $future->is_ready;
  my $timeout = Future::IO->sleep($secs || 15)
    ->then(sub { Future->fail('timed out') });
  return Future->wait_any($future, $timeout)->get;
}

# Run $code and return its result; dies "timed out" when it was still running
# in a loop after $secs. Nests: each call has a timer of its own, cancelled
# when its code is done.
sub within {
  my ($secs, $code) = @_;
  my $timer = Future::IO->sleep($secs || 15)
    ->on_done(sub { die "timed out\n" });
  my @result;
  my $ok = eval { @result = $code->(); 1 };
  my $error = $@;
  $timer->cancel unless $timer->is_ready;
  die $error unless $ok;
  return wantarray ? @result : $result[0];
}

1;
