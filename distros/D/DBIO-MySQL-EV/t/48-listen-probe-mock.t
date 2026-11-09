use strict;
use warnings;
use Test::More;

use Errno ();
use Socket ();

# EINTR on a zero-timeout select, injected: a signal cannot be made to land in
# that one syscall. Installed before the modules compile, so their select is
# this one; it passes everything on to the real thing.
my $EINTR_LEFT = 0;
BEGIN {
  *CORE::GLOBAL::select = sub {
    return CORE::select($_[0]) if @_ == 1;
    if ($EINTR_LEFT > 0) {
      $EINTR_LEFT--;
      $! = Errno::EINTR();
      return -1;
    }
    return CORE::select($_[0], $_[1], $_[2], $_[3]);
  };
}

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;

alarm 30;

# OFFLINE, karr k70. The listen connection's liveness probe asks the same
# question as the pool's check -- is the session of an idle handle gone -- and
# must give the same answer, an interrupted select included: it says nothing
# about the socket. The probe used to carry its own copy of the select without
# the retry, so an EINTR read as "dead" and a healthy listen connection was
# torn down and reopened.

{
  package FakeHandle;
  sub new {
    socketpair(my $client, my $server, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0)
      or die "socketpair: $!";
    return bless { client => $client, server => $server, pending => 0 }, shift;
  }
  sub socket        { exists $_[0]{fd} ? $_[0]{fd} : fileno $_[0]{client} }
  sub pending_count { $_[0]{pending} }
  sub hang_up       { close $_[0]{server}; return }
  sub no_socket     { $_[0]{fd} = -1; return }
}

sub probe { DBIO::MySQL::EV::Storage->_listen_probe({ mdb => $_[0], busy => $_[1] }) ? 1 : 0 }
sub pool_alive { DBIO::MySQL::EV::Pool->_mysql_connection_gone($_[0]) ? 0 : 1 }

is probe(undef), 0, 'no handle: dead';

{
  my $h = FakeHandle->new;
  is probe($h), 1, 'idle, nothing to read: alive';
  is probe($h), pool_alive($h), '... as the pool says';

  $EINTR_LEFT = 2;
  is probe($h), 1, 'an interrupted select is asked again: alive, not dead';
  is $EINTR_LEFT, 0, '... both interruptions were met and retried';
}
{
  my $h = FakeHandle->new;
  $h->hang_up;
  is probe($h), 0, 'the server hung up: dead';
  is probe($h), pool_alive($h), '... as the pool says';
  $EINTR_LEFT = 1;
  is probe($h), 0, 'a hung-up socket behind an interrupted select is still dead';
}
{
  my $h = FakeHandle->new;
  $h->no_socket;
  is probe($h), 0, 'no socket: dead';
  is probe($h), pool_alive($h), '... as the pool says';
}
{
  my $h = FakeHandle->new;
  $h->hang_up;
  is probe($h, 1), 1, 'a statement running through the listen connection: alive, the handle is not touched';
}

done_testing;
