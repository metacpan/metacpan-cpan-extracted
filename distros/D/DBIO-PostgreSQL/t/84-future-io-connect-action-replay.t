use strict;
use warnings;
use Test::More;

# OFFLINE test: the connect actions of a future_io connection reach its POOL
# connections (karr k99).
#
# WHY: a pool connection is a second PostgreSQL session beside the one the
# sync storage opens, and session state does not travel. on_connect_do =>
# [ 'SET search_path = tenant_a, public' ] shapes every sync query; an *_async
# query runs on whichever pool connection is free, and only core's replay puts
# the same statements onto that session (capability on_connect_replay, which
# this transport declares). Without it nothing fails: the query is answered
# against the default search_path -- another tenant's table of the same name,
# or "relation does not exist" on one connection out of ten -- with the wrong
# time zone, without the role the application meant to run as. And one replay
# too many is wrong as well: a connect action with a side effect would run
# again on every borrow.
#
# The runner itself is core's and is tested where it lives (dbio-async
# t/10-on-connect-replay.t, against a mock transport). What only this dist can
# show is that it reaches the connections THIS adapter opens, through the way
# an application gets them: until this file, t/73 pinned that on_connect_do
# stays out of the DBD attributes, and that it is ever executed was shown by
# the live suite alone.
#
# What this file claims:
#   1. every pool connection sees every connect action exactly once, the
#      on_connect_call actions first and on_connect_do in the order given,
#      bind values included -- and all of it before the first statement of a
#      caller;
#   2. a connection handed out again from the idle list does not see them a
#      second time;
#   3. the dedicated listen connection sees none of them (the promise in the
#      POD of _listen_open);
#   4. a connection without connect actions gets no statement it was not
#      asked for, while another connection of the same schema class has some;
#   5. a connect action the server refuses fails the caller, whose statement
#      is never sent on that connection; the connection is closed and not
#      kept, and the next one is set up in full.
#
# WHAT RUNS FOR REAL: the schema connect with { async => 'future_io' }, the
# sync driver storage owning the actions, core's transport resolution and
# replay dispatch, the real pool, and the shipped adapter with its
# _create_pool_connection / _submit_query / _collect_result / _listen_open.
# THE SUBSTITUTIONS: DBI->connect hands out a fake DBD::Pg handle that keeps a
# log of what it was sent; _await_readable is answered by the test (there is
# no socket to poll), which is what lets two statements be in flight at once;
# and the borrow-time check _idle_connection_alive answers its default, as in
# t/64 (t/75 pins the check itself). Both seams are replaced on the shipped
# class, not on a subclass: the schema resolves the transport by name.
#
# NOT HERE: the public listen() -- it needs a socket to watch. Claim 3 is made
# at the seam core opens the listen connection through.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

# --- the fake DBD::Pg -----------------------------------------------------------

our @CONNECTS;   # one entry per DBI->connect, in order
our @READABLE;   # the pending _await_readable Futures
our $REFUSE;     # a blocking statement matching this is refused by the "server"
my $next_pid = 8400;

{
  package FakeReplay::DBH;

  sub new {
    my ($class) = @_;
    return bless {
      Active    => 1,
      pg_socket => 42,
      pg_pid    => ++$next_pid,
      log       => [],
    }, $class;
  }

  # The blocking statement core's replay sends: do($sql, \%attrs, @bind).
  sub do {
    my ($self, $sql, $attrs, @bind) = @_;
    push @{ $self->{log} }, [ do => $sql, @bind ];
    die qq{DBD::Pg::db do failed: ERROR:  role "app_reader" does not exist\n}
      if defined $main::REFUSE && $sql =~ $main::REFUSE;
    return '0E0';
  }

  # The async statement of a caller (_submit_query).
  sub prepare {
    my ($self, $sql, $attrs) = @_;
    return bless { dbh => $self, sql => $sql, NUM_OF_FIELDS => 1 }, 'FakeReplay::STH';
  }

  sub pg_ready  { 1 }
  sub pg_result { 1 }
  sub state     { q{} }

  sub disconnect {
    my ($self) = @_;
    $self->{Active} = 0;
    return 1;
  }
}

{
  package FakeReplay::STH;

  sub execute {
    my ($self, @bind) = @_;
    push @{ $self->{dbh}{log} }, [ query => $self->{sql}, @bind ];
    return 1;
  }

  sub fetchall_arrayref { return [ [ $_[0]{dbh}{pg_pid} ] ] }
}

{
  no warnings 'redefine', 'once';

  *DBI::connect = sub {
    my ($class, $dsn, $user, $password, $attrs) = @_;
    my $dbh = FakeReplay::DBH->new;
    push @CONNECTS, { dsn => $dsn, dbh => $dbh };
    return $dbh;
  };

  # The socket turns readable when the test says so (answer_all).
  *DBIO::PostgreSQL::Storage::Async::_await_readable = sub {
    my $f = $_[0]->future_class->new;
    push @READABLE, $f;
    return $f;
  };

  # Held at the seam's default: the fake's pg_socket is no real fd.
  *DBIO::PostgreSQL::Storage::Async::_idle_connection_alive = sub { 1 };

  # The replay this file counts is the connect's. The reset between borrows
  # (DISCARD ALL and the replay again, k154) is t/196's claim.
  *DBIO::PostgreSQL::Storage::Async::_reset_pool_connection = sub { $_[0]->future_class->done };
}

{
  package Replay84::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

# --- helpers --------------------------------------------------------------------

# A schema connected the way an application connects it, and its async backend.
sub connected {
  my (%options) = @_;
  @CONNECTS = @READABLE = ();
  my $schema = Replay84::Schema->connect(
    'dbi:Pg:dbname=replay_test', 'u', 'p', { async => 'future_io', %options },
  );
  return ($schema, $schema->storage->async);
}

# One statement of a caller, named by its table.
sub query {
  my ($async, $table) = @_;
  return $async->select_async($table, ['x'], {});
}

# Every statement in flight gets its result.
sub answer_all {
  while (my $f = shift @READABLE) {
    $f->done unless $f->is_ready;
  }
  return;
}

# The connect actions a handle was sent, in order.
sub setup_of {
  my ($dbh) = @_;
  return [ map { $_->[1] } grep { $_->[0] eq 'do' } @{ $dbh->{log} } ];
}

# The callers' statements a handle was sent, in order, by table.
sub queries_of {
  my ($dbh) = @_;
  return [
    map  { $_->[1] =~ /FROM "?(\w+)/ ? $1 : $_->[1] }
    grep { $_->[0] eq 'query' } @{ $dbh->{log} }
  ];
}

# How many connect actions a handle was sent before its first caller's statement.
sub setup_ahead_of_first_query {
  my ($dbh) = @_;
  my $ahead = 0;
  for my $entry (@{ $dbh->{log} }) {
    last if $entry->[0] eq 'query';
    $ahead++;
  }
  return $ahead;
}

sub pool_state {
  my ($async) = @_;
  return [ $async->pool->size, $async->pool->available ];
}

# ---------------------------------------------------------------------------
# 1. Every pool connection, once, in order, ahead of the caller.
# ---------------------------------------------------------------------------

my @SETUP = (
  'SELECT set_config(?, ?, false)',        # on_connect_call
  'SET search_path = tenant_a, public',    # on_connect_do, as given
  q{SET TIME ZONE 'UTC'},
);

# Kept to the end of the file: claim 4 needs it alive beside another one.
my ($tenant_schema, $tenant) = connected(
  pool_size       => 2,
  on_connect_call => [ [ do_sql => [ $SETUP[0], {}, 'app.tenant', 'tenant_a' ] ] ],
  on_connect_do   => [ @SETUP[1, 2] ],
);

is ref $tenant, 'DBIO::PostgreSQL::Storage::Async',
  'the schema\'s future_io backend is the shipped adapter';
is scalar(@CONNECTS), 0, 'connecting the schema opens no connection';

my @first = map { query($tenant, $_) } qw( first second );
is scalar(@CONNECTS), 2,
  'two statements in flight: a pool connection was opened for each, and none besides';
answer_all();
ok $_->is_done, 'the statement completes' for @first;

my @pooled = map { $_->{dbh} } @CONNECTS;

for my $i (0, 1) {
  my $dbh  = $pooled[$i];
  my $name = 'pool connection ' . ($i + 1);

  is_deeply setup_of($dbh), \@SETUP,
    "$name: every connect action once -- on_connect_call first, on_connect_do in the order given";
  is_deeply $dbh->{log}[0], [ do => $SETUP[0], 'app.tenant', 'tenant_a' ],
    "$name: ... with its bind values";
  is setup_ahead_of_first_query($dbh), scalar(@SETUP),
    "$name: ... all of them before the first statement of a caller";
  is scalar(@{ queries_of($dbh) }), 1, "$name: ... which is the one it was opened for";
}

# ---------------------------------------------------------------------------
# 2. Handed out again from the idle list: the same session, no second replay.
# ---------------------------------------------------------------------------

is_deeply pool_state($tenant), [ 2, 2 ], 'both connections are back in the pool, idle';

my @again = map { query($tenant, $_) } qw( third fourth );
answer_all();
push @again, query($tenant, 'fifth');
answer_all();
ok $_->is_done, 'a later statement completes' for @again;

is scalar(@CONNECTS), 2, 'three more statements: no connection was opened for them';
is_deeply [ sort map { @{ queries_of($_) } } @pooled ],
  [ sort qw( first second third fourth fifth ) ],
  '... all five ran on the two pool connections';

for my $i (0, 1) {
  my $dbh  = $pooled[$i];
  my $name = 'pool connection ' . ($i + 1);

  cmp_ok scalar(@{ queries_of($dbh) }), '>=', 2, "$name: was handed out again";
  is scalar(@{ setup_of($dbh) }), scalar(@SETUP),
    "$name: ... and saw the connect actions once, not once per borrow";
}

# ---------------------------------------------------------------------------
# 3. The listen connection. It only ever runs LISTEN, UNLISTEN and a ping; a
#    session-setup statement with a side effect must not run once more per
#    reconnect.
# ---------------------------------------------------------------------------

{
  my $listen = $tenant->_listen_open->get;
  is scalar(@CONNECTS), 3, 'the listen connection is a connection of its own';
  is $listen->{dbh}, $CONNECTS[-1]{dbh}, '... the handle DBI->connect just handed out';
  is_deeply $listen->{dbh}{log}, [],
    'no connect action is replayed on the listen connection';
}

# ---------------------------------------------------------------------------
# 4. No connect actions: no statement that was not asked for -- with the
#    connection above, of the same schema class, still alive and set up.
# ---------------------------------------------------------------------------

{
  my ($schema, $plain) = connected(pool_size => 1);

  my $f = query($plain, 'plain');
  answer_all();
  ok $f->is_done, 'a statement on a connection without connect actions completes';
  is scalar(@CONNECTS), 1, '... on one pool connection';
  is $CONNECTS[0]{dbh}{log}[0][0], 'query', '... whose first statement is the caller\'s';
  is_deeply setup_of($CONNECTS[0]{dbh}), [], '... and which was sent nothing else';
}

# ---------------------------------------------------------------------------
# 5. A refused connect action. The connection is only half set up; the
#    caller's statement must not run on it.
# ---------------------------------------------------------------------------

{
  my @actions = ('SET search_path = tenant_a, public', 'SET ROLE app_reader');
  my ($schema, $async) = connected(pool_size => 1, on_connect_do => [ @actions ]);

  my ($f, $refused);
  {
    local $REFUSE = qr/SET ROLE/;
    $f = query($async, 'never');
    answer_all();
    $refused = $CONNECTS[0]{dbh};
  }

  ok $f->is_ready && $f->is_failed, 'a refused connect action fails the caller\'s statement';
  like scalar($f->failure), qr/role "app_reader" does not exist/, '... with the server\'s error';
  is_deeply setup_of($refused), \@actions, 'the connection got as far as the refused action';
  is_deeply queries_of($refused), [], '... and the caller\'s statement was never sent on it';
  ok !$refused->{Active}, '... it is closed';
  is_deeply pool_state($async), [ 0, 0 ], '... and not kept in the pool';

  my $next = query($async, 'after');
  answer_all();
  ok $next->is_done, 'once the server accepts the action, the next statement completes';
  is scalar(@CONNECTS), 2, '... on a newly opened connection';
  my $dbh = $CONNECTS[1]{dbh};
  is_deeply setup_of($dbh), \@actions, '... set up in full';
  is setup_ahead_of_first_query($dbh), scalar(@actions), '... before the statement ran on it';
  is_deeply queries_of($dbh), [ 'after' ], '... which is the caller\'s';
}

done_testing;
