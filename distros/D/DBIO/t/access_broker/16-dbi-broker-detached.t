# ABSTRACT: A sync storage whose broker is taken away keeps nothing of its answer
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util qw(blessed reftype refaddr);

use DBI;
use DBIO::Storage::DBI;
use DBIO::AccessBroker;

# OFFLINE (karr k270, k266 point 1; the sync twin of k252). DBIO::Storage::DBI
# stores what its AccessBroker answered -- DSN, user, PASSWORD -- as the DBI
# connect info (_dbi_connect_info), at connect_info and again at every
# connection. clear_access_broker only unset the broker, so the next connection
# took the "no broker, use what connect_info stored" path and was opened with
# the last answer of a broker that was no longer there: its user, its password.
# The async side stores nothing of an answer since k252; here the storage
# drops what it stored at the moment the broker is detached.
#
# What this file claims:
#   1. A broker detached with clear_access_broker: the next connection is not
#      opened -- _connect throws, DBI->connect is never called -- and nothing
#      in the storage still holds a value of the answer. Detached after a
#      connection, and detached right after connect_info.
#   2. With $ENV{DBI_DSN} set, a detached storage is where a storage that never
#      got connect info is: it has nothing to connect from, and the DSN of the
#      environment is no substitute (karr k306) -- _connect throws and
#      DBI->connect is never called.
#   3. A storage without a broker is not touched: clear_access_broker on a
#      statically connected storage leaves its connect info in place.
#   4. connect_info replacing a broker with static connect info detaches the
#      broker and connects with the static info. When that static connect info
#      is refused, the storage is left with nothing of the broker's answer.
#   5. Claim 1 holds on a driver storage class whatever its method resolution
#      order (karr k293). On one that does not declare c3 -- as
#      DBIO::PostgreSQL::Storage and DBIO::MySQL::Storage do not -- the bare
#      DBIO::Storage::clear_access_broker was found before the one that drops
#      the answer, and the next connection was opened with it.
#
# Since karr k266 the storage holds no copy of the answer while the broker is
# attached either (34-dbi-broker-holds-nothing.t); the detach therefore has
# nothing of the answer to drop, and these claims are what is left of it: the
# detached storage connects with nothing the broker gave.
#
# THE SUBSTITUTIONS: DBI->connect is replaced by a recorder returning a stand-in
# handle; no database is involved, and the DSNs name no real driver.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

# A broker answering from a script: one code per call, the last one repeating.
{
  package T::ScriptBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, @answers) = @_; bless { answers => \@answers, calls => 0 }, $class }
  sub connect_info_for {
    my $self = shift;
    my $i = $self->{calls}++;
    $i = $#{ $self->{answers} } if $i > $#{ $self->{answers} };
    return $self->{answers}[$i]->();
  }
}

{
  package T::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

# every value of a broker answer in this file, and nothing else in it
my $ANSWER = qr/k266-(?:dsn|user|secret)/;

sub answer { my $n = shift; [ "dbi:Fake:k266-dsn-$n", "k266-user-$n", "k266-secret-$n", {} ] }

sub broker { T::ScriptBroker->new(map { my $n = $_; sub { answer($n) } } 1 .. 3) }

# Does this structure hold a value matching $re? A broker object is not looked
# into: the raw connect info keeps the broker itself, and what a broker holds
# is the broker's business.
sub holds {
  my ($x, $re, $seen) = @_;
  $seen ||= {};
  return 0 unless defined $x;
  return $x =~ $re ? 1 : 0 unless ref $x;
  return 0 if blessed($x) && $x->isa('DBIO::AccessBroker');
  return 0 if $seen->{ refaddr $x }++;
  my $type = reftype $x;
  my @inside = $type eq 'HASH'                      ? %$x
             : $type eq 'ARRAY'                     ? @$x
             : $type eq 'SCALAR' || $type eq 'REF'  ? $$x
             :                                        ();
  return scalar grep { holds($_, $re, $seen) } @inside;
}

ok holds({ deep => [ { value => 'k266-secret-9' } ] }, $ANSWER), 'the scanner finds a value of an answer';
ok !holds({ deep => [ broker(), 'something else' ] }, $ANSWER), '... and none where there is none';

my $NO_CONNECT_INFO = qr/You did not provide any connection_info/;

# ---------------------------------------------------------------------------
# 1. The broker is detached.
# ---------------------------------------------------------------------------
{
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ broker() ]);
  local @CONNECTS;

  lives_ok { $storage->_connect } 'with the broker attached, a connection is opened';
  is_deeply [ @{ $CONNECTS[0] }[0 .. 2] ], [ @{ answer(2) }[0 .. 2] ],
    "... with the broker's current answer";

  $storage->clear_access_broker;
  is $storage->access_broker, undef, 'clear_access_broker detaches the broker';

  throws_ok { $storage->_connect } $NO_CONNECT_INFO,
    'detached after a connection: the next connection throws';
  is scalar @CONNECTS, 1, "... and DBI->connect is not called with the broker's last answer";
  is_deeply $storage->_dbi_connect_info, [], '... the stored DBI connect info is gone';
  ok !holds($storage, $ANSWER), '... and nothing in the storage holds a value of the answer';
}

{
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ broker() ]);
  $storage->clear_access_broker;
  local @CONNECTS;

  throws_ok { $storage->_connect } $NO_CONNECT_INFO,
    'detached right after connect_info: the next connection throws';
  is scalar @CONNECTS, 0, '... and DBI->connect is not called with the answer connect_info got';
  ok !holds($storage, $ANSWER), '... and nothing in the storage holds a value of the answer';
}

# ---------------------------------------------------------------------------
# 2. Detached, with a DSN in the environment.
# ---------------------------------------------------------------------------
{
  local $ENV{DBI_DSN} = 'dbi:Fake:from-the-environment';

  {
    local @CONNECTS;
    throws_ok { DBIO::Storage::DBI->new(undef)->_connect } $NO_CONNECT_INFO,
      'a storage that never got connect info does not connect to the DSN of the environment (control)';
    is scalar @CONNECTS, 0, '... DBI->connect is not called';
  }

  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ broker() ]);
  $storage->_connect;
  $storage->clear_access_broker;
  local @CONNECTS;

  throws_ok { $storage->_connect } $NO_CONNECT_INFO,
    'detached, with DBI_DSN set: the next connection throws, as on a storage that never got connect info';
  is scalar @CONNECTS, 0,
    '... and DBI->connect is called neither with the DSN of the environment nor with the answer';
}

# ---------------------------------------------------------------------------
# 3. No broker attached: nothing is dropped.
# ---------------------------------------------------------------------------
{
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ 'dbi:Fake:static', 'static-user', 'static-pw' ]);
  $storage->clear_access_broker;
  local @CONNECTS;

  lives_ok { $storage->_connect }
    'clear_access_broker on a statically connected storage: it still connects';
  is_deeply [ @{ $CONNECTS[0] }[0 .. 2] ], [ 'dbi:Fake:static', 'static-user', 'static-pw' ],
    '... with the static connect info';
}

# ---------------------------------------------------------------------------
# 4. connect_info replaces the broker with static connect info.
# ---------------------------------------------------------------------------
{
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ broker() ]);
  $storage->_connect;
  $storage->connect_info([ 'dbi:Fake:static', 'static-user', 'static-pw' ]);
  local @CONNECTS;

  is $storage->access_broker, undef, 'static connect info after a broker: the broker is detached';
  lives_ok { $storage->_connect } '... and a connection is opened';
  is_deeply [ @{ $CONNECTS[0] }[0 .. 2] ], [ 'dbi:Fake:static', 'static-user', 'static-pw' ],
    '... with the static connect info';
  ok !holds($storage, $ANSWER), '... and nothing in the storage holds a value of the answer';
}

{
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ broker() ]);
  $storage->_connect;

  # connection parameters on a storage registered for no DBD driver: refused
  throws_ok { $storage->connect_info([ { dbname => 'app', user => 'static-user' } ]) }
    qr/Cannot build a DSN from the connection parameters/,
    'static connect info after a broker, refused by connect_info';
  local @CONNECTS;

  throws_ok { $storage->_connect } $NO_CONNECT_INFO, '... the next connection throws';
  is scalar @CONNECTS, 0, "... and DBI->connect is not called with the broker's last answer";
  ok !holds($storage, $ANSWER), '... and nothing in the storage holds a value of the answer';
}

# ---------------------------------------------------------------------------
# 5. A driver storage class, in either method resolution order.
# ---------------------------------------------------------------------------
{ package T::DepthFirstDriver; our @ISA = ('DBIO::Storage::DBI'); }
{ package T::C3Driver; use mro 'c3'; our @ISA = ('DBIO::Storage::DBI'); }

for my $class (qw( T::DepthFirstDriver T::C3Driver )) {
  my $mro = mro::get_mro($class);
  my $storage = $class->new(undef);
  $storage->connect_info([ broker() ]);
  $storage->clear_access_broker;
  local @CONNECTS;

  throws_ok { $storage->_connect } $NO_CONNECT_INFO,
    "a driver storage class ($mro), detached: the next connection throws";
  is scalar @CONNECTS, 0, "... and DBI->connect is not called with the broker's last answer";
  ok !holds($storage, $ANSWER), '... and nothing in the storage holds a value of the answer';
}
is_deeply [ map { mro::get_mro($_) } qw( T::DepthFirstDriver T::C3Driver ) ], [qw( dfs c3 )],
  '... (the two classes are one of each order)';

done_testing;
