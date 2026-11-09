use strict;
use warnings;
use Test::More;

# LIVE: a connection parameter given beside an AccessBroker, against a real
# PostgreSQL (karr k76, k81; core k307). The offline half,
# t/68-access-broker-parameters-beside-mock.t, pins the refusal, its measure
# and what is left of a storage after it. This file asks the SERVER what was
# opened, and when:
#
#   MyApp::Schema->connect($broker, { async => 'ev', sslmode => 'require' })
#
# WHY it matters: the parameter beside the broker was dropped, so the pool
# connected without it and the application ran. Refusing is only better if the
# refusal is complete -- no backend of the transport exists that was opened
# without the parameter -- and if the caller knows when to expect it. Through
# a schema the transport is built at the first ->async, not at connect, and
# the owning sync storage is not this distribution's: so what happens between
# the two is measured here rather than assumed.
#
# The backends are told apart by application_name. libpq takes it from
# PGAPPNAME where nothing else names it, so each case sets its own, and a
# backend opened without the parameter is seen under that name. Given beside
# the broker as the parameter itself, it shows on the server who applied it:
# a backend opened WITH it carries the parameter's value.
#
#   a) application_name beside a broker:
#      - Schema->connect goes through, and the server has no backend for it;
#      - the first ->async is refused, naming application_name and neither its
#        value nor the password, and again when asked again; a statement on the
#        async API is refused the same way; the server still has no backend;
#      - the owner's dbh, when it is used, is refused too -- by the owning sync
#        storage, which is core's (core k307): it would open its connection
#        without the parameter. The refusal names application_name, says that
#        it stands beside the broker, and holds neither its value nor the
#        password; it comes again when the dbh is used again. So a caller who
#        never uses the async API is told as well, at the first use of the dbh
#        and not at connect;
#      - after that the transport is still refused, and the server has no
#        backend of the case at all: neither half opened one without the
#        parameter;
#   b) sslmode beside a broker, set to what this server cannot do (require
#      without TLS, disable with it): refused like (a), by the transport and
#      for the owner's dbh, and the server has no backend for it -- whatever
#      it would have made of a connection opened without sslmode;
#   c) the transport addressed directly, [ $broker, { application_name => ... } ]:
#      refused when given the connect info, a statement on it afterwards fails
#      for the same reason, and the server has no backend for it;
#   d) the control: the same broker with a DBD attribute and pool_size beside
#      it and no parameter is connected, pooled statements run, under the name
#      of the environment -- the refusal is about the parameter.

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

alarm 120;

my $EV  = 'DBIO::PostgreSQL::EV::Storage';
my $TAG = "dbio_k76_$$";

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
my ($SSL) = $observer->selectrow_array('SHOW ssl');

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

# A broker answering whatever the test puts in it: here the DBI form, which
# both halves of a schema connect from.
{
  package AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

{
  package BrokerSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

sub broker { AnswerBroker->new([ $dsn, $user, $pass ]) }

# The transport is asked for, and a statement on the async API: both refused,
# naming $name and no value.
sub transport_is_refused {
  my ($storage, $name, $value, $when) = @_;
  for my $ask ('->async', '->async again') {
    my $async = eval { $storage->async };
    my $err   = "$@";
    ok !$async, "$when, $ask: no transport is handed out";
    like $err, qr/PostgreSQL ev does not apply connection parameter\(s\) given beside an AccessBroker \(\Q$name\E\)/,
      "... the refusal names $name";
    unlike $err, qr/\Q$value\E|\Q$pass\E/, '... and neither its value nor the password';
  }
  my $f   = eval { $storage->select_async(\'(SELECT 1 AS one) me', [ 'one' ]) };
  my $err = $f ? (eval { settle($f, 'select_async'); 1 } ? '' : "$@") : "$@";
  like $err, qr/given beside an AccessBroker \(\Q$name\E\)/, "$when: a statement on the async API is refused the same way";
  return;
}

# The owner's dbh is used, and used again: both times refused by the sync
# storage, naming $name and no value.
sub owner_is_refused {
  my ($storage, $name, $value) = @_;
  for my $use ('when it is used', 'used again') {
    my $dbh = eval { $storage->dbh };
    my $err = "$@";
    ok !$dbh, "the owner's dbh, $use: no dbh";
    like $err, qr/A DBI storage does not apply parameter\(s\) given beside AccessBroker AnswerBroker \(\Q$name\E\)/,
      "... the sync storage refuses, naming $name and that it stands beside the broker";
    unlike $err, qr/\Q$value\E|\Q$pass\E/, '... and neither its value nor the password';
  }
  return;
}

sub hang_up {
  my ($schema) = @_;
  eval { $schema->storage->disconnect };
  return;
}

subtest 'a) application_name beside a broker' => sub {
  my ($env_name, $param) = ("${TAG}_a_env", "${TAG}_a_param");
  local $ENV{PGAPPNAME} = $env_name;

  my $schema = eval { BrokerSchema->connect(broker(), { async => 'ev', application_name => $param }) };
  ok $schema, 'Schema->connect goes through: the transport is not built yet' or diag $@;
  return unless $schema;
  my $storage = $schema->storage;

  is_deeply backends($env_name, $param), [], '... and the server has no backend for it';

  transport_is_refused($storage, 'application_name', $param, 'before anything connected');
  is_deeply backends($env_name, $param), [], 'the server still has no backend: the refusal opened nothing';

  # The owning sync storage (core's) applies nothing of the parameter to its
  # own connection either, and does not open it (core k307).
  owner_is_refused($storage, 'application_name', $param);
  is_deeply backends($env_name, $param), [],
    '... and the server has no backend for it: no dbh is opened without the parameter';

  transport_is_refused($storage, 'application_name', $param, 'after the dbh was refused');
  is_deeply backends($env_name, $param), [],
    'the server has no backend of the case at all: neither half opened one without the parameter';

  hang_up($schema);
};

subtest 'b) sslmode beside a broker' => sub {
  my $tag = "${TAG}_b";
  local $ENV{PGAPPNAME} = $tag;
  delete local $ENV{PGSSLMODE};

  # What this server cannot do for a connection without TLS / with it.
  my $sslmode = $SSL eq 'on' ? 'disable' : 'require';

  my $schema = eval { BrokerSchema->connect(broker(), { async => 'ev', sslmode => $sslmode }) };
  ok $schema, "Schema->connect with sslmode => '$sslmode' beside the broker goes through" or diag $@;
  return unless $schema;
  my $storage = $schema->storage;

  transport_is_refused($storage, 'sslmode', $sslmode, 'before anything connected');
  is_deeply backends($tag), [], 'the server has no backend for it';

  # The owner's dbh, as in (a): refused before the server is asked, so on a
  # server with TLS as on one without.
  owner_is_refused($storage, 'sslmode', $sslmode);
  is_deeply backends($tag), [], '... and the server still has no backend for it';

  hang_up($schema);
};

subtest 'c) the transport addressed directly' => sub {
  my ($env_name, $param) = ("${TAG}_c_env", "${TAG}_c_param");
  local $ENV{PGAPPNAME} = $env_name;

  my $s   = $EV->new(undef);
  my $ok  = eval { $s->connect_info([ broker(), { application_name => $param } ]); 1 };
  my $err = "$@";
  ok !$ok, '[ $broker, { application_name => ... } ] is refused';
  like $err, qr/given beside an AccessBroker \(application_name\)/, '... naming application_name';
  unlike $err, qr/\Q$param\E|\Q$pass\E/, '... and neither its value nor the password';

  my $f = eval { $s->select_async(\'(SELECT 1 AS one) me', [ 'one' ]) };
  $err  = $f ? (eval { settle($f, 'select_async'); 1 } ? '' : "$@") : "$@";
  like $err, qr/given beside an AccessBroker \(application_name\)/,
    'a statement on the storage afterwards fails for the same reason';
  is_deeply backends($env_name, $param), [], '... and the server has no backend for it';

  eval { $s->disconnect };
};

subtest 'd) control: a DBD attribute and pool_size beside the broker, no parameter' => sub {
  my $tag = "${TAG}_d";
  local $ENV{PGAPPNAME} = $tag;

  my $schema = BrokerSchema->connect(broker(), { async => 'ev', pool_size => 2, pg_enable_utf8 => 1 });
  my $async  = eval { $schema->storage->async };
  isa_ok $async, $EV, 'the transport' or diag $@;

  SKIP: {
    skip 'the transport was refused', 2 unless $async;
    my ($row) = eval { settle($async->select_async(
      'pg_catalog.pg_stat_activity', [ 'usename', 'application_name' ], { pid => \'= pg_backend_pid()' },
    ), 'select_async') };
    is_deeply $row, [ $user, $tag ], 'a pooled statement runs, on a backend under the name of the environment'
      or diag $@;
    is scalar @{ backends($tag) }, 1, '... the one backend of the case';
    eval { $async->disconnect };
  }

  hang_up($schema);
};

$observer->disconnect;

done_testing;
