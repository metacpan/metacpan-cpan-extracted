use strict;
use warnings;
use Test::More;

# LIVE test of t/lib/LiveServer.pm and t/lib/PrivatePgDatabase.pm: a real
# server reads the DSNs the helper writes (karr k113). The offline half,
# t/108-live-server.t, pins what is read and written and has libpq read a
# host out of it; which DATABASE a DSN leads to, only a server says.
#
# What this file claims:
#   1. control_dbh is a connection to the database of the test login, with
#      the attributes of the helper, or with those asked for;
#   2. PrivatePgDatabase->create answers a login that leads into the database
#      it made -- also for a name that needs quoting in a DSN;
#   3. dsn_with_dbname leads from one database to another however the first
#      is written in the DSN -- db=, database=, in single or double quotes,
#      with a ';' in the name, behind a value that has "dbname=" in it -- and
#      what read_dsn reads as the database of each of those spellings is the
#      database the server is in for it;
#   4. every other parameter arrives as it was.
#
# Every database made here is this file's own (dbio_t108..._<pid>), dropped
# at END by PrivatePgDatabase.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_$_" } qw( DSN USER PASS ) };

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBIO::PostgreSQL::Util qw(quote_dsn_value);
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan.
LiveServer->require_server;

my $WHERE = q{SELECT current_database(), current_setting('application_name')};

# The database a login leads into, and the application_name it arrives with
# -- or, for a login that leads nowhere, why, which is_deeply then shows.
sub lands_in {
  my (@login) = @_;
  my $dbh = eval { LiveServer->dbh_or_die(login => \@login) }
    or return "no connection: $@";
  my @row = $dbh->selectrow_array($WHERE);
  $dbh->disconnect;
  return \@row;
}

# ---------------------------------------------------------------------------
# 1. A connection of the test's own.
# ---------------------------------------------------------------------------

my %ci = LiveServer->conninfo;

my $dbh = LiveServer->control_dbh;
my ($home, $no_application_name) = $dbh->selectrow_array($WHERE);
note 'server ' . $dbh->selectrow_array('SHOW server_version');

SKIP: {
  skip 'the test DSN names no database', 1 unless defined $ci{dbname};
  is $home, $ci{dbname}, 'control_dbh is in the database conninfo reads out of the test DSN';
}
is_deeply [ map { $dbh->{$_} ? 1 : 0 } qw( RaiseError PrintError AutoCommit ) ], [ 1, 0, 1 ],
  '... with RaiseError, without PrintError, with AutoCommit';
$dbh->disconnect;

$dbh = LiveServer->control_dbh(attrs => { RaiseError => 0, AutoCommit => 0 });
is_deeply [ map { $dbh->{$_} ? 1 : 0 } qw( RaiseError PrintError AutoCommit ) ], [ 0, 0, 0 ],
  'attributes asked for are the attributes of the handle';
$dbh->disconnect;

# ---------------------------------------------------------------------------
# 2. A database of the file's own.
# ---------------------------------------------------------------------------

my @plain = PrivatePgDatabase->create('t108');
is_deeply lands_in(@plain), [ "dbio_t108_$$", $no_application_name ],
  'PrivatePgDatabase->create answers a login that leads into the database it made';

my $ODD = "dbio_t108 a;b_$$";
my @odd = PrivatePgDatabase->create('t108 a;b');
is_deeply lands_in(@odd), [ $ODD, $no_application_name ],
  q{... and into one whose name has a blank and a ';' in it};

# ---------------------------------------------------------------------------
# 3. From one database to another, however the first is written.
# ---------------------------------------------------------------------------

# The server of the test login, without the database and without the login.
my $SERVER = join ';',
  map  { "$_=" . quote_dsn_value($ci{$_}) }
  grep { !/\A(?:dbname|user|password)\z/ } sort keys %ci;

for my $case (
  [ 'dbname=, in single quotes',     "dbi:Pg:dbname='$ODD';$SERVER" ],
  [ 'dbname=, in double quotes',     qq{dbi:Pg:dbname="$ODD";$SERVER} ],
  [ 'db=, behind the server',        "dbi:Pg:$SERVER;db='$ODD'" ],
  [ q{database=, blanks around '='}, "dbi:Pg:database = '$ODD' ;$SERVER" ],
  [ 'a value in front that has dbname= and a ; in it',
    "dbi:Pg:application_name='dbname=$home;x';$SERVER;dbname='$ODD'", "dbname=$home;x" ],
) {
  my ($label, $written, $application_name) = @$case;
  $application_name //= $no_application_name;

  my %read = eval { my (undef, $pairs) = LiveServer->read_dsn($written); map { @$_ } @$pairs };
  is $read{dbname}, $ODD, "$label: read_dsn reads the database out of it"
    or diag $@;
  is_deeply lands_in($written, $user, $pass), [ $ODD, $application_name ],
    '... which is the database the server is in for that DSN';

  my $other = eval { LiveServer->dsn_with_dbname($written, "dbio_t108_$$") };
  ok defined $other, '... dsn_with_dbname names another database in it'
    or diag $@;
  is_deeply lands_in($other, $user, $pass), [ "dbio_t108_$$", $application_name ],
    '... and the server is in that one, every other parameter as it was';
}

is_deeply lands_in(LiveServer->dsn_with_dbname($plain[0], $ODD), $user, $pass),
  [ $ODD, $no_application_name ],
  q{and the other way: a name with a blank and a ';' is written so that the server is asked for it};

done_testing;
