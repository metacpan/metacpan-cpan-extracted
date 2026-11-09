use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Oracle::Storage;
use DBIO::Oracle::Storage::WhereJoins;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k33; core k242, ADR 0057). Connection parameters without a DSN
# -- { dbname, host, port }, as DBIO::AccessBroker::Static answers them, or a
# connect-info hash without a dsn -- become a DSN through the storage's seam
# _connect_params_dsn. Core's default form is
#
#   dbi:<DBD>:dbname=..;host=..;port=..
#
# and DBD::Oracle takes none of it. What follows "dbi:Oracle:" is a database
# identifier (DBD::Oracle POD, "connect"), and it has two shapes these three
# parts can fill:
#
#   by name       dbi:Oracle:<name>     a local SID or service name, or a name
#                                       tnsnames.ora defines -- the Oracle
#                                       client resolves it
#   Easy Connect  dbi:Oracle://host[:port][/service_name]
#                                       no tnsnames.ora; "If port name is not
#                                       specified, 1521 is the default"
#
# A ';' in the identifier switches DBD::Oracle to its keyed form
# (host=..;sid=..;port=..), whose keys do not include dbname: its connect
# refuses core's default before it reaches the Oracle client at all. And
# without a host the default hands the client the literal name "dbname=ORCL".
# So with the default every Oracle connection through a broker got a DSN its
# DBD cannot use. This driver overrides the seam; this file pins what it
# builds and, just as much, what it refuses to build:
#
#   1. dbname alone is the name the client resolves: dbi:Oracle:<dbname>;
#   2. with a host it is Easy Connect, and dbname is the SERVICE NAME there --
#      not a SID: that is what the form's last part is, and a pluggable
#      database is reached by service name only;
#   3. host without port puts no port into the DSN. Unlike DB2 or SQL Server
#      there IS a documented default, and it is the Oracle client's to apply,
#      so none is made up here -- no ":1521" either;
#   4. a part not given is left out: host without dbname is //host[:port],
#      which DBD::Oracle documents as valid, and nothing at all is
#      "dbi:Oracle:", which it documents too (ORACLE_SID / TWO_TASK);
#   5. port without host refuses. A name the client resolves has no place for
#      a port; dropping the one given would connect to wherever tnsnames.ora
#      or the local instance says, silently;
#   6. the override is asked through core's real path -- broker or
#      connect-info hash, schema with the Oracle component loaded -- and
#      dbname, host and port do not reach DBI->connect as attributes. Calling
#      the method directly would prove the string and not that the seam is in
#      the path at all.
#
# Nothing here reaches a database: connect_info builds the DSN, and
# DBI->connect is replaced where a connect is made. Whether an Oracle listener
# ACCEPTS these DSNs is not provable offline and is not claimed here.
# t/38-connect-params-live.t is where it is.

{
  package T::Oracle::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
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
  ShowErrorStatement => 0,
  # the driver's own defaults (karr k63, t/91)
  LongReadLen        => 16 * 1024 * 1024,
  ora_charset        => 'AL32UTF8',
  ora_ncharset       => 'AL32UTF8',
);

sub broker {
  return DBIO::AccessBroker::Static->new(
    username => 'scott',
    password => 's3cret',
    @_,
  );
}

sub storage_for { T::Oracle::Schema->connect(@_)->storage }

my $EASY = 'dbi:Oracle://ora.example:1522/ORCLPDB1';

# ------------------------------------------------- the seam is this driver's

isnt(
  DBIO::Oracle::Storage->can('_connect_params_dsn'),
  DBIO::Storage::DBI->can('_connect_params_dsn'),
  'DBIO::Oracle::Storage has a _connect_params_dsn of its own: core\'s '
. 'default form (dbname=..;host=..;port=..) is one DBD::Oracle does not take',
);

# ------------------------------- why: DBD::Oracle itself refuses core's default
#
# Not a citation but the DBD's own answer. Its connect() takes a ';' in the
# identifier as the keyed form and wants HOST plus one of SID, INSTANCE_NAME,
# SERVER, SERVICE_NAME; "dbname" is none of them, so it gives up in Perl,
# before the Oracle client is asked to connect anywhere.

SKIP: {
  skip 'DBD::Oracle cannot be loaded here: ' . ( $@ =~ /\A(.*)$/m )[0], 2
    unless eval { DBI->install_driver('Oracle'); 1 };

  my $default = DBIO::Storage::DBI::_connect_params_dsn(
    DBIO::Oracle::Storage->new(undef), 'Oracle',
    { dbname => 'ORCLPDB1', host => 'ora.example', port => 1522 },
  );

  is $default, 'dbi:Oracle:dbname=ORCLPDB1;host=ora.example;port=1522',
    'core\'s default form, for the record';

  my $dbh = DBI->connect(
    $default, 'scott', 's3cret', { RaiseError => 0, PrintError => 0 },
  );

  like +( $dbh ? 'connected' : DBI->errstr ),
    qr/Can't connect using this syntax without specifying a HOST and one of/,
    '... is refused by DBD::Oracle itself: "dbname" is no key of its keyed '
  . 'form, so there is nothing the default could have connected to';
}

# ------------------------------------- 1 + 6. by name, through the real path

{
  my $storage = storage_for(broker(dbname => 'ORCL'));

  is ref $storage, 'DBIO::Oracle::Storage',
    'a schema with the Oracle component connected through a Static broker '
  . 'has the Oracle storage -- the one registered for DBD::Oracle, so core '
  . 'can ask it';

  is_deeply $storage->_dbi_connect_info,
    [ 'dbi:Oracle:ORCL', 'scott', 's3cret', { %DEFAULT_ATTRS } ],
    'dbname alone is the name the Oracle client resolves, dbi:Oracle:<name>; '
  . 'user and password stay DBI->connect arguments, and dbname is no DBI '
  . 'attribute';
}

# -------------------------------- 2 + 6. Easy Connect, through the real path

{
  my $broker = broker(dbname => 'ORCLPDB1', host => 'ora.example', port => 1522);
  my $storage = storage_for($broker);

  is_deeply $storage->_dbi_connect_info,
    [ $EASY, 'scott', 's3cret', { %DEFAULT_ATTRS } ],
    'dbname, host and port are Easy Connect, //host:port/service_name, with '
  . 'dbname as the service name; none of the three parts left over as an '
  . 'attribute';

  # What DBD::Oracle is handed is the EZCONNECT url of its documentation and
  # nothing else: no "name=value", no ';' that would switch it to the keyed
  # form and its SID.
  is_deeply [ ( DBI->parse_dsn($EASY) )[1, 4] ],
    [ 'Oracle', '//ora.example:1522/ORCLPDB1' ],
    'DBI splits that DSN into the driver Oracle and the identifier '
  . '//host:port/service_name';

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
    'dbi:Oracle://standby.example:1522/ORCLPDB1',
    'scott', 's3cret', { %DEFAULT_ATTRS },
  ]], 'DBI->connect gets that DSN and nothing of the parts beside it -- built '
    . 'again from what the broker answers at connect time';
}

{
  my $storage = storage_for({
    dbname   => 'ORCLPDB1',
    host     => 'ora.example',
    port     => 1522,
    user     => 'scott',
    password => 's3cret',
  });

  is_deeply $storage->_dbi_connect_info,
    [ $EASY, 'scott', 's3cret', { %DEFAULT_ATTRS } ],
    'a connect-info hash without a dsn takes the same path as a broker';
}

# --------------------------- 3 + 4. a part not given is left out, not invented

is storage_for(broker(dbname => 'ORCLPDB1', host => 'ora.example'))
     ->_dbi_connect_info->[0],
  'dbi:Oracle://ora.example/ORCLPDB1',
  'host without port: no port in the DSN -- 1521 is the documented default '
. 'and the Oracle client applies it, so it is not written here';

is storage_for(broker(host => 'ora.example', port => 1522))
     ->_dbi_connect_info->[0],
  'dbi:Oracle://ora.example:1522',
  'host and port without dbname: //host:port and no service name -- the form '
. 'DBD::Oracle documents with the service name optional; none is made up';

is storage_for(broker())->_dbi_connect_info->[0],
  'dbi:Oracle:',
  'no connection parameters at all: the empty identifier DBD::Oracle '
. 'documents, where ORACLE_SID / TWO_TASK say which database';

# ------------------------------------------------- 5. what it refuses, and why

throws_ok {
  storage_for(broker(dbname => 'ORCL', port => 1522));
} qr/DBD::Oracle DSN.*without a host/s,
  'port without host refuses: beside a name the client resolves the port '
. 'would be dropped, and tnsnames.ora would decide where the connection goes';
like "$@", qr{//<host>}, '... naming the form a port belongs to';
like "$@", qr/\bdsn\b/, '... and the way out: the whole DSN';
unlike "$@", qr/s3cret/, '... naming no password';

throws_ok {
  storage_for(broker(port => 1522));
} qr/DBD::Oracle DSN.*without a host/s,
  'port alone refuses the same way, instead of becoming "dbi:Oracle:"';
unlike "$@", qr/s3cret/, '... naming no password';

# ------------------------------------------------ every combination, directly
#
# The seam itself, for all eight ways dbname, host and port can be given or
# not. Core hands over only the parts given (defined, not empty), so "not
# given" is an absent key.

my %PART = (dbname => 'ORCLPDB1', host => 'ora.example', port => 1522);

my @CASES = (
  [ [qw(dbname)],           'dbi:Oracle:ORCLPDB1' ],
  [ [qw(dbname host port)], $EASY ],
  [ [qw(dbname host)],      'dbi:Oracle://ora.example/ORCLPDB1' ],
  [ [qw(host port)],        'dbi:Oracle://ora.example:1522' ],
  [ [qw(host)],             'dbi:Oracle://ora.example' ],
  [ [],                     'dbi:Oracle:' ],
  [ [qw(dbname port)],      qr/without a host/ ],
  [ [qw(port)],             qr/without a host/ ],
);

my $storage = DBIO::Oracle::Storage->new(undef);

for my $case (@CASES) {
  my ($given, $expect) = @$case;
  my %params = map { $_ => $PART{$_} } @$given;
  my $name   = @$given ? join(' + ', @$given) : 'nothing';

  if (ref $expect) {
    throws_ok { $storage->_connect_params_dsn('Oracle', { %params }) } $expect,
      "$name: refuses";
  }
  else {
    is $storage->_connect_params_dsn('Oracle', { %params }), $expect,
      "$name: $expect";
  }
}

# ------------------------------------------------- the WHERE-joins storage
#
# DBIO::Oracle::Storage::WhereJoins is this dist's other storage class. It is
# registered for nothing itself; core finds its driver through its base, so it
# is asked for a DSN like the base is -- and what a storage reconnects with
# must not depend on which of the two it is.

is_deeply [ DBIO::Oracle::Storage::WhereJoins->_registered_dbd_drivers ],
  ['Oracle'],
  'DBIO::Oracle::Storage::WhereJoins is, through its base, a storage '
. 'registered for DBD::Oracle, so core asks it too';

is(
  DBIO::Oracle::Storage::WhereJoins->new(undef)
    ->_connect_params_dsn('Oracle', { %PART }),
  $EASY,
  '... and builds the DSN the base builds',
);

# ----------------------------------------------------- the way out still works
#
# The refusal above points at "supply a dsn instead". A dbname that is a whole
# DSN is taken as the DSN by core before the seam is asked, so anything these
# three parts cannot say -- a SID on a host, a full TNS descriptor -- has a
# way in on this driver too.

for my $whole (
  'dbi:Oracle:host=ora.example;sid=ORCL;port=1522',
  'dbi:Oracle:(DESCRIPTION=(ADDRESS=(PROTOCOL=TCPS)(HOST=ora.example)'
    . '(PORT=2484))(CONNECT_DATA=(SERVICE_NAME=ORCLPDB1)))',
) {
  is storage_for(broker(dbname => $whole))->_dbi_connect_info->[0], $whole,
    "a dbname that is a whole DSN is passed on untouched: $whole";
}

done_testing;
