use strict;
use warnings;
use Test::More;

# LIVE: a database named by value is the database the sync storage opens
# (karr k102). The offline half, t/106-connect-params-dsn.t, pins the DSN
# written for every kind of value and has the real libpq read a host out of
# it; this file shows a real server being asked for the name as it was given.
#
# WHY: with connection parameters instead of a DSN -- a connect-info hash with
# a dbname, or a DBIO::AccessBroker::Static -- the sync storage wrote the
# value into the DSN as it came. Measured against this server before the fix:
#   * a name with a blank did not connect (libpq: missing "=" after ...);
#   * a name with an apostrophe took the host behind it into the name, and
#     libpq went to its default socket instead of the server named;
#   * a name with a backslash was asked for without it;
#   * a name in double quotes was asked for without them -- the neighbour
#     database was opened;
#   * 'name application_name=x' opened name and set application_name: any
#     libpq parameter could ride in behind a database name;
# while the future_io transport of the same schema opened the database named
# in every one of these cases.
#
# What this file claims, for each such name:
#   1. the sync storage, connected with a connect-info hash, is in the
#      database of exactly that name, and nothing but the name was set;
#   2. the same through a Static broker;
#   3. the future_io transport opens the same database from the same broker.
#
# Every database is this file's own (dbio_k102_<pid>...), created here and
# dropped at END. Gated like the other live tests: DBIO_TEST_PG_DSN, _USER
# and _PASS.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBIO::Util ();
use DBIO::AccessBroker::Static;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

my $HAVE_FUTURE_IO = eval { require DBIO::PostgreSQL::Storage::Async; 1 };

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# The parameters need the server's host and port out of the DSN: the DSN read
# as DBD::Pg and libpq read it, not taken apart here (karr k113).
my %part = LiveServer->conninfo;
# The DSN is named without a password it may carry (karr k111).
plan skip_all => 'cannot take the host out of the test DSN: '
  . DBIO::Util::mask_connect_secrets($dsn, [ $dsn, $user, $pass ])
  unless defined $part{host};

my @SERVER = (host => $part{host}, (defined $part{port} ? (port => $part{port}) : ()));

{
  package K102::LiveSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

my $P = "dbio_k102_$$";

# [ what is special about it, the name, a neighbour the name must not become ]
my @NAMES = (
  [ 'a blank',                       "$P my db" ],
  [ 'an apostrophe',                 "${P}_it's" ],
  [ 'a backslash',                   "${P}_back\\slash" ],
  [ q{'db=', which DBD::Pg rewrites}, "$P-db=1" ],
  [ 'double quotes around it',       qq{"${P}_q"},                    "${P}_q" ],
  [ 'a libpq parameter behind it',   "${P}_p application_name=k102",  "${P}_p" ],
);

my @created;
my $admin = LiveServer->control_dbh(attrs => { PrintWarn => 0 });

END {
  if ($admin) {
    for my $name (@created) {
      eval { $admin->do('DROP DATABASE IF EXISTS ' . $admin->quote_identifier($name) . ' WITH (FORCE)') };
    }
    $admin->disconnect;
  }
}

for my $name (map { @$_[1 .. $#$_] } @NAMES) {
  push @created, $name;
  $admin->do('CREATE DATABASE ' . $admin->quote_identifier($name));
}

# What libpq sets by itself: the application_name of a connection that names
# none. A parameter that came in behind a database name would differ from it.
my ($NO_APPLICATION_NAME) = $admin->selectrow_array(q{SELECT current_setting('application_name')});

my $WHERE = q{SELECT current_database(), current_setting('application_name')};

# Why a connect failed, in libpq's or the server's words: without the DSN and
# the user DBI repeats in front of them, without the host and the password.
sub reason {
  my ($err) = @_;
  $err = DBIO::Util::mask_connect_secrets("$err", [ $dsn, $user, $pass ]);
  $err =~ s/\A.*?DBI connect\(.*?\) failed: //s;
  $err =~ s/connection to server at .*?, port \d+ failed: //s;
  $err =~ s/\Q$part{host}\E/<host>/g;
  $err =~ s/ at \S+ line \d+.*//s;
  return $err;
}

sub sync_hash {
  my ($name) = @_;
  my $schema = K102::LiveSchema->connect({ dbname => $name, @SERVER, user => $user, password => $pass });
  my @row = $schema->storage->dbh->selectrow_array($WHERE);
  $schema->storage->disconnect;
  return \@row;
}

sub broker_for {
  my ($name) = @_;
  return DBIO::AccessBroker::Static->new(dbname => $name, @SERVER, username => $user, password => $pass);
}

sub sync_broker {
  my ($name) = @_;
  my $schema = K102::LiveSchema->connect(broker_for($name));
  my @row = $schema->storage->dbh->selectrow_array($WHERE);
  $schema->storage->disconnect;
  return \@row;
}

sub future_io {
  my ($name) = @_;
  my $async = DBIO::PostgreSQL::Storage::Async->new(undef);
  $async->connect_info([ broker_for($name) ]);
  my $conn = $async->_create_pool_connection($async->_async_broker_conninfo('write'));
  my @row = $conn->{dbh}->selectrow_array($WHERE);
  $conn->{dbh}->disconnect;
  return \@row;
}

for my $case (@NAMES) {
  my ($label, $name) = @$case;
  my $want = [ $name, $NO_APPLICATION_NAME ];

  is_deeply scalar eval { sync_hash($name) }, $want,
    "a database name with $label: the sync storage, from a connect-info hash, is in that database, and only the name was set"
    or diag reason($@);
  is_deeply scalar eval { sync_broker($name) }, $want,
    '... and from a Static broker'
    or diag reason($@);

  SKIP: {
    skip 'DBIO::Async not installed (recommends only) -- future_io transport unavailable', 1
      unless $HAVE_FUTURE_IO;
    is_deeply scalar eval { future_io($name) }, $want,
      '... and the future_io transport opens the same database from the same broker'
      or diag reason($@);
  }
}

done_testing;
