use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;
use DBIO::Storage::PoolBase;

# karr k342: the binds an async runner (_query_async / _query_async_pinned)
# receives are bare VALUES. A subquery's as_query hands its literal binds over
# in the sync convention, [ \%attrs => $value ]; the async maker runs with
# bindtype normal, so a column bind is already a bare value but a literal bind
# stays a pair. A transport takes every bind as one value, so core unpacks the
# pair at the one point it hands maker output to the runner -- by the rule of
# the sync path, DBIO::Storage::DBI::_resolve_bindattrs: a two-element arrayref
# with a HASH or undef in front is a pair.
#
# Claim: for each statement shape (subquery in WHERE IN, in FROM, as a
# column) and each op, the runner's binds are exactly the sync path's binds
# with the attribute halves taken off, in the same order. The sync path is
# computed in the same test as the reference; nothing is hard-coded but the
# one expectation that proves the subquery's value took part.
#
# Mock only: DBIO::Test::Storage as the sync owner, a runner that records.

{
  package K342::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { bless { id => ++$_[0]->{_next_id} }, 'K342::Conn' }
}

{
  package K342::Backend;
  use base 'DBIO::Storage::Async';
  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }
  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= K342::Pool->new(
      conninfo => 'fake', size => 1, future_class => $self->future_class,
    );
  }
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{captured} }, [ $sql, @{ $bind || [] } ];
    return $self->future_class->new->done([ 1 ]);
  }
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    return $self->_query_async($sql, $bind);
  }
}

my $schema  = DBIO::Test->init_schema;
my $storage = $schema->storage;

my $backend = K342::Backend->new($schema);
$backend->_owner_storage($storage);
$backend->{captured} = [];
$storage->_async_mode('k342');
$storage->{_async_storage_obj} = $backend;
$storage->_use_supports_exists_query(1);
$storage->mock_persistent(qr/COUNT/i, [ [ 1 ] ]);

# What the sync path binds for a statement: the values, attribute halves off.
sub sync_values {
  my ($code) = @_;
  $storage->reset_captured;
  $code->();
  my @q = $storage->captured_queries;
  die "expected one sync statement, got " . @q unless @q == 1;
  return [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $q[0]{bind} || [] } ];
}

# What the runner got for the async statement.
sub runner_binds {
  my ($code) = @_;
  $backend->{captured} = [];
  $code->();
  die "expected one runner call, got " . @{ $backend->{captured} }
    unless @{ $backend->{captured} } == 1;
  my ($sql, @bind) = @{ $backend->{captured}[0] };
  return \@bind;
}

sub is_all_values {
  my ($bind, $name) = @_;
  my @pairs = grep { ref $_ } @$bind;
  ok !@pairs, $name or diag explain $bind;
}

my $sub_rs = $schema->resultset('Artist')->search(
  { rank => 7, name => { '!=' => 'ghost' } },
  { columns => ['artistid'] },
);
my $rs = $schema->resultset('CD');

my %shape = (
  'subquery in WHERE IN' => sub {
    $rs->search({
      artist => { -in => $sub_rs->as_query },
      title  => 'Spoonful',
    });
  },
  'subquery in FROM' => sub {
    $sub_rs->search({ name => 'Caterwauler' })->as_subselect_rs;
  },
  'subquery as a column' => sub {
    $rs->search({ title => 'Spoonful' }, {
      columns    => ['cdid'],
      '+columns' => { n => $sub_rs->count_rs->as_query },
    });
  },
);

for my $name (sort keys %shape) {
  subtest $name => sub {
    my $mk = $shape{$name};

    # a column subquery is no part of the count statement
    for my $op ($name eq 'subquery as a column' ? 'all' : qw(all count)) {
      my $sync = sync_values(sub {
        $op eq 'all' ? $mk->()->all : $mk->()->count;
      });
      my $async = runner_binds(sub {
        $op eq 'all' ? $mk->()->all_async : $mk->()->count_async;
      });

      ok scalar @$sync >= 2, "$op: the sync statement carries binds"
        or diag explain $sync;
      is_all_values($async, "$op: the runner got bare values only");
      is_deeply $async, $sync,
        "$op: the runner's binds are the sync binds, values only, same order";
      ok scalar( grep { defined $_ && $_ eq '7' } @$async ),
        "$op: the subquery's own value (7) is among them";
    }
  };
}

# --- update / delete with a subquery in the WHERE -----------------------------
{
  my $source = $schema->source('CD');
  my $where  = { artist => { -in => $sub_rs->as_query }, title => 'Spoonful' };

  my $sync_u = sync_values(sub { $storage->update($source, { year => 1999 }, $where) });
  my $async_u = runner_binds(sub { $backend->update_async($source, { year => 1999 }, $where) });
  is_all_values($async_u, 'update_async: the runner got bare values only');
  is_deeply $async_u, $sync_u, 'update_async: same values, same order as sync update';

  my $sync_d = sync_values(sub { $storage->delete($source, $where) });
  my $async_d = runner_binds(sub { $backend->delete_async($source, $where) });
  is_all_values($async_d, 'delete_async: the runner got bare values only');
  is_deeply $async_d, $sync_d, 'delete_async: same values, same order as sync delete';
}

# --- results_exist_async: the statement bypasses _run_crud --------------------
{
  my $exists = $rs->search({
    artist => { -in => $sub_rs->as_query },
    title  => 'Spoonful',
  });
  $storage->mock_persistent(qr/EXISTS/i, [ [ 1 ] ]);

  my $sync = sync_values(sub { $exists->results_exist });
  my $async = runner_binds(sub { $exists->results_exist_async });

  ok scalar @$sync >= 2, 'results_exist: the sync statement carries binds';
  is_all_values($async, 'results_exist_async: the runner got bare values only');
  is_deeply $async, $sync, '... the sync values, same order';
}

# --- the form is a pair, whoever wrote it --------------------------------------
# The rule is the sync path's: a two-element arrayref with a HASH or undef in
# front is [ attributes => value ]. So a plain value of exactly that form is
# read as a pair; an arrayref of any other shape is not touched.
{
  is_deeply [ DBIO::Util::bare_binds([ {} => 1 ], [ undef, 2 ], [ { sqlt_datatype => 'int' } => 3 ], 4 ) ],
    [ 1, 2, 3, 4 ], 'a pair with HASH or undef in front gives its value';
  my $three = [ {}, 1, 2 ];
  my $one   = [ 'a' ];
  my $strfirst = [ 'x', 'y' ];
  is_deeply [ DBIO::Util::bare_binds($three, $one, $strfirst, undef) ],
    [ $three, $one, $strfirst, undef ], 'every other shape is left alone';
}

done_testing;
