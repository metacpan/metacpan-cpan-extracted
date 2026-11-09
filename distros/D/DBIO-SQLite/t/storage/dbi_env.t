use strict;
use warnings;
use DBIO ();
use DBIO::SQLite::Test;
use DBIO::Storage::DBI;
use DBIO::SQLite::Storage;
use Test::More;
use Test::Exception;
use DBIO::Util 'sigwarn_silencer';

BEGIN { delete @ENV{qw(DBI_DSN DBI_DRIVER)} }

$ENV{DBIO_TEST_LOCK_HOLDER} = -1;

# pre-populate
my $schema = DBIO::SQLite::Test->init_schema(sqlite_use_file => 1);

my $dbname = DBIO::SQLite::Test->_sqlite_dbname(sqlite_use_file => 1);

sub count_sheep {
    my $schema = shift;

    local $SIG{__WARN__} = sigwarn_silencer(
      qr/
        \QThis version of DBIO does not yet seem to supply a driver for your particular RDBMS\E
          |
        \QUnable to extract a driver name from connect info\E
          |
        \QYour storage class (DBIO::Storage::DBI) does not set sql_limit_dialect\E
      /x
    );

    scalar $schema->resultset('Artist')->search( { name => "Exploding Sheep" } )
        ->all;
}

# A schema always has a driver (core ADR 0067): DBIO::Test::Schema keeps none
# in its class, so every connect below declares SQLite on a clone. Which
# driver a DSN leads to is DBIO->driver_for's question, not the storage's.
sub declared {
  my $declared = DBIO::Test::Schema->clone;
  $declared->storage_type('DBIO::SQLite::Storage');
  return $declared->connect(@_);
}

SKIP: {
  skip 'the refusal of a schema without a driver arrives with core ADR 0067', 1
    unless DBIO->can('driver_for');

  throws_ok { DBIO::Test::Schema->connect("dbi:SQLite:$dbname") }
    qr{declares no driver},
    'a schema without a driver is refused at connect, although the DSN names SQLite';
}

$schema = declared("dbi::$dbname");
throws_ok { count_sheep($schema) } qr{DSN without a driver part},
    'Driver in DSN empty is refused (core karr k340)';
isa_ok $schema->storage, 'DBIO::SQLite::Storage';

SKIP: {
  skip 'DBIO->driver_for arrives with core ADR 0067', 2
    unless DBIO->can('driver_for');

  throws_ok { DBIO->driver_for("dbi:Test_NonExistant_DBD:$dbname") }
    qr{DBD::Test_NonExistant_DBD names no DBIO driver},
    'driver_for: a DBD no driver is registered for names no driver';

  throws_ok { DBIO->driver_for("dbi::$dbname") }
    qr{the DSN names no DBD},
    'driver_for: a DSN without a driver part names no driver';
}

{
  local $ENV{DBI_DSN} = "dbi:SQLite:$dbname";
  $schema = declared("dbi::$dbname");
  throws_ok { count_sheep($schema) } qr{DSN without a driver part},
      'Driver in DSN empty, SQLite in DBI_DSN: still refused';
  isa_ok $schema->storage, 'DBIO::SQLite::Storage';
}

# connect() without arguments is refused at connect, whatever the DBI
# environment names
for my $case (
  [ 'no DBI environment'                 => {} ],
  [ 'SQLite in DBI_DSN'                  => { DBI_DSN => "dbi:SQLite:$dbname" } ],
  [ 'SQLite in DBI_DRIVER'               => { DBI_DRIVER => 'SQLite' } ],
  [ 'SQLite in DBI_DSN (and DBI_DRIVER)' => { DBI_DSN => "dbi:SQLite:$dbname", DBI_DRIVER => 'SQLite' } ],
  [ 'SQLite in DBI_DRIVER (not DBI_DSN)' => { DBI_DSN => "dbi::$dbname", DBI_DRIVER => 'SQLite' } ],
) {
  my ($name, $env) = @$case;
  local @ENV{keys %$env} = values %$env;

  throws_ok { declared() }
    qr/Connect info without a DSN \(no arguments\)/,
    "connect() without arguments refused, $name";
}

$schema = declared("dbi:SQLite:$dbname");
lives_ok { count_sheep($schema) } 'SQLite passed to connect_info';
isa_ok $schema->storage, 'DBIO::SQLite::Storage';

$schema = declared("dbi:SQLite(ReadOnly=1):$dbname");
lives_ok { count_sheep($schema) } 'SQLite passed to connect_info despite extra arguments present';
isa_ok $schema->storage, 'DBIO::SQLite::Storage';

SKIP: {
  skip 'DBIO->driver_for arrives with core ADR 0067', 2
    unless DBIO->can('driver_for');

  is( DBIO->driver_for("dbi:SQLite:$dbname"), 'SQLite',
    'driver_for: a dbi:SQLite DSN names the SQLite driver' );
  is( DBIO->driver_for("dbi:SQLite(ReadOnly=1):$dbname"), 'SQLite',
    'driver_for: ... also with DBI attributes in the DSN' );
}

# the DSN passed to connect names the driver, whatever the DBI environment names
for my $env (
  { DBI_DRIVER => 'Test_NonExistant_DBD3' },
  { DBI_DSN => "dbi:Test_NonExistant_DBD4:$dbname" },
) {
  local @ENV{keys %$env} = values %$env;
  my ($var) = keys %$env;

  $schema = declared("dbi:SQLite:$dbname");
  lives_ok { count_sheep($schema) } "SQLite passed to connect_info, another driver in $var";
  isa_ok $schema->storage, 'DBIO::SQLite::Storage';

  SKIP: {
    skip 'DBIO->driver_for arrives with core ADR 0067', 1
      unless DBIO->can('driver_for');

    is( DBIO->driver_for("dbi:SQLite:$dbname"), 'SQLite',
      "driver_for: the DSN names the driver, another driver in $var does not" );
  }
}

# A DSN that names no driver is refused, whatever DBI_DRIVER holds: the DSN
# names the driver, never $ENV{DBI_DRIVER} (core karr k340).
for my $driver (qw( SQLite Test_NonExistant_DBD3 )) {
  local $ENV{DBI_DRIVER} = $driver;
  $schema = declared("dbi::$dbname");
  throws_ok { count_sheep($schema) } qr{DSN without a driver part},
      "DBI_DRIVER=$driver does not fill a DSN without a driver part";
}

# a storage that never got connect info has nothing to connect from, and
# setting DBI_DSN gives it nothing
for my $class (qw( DBIO::Storage::DBI DBIO::SQLite::Storage )) {
  local $ENV{DBI_DSN};

  my $storage = $class->new(undef);

  throws_ok {
    $storage->ensure_connected
  } qr/You did not provide any connection_info/,
  "$class: sensible exception on connect without connect info";

  $ENV{DBI_DSN} = 'dbi:SQLite::memory:';

  throws_ok {
    $storage->ensure_connected
  } qr/You did not provide any connection_info/,
  "$class: the same exception with DBI_DSN set";
  ok ( ! $storage->connected, "$class: and no connection is opened" );
}

done_testing;
