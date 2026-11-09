use strict;
use warnings;
use Test::More;

# OFFLINE test: the reset of a future_io pool connection at the end of a borrow
# (karr k154, core k398).
#
# CLAIM: when a borrow ends, the connection is sent DISCARD ALL and then the
# connect actions again, in that order, and goes to the next borrower only
# after both; the borrower after that runs on the same connection. A connect
# action the server refuses during the reset retires the connection: it is
# closed, the pool does not keep it, and the next borrower gets a fresh one,
# set up in full.
#
# The server's side of the reset (what DISCARD ALL clears) is t/195's claim,
# against a real PostgreSQL. THE SUBSTITUTIONS are those of t/84: a fake
# DBD::Pg handle with a log, _await_readable answered by the test, and the
# borrow-time check _idle_connection_alive at its default.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

our @CONNECTS;
our @READABLE;
our $REFUSE;
my $next_pid = 9600;

{
  package FakeReset::DBH;

  sub new {
    return bless { Active => 1, pg_socket => 42, pg_pid => ++$next_pid, log => [] }, shift;
  }

  sub do {
    my ($self, $sql, $attrs, @bind) = @_;
    push @{ $self->{log} }, [ do => $sql ];
    die qq{DBD::Pg::db do failed: ERROR:  refused\n}
      if defined $main::REFUSE && $sql =~ $main::REFUSE;
    return '0E0';
  }

  sub prepare {
    my ($self, $sql) = @_;
    return bless { dbh => $self, sql => $sql, NUM_OF_FIELDS => 1 }, 'FakeReset::STH';
  }

  sub pg_ready  { 1 }
  sub pg_result { 1 }
  sub state     { q{} }

  sub disconnect { $_[0]{Active} = 0; return 1 }
}

{
  package FakeReset::STH;

  sub execute {
    my ($self, @bind) = @_;
    push @{ $self->{dbh}{log} }, [ query => $self->{sql} ];
    return 1;
  }

  sub fetchall_arrayref { [ [ 1 ] ] }
}

{
  no warnings 'redefine', 'once';

  *DBI::connect = sub {
    my $dbh = FakeReset::DBH->new;
    push @CONNECTS, $dbh;
    return $dbh;
  };

  *DBIO::PostgreSQL::Storage::Async::_await_readable = sub {
    my $f = $_[0]->future_class->new;
    push @READABLE, $f;
    return $f;
  };

  *DBIO::PostgreSQL::Storage::Async::_idle_connection_alive = sub { 1 };
}

{
  package Reset196::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

my $schema = Reset196::Schema->connect('dbi:Pg:dbname=reset_test', 'u', 'p', {
  async         => 'future_io',
  pool_size     => 1,
  on_connect_do => [ 'SET search_path = tenant_a, public' ],
});
my $async = $schema->storage->async;

# Statements in flight get their results until nothing is left.
sub settle {
  for (1 .. 10) {
    last unless @READABLE;
    while (my $f = shift @READABLE) { $f->done unless $f->is_ready }
  }
}

# What a handle was sent, in order: connect actions as "do: SQL", statements as
# "query: SQL" (a caller's statement is shortened to its table).
sub wire {
  my ($dbh) = @_;
  return [ map {
    my ($kind, $sql) = @$_;
    $sql =~ s/\ASELECT .* FROM "?(\w+).*\z/$1/s;
    "$kind: $sql";
  } @{ $dbh->{log} } ];
}

my $first = $async->select_async('first', ['x'], {});
settle();
ok $first->is_done, 'a statement completes';
is $async->pool->available, 1, 'its connection is back in the pool, idle';
my ($dbh) = @CONNECTS;

is_deeply wire($dbh), [
  'do: SET search_path = tenant_a, public',
  'query: first',
  'query: DISCARD ALL',
  'do: SET search_path = tenant_a, public',
], 'the borrow ends with DISCARD ALL and the connect actions again, in that order';

my $second = $async->select_async('second', ['x'], {});
settle();
ok $second->is_done, 'the next statement completes';
is scalar(@CONNECTS), 1, '... on the same connection';
is_deeply [ @{ wire($dbh) }[4 .. 5] ], [ 'query: second', 'query: DISCARD ALL' ],
  '... which is reset again when that borrow ends';

# A connect action refused during the reset retires the connection.
$REFUSE = qr/search_path/;
my $third = $async->select_async('third', ['x'], {});
settle();
ok $third->is_done, 'the statement of the borrow whose reset fails still completes';
is $async->pool->size, 0, 'the connection whose reset failed is not kept';
ok !$dbh->{Active}, '... it is closed';

$REFUSE = undef;
my $fourth = $async->select_async('fourth', ['x'], {});
settle();
ok $fourth->is_done, 'the next borrower is served';
is scalar(@CONNECTS), 2, '... by a fresh connection';
is_deeply [ @{ wire($CONNECTS[1]) }[0 .. 1] ],
  [ 'do: SET search_path = tenant_a, public', 'query: fourth' ],
  '... set up in full before its first statement';

done_testing;
