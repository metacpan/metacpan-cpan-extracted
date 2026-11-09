use strict;
use warnings;
use Test::More;

# LIVE (karr k49): a DDL statement the server refuses at its commit must come
# back as that error -- not as success, and not by way of a silent reconnect.
#
# DBD::Firebird commits after DDL, and the server can refuse the DDL only then:
# DROP TABLE of a table a live statement still holds is `object TABLE "..." is
# in use`. The DBD does not roll the failed commit back. The transaction stays
# in that state and EVERY later statement on the handle fails with the same
# error -- `select 1 from rdb$database` included. core's dbh_do decides about a
# retry with `! $storage->connected`, which is `_ping`, which ran exactly that
# select: the connection read as dead, was replaced, and the block (the DROP)
# ran again on the new connection, where nothing holds the table -- the DDL
# reported success, the session's state (context variables, on_connect actions
# applied once more) was gone, a transaction would have gone with it.
#
# What this file claims, on a storage connection brought into that state:
#   1. dbh_do dies with the server's error, running the block ONCE;
#   2. the handle is the same afterwards, on_connect_do did not run again and a
#      session context variable is still set;
#   3. the table is still there (the refused DDL was not "repeated");
#   4. the connection is usable at once, without any reconnect;
#   5. once nothing holds the table, the same DROP through dbh_do succeeds.
#
# How the state is reached (DBD::Firebird 1.39, see maint/upstream): a handle
# the DBD has destroyed and Perl frees later empties the DBD's list of
# statements; a statement prepared since is then alive, holds its table, and
# the DBD does not destroy it before a DDL commit. The storage's own cache is
# kept clean of that (ADR 0011); a statement held outside it is not.
#
# Skipped unless DBIO_TEST_FIREBIRD_DSN / _USER / _PASS are set.
#
# Run once per mode: default and on_connect_call => 'use_softcommit'.
#
# WARNING: creates and drops the tables "k49_t" and "k49_o".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live failed-DDL tests'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

{
  package DBIO::Firebird::Test::K49Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Firebird');
}

my $other = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1, ib_dialect => 3,
}) or plan skip_all => 'Cannot connect: ' . DBI->errstr;
$other->func(-lock_resolution => { wait => 10 }, 'ib_set_tx_param');

my $drop_all = sub { eval { $other->do("DROP TABLE $_") } for qw( k49_t k49_o ) };
$drop_all->();

# The same claims with ib_softcommit on: the rollback _ping takes then runs
# through isc_rollback_retaining (dbdimp.c 1.39) and the transaction of the
# failed commit might stay set; whether the ping still tells a refused commit
# from a dead connection is measured here, not assumed.
for my $mode (
  [ 'default'    => {} ],
  [ 'softcommit' => { on_connect_call => 'use_softcommit' } ],
) {
  my ($name, $connect_attrs) = @$mode;
  subtest "failed DDL commit, $name" => sub {
  my $on_connect = 0;
  my $schema = DBIO::Firebird::Test::K49Schema->connect($dsn, $user, $pass, {
    on_connect_do => sub { $on_connect++ },
    %$connect_attrs,
  });
  my $storage = $schema->storage;
  my $dbh     = $storage->dbh;
  is($on_connect, 1, 'on_connect_do ran once for the first connection');

  $dbh->do('CREATE TABLE k49_t (id INTEGER)');
  $dbh->do('INSERT INTO k49_t VALUES (1)');

  # A statement the DBD has destroyed (the DDL commit below), freed AFTER another
  # one was prepared: the second one is alive and off the DBD's list.
  my $first = $dbh->prepare('SELECT id FROM k49_t');
  $dbh->do('CREATE TABLE k49_o (id INTEGER)');
  my $holder = $dbh->prepare('SELECT id FROM k49_t');
  $holder->execute;
  $holder->fetchrow_arrayref;
  undef $first;
  $dbh->do('ALTER TABLE k49_o ADD x INTEGER');

  $dbh->selectrow_array(q{select rdb$set_context('USER_SESSION', 'k49', 'kept') from rdb$database});

  my $sql      = 'DROP TABLE k49_t';
  my $attempts = 0;
  my @handles;
  my $ok = eval {
    $storage->dbh_do(sub {
      $attempts++;
      push @handles, $_[1];
      $_[1]->do($sql);
    });
    1;
  };
  my $err = $@;

  ok(!$ok, 'DROP TABLE of a table a live statement holds is refused through dbh_do')
    or diag 'it reported success';
  like("$err", qr/is in use/, '... with the server\'s own error');
  is($attempts, 1, '1. the block ran once, not again on a new connection');
  is($storage->_dbh, $dbh, '2. the handle is the same one afterwards');
  is($on_connect, 1, '... on_connect_do did not run again');

  my ($ctx) = eval { $storage->_dbh->selectrow_array(
    q{select rdb$get_context('USER_SESSION', 'k49') from rdb$database}) };
  is($ctx, 'kept', '... and the session context variable is still set');

  my ($exists) = $other->selectrow_array(
    q{select count(*) from rdb$relations where rdb$relation_name = 'K49_T'});
  is($exists, 1, '3. the table is still there');

  ok(eval { $storage->dbh_do(sub { $_[1]->do('select 1 from rdb$database') }); 1 },
    '4. the connection answers the next statement') or diag $@;
  is($storage->_dbh, $dbh, '... on the same handle');

  undef $holder;
  ok(eval { $storage->dbh_do(sub { $_[1]->do($sql) }); 1 },
    '5. with nothing holding the table, the same DROP goes through') or diag $@;
  ($exists) = $other->selectrow_array(
    q{select count(*) from rdb$relations where rdb$relation_name = 'K49_T'});
  is($exists, 0, '... and the table is gone');


    $storage->disconnect;
    $drop_all->();
  };
}

$other->disconnect;
done_testing;
