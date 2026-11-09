use strict;
use warnings;
use Test::More;
use Scalar::Util qw( refaddr );

# OFFLINE regression for karr k91 and karr k90 (point 1): the release that
# ends a pooled statement is the release of ITS borrow, to the pool it came from.
#
# k91: a release that arrives after its connection went on (the callback
# _release_on_ready builds, run a second time once the connection was handed
# to a queued caller) used to take the connection from its new holder, and
# give the one session to two callers. The callback now carries the lease of
# the borrow (core k275, $pool->_lease); a stale lease releases nothing.
#
# k90: the statement's end asked $self->pool again. A storage disconnected
# while a statement was in flight has no pool then, and ->pool built a new,
# empty one to release into. The callback releases to the pool it was
# acquired from; the disconnected storage stays without one.
#
# The one substitution is EV::MariaDB: HoldMDB connects on a timer and answers
# nothing by itself -- the test fires the callbacks of the statements it holds.

use EV;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;

{
  package HoldMDB;
  use Carp ();
  use Socket ();

  our @SENT;   # { sql, cb } of every statement handed to the handle

  sub new {
    my ($class, %args) = @_;
    my $self = bless { on_connect => $args{on_connect}, connected => 0 }, $class;
    # A live session: a socket with nothing to read.
    socketpair($self->{sock}[0], $self->{sock}[1], Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    my $t;
    $t = EV::timer(0.001, 0, sub { undef $t; $self->{connected} = 1; $self->{on_connect}->() });
    return $self;
  }

  sub is_connected  { $_[0]{connected} }
  sub socket        { fileno $_[0]{sock}[0] }
  sub pending_count { 0 }
  sub finish        { Carp::croak('Usage: EV::MariaDB::finish(self)') if @_ != 1; $_[0]{connected} = 0; return }
  sub close_async   { Carp::croak('Usage: EV::MariaDB::close_async(self, cb)') if @_ != 2; return }
  sub query         { my ($self, $sql, $cb) = @_; push @SENT, { sql => $sql, cb => $cb }; return }
  # COM_RESET_CONNECTION, which the pool sends at the end of every borrow
  # (karr k100, core k398): answered at once, the session is clean.
  our $RESETS = 0;
  sub reset_connection { my ($self, $cb) = @_; $RESETS++; my $t; $t = EV::timer(0.001, 0, sub { undef $t; $cb->(1, undef) }); return }
}

{
  no warnings 'redefine';
  *DBIO::MySQL::EV::Pool::_new_connection = sub { shift; HoldMDB->new(@_) };
}

alarm 60;

sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.02, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub until_ready {
  my ($f) = @_;
  my $dog = EV::timer(3, 0, sub { $f->fail("watchdog\n") unless $f->is_ready });
  $dog->keepalive(0);
  EV::run(EV::RUN_ONCE()) until $f->is_ready;
  return $f;
}

sub pool_of_one {
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->connect_info([ { host => 'fake', database => 'fake', pool_size => 1 }, {} ]);
  @HoldMDB::SENT = ();
  return $storage;
}

# -----------------------------------------------------------------------------
# k91: a completion that runs a second time takes nothing from the new holder.
# -----------------------------------------------------------------------------
{
  my $storage = pool_of_one();
  my $pool    = $storage->pool;

  my $conn = until_ready($pool->acquire)->get;
  my $cb   = $storage->_release_on_ready($conn, $pool, $pool->_lease($conn));

  my $waiter = $pool->acquire;                 # queued behind the holder
  my $third  = $pool->acquire;                 # and another behind it
  ok !$waiter->is_ready, 'k91: a caller is queued for the one connection';

  $cb->();                                     # the holder's release: hands it on
  settle();                                    # the reset of the session first (karr k100)
  ok $waiter->is_done, 'k91: the release hands the connection to the queued caller';
  is refaddr($waiter->get), refaddr($conn), 'k91: the same connection';

  $cb->();                                     # the completion fires again
  settle();
  ok !$third->is_ready,
    'k91: the second run does not hand the session to the caller behind';
  is $pool->available, 0, 'k91: the connection is not on the idle list under its holder';

  $pool->release($conn, $pool->_lease($conn)); # the new holder's own release
  settle();
  ok $third->is_done, 'k91: the new holder\'s release hands it on';
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# k90: a statement that ends after disconnect builds no new pool.
# -----------------------------------------------------------------------------
{
  my $storage = pool_of_one();
  my $f = $storage->select_async('thing', [qw( id name )], {});
  my $deadline = EV::time() + 2;
  settle() while !@HoldMDB::SENT && EV::time() < $deadline;
  is scalar @HoldMDB::SENT, 1, 'k90: the statement is in flight';

  $storage->disconnect;
  ok !defined $storage->{pool}, 'k90: disconnected: no pool';

  $HoldMDB::SENT[0]{cb}->([ [ 1, 'one' ] ]);   # it completes afterwards
  settle();
  ok !defined $storage->{pool},
    'k90: the completion of the statement built no new pool on the disconnected storage';
}

{
  my $storage = pool_of_one();
  my $f = $storage->insert_async('thing', {});
  my $deadline = EV::time() + 2;
  settle() while !@HoldMDB::SENT && EV::time() < $deadline;
  is scalar @HoldMDB::SENT, 1, 'k90: the insert is in flight';

  $storage->disconnect;
  $HoldMDB::SENT[0]{cb}->(1);                  # the INSERT is answered afterwards
  settle();
  $HoldMDB::SENT[1]{cb}->([ [ 7 ] ]) if $HoldMDB::SENT[1];   # and LAST_INSERT_ID()
  settle();
  ok !defined $storage->{pool},
    'k90: the end of an insert built no new pool on the disconnected storage either';
}

done_testing;
