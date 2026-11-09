use strict;
use warnings;
use Test::More;

# LIVE: a plain value in the update set of an upsert reaches the column through
# the future_io transport (karr k122).
#
# DBIO::PostgreSQL::SQLMaker::_insert_on_conflict bound that value as
# [ $column => $value] whatever the bindtype of the maker. The sync driver's
# maker has bindtype 'columns', which is that shape; the future_io transport's
# has none ('normal', bare values), so DBD::Pg got the pair as one bind, took
# the arrayref for a PostgreSQL array and wrote '{"note","fixed"}' into a text
# column -- or, in an integer column, failed with 'invalid input syntax'.
# The sync side of the same claim is in t/42-upsert-live.t, the shape of the
# binds, offline, in t/41-upsert-on-conflict.t.
#
# The claim: what $rs->upsert_async and $storage->insert_async write for
# set => { note => 'fixed' } is the string 'fixed', with and without
# update_where, beside a literal and an -attempted value.

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

use Future;
use Future::IO;

eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

# A server that is not there fails the file, with a plan (karr k113).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

BEGIN {
  package DBIO::Test::UpsertSetBind::Result::Probe;
  $INC{'DBIO/Test/UpsertSetBind/Result/Probe.pm'} = 1;
  use base 'DBIO::Core';

  __PACKAGE__->table('dbio_k122_probe');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
    rank => { data_type => 'integer', default_value => 0 },
    note => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(dbio_k122_probe_name => ['name']);

  package DBIO::Test::UpsertSetBind;
  $INC{'DBIO/Test/UpsertSetBind.pm'} = 1;
  use DBIO 'Schema', -pg;
  __PACKAGE__->register_class(Probe => 'DBIO::Test::UpsertSetBind::Result::Probe');
}

my $schema = DBIO::Test::UpsertSetBind->connect($dsn, $user, $pass, { async => 'future_io' });
my $async  = $schema->storage->async;
isa_ok $async, 'DBIO::PostgreSQL::Storage::Async', 'the future_io transport';

my $dbh = LiveServer->control_dbh;
$dbh->do('DROP TABLE IF EXISTS dbio_k122_probe');
$dbh->do(<<'SQL');
CREATE TABLE dbio_k122_probe (
  id   serial  PRIMARY KEY,
  name text    NOT NULL UNIQUE,
  rank integer NOT NULL DEFAULT 0,
  note text
)
SQL

my $source = $schema->source('Probe');
my $rs     = $schema->resultset('Probe');

# The stored row, as the table itself has it.
sub stored {
  my ($note, $rank) = @{
    $dbh->selectrow_arrayref(q{SELECT note, rank FROM dbio_k122_probe WHERE name = 'foo'})
  };
  return { note => $note, rank => $rank };
}
sub fresh_row {
  $dbh->do('TRUNCATE dbio_k122_probe RESTART IDENTITY');
  $dbh->do(q{INSERT INTO dbio_k122_probe (name, rank, note) VALUES ('foo', 3, 'orig')});
}

my %way = (
  'upsert_async' => sub {
    my ($opts) = @_;
    $rs->upsert_async({ name => 'foo', rank => 4 },
      { conflict_target => ['name'], result => 'void', %$opts })->get;
  },
  'insert_async' => sub {
    my ($opts) = @_;
    my $set = $opts->{update};
    $set = { map { $_ => { -attempted => $_ } } @$set } if ref $set eq 'ARRAY';
    $async->insert_async($source, { name => 'foo', rank => 4 }, {
      on_conflict => {
        target => ['name'], action => 'update', set => $set,
        $opts->{update_where} ? ( where => $opts->{update_where} ) : (),
      },
    })->get;
  },
);

for my $way (sort keys %way) {
  # A statement the server refuses is a failed claim, with the reason, and
  # the file goes on: the same statement before the fix failed with
  # 'invalid input syntax for type integer' on the integer column.
  my $go = sub {
    local $@;
    eval { $way{$way}->(@_); 1 } or diag "$way: $@";
  };

  fresh_row();
  $go->({ update => { note => 'fixed' } });
  is_deeply stored(), { note => 'fixed', rank => 3 },
    "$way: a plain value in the update set is written as that value";

  fresh_row();
  $go->({ update => { note => 'fixed', rank => 9 } });
  is_deeply stored(), { note => 'fixed', rank => 9 },
    "$way: ... also two of them, one an integer";

  fresh_row();
  $go->({ update => { note => 'fixed' }, update_where => { rank => { '<' => 5 } } });
  is_deeply stored(), { note => 'fixed', rank => 3 },
    "$way: ... behind an update_where that holds";

  fresh_row();
  $go->({ update => { note => 'fixed' }, update_where => { rank => { '>' => 5 } } });
  is_deeply stored(), { note => 'orig', rank => 3 },
    "$way: ... and not behind one that does not";

  fresh_row();
  $go->({ update => { note => \"'lit'" } });
  is_deeply stored(), { note => 'lit', rank => 3 },
    "$way: a literal beside it is unchanged";

  fresh_row();
  $go->({ update => { note => { -attempted => 'name' } } });
  is_deeply stored(), { note => 'foo', rank => 3 },
    "$way: ... as is an -attempted value";
}

END {
  if ($dbh) {
    local $@;
    eval { $dbh->do('DROP TABLE IF EXISTS dbio_k122_probe') };
  }
}

$async->disconnect;
done_testing;
