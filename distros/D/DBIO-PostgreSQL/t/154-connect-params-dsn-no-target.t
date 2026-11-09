use strict;
use warnings;
use Test::More;

# OFFLINE test: connection parameters that name no database, no host and no
# port are refused (karr k121, point 21; maintainer's decision).
#
# WHY: a Static broker (or a connect-info hash) with only a user and a
# password built the DSN "dbi:Pg:". DBD::Pg hands that to libpq, and libpq
# fills in whatever PGHOST, PGDATABASE, PGPORT or a service file say -- so
# where the credentials went was decided by the process environment, not by
# the program. A connection that names nothing is refused instead, loudly,
# naming dbname, host and port; the credentials never appear in the message.
#
# What this file claims:
#   1. the seam _connect_params_dsn refuses an empty parameter set, and one
#      whose parts are all undefined or empty (nothing is written for those);
#   2. any one of dbname, host or port is enough and builds its DSN;
#   3. through a connect-info hash and through a Static broker the sync
#      storage refuses, never reaches DBI->connect, and the message names the
#      three parameters and not the password;
#   4. the future_io transport refuses the same answer in the same terms, as a
#      DBIO::Exception naming the caller's file, and accepts one part.
#
# WHAT RUNS FOR REAL: core's connect-info normalisation, the broker attach and
# this dist's seams. THE SUBSTITUTION: DBI->connect counts its calls.

use DBI;
use DBIO::AccessBroker::Static;
use DBIO::PostgreSQL::Storage;

my $HAVE_FUTURE_IO = eval { require DBIO::PostgreSQL::Storage::Async; 1 };
my $NO_FUTURE_IO   = 'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

{
  package K121::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

my $SECRET = 'hunter2-s3cret';

sub refusal_ok {
  my ($err, $label) = @_;
  like $err, qr/dbname/, "$label: names dbname";
  like $err, qr/host/,   '... host';
  like $err, qr/port/,   '... and port';
  unlike $err, qr/\Q$SECRET\E/, '... and not the password';
}

# 1. the seam
for my $case (
  [ 'nothing given',          {} ],
  [ 'only undefined parts',   { dbname => undef, host => undef, port => undef } ],
  [ 'only empty parts',       { host => '', port => '' } ],
) {
  my ($label, $params) = @$case;
  my $dsn = eval { DBIO::PostgreSQL::Storage->_connect_params_dsn('Pg', $params) };
  ok !defined $dsn, "_connect_params_dsn, $label: no DSN";
  refusal_ok("$@", "_connect_params_dsn, $label");
}

# 2. one part is enough
for my $case (
  [ dbname => { dbname => 'appdb' },        'dbi:Pg:dbname=appdb' ],
  [ host   => { host   => 'db.example' },   'dbi:Pg:host=db.example' ],
  [ port   => { port   => 5433 },           'dbi:Pg:port=5433' ],
) {
  my ($what, $params, $want) = @$case;
  is scalar eval { DBIO::PostgreSQL::Storage->_connect_params_dsn('Pg', $params) },
    $want, "only $what given: runs" or diag $@;
}

# 3. through a whole connect
{
  my $connects = 0;
  no warnings 'redefine';
  local *DBI::connect = sub { $connects++; die "DBI->connect was reached\n" };

  for my $way (
    [ 'a connect-info hash', sub {
        K121::Schema->connect({ user => 'app', password => $SECRET })->storage->dbh } ],
    [ 'a Static broker', sub {
        K121::Schema->connect(
          DBIO::AccessBroker::Static->new(username => 'app', password => $SECRET),
        )->storage->dbh } ],
  ) {
    my ($from, $code) = @$way;
    $connects = 0;
    my $ok = eval { $code->(); 1 };
    ok !$ok, "no target, from $from: the sync storage does not connect";
    if ($from eq 'a Static broker') {
      refusal_ok("$@", "from $from");
    }
    else {
      # core refuses a hash without dsn or dbname before this seam is asked
      like "$@", qr/Connect info without a DSN/, "from $from: refused by core";
      unlike "$@", qr/\Q$SECRET\E/, '... and not the password';
    }
    is $connects, 0, '... and nothing was sent to DBI->connect';
  }
}

# 4. future_io
SKIP: {
  skip $NO_FUTURE_IO, 12 unless $HAVE_FUTURE_IO;

  my $conninfo = sub {
    my (%param) = @_;
    my $s = DBIO::PostgreSQL::Storage::Async->new(undef);
    $s->connect_info([
      DBIO::AccessBroker::Static->new(%param, username => 'app', password => $SECRET),
    ]);
    return $s->_async_broker_conninfo('write');
  };

  my $ok = eval { $conninfo->(); 1 };
  my $err = $@;
  ok !$ok, 'future_io: a Static broker with credentials only is refused';
  isa_ok $err, 'DBIO::Exception';
  like "$err", qr/154-connect-params-dsn-no-target\.t/, '... naming the caller\'s file';
  refusal_ok("$err", 'future_io');

  is eval { $conninfo->(host => 'db.example')->{dsn} }, 'dbi:Pg:host=db.example',
    'future_io: only host given: runs' or diag $@;
  is eval { $conninfo->(dbname => 'appdb')->{dsn} }, 'dbi:Pg:dbname=appdb',
    'future_io: only dbname given: runs' or diag $@;
  # Static answers only dbname, host and port; a broker answering other libpq
  # parameters is a hash of its own.
  {
    package K121::HashBroker;
    use base 'DBIO::AccessBroker';
    sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
    sub connect_info_for { $_[0]{answer} }
  }
  my $hash_dsn = sub {
    my (%param) = @_;
    my $s = DBIO::PostgreSQL::Storage::Async->new(undef);
    $s->connect_info([
      K121::HashBroker->new({ %param, user => 'app', password => $SECRET }),
    ]);
    return $s->_async_broker_conninfo('write')->{dsn};
  };
  is eval { $hash_dsn->(service => 'prod') }, 'dbi:Pg:service=prod',
    'future_io: only service given: runs' or diag $@;
  is eval { $hash_dsn->(hostaddr => '192.0.2.1') }, 'dbi:Pg:hostaddr=192.0.2.1',
    'future_io: only hostaddr given: runs' or diag $@;
  ok !eval { $hash_dsn->(sslmode => 'require'); 1 },
    'future_io: only sslmode given: still refused';
}

done_testing;
