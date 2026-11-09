use strict;
use warnings;
use Test::More;
use Scalar::Util ();

# LIVE, karr k74 (decision (b), ADR 0062 in core): a statement the server
# refused fails its Future with a DBIO::Exception::Server, on a real
# PostgreSQL, for the errors a caller has to tell apart: 23505 unique
# violation (with constraint and table), 40P01 deadlock, 40001 serialization
# failure. t/60 holds 57014 (the cancel, also under lc_messages de_DE and a
# connection lost); t/98 holds the object's construction offline.
#
# The claims:
#   1. a unique violation fails the Future with the object: sqlstate 23505,
#      constraint and table named, detail the server's line, and it
#      stringifies to libpq's text -- on the pooled path, pinned, inside
#      txn_do_async, in a pipeline, and through the blocking call of the
#      async storage (insert, which is insert_async->get: it dies with the
#      object).
#   2. the same text matches what a caller matched before: =~ and eq.
#   3. a deadlock (40P01) of two transactions: one of them fails with the
#      object, the other commits.
#   4. a serialization failure (40001) of two SERIALIZABLE transactions: one
#      fails, the other commits. Where PostgreSQL detects it decides the
#      place, not the class: at a statement it is the object; at COMMIT it is
#      the same class as a copy with context COMMIT and core's "COMMIT
#      failed: ..." in front of the server's text (core k335, ADR 0062).
#   5. an error at COMMIT -- a deferred unique constraint -- fails
#      txn_do_async with a DBIO::Exception::Server whose context is COMMIT,
#      sqlstate 23505, constraint and table those of the violation, and that
#      stringifies "COMMIT failed: ERROR: ...".
#   6. the synchronous DBI storage (sync_storage) throws a
#      DBIO::Exception::Server for the same violation, sqlstate 23505 taken
#      from the handle; the ev path and the sync path give the same class and
#      the same sqlstate, constraint, table and detail (measured: the
#      DBIO::PostgreSQL::Storage of the installed driver reports all four).
#
# Tables of its own, dropped at the end; nothing server-wide is touched.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

# A server that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

use EV;

alarm 300;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my @T = qw( dbio_karr74_srv dbio_karr74_def dbio_karr74_lock dbio_karr74_ssi );
my ($SRV, $DEF, $LOCK, $SSI) = @T;

# Wait for $f: (1, @result) once it is done, (0, $error) once it failed.
sub wait_for {
  my ($f) = @_;
  EV::now_update();
  my $dog = EV::timer(15, 0, sub { $f->fail("watchdog: still pending after 15s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

sub sleep_expr { return ('pg_namespace', [ \'pg_sleep(0.4)' ], { nspname => 'pg_catalog' }) }

sub is_server_error {
  my ($got, $label, %want) = @_;
  ok Scalar::Util::blessed($got) && $got->isa('DBIO::Exception::Server'),
    "$label: a DBIO::Exception::Server" or do { diag explain $got; return };
  is $got->$_, $want{$_}, "$label: $_" for sort keys %want;
  return 1;
}

my $h = DBIO::PostgreSQL::EV::TestHarness->new(
  connect_attrs => { pool_size => 2, on_connect_do => [ q{SET lock_timeout = '10s'} ] },
);
my $dbh = $h->sync_storage->dbh;

sub drop_tables { $dbh->do("DROP TABLE IF EXISTS $_") for @T }
drop_tables();
$dbh->do("CREATE TABLE $SRV (id serial PRIMARY KEY, name text NOT NULL, CONSTRAINT ${SRV}_name_key UNIQUE (name))");
$dbh->do("CREATE TABLE $DEF (a int, CONSTRAINT ${DEF}_a_key UNIQUE (a) DEFERRABLE INITIALLY DEFERRED)");
$dbh->do("CREATE TABLE $LOCK (id int PRIMARY KEY, v int NOT NULL)");
$dbh->do("INSERT INTO $LOCK VALUES (1, 0), (2, 0)");
$dbh->do("CREATE TABLE $SSI (class int NOT NULL, val int NOT NULL)");
$dbh->do("INSERT INTO $SSI VALUES (1, 10), (2, 20)");
$dbh->do("INSERT INTO $SRV (name) VALUES ('taken')");

END { eval { drop_tables() } }

my $async = $h->async;

# -----------------------------------------------------------------------------
# 1. unique violation, on every path
# -----------------------------------------------------------------------------
my $TEXT = qr/duplicate key value violates unique constraint "${SRV}_name_key"/;
my %UNIQUE = (
  sqlstate   => '23505',
  constraint => "${SRV}_name_key",
  table      => $SRV,
);

sub check_unique {
  my ($label, $error) = @_;
  return unless is_server_error($error, $label, %UNIQUE);
  like $error->detail // '', qr/Key \(name\)=\(\*\*\*\) already exists/, "$label: detail is the server's, values masked";
  like "$error", $TEXT, "$label: matches the text a caller matched before";
  unlike "$error", qr/\(taken\)/, "$label: the message names no value";
  ok $error =~ /^ERROR:  /, "$label: and begins as libpq's text does";
  ok $error eq "$error", "$label: eq the string it stringifies to";
}

{
  my $f = $async->insert_async($SRV, { name => 'taken' });
  my ($ok, $err) = wait_for($f);
  ok !$ok, 'pooled: the insert fails';
  check_unique('pooled', $err);
  is scalar(my @failure = $f->failure), 1, 'pooled: the Future failed with one value';
}
{
  my ($got, $pg) = wait_for($h->pool->acquire);
  die "acquire failed: $pg" unless $got;
  my ($ok, $err) = wait_for($h->query_on($pg, "INSERT INTO $SRV (name) VALUES ('taken')"));
  ok !$ok, 'pinned: the insert fails';
  check_unique('pinned', $err);
  $h->pool->release($pg);
}
{
  my ($ok, $err) = wait_for($async->txn_do_async(sub {
    return $_[0]->insert_async($SRV, { name => 'taken' });
  }));
  ok !$ok, 'txn_do_async: the transaction fails';
  check_unique('txn_do_async', $err);
}
{
  my ($ok, $err) = wait_for($async->pipeline(sub {
    my ($batch) = @_;
    $batch->insert_async($SRV, { name => 'fresh-in-pipeline' });
    return $batch->insert_async($SRV, { name => 'taken' });
  }));
  ok !$ok, 'pipeline: the batch fails';
  check_unique('pipeline', $err);
}
{
  # the blocking call: insert is insert_async->get, and dies with the object
  my $died = eval { $async->insert($SRV, { name => 'taken' }); 1 } ? undef : $@;
  check_unique('blocking insert', $died);
}

# -----------------------------------------------------------------------------
# 3. deadlock
# -----------------------------------------------------------------------------
{
  my $crossing = sub {
    my ($first, $second) = @_;
    return $async->txn_do_async(sub {
      my ($ctx) = @_;
      return $ctx->update_async($LOCK, { v => 1 }, { id => $first })
        ->then(sub { $ctx->select_async(sleep_expr()) })
        ->then(sub { $ctx->update_async($LOCK, { v => 1 }, { id => $second }) });
    });
  };
  my @txn = ($crossing->(1, 2), $crossing->(2, 1));
  my @res = map { [ wait_for($_) ] } @txn;
  my @failed = grep { !$_->[0] } @res;
  is scalar(@failed), 1, 'deadlock: exactly one of the two transactions fails';
  is scalar(grep { $_->[0] } @res), 1, 'deadlock: and the other commits';
  if (@failed) {
    is_server_error($failed[0][1], 'deadlock', sqlstate => '40P01');
    like "$failed[0][1]", qr/deadlock detected/, 'deadlock: the text is the server\'s';
  }
}

# -----------------------------------------------------------------------------
# 4. serialization failure
# -----------------------------------------------------------------------------
{
  my $ssi = DBIO::PostgreSQL::EV::TestHarness->new(
    connect_attrs => {
      pool_size     => 2,
      on_connect_do => [ q{SET default_transaction_isolation = 'serializable'} ],
    },
  );
  my $skew = sub {
    my ($read, $write) = @_;
    return $ssi->async->txn_do_async(sub {
      my ($ctx) = @_;
      my $sum;
      return $ctx->select_async($SSI, [ \'sum(val)' ], { class => $read })
        ->then(sub {
          $sum = $_[0][0];
          return $ctx->select_async(sleep_expr());
        })
        ->then(sub {
          return $ctx->insert_async($SSI, { class => $write, val => $sum });
        });
    });
  };
  my @txn = ($skew->(1, 2), $skew->(2, 1));
  my @res = map { [ wait_for($_) ] } @txn;
  my @failed = grep { !$_->[0] } @res;
  is scalar(@failed), 1, 'serialization: exactly one of the two transactions fails';
  is scalar(grep { $_->[0] } @res), 1, 'serialization: and the other commits';
  if (@failed) {
    my $err = $failed[0][1];
    like "$err", qr/could not serialize access/, 'serialization: the text is the server\'s';
    if ("$err" =~ /\ACOMMIT failed: /) {
      note '  detected at COMMIT';
      is_server_error($err, 'serialization, at COMMIT', sqlstate => '40001', context => 'COMMIT');
    }
    else {
      note '  detected at a statement';
      is_server_error($err, 'serialization, at a statement', sqlstate => '40001');
    }
  }
  $ssi->disconnect;
}

# -----------------------------------------------------------------------------
# 5. COMMIT, and the synchronous DBI storage
# -----------------------------------------------------------------------------
my $commit_error;
{
  my ($ok, $err) = wait_for($async->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->insert_async($DEF, { a => 1 })
      ->then(sub { $ctx->insert_async($DEF, { a => 1 }) });
  }));
  ok !$ok, 'COMMIT: the deferred constraint fails the transaction';
  $commit_error = $err;
  is_server_error($err, 'COMMIT', sqlstate => '23505', context => 'COMMIT',
    constraint => "${DEF}_a_key", table => $DEF);
  like "$err", qr/\ACOMMIT failed: ERROR:  duplicate key value violates unique constraint "${DEF}_a_key"/,
    'COMMIT: core\'s "COMMIT failed: " and the server\'s text behind it';
}

# 6. the synchronous path: the same class, the same fields
{
  my $ev;
  {
    my ($ok, $err) = wait_for($async->insert_async($SRV, { name => 'taken' }));
    $ev = $err;
  }
  my $died = eval {
    $h->sync_storage->dbh_do(sub { $_[1]->do("INSERT INTO $SRV (name) VALUES ('taken')") });
    1;
  } ? undef : $@;
  ok $died, 'sync storage: the insert dies';
  is_server_error($died, 'sync storage', sqlstate => '23505');
  like "$died", qr/duplicate key value violates unique constraint/, 'sync storage: with the server\'s text';
  is ref($died), ref($ev), 'sync and ev path: the same class';
  is $died->sqlstate, $ev->sqlstate, 'sync and ev path: the same sqlstate';
  for my $field (qw( constraint table detail )) {
    ok defined $died->$field, "sync storage: $field is reported";
    is $died->$field, $ev->$field, "sync and ev path: the same $field";
  }
  is $commit_error->sqlstate, $died->sqlstate, 'sync and the ev COMMIT failure: the same sqlstate';
  ok !defined $died->context, 'sync storage: no context, nothing core put its words in front of';
}

my @died = grep { /exception in callback/ } @warnings;
is scalar @died, 0, 'no callback died out of EV::Pg' or diag @died;

drop_tables();
$h->disconnect;
done_testing;
