# ABSTRACT: A sync storage asks its broker again whenever it has to open a connection
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Storage::DBI;
use DBIO::AccessBroker;

# OFFLINE (karr k270). A sync storage asks its AccessBroker for every new
# connection, so credentials the broker rotated reach the next one. Every core
# test of that called _connect by hand (05-dbi-reconnect.t, 13, 16, 18). No
# test lost a handle the way a running application loses one -- disconnect, a
# connection the server dropped, a server that stopped answering, a fork, a
# block retried by dbh_do or txn_do -- and looked at what the storage then
# opened the next connection with. Nor did one switch a connected storage from
# a broker to static connect info and count what the broker was asked after.
#
# What this file claims, with a real DBIO::Storage::DBI and its own dbh,
# ensure_connected, disconnect, dbh_do and txn_do:
#   1. the first dbh opens a connection with the broker's answer of that
#      moment, and while that handle stands nothing asks the broker again and
#      nothing reconnects;
#   2. after disconnect, the next dbh opens a connection with the next answer;
#   3. a handle that is no longer active, or whose server no longer answers a
#      ping, is replaced on the next dbh or ensure_connected -- with the next
#      answer;
#   4. a handle opened by another process is dropped, not disconnected (it is
#      that process's), and the next dbh opens one with the next answer;
#   5. a dbh_do block that fails on a dead handle is run again on a new
#      connection, opened with the next answer; so is a txn_do block, and
#      txn_do on a disconnected storage connects with the next answer first;
#   6. a reconnect the broker refuses -- it throws, or answers nothing --
#      opens no connection and leaves the storage without a handle, with the
#      credentials of no earlier answer in the error; the attempt after it
#      asks again and connects;
#   7. a connected storage given static connect info asks the broker no more:
#      its next connections are opened with the static info, however many;
#      and a statically connected storage given a broker opens its next
#      connection with the broker's answer.
#
# THE SUBSTITUTIONS: DBI->connect records its arguments and returns a stand-in
# handle that can be killed, made deaf to ping, and records disconnect and the
# transaction calls. No database.

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
  sub calls { $_[0]{calls} }
}

# A storage class of its own: nothing is resolved from the DSN.
{
  package T::Storage;
  use base 'DBIO::Storage::DBI';
}

{
  package T::Handle;
  sub new {
    bless { Active => 1, AutoCommit => 1, RaiseError => 1, deaf => 0, log => [] }, shift;
  }
  sub FETCH      { $_[0]->{ $_[1] } }
  sub ping       { $_[0]{Active} && !$_[0]{deaf} ? 1 : 0 }
  sub disconnect { push @{ $_[0]{log} }, 'disconnect'; $_[0]{Active} = 0; 1 }
  sub begin_work { push @{ $_[0]{log} }, 'begin_work'; $_[0]{AutoCommit} = 0; 1 }
  sub commit     { push @{ $_[0]{log} }, 'commit';     $_[0]{AutoCommit} = 1; 1 }
  sub rollback   { push @{ $_[0]{log} }, 'rollback';   $_[0]{AutoCommit} = 1; 1 }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

# every value of a broker answer in this file
my $ANSWER = qr/k270-(?:dsn|user|pw)/;

sub answer { my $n = shift; [ "dbi:Fake:k270-dsn-$n", "k270-user-$n", "k270-pw-$n", {} ] }
sub creds  { [ @{ answer(shift) }[0 .. 2] ] }

# Answers 1, 2, 3, ...: answer 1 goes to connect_info, answer 2 to the first
# connection.
sub numbered_broker {
  my $n = 0;
  return T::ScriptBroker->new(sub { answer(++$n) });
}

sub storage_with {
  my ($broker) = @_;
  my $storage = T::Storage->new(undef);
  $storage->connect_info([ $broker ]);
  return $storage;
}

# What DBI->connect was called with since the last look: [ dsn, user, pw ] each.
sub connects { my @seen = map { [ @$_[0 .. 2] ] } @CONNECTS; @CONNECTS = (); return \@seen }

# ---------------------------------------------------------------------------
# 1. The first connection, and a handle that stands.
# ---------------------------------------------------------------------------
{
  local @CONNECTS;
  my $broker  = numbered_broker();
  my $storage = storage_with($broker);
  is $broker->calls, 1, 'connect_info asks the broker once';
  is_deeply connects(), [], '... and opens no connection';

  my $dbh = $storage->dbh;
  is_deeply connects(), [ creds(2) ], "the first dbh opens a connection with the broker's answer of that moment";

  is $storage->dbh, $dbh, 'a second dbh hands out the same handle';
  ok $storage->connected, '... connected says so';
  ok $storage->ensure_connected, '... ensure_connected has nothing to do';
  is $storage->_get_dbh, $dbh, '... _get_dbh hands it out too';
  is $storage->dbh_do(sub { $_[1] }), $dbh, '... and dbh_do runs its block on it';
  is_deeply connects(), [], 'while the handle stands, no connection is opened';
  is $broker->calls, 2, '... and the broker is not asked';
}

# ---------------------------------------------------------------------------
# 2. disconnect, then dbh.
# ---------------------------------------------------------------------------
{
  local @CONNECTS;
  my $broker  = numbered_broker();
  my $storage = storage_with($broker);
  my $first   = $storage->dbh;
  connects();

  $storage->disconnect;
  is_deeply $first->{log}, [ 'disconnect' ], 'disconnect closes the handle';
  is_deeply connects(), [], '... and opens nothing';
  is $broker->calls, 2, '... and does not ask the broker';

  my $second = $storage->dbh;
  isnt $second, $first, 'the next dbh hands out a new handle';
  is_deeply connects(), [ creds(3) ], '... opened with the next answer of the broker';

  $storage->disconnect;
  $storage->ensure_connected;
  is_deeply connects(), [ creds(4) ], 'disconnect, then ensure_connected: a connection with the answer after that';
}

# ---------------------------------------------------------------------------
# 3. A handle that died, a server that no longer answers.
# ---------------------------------------------------------------------------
{
  local @CONNECTS;
  my $broker  = numbered_broker();
  my $storage = storage_with($broker);
  my $first   = $storage->dbh;
  connects();

  $first->{Active} = 0;
  ok !$storage->connected, 'a handle no longer active: connected says so';
  is_deeply connects(), [], '... without opening a connection';

  my $second = $storage->dbh;
  isnt $second, $first, '... and dbh replaces it';
  is_deeply connects(), [ creds(3) ], '... with a connection opened with the next answer';

  $second->{deaf} = 1;
  my $third = $storage->dbh;
  isnt $third, $second, 'a server that no longer answers a ping: dbh replaces the handle';
  is_deeply connects(), [ creds(4) ], '... with a connection opened with the next answer';

  $third->{Active} = 0;
  ok $storage->ensure_connected, 'a dead handle and ensure_connected: it reconnects';
  is_deeply connects(), [ creds(5) ], '... with the next answer';
  isnt $storage->_dbh, $third, '... and the storage holds the new handle';
  is $broker->calls, 5, 'the broker was asked once per connection, and once by connect_info';
}

# ---------------------------------------------------------------------------
# 4. A handle of another process.
# ---------------------------------------------------------------------------
SKIP: {
  skip 'no pid check on Windows, where a fork is a thread', 5 if $^O eq 'MSWin32';

  local @CONNECTS;
  my $broker  = numbered_broker();
  my $storage = storage_with($broker);
  my $first   = $storage->dbh;
  connects();

  $storage->_conn_pid($$ + 1);   # as in a forked child: opened by another process
  my $second = $storage->dbh;

  isnt $second, $first, "a handle another process opened: dbh hands out a new one";
  is_deeply connects(), [ creds(3) ], '... opened with the next answer';
  is_deeply $first->{log}, [], "... the other process's handle is not disconnected";
  ok $first->{InactiveDestroy}, '... and is marked not to close its connection when it goes';
  is $storage->_conn_pid, $$, '... the new one is recorded as this process\'s';
}

# ---------------------------------------------------------------------------
# 5. A block run again on a new connection.
# ---------------------------------------------------------------------------
{
  local @CONNECTS;
  my $broker  = numbered_broker();
  my $storage = storage_with($broker);
  my $first   = $storage->dbh;
  connects();

  my @ran_on;
  my $result = eval {
    local $SIG{__WARN__} = sub { };    # k303: the retry says it drops the old handle
    $storage->dbh_do(sub {
      my ($s, $dbh) = @_;
      push @ran_on, $dbh;
      if (@ran_on == 1) { $dbh->{Active} = 0; die "k270 server has gone away\n" }
      return 'done';
    });
  };

  is $result, 'done', 'a dbh_do block that fails on a handle that died is run again';
  is scalar @ran_on, 2, '... once';
  is $ran_on[0], $first, '... the first time on the handle that died';
  isnt $ran_on[1], $first, '... the second time on a new one';
  is_deeply connects(), [ creds(3) ], '... opened with the next answer';
}

{
  local @CONNECTS;
  my $broker  = numbered_broker();
  my $storage = storage_with($broker);
  my $first   = $storage->dbh;
  connects();

  my @ran_on;
  my @retry_warnings;
  local $SIG{__WARN__} = sub { push @retry_warnings, @_ };
  my $result = eval {
    $storage->txn_do(sub {
      my $dbh = $storage->_dbh;
      push @ran_on, $dbh;
      if (@ran_on == 1) { $dbh->{Active} = 0; die "k270 server has gone away\n" }
      return 'done';
    });
  };

  is $result, 'done', 'a txn_do block that fails on a handle that died is run again';
  is scalar @ran_on, 2, '... once';
  isnt $ran_on[1], $first, '... on a new handle';
  is_deeply connects(), [ creds(3) ], '... opened with the next answer';
  is_deeply $ran_on[1] && $ran_on[1]{log}, [ 'begin_work', 'commit' ], '... in a transaction of its own, committed';
  # k303: the retry disconnects the old handle (it is never asked to roll back
  # or commit); before, it was merely dropped
  is_deeply $first->{log}, [ 'begin_work', 'disconnect' ], '... while the dead handle saw only its begin, then was disconnected';
  is scalar(grep { /old handle is disconnected/ } @retry_warnings), 1, '... with a warning saying so';

  $storage->disconnect;
  @ran_on = ();
  lives_ok { $storage->txn_do(sub { push @ran_on, $storage->_dbh }) }
    'txn_do on a disconnected storage runs its block';
  is_deeply connects(), [ creds(4) ], '... on a connection opened with the next answer';
  is_deeply $ran_on[0] && $ran_on[0]{log}, [ 'begin_work', 'commit' ], '... in a transaction there';
}

# ---------------------------------------------------------------------------
# 6. A reconnect the broker refuses.
# ---------------------------------------------------------------------------
for my $case (
  [ 'a broker that throws',
    sub { die "k270 vault unreachable\n" },
    qr/^k270 vault unreachable/ ],
  [ 'a broker that answers nothing',
    sub { undef },
    qr/AccessBroker T::ScriptBroker answered no connect info \(undef\)/ ],
) {
  my ($label, $refusal, $error) = @$case;
  local @CONNECTS;
  my $broker = T::ScriptBroker->new(
    sub { answer(1) }, sub { answer(2) }, $refusal, sub { answer(4) },
  );
  my $storage = storage_with($broker);
  my $first   = $storage->dbh;
  connects();
  $storage->disconnect;

  throws_ok { $storage->dbh } $error, "$label at a reconnect: dbh throws its error";
  unlike "$@", $ANSWER, "$label: ... quoting no value of an earlier answer";
  is_deeply connects(), [], "$label: ... no connection is opened";
  is $storage->_dbh, undef, "$label: ... and the storage holds no handle";

  my $next;
  lives_ok { $next = $storage->dbh } "$label: the attempt after it connects";
  is_deeply connects(), [ creds(4) ], "$label: ... with the answer the broker gives then";
  isnt $next, $first, "$label: ... on a new handle";
}

# ---------------------------------------------------------------------------
# 7. From a broker to static connect info, and back.
# ---------------------------------------------------------------------------
{
  local @CONNECTS;
  my $broker  = numbered_broker();
  my $storage = storage_with($broker);
  $storage->dbh;
  connects();

  $storage->connect_info([ 'dbi:Fake:static', 'static-user', 'static-pw' ]);
  is $storage->access_broker, undef, 'static connect info on a connected storage: the broker is detached';
  my $asked = $broker->calls;

  for my $round (1, 2) {
    $storage->disconnect;
    $storage->dbh;
    is_deeply connects(), [ [ 'dbi:Fake:static', 'static-user', 'static-pw' ] ],
      "reconnect $round after that: opened with the static connect info";
  }
  $storage->_dbh->{Active} = 0;
  $storage->ensure_connected;
  is_deeply connects(), [ [ 'dbi:Fake:static', 'static-user', 'static-pw' ] ],
    '... and so is the one replacing a handle that died';
  is $broker->calls, $asked, '... and the broker is asked no more';

  my $other = numbered_broker();
  $storage->connect_info([ $other ]);
  $storage->disconnect;
  $storage->dbh;
  is_deeply connects(), [ creds(2) ],
    "a broker given to the statically connected storage: the next connection is opened with its answer";
  is $broker->calls, $asked, '... the first broker still asked no more';
}

done_testing;
