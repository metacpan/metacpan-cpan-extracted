use strict;
use warnings;
use Test::More;

# LIVE (karr k60): the raw fact of DBD::Firebird 1.39 that makes install_ddl
# refuse a NUMERIC / DECIMAL of more than 18 digits (case bind-numeric-exact).
#
# WHY: the server (Firebird 4 and later) stores such a column as an INT128,
# but the DBD does not know the type: a value cannot be bound to the column
# as written and a value read does not come back as the number written. A
# column the ORM can neither write nor read is not built (DBIO::Firebird::DDL
# refuses it on every server, t/96). The table here is written by hand, and
# the ORM is used the way a user's code would.
#
# Red when a DBD release learns the type: then the refusal can go and the
# bind-numeric-exact case runs through.
#
# Skipped below Firebird 4. WARNING: creates and drops the table "k60_i128".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live INT128 test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

{
  package K60I128::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('Firebird');

  package K60I128::Schema::Result::Num;
  use DBIO 'Core';
  __PACKAGE__->table('k60_i128');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    v  => { data_type => 'numeric', size => [ 20, 4 ], is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package main;
  K60I128::Schema->register_class(Num => 'K60I128::Schema::Result::Num');
}

$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^non-transactional DDL on |problem parsing SQL_/ };

my $schema = K60I128::Schema->connect($dsn, $user, $pass,
  { quote_names => 1, on_connect_call => 'use_softcommit' });
my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach Firebird server: $@";

my ($ver) = $dbh->selectrow_array(
  q{SELECT rdb$get_context('SYSTEM','ENGINE_VERSION') FROM rdb$database});
plan skip_all => "INT128 needs Firebird 4 (server is $ver)" if ($ver =~ /^(\d+)/)[0] < 4;

sub cleanup { eval { $schema->storage->dbh->do('DROP TABLE "k60_i128"') } }
cleanup();

$dbh->do('CREATE TABLE "k60_i128" ("id" INTEGER NOT NULL PRIMARY KEY, "v" NUMERIC(20,4))');
$dbh->do(q{INSERT INTO "k60_i128" ("id", "v") VALUES (1, 1234567890123456.7890)});

my $rs   = $schema->resultset('Num');
my $want = '1234567890123456.7890';

# write: the value lands as written, or the bind fails
my $created = eval { $rs->create({ id => 2, v => $want }); 1 };
my $written = $created
  ? eval { ($dbh->selectrow_array(q{SELECT CAST("v" AS VARCHAR(40)) FROM "k60_i128" WHERE "id" = 2}))[0] }
  : undef;
ok !$created || !defined $written || $written ne $want,
  'a NUMERIC(20,4) value is not bound as written (the DBD cannot bind an INT128)'
  or diag 'written: ' . ($written // 'undef');

# read: the value the server holds
my $read = eval { $rs->find(1)->v };
ok !defined $read || $read ne $want,
  'a NUMERIC(20,4) value is not read back as written (the DBD cannot read an INT128)'
  or diag 'read: ' . ($read // 'undef');

# the value is there; only the DBD cannot hand it over
my ($text) = $dbh->selectrow_array(q{SELECT CAST("v" AS VARCHAR(40)) FROM "k60_i128" WHERE "id" = 1});
is $text, $want, 'the server holds the value (read through a CAST)';

cleanup();
$schema->storage->disconnect;
done_testing;
