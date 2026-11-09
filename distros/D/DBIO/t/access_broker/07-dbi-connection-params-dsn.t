# ABSTRACT: A hash-shaped broker answer becomes a DSN of the storage's own driver
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k239). DBIO::AccessBroker::Static answers connection
# parameters, not a DSN: { dbname, host, port, user, password }. The sync
# storage turned that into 'dbi:SQLite:dbname=<dbname>' whatever the driver,
# and handed host and port to DBI->connect as DBI attributes -- so a Static
# broker on a PostgreSQL schema connected (or tried to) to a SQLite file named
# after the database, and driver detection read SQLite back out of that DSN.
#
# What this file claims:
#   1. on a storage pinned to a driver (a driver's registered storage class,
#      as the driver component pins it), the DSN names THAT driver and carries
#      dbname, host and port -- and host/port are no DBI attributes;
#   2. driver detection reads the pinned driver back out of that DSN, not
#      SQLite -- the observable half of the bug;
#   3. the reconnect path, which asks the broker again for every connection,
#      builds the same DSN for DBI->connect;
#   4. a HostBound view's host and port land in the DSN; parts the broker
#      leaves empty are left out, never sent as empty or undef;
#   5. a subclass of a driver storage (as a composed storage layer is) still
#      answers its driver;
#   6. a storage pinned to no driver refuses, naming the way out, instead of
#      guessing one; a value that would split the DSN refuses too.
#
# THE SUBSTITUTIONS: a fake driver storage (DBIO::Test::Storage, registered
# for the DBD name 'FakeDBD'); DBI->connect records its arguments and hands
# out a fake handle.

{
  package T::FakeDriver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(FakeDBD => __PACKAGE__);
}

{
  package T::FakeDriver::Storage::Layered;
  use base 'T::FakeDriver::Storage';
}

{
  package T::FakeDBH;
  sub new { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]{$_[1]} }
}

sub static_broker {
  return DBIO::AccessBroker::Static->new(
    host     => 'db.example',
    port     => 5433,
    dbname   => 'appdb',
    username => 'app',
    password => 's3cret',
    @_,
  );
}

# The schema path: storage_type pinned the way a driver component pins it,
# then connection() with the broker.
sub storage_for {
  my ($storage_type, $broker) = @_;
  my $schema = DBIO::Test->init_schema(
    no_connect   => 1,
    storage_type => "+$storage_type",
  );
  return $schema->connection($broker)->storage;
}

my %DEFAULT_ATTRS = (
  AutoCommit         => 1,
  PrintError         => 0,
  RaiseError         => 1,
  ShowErrorStatement => 0,
);

# ---------------------------------------------------------------------------
# 1 + 2. Pinned driver: the DSN is that driver's, host/port are inside it.
# ---------------------------------------------------------------------------
{
  my $storage = storage_for('T::FakeDriver::Storage', static_broker());

  is_deeply $storage->_dbi_connect_info, [
    'dbi:FakeDBD:dbname=appdb;host=db.example;port=5433',
    'app',
    's3cret',
    { %DEFAULT_ATTRS },
  ], "Static broker on a pinned storage: the driver's DSN, host and port inside it, not attributes";

  is $storage->_extract_driver_from_connect_info, 'FakeDBD',
    'driver detection reads the pinned driver back out of the DSN, not SQLite';
}

# ---------------------------------------------------------------------------
# 3. The reconnect path asks the broker again and builds the same DSN.
# ---------------------------------------------------------------------------
{
  my $broker  = static_broker();
  my $storage = storage_for('T::FakeDriver::Storage', $broker);
  $broker->host('db2.example');   # the broker's answer changes between connects

  my @connects;
  {
    no warnings qw(redefine once);
    require DBI;
    local *DBI::connect = sub { shift; push @connects, [@_]; T::FakeDBH->new };
    $storage->_connect;
  }

  is_deeply \@connects, [[
    'dbi:FakeDBD:dbname=appdb;host=db2.example;port=5433',
    'app',
    's3cret',
    { %DEFAULT_ATTRS },
  ]], 'DBI->connect gets the DSN built from the answer fetched at connect time';
}

# ---------------------------------------------------------------------------
# 4. HostBound over Static; absent parts left out.
# ---------------------------------------------------------------------------
{
  my $storage = storage_for('T::FakeDriver::Storage',
    static_broker()->for_host({ host => 'replica.example', port => 6432 }));

  is $storage->_dbi_connect_info->[0],
    'dbi:FakeDBD:dbname=appdb;host=replica.example;port=6432',
    "a HostBound view's host and port go into the DSN";
}

{
  my $storage = storage_for('T::FakeDriver::Storage',
    DBIO::AccessBroker::Static->new(dbname => 'appdb', username => 'app'));

  is_deeply $storage->_dbi_connect_info, [
    'dbi:FakeDBD:dbname=appdb', 'app', '', { %DEFAULT_ATTRS },
  ], 'parts the broker leaves empty are left out of the DSN and out of the attributes';
}

# ---------------------------------------------------------------------------
# 5. A subclass of the driver storage answers the driver it inherits.
# ---------------------------------------------------------------------------
{
  my $storage = storage_for('T::FakeDriver::Storage::Layered', static_broker());

  is $storage->_dbi_connect_info->[0],
    'dbi:FakeDBD:dbname=appdb;host=db.example;port=5433',
    'a subclass of a driver storage builds its DSN for the inherited driver';
}

# ---------------------------------------------------------------------------
# 6. No driver to build for: refuse, never guess.
# ---------------------------------------------------------------------------
throws_ok {
  storage_for('DBIO::Test::Storage', static_broker());
} qr/name no DBI driver, and storage class DBIO::Test::Storage is not registered for any DBD driver.*load_components/s,
  'a storage pinned to no driver refuses the connection parameters, naming the way out';

throws_ok {
  storage_for('T::FakeDriver::Storage', static_broker(dbname => 'app;host=elsewhere'));
} qr/connection parameter 'dbname'.*contains ';'/,
  "a value that would split the DSN into more parts refuses";

done_testing;
