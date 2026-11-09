use strict;
use warnings;
use Test::More;

# OFFLINE test of t/lib/LiveServer.pm, the one way a live test of this
# distribution opens a DBI connection of its own (karr k113).
#
# WHY: the live files connected with DBI->connect($dsn, $user, $pass,
# { RaiseError => 1 }) from DBIO_TEST_PG_DSN. A connect that fails has DBI
# quote the DSN, and with it a password the DSN carries -- into the test log,
# from some twenty files. And t/lib/PrivatePgDatabase.pm put the name of its
# database into the DSN with s/(dbname|database|db)=[^;]+/.../: a quoted
# value with a ';' in it was cut in two, and a dbname= inside another value
# was taken for the parameter.
#
# What this file claims:
#   1. login reads the three variables of the test login;
#   2. a connect that fails is thrown as a text without the password -- the
#      one in the DSN and the one given as the third argument -- and with
#      libpq's reason; no attribute of the caller makes DBI print it instead;
#   3. at the top level of a file such a connect ends the file as one failed
#      test with a plan, the reason a diagnostic without the password -- from
#      require_server, from control_dbh and from PrivatePgDatabase->create;
#      inside a subtest, which cannot end a file, it is thrown;
#   4. read_dsn reads a DSN as DBD::Pg and libpq do, and
#   5. the real DBD::Pg and libpq agree, where that can be asked without a
#      server: the socket directory libpq tries is the host read_dsn read;
#   6. dsn_with_dbname names another database in a DSN and leaves every other
#      parameter what it was -- for quoted values and for the db= and
#      database= spellings too -- and what it cannot read it refuses, without
#      repeating it;
#   7. conninfo and login_for_database work on the login of the environment.
#
# WHAT RUNS FOR REAL: the helper, DBI, DBD::Pg and libpq up to a failing
# connect(2) on a unix socket directory that does not exist; in 3 a perl of
# its own that runs a test file of three lines.
# THE SUBSTITUTION: none.

use DBI;
use DBD::Pg;
use IPC::Open3 ();
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

# A unix socket directory that does not exist: the only place a connection of
# this file may be tried at.
my $DEAD = '/nonexistent/dbio-postgresql-k113';

# libpq reads its environment for what a connection string leaves out, and DBI
# its own for a user and a password not given: none of it is there.
delete @ENV{ grep { /^(?:PG|DBI_)/ } keys %ENV };

alarm 60;

my @ENV_LOGIN = map { "DBIO_TEST_PG_$_" } qw( DSN USER PASS );

my $DEAD_DSN = "dbi:Pg:dbname=appdb;host=$DEAD;password=GEHEIM-in-der-dsn";
my @DEAD     = ($DEAD_DSN, 'app', 'GEHEIM-als-argument');

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
# 2. A connect that fails, thrown.
# ---------------------------------------------------------------------------
SKIP: {
  skip "$DEAD exists on this machine", 13 if -e $DEAD;

  for my $case (
    [ 'the attributes of the helper',                {} ],
    [ 'RaiseError off and PrintError on',            { RaiseError => 0, PrintError => 1 } ],
    [ 'a HandleError that takes the error',          { HandleError => sub { 1 } } ],
  ) {
    my ($label, $attrs) = @$case;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $dbh = eval { LiveServer->dbh_or_die(login => \@DEAD, attrs => $attrs) };
    my $err = "$@";
    if ($dbh) {
      $dbh->disconnect;
      BAIL_OUT('a connection was opened -- this file must never reach a server');
    }

    like $err, $SOCKET_TRIED, "a connect that fails, with $label: thrown, with libpq's reason";
    unlike $err, qr/GEHEIM/, '... without the password of the DSN and without the one given as an argument';
    is_deeply \@warnings, [], '... and DBI printed nothing';
  }

  my $err = do { eval { LiveServer->dbh_or_die(login => \@DEAD) }; "$@" };
  like $err, qr/\Qdbname=appdb;host=$DEAD;password=***\E/,
    'the DSN is still in the text, its password as ***';
  like $err, qr/'app'/, '... and the user';
  unlike $err, qr/LiveServer\.pm line/, '... and no line of the helper, which says nothing about the file';
  like $err, qr/\n\z/, '... which ends in a newline: nothing is appended to it';
}

# ---------------------------------------------------------------------------
# 3. A connect that fails, at the top level of a file and inside a subtest.
# ---------------------------------------------------------------------------

# Runs a test file of its own, with the login of the dead server in its
# environment: its output, stdout and stderr together, and its exit status.
sub run_file {
  my ($code) = @_;
  local @ENV{@ENV_LOGIN} = @DEAD;
  my $pid = IPC::Open3::open3(my $in, my $out, undef,
    $^X, (map { "-I$_" } grep { !ref } @INC),
    '-MTest::More', '-MLiveServer', '-MPrivatePgDatabase', '-e', $code);
  close $in;
  my $output = do { local $/; <$out> };
  waitpid $pid, 0;
  return ($output, $? >> 8);
}

SKIP: {
  skip "$DEAD exists on this machine", 26 if -e $DEAD;

  for my $case (
    [ 'require_server', 'LiveServer->require_server;' ],
    [ 'control_dbh',    'my $dbh = LiveServer->control_dbh(attrs => { PrintWarn => 0 });' ],
    [ 'PrivatePgDatabase->create', 'my @db = PrivatePgDatabase->create(q{t108});' ],
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
    like $output, qr/\Qpassword=***\E/, '... the password of the DSN in it as ***';
    unlike $output, qr/GEHEIM/, '... and no password anywhere in what the file wrote';
  }

  subtest 'inside a subtest, which cannot end the file' => sub {
    my $dbh = eval { LiveServer->control_dbh(login => \@DEAD) };
    my $err = "$@";
    ok !$dbh, 'control_dbh throws';
    like $err, $SOCKET_TRIED, q{... libpq's reason};
    unlike $err, qr/GEHEIM/, '... without a password';
  };
  pass 'and the file went on behind the subtest';
}

# ---------------------------------------------------------------------------
# 4. A DSN, read as DBD::Pg and libpq read it.
# ---------------------------------------------------------------------------

sub pairs_of {
  my ($dsn) = @_;
  my ($head, $pairs) = LiveServer->read_dsn($dsn);
  return [ $head, map { @$_ } @$pairs ];
}

for my $case (
  [ 'plain parameters',
    'dbi:Pg:dbname=appdb;host=db.example;port=5433',
    [ 'dbi:Pg:', dbname => 'appdb', host => 'db.example', port => '5433' ] ],
  [ q{a quoted value with a ';' and a blank in it},
    q{dbi:Pg:dbname='a;b c';host=db.example},
    [ 'dbi:Pg:', dbname => 'a;b c', host => 'db.example' ] ],
  [ q{an escaped quote and an escaped backslash in a quoted value},
    q{dbi:Pg:dbname='it\\'s \\\\ here';host=db.example},
    [ 'dbi:Pg:', dbname => q{it's \\ here}, host => 'db.example' ] ],
  [ 'a backslash in a bare value',
    q{dbi:Pg:dbname=a\\ b;host=db.example},
    [ 'dbi:Pg:', dbname => 'a b', host => 'db.example' ] ],
  [ 'a dbname in double quotes, the way DBD::Pg allows it',
    q{dbi:Pg:dbname="my db";host=db.example},
    [ 'dbi:Pg:', dbname => 'my db', host => 'db.example' ] ],
  [ 'db= for dbname=',
    'dbi:Pg:db=appdb;host=db.example',
    [ 'dbi:Pg:', dbname => 'appdb', host => 'db.example' ] ],
  [ 'database= for dbname=',
    'dbi:Pg:host=db.example;database=appdb',
    [ 'dbi:Pg:', host => 'db.example', dbname => 'appdb' ] ],
  [ q{blanks around the '=' and between the parameters},
    'dbi:Pg:dbname = appdb ; host= db.example',
    [ 'dbi:Pg:', dbname => 'appdb', host => 'db.example' ] ],
  [ q{a parameter given twice: both, in their order},
    'dbi:Pg:dbname=a;host=db.example;dbname=b',
    [ 'dbi:Pg:', dbname => 'a', host => 'db.example', dbname => 'b' ] ],
  [ q{dbname= inside another value is that value},
    q{dbi:Pg:application_name='my dbname=x';dbname=appdb},
    [ 'dbi:Pg:', application_name => 'my dbname=x', dbname => 'appdb' ] ],
  [ 'DBI attributes in front of the DSN',
    'dbi:Pg(PrintWarn=>0,AutoCommit=>1):dbname=appdb',
    [ 'dbi:Pg(PrintWarn=>0,AutoCommit=>1):', dbname => 'appdb' ] ],
  [ 'DBI: in capitals',
    'DBI:Pg:dbname=appdb',
    [ 'DBI:Pg:', dbname => 'appdb' ] ],
  [ 'no parameter at all',
    'dbi:Pg:',
    [ 'dbi:Pg:' ] ],
  [ 'an empty quoted value',
    q{dbi:Pg:application_name='';host=db.example},
    [ 'dbi:Pg:', application_name => '', host => 'db.example' ] ],
) {
  my ($label, $dsn, $want) = @$case;
  is_deeply scalar eval { pairs_of($dsn) }, $want, "read_dsn, $label"
    or diag $@;
}

# ---------------------------------------------------------------------------
# 5. The real DBD::Pg and libpq, without a server: the host they read.
#
# A connect to a unix socket directory that does not exist fails in
# connect(2), and libpq's error names the socket path it tried -- the host as
# it read it. Every host below is under that directory, however it is written.
# ---------------------------------------------------------------------------

# The socket directory in libpq's own words -- socket "<dir>/.s.PGSQL.<port>"
# -- and not the DSN that DBI repeats in front of them.
sub socket_dir_tried {
  my ($error) = @_;
  return defined $error && $error =~ m{socket "(\Q$DEAD\E.*?)/\.s\.PGSQL\.\d+"}s ? $1 : undef;
}

SKIP: {
  my @forms = (
    [ 'bare',                                "dbi:Pg:dbname=appdb;host=$DEAD/plain" ],
    [ q{quoted, with a ';'},                 "dbi:Pg:dbname=appdb;host='$DEAD/a;b'" ],
    [ 'quoted, with a blank',                "dbi:Pg:host='$DEAD/my dir';dbname=appdb" ],
    [ 'quoted, with an escaped quote and a ; behind it', "dbi:Pg:host='$DEAD/it\\'s;here';dbname=appdb" ],
    [ 'bare, with an escaped blank',         "dbi:Pg:host=$DEAD/a\\ b;dbname=appdb" ],
    [ q{with blanks around the '='},         "dbi:Pg:host = $DEAD/x ;dbname=appdb" ],
    [ 'given twice',                         "dbi:Pg:host=$DEAD/first;dbname=appdb;host=$DEAD/second" ],
    [ q{with 'db=' in it, which DBD::Pg rewrites}, "dbi:Pg:host='$DEAD/db=1';application_name=k113" ],
    [ 'behind a dbname in double quotes',    qq{dbi:Pg:dbname="my;db";host=$DEAD/behind} ],
  );
  skip "$DEAD exists on this machine", scalar @forms if -e $DEAD;

  for my $form (@forms) {
    my ($label, $dsn) = @$form;

    my $dbh = eval { LiveServer->dbh_or_die(login => [ $dsn, 'app', 's3cret' ]) };
    my $tried = socket_dir_tried("$@");
    if ($dbh) {
      $dbh->disconnect;
      BAIL_OUT('a connection was opened -- this file must never reach a server');
    }

    my %read = eval { my (undef, $pairs) = LiveServer->read_dsn($dsn); map { @$_ } @$pairs };
    ok defined $tried && defined $read{host} && $read{host} eq $tried,
      "a host $label: read_dsn reads what libpq itself went to"
      or diag 'libpq: ' . ($tried // 'undef') . "\nread_dsn: " . ($read{host} // 'undef') . "\n$@";
  }
}

# ---------------------------------------------------------------------------
# 6. Another database in a DSN.
# ---------------------------------------------------------------------------

for my $case (
  [ 'a plain DSN',
    'dbi:Pg:dbname=appdb;host=db.example;port=5433', 'priv',
    'dbi:Pg:dbname=priv;host=db.example;port=5433' ],
  [ 'a DSN that names no database: it is added',
    'dbi:Pg:host=db.example', 'priv',
    'dbi:Pg:host=db.example;dbname=priv' ],
  [ q{a quoted name with a ';' in it},
    q{dbi:Pg:dbname='a;b';host=db.example}, 'priv',
    'dbi:Pg:dbname=priv;host=db.example' ],
  [ 'a name in double quotes',
    q{dbi:Pg:dbname="my db";host=db.example}, 'priv',
    'dbi:Pg:dbname=priv;host=db.example' ],
  [ 'a name with an escaped quote',
    q{dbi:Pg:dbname='it\\'s';host=db.example}, 'priv',
    'dbi:Pg:dbname=priv;host=db.example' ],
  [ 'db=',
    'dbi:Pg:db=appdb;host=db.example', 'priv',
    'dbi:Pg:dbname=priv;host=db.example' ],
  [ 'database=, behind the host',
    'dbi:Pg:host=db.example;database=appdb', 'priv',
    'dbi:Pg:host=db.example;dbname=priv' ],
  [ q{blanks around the '='},
    'dbi:Pg:host=db.example;dbname = appdb', 'priv',
    'dbi:Pg:host=db.example;dbname=priv' ],
  [ 'a database named twice: once, where the first stood',
    'dbi:Pg:dbname=a;host=db.example;dbname=b', 'priv',
    'dbi:Pg:dbname=priv;host=db.example' ],
  [ 'dbname= inside another value: that value stays',
    q{dbi:Pg:application_name='my dbname=x';dbname=appdb}, 'priv',
    q{dbi:Pg:application_name='my dbname\\=x';dbname=priv} ],
  [ q{a quoted password with a ';' in it: it stays},
    q{dbi:Pg:password='se;cret pw';dbname=appdb;host=db.example}, 'priv',
    q{dbi:Pg:password='se;cret pw';dbname=priv;host=db.example} ],
  [ 'a value with blanks and a parameter of its own',
    q{dbi:Pg:dbname=appdb;options='-c search_path=app'}, 'priv',
    q{dbi:Pg:dbname=priv;options='-c search_path\\=app'} ],
  [ 'DBI attributes in front of the DSN: they stay',
    'dbi:Pg(PrintWarn=>0):dbname=appdb', 'priv',
    'dbi:Pg(PrintWarn=>0):dbname=priv' ],
  [ 'no parameter at all',
    'dbi:Pg:', 'priv',
    'dbi:Pg:dbname=priv' ],
  [ q{a new name with a blank and a ';': written quoted},
    'dbi:Pg:dbname=appdb;host=db.example', 'my db;1',
    q{dbi:Pg:dbname='my db;1';host=db.example} ],
) {
  my ($label, $dsn, $name, $want) = @$case;

  my $got = eval { LiveServer->dsn_with_dbname($dsn, $name) };
  is $got, $want, "dsn_with_dbname, $label"
    or diag $@;

  # read back, it is the DSN it was with the one parameter changed
  my %before = eval { my (undef, $pairs) = LiveServer->read_dsn($dsn); (map { @$_ } @$pairs), dbname => $name };
  my %after  = eval { my (undef, $pairs) = LiveServer->read_dsn($got); map { @$_ } @$pairs };
  is_deeply \%after, \%before, '... and read back, every other parameter is what it was'
    or diag $@;
}

for my $case (
  [ 'an undefined DSN',                undef,                                             qr/dbi:Pg:/ ],
  [ 'a DSN of another driver',         'dbi:mysql:database=appdb;password=GEHEIM',        qr/dbi:Pg:/ ],
  [ 'a string that is no DBI DSN',     'dbname=appdb password=GEHEIM',                    qr/dbi:Pg:/ ],
  [ 'a quote that is not closed',      q{dbi:Pg:dbname='appdb;host=db.example;password=GEHEIM}, qr/quote/ ],
  [ q{a parameter without '='},        'dbi:Pg:dbname=appdb;password=GEHEIM;GEHEIM',      qr/"="/ ],
  [ 'a connection URI',                'dbi:Pg:postgresql://app:GEHEIM@db.example/appdb', qr/URI/ ],
) {
  my ($label, $dsn, $why) = @$case;
  my $ok  = eval { LiveServer->dsn_with_dbname($dsn, 'priv'); 1 };
  my $err = "$@";
  ok !$ok, "dsn_with_dbname refuses $label";
  like $err, $why, '... saying what is wrong with it';
  unlike $err, qr/GEHEIM/, '... and not what is in it';
}

for my $case ([ 'an undefined name', undef ], [ 'an empty name', '' ]) {
  my ($label, $name) = @$case;
  ok !eval { LiveServer->dsn_with_dbname('dbi:Pg:dbname=appdb', $name); 1 },
    "dsn_with_dbname refuses $label";
}

# ---------------------------------------------------------------------------
# 7. The login of the environment, read.
# ---------------------------------------------------------------------------
{
  local @ENV{@ENV_LOGIN} = (q{dbi:Pg:db='app;db';host=db.example;port=5433}, 'app', 's3cret');

  is_deeply { LiveServer->conninfo },
    { dbname => 'app;db', host => 'db.example', port => '5433', user => 'app', password => 's3cret' },
    'conninfo: the parameters the login makes, user and password among them';

  is_deeply [ LiveServer->login_for_database('dbio_t108_1') ],
    [ 'dbi:Pg:dbname=dbio_t108_1;host=db.example;port=5433', 'app', 's3cret' ],
    'login_for_database: the login, for another database of the same server';

  local $ENV{DBIO_TEST_PG_PASS};
  local $ENV{DBIO_TEST_PG_DSN} = 'dbi:Pg:dbname=appdb;user=dsn-user;password=dsn-pw';
  local $ENV{DBIO_TEST_PG_USER} = 'app';
  is_deeply { LiveServer->conninfo },
    { dbname => 'appdb', user => 'app', password => 'dsn-pw' },
    'conninfo: a user given beside the DSN wins over the one in it, a password not given does not';
}

done_testing;
