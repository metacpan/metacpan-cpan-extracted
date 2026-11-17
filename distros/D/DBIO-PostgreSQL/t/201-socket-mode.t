use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use Socket qw( AF_UNIX SOCK_STREAM PF_UNSPEC );
use Fcntl qw( F_GETFL );
use IO::Handle;

# A perl without fcntl (Windows) is emulated: the override must be in place
# before SocketMode is compiled.
our $NO_FCNTL = 0;
BEGIN {
  *CORE::GLOBAL::fcntl = sub {
    die "The fcntl function is unimplemented\n" if $main::NO_FCNTL;
    return CORE::fcntl($_[0], $_[1], $_[2]);
  };
}
use SocketMode;

# OFFLINE test of t/lib/SocketMode.pm, which the fakes of t/62 and t/75 ask
# for the blocking mode of their socket.
#
# WHY: Windows has no fcntl and IO::Handle::blocking cannot ask the mode
# there, so the mode of a socket cannot be read at all. SocketMode answers
# from fcntl where perl has it and says "unknown" (undef) where it has not, so
# a test skips its assertions on the mode instead of asserting a guess.
#
# What this file claims:
#   1. with fcntl (part 1 runs only where perl has F_GETFL, else it skips), a blocking socket is blocking (0), a non-blocking one
#      non-blocking (1), also when it holds bytes, and the bytes stay;
#   2. without fcntl, the answer is undef for both modes, and no mode changes.

sub unix_pair {
  socketpair(my $client, my $server, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
  return ($client, $server);
}

# Does this perl have fcntl? Asked through the override (a call without CORE::),
# with F_GETFL alone: the mode of the socket is read, never set.
my $have_fcntl = do {
  my ($c) = unix_pair();
  my $mode = eval { fcntl($c, F_GETFL, 0) };
  defined $mode;
};

SKIP: {
  skip 'this perl has no fcntl (F_GETFL): the mode of a socket cannot be read', 5
    unless $have_fcntl;
  my ($c, $s) = unix_pair();
  $c->blocking(1);
  is SocketMode::nonblocking($c), 0, 'fcntl: a blocking socket is blocking';
  $c->blocking(0);
  is SocketMode::nonblocking($c), 1, 'fcntl: a non-blocking socket is non-blocking';

  syswrite $s, "held\n";
  is SocketMode::nonblocking($c), 1, 'fcntl: ... with bytes in it too';
  $c->blocking(1);
  is SocketMode::nonblocking($c), 0, 'fcntl: a blocking socket with bytes in it is blocking';
  sysread $c, my $buf, 100;
  is $buf, "held\n", 'fcntl: the bytes are still in the socket after the questions';
}

{
  local $NO_FCNTL = 1;
  my ($c, $s) = unix_pair();
  $c->blocking(1);
  is SocketMode::nonblocking($c), undef, 'no fcntl: a blocking socket is unknown';
  $c->blocking(0);
  is SocketMode::nonblocking($c), undef, 'no fcntl: a non-blocking socket is unknown';
  syswrite $s, "held\n";
  is SocketMode::nonblocking($c), undef, 'no fcntl: ... with bytes in it too';
  sysread $c, my $buf, 100;
  is $buf, "held\n", 'no fcntl: the bytes are still in the socket';
  local $NO_FCNTL = 0;
  SKIP: {
    skip 'this perl has no fcntl (F_GETFL): the mode of a socket cannot be read', 1
      unless $have_fcntl;
    is SocketMode::nonblocking($c), 1, 'the socket kept its mode (non-blocking)';
  }
}

done_testing;
