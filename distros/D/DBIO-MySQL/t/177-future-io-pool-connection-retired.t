use strict;
use warnings;

use Test::More;

# WHY (core k398, ADR 0079): the pool of an async storage resets a connection
# when its borrow ends, through the transport's _reset_pool_connection, and a
# transport without one gets core's default, which fails: the connection is
# closed and the next borrow runs on a fresh one. DBD::mysql and DBD::MariaDB
# offer no session reset this transport could call, and the driver builds none
# of its own: it must stay on the core default. What this holds:
#   a. neither transport class has a _reset_pool_connection of its own;
#   b. so a statement on the pool leaves no connection behind: the one it ran on
#      is closed, and the next statement runs on a new one (a session of one
#      borrow -- role, variables, temporary tables -- never reaches the next).

BEGIN {
  eval {
    require DBIO::MySQL::Storage::Async;
    require DBIO::MySQL::Storage::MariaDB::Async;
    require Future;
    1;
  } or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

# --- a
for my $class (qw(DBIO::MySQL::Storage::Async DBIO::MySQL::Storage::MariaDB::Async)) {
  my $own = do { no strict 'refs'; defined &{"${class}::_reset_pool_connection"} };
  ok !$own, "a: $class has no reset of its own";
  is $class->can('_reset_pool_connection'), DBIO::Storage::Async->can('_reset_pool_connection'),
    "a: ... it answers core's default";
}

# --- b: the DBD is faked, the transport, the base's query path and the pool are real
{
  package K398::Sth;
  sub new { bless { NUM_OF_FIELDS => 1 }, shift }
  sub execute { 1 }
  sub mysql_async_ready  { 1 }
  sub mysql_async_result { 0 }
  sub fetchall_arrayref  { [ [1] ] }
  sub more_results { 0 }
}
{
  package K398::Dbh;
  my $id = 0;
  sub new { bless { Driver => { Name => 'mysql' }, Active => 1, err => undef, id => ++$id }, shift }
  sub prepare { K398::Sth->new }
  sub err { undef }
  sub disconnect { $_[0]{Active} = 0; $_[0]{closed} = 1 }
}
{
  package K398::Storage;
  use base 'DBIO::MySQL::Storage::Async';
  our @MADE;
  sub _await_readable { Future->done }
  sub _create_pool_connection { my $dbh = K398::Dbh->new; push @MADE, $dbh; { dbh => $dbh } }
  sub _idle_connection_alive { 1 }
  sub _shutdown_pool_connection { $_[1]{dbh}->disconnect if $_[1] && $_[1]{dbh} }
}

my $s = K398::Storage->new(undef);
$s->connect_info([{ host => 'localhost' }]);

my $first = $s->_query_async('SELECT 1', []);
my @rows = eval { $first->get };
is $@, '', 'b: a statement on the pool runs';
is scalar(@K398::Storage::MADE), 1, 'b: ... on one connection';

is_deeply [ $s->pool->size, $s->pool->available ], [ 0, 0 ],
  'b: at the end of the borrow the pool holds no connection: none idle, none counted';
ok $K398::Storage::MADE[0]{closed}, 'b: ... the connection was closed';

my $second = $s->_query_async('SELECT 1', []);
eval { $second->get };
is scalar(@K398::Storage::MADE), 2, 'b: the next statement runs on a new connection';

done_testing;
