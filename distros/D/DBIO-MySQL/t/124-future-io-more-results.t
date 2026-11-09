use strict;
use warnings;

use Test::More;

# OFFLINE test for karr k73: a statement with several result sets (a CALL)
# leaves the later ones unread, and the client library then refuses every
# further statement on that pool connection (DBD::MariaDB 1.24: 2000). The
# collector reads them out (more_results); when that fails the connection is
# retired. The DBD handle is faked; the transport, the base's query path and
# a real DBIO::Async::Pool are real.

BEGIN {
  eval {
    require DBIO::MySQL::Storage::Async;
    require Future;
    1;
  } or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

{
  package K73::Sth;
  # more => N further result sets (each more_results call consumes one);
  # more_die => the call that dies (1-based).
  sub new { my ($c, %a) = @_; bless { NUM_OF_FIELDS => 1, more => 0, calls => 0, %a }, $c }
  sub execute { 1 }
  sub mysql_async_ready  { 1 }
  sub mysql_async_result { 0 }
  sub fetchall_arrayref  { [ [1] ] }
  sub more_results {
    my $self = shift;
    $self->{calls}++;
    die "more_results failed\n" if $self->{more_die} && $self->{calls} == $self->{more_die};
    return $self->{more}-- > 0 ? 1 : 0;
  }
}

{
  package K73::Dbh;
  sub new { bless { Driver => { Name => 'mysql' }, Active => 1, err => undef }, shift }
  sub prepare { my ($s, $sql) = @_; $s->{sth} = K73::Sth->new(%{ $s->{sth_args} || {} }) }
  sub err { $_[0]{err} }
  sub disconnect { $_[0]{Active} = 0 }
}

{
  package K73::Storage;
  use base 'DBIO::MySQL::Storage::Async';
  sub _await_readable { Future->done }
  sub _create_pool_connection { my $dbh = K73::Dbh->new; $dbh->{sth_args} = $_[0]{sth_args}; { dbh => $dbh } }
  sub _idle_connection_alive { 1 }
  sub _shutdown_pool_connection { }
  # The real transport has no reset (core ADR 0079: its connection is retired at
  # the end of every borrow). This test is about what more_results does to the
  # connection, so the fake gives one that survives the borrow: a connection
  # still in the pool is one the collector did not retire.
  sub _reset_pool_connection { Future->done }
}

sub run {
  my ($sth_args) = @_;
  my $s = K73::Storage->new(undef);
  $s->{sth_args} = $sth_args;
  $s->connect_info([{ host => 'localhost' }]);
  my $f = $s->_query_async('CALL p()', []);
  my ($conn) = grep { defined } @{ $s->pool->{_connections} };
  return ($s, $conn, $f);
}

# 1. two further result sets: read out, rows are the first set's.
{
  my ($s, $conn, $f) = run({ more => 2 });
  my @rows = eval { $f->get };
  is $@, '', 'a CALL with three result sets resolves';
  is_deeply \@rows, [ [1] ], '... with the rows of the first';
  is $conn->{dbh}{sth}{calls}, 3,
    '... more_results was asked until it said no (2 sets + the final no)';
  ok !$s->pool->_connection_is_dead($conn), '... and the connection is not retired';
}

# 2. one result set: one question, no more.
{
  my ($s, $conn, $f) = run({ more => 0 });
  my @rows = eval { $f->get };
  is_deeply \@rows, [ [1] ], 'a single result set resolves as before';
  is $conn->{dbh}{sth}{calls}, 1, '... more_results asked exactly once';
}

# 3. reading them out fails: the statement fails and the connection is retired.
{
  my ($s, $conn, $f) = run({ more => 2, more_die => 2 });
  ok eval { $f->get; 1 } ? 0 : 1, 'a failing drain fails the statement';
  like $f->failure, qr/more_results failed/, '... with the error';
  ok $s->_conn_error_is_fatal($conn, $f->failure), '... and the seam says the connection is dead';
  ok !( grep { defined && $_ == $conn } @{ $s->pool->{_idle} || [] } ),
    '... so the pool did not idle it again';
}

done_testing;
