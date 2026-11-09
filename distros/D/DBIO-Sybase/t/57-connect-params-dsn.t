use strict;
use warnings;

use Test::More;

use mro ();
use DBI;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;
use DBIO::Sybase::Storage::FreeTDS;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k59; core k242, ADR 0057). Connection parameters without a DSN
# -- { dbname, host, port }, as DBIO::AccessBroker::Static answers them, or a
# connect-info hash without a dsn -- become a DSN through the storage's seam
# _connect_params_dsn. Core's default form is
#
#   dbi:<DBD>:dbname=..;host=..;port=..
#
# and DBD::Sybase has no dbname= key: it reads the database from database=
# (DBD::Sybase POD, "Specifying other connection specific parameters"; its
# dbdimp.c looks for exactly that tag and skips what it does not know). Going
# by that source, the default DSN reaches the right server and leaves the
# session in the login's default database, with no error at all. This driver
# overrides the seam; this file pins what it builds and what it refuses to
# build:
#
#   1. dbname is database=<dbname>, host and port together are
#      host=<host>;port=<port>, and a part not given is left out: nothing goes
#      into the DSN that the parameters do not say, no port above all;
#   2. host without port and port without host refuse. DBD::Sybase sets the
#      server address only when it has both (dbdimp.c: host[0] && port[0]);
#      a lone one is ignored and the connection goes to the client library's
#      default server -- somewhere the parameters never named;
#   3. the DSN names DBD::Sybase, whatever name the seam is handed: the keys
#      are that DBD's and no other's;
#   4. the override is asked through core's real path -- broker or
#      connect-info hash, schema with the Sybase component loaded -- and
#      dbname, host and port do not reach DBI->connect as attributes. Calling
#      the method directly would prove the string and not that the seam is in
#      the path at all;
#   5. it holds on the classes the storage is reblessed into. The first
#      connect is made by DBIO::Sybase::Storage, every later one by
#      DBIO::Sybase::Storage::ASE or its FreeTDS trait class, and a broker is
#      asked anew for each; the ASE writer storage builds its own DSN from
#      the same broker.
#
# The form is shared with dbio-mssql: DBIO::MSSQL::Storage::Sybase inherits
# this class ahead of DBIO::MSSQL::Storage, so what is built here is what it
# builds, and dbio-mssql's t/59-connect-params-dsn.t pins the same string.
#
# Nothing here connects: connect_info builds the DSN, and DBI->connect is
# replaced where a connect is made. Whether a server ACCEPTS these DSNs is not
# provable offline and is not claimed here.

{
  package T::Sybase::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
}

{
  package T::FakeDBH;
  sub new { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]{$_[1]} }
}

my $BASE = 'DBIO::Sybase::Storage';
my $ASE  = 'DBIO::Sybase::Storage::ASE';

# The runtime FreeTDS trait class, built the way DBIO::Sybase::Storage::_init
# builds it once DBD::Sybase turns out to be linked against FreeTDS.
my $FREETDS = "${ASE}::FreeTDS";
{
  my @isa = @{ mro::get_linear_isa($ASE) };
  shift @isa;
  mro::set_mro($FREETDS, 'c3');
  no strict 'refs';
  @{"${FREETDS}::ISA"} = ($ASE, 'DBIO::Sybase::Storage::FreeTDS', @isa);
}

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

sub storage_for { T::Sybase::Schema->connect(@_)->storage }

# What DBI->connect is handed when $storage makes a connection.
sub connect_args {
  my $storage = shift;
  my @connects;
  no warnings qw(redefine once);
  local *DBI::connect = sub { shift; push @connects, [@_]; T::FakeDBH->new };
  $storage->_connect;
  return \@connects;
}

my $FULL = 'dbi:Sybase:host=ase.example;port=5000;database=app';

# ------------------------------------------------- the seam is this driver's

isnt(
  $BASE->can('_connect_params_dsn'),
  DBIO::Storage::DBI->can('_connect_params_dsn'),
  "$BASE has a _connect_params_dsn of its own: core's default names the "
. 'database with dbname=, which DBD::Sybase does not read',
);

# ------------------------- 1 + 4. all three parts, through core's real path

{
  my $broker  = broker(dbname => 'app', host => 'ase.example', port => 5000);
  my $storage = storage_for($broker);

  is ref $storage, $BASE,
    'a schema with the Sybase component connected through a Static broker has '
  . 'the Sybase storage -- registered for one DBD name, so core asks its seam';

  is_deeply $storage->_dbi_connect_info,
    [ $FULL, 'sa', 's3cret', { %DEFAULT_ATTRS } ],
    'dbname, host and port are a DBD::Sybase DSN: host= and port=, the '
  . 'database as database=; user and password stay DBI->connect arguments, '
  . 'and none of the three parts is left over as an attribute';

  unlike $storage->_dbi_connect_info->[0], qr/dbname=/,
    'no dbname= in the DSN: DBD::Sybase would not read it, and the session '
  . 'would silently stay in the login\'s default database';

  # Core asks the broker anew for every connection, and the seam with it.
  $broker->host('standby.example');
  is_deeply connect_args($storage), [[
    'dbi:Sybase:host=standby.example;port=5000;database=app',
    'sa', 's3cret', { %DEFAULT_ATTRS },
  ]], 'DBI->connect gets that DSN and nothing of the parts beside it -- built '
    . 'again from what the broker answers at connect time';

  # 5. After the first connect the storage is reblessed, and every reconnect
  # asks the seam on the class it has become.
  for my $class ($ASE, $FREETDS) {
    bless $storage, $class;
    is_deeply connect_args($storage), [[
      'dbi:Sybase:host=standby.example;port=5000;database=app',
      'sa', 's3cret', { %DEFAULT_ATTRS },
    ]], "reblessed into $class, a reconnect builds the same DSN";
  }
}

{
  my $storage = storage_for({
    dbname   => 'app',
    host     => 'ase.example',
    port     => 5000,
    user     => 'sa',
    password => 's3cret',
  });

  is_deeply $storage->_dbi_connect_info,
    [ $FULL, 'sa', 's3cret', { %DEFAULT_ATTRS } ],
    'a connect-info hash without a dsn takes the same path as a broker';
}

# ------------------------------- 1. a part not given is left out, not invented

is storage_for(broker(host => 'ase.example', port => 5000))
     ->_dbi_connect_info->[0],
  'dbi:Sybase:host=ase.example;port=5000',
  'host and port without dbname: no database= at all -- the server puts the '
. 'session into the login\'s default database, none is made up here';

is storage_for(broker(dbname => 'app'))->_dbi_connect_info->[0],
  'dbi:Sybase:database=app',
  'dbname alone: no host=, no port= -- which server is the client library\'s '
. 'to say (DSQUERY, its default server), no localhost and no port made up';

# ------------------------------------------------- 2. what it refuses, and why

{
  my $ok = eval {
    storage_for(broker(dbname => 'app', host => 'ase.example'));
    1;
  };
  my $error = "$@";

  ok !$ok, 'host without port refuses: DBD::Sybase would ignore the lone host '
         . 'and connect to its default server instead';
  like $error, qr/DBD::Sybase DSN.*without a port/s, '... saying which part is missing';
  like $error, qr/No port is assumed/, '... and that none is assumed for it';
  like $error, qr/\bdsn\b/, '... and the way out: the whole DSN';
  unlike $error, qr/s3cret/, '... naming no password';
}

{
  my $ok = eval {
    storage_for(broker(dbname => 'app', port => 5000));
    1;
  };
  my $error = "$@";

  ok !$ok, 'port without host refuses: the port given would be dropped silently';
  like $error, qr/DBD::Sybase DSN.*without a host/s, '... saying which part is missing';
  like $error, qr/\bdsn\b/, '... naming the way out';
  unlike $error, qr/s3cret/, '... naming no password';
}

# ------------------------------------- 5. every combination, on every class
#
# The seam itself, for all eight ways dbname, host and port can be given or
# not. Core hands over only the parts given (defined, not empty), so "not
# given" is an absent key. It is asked with the registered name, as core does.

my %PART = (dbname => 'app', host => 'ase.example', port => 5000);

my @CASES = (
  [ [qw(dbname host port)], $FULL ],
  [ [qw(host port)],        'dbi:Sybase:host=ase.example;port=5000' ],
  [ [qw(dbname)],           'dbi:Sybase:database=app' ],
  [ [],                     'dbi:Sybase:' ],
  [ [qw(dbname host)],      qr/without a port/ ],
  [ [qw(host)],             qr/without a port/ ],
  [ [qw(dbname port)],      qr/without a host/ ],
  [ [qw(port)],             qr/without a host/ ],
);

for my $class ($BASE, $ASE, $FREETDS) {
  is_deeply [ $class->_registered_dbd_drivers ], ['Sybase'],
    "$class answers for the one DBD name Sybase, so core asks its seam "
  . 'instead of refusing the parameters';

  my $storage = $class->new;

  for my $case (@CASES) {
    my ($given, $expect) = @$case;
    my %params = map { $_ => $PART{$_} } @$given;
    my $name   = @$given ? join(' + ', @$given) : 'nothing';

    if (ref $expect) {
      my $ok = eval { $storage->_connect_params_dsn('Sybase', { %params }); 1 };
      ok !$ok && "$@" =~ $expect, "$class, $name: refuses"
        or diag $ok ? 'built a DSN instead' : $@;
    }
    else {
      is $storage->_connect_params_dsn('Sybase', { %params }), $expect,
        "$class, $name: $expect";
    }
  }
}

# ------------------------------------------------ 3. the DBD named is Sybase

is $BASE->new->_connect_params_dsn('NotSybase', { %PART }), $FULL,
  'the DSN names DBD::Sybase whatever name the seam is handed: host=, port= '
. 'and database= are its keys, so a class registered under another name '
. 'must not get that name in front of them';

# ------------------------------------------------- 5. the ASE writer storage
#
# DBIO::Sybase::Storage::ASE::_init builds a second storage for inserts and
# blob updates and hands it the first one's connect info -- the broker, not a
# DSN. It is an ASE storage from the start, so its DSN is built by the seam as
# ASE resolves it. Only the server-bound parts of _init are neutralised.

{
  my $storage = $ASE->new;
  $storage->connect_info([
    broker(dbname => 'app', host => 'ase.example', port => 5000)
  ]);

  is $storage->_dbi_connect_info->[0], $FULL,
    'an ASE storage given a broker builds the DBD::Sybase DSN';

  no warnings 'redefine';
  local *DBIO::Sybase::Storage::ASE::_using_freetds         = sub { 1 };
  local *DBIO::Sybase::Storage::ASE::_using_freetds_version = sub { 0 };
  local *DBIO::Sybase::Storage::ASE::_set_max_connect       = sub { };
  local *DBIO::Storage::DBI::_init                          = sub { };

  $storage->_init;

  is_deeply $storage->_writer_storage->_dbi_connect_info,
    [ $FULL, 'sa', 's3cret', { %DEFAULT_ATTRS } ],
    '... and so does the writer storage _init creates from its connect info';
}

# ----------------------------------------------------- the way out still works
#
# Both refusals point at "supply a dsn instead". A dbname that is a whole DSN
# is taken as the DSN by core before the seam is asked -- the way in for a
# server reached by name (interfaces file, freetds.conf).

{
  my $whole = 'dbi:Sybase:server=ASE_PROD;database=app';
  is storage_for(broker(dbname => $whole))->_dbi_connect_info->[0], $whole,
    "a dbname that is a whole DSN is passed on untouched: $whole";
}

done_testing;
