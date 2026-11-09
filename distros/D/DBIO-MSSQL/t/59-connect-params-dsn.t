use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Storage::DBI::ODBC;
use DBIO::MSSQL::Storage;
use DBIO::MSSQL::Storage::ODBC;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k37; core k242, ADR 0057). Connection parameters without a DSN
# -- { dbname, host, port }, as DBIO::AccessBroker::Static answers them, or a
# connect-info hash without a dsn -- become a DSN through the storage's seam
# _connect_params_dsn. Core's default form is
#
#   dbi:<DBD>:dbname=..;host=..;port=..
#
# where <DBD> is the name the storage class is registered for. For this driver
# that name is 'MSSQL', and it is a registry name only: no DBD::MSSQL exists.
# So with the default every MSSQL connection through a broker got a DSN that
# names a driver DBI cannot load. The two DBDs that do reach SQL Server:
#
#   DBD::Sybase  server=<name> | host=<host>;port=<port>, and database=<db>
#                (DBD::Sybase POD, "Specifying other connection specific
#                parameters") -- keys the three parts can fill
#   DBD::ODBC    DSN=<name> | Driver={...};Server=..;Database=..
#                -- needs a data source or ODBC driver name the parts do not
#                carry
#
# This driver overrides the seam to build the DBD::Sybase form; this file pins
# what it builds and, just as much, what it refuses to build:
#
#   1. the DSN names DBD::Sybase whatever name the seam is handed -- never the
#      registry name;
#   2. host and port together are host=<host>;port=<port>, dbname is
#      database=<dbname> ('dbname=' is no DBD::Sybase key), and a part not
#      given is left out: nothing is put into the DSN that the parameters do
#      not say, no port 1433 above all;
#   3. host without port and port without host refuse. DBD::Sybase uses the
#      two only together; a lone one is ignored and the connection goes to the
#      client library's default server -- somewhere the parameters never named;
#   4. the override is asked through core's real path -- broker or
#      connect-info hash, schema with the MSSQL component loaded -- and
#      dbname, host and port do not reach DBI->connect as attributes. Calling
#      the method directly would prove the string and not that the seam is in
#      the path at all;
#   5. the ODBC transport class keeps core's ODBC refusal. It inherits this
#      class too, and only the order of its bases decides which seam it gets:
#      an ODBC storage that built a dbi:Sybase: DSN would reconnect through a
#      different DBD than the one it is connected with.
#
# Nothing here connects: connect_info builds the DSN, and DBI->connect is
# replaced where a connect is made. Whether a server ACCEPTS these DSNs is not
# provable offline and is not claimed here.

{
  package T::MSSQL::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
}

{
  package T::FakeDBH;
  sub new { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]{$_[1]} }
}

# ShowErrorStatement is always off (core k386): an error text carries no bind value.
my %DEFAULT_ATTRS = (
  AutoCommit         => 1,
  PrintError         => 0,
  RaiseError         => 1,
  ShowErrorStatement => 0,
);

sub broker {
  return DBIO::AccessBroker::Static->new(
    username => 'sa',
    password => 's3cret',
    @_,
  );
}

sub storage_for { T::MSSQL::Schema->connect(@_)->storage }

my $FULL = 'dbi:Sybase:host=mssql.example;port=1433;database=app';

# ------------------------------------------------- the seam is this driver's

isnt(
  DBIO::MSSQL::Storage->can('_connect_params_dsn'),
  DBIO::Storage::DBI->can('_connect_params_dsn'),
  'DBIO::MSSQL::Storage has a _connect_params_dsn of its own: core\'s default '
. 'puts the registered name into the DSN, and no DBD::MSSQL exists',
);

# ----------------------------- 1 + 2 + 4. all three parts, through the real path

{
  my $broker = broker(dbname => 'app', host => 'mssql.example', port => 1433);
  my $storage = storage_for($broker);

  is ref $storage, 'DBIO::MSSQL::Storage',
    'a schema with the MSSQL component connected through a Static broker has '
  . 'the MSSQL storage -- the one registered for a single name, so core asks it';

  is_deeply [ $storage->_registered_dbd_drivers ], ['MSSQL'],
    '... and that name is MSSQL, which is what core hands the seam';

  is_deeply $storage->_dbi_connect_info,
    [ $FULL, 'sa', 's3cret', { %DEFAULT_ATTRS } ],
    'dbname, host and port are a DBD::Sybase DSN: host= and port=, the '
  . 'database as database=; user and password stay DBI->connect arguments, '
  . 'and none of the three parts is left over as an attribute';

  unlike $storage->_dbi_connect_info->[0], qr/^dbi:MSSQL:/i,
    'the DSN does not name the registry name MSSQL as its DBD';

  # What DBI->connect is actually handed, at a (re)connect: core asks the
  # broker anew for every connection, and the seam with it.
  $broker->host('standby.example');
  my @connects;
  {
    no warnings qw(redefine once);
    local *DBI::connect = sub { shift; push @connects, [@_]; T::FakeDBH->new };
    $storage->_connect;
  }
  is_deeply \@connects, [[
    'dbi:Sybase:host=standby.example;port=1433;database=app',
    'sa', 's3cret', { %DEFAULT_ATTRS },
  ]], 'DBI->connect gets that DSN and nothing of the parts beside it -- built '
    . 'again from what the broker answers at connect time';
}

{
  my $storage = storage_for({
    dbname   => 'app',
    host     => 'mssql.example',
    port     => 1433,
    user     => 'sa',
    password => 's3cret',
  });

  is_deeply $storage->_dbi_connect_info,
    [ $FULL, 'sa', 's3cret', { %DEFAULT_ATTRS } ],
    'a connect-info hash without a dsn takes the same path as a broker';
}

# ------------------------------- 2. a part not given is left out, not invented

is storage_for(broker(host => 'mssql.example', port => 1433))
     ->_dbi_connect_info->[0],
  'dbi:Sybase:host=mssql.example;port=1433',
  'host and port without dbname: no database= at all -- the server puts the '
. 'session into the login\'s default database, none is made up here';

is storage_for(broker(dbname => 'app'))->_dbi_connect_info->[0],
  'dbi:Sybase:database=app',
  'dbname alone: no host=, no port= -- which server is the client library\'s '
. 'to say (DSQUERY, its default server), no localhost and no 1433 made up';

# ------------------------------------------------- 3. what it refuses, and why

throws_ok {
  storage_for(broker(dbname => 'app', host => 'mssql.example'));
} qr/DBD::Sybase DSN.*without a port/s,
  'host without port refuses: DBD::Sybase would ignore the lone host and '
. 'connect to its default server instead';
like "$@", qr/\b1433\b/,
  '... saying why no port is assumed, 1433 being only the usual one';
like "$@", qr/\bdsn\b/, '... and the way out: the whole DSN';
unlike "$@", qr/s3cret/, '... naming no password';

throws_ok {
  storage_for(broker(dbname => 'app', port => 1433));
} qr/DBD::Sybase DSN.*without a host/s,
  'port without host refuses: the port given would be dropped silently';
like "$@", qr/\bdsn\b/, '... naming the way out';
unlike "$@", qr/s3cret/, '... naming no password';

# ------------------------------------------------ every combination, directly
#
# The seam itself, for all eight ways dbname, host and port can be given or
# not. Core hands over only the parts given (defined, not empty), so "not
# given" is an absent key. It is asked with the registered name, as core does.

my %PART = (dbname => 'app', host => 'mssql.example', port => 1433);

my @CASES = (
  [ [qw(dbname host port)], $FULL ],
  [ [qw(host port)],        'dbi:Sybase:host=mssql.example;port=1433' ],
  [ [qw(dbname)],           'dbi:Sybase:database=app' ],
  [ [],                     'dbi:Sybase:' ],
  [ [qw(dbname host)],      qr/without a port/ ],
  [ [qw(host)],             qr/without a port/ ],
  [ [qw(dbname port)],      qr/without a host/ ],
  [ [qw(port)],             qr/without a host/ ],
);

my $storage = DBIO::MSSQL::Storage->new(undef);

for my $case (@CASES) {
  my ($given, $expect) = @$case;
  my %params = map { $_ => $PART{$_} } @$given;
  my $name   = @$given ? join(' + ', @$given) : 'nothing';

  if (ref $expect) {
    throws_ok { $storage->_connect_params_dsn('MSSQL', { %params }) } $expect,
      "$name: refuses";
  }
  else {
    is $storage->_connect_params_dsn('MSSQL', { %params }), $expect,
      "$name: $expect";
  }
}

# ------------------------------------- 5. the ODBC transport keeps its refusal
#
# DBIO::MSSQL::Storage::ODBC inherits DBIO::Storage::DBI::ODBC *before*
# DBIO::MSSQL::Storage, so core's ODBC refusal is the seam it resolves to.
# Nothing but that base order keeps it so.

is(
  DBIO::MSSQL::Storage::ODBC->can('_connect_params_dsn'),
  DBIO::Storage::DBI::ODBC->can('_connect_params_dsn'),
  'DBIO::MSSQL::Storage::ODBC resolves the seam to core\'s ODBC refusal, not '
. 'to the DBD::Sybase form of DBIO::MSSQL::Storage',
);

is_deeply [ DBIO::MSSQL::Storage::ODBC->_registered_dbd_drivers ], ['ODBC'],
  '... and is registered for ODBC, so core does ask it';

{
  my $odbc = DBIO::MSSQL::Storage::ODBC->new(undef);

  for my $case (@CASES) {
    my %params = map { $_ => $PART{$_} } @{ $case->[0] };
    my $name   = %params ? join(' + ', @{ $case->[0] }) : 'nothing';

    throws_ok { $odbc->_connect_params_dsn('ODBC', { %params }) }
      qr/Cannot build a DBD::ODBC DSN/,
      "over ODBC, $name: refuses -- no dbi:Sybase: DSN for a DBD::ODBC storage";
  }
}

# ------------------------------------------- the DBD::Sybase transport class
#
# DBIO::MSSQL::Storage::Sybase is registered for the real DBD name, through
# DBIO::Sybase::Storage. Core's default would give it
# dbi:Sybase:dbname=..;host=..;port=.. -- the right DBD and the wrong key for
# the database. It has to build the same DSN the pinned base does: what a
# storage reconnects with must not depend on which of the two it is.

SKIP: {
  # Only "not installed" is a reason to skip. With DBIO::Sybase there, this
  # distribution's own class not loading is a failure -- it must not pass as
  # a missing optional dependency.
  unless (eval { require DBIO::Sybase::Storage; 1 }) {
    die $@ unless $@ =~ m{\ACan't locate DBIO/Sybase/Storage\.pm };

    skip 'DBIO::Sybase is not installed (optional, cpanfile recommends)', 2;
  }

  require DBIO::MSSQL::Storage::Sybase;

  is_deeply [ DBIO::MSSQL::Storage::Sybase->_registered_dbd_drivers ],
    ['Sybase'],
    'DBIO::MSSQL::Storage::Sybase is registered for the DBD it runs on';

  is(
    DBIO::MSSQL::Storage::Sybase->new(undef)
      ->_connect_params_dsn('Sybase', { %PART }),
    $FULL,
    '... and builds the DSN the pinned base builds, database= included',
  );
}

# ----------------------------------------------------- the way out still works
#
# Every refusal above points at "supply a dsn instead", and for DBD::ODBC --
# this driver's default transport -- it is the only way in at all. A dbname
# that is a whole DSN is taken as the DSN by core before the seam is asked.

for my $whole (
  'dbi:ODBC:Driver={ODBC Driver 18 for SQL Server};Server=mssql.example,1433;'
    . 'Database=app',
  'dbi:Sybase:server=mssql-dev;database=app',
) {
  is storage_for(broker(dbname => $whole))->_dbi_connect_info->[0], $whole,
    "a dbname that is a whole DSN is passed on untouched: $whole";
}

done_testing;
