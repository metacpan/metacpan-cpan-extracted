use strict;
use warnings;
use Test::More;
use Test::Exception;

# LIVE coverage for $storage->deploy_async
# (DBIO::PostgreSQL::EV::Storage::deploy_async).
#
# WHY this is a live test: deploy_async wires three concerns together that
# only a real PG backend can validate:
#
#   1. The DDL generated locally by DBIO::PostgreSQL::DDL->install_ddl from
#      DBIO schema classes actually parses and runs on real libpq (column
#      types, NOT NULL, GENERATED AS IDENTITY, UNIQUE constraints, PK).
#   2. Each DDL statement runs on a SINGLE pinned EV::Pg connection inside
#      one async transaction -- PostgreSQL's transactional DDL must ROLLBACK
#      all preceding statements on the first failure, not just the bad one.
#   3. The Future-chaining across BEGIN -> N DDLs -> COMMIT/ROLLBACK does
#      not leak "lost a sequence Future" warnings (the same lifetime defect
#      karr #10 caught in the txn_do_async path -- deploy_async inherits the
#      shape).
#
# A mock libpq could prove the SQL string is right but nothing about whether
# the pinned-connection semantics + transactional rollback + Future lifetime
# actually hold on the wire.
#
# We assert:
#   1. deploy_async on an empty DB produces all expected tables;
#   2. a second deploy_async with add_drop_table succeeds (idempotent re-run);
#   3. CRUD on the deployed tables works (smoke-test that the DDL really
#      matches the schema classes);
#   4. a corrupted DDL chain FAILS the Future AND leaves the DB untouched
#      (atomicity: bad statement #3 of 5, statements #1 and #2 must be
#      rolled back);
#   5. No "lost a sequence Future" warning is emitted across any path.

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use Future;
use DBIO::PostgreSQL::EV::Storage;

# Parse DSN into a libpq conninfo hash (mirrors t/12..18).
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
  for my $kv (split /\s+/, $dsn) {
    my ($k, $v) = split /=/, $kv, 2;
    $ci{$k} = $v if defined $k && length $k;
  }
}
$ci{user}     = $user if length $user;
$ci{password} = $pass if length $pass;

# Capture warnings so we can assert the "lost a sequence Future" regression
# never returns on the deploy_async path. Re-emit anything unexpected so
# genuine warnings stay visible.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0]; warn $_[0] };

# Drive a Future to completion on the EV loop under a wall-clock guard, so
# a regression that reintroduces a hang fails this test instead of spinning.
sub await_guarded {
  my ($f, $what) = @_;
  local $SIG{ALRM} = sub { die "TIMEOUT awaiting $what (karr #10 regression: deploy hung)\n" };
  alarm 20;
  EV::run(EV::RUN_ONCE) until $f->is_ready;
  alarm 0;
  return $f;
}

# Raw statement on a pooled connection (DDL setup/teardown + verification).
# Returns the first column of the first row in scalar context, or the whole
# first row in list context -- mirrors DBI's $dbh->selectrow_array /
# selectrow_arrayref ergonomics for the COUNT(*) checks below.
sub run_raw {
  my ($storage, $sql) = @_;
  my $f = $storage->pool->acquire->then(sub {
    my $pg  = shift;
    my $rf  = Future->new;
    $pg->query($sql, sub {
      my ($res, $err) = @_;
      $storage->pool->release($pg);
      $err ? $rf->fail($err) : $rf->done($res);
    });
    return $rf;
  });
  my $res = await_guarded($f, "run_raw: $sql")->get;
  return () unless $res && ref $res eq 'ARRAY' && @$res;
  return wantarray ? @{ $res->[0] } : $res->[0][0];
}

# Schema classes for the deploy-async test -- 3 tables, FK-free (mirrors
# the demo: belongs_to declares the relationship for joins but DBIO does
# NOT auto-emit FKs in DDL; that's the same contract DBIO::Schema->deploy
# follows).
package DeployTest::Result::Artist {
  use base 'DBIO::Core';
  __PACKAGE__->table('deploy_test_artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 128 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint([qw( name )]);
}

package DeployTest::Result::CD {
  use base 'DBIO::Core';
  __PACKAGE__->table('deploy_test_cd');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    artist_id => { data_type => 'integer' },
    title     => { data_type => 'varchar', size => 256 },
    year      => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

package DeployTest::Result::Track {
  use base 'DBIO::Core';
  __PACKAGE__->table('deploy_test_track');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    cd_id    => { data_type => 'integer' },
    title    => { data_type => 'varchar', size => 256 },
    position => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

package DeployTest::Schema {
  # -pg pins storage_type to DBIO::PostgreSQL::Storage. load_components
  # then layers in the PostgreSQL schema component that provides
  # pg_install_ddl -- the DDL generator deploy_async consumes.
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Artist => 'DeployTest::Result::Artist');
  __PACKAGE__->register_class(CD     => 'DeployTest::Result::CD');
  __PACKAGE__->register_class(Track  => 'DeployTest::Result::Track');
}

package main;

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ \%ci, {} ]);

# Pre-flight cleanup so the test starts from a known state. Even though
# deploy_async({add_drop_table=>1}) handles pre-existing tables, starting
# from clean makes the assertion in test #1 straightforward (no leftover
# rows / schema from a previous run muddying the count check).
for my $t (qw(deploy_test_artist deploy_test_cd deploy_test_track)) {
  run_raw($storage, "DROP TABLE IF EXISTS $t CASCADE");
}

my $schema = DeployTest::Schema->connect($ENV{DBIO_TEST_PG_DSN}, $user, $pass, {
  AutoCommit => 1,
  RaiseError => 1,
  async      => 'ev',   # ADR 0030: async is explicit per-connection -- without
                        # this ->async is undef (EV is a thin transport over the
                        # core per-connection model since karr #22).
});

# --- 1. deploy_async on an empty DB ---------------------------------------

subtest 'deploy_async creates all 3 tables' => sub {
  my $f = await_guarded(
    $schema->storage->async->deploy_async($schema, { add_drop_table => 1 }),
    'deploy_async empty DB',
  );
  ok $f->is_done,    'deploy_async Future resolved';
  ok !$f->is_failed, 'deploy_async Future succeeded';

  # Verify each table exists and is empty. run_raw goes through the pool
  # with raw SQL (select_async would route through SQL::Abstract's column
  # hash, which is not what we want for DDL verification queries).
  for my $t (qw(deploy_test_artist deploy_test_cd deploy_test_track)) {
    my ($n) = run_raw($storage, "SELECT COUNT(*) FROM $t");
    is $n, 0, "table $t exists and is empty";
  }
};

# --- 2. idempotent re-run --------------------------------------------------

subtest 'deploy_async with add_drop_table is idempotent' => sub {
  # Insert a row first so we can prove the second deploy actually DROPPED
  # (a fresh deploy with no rows would also pass even if DROP failed).
  my $row = await_guarded(
    $schema->storage->insert_async('deploy_test_artist', { name => 'pre-deploy' }),
    'insert before re-deploy',
  )->get;
  ok ref($row) eq 'HASH',
    'pre-deploy insert_async returned the returned-columns HASHREF (ADR 0031 §3)';
  is $row->{name}, 'pre-deploy', 'pre-deploy hashref carries the supplied insert data';

  my $f = await_guarded(
    $schema->storage->async->deploy_async($schema, { add_drop_table => 1 }),
    'deploy_async re-run',
  );
  ok $f->is_done && !$f->is_failed, 'second deploy_async succeeded';

  # The pre-deploy row must be gone -- proves the DROP TABLE actually ran
  # (add_drop_table => 1 really did its job, not just the CREATE).
  my ($after) = run_raw($storage,
    'SELECT COUNT(*) FROM deploy_test_artist');
  is $after, 0, 'pre-deploy row gone after re-deploy (DROP worked)';
};

# --- 3. CRUD smoke on the deployed tables ----------------------------------

subtest 'CRUD works on tables deployed via deploy_async' => sub {
  my $insert_f = $schema->storage->insert_async('deploy_test_artist',
    { name => 'live-smoke' });
  my $artist_row = await_guarded($insert_f, 'insert artist')->get;
  is ref($artist_row), 'HASH',
    'insert_async returned the returned-columns HASHREF (ADR 0031 §3)';
  is $artist_row->{name}, 'live-smoke',
    'insert_async hashref carries the supplied insert data';

  my ($count) = run_raw($storage,
    "SELECT COUNT(*) FROM deploy_test_artist WHERE name = 'live-smoke'");
  is $count, 1, 'row is queryable through the deployed table';

  # Sanity-check the unique constraint actually fired by the DDL we generated
  # (add_unique_constraint([qw(name)]) must have produced a UNIQUE constraint,
  # not just a column declaration we silently ignored).
  my $dup_threw = !eval {
    await_guarded(
      $schema->storage->insert_async('deploy_test_artist',
        { name => 'live-smoke' }),
      'insert duplicate (must fail)',
    )->get;
    1;
  };
  ok $dup_threw, 'UNIQUE constraint from add_unique_constraint is enforced';
};

# --- 4. atomicity: bad DDL rolls back the whole batch ----------------------

subtest 'atomicity: failing statement rolls back preceding DDLs' => sub {
  # Build a DDL chain where statement #3 of 5 is intentionally broken.
  # We test atomicity by routing the chain through _execute_ddl_async
  # directly -- it is the same private helper deploy_async uses, and we
  # want to be sure it propagates a libpq failure up to txn_do_async so
  # the surrounding transaction actually ROLLBACKs.
  my $bad_ddl = join("\n\n",
    "CREATE TABLE atomicity_a (id int PRIMARY KEY)",
    "CREATE TABLE atomicity_b (id int PRIMARY KEY)",
    "THIS IS NOT VALID SQL",
    "CREATE TABLE atomicity_c (id int PRIMARY KEY)",
    "CREATE TABLE atomicity_d (id int PRIMARY KEY)",
  );

  my $f = await_guarded(
    $schema->storage->txn_do_async(sub {
      my ($ctx) = @_;
      return $schema->storage->_execute_ddl_async($ctx->txn_pg, $bad_ddl);
    }),
    'atomicity bad DDL',
  );

  ok $f->is_failed, 'atomicity: Future failed (bad DDL)';
  ok $f->failure,   'atomicity: failure carries a libpq error message';

  # Pre-rollback state check: NONE of the four tables must exist.
  # If atomicity had leaked (bad DDL applied but only #3 reverted), at
  # least atomicity_a and atomicity_b would survive.
  for my $t (qw(atomicity_a atomicity_b atomicity_c atomicity_d)) {
    my ($exists) = run_raw($storage,
      "SELECT COUNT(*) FROM pg_tables WHERE tablename = '$t'");
    is $exists, 0, "atomicity: $t was rolled back, no leftover table";
  }
};

# --- 5. no Future-lost warning across all paths ----------------------------

subtest 'no "lost a sequence Future" warning on any deploy_async path' => sub {
  my @lost = grep { /lost a sequence Future/i } @warnings;
  ok !@lost, 'no Future-lost warnings'
    or diag("warnings: " . join("\n", @lost));
};

# Cleanup -- leave the DB clean for the next run.
for my $t (qw(deploy_test_artist deploy_test_cd deploy_test_track
              atomicity_a atomicity_b atomicity_c atomicity_d)) {
  run_raw($storage, "DROP TABLE IF EXISTS $t CASCADE");
}

done_testing;