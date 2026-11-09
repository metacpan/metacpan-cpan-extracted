use strict;
use warnings;
use Test::More;
use Scalar::Util qw( refaddr );

# OFFLINE test for karr k100 (core k398, ADR 0079): the seam
# _reset_pool_connection of the transport.
#
# When a borrow ends the pool asks the storage to reset the session, and hands
# the connection on only after the Future the seam returned is done. Here that
# means, in this order:
#
#   1. COM_RESET_CONNECTION on the EV::MariaDB handle,
#   2. SET NAMES <character set> COLLATE <collation> with the two names the
#      connection had when it was new (read once, after its connect actions),
#   3. the connect actions again (on_connect_call / on_connect_do), each one
#      after the other,
#   4. only then does a caller waiting for the connection get it.
#
# A reset the server refuses, one EV::MariaDB refuses to send, a connect action
# that fails, and a reset that never answers (reset_timeout of the pool) retire
# the connection: the next caller gets a newly opened one. The live proof that a
# server really forgets the session is t/58-session-reset-live.t.
#
# The one substitution is EV::MariaDB (ResetMDB) and the owner of the connect
# actions (Owner59), which names two statements and runs them through the
# transport's runner.

use EV;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;

our @ACTION_CONNS;      # the connection each connect action ran on
our @TRACE;                 # what happened, in order
our %MODE = (reset => 'ok');  # ok | error | croak | hold
our $FAIL_ACTION;           # a connect action (SQL text) that fails
our @NAMES = ('utf8mb4', 'utf8mb4_unicode_ci');   # what the server answers for character set and collation
our $FAIL_QUERY;            # a statement (SQL text) the handle answers with an error

{
  package ResetMDB;
  use Carp ();
  use Socket ();

  sub new {
    my ($class, %args) = @_;
    my $self = bless { on_connect => $args{on_connect}, connected => 0 }, $class;
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

  sub query {
    my ($self, $sql, $cb) = @_;
    push @main::TRACE, "query $sql";
    my $t;
    my $fail = defined $main::FAIL_QUERY && $sql eq $main::FAIL_QUERY;
    $t = EV::timer(0.001, 0, sub { undef $t; $fail ? $cb->(undef, 'Unknown collation') : $cb->(0, undef) });
    return;
  }

  sub reset_connection {
    my ($self, $cb) = @_;
    push @main::TRACE, 'reset';
    Carp::croak('another operation is in progress') if $main::MODE{reset} eq 'croak';
    return if $main::MODE{reset} eq 'hold';
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      $main::MODE{reset} eq 'error' ? $cb->(undef, 'Lost connection to server during query') : $cb->(1, undef);
    });
    return;
  }
}

{
  # What the owning sync storage does for a new connection: two statements.
  package Owner59;
  sub new { bless {}, shift }
  sub _run_pool_connect_actions {
    my ($self, $runner) = @_;
    $runner->(q{SET @dbio_a = 1});
    $runner->(q{SET @dbio_b = 2});
    return $self;
  }
}

{
  # The runner of the connect actions is the transport's own; here it records
  # the statement instead of driving the loop, and can fail one.
  package Storage59;
  use base 'DBIO::MySQL::EV::Storage';
  sub _run_pool_connect_statement {
    my ($self, $conn, $sql, $attrs) = @_;
    if ($attrs && $attrs->{dbio_rows}) {
      push @main::TRACE, 'read names';
      return [ [ @main::NAMES ] ];
    }
    push @main::TRACE, "action $sql";
    push @main::ACTION_CONNS, Scalar::Util::refaddr($conn);
    if (defined $main::FAIL_ACTION && $sql eq $main::FAIL_ACTION) {
      undef $main::FAIL_ACTION;               # once: the replacement connects normally
      die "connect action failed\n";
    }
    return;
  }
}

{
  no warnings 'redefine';
  *DBIO::MySQL::EV::Pool::_new_connection = sub { shift; ResetMDB->new(@_) };
}

alarm 60;

sub until_ready {
  my ($f) = @_;
  my $dog = EV::timer(3, 0, sub { $f->fail("watchdog\n") unless $f->is_ready });
  $dog->keepalive(0);
  EV::run(EV::RUN_ONCE()) until $f->is_ready;
  return $f;
}

sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

my $OWNER = Owner59->new;

sub pool_of_one {
  my (%options) = @_;
  my $storage = Storage59->new(undef);
  $storage->connect_info([ { host => q{fake}, database => q{fake}, pool_size => 1, %options } ]);
  $storage->_owner_storage($OWNER);
  @TRACE = ();
  @ACTION_CONNS = ();
  %MODE  = (reset => q{ok});
  undef $FAIL_ACTION;
  undef $FAIL_QUERY;
  @NAMES = ('utf8mb4', 'utf8mb4_unicode_ci');
  return $storage;
}

my @ACTIONS = ('action SET @dbio_a = 1', 'action SET @dbio_b = 2');
my $SET_NAMES = 'query SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci';

# -----------------------------------------------------------------------------
# 1. The order: reset, the connect actions, and only then the next caller.
# -----------------------------------------------------------------------------
{
  my $storage = pool_of_one();
  my $pool    = $storage->pool;

  my $conn = until_ready($pool->acquire)->get;
  my $lease = $pool->_lease($conn);
  @TRACE = (); @ACTION_CONNS = ();                                 # the actions of the spawn are not the subject

  my @seen_by_waiter;
  my $waiter = $pool->acquire;                 # queued behind the holder
  $waiter->on_done(sub { @seen_by_waiter = @TRACE });
  ok !$waiter->is_ready, 'a caller is queued for the one connection';

  $pool->release($conn, $lease);
  is_deeply \@TRACE, ['reset'], 'the release sends the reset first, and nothing else yet';
  ok !$waiter->is_ready, 'the queued caller does not get the connection before the reset answered';

  until_ready($waiter);
  is_deeply \@seen_by_waiter, [ 'reset', $SET_NAMES, @ACTIONS ],
    'the caller got it after the reset, the SET NAMES and both connect actions, in that order';
  is refaddr($waiter->get), refaddr($conn), 'and it is the same connection';
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 2. A reset the server refuses: no connect action, the connection is retired.
# -----------------------------------------------------------------------------
for my $mode (qw( error croak )) {
  my $storage = pool_of_one();
  my $pool    = $storage->pool;

  my $conn = until_ready($pool->acquire)->get;
  my $lease = $pool->_lease($conn);
  @TRACE = (); @ACTION_CONNS = ();
  $MODE{reset} = $mode;

  my $waiter = $pool->acquire;
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, @_ };
  $pool->release($conn, $lease);
  until_ready($waiter);

  is $TRACE[0], q{reset}, "reset $mode: the reset was sent";
  ok !(grep { $_ == refaddr($conn) } @ACTION_CONNS), "reset $mode: no connect action ran on the connection";
  isnt refaddr($waiter->get), refaddr($conn), "reset $mode: the caller got a newly opened connection";
  is $pool->size, 1, "reset $mode: the pool holds the one new connection";
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 3. A connect action that fails: the connection is retired.
# -----------------------------------------------------------------------------
{
  my $storage = pool_of_one();
  my $pool    = $storage->pool;

  my $conn = until_ready($pool->acquire)->get;
  my $lease = $pool->_lease($conn);
  @TRACE = (); @ACTION_CONNS = ();
  $FAIL_ACTION = q{SET @dbio_b = 2};

  my $waiter = $pool->acquire;
  $pool->release($conn, $lease);
  until_ready($waiter);

  isnt refaddr($waiter->get), refaddr($conn), 'connect action failed: the caller got a newly opened connection';
  is_deeply [ @TRACE[ 0 .. 3 ] ], [ 'reset', $SET_NAMES, @ACTIONS ],
    'connect action failed: it was the second action that failed, after the reset';
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 4. A reset that never answers: reset_timeout retires the connection.
# -----------------------------------------------------------------------------
{
  my $storage = pool_of_one(reset_timeout => 0.1);
  my $pool    = $storage->pool;

  my $conn = until_ready($pool->acquire)->get;
  my $lease = $pool->_lease($conn);
  @TRACE = (); @ACTION_CONNS = ();
  $MODE{reset} = 'hold';

  my $waiter = $pool->acquire;
  $pool->release($conn, $lease);
  $MODE{reset} = 'ok';                         # the replacement answers
  until_ready($waiter);

  isnt refaddr($waiter->get), refaddr($conn),
    'no answer within reset_timeout: the caller got a newly opened connection';
  ok !(grep { $_ == refaddr($conn) } @ACTION_CONNS), q{no connect action ran on the connection that never answered};
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 5. No owning sync storage: the reset alone.
# -----------------------------------------------------------------------------
{
  my $storage = Storage59->new(undef);
  $storage->connect_info([ { host => 'fake', database => 'fake', pool_size => 1 }, {} ]);
  @TRACE = (); @ACTION_CONNS = ();
  %MODE  = (reset => 'ok');
  my $pool = $storage->pool;
  my $conn = until_ready($pool->acquire)->get;
  $pool->release($conn, $pool->_lease($conn));
  settle();
  is_deeply \@TRACE, ['reset'], 'a storage without an owning sync storage sends only the reset';
  is $pool->available, 1, 'and the connection is idle again';
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 6. A SET NAMES the server refuses retires the connection; no connect action.
# -----------------------------------------------------------------------------
{
  my $storage = pool_of_one();
  my $pool    = $storage->pool;

  my $conn = until_ready($pool->acquire)->get;
  my $lease = $pool->_lease($conn);
  @TRACE = (); @ACTION_CONNS = ();
  $FAIL_QUERY = q{SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci};

  my $waiter = $pool->acquire;
  $pool->release($conn, $lease);
  until_ready($waiter);

  is_deeply [ @TRACE[ 0 .. 1 ] ], [ 'reset', $SET_NAMES ], 'SET NAMES refused: it followed the reset';
  ok !(grep { $_ == refaddr($conn) } @ACTION_CONNS), 'SET NAMES refused: no connect action ran on the connection';
  isnt refaddr($waiter->get), refaddr($conn), 'SET NAMES refused: the caller got a newly opened connection';
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 7. A name that is not a plain name is never put into SET NAMES.
# -----------------------------------------------------------------------------
{
  my $storage = pool_of_one();
  my $pool    = $storage->pool;
  @NAMES = ('utf8mb4', q{x'; DROP TABLE t; --});

  my $f = until_ready($pool->acquire);
  ok $f->is_failed, 'a collation name with other characters than letters, digits and underscores: the connection is refused';
  my $msg = $f->is_failed ? ($f->failure // '') : '';
  like $msg, qr/not a plain name/, 'and the error says why';
  unlike $msg, qr/DROP/, 'without quoting the name';
  ok !(grep { /SET NAMES/ } @TRACE), 'no SET NAMES was sent';
  $storage->disconnect;
}

done_testing;
