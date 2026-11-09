use strict;
use warnings;
use Test::More;
use DBD::Pg;
use IPC::Open3 ();
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

alarm 60;

# OFFLINE test of t/lib/LiveServer.pm, karr k88: the same claims
# dbio-postgresql holds of its LiveServer (t/108-live-server.t there, karr
# k113), as far as this one has the same methods. Nothing is compared by
# reading the two files: what each does is measured.
#
# What this file claims:
#   1. login reads the three variables of the test login;
#   2. a connect that fails ends a file at its top level as one failed test
#      with a plan, reported at the line of the file, the reason a diagnostic
#      without the password -- the one in the DSN and the one given beside it
#      -- and with libpq's reason; from require_server and from control_dbh;
#   3. inside a subtest, which cannot end a file, it is thrown instead, in the
#      same words, and the file goes on behind the subtest;
#   4. the text does not name a line of the helper, which says nothing about
#      the test;
#   5. conninfo is the login as the transport reads it: user and password
#      among the parameters, a user beside the DSN wins over the one in it,
#      and DBI_USER / DBI_PASS stand for a user and a password the login
#      leaves undefined -- as DBI reads them for control_dbh, the transport
#      for static connect info and dbio-postgresql's helper for its conninfo
#      (maintainer's decision 2026-10-16, karr k88).

#
# WHAT RUNS FOR REAL: the helper, DBI, DBD::Pg and libpq up to a failing
# connect(2) on a unix socket directory that does not exist; a perl of its
# own that runs a test file of three lines. THE SUBSTITUTION: none.
#
# Not claimed, because this helper has nothing to claim it of: read_dsn,
# dsn_with_dbname, login_for_database (dbio-postgresql reads a DSN itself and
# writes a private database's name into it; here the transport reads the DSN,
# t/53-dbi-to-conninfo.t holds that against DBI and libpq, and no file
# diffs a whole database), and dbh_or_die (no END block or subtest of this
# distribution connects).

my $DEAD = '/nonexistent/dbio-postgresql-ev-k88';

# libpq reads its environment for what a connection string leaves out, and DBI
# its own for a user and a password not given: none of it is there.
delete @ENV{ grep { /^(?:PG|DBI_)/ } keys %ENV };

my @ENV_LOGIN = map { "DBIO_TEST_PG_$_" } qw( DSN USER PASS );
my @DEAD = ("dbi:Pg:dbname=appdb;host=$DEAD;password=GEHEIM-in-der-dsn", 'app', 'GEHEIM-als-argument');

# libpq's reason, by what no locale translates: the socket it tried.
my $SOCKET_TRIED = qr{\Q$DEAD\E/\.s\.PGSQL\.\d+};

# ---------------------------------------------------------------------------
# 1. The login of the environment.
# ---------------------------------------------------------------------------
{
  local @ENV{@ENV_LOGIN} = ('dbi:Pg:dbname=appdb;host=db.example', 'app', 's3cret');
  is_deeply [ LiveServer->login ], [ 'dbi:Pg:dbname=appdb;host=db.example', 'app', 's3cret' ],
    'login is DBIO_TEST_PG_DSN, _USER and _PASS';

  delete local @ENV{@ENV_LOGIN};
  is_deeply [ LiveServer->login ], [ undef, undef, undef ],
    '... and three undefined values where none is set';
}

# ---------------------------------------------------------------------------
# 2. A connect that fails, at the top level of a file.
# ---------------------------------------------------------------------------
sub run_file {
  my ($code) = @_;
  local @ENV{@ENV_LOGIN} = @DEAD;
  my $pid = IPC::Open3::open3(my $in, my $out, undef,
    $^X, (map { "-I$_" } grep { !ref } @INC),
    '-MTest::More', '-MLiveServer', '-e', $code);
  close $in;
  my $output = do { local $/; <$out> };
  waitpid $pid, 0;
  return ($output, $? >> 8);
}

SKIP: {
  skip "$DEAD exists on this machine", 32 if -e $DEAD;

  for my $case (
    [ 'require_server', 'LiveServer->require_server;' ],
    [ 'control_dbh',    'my $dbh = LiveServer->control_dbh(attrs => { PrintWarn => 0 });' ],
  ) {
    my ($method, $call) = @$case;
    my ($output, $exit) = run_file(
      qq{pass 'before'; $call pass 'REACHED-BEHIND-IT'; done_testing;});

    like $output, qr/^ok 1 - before\nnot ok 2 - the server DBIO_TEST_PG_DSN names takes a connection$/m,
      "$method, no server behind the DSN: the file fails one test";
    like $output, qr/^#\s+at -e line 1\.$/m, '... reported at the line of the file, not at one in t/lib';
    like $output, qr/^1\.\.2$/m, '... with a plan';
    isnt $exit, 0, '... and a failing exit status';
    unlike $output, qr/REACHED-BEHIND-IT/, '... and ends there';
    like $output, qr/^# .*$SOCKET_TRIED/m, q{... libpq's reason is a diagnostic};
    unlike $output, qr/GEHEIM/, '... and no password anywhere in what the file wrote';
    unlike $output, qr/LiveServer\.pm line/, '... and no line of the helper, which says nothing about the file';
  }

# ---------------------------------------------------------------------------
# 3. ... and inside a subtest, which cannot end the file.
# ---------------------------------------------------------------------------
  subtest 'inside a subtest, which cannot end the file' => sub {
    local @ENV{@ENV_LOGIN} = @DEAD;
    my $dbh = eval { LiveServer->control_dbh };
    my $err = "$@";
    ok !$dbh, 'control_dbh throws';
    like $err, $SOCKET_TRIED, q{... libpq's reason};
    unlike $err, qr/GEHEIM/, '... without a password';
    unlike $err, qr/LiveServer\.pm line/, '... and without a line of the helper';
  };
  pass 'and the file went on behind the subtest';
}

# ---------------------------------------------------------------------------
# 5. The login of the environment, read.
# ---------------------------------------------------------------------------
{
  local @ENV{@ENV_LOGIN} = (q{dbi:Pg:db='app;db';host=db.example;port=5433}, 'app', 's3cret');
  is_deeply { LiveServer->conninfo },
    { dbname => 'app;db', host => 'db.example', port => '5433', user => 'app', password => 's3cret' },
    'conninfo: the parameters the login makes, user and password among them';

  local $ENV{DBIO_TEST_PG_PASS};
  local $ENV{DBIO_TEST_PG_DSN} = 'dbi:Pg:dbname=appdb;user=dsn-user;password=dsn-pw';
  local $ENV{DBIO_TEST_PG_USER} = 'app';
  is_deeply { LiveServer->conninfo },
    { dbname => 'appdb', user => 'app', password => 'dsn-pw' },
    'conninfo: a user given beside the DSN wins over the one in it, a password not given does not';

  # DBI takes DBI_USER and DBI_PASS for a user and a password not given, so
  # control_dbh connects as DBI_USER; so does the transport for static connect
  # info (ConnectInfo's env => 1, karr k66), and so does dbio-postgresql's
  # helper. conninfo reads them the same way, or a pool connected from it and
  # the control dbh beside it log in as two different users (karr k88,
  # maintainer's decision 2026-10-16). Until then this held that conninfo did
  # not read them.
  local @ENV{@ENV_LOGIN} = ('dbi:Pg:dbname=appdb;host=db.example', undef, undef);
  local @ENV{qw( DBI_USER DBI_PASS )} = ('env-user', 'env-pw');
  is_deeply { LiveServer->conninfo },
    { dbname => 'appdb', host => 'db.example', user => 'env-user', password => 'env-pw' },
    'conninfo: DBI_USER and DBI_PASS stand for a login user and password left undefined';

  # Only for what is undefined: a login that gives them wins, as with DBI.
  local @ENV{@ENV_LOGIN} = ('dbi:Pg:dbname=appdb', 'app', 's3cret');
  is_deeply { LiveServer->conninfo },
    { dbname => 'appdb', user => 'app', password => 's3cret' },
    '... and a login user and password win over them';

  # An empty user is defined: DBI keeps it, and so does the transport (no
  # user parameter at all -- libpq's default).
  local @ENV{@ENV_LOGIN} = ('dbi:Pg:dbname=appdb', '', '');
  is_deeply { LiveServer->conninfo }, { dbname => 'appdb' },
    '... and an empty login user and password are given: DBI_USER is not read for them';
}

done_testing;
