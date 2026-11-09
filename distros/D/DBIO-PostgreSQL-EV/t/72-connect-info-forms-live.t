use strict;
use warnings;
use Test::More;

# LIVE: connect info in every form the owning sync storage reads, through a
# schema connected with { async => 'ev' }, against a real PostgreSQL (karr
# k64, k66). The offline half, t/71-connect-info-forms-mock.t, pins what
# EV::Pg is constructed with for each form and what is refused; a broker's
# hash answer with a dsn key is asked of the server in
# t/67-access-broker-libpq-answer-live.t. This file asks the SERVER where the
# two halves of one schema ended up.
#
# WHY: a schema's dbh and its pool are opened from the same connect info, by
# two readers -- DBI and DBD::Pg for the dbh, this transport for the pool and
# the listen connection. They must end up in the same database as the same
# user (karr k58), and the transport read only one of the forms the owner
# reads. Schema->connect({ dsn => 'dbi:Pg:...', user => ..., password => ...,
# async => 'ev' }) connected the dbh, and the first pooled statement failed
# with libpq's 'invalid connection option "dsn"'. A DSN with DBI attributes in
# front, 'dbi:Pg(RaiseError=>1):...', connected the dbh and stopped the first
# ->async. And with DBI's Username attribute the dbh was opened as that user
# and the pool as the one beside the DSN.
#
# "It connects" proves little: a connection opened from something else than
# the connect info -- libpq's environment, the user beside the DSN -- connects
# as well. So each claim is made on what the server can only show when the
# connect info was read:
#
#   - the user and the database of the backend, as pg_stat_activity lists it;
#   - application_name, given in the DSN. Where nothing names one libpq takes
#     PGAPPNAME, which every case sets to a name of its own -- so a backend
#     opened without the DSN's parameters is seen too, under that name;
#   - for DBI's Username and Password: the user and password beside the DSN
#     are ones the server refuses, so a connection opened with them is none.
#
# Per form: a statement over the owner's dbh and one over the pool run on two
# backends, both as the user and in the database the connect info means, both
# under the application_name of the DSN; the listen connection is a third
# backend under that name; and the case has no backend under the name of the
# environment.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_$_" } qw( DSN USER PASS ) };
plan skip_all => 'Set DBIO_TEST_PG_USER and DBIO_TEST_PG_PASS: the forms here carry a login'
  unless defined $user && length $user && defined $pass && length $pass;
plan skip_all => 'the test DSN has DBI attributes or a login of its own; this file writes its own around the parameters'
  unless $dsn =~ /^dbi:Pg:(?!.*\b(?:user|password)\s*=)/is;

use EV;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use DBIO::PostgreSQL::EV::Storage;
use DBIO::Util ();
use DBIO::PostgreSQL::EV::ConnectInfo ();

alarm 120;

my $EV  = 'DBIO::PostgreSQL::EV::Storage';
my $TAG = "dbio_k64_$$";

# What follows 'dbi:Pg:' in the test DSN, and what it says about where to
# connect, read as DBD::Pg reads it (t/53-dbi-to-conninfo.t).
(my $PARAMS = $dsn) =~ s/^dbi:Pg://i;
my %WHERE = %{ DBIO::PostgreSQL::EV::ConnectInfo::dbi_to_conninfo([ $dsn ])->[0] };

# The server's view, from a connection that belongs to no case.
# A server that is not there fails the file here, with a plan (karr k77).
my $observer = LiveServer->control_dbh(application_name => "${TAG}_observer");
{
  my ($seen_as) = $observer->selectrow_array(
    'SELECT application_name FROM pg_catalog.pg_stat_activity WHERE pid = pg_backend_pid()'
  );
  plan skip_all => 'the test DSN sets an application_name of its own; this file tells its backends apart by PGAPPNAME'
    unless defined $seen_as && $seen_as eq "${TAG}_observer";
}
my ($DATABASE) = $observer->selectrow_array('SELECT current_database()::text');

# Run the EV loop until $cond holds or $timeout passes. Never open-ended.
sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = EV::time() + ($timeout // 10);
  until ($cond->()) {
    return 0 if EV::time() > $deadline;
    my $tick = EV::timer(0.02, 0, sub { });
    EV::run(EV::RUN_ONCE());
  }
  return 1;
}

# get, bounded: a Future that does not settle fails instead of hanging. Dies
# with the Future's failure.
sub settle {
  my ($f, $what) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(15, 0, sub { $f->fail("watchdog: $what still pending after 15s\n") unless $f->is_ready });
  $dog->keepalive(0);
  return $f->get;
}

# Every backend the server has under one of these application names, after
# what a connection in the making would need to arrive: [ pid, name ] by pid.
sub backends {
  my (@names) = @_;
  wait_until(sub { 0 }, 0.3);
  return $observer->selectall_arrayref(
    'SELECT pid, application_name FROM pg_catalog.pg_stat_activity
      WHERE application_name = ANY (?) ORDER BY pid',
    undef, \@names,
  );
}

# One statement on the async API of the schema's storage, answered by the
# pooled backend that ran it about itself: [ pid, user, database, name ]. The
# error instead, as a string, when it fails; the pool's warning about a
# connection it could not open is kept out of the test output.
sub pooled {
  my ($storage) = @_;
  local $SIG{__WARN__} = sub { };
  my ($row) = eval {
    settle($storage->select_async(
      'pg_catalog.pg_stat_activity', [ 'pid', 'usename', 'datname', 'application_name' ],
      { pid => \'= pg_backend_pid()' },
    ), 'select_async')
  };
  return $row // DBIO::Util::mask_connect_secrets("$@", [ $dsn, $user, $pass ]);
}

# The owner's dbh: [ pid, user, database, name ], or the error as a string.
sub owner {
  my ($storage) = @_;
  my $row = eval {
    $storage->dbh->selectrow_arrayref(
      'SELECT pid, usename::text, datname::text, application_name
         FROM pg_catalog.pg_stat_activity WHERE pid = pg_backend_pid()'
    )
  };
  return $row // DBIO::Util::mask_connect_secrets("$@", [ $dsn, $user, $pass ]);
}

{
  package FormSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

sub hang_up {
  my ($schema) = @_;
  eval { $schema->storage->async->disconnect };
  eval { $schema->storage->disconnect };
  return;
}

# A user and a password the server refuses: where DBI's Username and Password
# attributes are read they are never used.
my @NOBODY = ("${TAG}_nobody", 'not-the-password');

# DBI splits the attributes in front of a DSN at '=', '=>' and ',', trims
# blanks around those, and ends them at the first '):' -- a user or password
# holding one of these cannot be written there.
my $writable = !grep { /[=,\s]|\)/ } $user, $pass;

# [ label, sub ($param): the arguments of connect for a DSN carrying
#   application_name=$param, whether the DSN's application_name reaches the
#   owner's dbh, the pool size the form gives, what it needs ]
my @FORMS = (
  [ 'a) a hash with a dsn key',
    sub { { dsn => "$dsn;application_name=$_[0]", user => $user, password => $pass, async => 'ev' } }, 1, 5 ],
  [ 'b) a hash with a dsn key, attributes of the owner\'s and a pool size',
    sub { { dsn => "$dsn;application_name=$_[0]", user => $user, password => $pass, async => 'ev',
            AutoCommit => 1, RaiseError => 1, pg_enable_utf8 => 1, quote_names => 1, pool_size => 2 } }, 1, 2 ],
  [ 'c) a hash whose dbname is the DSN',
    sub { { dbname => "$dsn;application_name=$_[0]", user => $user, password => $pass, async => 'ev' } }, 1, 5 ],
  [ 'd) a DSN with DBI attributes in front',
    sub { ("dbi:Pg(RaiseError=>1,PrintError=>0):$PARAMS;application_name=$_[0]", $user, $pass, { async => 'ev' }) }, 1, 5 ],
  [ 'e) DBI\'s Username and Password in front of the DSN, a login the server refuses beside it',
    sub { ("dbi:Pg(Username=>$user,Password=>$pass):$PARAMS;application_name=$_[0]", @NOBODY, { async => 'ev' }) }, 1, 5,
    $writable ],
  [ 'f) DBI\'s Username and Password among the attributes, a login the server refuses beside the DSN',
    sub { ("$dsn;application_name=$_[0]", @NOBODY, { async => 'ev', Username => $user, Password => $pass }) }, 1, 5 ],
  [ 'g) a hash with a dsn key and DBI\'s Username and Password, a login the server refuses for its user and password',
    sub { { dsn => "$dsn;application_name=$_[0]", user => $NOBODY[0], password => $NOBODY[1],
            Username => $user, Password => $pass, async => 'ev' } }, 1, 5 ],
  # A hash of connection parameters is read by the owner for dbname, host and
  # port alone, so it carries no application_name to the dbh: both halves are
  # listed under the name of the environment.
  [ 'h) a hash of connection parameters and attributes of the owner\'s',
    sub { +{ (map { $_ => $WHERE{$_} } grep { defined $WHERE{$_} } qw( dbname host port )),
            user => $user, password => $pass, async => 'ev',
            AutoCommit => 1, RaiseError => 1, pg_enable_utf8 => 1, quote_names => 1 } }, 0, 5 ],
);

# A postgresql:// URI in the DSN's rest (karr k66): the host, the port and the
# database of the test DSN, the login in front of the host, percent-encoded,
# and application_name in the query. libpq takes it whole for the dbh; the
# transport reads it to parameters (t/53 section 8 holds that against libpq).
sub pct { my ($v) = @_; $v =~ s/([^A-Za-z0-9._~-])/sprintf '%%%02X', ord $1/ge; $v }
sub uri_for {
  my ($param, $login) = @_;
  my $host = $WHERE{host} // '';
  $host = "[$host]" if $host =~ /:/;
  return 'postgresql://' . ($login ? pct($login->[0]) . ':' . pct($login->[1]) . '@' : '')
    . $host . (defined $WHERE{port} ? ":$WHERE{port}" : '')
    . '/' . pct($WHERE{dbname} // '') . '?application_name=' . pct($param);
}
push @FORMS,
  [ 'i) a postgresql:// URI in the DSN, the login percent-encoded in it',
    sub { ('dbi:Pg:' . uri_for($_[0], [ $user, $pass ]), undef, undef, { async => 'ev' }) }, 1, 5,
    defined $WHERE{dbname} && length $WHERE{dbname} ];

for my $form (@FORMS) {
  my ($label, $build, $named_by_dsn, $pool_size, $can) = @$form;

  subtest $label => sub {
    plan skip_all => 'the test user or password cannot be written among the DBI attributes of a DSN'
      if @$form > 4 && !$can;

    (my $case = $label) =~ s/\).*//;
    my ($env_name, $param) = ("${TAG}_${case}_env", "${TAG}_${case}_param");
    local $ENV{PGAPPNAME} = $env_name;
    delete local @ENV{qw( DBI_DSN DBI_USER DBI_PASS PGUSER PGPASSWORD PGDATABASE )};
    my $name = $named_by_dsn ? $param : $env_name;

    my $schema = eval { FormSchema->connect($build->($param)) };
    ok $schema, 'Schema->connect goes through' or diag DBIO::Util::mask_connect_secrets("$@", [ $dsn, $user, $pass ]);
    return unless $schema;
    my $storage = $schema->storage;

    my $dbh = owner($storage);
    is_deeply [ ref $dbh ? @{$dbh}[1 .. 3] : $dbh ], [ $user, $DATABASE, $name ],
      'a statement over the owner\'s dbh runs as the user and in the database the connect info means';

    my $pool = pooled($storage);
    is_deeply [ ref $pool ? @{$pool}[1 .. 3] : $pool ], [ $user, $DATABASE, $name ],
      'a statement over the pool runs as the same user, in the same database, with the same parameters';
    isnt ref $pool && $pool->[0], ref $dbh && $dbh->[0], '... on a backend of its own';
    is scalar eval { $storage->async->pool->max_size }, $pool_size, "... of a pool of $pool_size";

    eval { settle($storage->async->listen("${TAG}_${case}_channel" => sub { }), 'listen'); 1 }
      or diag DBIO::Util::mask_connect_secrets("$@", [ $dsn, $user, $pass ]);
    my @mine = @{ backends($env_name, $param) };
    is scalar(grep { $_->[1] eq $name } @mine), 3,
      '... and the listen connection is a third backend under the same name';
    is scalar(@mine), 3, '... the case has no other backend: none was opened from anything but the connect info';

    hang_up($schema);
  };
}

# The login beside a URI counts over the one in it, as beside keyword=value
# parameters: the URI names a login the server refuses, the real one stands
# beside it, and the pool runs as that one. The dbh is not part of this: it
# appends what stands beside to the URI, libpq then reads none, and the dbh
# is not opened.
subtest 'j) a postgresql:// URI, the login beside it' => sub {
  plan skip_all => 'the test DSN names no database' unless defined $WHERE{dbname} && length $WHERE{dbname};
  local $ENV{PGAPPNAME} = "${TAG}_j_env";
  delete local @ENV{qw( DBI_DSN DBI_USER DBI_PASS PGUSER PGPASSWORD PGDATABASE )};

  my $schema = FormSchema->connect(
    'dbi:Pg:' . uri_for("${TAG}_j_param", \@NOBODY), $user, $pass, { async => 'ev' },
  );
  my $row = pooled($schema->storage);
  is_deeply [ ref $row ? @{$row}[1 .. 3] : $row ], [ $user, $DATABASE, "${TAG}_j_param" ],
    'the pool runs as the user beside the URI, in the database and under the name the URI gives';
  hang_up($schema);
};

# k) dbi:Pg: with nothing behind it (dbio-postgresql k121 P21, karr k95): the
# sync storage refuses it loudly where it opens its dbh, instead of letting
# libpq take the target from PGHOST and PGDATABASE. The environment names the
# test server here, and the refusal comes all the same. The message names what
# is missing and carries neither the user nor the password.
subtest 'k) dbi:Pg: with nothing behind it, a user and a password: the owner refuses it, whatever the environment names' => sub {
  plan skip_all => 'the test DSN names no database' unless defined $WHERE{dbname} && length $WHERE{dbname};
  local $ENV{PGAPPNAME} = "${TAG}_k_env";
  delete local @ENV{qw( DBI_DSN DBI_USER DBI_PASS PGUSER PGPASSWORD )};
  local $ENV{PGDATABASE} = $WHERE{dbname};
  local $ENV{PGHOST} = $WHERE{host} if defined $WHERE{host};
  local $ENV{PGPORT} = $WHERE{port} if defined $WHERE{port};

  my $schema = FormSchema->connect('dbi:Pg:', $user, $pass, { async => 'ev' });
  my $dbh = owner($schema->storage);
  ok !ref $dbh, 'the owner opens no dbh: its answer is the error';
  like $dbh, qr/names no dbname, host or port/, '... which names what the DSN lacks';
  unlike $dbh, qr/\Q$pass\E/, '... and does not carry the password' if length $pass;
  hang_up($schema);
};

# karr k66 (a), (d): libpq fills what is missing from PGHOST, PGPORT and
# PGDATABASE, for the dbh and for the pool alike. The login is not among them:
# core reads neither DBI_USER nor DBI_PASS any more (core k392), so the user and
# the password are given explicitly, and the environment holds none.
for my $case (
  [ 'l) a DSN with the parameters, the user and password given explicitly',
    sub { [ $dsn, $user, $pass, { async => 'ev' } ] },
    {} ],
) {
  my ($label, $build, $env) = @$case;
  subtest $label => sub {
    plan skip_all => 'the test DSN names no database' unless defined $WHERE{dbname} && length $WHERE{dbname};
    (my $c = $label) =~ s/\).*//;
    local $ENV{PGAPPNAME} = "${TAG}_${c}_env";
    delete local @ENV{qw( DBI_DSN DBI_USER DBI_PASS PGUSER PGPASSWORD PGDATABASE PGHOST PGPORT )};
    local @ENV{ keys %$env } = values %$env;
    local $ENV{PGDATABASE} = $WHERE{dbname};
    local $ENV{PGHOST} = $WHERE{host} if defined $WHERE{host};
    local $ENV{PGPORT} = $WHERE{port} if defined $WHERE{port};
    # a DSN with parameters needs none of the above, and has them anyway

    my $schema = FormSchema->connect(@{ $build->() });
    my $dbh = owner($schema->storage);
    is_deeply [ ref $dbh ? @{$dbh}[1 .. 3] : $dbh ], [ $user, $DATABASE, "${TAG}_${c}_env" ],
      'a statement over the owner\'s dbh runs as the user, in the database the environment names';
    my $pool = pooled($schema->storage);
    is_deeply [ ref $pool ? @{$pool}[1 .. 3] : $pool ], [ $user, $DATABASE, "${TAG}_${c}_env" ],
      'a statement over the pool runs as the same user, in the same database';
    hang_up($schema);
  };
}

$observer->disconnect;

done_testing;
