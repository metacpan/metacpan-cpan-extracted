use strict;
use warnings;
use Test::More;

# LIVE: the connect options beside an AccessBroker on the ev transport, against
# a real PostgreSQL (karr k60; core k240 / k243 / k245). The offline half,
# t/51-access-broker-connect-options-mock.t, pins what EV::Pg is constructed
# with and what the pool's max_size accessor answers. Neither is what a user
# sizes a pool for. This file asks the SERVER:
#
#   MyApp::Schema->connect($broker, { async => 'ev', pool_size => 3, ... })
#
# WHY it matters: pool_size is the one knob that bounds what an application
# costs the database -- its backends, each a process holding memory and one of
# max_connections. A size that is accepted, answered by an accessor and then
# not applied is worse than a refused one: the application runs, and the
# server pays for five connections where three were asked for. And the DBD
# attributes that may stand beside the broker belong to the owner's DBI
# connection only: one of them in a pooled connection's conninfo and libpq
# refuses the connection ("invalid connection option"), which only a real
# libpq says.
#
# So every claim about a pool here is made three times over, from the server:
# twice as many statements as the pool may hold connections are issued at once,
# each holding its backend for a moment, and
#   - they are answered by exactly pool_size backends (pg_backend_pid),
#   - the server runs pool_size of them at a time, never more (pg_stat_activity,
#     sampled from a connection of its own while they run),
#   - and afterwards pg_stat_activity lists exactly those backends for the pool.
#
# The cases:
#   a) a Static broker with { async => 'ev', pool_size => 3, pg_enable_utf8 => 1 }
#      beside it: the transport is not refused; the owner's DBI connection has
#      the DBD attribute and answers; the pool is three backends, logged in
#      from the broker; the listen connection opens from the same broker and
#      options, a fourth backend outside the pool;
#   b) the control -- the same broker with the mode alone: five backends, the
#      default, and no DBD attribute. The three in (a) is the option's doing;
#   c) a DBI-form answer with pool_size in its fifth element: two backends;
#   d) pool_size 3 in the answer and 4 beside the broker: refused naming
#      pool_size and nothing of the answer, again when asked again, and the
#      server never sees a backend for it -- neither size wins silently;
#   e) no broker: connect($dsn, $user, $pass, \%attrs, { pool_size => 4 }) --
#      the fifth element sizes the pool, four backends.
#
# The backends are told apart by application_name, which libpq takes from
# PGAPPNAME for the owner's DBI connection and the pooled ones alike; each case
# sets its own.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_$_" } qw( DSN USER PASS ) };
plan skip_all => 'Set DBIO_TEST_PG_USER and DBIO_TEST_PG_PASS: the broker hands out credentials'
  unless defined $user && length $user && defined $pass && length $pass;

use EV;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use DBIO::AccessBroker::Static;
use DBIO::PostgreSQL::EV::Storage;
use DBIO::Util ();

plan skip_all => 'the installed DBIO core predates connect options beside an AccessBroker (core k243 / k245)'
  unless DBIO::Storage::Async->can('_access_broker_pool_size');

alarm 120;

# The Static broker needs the DSN's parts: the DSN read as the transport reads
# it, not taken apart here (karr k77).
my %part = LiveServer->conninfo;
# The DSN is named without a password it may carry (karr k78).
plan skip_all => 'cannot take the test DSN apart into dbname / host / port: '
  . DBIO::Util::mask_connect_secrets($dsn, [ $dsn, $user, $pass ])
  unless defined $part{dbname};

my $EV   = 'DBIO::PostgreSQL::EV::Storage';
my $TAG  = "dbio_k60_$$";
my $HOLD = 0.5;   # seconds a statement of a burst holds its backend

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

# The backends the server has for the connections of one case, the owner's DBI
# connection left out: [ pid, user, database ] each, by pid.
sub pool_backends {
  my ($tag, $owner_pid) = @_;
  return grep { !defined $owner_pid || $_->[0] != $owner_pid } @{ $observer->selectall_arrayref(
    'SELECT pid, usename, datname FROM pg_catalog.pg_stat_activity WHERE application_name = ? ORDER BY pid',
    undef, $tag,
  ) };
}

# $n statements issued at once, each holding its backend for $HOLD seconds:
# how many were answered, the backends that answered them, and the most the
# server was running at one time.
sub burst {
  my ($async, $tag, $n) = @_;
  my $peak = 0;
  EV::now_update();
  my $sampler = EV::timer(0.05, 0.05, sub {
    my ($busy) = $observer->selectrow_array(
      q{SELECT count(*) FROM pg_catalog.pg_stat_activity
         WHERE application_name = ? AND state = 'active' AND query LIKE '%pg_sleep%'},
      undef, $tag,
    );
    $peak = $busy if $busy > $peak;
  });
  my @rows = settle($async->future_class->needs_all(
    map {
      $async->select_async(\"(SELECT pg_backend_pid() AS pid, pg_sleep($HOLD) AS held) me", [ 'pid', 'held' ])
    } 1 .. $n
  ), "$n statements at once");
  undef $sampler;
  my %pid = map { $_->[0] => 1 } @rows;
  return { answered => scalar @rows, pids => [ sort { $a <=> $b } keys %pid ], peak => $peak };
}

# A pool of $size connections, as the server sees it.
sub pool_is {
  my ($async, $tag, $size, $owner_pid) = @_;
  my $n = 2 * $size;
  is scalar eval { $async->pool->max_size }, $size, "the pool may hold $size connections" or diag $@;
  my $seen = eval { burst($async, $tag, $n) } || { answered => 0, pids => [], peak => 0 };
  diag $@ if $@;
  is $seen->{answered}, $n, "$n statements issued at once are all answered";
  is scalar @{ $seen->{pids} }, $size, "... by $size backends";
  is $seen->{peak}, $size, "... of which the server ran $size at a time, never more";
  is_deeply [ map { $_->[0] } pool_backends($tag, $owner_pid) ], $seen->{pids},
    '... and those are all the backends the server has for the pool';
  return;
}

# A broker answering whatever the test puts in it.
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

sub static {
  return DBIO::AccessBroker::Static->new(
    dbname => $part{dbname},
    (defined $part{host} ? (host => $part{host}) : ()),
    (defined $part{port} ? (port => $part{port}) : ()),
    username => $user,
    password => $pass,
  );
}

# The owner's DBI connection: its backend, and who is logged in where.
sub owner_login {
  my ($schema) = @_;
  my $dbh = $schema->storage->dbh;
  return ($dbh, $dbh->{pg_pid}, [ $dbh->selectrow_array('SELECT current_user::text, current_database()::text') ]);
}

sub hang_up {
  my ($schema, $async) = @_;
  eval { $async->disconnect } if $async;
  eval { $schema->storage->disconnect };
  return;
}

subtest 'a) Static broker, { async, pool_size => 3, pg_enable_utf8 => 1 } beside it' => sub {
  my $tag = "${TAG}_a";
  local $ENV{PGAPPNAME} = $tag;

  my $schema = BrokerSchema->connect(static(), { async => 'ev', pool_size => 3, pg_enable_utf8 => 1 });
  my $async  = eval { $schema->storage->async };
  isa_ok $async, $EV, 'the transport, not refused for the settings beside the broker'
    or diag $@;

  my ($dbh, $owner_pid, $login) = owner_login($schema);
  is $dbh->{pg_enable_utf8}, 1, 'the owner\'s DBI connection has the DBD attribute given beside the broker';
  is_deeply $login, [ $user, $part{dbname} ], '... and answers, logged in from the broker';

  SKIP: {
    skip 'the connection was refused', 9 unless $async;

    # The first pooled connection: libpq took its conninfo, so pg_enable_utf8
    # is not in it.
    my $row = eval { (settle($async->select_async(
      'pg_catalog.pg_stat_activity', [ 'usename', 'datname' ], { pid => \'= pg_backend_pid()' },
    ), 'select_async'))[0] };
    is_deeply $row, [ $user, $part{dbname} ],
      'select_async runs on a pooled connection: libpq was handed no DBD attribute, and the broker\'s login'
      or diag $@;

    pool_is($async, $tag, 3, $owner_pid);

    my %login = map { ("$_->[1] in $_->[2]" => 1) } pool_backends($tag, $owner_pid);
    is_deeply [ keys %login ], [ "$user in $part{dbname}" ], 'every one of them logged in from the broker';

    my $channel = "${TAG}_listen";
    my @got;
    my $heard = eval {
      settle($async->listen($channel => sub { push @got, [ @_[0, 1] ] }), 'listen');
      settle($async->notify($channel => 'beside the broker'), 'notify');
      wait_until(sub { @got });
    };
    ok $heard, 'the listen connection opens from the same broker and options, and hears a notify' or diag $@;
    is scalar(pool_backends($tag, $owner_pid)), 4, '... as a fourth backend: pool_size bounds the pool, not it';
    eval { settle($async->unlisten($channel), 'unlisten') };
  }

  hang_up($schema, $async);
};

subtest 'b) control: the same broker with the mode alone' => sub {
  my $tag = "${TAG}_b";
  local $ENV{PGAPPNAME} = $tag;

  my $schema = BrokerSchema->connect(static(), { async => 'ev' });
  my $async  = eval { $schema->storage->async };
  isa_ok $async, $EV, 'the transport' or diag $@;

  my ($dbh, $owner_pid) = owner_login($schema);
  isnt $dbh->{pg_enable_utf8}, 1, 'the owner\'s DBI connection has no pg_enable_utf8 of 1 unless it is given';

  SKIP: {
    skip 'the connection was refused', 5 unless $async;
    pool_is($async, $tag, 5, $owner_pid);
  }

  hang_up($schema, $async);
};

subtest 'c) a DBI-form answer with pool_size in its fifth element' => sub {
  my $tag = "${TAG}_c";
  local $ENV{PGAPPNAME} = $tag;

  my $schema = BrokerSchema->connect(
    AnswerBroker->new([ $dsn, $user, $pass, {}, { pool_size => 2 } ]),
    { async => 'ev' },
  );
  my $async = eval { $schema->storage->async };
  isa_ok $async, $EV, 'the transport' or diag $@;

  my (undef, $owner_pid, $login) = owner_login($schema);
  is_deeply $login, [ $user, $part{dbname} ], 'the owner\'s DBI connection answers from the same answer';

  SKIP: {
    skip 'the connection was refused', 5 unless $async;
    pool_is($async, $tag, 2, $owner_pid);
  }

  hang_up($schema, $async);
};

subtest 'd) pool_size 3 in the answer, 4 beside the broker' => sub {
  my $tag = "${TAG}_d";
  local $ENV{PGAPPNAME} = $tag;

  my $schema = BrokerSchema->connect(
    AnswerBroker->new([ $dsn, $user, $pass, { pool_size => 3 } ]),
    { async => 'ev', pool_size => 4 },
  );

  # Asked twice: a refusal that left a half-configured backend behind would
  # hand that one out the second time, with one of the two sizes.
  for my $ask ('asked for the transport', 'asked again') {
    my $async = eval { $schema->storage->async };
    my $err   = "$@";
    ok !$async, "$ask: refused";
    like $err, qr/Connection setting 'pool_size' is given both beside the AccessBroker and in the broker's answer, with different values/,
      '... naming pool_size, so neither size wins silently';
    unlike $err, qr/\Q$pass\E/, '... and nothing of the answer, which carries the password';
  }

  wait_until(sub { 0 }, 0.3);   # what a connection in the making would need to arrive
  is_deeply [ pool_backends($tag) ], [], 'the server never saw a backend for it';

  hang_up($schema);
};

subtest 'e) no broker: connect($dsn, $user, $pass, \%attrs, { pool_size => 4 })' => sub {
  my $tag = "${TAG}_e";
  local $ENV{PGAPPNAME} = $tag;

  my $schema = BrokerSchema->connect($dsn, $user, $pass, { async => 'ev' }, { pool_size => 4 });
  my $async  = eval { $schema->storage->async };
  isa_ok $async, $EV, 'the transport' or diag $@;

  my (undef, $owner_pid, $login) = owner_login($schema);
  is_deeply $login, [ $user, $part{dbname} ], 'the owner\'s DBI connection answers';

  SKIP: {
    skip 'the connection was refused', 5 unless $async;
    pool_is($async, $tag, 4, $owner_pid);
  }

  hang_up($schema, $async);
};

$observer->disconnect;

done_testing;
