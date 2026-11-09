use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::DB2::Storage;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k37; core k242, ADR 0057). Connection parameters without a DSN
# -- { dbname, host, port }, as DBIO::AccessBroker::Static answers them, or a
# connect-info hash without a dsn -- become a DSN through the storage's seam
# _connect_params_dsn. Core's default form is
#
#   dbi:<DBD>:dbname=..;host=..;port=..
#
# and DBD::DB2 takes none of it. It knows two ways to connect (DBD::DB2 POD,
# "Connecting to a database"):
#
#   cataloged    dbi:DB2:<alias>      the DSN is nothing but the alias the
#                                     client's database directory resolves
#   uncataloged  dbi:DB2:DATABASE=<db>;HOSTNAME=<host>;PORT=<port>;PROTOCOL=TCPIP
#                                     a CLI connection string, whose keywords
#                                     are DATABASE/HOSTNAME/PORT -- not
#                                     dbname/host/port
#
# So with the default every DB2 connection through a broker got a DSN its DBD
# refuses. This driver overrides the seam; this file pins what it builds and,
# just as much, what it refuses to build:
#
#   1. dbname alone is the cataloged alias: dbi:DB2:<dbname>;
#   2. dbname, host and port are the uncataloged connection string;
#   3. host without port refuses. DB2 has no implied port -- the instance
#      listens on whatever its SVCENAME says -- so there is nothing to default
#      to, and a guessed port connects to something else or to nothing;
#   4. port without host refuses. Without a host the dbname is a cataloged
#      alias and the port lives in the catalog's node entry; dropping the one
#      given would connect to wherever the catalog says, silently;
#   5. no dbname refuses. Both forms need it, there is no default database;
#   6. the override is asked through core's real path -- broker or connect-info
#      hash, schema with the DB2 component loaded -- and dbname, host and port
#      do not reach DBI->connect as attributes. Calling the method directly
#      would prove the string and not that the seam is in the path at all.
#
# Nothing here connects: connect_info builds the DSN, and DBI->connect is
# replaced where a connect is made. Whether a Db2 server ACCEPTS these DSNs is
# not provable offline and is not claimed here.

{
  package T::DB2::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
}

{
  package T::FakeDBH;
  sub new { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]{$_[1]} }
}

my %DEFAULT_ATTRS = (
  AutoCommit         => 1,
  PrintError         => 0,
  RaiseError         => 1,
  ShowErrorStatement => 0,    # core sets it off whatever connect_info says (ADR 0075, core k386)
);

sub broker {
  return DBIO::AccessBroker::Static->new(
    username => 'db2inst1',
    password => 's3cret',
    @_,
  );
}

sub storage_for { T::DB2::Schema->connect(@_)->storage }

my $UNCATALOGED
  = 'dbi:DB2:DATABASE=SAMPLE;HOSTNAME=db2.example;PORT=50000;PROTOCOL=TCPIP';

# ------------------------------------------------- the seam is this driver's

isnt(
  DBIO::DB2::Storage->can('_connect_params_dsn'),
  DBIO::Storage::DBI->can('_connect_params_dsn'),
  'DBIO::DB2::Storage has a _connect_params_dsn of its own: core\'s default '
. 'form (dbname=..;host=..;port=..) is one DBD::DB2 does not take',
);

# ----------------------------------- 1 + 6. cataloged, through the real path

{
  my $storage = storage_for(broker(dbname => 'SAMPLE'));

  is ref $storage, 'DBIO::DB2::Storage',
    'a schema with the DB2 component connected through a Static broker has '
  . 'the DB2 storage -- the one registered for DBD::DB2, so core can ask it';

  is_deeply $storage->_dbi_connect_info,
    [ 'dbi:DB2:SAMPLE', 'db2inst1', 's3cret', { %DEFAULT_ATTRS } ],
    'dbname alone is the cataloged alias, dbi:DB2:<alias>; user and password '
  . 'stay DBI->connect arguments, and dbname is no DBI attribute';
}

# --------------------------------- 2 + 6. uncataloged, through the real path

{
  my $broker = broker(dbname => 'SAMPLE', host => 'db2.example', port => 50000);
  my $storage = storage_for($broker);

  is_deeply $storage->_dbi_connect_info,
    [ $UNCATALOGED, 'db2inst1', 's3cret', { %DEFAULT_ATTRS } ],
    'dbname, host and port are the uncataloged connection string, spelled '
  . 'with the CLI keywords DATABASE/HOSTNAME/PORT and PROTOCOL=TCPIP; no '
  . 'UID=/PWD= in it, and none of the three parts left over as an attribute';

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
    'dbi:DB2:DATABASE=SAMPLE;HOSTNAME=standby.example;PORT=50000;PROTOCOL=TCPIP',
    'db2inst1', 's3cret', { %DEFAULT_ATTRS },
  ]], 'DBI->connect gets that DSN and nothing of the parts beside it -- built '
    . 'again from what the broker answers at connect time';
}

{
  my $storage = storage_for({
    dbname   => 'SAMPLE',
    host     => 'db2.example',
    port     => 50000,
    user     => 'db2inst1',
    password => 's3cret',
  });

  is_deeply $storage->_dbi_connect_info,
    [ $UNCATALOGED, 'db2inst1', 's3cret', { %DEFAULT_ATTRS } ],
    'a connect-info hash without a dsn takes the same path as a broker';
}

# ------------------------------------------- 3, 4, 5. what it refuses, and why

throws_ok {
  storage_for(broker(dbname => 'SAMPLE', host => 'db2.example'));
} qr/DBD::DB2 DSN.*without a port/s,
  'host without port refuses: DB2 has no implied port to fall back on';
like "$@", qr/PORT=/,
  '... naming the form the port is missing from';
like "$@", qr/\bdsn\b/, '... and the way out: the whole DSN';
unlike "$@", qr/s3cret/, '... naming no password';

throws_ok {
  storage_for(broker(dbname => 'SAMPLE', port => 50000));
} qr/DBD::DB2 DSN.*without a host/s,
  'port without host refuses: beside a cataloged alias the port would be '
. 'dropped and the catalog would decide where the connection goes';
unlike "$@", qr/s3cret/, '... naming no password';

throws_ok {
  storage_for(broker(host => 'db2.example', port => 50000));
} qr/DBD::DB2 DSN.*without a dbname/s,
  'host and port without dbname refuse: there is no default database';
unlike "$@", qr/s3cret/, '... naming no password';

throws_ok {
  storage_for(broker());
} qr/DBD::DB2 DSN.*without a dbname/s,
  'no connection parameters at all refuse the same way, instead of becoming '
. 'the empty DSN "dbi:DB2:"';

# ------------------------------------------------ every combination, directly
#
# The seam itself, for all eight ways dbname, host and port can be given or
# not. Core hands over only the parts given (defined, not empty), so "not
# given" is an absent key.

my %PART = (dbname => 'SAMPLE', host => 'db2.example', port => 50000);

my @CASES = (
  [ [qw(dbname)],           'dbi:DB2:SAMPLE' ],
  [ [qw(dbname host port)], $UNCATALOGED ],
  [ [qw(dbname host)],      qr/without a port/ ],
  [ [qw(dbname port)],      qr/without a host/ ],
  [ [qw(host port)],        qr/without a dbname/ ],
  [ [qw(host)],             qr/without a dbname/ ],
  [ [qw(port)],             qr/without a dbname/ ],
  [ [],                     qr/without a dbname/ ],
);

my $storage = DBIO::DB2::Storage->new(undef);

for my $case (@CASES) {
  my ($given, $expect) = @$case;
  my %params = map { $_ => $PART{$_} } @$given;
  my $name   = @$given ? join(' + ', @$given) : 'nothing';

  if (ref $expect) {
    throws_ok { $storage->_connect_params_dsn('DB2', { %params }) } $expect,
      "$name: refuses";
  }
  else {
    is $storage->_connect_params_dsn('DB2', { %params }), $expect,
      "$name: $expect";
  }
}

# ----------------------------------------------------- the way out still works
#
# Every refusal above points at "supply a dsn instead". A dbname that is a
# whole DSN is taken as the DSN by core before the seam is asked, so anything
# these three parts cannot say -- SECURITY=SSL, a trailing keyword -- has a
# way in on this driver too.

{
  my $whole = 'dbi:DB2:DATABASE=SAMPLE;HOSTNAME=db2.example;PORT=50001;'
            . 'PROTOCOL=TCPIP;SECURITY=SSL';

  is storage_for(broker(dbname => $whole))->_dbi_connect_info->[0], $whole,
    'a dbname that is a whole dbi:DB2: DSN is passed on untouched';
}

done_testing;
