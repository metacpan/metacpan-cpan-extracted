package SocketMode;
use strict;
use warnings;
use Fcntl qw( F_GETFL O_NONBLOCK );

# Whether a socket is in non-blocking mode, for the fakes of the future_io
# tests that record what mode their socket was in when it was read.
#
# 1 for non-blocking, 0 for blocking, undef for unknown.
#
# WHY undef: the fakes asked fcntl($fh, F_GETFL, 0) or IO::Handle->blocking
# without an argument. Windows has neither: perl's win32 build does not define
# HAS_FCNTL ("fcntl is not implemented"), and IO::Handle::blocking cannot ask
# there -- without an argument it returns undef, and blocking(0) always returns
# 1 and blocking(1) always 0, not the previous mode; it only sets FIONBIO. The
# mode of a socket cannot be read at all on that perl (and a receive probe is
# no way out: MSG_WAITALL fails there with MSG_PEEK and on a non-blocking
# socket). So the answer is unknown, and a test skips the assertion on the
# mode instead of asserting a guess.

sub nonblocking {
  my ($fh) = @_;

  my $flags = do { local $@; eval { fcntl($fh, F_GETFL, 0) } };
  return undef unless defined $flags;
  return ($flags & O_NONBLOCK) ? 1 : 0;
}

1;
