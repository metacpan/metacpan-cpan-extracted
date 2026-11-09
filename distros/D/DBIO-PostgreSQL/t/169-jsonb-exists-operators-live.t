use strict;
use warnings;
use Test::More;

# LIVE: the key-existence operators ? ?| ?& are written as the operators
# \? \?| \?& and a GIN index over the column answers them, over the dbh and
# over the future_io transport (karr k121, point 18; maintainer's decision
# 2026-10-22).
#
# WHY IT MATTERS: the maker used to write jsonb_exists(col, ?),
# jsonb_exists_any() and jsonb_exists_all(). They are the functions behind the
# operators, but the planner does not see through a function call: a GIN index
# over the column is used for the operator and for no call in its place, so a
# key search was a sequential scan. The operator has a '?' in it, which
# DBD::Pg takes for a placeholder; the maker writes it '\?' -- as it writes
# the jsonpath operator '@\?' (t/130) -- which DBD::Pg sends as '?', and which
# the future_io transport (DBIO::PostgreSQL::Util::number_placeholders) reads
# as a literal question mark, too.
#
# The claims:
#   1. ->all and ->count over the dbh, ->all_async and ->count_async over
#      future_io, and the text of as_query run at a plain DBI handle, give the
#      rows the data says they must;
#   2. as_query shows the operator, not a function;
#   3. the server plans the search over the GIN index. The table is small, so
#      the planner would prefer a sequential scan whatever the statement
#      says: the session turns enable_seqscan off. Under it a statement the
#      planner can answer from the index does so, and one it cannot (a
#      function call) stays a Seq Scan -- that is the difference measured.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io transport';
}

eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

BEGIN {
  package DBIO::Test::JsonbExists::Result::Doc;
  $INC{'DBIO/Test/JsonbExists/Result/Doc.pm'} = 1;
  use base 'DBIO::Core';

  __PACKAGE__->table('dbio_k121_jsonb_exists');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    data => { data_type => 'jsonb' },
  );
  __PACKAGE__->set_primary_key('id');

  package DBIO::Test::JsonbExists;
  $INC{'DBIO/Test/JsonbExists.pm'} = 1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Doc => 'DBIO::Test::JsonbExists::Result::Doc');
}

my $schema = DBIO::Test::JsonbExists->connect($dsn, $user, $pass, { async => 'future_io' });
my $async  = $schema->storage->async;
isa_ok $async, 'DBIO::PostgreSQL::Storage::Async', 'the future_io transport';

my $dbh = LiveServer->control_dbh;
$dbh->do('DROP TABLE IF EXISTS dbio_k121_jsonb_exists');
$dbh->do('CREATE TABLE dbio_k121_jsonb_exists (id integer PRIMARY KEY, data jsonb NOT NULL)');
$dbh->do('CREATE INDEX dbio_k121_jsonb_exists_data ON dbio_k121_jsonb_exists USING gin (data)');
$dbh->do(q{INSERT INTO dbio_k121_jsonb_exists (id, data) VALUES (?, ?::jsonb)}, undef, @$_) for (
  [ 1, '{"email":"a@x","phone":"1","name":"A"}' ],
  [ 2, '{"email":"b@x","name":"B"}' ],
  [ 3, '{"phone":"3","name":"C","note":"what?"}' ],
  [ 4, '{}' ],
);

my $rs = $schema->resultset('Doc');

my %ids_by = (
  'the dbh: ->all' => sub {
    [ map { $_->id } $_[0]->all ];
  },
  'future_io: ->all_async' => sub {
    [ map { $_->id } $_[0]->all_async->get ];
  },
  'a plain DBI handle running the text of as_query' => sub {
    my ($sql, @bind) = @${ $_[0]->as_query };
    $dbh->selectcol_arrayref($sql, undef, map { $_->[1] } @bind);
  },
);
my %count_by = (
  'the dbh: ->count'         => sub { $_[0]->count },
  'future_io: ->count_async' => sub { $_[0]->count_async->get },
);

my @cases = (
  [ '? a key', { 'me.data' => { '?' => 'email' } }, [ 1, 2 ] ],
  [ '? a key no row has', { 'me.data' => { '?' => 'nothing' } }, [] ],
  [ '?| any of two keys', { 'me.data' => { '?|' => [qw(email phone)] } }, [ 1, 2, 3 ] ],
  [ '?| one key as a string', { 'me.data' => { '?|' => 'note' } }, [ 3 ] ],
  [ '?& all of two keys', { 'me.data' => { '?&' => [qw(email phone)] } }, [ 1 ] ],
  [ '?& all of three keys', { 'me.data' => { '?&' => [qw(email phone name)] } }, [ 1 ] ],
  [ '? beside a bound column', { 'me.data' => { '?' => 'name' }, 'me.id' => { '>' => 1 } }, [ 2, 3 ] ],
  [ 'two of them, either one', { -or => [
      { 'me.data' => { '?' => 'note' } },
      { 'me.data' => { '?&' => [qw(email phone)] } },
    ] }, [ 1, 3 ] ],
  [ '? beside the jsonpath operator @?', { -and => [
      { 'me.data' => { '?' => 'name' } },
      { 'me.data' => { '@?' => '$.note' } },
    ] }, [ 3 ] ],
);

for my $case (@cases) {
  my ($name, $where, $want) = @$case;
  my $search = $rs->search($where, { order_by => 'me.id' });

  for my $way (sort keys %ids_by) {
    my $got = eval { $ids_by{$way}->($search) };
    diag "$name, $way: $@" unless $got;
    is_deeply $got, $want, "$name: $way";
  }
  for my $way (sort keys %count_by) {
    my $got = eval { $count_by{$way}->(scalar $rs->search($where)) };
    diag "$name, $way: $@" unless defined $got;
    is $got, scalar(@$want), "$name: $way";
  }
}

# The statement shows the operator, never a function call.
for my $case (
  [ { 'me.data' => { '?' => 'email' } },          qr/"me"\."data" \\\? \?/ ],
  [ { 'me.data' => { '?|' => [qw(a b)] } },       qr/"me"\."data" \\\?\| ARRAY\[\?, \?\]/ ],
  [ { 'me.data' => { '?&' => [qw(a b)] } },       qr/"me"\."data" \\\?& ARRAY\[\?, \?\]/ ],
) {
  my ($where, $re) = @$case;
  my ($sql) = @${ $rs->search($where)->as_query };
  like $sql, $re, "as_query shows the operator: $sql";
  unlike $sql, qr/jsonb_exists(?:_any|_all)?\(/, '... and no function call';
}

# The plan: a GIN index over the column answers the operator. enable_seqscan
# is off in the session because the table has four rows, and for four rows
# the planner would scan whatever the statement is.
for my $case (
  [ '?',  { 'me.data' => { '?' => 'email' } } ],
  [ '?|', { 'me.data' => { '?|' => [qw(email phone)] } } ],
  [ '?&', { 'me.data' => { '?&' => [qw(email phone)] } } ],
) {
  my ($op, $where) = @$case;
  my ($sql, @bind) = @${ $rs->search($where)->as_query };
  my $plan = eval {
    $dbh->begin_work;
    $dbh->do('SET LOCAL enable_seqscan = off');
    my $lines = $dbh->selectcol_arrayref("EXPLAIN $sql", undef, map { $_->[1] } @bind);
    $dbh->rollback;
    join "\n", @$lines;
  };
  $dbh->rollback if $@ && !$dbh->{AutoCommit};
  diag "EXPLAIN $op: $@" unless defined $plan;
  like $plan // '', qr/dbio_k121_jsonb_exists_data/,
    "$op: answered from the GIN index over the column (enable_seqscan off)";
  unlike $plan // '', qr/Seq Scan/, "$op: no Seq Scan in the plan";
}

END {
  if ($dbh) {
    local $@;
    eval { $dbh->do('DROP TABLE IF EXISTS dbio_k121_jsonb_exists') };
  }
}

$async->disconnect;
done_testing;
