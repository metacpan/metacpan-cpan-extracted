use strict;
use warnings;
use Test::More;
use Test::Exception;

# LIVE regression for karr #7: the async CRUD facade must translate the SQL
# maker's '?' placeholders into PostgreSQL positional '$N' before handing SQL
# to libpq (EV::Pg->query_params).
#
# WHY this is a live test and not just offline: the offline facade test
# (storage-facade.t) mocks EV::Pg, so a '?' that libpq would reject sails
# straight through. The bug only bites when a bound WHERE/SET/VALUES actually
# reaches a real PostgreSQL, which parses '? ' as a syntax error
# (`syntax error at or near ")"`). This test drives select_async +
# insert_async + update_async + delete_async with BOUND predicates
# ({ col => $val }) through the real Storage facade against a real server, so
# the '?'->'$N' translation is exercised end to end through libpq.

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use DBIO::PostgreSQL::EV::Storage;

# Parse DSN into a libpq conninfo hash (same shape Storage->connect_info wants).
# Mirrors t/10-integration.t's DSN handling.
my $dsn  = $ENV{DBIO_TEST_PG_DSN};
my $user = $ENV{DBIO_TEST_PG_USER} || '';
my $pass = $ENV{DBIO_TEST_PG_PASS} || '';

my %ci;
if ($dsn =~ /^dbi:Pg:(.+)/i) {
  for my $kv (split /;/, $1) {
    my ($k, $v) = split /=/, $kv, 2;
    next unless defined $k && length $k;
    $k = 'dbname' if $k eq 'database';   # normalize for libpq
    $ci{$k} = $v;
  }
} else {
  # Already a libpq conninfo string — split into the hash.
  for my $kv (split /\s+/, $dsn) {
    my ($k, $v) = split /=/, $kv, 2;
    $ci{$k} = $v if defined $k && length $k;
  }
}
$ci{user}     = $user if length $user;
$ci{password} = $pass if length $pass;

# --- bring up storage (COLD pool — no pre-warm) ---
#
# karr #9: the pool's acquire() used to hand back an EV::Pg handle before its
# async connect had finished, so the very first facade CRUD call on a cold pool
# threw "not connected". The fix gates acquire on a per-connection readiness
# Future, so this test deliberately does NOT pre-warm: every query below is the
# first thing that ever touches the pool, exercising the cold-pool path and
# making this a live regression for #9 (in addition to the #7 placeholder fix).

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ \%ci, {} ]);

# Drive a Future to completion on the EV loop, then return its result.
sub await {
  my $f = shift;
  EV::run(EV::RUN_ONCE) until $f->is_ready;
  return $f->get;
}

# Run a raw statement on a pooled connection (used only for table DDL setup).
sub run_raw {
  my ($sql) = @_;
  return await($storage->pool->acquire->then(sub {
    my $pg = shift;
    my $f  = Future->new;
    $pg->query($sql, sub {
      my (undef, $err) = @_;
      $storage->pool->release($pg);
      $err ? $f->fail($err) : $f->done;
    });
    return $f;
  }));
}

my $table = 'dbio_karr7_live';

lives_ok {
  run_raw("DROP TABLE IF EXISTS $table");
  run_raw("CREATE TABLE $table (id serial PRIMARY KEY, name text, tag text)");
} 'test table created';

# --- insert_async with bound VALUES (?, ?) -> ($1, $2) ---
# ADR 0031 §3: insert_async resolves with the returned-columns HASHREF
# (supplied insert data overlaid with DB-populated cols). Here we drive
# the bare-table-name path, so the hashref carries the insert data
# directly (no source ->columns to zip the RETURNING row onto, so the
# PK id from RETURNING is not overlaid — the autoinc key is exposed
# implicitly via the SELECT below, which is what the sync $storage->insert
# contract returns for a bare table source too).

my $ins = await($storage->insert_async($table, { name => 'Miles', tag => 'jazz' }));
is ref $ins, 'HASH',
  'insert_async with bound VALUES resolved with a returned-columns HASHREF (ADR 0031 §3)';
is_deeply $ins, { name => 'Miles', tag => 'jazz' },
  'hashref carries the supplied insert data (no source = no PK overlay)';

await($storage->insert_async($table, { name => 'Coltrane', tag => 'jazz' }));
await($storage->insert_async($table, { name => 'Hendrix',  tag => 'rock' }));

# --- select_async with a bound WHERE { col => $val } -> WHERE "name" = $1 ---
# This is the exact shape that died pre-fix with `syntax error at or near ")"`.

my @miles = await($storage->select_async($table, ['id', 'name', 'tag'], { name => 'Miles' }));
is scalar(@miles), 1, 'select_async with bound WHERE returned one row';
is $miles[0][1], 'Miles', 'bound WHERE matched the right row';

# Multiple bound predicates -> $1 AND $2, numbered left-to-right.
my @jazz = await($storage->select_async($table, ['name'], { tag => 'jazz' }));
is scalar(@jazz), 2, 'bound WHERE on tag returned both jazz rows';

# --- update_async with bound SET + bound WHERE -> SET .. = $1 WHERE .. = $2 ---

await($storage->update_async($table, { tag => 'fusion' }, { name => 'Miles' }));
my @after = await($storage->select_async($table, ['tag'], { name => 'Miles' }));
is $after[0][0], 'fusion', 'update_async with bound SET+WHERE applied (?,? -> $1,$2)';

# --- delete_async with a bound WHERE -> WHERE "name" = $1 ---

await($storage->delete_async($table, { name => 'Hendrix' }));
my @gone = await($storage->select_async($table, ['id'], { name => 'Hendrix' }));
is scalar(@gone), 0, 'delete_async with bound WHERE removed the row';

my @remaining = await($storage->select_async($table, ['id'], {}));
is scalar(@remaining), 2, 'exactly the two undeleted rows remain';

# --- cleanup ---

lives_ok { run_raw("DROP TABLE IF EXISTS $table") } 'test table dropped';

$storage->disconnect;

done_testing;
