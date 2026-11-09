package MySQLProtocolStub;

# A test-only MySQL wire-protocol server, about sixty lines of it: a v10
# handshake with mysql_native_password, an OK packet for the login and for every
# command after it, and the end of the session on COM_QUIT. It is not a
# database -- it answers no result set. It exists to show what a client writes
# to a socket, which is all the fork tests of this dist need to know: a forked
# child that closes a connection it inherited sends COM_QUIT down the socket it
# shares with its parent, and the stub then hangs up on the parent too.
#
#   my $stub = MySQLProtocolStub->new;
#   my $dbh  = DBI->connect($stub->dsn('MariaDB'), 'u', 'p', { ... });
#   $dbh->do('DO 1');        # alive until anybody sent COM_QUIT on this session
#
# The server is a forked process serving every connection; it ends with the
# object.

use strict;
use warnings;
use IO::Socket::INET ();
use IO::Select ();

sub new {
  my $class = shift;
  my $listen = IO::Socket::INET->new(
    Listen => 16, LocalAddr => '127.0.0.1', LocalPort => 0, ReuseAddr => 1,
  ) or die "stub listen: $!";
  my $pid = fork // die "fork: $!";
  if (!$pid) {
    _serve($listen);
    POSIX::_exit(0);
  }
  return bless { pid => $pid, port => $listen->sockport, owner => $$ }, $class;
}

sub port { $_[0]{port} }

sub dsn {
  my ($self, $driver) = @_;
  return "dbi:$driver:database=stub;host=127.0.0.1;port=$self->{port}";
}

sub DESTROY {
  my $self = shift;
  return unless $self->{pid} && $self->{owner} == $$;
  kill 'TERM', $self->{pid};
  waitpid $self->{pid}, 0;
}

sub _packet { my ($seq, $body) = @_; substr(pack('V', length $body), 0, 3) . chr($seq) . $body }

sub _ok { _packet($_[0], pack('C C C v v', 0, 0, 0, 2, 0)) }

sub _greeting {
  my $scramble = 'abcdefgh' . 'ijklmnopqrst';
  my $caps     = 0x0001 | 0x0004 | 0x0008 | 0x0200 | 0x2000 | 0x8000 | 0x0008_0000;
  return _packet(0, pack('C Z* V a8 C v C v v C a10 a12 C Z*',
    10, '8.0.30-stub', 1, substr($scramble, 0, 8), 0,
    $caps & 0xFFFF, 0x21, 2, $caps >> 16, 21, '', substr($scramble, 8), 0,
    'mysql_native_password'));
}

sub _serve {
  my ($listen) = @_;
  $SIG{TERM} = sub { POSIX::_exit(0) };
  my $select = IO::Select->new($listen);
  my %state;    # fileno => 'login' | 'ready'
  while (1) {
    for my $fh ($select->can_read) {
      if ($fh == $listen) {
        my $c = $listen->accept or next;
        $c->autoflush(1);
        $select->add($c);
        $state{ fileno $c } = 'login';
        syswrite $c, _greeting();
        next;
      }
      my $n = sysread $fh, my $buf, 65536;
      if (!$n) { $select->remove($fh); delete $state{ fileno $fh }; close $fh; next }
      my $st = $state{ fileno $fh };
      if ($st eq 'login') {
        $state{ fileno $fh } = 'ready';
        syswrite $fh, _ok(2);
        next;
      }
      my $command = ord substr($buf, 4, 1);
      if ($command == 1) {    # COM_QUIT
        $select->remove($fh); delete $state{ fileno $fh }; close $fh;
        next;
      }
      syswrite $fh, _ok(1);
    }
  }
}

1;
