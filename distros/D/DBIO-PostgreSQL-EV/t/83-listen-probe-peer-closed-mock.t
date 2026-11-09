use strict;
use warnings;
use Test::More;
use Socket ();

# OFFLINE, karr k88 (_listen_probe): the probe of the LISTEN connection sees a
# session the server has ended although the EV loop has not read it yet.
#
# WHY: listen_alive is what an external watchdog asks, and a program that only
# blocks never runs the loop between two calls. EV::Pg keeps reporting the
# handle connected until its read watcher has run (libpq learns of a lost
# connection only by reading), so a probe that asked is_connected alone said
# "alive" for a session pg_terminate_backend had ended, until the loop ran.
# The pool has the same look for its idle connections (karr k72,
# Pool::_pg_peer_closed): the server's end of the socket is CLOSED (poll,
# POLLRDHUP), which no live session's is. The probe asks it too.
#
# What this file claims, over a stand-in handle on a real socket pair:
#   1. a connected handle whose server end is open is alive -- also when the
#      server has SENT it something (readable is not gone: a notification);
#   2. the server's end closed, behind unread data or not, and the handle
#      still reporting connected: dead;
#   3. the handle not connected, or none: dead, as before;
#   4. the probe reads nothing off the socket (the notification is still there).
# The live half is t/84-listen-probe-peer-closed-live.t.

use DBIO::PostgreSQL::EV::Storage;
use DBIO::PostgreSQL::EV::Pool;

plan skip_all => 'this platform has no poll flag for a closed peer'
  unless DBIO::PostgreSQL::EV::Pool::_pg_rdhup();

{
  package FakePg;
  sub new { my ($c, $fd) = @_; bless { fd => $fd, connected => 1 }, $c }
  sub is_connected { $_[0]{connected} }
  sub socket       { $_[0]{fd} }
}

sub pair {
  socketpair(my $ours, my $servers, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
    or die "socketpair: $!";
  return ($ours, $servers);
}

my $class = 'DBIO::PostgreSQL::EV::Storage';

{
  my ($ours, $servers) = pair();
  my $conn = { pg => FakePg->new(fileno $ours) };
  is $class->_listen_probe($conn), 1, '1. connected, server end open: alive';

  syswrite $servers, "N";
  is $class->_listen_probe($conn), 1, '... also with something to read (a notification)';

  close $servers;
  is $class->_listen_probe($conn), 0,
    '2. server end closed behind unread data, handle still "connected": dead';

  my $buf;
  is sysread($ours, $buf, 10), 1, '4. the probe took nothing off the socket ...';
  is $buf, 'N', '... the notification is still there';
}

{
  my ($ours, $servers) = pair();
  my $conn = { pg => FakePg->new(fileno $ours) };
  close $servers;
  is $class->_listen_probe($conn), 0, '2. server end closed, nothing unread: dead';
}

{
  my ($ours, $servers) = pair();
  my $pg = FakePg->new(fileno $ours);
  $pg->{connected} = 0;
  is $class->_listen_probe({ pg => $pg }), 0, '3. not connected: dead';
  is $class->_listen_probe({}), 0, '... no handle: dead';
}

done_testing;
