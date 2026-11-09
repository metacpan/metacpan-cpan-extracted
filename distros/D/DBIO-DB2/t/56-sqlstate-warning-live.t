use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k43, ADR 0007), the counterpart of t/55-sqlstate-warning.t.
#
# A DELETE or UPDATE without a WHERE clause makes Db2 answer SQLSTATE 01504,
# SQL0513W "The SQL statement will modify an entire table or view" -- a
# warning: the statement ran and the rows are changed. DBD::DB2 sets err to a
# true value for it, so with RaiseError it died, and through DBIO
# $rs->delete on an unrestricted resultset threw after deleting every row; in
# a txn_do that exception rolled the delete back again.
#
# What an application relies on, and what every block here ends on: the call
# returns, the rows are changed, and inside a txn_do they are still changed
# after the commit -- read back over a second connection. And a real error
# still throws, and still rolls a transaction back.
#
# The update comes twice on purpose. With a bind value (UPDATE "t" SET "v" = ?)
# the server sends no warning; with the value as literal SQL it does. Only the
# second one exercises the fix, the first pins that it stayed as it was.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

my $TABLE = "dbio_k43_$$";

# Inline result class, as in t/11-db2-fk.t and t/12-db2-upgrade.t: the table
# is this file's own, under a name no other test and no other run uses.
{
  package DBIO::Test::Warning::Item;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table($TABLE);
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    v  => { data_type => 'varchar', size => 20, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package DBIO::Test::Warning::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->register_class(Item => 'DBIO::Test::Warning::Item');
}

my $schema  = DBIO::Test::Warning::Schema->connect($dsn, $user, $pass);
my $storage = $schema->storage;
my $dbh     = $storage->dbh;

# a second connection: what it reads is committed
my $other = DBIO::Test::Warning::Schema->connect($dsn, $user, $pass);

$dbh->do(qq{CREATE TABLE "$TABLE" ("id" INTEGER NOT NULL PRIMARY KEY, "v" VARCHAR(20))});

END {
  if ($dbh) {
    local $@;
    eval { local $dbh->{PrintError} = 0; $dbh->do(qq{DROP TABLE "$TABLE"}) };
  }
}

my $rs = $schema->resultset('Item');

# three rows, whatever the block before left behind; with a WHERE, so that
# the setup itself never depends on what is under test
sub refill {
  $rs->search({ id => { '>' => 0 } })->delete;
  $rs->populate([ map { { id => $_, v => "row$_" } } 1 .. 3 ]);
  return;
}

sub values_seen { [ map { $_->v } $_[0]->resultset('Item')->search({}, { order_by => 'id' })->all ] }

# ------------------------------------------------------------ the premise

# On a handle of its own, without RaiseError and without any handler: the
# server sends 01504 and the statement has run all the same. If this stops
# being true the rest of the file proves nothing about the fix.
{
  refill();

  my $raw = DBI->connect($dsn, $user, $pass,
    { AutoCommit => 1, RaiseError => 0, PrintError => 0, PrintWarn => 0 });
  my $rv = $raw->do(qq{DELETE FROM "$TABLE"});

  is $raw->state, '01504',
    'premise: DELETE without WHERE makes the server answer SQLSTATE 01504';
  like $raw->errstr, qr/SQL0513W/, '... SQL0513W';
  is $rv, 3, '... and the statement ran: three rows deleted';
  note 'DBD::DB2 ' . DBD::DB2->VERSION . ' reports err=' . (defined $raw->err ? $raw->err : 'undef');
  $raw->disconnect;
}

# ------------------------------------------------------- $rs->delete

{
  refill();

  my $rv;
  lives_ok { $rv = $rs->delete({ all => 1 }) } '$rs->delete without a condition does not throw';
  is $rv, 3, '... and returns the three rows it deleted';
  is $rs->count, 0, '... the table is empty';
}

# ------------------------------------------------------- $rs->update

{
  refill();

  lives_ok { $rs->update({ v => 'bound' }, { all => 1 }) }
    '$rs->update without a condition, bind value: does not throw (the server '
  . 'sends no warning for this form)';
  is_deeply values_seen($schema), [ ('bound') x 3 ], '... every row is updated';
}

{
  refill();

  my $rv;
  lives_ok { $rv = $rs->update({ v => \"'literal'" }, { all => 1 }) }
    '$rs->update without a condition, literal SQL: does not throw (this is '
  . 'the form the server warns about)';
  is $rv, 3, '... and returns the three rows it updated';
  is_deeply values_seen($schema), [ ('literal') x 3 ], '... every row is updated';
}

# --------------------------------------------------------- inside txn_do

{
  refill();

  lives_ok { $schema->txn_do(sub { $rs->delete({ all => 1 }) }) }
    '$rs->delete without a condition inside txn_do does not throw';
  is $other->resultset('Item')->count, 0,
    '... and it is committed: a second connection sees the empty table';
}

{
  refill();

  lives_ok {
    $schema->txn_do(sub {
      $rs->update({ v => 'bound' }, { all => 1 });
      $rs->update({ v => \"'in txn'" }, { all => 1 });
    });
  } '$rs->update without a condition inside txn_do, bind value and then '
  . 'literal SQL, does not throw';
  is_deeply values_seen($other), [ ('in txn') x 3 ],
    '... and it is committed: a second connection reads the updated rows';
}

# ------------------------------------------------------ raw SQL, dbh_do

{
  refill();

  my ($rv, $state);
  lives_ok {
    $rv = $storage->dbh_do(sub {
      my $done = $_[1]->do(qq{DELETE FROM "$TABLE"});
      $state = $_[1]->state;
      $done;
    });
  } 'a raw DELETE without WHERE through dbh_do does not throw';
  is $rv, 3, '... and do returns the three rows it deleted';
  is $state, '01504',
    '... the warning is not thrown away: the state is on the handle for '
  . 'whoever asks';
  is $rs->count, 0, '... the table is empty';
}

# ------------------------------------------------ a real error still throws

{
  refill();

  throws_ok { $storage->dbh_do(sub { $_[1]->do(qq{DELETE FROM "${TABLE}_nope"}) }) }
    qr/DBI Exception: .*SQL0204N/s,
    'raw SQL on a table that is not there still throws (42S02)';
  isa_ok $@, 'DBIO::Exception', '... the exception';

  throws_ok { $rs->search({ nope => 1 })->delete }
    qr/SQL0206N/,
    'a resultset delete on a column that is not there still throws (42703)';

  # the warned delete and the failing one in one transaction: the error must
  # take the delete back with it
  throws_ok {
    $schema->txn_do(sub {
      $rs->delete({ all => 1 });
      $storage->dbh_do(sub { $_[1]->do(qq{DELETE FROM "${TABLE}_nope"}) });
    });
  } qr/SQL0204N/, 'an error after a warned delete inside txn_do throws';
  is $other->resultset('Item')->count, 3,
    '... and rolls the transaction back: the three rows are still there';
}

done_testing;
