use strict;
use warnings;
use Test::More;

# t/07-transport-dbd-live.t — a real connection over the configured MySQL-wire
# DBD is this driver's own access path, and nothing says otherwise.
#
# t/07-transport-dbd.t settles the same question offline, from the DBD name in
# the DSN. This file is the part only a server can answer, because it is where
# the defect was found (karr k35): since core ADR 0059, driver determination
# holds the DBD of the connection against core's driver registry, where
# DBD::mysql and DBD::MariaDB are registered for the MySQL storages. The
# ClickHouse storage inherits neither (ADR 0002), so a live run produced a
# "Driver mismatch" warning from every connection it opened -- sixteen of them
# across nine files -- and stayed green, because no file counted warnings.
#
# This one does. It also asks the question a warning count cannot: a schema
# with driver_strict(1) turns that report into an exception, so before the fix
# the strictest schema was the one that could not reach ClickHouse at all.
#
# Whichever DBD the DSN names is the one under test (DBD::mysql is the
# transport of record, ADR 0001); the file makes no assumption about it beyond
# being one of the two.

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;

{
  # driver_strict is inherited class data: it goes on a class of this file's
  # own, never on the shared fixture schema.
  package MyTest::TransportLive::StrictSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('ClickHouse');
  __PACKAGE__->driver_strict(1);
}

# Collected for the whole file, from before the first connection: the report
# comes out of driver determination, which runs at the first real use of a
# storage -- inside init_schema's deploy, not at a line of this file.
my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $schema = DBIO::ClickHouse::Test->init_schema;

my $dbd = $schema->storage->dbh->{Driver}{Name};
diag "transport under test: DBD::$dbd";

like $dbd, qr/\A(?:mysql|MariaDB)\z/,
  'the configured DSN leads through one of the two MySQL-wire DBDs';

is ref($schema->storage), 'DBIO::ClickHouse::Storage',
  'the declared storage is what drives the live connection';

is $schema->resultset('Hit')->count, 6,
  'a real query over that connection answers';

# A second connection, strict. The first one having been accepted proves
# nothing about this: the default only warns.
{
  my $strict = MyTest::TransportLive::StrictSchema->connect(
    DBIO::ClickHouse::Test->test_connect_info,
  );

  my $one = eval {
    $strict->storage->dbh_do(sub { $_[1]->selectrow_array('SELECT 1') });
  };

  is $@, '', 'a driver_strict(1) schema connects over the same DSN';
  is $one, 1, '... and its query answers';

  $strict->storage->disconnect;
}

is_deeply [ grep { /Driver mismatch/ } @warnings ], [],
  "no connection reported DBD::$dbd as another driver's DBD";

# Anything else that warned is not this file's claim, but it must not vanish
# into the collector either.
diag "warning during the run: $_" for grep { !/Driver mismatch/ } @warnings;

done_testing;
