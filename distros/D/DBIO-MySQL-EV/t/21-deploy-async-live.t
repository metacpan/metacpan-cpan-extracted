use strict;
use warnings;
use Test::More;

# LIVE counterpart to t/21-deploy-async-mock.t (karr #21).
#
# The mock test pins the wiring: which generator deploy_async resolves, which
# statements it runs, on which connection, with no transaction wrap. What it
# cannot answer is the only question a real server can: does the DDL that
# DBIO::MySQL::DDL generates from DBIO schema classes actually parse and run
# on MySQL/MariaDB over EV::MariaDB -- including the DROP TABLE IF EXISTS ...
# CASCADE pre-pass (MySQL accepts CASCADE for portability and ignores it).
#
# Asserted here:
#   1. deploy_async on a clean database creates every table;
#   2. a re-run with add_drop_table is idempotent AND really drops (a row
#      written between the two deploys must be gone);
#   3. the deployed tables carry the constraints the schema classes declared
#      (the UNIQUE constraint is enforced by the server);
#   4. CRUD over the async transport works on the deployed tables.
#
# NOT asserted: atomicity. MySQL implicitly COMMITs each DDL statement, so
# core's deploy_async deliberately does not wrap the batch in a transaction
# (ADR 0026) -- there is no rollback to test, only the one-shot warning that
# says so (pinned in the mock test).

use DBIO::MySQL::EV::TestHarness;

BEGIN { DBIO::MySQL::EV::TestHarness->skip_all_unless_live }

{
  package DBIO::MySQL::EV::DeployLive::Artist;
  use base 'DBIO::Core';
  __PACKAGE__->table('deploy_ev_artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 128 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint([qw( name )]);

  package DBIO::MySQL::EV::DeployLive::CD;
  use base 'DBIO::Core';
  __PACKAGE__->table('deploy_ev_cd');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    artist_id => { data_type => 'integer' },
    title     => { data_type => 'varchar', size => 256 },
  );
  __PACKAGE__->set_primary_key('id');

  package DBIO::MySQL::EV::DeployLive::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL', 'MySQL::EV');
  __PACKAGE__->register_class(Artist => 'DBIO::MySQL::EV::DeployLive::Artist');
  __PACKAGE__->register_class(CD     => 'DBIO::MySQL::EV::DeployLive::CD');
}

my @tables = qw( deploy_ev_artist deploy_ev_cd );

my $h;

# Leave the database as we found it -- also when a subtest dies or the file
# aborts (karr k41): the harness's await croaks on a failed Future, so cleanup
# at the bottom of the file would be skipped, and leftover deploy_ev_* tables
# break dbio-mysql's live suite on the same database. Every step is
# eval-guarded: an END block must never mask the real failure.
END {
  return unless $h;
  for my $t (@tables) {
    eval { $h->await($h->async->_query_async("DROP TABLE IF EXISTS $t", [])) };
  }
  eval { $h->disconnect };
}

$h = DBIO::MySQL::EV::TestHarness->new(
  schema_class => 'DBIO::MySQL::EV::DeployLive::Schema',
);

# Bound queries (insert_async) need an already-connected pooled handle; the
# pool hands one off before its connect handshake completes.
$h->warm_pool;

my $async = $h->async;

# Raw bindless SQL on a pooled connection -- used for setup/teardown and for
# the verification SELECTs (which must not go through the ORM's column
# handling). Returns the first result row as an arrayref, or undef.
sub run_raw {
  my ($sql) = @_;
  my @rows = $h->await($async->_query_async($sql, []));
  return $rows[0];
}

# Drive a Future to completion WITHOUT dying on failure, so a failed deploy is
# reported as a failing assertion (with the server's error) instead of aborting
# the remaining subtests.
sub await_settled {
  my ($f, $what) = @_;
  eval { $h->await($f); 1 } or diag "$what: $@";
  return $f;
}

# Start from a known state: deploy_async(add_drop_table) would handle leftovers
# itself, but the "did the DROP really run" assertion below needs a clean base.
run_raw("DROP TABLE IF EXISTS $_") for @tables;

# insert_async takes the ResultSource, not the table name (core ADR 0031 §3):
# only a source tells the transport which column the LAST_INSERT_ID() belongs
# to. A bare table name is accepted by the SQLMaker but yields a hashref
# WITHOUT the auto_increment id (karr k41: the CD insert below then wrote
# artist_id NULL).
my $artist_source = $h->schema->source('Artist');
my $cd_source     = $h->schema->source('CD');

# --- 1. deploy on a clean database -------------------------------------------

subtest 'deploy_async creates the schema' => sub {
  my $f = await_settled($async->deploy_async($h->schema), 'deploy_async on clean DB');
  ok $f->is_done && !$f->is_failed, 'deploy_async Future resolved';

  for my $t (@tables) {
    my $row = run_raw("SELECT COUNT(*) FROM $t");
    is $row->[0], 0, "table $t exists and is empty";
  }
};

# --- 2. idempotent re-run really drops ---------------------------------------

subtest 'deploy_async with add_drop_table is idempotent' => sub {
  my $row = $h->await($async->insert_async($artist_source, { name => 'pre-deploy' }));
  is ref($row), 'HASH', 'pre-deploy insert returned the returned-columns hashref';
  is run_raw('SELECT COUNT(*) FROM deploy_ev_artist')->[0], 1,
    'the pre-deploy row is there';

  my $f = await_settled(
    $async->deploy_async($h->schema, { add_drop_table => 1 }),
    'deploy_async re-run',
  );
  ok $f->is_done && !$f->is_failed, 'second deploy_async succeeded';

  is run_raw('SELECT COUNT(*) FROM deploy_ev_artist')->[0], 0,
    'pre-deploy row gone -- the DROP TABLE pre-pass really ran';
};

# --- 3./4. the deployed tables behave like the schema classes declared -------

subtest 'CRUD and constraints on the deployed tables' => sub {
  my $artist = $h->await($async->insert_async($artist_source, { name => 'live-smoke' }));
  is $artist->{name}, 'live-smoke', 'insert_async wrote a row through the deployed table';
  ok defined $artist->{id} && $artist->{id} =~ /^\d+$/,
    'insert_async(<source>) returned the auto_increment id from LAST_INSERT_ID()';

  is run_raw("SELECT COUNT(*) FROM deploy_ev_artist WHERE name = 'live-smoke'")->[0], 1,
    'the row is queryable';

  my $dup_failed = !eval {
    $h->await($async->insert_async($artist_source, { name => 'live-smoke' }));
    1;
  };
  ok $dup_failed, 'UNIQUE constraint from add_unique_constraint is enforced by the server';

  my $cd = $h->await($async->insert_async($cd_source,
    { artist_id => $artist->{id}, title => 'live-cd' }));
  is $cd->{title}, 'live-cd', 'insert into the second deployed table works';
};

# --- 5. reserved and non-plain names in the drop pre-pass (karr k96) ----------

{
  package DBIO::MySQL::EV::DeployLive::Order;
  use base 'DBIO::Core';
  __PACKAGE__->table('order');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer', is_auto_increment => 1 },
    qty => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');

  package DBIO::MySQL::EV::DeployLive::Dashed;
  use base 'DBIO::Core';
  __PACKAGE__->table('deploy-ev-dashed');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package DBIO::MySQL::EV::DeployLive::ReservedSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL', 'MySQL::EV');
  __PACKAGE__->register_class(Order  => 'DBIO::MySQL::EV::DeployLive::Order');
  __PACKAGE__->register_class(Dashed => 'DBIO::MySQL::EV::DeployLive::Dashed');
}

subtest 'deploy_async(add_drop_table) over reserved table names' => sub {
  my $rh = DBIO::MySQL::EV::TestHarness->new(
    schema_class => 'DBIO::MySQL::EV::DeployLive::ReservedSchema',
  );
  $rh->warm_pool;
  my $ra = $rh->async;
  my $cleanup = sub {
    for my $t ('`order`', '`deploy-ev-dashed`') {
      eval { $rh->await($ra->_query_async("DROP TABLE IF EXISTS $t", [])) };
    }
  };
  $cleanup->();

  for my $round (1, 2) {
    my $ok = eval { $rh->await($ra->deploy_async($rh->schema, { add_drop_table => 1 })); 1 };
    ok $ok, "deploy_async(add_drop_table) round $round succeeds over order and a dashed name"
      or diag $@;
  }

  my @rows = $rh->await($ra->_query_async('SELECT COUNT(*) FROM `order`', []));
  is $rows[0][0], 0, 'the table `order` exists and is empty';

  $cleanup->();
  $rh->disconnect;
};

# Cleanup (DROP + disconnect) runs in the END block above.

done_testing;
