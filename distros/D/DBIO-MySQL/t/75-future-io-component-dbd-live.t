use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# LIVE proof of karr k60: under { async => 'future_io' } every connection is
# driven through the binding of the DBD its DSN names, whichever storage class
# the schema component pinned.
#
# WHY IT MATTERS. load_components('MySQL') pins DBIO::MySQL::Storage -- and with
# it, by convention, the transport DBIO::MySQL::Storage::Async -- for EVERY DSN;
# load_components('MySQL::MariaDB') pins the MariaDB pair the same way. While the
# transport chose its DBD binding by class, the pinned class and the DSN's DBD
# could disagree: load_components('MySQL') over a dbi:MariaDB: DSN died at the
# pool connect with "Unknown attribute mysql_auto_reconnect" (measured
# 2026-09-26, MySQL 8.0.30, DBD::MariaDB 1.24), and behind that every async
# primitive and the insertid were DBD::mysql's. t/66 pins the per-connection
# choice offline, over fake DBDs that are strict the way it assumes the real
# ones are. This file is the other half: the real DBDs, a real server.
#
# t/55 and t/63 cannot show it. They connect DBIO::Test::Schema with the storage
# class the DSN's DBD is registered for declared on it, so the storage class
# always agrees with the DBD. Here both components are loaded, and each runs over both
# DBDs: two of the four cells are the disagreement (the one filed, and its
# mirror image), the other two are the combinations that always worked and that
# a fix which merely swapped the bindings would break.
#
# What a cell claims, on real handles:
#   1. the pool connection opens and a statement runs on it -- on a handle of
#      the DSN's DBD, with that DBD's auto-reconnect off;
#   2. an INSERT resolves with the AUTO_INCREMENT id of the row it wrote, which
#      is that DBD's per-statement insertid (the transport appends no
#      RETURNING), checked against the table from another session;
#   3. the dedicated listen connection is a handle of the same DBD, again with
#      auto-reconnect off, and a notify sent through the pool is delivered on
#      it with the pool session as sender.
#
# What the other DBD's binding does on the real handles (measured 2026-10-05,
# DBD::mysql 4.055, DBD::MariaDB 1.24, with this file over the lib before the
# fix and with single primitives bound to the class again) -- and so why a
# cell asks for values, not for survival:
# DBD::MariaDB refuses a mysql_* attribute outright, at the connect and at a
# FETCH ("Unknown attribute"). DBD::mysql does not: it takes a mariadb_*
# connect attribute and prepare attribute without a word, answers undef for
# mariadb_insertid -- the INSERT then resolves without its id -- and fails only
# where a method is called (mariadb_sockfd).
#
# The DSN comes from the environment. The other DBD's DSN is derived from it by
# exchanging the dbi:<DBD>: prefix -- both DBDs read database= / host= / port=
# alike -- when that DBD is installed and the DSN carries no mysql_* / mariadb_*
# part, which would not translate; otherwise its two cells are skipped, saying
# why. One run therefore covers component x DBD for the server it was pointed
# at.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Creates and drops the table artist and a notify table of its own.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io roundtrip';
}

use DBI;
use DBIO::Test;

eval {
  require DBIO::MySQL::Storage::Async;
  require DBIO::MySQL::Storage::MariaDB::Async;
  1;
} or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
  unless DBIO::Storage::Async->can('listen_alive');
plan skip_all => 'the installed dbio-async predates its Future::IO listen seams (dbio-async k22)'
  unless defined &DBIO::Async::Storage::_listen_drain;

# Each DBD's own names, spelled out here on purpose: the expectation must not
# be derived from the table under test.
my %API = (
  mysql => {
    reconnect => 'mysql_auto_reconnect',
    insertid  => 'mysql_insertid',
    thread_id => 'mysql_thread_id',
  },
  MariaDB => {
    reconnect => 'mariadb_auto_reconnect',
    insertid  => 'mariadb_insertid',
    thread_id => 'mariadb_thread_id',
  },
);
my %OTHER = ( mysql => 'MariaDB', MariaDB => 'mysql' );

my ($env_dbd, $dsn_rest) = $dsn =~ /\Adbi:(\w+):(.*)\z/s;
plan skip_all => 'DBIO_TEST_MYSQL_DSN names neither dbi:mysql: nor dbi:MariaDB:'
  unless defined $env_dbd && $API{$env_dbd};

# The DSN of the other DBD, or why there is none.
my $other_dbd = $OTHER{$env_dbd};
my ($other_dsn, $no_other);
if ($dsn_rest =~ /\b(?:mysql|mariadb)_/i) {
  $no_other = "the DSN carries a DBD-specific part, which DBD::$other_dbd would not read";
}
elsif (!eval "require DBD::$other_dbd; 1") {
  $no_other = "DBD::$other_dbd is not installed";
}
else {
  $other_dsn = "dbi:$other_dbd:$dsn_rest";
}

# The component pins the storage class, and the convention the transport: for
# every DSN. That is the premise of each cell, so each cell asserts it.
{
  package K60Live::MySQLSchema;
  use base 'DBIO::Test::Schema';
  __PACKAGE__->load_components('MySQL');

  package K60Live::MariaDBSchema;
  use base 'DBIO::Test::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');
}
my @COMPONENTS = (
  [ 'MySQL',          'K60Live::MySQLSchema',   'DBIO::MySQL::Storage::Async' ],
  [ 'MySQL::MariaDB', 'K60Live::MariaDBSchema', 'DBIO::MySQL::Storage::MariaDB::Async' ],
);

my $loop = IO::Async::Loop->new;

sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = Time::HiRes::time() + ($timeout // 10);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    $loop->loop_once(0.05);
  }
  return 1;
}

# Another session, for the fixture and for checking what the transport wrote.
my $raw = DBI->connect($dsn, $user, $pass, {
  AutoCommit => 1, RaiseError => 1, PrintError => 0,
});
note sprintf 'server %s, DBD::mysql %s, DBD::MariaDB %s',
  scalar $raw->selectrow_array('SELECT VERSION()'),
  map { $_->VERSION // 'not loaded' } qw( DBD::mysql DBD::MariaDB );

# A notify table unique to this run: the database is shared.
my $T    = "dbio_k60_notify_$$";
my $SEED = 4711;

sub drop_tables {
  local $raw->{Warn} = 0;
  $raw->do('DROP TABLE IF EXISTS artist');
  $raw->do("DROP TABLE IF EXISTS `$T`");
}

# Whatever happens below, the tables go.
END {
  if ($raw) {
    local ($@, $?);
    eval { drop_tables() };
  }
}

drop_tables();
$raw->do(<<'SQL');
CREATE TABLE artist (
    artistid  INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY
  , name      VARCHAR(100)
  , `rank`    INTEGER NOT NULL DEFAULT 13
  , charfield CHAR(10)
)
SQL
# AUTO_INCREMENT continues above the seed, so no id below is a 1 that anything
# could have made up.
$raw->do('INSERT INTO artist (artistid, name) VALUES (?, ?)', undef, $SEED, 'k60 seed');

sub pool_connections { grep { defined } @{ $_[0]->pool->{_connections} } }

sub cell {
  my ($component, $schema_class, $transport, $dbd, $cell_dsn) = @_;
  my $api   = $API{$dbd};
  my $label = "load_components('$component') over DBD::$dbd";
  my $name  = "k60 $component over $dbd";

  my $schema = $schema_class->connect($cell_dsn, $user, $pass, { async => 'future_io' });
  my $async  = $schema->storage->async;
  is ref($async), $transport, "$label: the transport the component pins, whatever the DSN";

  my $done = eval {
    # -- 1. the pool connection, and a statement on it. Opened under
    #       GATEWAY_INTERFACE, where DBD::mysql switches its auto-reconnect on
    #       by itself: off on the handle is then the transport's doing.
    #       (DBD::MariaDB never does; there it holds on the default as well.)
    my @rows = eval {
      local $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
      $async->select_async('artist', [ 'artistid', 'name' ], { artistid => $SEED })->get;
    };
    is $@, '', "$label: the pool connection opens and a SELECT runs on it"
      or die "no statement ran on the pool -- nothing else in this cell can be asked\n";
    is_deeply \@rows, [ [ $SEED, 'k60 seed' ] ], '... returning the row it asked for';

    # The pool retires a connection at the end of every borrow (core ADR 0079):
    # the statement's is gone, so one is borrowed and held, opened the same way,
    # to read the handle the pool makes.
    my $held = do {
      local $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
      $async->pool->acquire->get;
    };
    my @conns = pool_connections($async);
    is scalar(@conns), 1, '... on one pool connection';
    my $pool_dbh = $held->{dbh};
    is $pool_dbh->{Driver}{Name}, $dbd, "... a DBD::$dbd handle, as the DSN says"
      or die "the pool handle is another DBD's -- its attributes cannot be read by this DBD's names\n";
    ok !$pool_dbh->{ $api->{reconnect} }, "... with $api->{reconnect} off";
    my $pool_tid_held = $pool_dbh->{ $api->{thread_id} };
    $async->pool->release($held);

    # -- 2. the insertid. MySQL has no RETURNING: the id in the returned
    #       columns is the DBD's per-statement insertid and nothing else.
    for my $row_name ($name, "$name, again") {
      my $ret = eval { $async->insert_async($schema->source('Artist'), { name => $row_name })->get };
      is $@, '', "$label: insert_async runs";
      my ($written) = $raw->selectrow_array(
        'SELECT artistid FROM artist WHERE name = ?', undef, $row_name,
      );
      ok defined $written && $written > $SEED,
        '... the row is there, under an id AUTO_INCREMENT generated';
      is $ret && $ret->{artistid}, $written,
        "... and that id is the one insert_async resolved with ($api->{insertid})";
    }

    # -- 3. listen and notify.
    $async->notify_table($T);
    $async->notify_poll_interval(0.1);
    my (@got, @errors);
    $async->on_listen_error(sub { push @errors, $_[1] });

    $raw->do("DROP TABLE IF EXISTS `$T`");
    ok eval { $async->deploy_notify_table->get; 1 }, "$label: deploy_notify_table runs"
      or die "deploy_notify_table failed: $@";
    ok scalar $raw->selectrow_array(
      'SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?',
      undef, $T,
    ), '... and the notify table exists';

    my $channel = "k60_${$}_${dbd}";
    ok eval {
      local $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
      $async->listen($channel => sub { push @got, [@_] })->get;
      1;
    }, "$label: listen resolves" or die "listen failed: $@";

    # The listen connection, out of core's state: a test's privilege, as in
    # t/63.
    my $listen_dbh = $async->{_listen} && $async->{_listen}{conn} && $async->{_listen}{conn}{dbh};
    ok $listen_dbh, '... on a listen connection'
      or die "no listen connection -- nothing to deliver a notification on\n";
    is $listen_dbh->{Driver}{Name}, $dbd, "... a DBD::$dbd handle too"
      or die "the listen handle is another DBD's\n";
    ok !$listen_dbh->{ $api->{reconnect} }, "... with $api->{reconnect} off";
    isnt $listen_dbh->{ $api->{thread_id} }, $pool_tid_held,
      '... a session of its own, not the pool\'s';

    my $payload = "over DBD::$dbd under $component";
    ok eval { $async->notify($channel => $payload)->get; 1 }, "$label: notify resolves"
      or die "notify failed: $@";
    ok wait_until(sub { @got }), '... and the listener receives it';
    is_deeply [ @{ $got[0] || [] }[0, 1] ], [ $channel, $payload ], '... with channel and payload';
    # the pool's connection of that notify is retired by now (core ADR 0079),
    # so the sender is told apart from the two sessions it is not
    my ($raw_tid) = $raw->selectrow_array('SELECT CONNECTION_ID()');
    ok defined $got[0] && $got[0][2] && $got[0][2] != $raw_tid
      && $got[0][2] != $listen_dbh->{ $api->{thread_id} },
      '... sent from a pool session: neither the listen one nor the test\'s own';
    is_deeply \@errors, [], '... without a listen error';

    $async->unlisten($channel)->get;
    1;
  };
  ok $done, "$label: the cell ran to its end" or diag $@;

  eval { $async->disconnect };
  return;
}

for my $dbd_case ([ $env_dbd, $dsn ], [ $other_dbd, $other_dsn ]) {
  my ($dbd, $cell_dsn) = @$dbd_case;
  for my $case (@COMPONENTS) {
    SKIP: {
      skip "load_components('$case->[0]') over DBD::$dbd -- $no_other", 1 unless defined $cell_dsn;
      cell(@$case, $dbd, $cell_dsn);
    }
  }
}

drop_tables();
$raw->disconnect;
undef $raw;

done_testing;
