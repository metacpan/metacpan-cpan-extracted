use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k120: reading a model leaves the caller's session as it
# was -- its search_path, and its transaction.
#
# WHY it exists: the view definitions of a model are read under an empty
# search_path (karr k100), in the session of whoever asks -- Deploy->diff on
# the connection of the application, DBIO::Generate on the one it was given.
# That session is not the reader's to change. It used to set the search_path
# and set it back with a statement of its own, and so
#
#  * a SET LOCAL search_path of the caller's -- the search_path of one
#    transaction, a tenant's -- had become the search_path of the SESSION by
#    the time the transaction was committed: every later transaction on that
#    connection ran under it;
#  * after a read that failed inside a transaction there was nothing to set
#    back with, the transaction being aborted.
#
# Asked the way it matters: whatever state the caller's session is in -- no
# transaction, one begun through DBI, one begun with a BEGIN of its own,
# AutoCommit off -- afterwards the search_path is what it was, the transaction
# is open with everything it did, and it ends the way the caller ends it. Also
# when the read dies half way.
#
# Everything happens in a database of this file's own (karr k81).

my %ATTR = (RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1);
my @db = PrivatePgDatabase->create('t103leaves');

sub handle {
  my $dbh = LiveServer->control_dbh(login => \@db, attrs => { %ATTR, @_ });
  $dbh->do('SET client_min_messages = warning');
  $dbh->commit unless $dbh->{AutoCommit};
  return $dbh;
}
sub path { ($_[0]->selectrow_array(q{SELECT pg_catalog.current_setting('search_path')}))[0] }
sub has_mine { $_[0]->selectrow_array(q{SELECT pg_catalog.to_regclass('app.t103_mine') IS NOT NULL}) ? 1 : 0 }

# The model of $dbh. With $dies_in, the first query of the run that calls
# that function fails on the server: pg_get_viewdef is the query under the
# empty search_path, pg_get_triggerdef one that comes after it.
sub read_model {
  my ($dbh, $dies_in) = @_;
  my $fail = sub { $_[1] = 'SELECT 1/0' if $_[1] =~ /\Q$dies_in\E/; return };
  local $dbh->{Callbacks} = { selectall_arrayref => $fail, prepare => $fail }
    if $dies_in;
  return DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
}

my $START;
{
  my $dbh = handle();
  note 'server ' . $dbh->selectrow_array('SHOW server_version');
  $START = path($dbh);
  $dbh->do('CREATE SCHEMA app');
  $dbh->do('CREATE TABLE app.t (id integer)');
  $dbh->do('CREATE VIEW app.v AS SELECT id FROM app.t');
  $dbh->do(q{CREATE FUNCTION app.touch() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RETURN NEW; END $$});
  $dbh->do('CREATE TRIGGER t_touch BEFORE UPDATE ON app.t FOR EACH ROW EXECUTE FUNCTION app.touch()');
  $dbh->disconnect;
}
isnt($START, 'app', 'a new session does not start with the search_path the cases set');

# What the empty search_path is for, so that leaving the session alone is not
# bought by not setting it: "app" is on the search_path of the asking session,
# and the definition names app.t with its schema all the same.
sub names_its_schema {
  my ($label, $model) = @_;
  like($model->{tables}{'app.v'}{view_definition}, qr/\bFROM app\.t\b/,
    "$label: the view definition is read under the empty search_path");
}

# ---------------------------------------------------------------------------
# 1. The model is read
# ---------------------------------------------------------------------------
{
  my $dbh = handle();
  $dbh->do('SET search_path TO app');
  names_its_schema('no transaction', read_model($dbh));
  is(path($dbh), 'app', 'no transaction: the session keeps its search_path');
  ok($dbh->{AutoCommit}, 'no transaction: AutoCommit is on as before');
  is($dbh->ping, 1, 'no transaction: and the server is in none');
  $dbh->disconnect;
}

{
  # SET LOCAL lasts as long as its transaction. Reading the model inside
  # that transaction must not make it the search_path of the session.
  my $dbh = handle();
  $dbh->begin_work;
  $dbh->do('SET LOCAL search_path TO app');
  $dbh->do('CREATE TABLE app.t103_mine (id integer)');
  names_its_schema('a transaction with SET LOCAL', read_model($dbh));
  is(path($dbh), 'app', 'a transaction with SET LOCAL: the search_path stands');
  ok(has_mine($dbh), 'a transaction with SET LOCAL: what the transaction did is there');
  lives_ok { $dbh->commit } 'a transaction with SET LOCAL: it commits';
  is(path($dbh), $START, 'a transaction with SET LOCAL: after COMMIT the search_path is the session\'s again');
  ok(has_mine($dbh), 'a transaction with SET LOCAL: and the transaction was committed whole');
  $dbh->do('DROP TABLE IF EXISTS app.t103_mine');
  $dbh->disconnect;
}

{
  my $dbh = handle();
  $dbh->begin_work;
  $dbh->do('SET LOCAL search_path TO app');
  $dbh->do('CREATE TABLE app.t103_mine (id integer)');
  read_model($dbh);
  $dbh->rollback;
  is(path($dbh), $START, 'a transaction that is rolled back: the search_path is the session\'s again');
  ok(!has_mine($dbh), 'a transaction that is rolled back: and nothing of it is left');
  $dbh->disconnect;
}

{
  # A transaction DBI knows nothing of: BEGIN sent as a statement.
  my $dbh = handle();
  $dbh->do('BEGIN');
  $dbh->do('SET LOCAL search_path TO app');
  $dbh->do('CREATE TABLE app.t103_mine (id integer)');
  names_its_schema('behind a BEGIN of the caller\'s', read_model($dbh));
  is($dbh->ping, 3, 'behind a BEGIN of the caller\'s: the transaction is still open');
  is(path($dbh), 'app', 'behind a BEGIN of the caller\'s: the search_path stands');
  ok(has_mine($dbh), 'behind a BEGIN of the caller\'s: what the transaction did is there');
  $dbh->do('COMMIT');
  is(path($dbh), $START, 'behind a BEGIN of the caller\'s: after COMMIT the search_path is the session\'s again');
  ok(has_mine($dbh), 'behind a BEGIN of the caller\'s: and the transaction was committed whole');
  $dbh->do('DROP TABLE IF EXISTS app.t103_mine');

  $dbh->do('BEGIN');
  $dbh->do('CREATE TABLE app.t103_mine (id integer)');
  read_model($dbh);
  ok(has_mine($dbh), 'behind a BEGIN of the caller\'s: the transaction is the caller\'s to end');
  $dbh->do('ROLLBACK');
  ok(!has_mine($dbh), 'behind a BEGIN of the caller\'s: and ROLLBACK takes what it did');
  $dbh->disconnect;
}

{
  my $dbh = handle(AutoCommit => 0);
  $dbh->do('SET search_path TO app');
  $dbh->commit;
  $dbh->do('CREATE TABLE app.t103_mine (id integer)');
  names_its_schema('AutoCommit off', read_model($dbh));
  is(path($dbh), 'app', 'AutoCommit off: the session keeps its search_path');
  ok(has_mine($dbh), 'AutoCommit off: what the transaction did is there');
  $dbh->rollback;
  ok(!has_mine($dbh), 'AutoCommit off: and it is the caller\'s to roll back');
  is(path($dbh), 'app', 'AutoCommit off: the search_path as it was after that');
  $dbh->rollback;
  $dbh->disconnect;
}

# ---------------------------------------------------------------------------
# 2. The query under the empty search_path dies
# ---------------------------------------------------------------------------
{
  my $dbh = handle();
  $dbh->do('SET search_path TO app');
  throws_ok { read_model($dbh, 'pg_get_viewdef') } qr/division by zero/,
    'the read dies, no transaction: its error is the one reported';
  is(path($dbh), 'app', 'the read dies, no transaction: the session keeps its search_path');
  ok($dbh->{AutoCommit}, 'the read dies, no transaction: AutoCommit is on as before');
  is($dbh->ping, 1, 'the read dies, no transaction: and the server is in none');
  $dbh->disconnect;
}

{
  # The search_path is back without a statement that has to run behind the
  # failed one: the transaction goes on.
  my $dbh = handle();
  $dbh->begin_work;
  $dbh->do('SET LOCAL search_path TO app');
  $dbh->do('CREATE TABLE app.t103_mine (id integer)');
  throws_ok { read_model($dbh, 'pg_get_viewdef') } qr/division by zero/,
    'the read dies, in a transaction: its error is the one reported';
  is(eval { path($dbh) }, 'app', 'the read dies, in a transaction: the search_path stands')
    or diag $@;
  ok(eval { has_mine($dbh) }, 'the read dies, in a transaction: what the transaction did is there')
    or diag $@;
  lives_ok { $dbh->commit } 'the read dies, in a transaction: it commits';
  is(path($dbh), $START, 'the read dies, in a transaction: after COMMIT the search_path is the session\'s again');
  ok(has_mine($dbh), 'the read dies, in a transaction: and the transaction was committed whole');
  $dbh->do('DROP TABLE IF EXISTS app.t103_mine');
  $dbh->disconnect;
}

{
  my $dbh = handle();
  $dbh->do('BEGIN');
  $dbh->do('CREATE TABLE app.t103_mine (id integer)');
  throws_ok { read_model($dbh, 'pg_get_viewdef') } qr/division by zero/,
    'the read dies, behind a BEGIN of the caller\'s: its error is the one reported';
  is($dbh->ping, 3, 'the read dies, behind a BEGIN of the caller\'s: the transaction is still open, and not failed');
  ok(eval { has_mine($dbh) }, 'the read dies, behind a BEGIN of the caller\'s: what the transaction did is there')
    or diag $@;
  $dbh->do('ROLLBACK');
  is(path($dbh), $START, 'the read dies, behind a BEGIN of the caller\'s: the search_path as it was');
  $dbh->disconnect;
}

{
  my $dbh = handle(AutoCommit => 0);
  $dbh->do('SET search_path TO app');
  $dbh->commit;
  $dbh->do('CREATE TABLE app.t103_mine (id integer)');
  throws_ok { read_model($dbh, 'pg_get_viewdef') } qr/division by zero/,
    'the read dies, AutoCommit off: its error is the one reported';
  is(eval { path($dbh) }, 'app', 'the read dies, AutoCommit off: the session keeps its search_path')
    or diag $@;
  ok(eval { has_mine($dbh) }, 'the read dies, AutoCommit off: what the transaction did is there')
    or diag $@;
  $dbh->rollback;
  is(path($dbh), 'app', 'the read dies, AutoCommit off: the search_path as it was after ROLLBACK');
  $dbh->rollback;
  $dbh->disconnect;
}

# ---------------------------------------------------------------------------
# 3. A later query of the run dies
# ---------------------------------------------------------------------------
# No search_path is set for it. Inside a transaction it fails the
# transaction, as any statement of the caller's would; what is asked here is
# that the session is the caller's own again once that is dealt with.
{
  my $dbh = handle();
  $dbh->do('SET search_path TO app');
  throws_ok { read_model($dbh, 'pg_get_triggerdef') } qr/division by zero/,
    'a later query dies, no transaction: its error is the one reported';
  is(path($dbh), 'app', 'a later query dies, no transaction: the session keeps its search_path');
  is($dbh->ping, 1, 'a later query dies, no transaction: and is in no transaction');
  $dbh->disconnect;
}

{
  my $dbh = handle();
  $dbh->begin_work;
  $dbh->do('SET LOCAL search_path TO app');
  throws_ok { read_model($dbh, 'pg_get_triggerdef') } qr/division by zero/,
    'a later query dies, in a transaction: its error is the one reported';
  $dbh->rollback;
  is(path($dbh), $START, 'a later query dies, in a transaction: after ROLLBACK the search_path is the session\'s');
  $dbh->disconnect;
}

done_testing;
