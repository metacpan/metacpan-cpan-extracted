use strict;
use warnings;
use Test::More;

# LIVE: a jsonpath search written through the SQL maker finds the same rows
# over the schema's dbh and over the future_io transport (karr k120).
#
# WHY IT MATTERS: PostgreSQL's jsonpath operator is '@?', and a '?' is what
# DBD::Pg takes for a placeholder. Written bare, the statement of
# $rs->search({ data => { '@?' => $path } }) has two of them and one bind, and
# the dbh refuses it ("execute called with an unbound placeholder") -- the
# search ran over the async transports and nowhere else. The maker writes the
# operator as '@\?': DBD::Pg reads '\?' as a literal question mark and sends
# '@?', and the future_io transport, which numbers the placeholders itself,
# drops the backslash where it does (DBIO::PostgreSQL::Util::number_placeholders).
# One statement, the same rows on both ways. The text of the statement is held
# offline, in t/26-jsonb.t and t/104-number-placeholders.t; this is the server's
# answer to it.
#
# The claim: for every search below, ->all and ->count over the dbh, ->all_async
# and ->count_async over future_io, and the text as_query shows, run at a plain
# DBI handle, give the rows the data says they must.

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

# A server that is not there fails the file, with a plan (karr k113).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

BEGIN {
  package DBIO::Test::JsonpathMaker::Result::Doc;
  $INC{'DBIO/Test/JsonpathMaker/Result/Doc.pm'} = 1;
  use base 'DBIO::Core';

  __PACKAGE__->table('dbio_k120_jsonpath');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    data => { data_type => 'jsonb' },
  );
  __PACKAGE__->set_primary_key('id');

  package DBIO::Test::JsonpathMaker;
  $INC{'DBIO/Test/JsonpathMaker.pm'} = 1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Doc => 'DBIO::Test::JsonpathMaker::Result::Doc');
}

my $schema = DBIO::Test::JsonpathMaker->connect($dsn, $user, $pass, { async => 'future_io' });
my $async  = $schema->storage->async;
isa_ok $async, 'DBIO::PostgreSQL::Storage::Async', 'the future_io transport';

my $dbh = LiveServer->control_dbh;
$dbh->do('DROP TABLE IF EXISTS dbio_k120_jsonpath');
$dbh->do('CREATE TABLE dbio_k120_jsonpath (id integer PRIMARY KEY, data jsonb NOT NULL)');
$dbh->do('CREATE INDEX dbio_k120_jsonpath_data ON dbio_k120_jsonpath USING gin (data jsonb_path_ops)');
$dbh->do(q{INSERT INTO dbio_k120_jsonpath (id, data) VALUES (?, ?::jsonb)}, undef, @$_) for (
  [ 1, '{"status":"active","score":12,"tags":["a","b"]}' ],
  [ 2, '{"status":"inactive","score":3,"tags":["b"]}' ],
  [ 3, '{"status":"active","score":7,"note":"what?"}' ],
  [ 4, '{}' ],
);

my $rs = $schema->resultset('Doc');

# One reading per way; a statement that fails is a failed claim with its
# reason, and the file goes on.
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
  'the dbh: ->count'             => sub { $_[0]->count },
  'future_io: ->count_async'     => sub { $_[0]->count_async->get },
);

for my $case (
  [ 'a jsonpath with a filter, a ? of its own in the bind',
    { 'me.data' => { '@?' => '$.status ? (@ == "active")' } }, [ 1, 3 ] ],
  [ 'a jsonpath into an array',
    { 'me.data' => { '@?' => '$.tags[*] ? (@ == "b")' } }, [ 1, 2 ] ],
  [ 'a jsonpath that finds a key',
    { 'me.data' => { '@?' => '$.note' } }, [ 3 ] ],
  [ 'a jsonpath no row answers',
    { 'me.data' => { '@?' => '$.score ? (@ > 100)' } }, [] ],
  [ 'beside a bound column',
    { 'me.data' => { '@?' => '$.score ? (@ > 5)' }, 'me.id' => { '>' => 1 } }, [ 3 ] ],
  [ 'two of them, either one',
    { -or => [
        { 'me.data' => { '@?' => '$.note' } },
        { 'me.data' => { '@?' => '$.score ? (@ < 5)' } },
    ] }, [ 2, 3 ] ],
  [ 'beside the match operator @@',
    { -and => [
        { 'me.data' => { '@?' => '$.tags' } },
        { 'me.data' => { '@@' => '$.score > 5' } },
    ] }, [ 1 ] ],
) {
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

# Inside a subquery the operator keeps its form, and the outer statement runs.
# Over the dbh: a subquery handed over as as_query does not run over future_io
# whatever it holds -- its binds arrive there in the dbh's shape (noted on karr
# k120) -- so that way would say nothing about the operator.
{
  my $inner = $rs->search({ 'me.data' => { '@?' => '$.status ? (@ == "active")' } });
  my $outer = $rs->search(
    { 'me.id' => { -in => $inner->get_column('id')->as_query }, 'me.data' => { '@?' => '$.tags' } },
    { order_by => 'me.id' },
  );
  for my $way (grep { !/future_io/ } sort keys %ids_by) {
    my $got = eval { $ids_by{$way}->($outer) };
    diag "in a subquery, $way: $@" unless $got;
    is_deeply $got, [ 1 ], "in a subquery and beside it: $way";
  }
}

# Inside a transaction the statement goes over the connection the transaction
# is pinned to, a second way into the transport.
{
  my @rows = eval {
    $async->txn_do_async(sub {
      my ($txn) = @_;
      return $txn->select_async(
        'dbio_k120_jsonpath', ['id'],
        { data => { '@?' => '$.status ? (@ == "active")' } },
        { order_by => 'id' },
      );
    })->get;
  };
  diag "in a transaction over future_io: $@" if $@;
  is_deeply [ map { $_->[0] } @rows ], [ 1, 3 ],
    'future_io: the same search inside txn_do_async';
}

# It is the operator the server gets, and an index over the column answers it:
# a GIN index does that for '@?' and for no function call in its place.
{
  my ($sql, @bind) = @${ $rs->search({ 'me.data' => { '@?' => '$.status ? (@ == "active")' } })->as_query };
  my $plan = eval {
    $dbh->begin_work;
    $dbh->do('SET LOCAL enable_seqscan = off');
    my $lines = $dbh->selectcol_arrayref("EXPLAIN $sql", undef, map { $_->[1] } @bind);
    $dbh->rollback;
    join "\n", @$lines;
  };
  diag $@ unless defined $plan;
  like $plan // '', qr/dbio_k120_jsonpath_data/,
    'the search is answered from the GIN index over the column';
}

# A statement that changes rows by such a search.
{
  my $hit = { 'me.data' => { '@?' => '$.score ? (@ < 5)' } };

  my $changed = eval { $rs->search($hit)->update({ data => '{"score":4,"seen":"dbh"}' }) };
  diag "update over the dbh: $@" unless defined $changed;
  is_deeply
    $dbh->selectcol_arrayref(q{SELECT id FROM dbio_k120_jsonpath WHERE data->>'seen' = 'dbh'}),
    [ 2 ], 'an update by a jsonpath search over the dbh changes the row it finds';
}

END {
  if ($dbh) {
    local $@;
    eval { $dbh->do('DROP TABLE IF EXISTS dbio_k120_jsonpath') };
  }
}

$async->disconnect;
done_testing;
