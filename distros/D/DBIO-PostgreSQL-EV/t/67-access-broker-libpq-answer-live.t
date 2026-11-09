use strict;
use warnings;
use Test::More;

# LIVE: an AccessBroker whose answer carries a libpq parameter, through a
# schema connected with { async => 'ev' }, against a real PostgreSQL (karr
# k78, k81; core k298). The offline half,
# t/66-access-broker-libpq-answer-mock.t, pins who refuses what, where, and
# what EV::Pg is constructed with. This file asks the SERVER whether the
# parameter arrived.
#
# WHY: a parameter such as sslmode is given so that the connection is opened
# with it. The ways to give one differ in which half of a schema they reach.
# The plain one -- a hash of libpq parameters answered to every storage --
# reaches every connection of this transport and stops the owner's dbh: the
# sync storage would open it without the parameter, and with core k298 it
# refuses where it connects (the first use of its dbh, every reconnect), not
# at Schema->connect. "It connects" proves none of that: a connection opened
# WITHOUT the parameter connects just as well. So each claim here is made on
# something the server can only show when the parameter reached libpq:
#
#   - application_name: pg_stat_activity lists the backend under the name the
#     parameter gave it. Where nothing names one libpq takes PGAPPNAME, which
#     every case sets to a name of its own -- so a backend opened without the
#     parameter is seen too, under that name;
#   - sslmode, set to what this server cannot do: require where the server has
#     no TLS (libpq then refuses to connect: "server does not support SSL, but
#     SSL was required"), disable where it has (the backend is then listed
#     unencrypted in pg_stat_ssl, where a connection without the parameter
#     would be encrypted). The server is asked which (SHOW ssl).
#
# The cases:
#   a) the hash with a parameter, answered to every storage alike:
#      Schema->connect goes through and the server has no backend for it. A
#      pooled statement runs on a backend carrying the parameter, and so does
#      the listen connection; the case has no other backend, so the sync
#      storage connected for neither. The owner's dbh, when it is used, is
#      refused by the sync storage, naming the parameter and no value, and
#      again when it is used again; the server never sees a backend for it,
#      and pooled statements go on running. With sslmode in the hash too, the
#      pooled connection is opened as sslmode says, and the refusal of the
#      owner's dbh names both parameters;
#   b) the broker answers by the storage that asks (connect_info_for_storage):
#      this transport a hash with the parameter, the sync storage an answer
#      without. A pooled statement runs on a backend carrying the parameter,
#      and so does the listen connection; the owner's dbh is opened without
#      it. With sslmode in the transport's hash, the pooled connection is
#      opened as sslmode says and the owner's dbh is not affected;
#   c) the DBI form with the parameter in the DSN, one answer for every
#      storage: the owner's dbh and the pooled connection both carry it, and
#      with sslmode in the DSN both are opened as sslmode says;
#   d) a hash with a dsn key, the DBI form written as a hash and the answer
#      core's refusal in a) names as the way out: one answer for every
#      storage, like c). The owner's dbh and a pooled statement both run on a
#      backend carrying the parameter of the DSN, as the user of the hash, in
#      the database of the DSN, and so does the listen connection (karr k79;
#      before it the first pooled connection failed with libpq's 'invalid
#      connection option "dsn"').

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_$_" } qw( DSN USER PASS ) };
plan skip_all => 'Set DBIO_TEST_PG_USER and DBIO_TEST_PG_PASS: the broker hands out credentials'
  unless defined $user && length $user && defined $pass && length $pass;

use EV;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use DBIO::AccessBroker;
use DBIO::PostgreSQL::EV::Storage;
use DBIO::PostgreSQL::EV::ConnectInfo ();

alarm 120;

my $EV  = 'DBIO::PostgreSQL::EV::Storage';
my $TAG = "dbio_k78_$$";

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
my ($SSL, $DATABASE) = $observer->selectrow_array('SELECT current_setting(?), current_database()::text', undef, 'ssl');

# What this server cannot do for a connection: TLS where it has none, none
# where it has it. And what libpq or the server then shows.
my $SSLMODE     = $SSL eq 'on' ? 'disable' : 'require';
my $SSL_REFUSAL = qr/server does not support SSL, but SSL was required/;

# What the test DSN says about where to connect, read as DBD::Pg reads it
# (t/53-dbi-to-conninfo.t) -- without a login, which the brokers here give.
my %WHERE = %{ DBIO::PostgreSQL::EV::ConnectInfo::dbi_to_conninfo([ $dsn ])->[0] };
delete @WHERE{qw( user password )};

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
# what a connection in the making would need to arrive:
# [ pid, name, encrypted ] by pid.
sub backends {
  my (@names) = @_;
  wait_until(sub { 0 }, 0.3);
  return $observer->selectall_arrayref(
    'SELECT a.pid, a.application_name, COALESCE(s.ssl, false)::int
       FROM pg_catalog.pg_stat_activity a LEFT JOIN pg_catalog.pg_stat_ssl s USING (pid)
      WHERE a.application_name = ANY (?) ORDER BY a.pid',
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
  return $row // "$@";
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
  return $row // "$@";
}

sub encrypted {
  my ($pid) = @_;
  my ($ssl) = $observer->selectrow_array(
    'SELECT COALESCE(ssl, false)::int FROM pg_catalog.pg_stat_ssl WHERE pid = ?', undef, $pid,
  );
  return $ssl;
}

# A broker answering every storage alike, whatever the test puts in it.
{
  package AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

# A broker answering by the storage that asks: this transport {ev}, every
# other storage {dbi}.
{
  package PerStorageBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, %arg) = @_; bless { %arg }, $class }
  sub connect_info_for_storage {
    my ($self, $storage) = @_;
    my $answer = $self->{ $storage->isa('DBIO::PostgreSQL::EV::Storage') ? 'ev' : 'dbi' };
    return ref $answer eq 'HASH' ? { %$answer } : [ @$answer ];
  }
}

{
  package BrokerSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

sub hang_up {
  my ($schema) = @_;
  eval { $schema->storage->async->disconnect };
  eval { $schema->storage->disconnect };
  return;
}

# sslmode set to what the server cannot do, as it shows on one connection
# attempt: $got is the [ pid, ... ] row of a connection that was opened, or
# the error of one that was not.
sub opened_as_sslmode_says {
  my ($got, $what) = @_;
  if ($SSL eq 'on') {
    SKIP: {
      # A server that admits TLS connections only refuses the unencrypted one
      # by its access rules; that too is sslmode arriving, but in words that
      # depend on the server's pg_hba.conf.
      skip "the server admits no connection without TLS: $what cannot show sslmode => 'disable'", 1
        if !ref $got && $got =~ /pg_hba\.conf/;
      ok ref $got && !encrypted($got->[0]),
        "$what is opened unencrypted, as sslmode => 'disable' says, on a server that would encrypt it"
        or diag ref $got ? 'it is encrypted' : $got;
    }
  }
  else {
    like ref $got ? 'it connected' : $got, $SSL_REFUSAL,
      "$what is not opened: libpq refuses, as sslmode => 'require' says, a server without TLS";
  }
  return;
}

subtest 'a) the hash with a parameter, answered to every storage alike' => sub {
  my ($env_name, $param) = ("${TAG}_a_env", "${TAG}_a_param");
  local $ENV{PGAPPNAME} = $env_name;
  delete local $ENV{PGSSLMODE};

  my %answer = (
    (map { $_ => $WHERE{$_} } grep { defined $WHERE{$_} } qw( dbname host port )),
    user => $user, password => $pass, application_name => $param,
  );
  my $schema = eval { BrokerSchema->connect(AnswerBroker->new({ %answer }), { async => 'ev' }) };
  ok $schema, 'Schema->connect goes through' or diag $@;
  return unless $schema;
  my $storage = $schema->storage;
  is_deeply backends($env_name, $param), [], '... and the server has no backend for it';

  # What the parameter is given for: the transport's connections carry it.
  my $pool = pooled($storage);
  is_deeply [ ref $pool ? @{$pool}[1 .. 3] : $pool ], [ $user, $DATABASE, $param ],
    'a pooled statement runs on a backend the server lists under the application_name of the answer';
  eval { settle($storage->async->listen("${TAG}_a_channel" => sub { }), 'listen'); 1 } or diag $@;
  is_deeply [ map { $_->[1] } @{ backends($env_name, $param) } ], [ $param, $param ],
    '... the listen connection is a second backend under that name, and the case has no other: '
  . 'the sync storage connected for neither';

  # The owner's dbh is the sync storage's own connection, which it would open
  # without the parameter: refused where it is opened, every time.
  for my $use ('when it is used', 'used again') {
    my $dbh = owner($storage);
    like ref $dbh ? 'it connected' : $dbh,
      qr/AccessBroker AnswerBroker answered connect info with parameter\(s\) a DBI storage does not apply \(application_name\)/,
      "the owner's dbh, $use, is refused by the sync storage, naming the broker class and the parameter";
    unlike ref $dbh ? '' : $dbh, qr/\Q$param\E|\Q$pass\E/, '... and neither its value nor the password';
  }
  is_deeply [ map { $_->[1] } @{ backends($env_name, $param) } ], [ $param, $param ],
    '... and the server never saw a backend for it: none of the case is opened without the parameter';

  $pool = pooled($storage);
  is_deeply [ ref $pool ? @{$pool}[1 .. 3] : $pool ], [ $user, $DATABASE, $param ],
    'a pooled statement still runs after that, on a backend under the application_name of the answer';
  hang_up($schema);

  # The same with sslmode in the hash too.
  $schema = eval {
    BrokerSchema->connect(AnswerBroker->new({ %answer, sslmode => $SSLMODE }), { async => 'ev' })
  };
  ok $schema, "with sslmode => '$SSLMODE' in the hash too, Schema->connect goes through" or diag $@;
  return unless $schema;

  opened_as_sslmode_says(pooled($schema->storage), 'the pooled connection');
  my $dbh = owner($schema->storage);
  like ref $dbh ? 'it connected' : $dbh,
    qr/AccessBroker AnswerBroker answered connect info with parameter\(s\) a DBI storage does not apply \(application_name, sslmode\)/,
    '... while the owner\'s dbh is refused, naming both parameters';
  unlike ref $dbh ? '' : $dbh, qr/\Q$param\E|\Q$pass\E/, '... and neither the application_name nor the password';
  hang_up($schema);
};

subtest 'b) the broker answers by the storage that asks' => sub {
  my ($env_name, $param) = ("${TAG}_b_env", "${TAG}_b_param");
  local $ENV{PGAPPNAME} = $env_name;
  delete local $ENV{PGSSLMODE};

  my %ev = (%WHERE, user => $user, password => $pass, application_name => $param);
  my $broker = PerStorageBroker->new(ev => { %ev }, dbi => [ $dsn, $user, $pass ]);
  my $schema = eval { BrokerSchema->connect($broker, { async => 'ev' }) };
  ok $schema, 'Schema->connect goes through' or diag $@;
  return unless $schema;
  my $storage = $schema->storage;

  my $pool = pooled($storage);
  is_deeply [ ref $pool ? @{$pool}[1 .. 3] : $pool ], [ $user, $DATABASE, $param ],
    'a pooled statement runs on a backend the server lists under the application_name of the answer';

  eval { settle($storage->async->listen("${TAG}_b_channel" => sub { }), 'listen'); 1 } or diag $@;
  is scalar(grep { $_->[1] eq $param } @{ backends($env_name, $param) }), 2,
    '... and the listen connection is a second backend under that name';

  my $dbh = owner($storage);
  is_deeply [ ref $dbh ? @{$dbh}[1 .. 3] : $dbh ], [ $user, $DATABASE, $env_name ],
    'the owner\'s dbh is opened from the answer the sync storage got: under the name of the environment';
  hang_up($schema);

  # The same with sslmode in the transport's hash.
  $broker = PerStorageBroker->new(ev => { %ev, sslmode => $SSLMODE }, dbi => [ $dsn, $user, $pass ]);
  $schema = eval { BrokerSchema->connect($broker, { async => 'ev' }) };
  ok $schema, "with sslmode => '$SSLMODE' in the transport's hash, Schema->connect goes through" or diag $@;
  return unless $schema;

  opened_as_sslmode_says(pooled($schema->storage), 'the pooled connection');
  $dbh = owner($schema->storage);
  ok ref $dbh, '... while the owner\'s dbh, whose answer has no sslmode, connects' or diag $dbh;
  hang_up($schema);
};

subtest 'c) the DBI form with the parameter in the DSN, one answer for every storage' => sub {
  my ($env_name, $param) = ("${TAG}_c_env", "${TAG}_c_param");
  local $ENV{PGAPPNAME} = $env_name;
  delete local $ENV{PGSSLMODE};

  my $with   = "$dsn;application_name=$param";
  my $schema = eval { BrokerSchema->connect(AnswerBroker->new([ $with, $user, $pass ]), { async => 'ev' }) };
  ok $schema, 'Schema->connect goes through' or diag $@;
  return unless $schema;
  my $storage = $schema->storage;

  my $pool = pooled($storage);
  is_deeply [ ref $pool ? @{$pool}[1 .. 3] : $pool ], [ $user, $DATABASE, $param ],
    'a pooled statement runs on a backend under the application_name of the DSN';
  my $dbh = owner($storage);
  is_deeply [ ref $dbh ? @{$dbh}[1 .. 3] : $dbh ], [ $user, $DATABASE, $param ],
    '... and the owner\'s dbh is listed under it too: one answer, both halves';
  isnt ref $pool && $pool->[0], ref $dbh && $dbh->[0], '... two backends';
  is_deeply [ grep { $_->[1] eq $env_name } @{ backends($env_name, $param) } ], [],
    '... and none of the case under the name of the environment';
  hang_up($schema);

  # The same with sslmode in the DSN.
  $schema = eval {
    BrokerSchema->connect(AnswerBroker->new([ "$with;sslmode=$SSLMODE", $user, $pass ]), { async => 'ev' })
  };
  ok $schema, "with sslmode=$SSLMODE in the DSN, Schema->connect goes through" or diag $@;
  return unless $schema;

  opened_as_sslmode_says(pooled($schema->storage), 'the pooled connection');
  opened_as_sslmode_says(owner($schema->storage), 'the owner\'s dbh');
  hang_up($schema);
};

subtest 'd) a hash with a dsn key (karr k79)' => sub {
  my ($env_name, $param) = ("${TAG}_d_env", "${TAG}_d_param");
  local $ENV{PGAPPNAME} = $env_name;

  my $schema = eval {
    BrokerSchema->connect(
      AnswerBroker->new({ dsn => "$dsn;application_name=$param", user => $user, password => $pass }),
      { async => 'ev' },
    )
  };
  ok $schema, 'Schema->connect goes through' or diag $@;
  return unless $schema;
  my $storage = $schema->storage;

  my $dbh = owner($storage);
  is_deeply [ ref $dbh ? @{$dbh}[1 .. 3] : $dbh ], [ $user, $DATABASE, $param ],
    'the owner\'s dbh is opened from the DSN of the hash, its parameter included';

  # The transport reads the dsn key as the sync storage does, so a pooled
  # statement runs where the dbh's does, as the same user, and the parameter
  # of the DSN arrives: libpq is handed no parameter named dsn.
  my $pool = pooled($storage);
  unlike ref $pool ? 'it ran' : $pool, qr/invalid connection option "dsn"/,
    'a statement on the async API does not fail with libpq refusing a parameter named dsn';
  unlike ref $pool ? '' : $pool, qr/\Q$pass\E/, '... and whatever it fails with does not quote the password';
  is_deeply [ ref $pool ? @{$pool}[1 .. 3] : $pool ], [ $user, $DATABASE, $param ],
    '... it runs on a backend under the application_name of the DSN, as the user of the hash, in the database of the DSN';
  isnt ref $pool && $pool->[0], ref $dbh && $dbh->[0], '... a second backend beside the dbh\'s';

  eval { settle($storage->async->listen("${TAG}_d_channel" => sub { }), 'listen'); 1 } or diag $@;
  is scalar(grep { $_->[1] eq $param } @{ backends($env_name, $param) }), 3,
    '... and the listen connection is a third backend under that name';
  is_deeply [ grep { $_->[1] eq $env_name } @{ backends($env_name, $param) } ], [],
    '... none of the case under the name of the environment: no connection was opened without the DSN';

  hang_up($schema);
};

$observer->disconnect;

done_testing;
