use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp ();
use IO::Socket::INET ();
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::AccessBroker::Static;
use DBIO::Util qw(file_path write_file);

# LIVE (karr k37; core k242, ADR 0057). The counterpart of
# t/53-connect-params-dsn.t, which pins offline what DSN the seam
# _connect_params_dsn builds from { dbname, host, port } and says of itself:
# "Whether a Db2 server ACCEPTS these DSNs is not provable offline and is not
# claimed here." This file is where it is claimed, against a real Db2 over
# DBD::DB2. Every connection is made the way karr k37 is about: a schema that
# loaded the DB2 component, connected through a DBIO::AccessBroker::Static.
# The sections follow the live plan on the card:
#
#   1. Uncataloged. dbname, host and port are a DSN the server accepts --
#      exactly as built, without the spaces, the trailing ";" and the
#      UID=/PWD= the DBD::DB2 documentation writes -- the login is the
#      broker's user, and the session is in the database named.
#   2. Cataloged. dbname alone is an alias the client resolves, and one it
#      does not know connects nowhere.
#   3. A reconnect after the broker's answer changed goes where the broker
#      says then.
#   4. The way out: a dbname that is a whole dbi:DB2: DSN is passed on
#      untouched and connects, with a CLI keyword the three parts cannot say
#      taking effect.
#
# Two things in here are not a plain connect, and why:
#
#   * the catalog of 2 is a temporary db2dsdriver.cfg, named by
#     $ENV{DB2DSDRIVER_CFG_PATH}. The CLI driver reads that file ONCE per
#     process, at its first connect -- measured: set after a first connect,
#     successful or failed, the variable is ignored and the alias stays
#     unknown (SQL1531N); set after DBD::DB2 was loaded but before the first
#     connect it is honoured. So the variable is set at the top of this file,
#     before anything connects, and every connection below runs with it. The
#     uncataloged form does not look anything up in it. A
#     DB2DSDRIVER_CFG_PATH the environment already carries is not replaced;
#     2 skips then.
#   * the "other host" of 3 is a loopback address and a port nothing listens
#     on, so the connect is refused at once instead of running into a
#     timeout. That the connection went there is what the CLI driver's error
#     says: SQL30081N names the address it could not reach.
#
# The parts come out of $ENV{DBIO_TEST_DB2_DSN} when it is the uncataloged
# form itself (the keywords in any order and case, with or without the
# trailing ";" maint/docker and maint/k8s write), so that the broker provably
# goes where the DSN goes. A DSN of another form -- an alias of the client's
# own catalog -- says nothing about host and port; they are then read from
# $ENV{DBIO_TEST_DB2_HOST}, _PORT and _DBNAME, and without those 1 to 3 skip.
# Nothing is guessed.
#
# Measured 2026-10-05 against Db2 12.1.5 (DB2/LINUXX8664 12.01.0500), with
# DBD::DB2 1.92 on the IBM Data Server Driver for ODBC and CLI ("clidriver")
# 12.01.0400. What this file does NOT claim:
#
#   * a database directory. "Cataloged" in the DBD::DB2 documentation is an
#     entry made with "db2 catalog tcpip node" / "db2 catalog database" in a
#     full Db2 client. The clidriver has neither that directory nor the db2
#     command; its catalog is db2dsdriver.cfg (or db2cli.ini), and that is
#     what 2 resolves the alias from. That dbi:DB2:<alias> reaches a database
#     cataloged the other way was not seen.
#   * a local database. An alias of an instance on the same machine (IPC, no
#     host at all) needs a server installation beside the client.
#   * SECURITY=SSL, the keyword the seam's POD names for the way out. This
#     server offered no TLS port; 4 uses CurrentSchema instead, which shows
#     the same thing -- a keyword beyond the three parts reaches the driver.
#   * an IPv6 host.
#   * the refusals (host without port, port without host, no dbname). They
#     throw before any connect, so there is nothing a server could add to
#     t/53.
#   * the error numbers on another client. SQL1531N, SQL30061N and SQL30081N
#     are what this clidriver and this server say.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

# dbname, host and port of a DSN that is the uncataloged form and nothing
# else; the empty list for every other DSN.
sub uncataloged_parts {
  my ($keywords) = $_[0] =~ /\Adbi:DB2:(.*)\z/si or return;

  my %keyword;
  for my $pair (grep { length } split /;/, $keywords) {
    my ($name, $value) = $pair =~ /\A([^=]+)=(.*)\z/s or return;
    return if exists $keyword{ uc $name };
    $keyword{ uc $name } = $value;
  }

  return unless 'DATABASE HOSTNAME PORT PROTOCOL' eq join ' ', sort keys %keyword;
  return unless 'TCPIP' eq uc $keyword{PROTOCOL};
  return unless 3 == grep { length } @keyword{qw(DATABASE HOSTNAME PORT)};

  return (
    dbname => $keyword{DATABASE},
    host   => $keyword{HOSTNAME},
    port   => $keyword{PORT},
  );
}

my %part = uncataloged_parts($dsn);
my $dsn_is_uncataloged = %part ? 1 : 0;

if (!%part) {
  my %given;
  @given{qw(host port dbname)}
    = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/HOST PORT DBNAME/};
  %part = %given if 3 == grep { defined && length } values %given;
}

my ($dbname, $host, $port) = @part{qw(dbname host port)};

my $NO_PARTS = %part ? undef
  : 'Needs dbname, host and port: $ENV{DBIO_TEST_DB2_DSN} is not the '
  . 'uncataloged form (dbi:DB2:DATABASE=<dbname>;HOSTNAME=<host>;'
  . 'PORT=<port>;PROTOCOL=TCPIP), and $ENV{DBIO_TEST_DB2_HOST}, _PORT and '
  . '_DBNAME are not all set';

my $BUILT = $NO_PARTS ? undef
  : "dbi:DB2:DATABASE=$dbname;HOSTNAME=$host;PORT=$port;PROTOCOL=TCPIP";

# ------------------------------------------------- the catalog, for section 2
#
# BEFORE the first connect of this process: see the head of this file.

my $ALIAS    = 'DBIOK37A';
my $NO_ALIAS = 'DBIOK37X';   # in no catalog

my $NO_CATALOG = $NO_PARTS ? $NO_PARTS
  : defined $ENV{DB2DSDRIVER_CFG_PATH}
    ? '$ENV{DB2DSDRIVER_CFG_PATH} is set: this test would have to replace '
    . 'the client configuration of the environment to catalog its alias'
  : !$dsn_is_uncataloged
    ? '$ENV{DBIO_TEST_DB2_DSN} is not the uncataloged form: it may need the '
    . 'client configuration this test would have to replace to catalog its '
    . 'alias'
  : undef;

my $catalog_dir;

if (!$NO_CATALOG) {
  my %xml = (dbname => $dbname, host => $host, port => $port);
  for (values %xml) { s/&/&amp;/g; s/</&lt;/g; s/"/&quot;/g }

  $catalog_dir = File::Temp->newdir;
  my $cfg = file_path("$catalog_dir", 'db2dsdriver.cfg');

  write_file($cfg, <<"XML");
<configuration>
  <dsncollection>
    <dsn alias="$ALIAS" name="$xml{dbname}" host="$xml{host}" port="$xml{port}"/>
  </dsncollection>
</configuration>
XML

  $ENV{DB2DSDRIVER_CFG_PATH} = $cfg;
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0]; warn $_[0] };

{
  package T::K37::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
}

sub broker {
  return DBIO::AccessBroker::Static->new(
    username => $user,
    password => $pass,
    @_,
  );
}

sub storage_for { T::K37::Schema->connect(@_)->storage }

# What a session says about itself -- asked on the connection under test.
sub value_of {
  my ($dbh, $what) = @_;
  my ($value) = $dbh->selectrow_array("SELECT $what FROM SYSIBM.SYSDUMMY1");
  $value =~ s/\s+\z// if defined $value;
  return $value;
}

sub user_of    { lc value_of($_[0], 'CURRENT USER') }     # an authorization ID
sub server_of  { lc value_of($_[0], 'CURRENT SERVER') }   # ... and a database
sub session_of { value_of($_[0], 'APPLICATION_ID()') }    # name are folded

# The server's address is the environment's and stays out of the output.
sub masked {
  my $text = shift // '(undef)';
  $text =~ s/\b(HOSTNAME|PORT)=[^;]*/$1=../gi;
  return $text;
}

sub dsn_is {
  my ($got, $expected, $name) = @_;
  ok defined $got && $got eq $expected, $name
    or diag 'the DSN is ' . masked($got) . ', expected ' . masked($expected);
}

# The DSN DBI->connect was handed, as the handle itself keeps it.
sub dsn_of { 'dbi:DB2:' . $_[0]->{Name} }

# A loopback port nothing listens on: bound once, so that it was free a
# moment ago, and closed again.
sub refusing_port {
  my $listen = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1, Proto => 'tcp',
  ) or return;
  my $free = $listen->sockport;
  close $listen;
  return $free;
}

# ===================================================================== 1
# Uncataloged: dbname + host + port.

SKIP: {
  skip $NO_PARTS, 12 if $NO_PARTS;

  my $storage
    = storage_for(broker(dbname => $dbname, host => $host, port => $port));

  dsn_is $storage->_dbi_connect_info->[0], $BUILT,
    'dbname, host and port from a Static broker are the DSN '
  . 'dbi:DB2:DATABASE=..;HOSTNAME=..;PORT=..;PROTOCOL=TCPIP -- what t/53 '
  . 'pins, here on the storage that is about to connect with it';

  unlike $storage->_dbi_connect_info->[0], qr/\s|;\z|\b(?:UID|PWD)=/i,
    '... with no space, no trailing ";" and no UID=/PWD= in it: not the '
  . 'spelling of the DBD::DB2 documentation';

  my $dbh;
  lives_ok { $dbh = $storage->dbh }
    'the server accepts that DSN -- the thing t/53 could not show'
    or skip 'no connection to look at', 9;

  # Driver resolution is lazy: connected before the class is looked at.
  is ref $storage, 'DBIO::DB2::Storage',
    'connected, the storage is DBIO::DB2::Storage';

  is $dbh->{Driver}{Name}, 'DB2', 'the connection runs on DBD::DB2';

  dsn_is dsn_of($dbh), $BUILT,
    'DBI->connect was handed exactly that DSN: the handle keeps it';

  is user_of($dbh), lc $user,
    'CURRENT USER is the user of the broker -- user and password went in as '
  . 'DBI->connect arguments, the DSN names neither';

  is server_of($dbh), lc $dbname,
    'CURRENT SERVER is the database the parameters name';

  note 'server: ' . ( $dbh->get_info(17) // '?' ) . ' '
     . ( $dbh->get_info(18) // '?' )
     . "; DBD::DB2 $DBD::DB2::VERSION; CLI driver "
     . ( $dbh->get_info(7) // '?' );

  $storage->disconnect;

  # The counter-proof. That the session is in the right database proves
  # little if the server would have put it there whatever DATABASE= said.
  throws_ok {
    storage_for(
      broker(dbname => $NO_ALIAS, host => $host, port => $port)
    )->ensure_connected;
  } qr/SQL30061N/,
    'a dbname the server has no database for does not connect -- DATABASE= '
  . 'is what the server is asked for, nothing falls back to a default one';

  # The broker is not the only way to the seam.
  my $by_hash = storage_for({
    dbname => $dbname, host => $host, port => $port,
    user   => $user,   password => $pass,
  });

  dsn_is $by_hash->_dbi_connect_info->[0], $BUILT,
    'a connect-info hash without a dsn builds the same DSN';

  lives_and { is server_of($by_hash->dbh), lc $dbname }
    '... and connects into the same database';

  lives_and { is user_of($by_hash->dbh), lc $user }
    '... as the user given beside the parts';

  $by_hash->disconnect;
}

# ===================================================================== 2
# Cataloged: dbname alone.

SKIP: {
  skip $NO_CATALOG, 6 if $NO_CATALOG;

  my $storage = storage_for(broker(dbname => $ALIAS));

  is $storage->_dbi_connect_info->[0], "dbi:DB2:$ALIAS",
    'dbname alone from a Static broker is the DSN dbi:DB2:<dbname>';

  my $dbh;
  lives_ok { $dbh = $storage->dbh }
    'a dbname the client has cataloged connects -- the DSN carries neither '
  . 'host nor port, they come from the catalog entry'
    or skip 'no connection to look at', 4;

  is dsn_of($dbh), "dbi:DB2:$ALIAS",
    'DBI->connect was handed the alias and nothing else';

  is user_of($dbh), lc $user,
    'CURRENT USER is the user of the broker on this form too';

  is server_of($dbh), lc $dbname,
    'CURRENT SERVER is the database the alias stands for';

  $storage->disconnect;

  # Without this the connect above proves nothing: it has to be the catalog
  # that placed it.
  throws_ok {
    storage_for(broker(dbname => $NO_ALIAS))->ensure_connected;
  } qr/SQL1531N/,
    'a dbname no catalog knows does not connect: the client cannot resolve '
  . 'it, and nothing falls back to a local database or a default host';
}

# ===================================================================== 3
# A reconnect after the broker's answer changed. Core asks the broker anew
# for every connection (t/53 shows the DSN it then hands to DBI->connect);
# here the connect is a real one, to an address where nothing listens.

SKIP: {
  skip $NO_PARTS, 10 if $NO_PARTS;

  my $refusing = refusing_port()
    or skip "No loopback port to be refused on: $!", 10;

  # Never the server's own address, and literal where it can be: the CLI
  # driver then names it in its error as it was given.
  my $elsewhere = $host eq '127.0.0.1' ? 'localhost' : '127.0.0.1';
  my $arrived   = $elsewhere eq 'localhost' ? qr/127\.0\.0\.1|::1/
                                            : qr/\Q$elsewhere\E/;

  my $broker  = broker(dbname => $dbname, host => $host, port => $port);
  my $storage = storage_for($broker);

  my $first;
  lives_ok { $first = session_of($storage->dbh) }
    '(the first connection, to the server\'s own address)'
    or skip 'no first connection to reconnect from', 9;

  $broker->host($elsewhere);
  $broker->port($refusing);

  is session_of($storage->dbh), $first,
    'a new answer of the broker alone moves nothing: the open connection '
  . 'stays the session it was';

  $storage->disconnect;

  ok !$storage->connected, '(disconnected)';

  throws_ok { $storage->ensure_connected } qr/SQL30081N/,
    'the next connect does not reach the server: a communication error, '
  . 'where the first host answered a moment ago';

  like "$@", qr/Location where the error was detected: "$arrived"/,
    '... detected at the address the broker names now -- the connection '
  . 'went to the new host';

  dsn_is $storage->_dbi_connect_info->[0],
    "dbi:DB2:DATABASE=$dbname;HOSTNAME=$elsewhere;PORT=$refusing;PROTOCOL=TCPIP",
    '... with a DSN built again from what the broker answered then';

  $broker->host($host);
  $broker->port($port);

  my $second;
  lives_ok { $second = session_of($storage->dbh) }
    'the broker answering the server\'s address again, the same storage '
  . 'connects'
    or skip 'no connection to look at', 3;

  isnt $second, $first, '... as a new session';

  is server_of($storage->dbh), lc $dbname, '... in the database named';

  dsn_is $storage->_dbi_connect_info->[0], $BUILT,
    '... with the DSN of the first connection, built once more';

  $storage->disconnect;
}

# ===================================================================== 4
# The way out: a dbname that is a whole DSN. Core takes it as the DSN before
# the seam is asked.

{
  my $storage = storage_for(broker(dbname => $dsn));

  dsn_is $storage->_dbi_connect_info->[0], $dsn,
    'a dbname that is a whole dbi:DB2: DSN -- $ENV{DBIO_TEST_DB2_DSN} as it '
  . 'was given -- is passed on untouched';

  SKIP: {
    my $dbh;
    lives_ok { $dbh = $storage->dbh } '... and connects'
      or skip 'no connection to look at', 2;

    dsn_is dsn_of($dbh), $dsn, '... DBI->connect handed that very string';

    is user_of($dbh), lc $user, '... as the user of the broker';
  }

  $storage->disconnect;
}

SKIP: {
  skip $NO_PARTS, 3 if $NO_PARTS;

  # No such schema has to exist: CURRENT SCHEMA is a register, and nothing
  # here creates an object in it.
  my $schema = 'DBIO_K37_LIVE';
  my $whole  = "$BUILT;CurrentSchema=$schema";

  my $storage = storage_for(broker(dbname => $whole));

  dsn_is $storage->_dbi_connect_info->[0], $whole,
    'the built DSN with a CLI keyword appended, as dbname, is passed on '
  . 'untouched';

  lives_and { is value_of($storage->dbh, 'CURRENT SCHEMA'), $schema }
    '... and the keyword reaches the driver: the session\'s CURRENT SCHEMA '
  . 'is the one it names -- something dbname, host and port cannot say';

  # ... and it was the keyword: a session without it is in the user's schema.
  my $plain = storage_for(broker(dbname => $BUILT));

  lives_and { isnt value_of($plain->dbh, 'CURRENT SCHEMA'), $schema }
    '... which the same DSN without the keyword is not in';

  $_->disconnect for $storage, $plain;
}

# ================================================================ the end

is_deeply \@warnings, [], 'no warning on the way';

done_testing;
