# ABSTRACT: The DSN of connection parameters is a per-driver form seam
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Storage::DBI;
use DBIO::Storage::DBI::ODBC;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k242, ADR 0057). Connection parameters without a DSN --
# { dbname, host, port }, as DBIO::AccessBroker::Static answers them -- become
# a DSN for the driver the storage is registered for (k239). The form was
# fixed: dbi:<DBD>:dbname=..;host=..;port=... DBD::Oracle, DBD::DB2,
# DBD::Sybase and DBD::ODBC do not take that form, and the MSSQL driver
# registers a name no DBD carries -- so each got a DSN its DBD refuses. The
# form is now the storage's own seam, _connect_params_dsn; core keeps
# everything around it.
#
# What this file claims:
#   1. the seam is asked with the DBD name the storage is registered for and
#      the parts given -- dbname, host, port, the empty ones left out -- and
#      what it returns is the DSN, at connect_info and at every reconnect;
#   2. whatever a driver's seam builds, dbname, host and port never reach
#      DBI->connect as attributes: that stays core's;
#   3. the seam is no way around the driver: a storage registered for no DBD
#      still refuses, even one that overrides the seam, and a value that would
#      split a DSN refuses before the seam is asked;
#   4. the default seam builds dbi:<DBD>:dbname=..;host=..;port=.. -- in that
#      order, only what it is given;
#   5. core's ODBC storage refuses connection parameters, naming why and the
#      ways out: DBD::ODBC needs a data source name or an ODBC driver name,
#      and connection parameters carry neither;
#   6. a dbname that is a whole DSN is taken as the DSN -- the ODBC way out --
#      and host and port, which cannot go into it, never become DBI attributes:
#      absent ones are dropped, given ones refuse (a HostBound view's host
#      would be lost).
#
# THE SUBSTITUTIONS: fake driver storages (DBIO::Test::Storage) registered for
# the DBD names 'FakeOra' and 'FakeDBD'; DBI->connect records its arguments.

# A driver whose DBD takes another form: an Easy-Connect-like one.
{
  package T::FakeOra::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(FakeOra => __PACKAGE__);

  our @ASKED;
  sub _connect_params_dsn {
    my ($self, $driver, $params) = @_;
    push @ASKED, [ $driver, { %$params } ];
    return "dbi:$driver://" . ($params->{host} // '')
      . (defined $params->{port} ? ":$params->{port}" : '') . "/$params->{dbname}";
  }
}

# A driver with the default form.
{
  package T::FakeDriver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(FakeDBD => __PACKAGE__);
}

# Overrides the seam but is registered for no DBD.
{
  package T::Unregistered::Storage;
  use base 'DBIO::Test::Storage';
  sub _connect_params_dsn { 'dbi:Anything:' }
}

{
  package T::FakeDBH;
  sub new { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]{$_[1]} }
}

sub static_broker {
  return DBIO::AccessBroker::Static->new(
    host     => 'db.example',
    port     => 1522,
    dbname   => 'ORCLPDB',
    username => 'app',
    password => 's3cret',
    @_,
  );
}

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
# 1 + 2. The driver's seam builds the DSN; the parts stay out of the attributes.
# ---------------------------------------------------------------------------
{
  local @T::FakeOra::Storage::ASKED;
  my $broker  = static_broker();
  my $storage = storage_for('T::FakeOra::Storage', $broker);

  is_deeply \@T::FakeOra::Storage::ASKED,
    [ [ 'FakeOra', { dbname => 'ORCLPDB', host => 'db.example', port => 1522 } ] ],
    "the seam is asked with the storage's DBD name and the parts";
  is_deeply $storage->_dbi_connect_info, [
    'dbi:FakeOra://db.example:1522/ORCLPDB', 'app', 's3cret', { %DEFAULT_ATTRS },
  ], "its answer is the DSN; dbname, host and port are no DBI attributes";

  $broker->host('db2.example');
  my @connects;
  {
    no warnings qw(redefine once);
    local *DBI::connect = sub { shift; push @connects, [@_]; T::FakeDBH->new };
    $storage->_connect;
  }
  is_deeply \@connects, [[
    'dbi:FakeOra://db2.example:1522/ORCLPDB', 'app', 's3cret', { %DEFAULT_ATTRS },
  ]], 'a reconnect asks the broker again and the seam builds the DSN again';
}

{
  local @T::FakeOra::Storage::ASKED;
  storage_for('T::FakeOra::Storage',
    DBIO::AccessBroker::Static->new(dbname => 'ORCLPDB', host => '', username => 'app'));
  is_deeply \@T::FakeOra::Storage::ASKED, [ [ 'FakeOra', { dbname => 'ORCLPDB' } ] ],
    'parts the broker leaves empty or undefined are not handed to the seam';
}

# ---------------------------------------------------------------------------
# 3. No way around the driver; the split guard comes first.
# ---------------------------------------------------------------------------
throws_ok {
  storage_for('T::Unregistered::Storage', static_broker());
} qr/name no DBI driver, and storage class T::Unregistered::Storage is not registered for any DBD driver/,
  'a storage registered for no DBD refuses, even with a seam of its own';

{
  local @T::FakeOra::Storage::ASKED;
  throws_ok {
    storage_for('T::FakeOra::Storage', static_broker(host => 'h;dbname=other'));
  } qr/connection parameter 'host'.*contains ';'/,
    "a value that would split the DSN refuses";
  is scalar @T::FakeOra::Storage::ASKED, 0, '... before the seam is asked';
}

# ---------------------------------------------------------------------------
# 4. The default form.
# ---------------------------------------------------------------------------
is(DBIO::Storage::DBI->_connect_params_dsn('Pg', { port => 5433, host => 'h', dbname => 'app' }),
  'dbi:Pg:dbname=app;host=h;port=5433',
  'the default seam: dbname, host, port, in that order');
is(DBIO::Storage::DBI->_connect_params_dsn('Pg', { host => 'h' }), 'dbi:Pg:host=h',
  '... only what it is given');
is storage_for('T::FakeDriver::Storage', static_broker())->_dbi_connect_info->[0],
  'dbi:FakeDBD:dbname=ORCLPDB;host=db.example;port=1522',
  'a driver that keeps the default gets it';

# ---------------------------------------------------------------------------
# 5. Core's ODBC storage refuses connection parameters.
# ---------------------------------------------------------------------------
{
  my $storage = DBIO::Storage::DBI::ODBC->new(undef);
  throws_ok { $storage->connect_info([ static_broker() ]) }
    qr/Cannot build a DBD::ODBC DSN from connection parameters.*DSN=.*Driver=/s,
    'ODBC refuses connection parameters, naming what DBD::ODBC needs';
  like "$@", qr/dbi:ODBC:/, '... and the way out: the whole DSN';
  unlike "$@", qr/s3cret/, '... naming no password';
}

# ---------------------------------------------------------------------------
# 6. A dbname that is a whole DSN.
# ---------------------------------------------------------------------------
{
  my $storage = DBIO::Storage::DBI::ODBC->new(undef);
  $storage->connect_info([ DBIO::AccessBroker::Static->new(
    dbname => 'dbi:ODBC:DSN=appdsn', username => 'app', password => 's3cret',
  ) ]);
  is_deeply $storage->_dbi_connect_info, [
    'dbi:ODBC:DSN=appdsn', 'app', 's3cret', { %DEFAULT_ATTRS },
  ], 'a whole DSN as dbname connects ODBC; the absent host and port are no DBI attributes';
}

for my $given ([ host => 'replica.example' ], [ port => 1433 ]) {
  my ($key) = @$given;
  my $storage = DBIO::Storage::DBI::ODBC->new(undef);
  throws_ok {
    $storage->connect_info([ DBIO::AccessBroker::Static->new(
      dbname => 'dbi:ODBC:DSN=appdsn', @$given, username => 'app',
    ) ]);
  } qr/'$key'.*beside a dbname that is a whole DSN/,
    "a whole DSN as dbname with $key beside it refuses, instead of losing $key";
}

{
  my $storage = DBIO::Storage::DBI::ODBC->new(undef);
  throws_ok {
    $storage->connect_info([ DBIO::AccessBroker::Static->new(
      dbname => 'dbi:ODBC:DSN=appdsn', username => 'app',
    )->for_host('replica.example') ]);
  } qr/'host'.*beside a dbname that is a whole DSN/,
    "... so a HostBound view's host is not dropped either";
}

done_testing;
