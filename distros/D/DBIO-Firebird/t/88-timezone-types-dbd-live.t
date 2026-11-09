use strict;
use warnings;
use Test::More;

# LIVE (karr k55): the raw facts of DBD::Firebird 1.39 that make install_ddl
# refuse TIMESTAMP WITH TIME ZONE and TIME WITH TIME ZONE (timestamptz,
# 'timestamp with time zone', 'time with time zone').
#
# WHY: the server (Firebird 4 and later) has the types, but the DBD does not
# know SQL_TIMESTAMP_TZ / SQL_TIME_TZ (dbdimp.c prints "** unknown **" for the
# type): a value cannot be bound to such a column, and a value read comes
# back as the text "** unknown **". A column the ORM can neither write nor
# read is not built (DBIO::Firebird::DDL refuses it, t/81). The table here is
# written by hand, and the ORM is used the way a user's code would.
#
# Red when a DBD release learns the types: then the refusal can go and
# t/84 gets the value round trip back.
#
# Skipped below Firebird 4. WARNING: creates and drops the table "k55_tz".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live time zone test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

{
  package K55Tz::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('Firebird');

  package K55Tz::Schema::Result::Tz;
  use DBIO 'Core';
  __PACKAGE__->table('k55_tz');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    ts => { data_type => 'timestamp with time zone', is_nullable => 1 },
    tm => { data_type => 'time with time zone', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package main;
  K55Tz::Schema->register_class(Tz => 'K55Tz::Schema::Result::Tz');
}

$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^non-transactional DDL on |problem parsing SQL_/ };

my $schema = K55Tz::Schema->connect($dsn, $user, $pass,
  { quote_names => 1, on_connect_call => 'use_softcommit' });
my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach Firebird server: $@";

my ($ver) = $dbh->selectrow_array(
  q{SELECT rdb$get_context('SYSTEM','ENGINE_VERSION') FROM rdb$database});
plan skip_all => "time zone types need Firebird 4 (server is $ver)" if ($ver =~ /^(\d+)/)[0] < 4;

sub cleanup { eval { $schema->storage->dbh->do('DROP TABLE "k55_tz"') } }
cleanup();

$dbh->do('CREATE TABLE "k55_tz" ("id" INTEGER NOT NULL PRIMARY KEY, '
       . '"ts" TIMESTAMP WITH TIME ZONE, "tm" TIME WITH TIME ZONE)');
$dbh->do(q{INSERT INTO "k55_tz" ("id", "ts", "tm") VALUES (1, '2026-10-19 04:43:18.0000 Europe/Berlin', '04:43:18 +02:00')});

my $rs = $schema->resultset('Tz');

# write: a value bound for the column
for my $v ('2026-10-19 04:43:18 Europe/Berlin', '2026-10-19 04:43:18 +02:00') {
  my $ok = eval { $rs->create({ id => 2, ts => $v }); 1 };
  ok !$ok, "create with ts => '$v' fails (the DBD cannot bind the type)";
  like "$@", qr/SQLDA|input parameters/, '... with the DBD\'s parameter error';
}
ok eval { $rs->create({ id => 3 }); 1 }, 'a row without the column is written';

# read: a value the server holds
my $row = $rs->find(1);
is $row->ts, '** unknown **', 'TIMESTAMP WITH TIME ZONE reads back as "** unknown **", not the value';
is $row->tm, '** unknown **', 'TIME WITH TIME ZONE reads back as "** unknown **", not the value';

# the value is there; only the DBD cannot hand it over
my ($text) = $dbh->selectrow_array(q{SELECT CAST("ts" AS VARCHAR(60)) FROM "k55_tz" WHERE "id" = 1});
like $text, qr/\A2026-10-19 04:43:18/, 'the server holds the value (read through a CAST)';

cleanup();
$schema->storage->disconnect;
done_testing;
