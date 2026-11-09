use strict;
use warnings;
use Test::More;

# OFFLINE test: a whole DSN that names no target is refused when a connection
# is made, on the sync storage and on the future_io transport (karr k121,
# point 21; maintainer's decision 2026-10-22).
#
# WHY: 'dbi:Pg:' (or 'dbi:Pg:;', or a DSN with only 'sslmode=require') went
# to DBI->connect as it was, and libpq filled in whatever PGHOST, PGDATABASE,
# PGPORT or a service file said -- the credentials went where the process
# environment pointed, as they did for connection parameters that named
# nothing until t/154 refused those. service= and hostaddr= name a target
# themselves and are enough (future_io has held that since f39df20).
#
# What this file claims:
#   1. Util::dsn_names_target reads a DSN as DBD::Pg and libpq do: ';' and
#      whitespace separate, quotes and backslashes in values, db= and
#      database= for dbname, an empty value is none;
#   2. the sync storage refuses at the connection -- for a DSN string, for
#      the dsn key of a hash and for the answer of an AccessBroker -- before
#      DBI->connect, with the three parameters named and not the password;
#      and a schema that only generates SQL still connects with 'dbi:Pg:';
#   3. the same DSN is refused by future_io, as a DBIO::Exception naming the
#      caller's file, and a DSN naming a target gets through to DBI->connect.
#
# WHAT RUNS FOR REAL: core's connect-info normalisation, the broker attach and
# this dist's storages. THE SUBSTITUTION: DBI->connect counts its calls.

use DBI;
use DBIO::AccessBroker;
use DBIO::PostgreSQL::Util qw(dsn_names_target);

my $HAVE_FUTURE_IO = eval { require DBIO::PostgreSQL::Storage::Async; 1 };
my $NO_FUTURE_IO   = 'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

{
  package K121b::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');

  package K121b::Broker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

my $SECRET = 'hunter2-s3cret';

my @NO_TARGET = (
  'dbi:Pg:',
  'dbi:Pg:;',
  'dbi:Pg:  ',
  "dbi:Pg:;\n;",
  'DBI:Pg:',
  'dbi:Pg(PrintError=>0):',
  'dbi:Pg:sslmode=require',
  'dbi:Pg:sslmode=require;application_name=x',
  'dbi:Pg:dbname=',
  q{dbi:Pg:dbname='';host=},
  'dbi:Pg:user=app;options=-c',
);
my @TARGET = (
  'dbi:Pg:dbname=app',
  'dbi:Pg:host=db.example',
  'dbi:Pg:port=5433',
  'dbi:Pg:service=prod',
  'dbi:Pg:hostaddr=192.0.2.1',
  'dbi:Pg:db=app',
  'dbi:Pg:database=app',
  'dbi:Pg:DBNAME=app',
  'dbi:Pg:sslmode=require;host=db.example',
  'dbi:Pg:dbname=app host=db.example',
  q{dbi:Pg:dbname='my db'},
  'dbi:Pg:dbname=a\\ b',
  'dbi:Pg:postgresql://app@db.example/appdb',
  'dbi:Pg(PrintError=>0):dbname=app',
);

# 1. the reading of a DSN
ok !dsn_names_target($_), "names no target: $_" for @NO_TARGET;
ok  dsn_names_target($_), "names a target: $_" for @TARGET;
# a keyword that is only inside a quoted value is no parameter
ok !dsn_names_target(q{dbi:Pg:application_name='dbname=x host=y'}),
  'a parameter name inside a quoted value is no parameter';

sub refusal_ok {
  my ($err, $label) = @_;
  like $err, qr/dbname/, "$label: names dbname";
  like $err, qr/host/,   '... host';
  like $err, qr/port/,   '... and port';
  unlike $err, qr/\Q$SECRET\E/, '... and not the password';
}

# 2. the sync storage
{
  my $connects = 0;
  no warnings 'redefine';
  local *DBI::connect = sub { $connects++; die "DBI->connect was reached\n" };

  for my $dsn (@NO_TARGET) {
    for my $way (
      [ 'a DSN string', sub {
          K121b::Schema->connect($dsn, 'app', $SECRET)->storage->dbh } ],
      [ 'the dsn key of a hash', sub {
          K121b::Schema->connect({ dsn => $dsn, user => 'app', password => $SECRET })->storage->dbh } ],
      [ 'an AccessBroker answering the DBI form', sub {
          K121b::Schema->connect(K121b::Broker->new([ $dsn, 'app', $SECRET ]))->storage->dbh } ],
      [ 'an AccessBroker answering a hash with a dsn', sub {
          K121b::Schema->connect(K121b::Broker->new({ dsn => $dsn, user => 'app', password => $SECRET }))->storage->dbh } ],
    ) {
      my ($from, $code) = @$way;
      $connects = 0;
      my $ok = eval { $code->(); 1 };
      my $err = "$@";
      ok !$ok, "'$dsn' from $from: refused";
      refusal_ok($err, "'$dsn' from $from");
      unlike $err, qr/DBI->connect was reached/, '... before DBI->connect';
      is $connects, 0, '... and nothing was sent to DBI->connect';
    }
  }

  # A DSN with a target gets to DBI->connect.
  for my $dsn (@TARGET) {
    $connects = 0;
    my $ok = eval { K121b::Schema->connect($dsn, 'app', $SECRET)->storage->dbh; 1 };
    ok !$ok, "'$dsn': DBI->connect is reached";
    like "$@", qr/DBI->connect was reached/, '... and it is what stopped the connect';
    is $connects, 1, '... once';
  }
  {
    $connects = 0;
    my $ok = eval {
      K121b::Schema->connect(K121b::Broker->new([ 'dbi:Pg:service=prod', 'app', $SECRET ]))->storage->dbh; 1 };
    ok !$ok && $connects == 1, 'a broker answering a DSN with a service: DBI->connect is reached';
  }

  # A schema that only generates SQL connects without a target and opens
  # nothing: the refusal is for a connection, not for connect info.
  $connects = 0;
  my $schema = eval { K121b::Schema->connect('dbi:Pg:') };
  ok $schema, "connect('dbi:Pg:') for a schema that only writes SQL is still allowed" or diag $@;
  my $sql = eval { $schema->storage->sql_maker->select('t', ['*'], {}) };
  ok defined $sql, '... and writes SQL' or diag $@;
  is $connects, 0, '... without a connection';
}

# 3. future_io
SKIP: {
  skip $NO_FUTURE_IO, 4 * @NO_TARGET + 4 + 2 * @TARGET unless $HAVE_FUTURE_IO;

  my $connects = 0;
  no warnings 'redefine';
  local *DBI::connect = sub { $connects++; die "DBI->connect was reached\n" };

  my $s = DBIO::PostgreSQL::Storage::Async->new(undef);
  for my $dsn (@NO_TARGET) {
    $connects = 0;
    my $ok = eval { $s->_pg_connect({ dsn => $dsn, user => 'app', password => $SECRET }); 1 };
    my $err = $@;
    ok !$ok, "future_io, '$dsn': refused";
    isa_ok $err, 'DBIO::Exception';
    like "$err", qr/174-dsn-without-target\.t/, '... naming the caller\'s file';
    is $connects, 0, '... before DBI->connect';
  }
  {
    my $err = eval { $s->_pg_connect({ dsn => 'dbi:Pg:', user => 'app', password => $SECRET }); 1 } ? '' : "$@";
    refusal_ok($err, 'future_io');
  }
  for my $dsn (@TARGET) {
    $connects = 0;
    eval { $s->_pg_connect({ dsn => $dsn, user => 'app', password => $SECRET }) };
    like "$@", qr/DBI->connect was reached/, "future_io, '$dsn': DBI->connect is reached";
    is $connects, 1, '... once';
  }
}

done_testing;
