use strict;
use warnings;

use Test::More;

use DBIO::Optional::Dependencies ();

use DBIO::SQLite::Test;

# The driver each run declares: DBIO::Test::Schema keeps none in its class,
# and a schema always has one (core ADR 0067).
my %storage_type = (
  PG     => 'DBIO::PostgreSQL::Storage',
  MYSQL  => 'DBIO::MySQL::Storage',
  SQLite => 'DBIO::SQLite::Storage',
);

for my $type (qw/PG MYSQL SQLite/) {

  SKIP: {
    my @dsn = $type eq 'SQLite'
      ? DBIO::SQLite::Test->_database(sqlite_use_file => 1)
      : do {
        skip "Skipping $type tests without DBIO_TEST_${type}_DSN", 1
          unless $ENV{"DBIO_TEST_${type}_DSN"};
        @ENV{map { "DBIO_TEST_${type}_${_}" } qw/DSN USER PASS/}
      }
    ;

    if ($type eq 'PG') {
      skip "skipping Pg tests without dependencies installed", 1
        unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_pg');
    }
    elsif ($type eq 'MYSQL') {
      skip "skipping MySQL tests without dependencies installed", 1
        unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mysql');
    }

    my $schema = DBIO::Test::Schema->clone;
    $schema->storage_type($storage_type{$type});
    $schema = $schema->connect (@dsn);

    # emulate a singleton-factory, just cache the object *somewhere in a different package*
    # to induce out-of-order destruction
    $DBIO::Test::FakeSchemaFactory::schema = $schema;

    # so we can see the retry exceptions (if any)
    $ENV{DBIO_DBIRETRY_DEBUG} = 1;

    ok (!$schema->storage->connected, "$type: start disconnected");

    $schema->txn_do (sub {

      ok ($schema->storage->connected, "$type: transaction starts connected");

      my $pid = fork();
      SKIP: {
        skip "Fork failed: $!", 1 if (! defined $pid);

        if ($pid) {
          note "Parent $$ sleeping...";
          wait();
          note "Parent $$ woken up after child $pid exit";
        }
        else {
          note "Child $$ terminating";
          undef $DBIO::Test::FakeSchemaFactory::schema;
          exit 0;
        }

        ok ($schema->storage->connected, "$type: parent still connected (in txn_do)");
      }
    });

    ok ($schema->storage->connected, "$type: parent still connected (outside of txn_do)");

    undef $DBIO::Test::FakeSchemaFactory::schema;
  }
}

done_testing;
