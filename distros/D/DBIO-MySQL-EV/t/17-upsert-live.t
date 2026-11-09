use strict;
use warnings;
use Test::More;

# LIVE counterpart to t/09-upsert-inherit.t (karr #23, follow-up to dbio-mysql
# #27, ADR 0036). The offline test freezes that the ev-mode sql_maker is
# DBIO::MySQL::SQLMaker and emits byte-identical ODKU SQL to a standalone
# base maker -- WHEN the on_conflict structure carries identity_column. What
# only a real server can answer is the session-state half: the ADR-0036 §4
# row-identity channel (`pk` = LAST_INSERT_ID(`pk`)) lives in the session
# LII, and the ev backend multiplexes pooled connections. This file drives a
# real upsert_async through the ev backend and checks which row comes back.
#
# The claim under test, stated plainly: core's upsert_async builds the
# on_conflict structure (target/action/set) WITHOUT identity_column -- that
# key is added by the sync driver's _mysql_upsert_plan (DBIO::MySQL::Storage)
# before a sync statement runs, and the ev backend's insert path renders the
# SQLMaker directly -- no other layer in the MRO supplies the key. So the
# backend itself must fold the plan's private keys in, resolved against its
# OWNING sync storage (the _owner_storage back-ref core wires in
# _async_storage), exactly like DBIO::MySQL::Storage::insert does. If that
# fold is missing or wrong, the ODKU UPDATE branch cannot report the touched
# row's id. That is the seam this file exists to probe.
#
# karr #45 fixed this in dbio-mysql (the SQLMaker no longer pretends it can
# derive identity_column from a ResultSource) and here in the ev backend
# (it now delegates the decision to the owning sync storage's
# _mysql_upsert_plan before rendering). The round-trip pins below are the
# live half of that fix: the ODKU UPDATE branch must report the id of the row
# the server actually touched, not a fresh session's LII.

use DBIO::MySQL::EV::TestHarness;
use DBIO::MySQL::SQLMaker;

BEGIN { DBIO::MySQL::EV::TestHarness->skip_all_unless_live }

{
  package DBIO::MySQL::EV::UpsertLive::Artist;
  use base 'DBIO::Core';
  __PACKAGE__->table('upsert_ev_artist');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    name  => { data_type => 'varchar', size => 128 },
    genre => { data_type => 'varchar', size => 64 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint([qw( name )]);

  package DBIO::MySQL::EV::UpsertLive::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL', 'MySQL::EV');
  __PACKAGE__->register_class(Artist => 'DBIO::MySQL::EV::UpsertLive::Artist');
}

my $table = 'upsert_ev_artist';

my $h;

# Leave the database as we found it -- also when an await croaks mid-file
# (karr k41): cleanup at the bottom would be skipped and the leftover table
# lingers in the shared test database. Eval-guarded so the END block never
# masks the real failure.
END {
  return unless $h;
  eval { $h->await($h->async->_query_async("DROP TABLE IF EXISTS $table", [])) };
  eval { $h->disconnect };
}

# pool_size 2 on purpose: the §4 probe below needs a SECOND, fresh pool
# connection to make the update-branch failure deterministic -- a fresh
# session's LAST_INSERT_ID() is 0 unless the idiom set it.
$h = DBIO::MySQL::EV::TestHarness->new(
  schema_class  => 'DBIO::MySQL::EV::UpsertLive::Schema',
  connect_attrs => { pool_size => 2 },
);
$h->warm_pool;

my $async = $h->async;
my $sync  = $h->sync_storage;

# Raw bindless SQL on a pooled connection for setup/teardown/verification.
sub run_raw {
  my ($sql) = @_;
  my @rows = $h->await($async->_query_async($sql, []));
  return $rows[0];
}

# --- 1. the capability is visible on the ev-mode connection ----------------
# The ev-mode schema's storage is the sync MySQL driver; the ev backend is
# its embedded async half. supports_upsert is declared by the sync driver
# (DBIO::MySQL::Storage) and must be visible on the connection core asks.
is $sync->_use_supports_upsert, 1,
  'supports_upsert visible on the ev-mode connection (sync storage owner)';

# --- 2. emitted conflict SQL, with identity_column supplied, matches base ---
# Same class, same standalone configuration as t/09 -- but this time from the
# LIVE backend's sql_maker, the exact maker that will render the wire SQL.
my $sm = $async->sql_maker;
my $base_sm = DBIO::MySQL::SQLMaker->new({
  quote_char => $sm->{quote_char} // '`',
  name_sep   => $sm->{name_sep}   // '.',
});

my %data = ( name => 'Thelonious', genre => 'bebop' );
my %on_conflict_with_id = (
  action          => 'update',
  set             => { name => { -attempted => 'name' } },
  identity_column => 'id',
);

my ($ev_sql,  @ev_bind)   = $sm->insert('upsert_ev_artist', { %data }, { on_conflict => { %on_conflict_with_id } });
my ($base_sql, @base_bind) = $base_sm->insert('upsert_ev_artist', { %data }, { on_conflict => { %on_conflict_with_id } });

is $ev_sql, $base_sql,
  'live ev-mode ODKU emission is byte-identical to the MySQL base maker';
like $ev_sql, qr/`id` \s* = \s* LAST_INSERT_ID \( `id` \)/xi,
  '§4 identity idiom present when identity_column is supplied';

# What core's upsert_async actually hands the backend: on_conflict WITHOUT
# identity_column (the sync driver's _mysql_upsert_plan adds it; the ev
# backend's insert path renders the SQLMaker directly). This is the seam the
# live round-trip below probes.
my %on_conflict_plain = (
  action => 'update',
  set    => { name => { -attempted => 'name' } },
);
my ($plain_sql) = $sm->insert('upsert_ev_artist', { %data }, { on_conflict => { %on_conflict_plain } });
unlike $plain_sql, qr/LAST_INSERT_ID/xi,
  'upsert_async-shaped on_conflict carries no identity idiom (plan key absent)';

# --- 3. the §4 identity path through the ev backend -------------------------
# Deploy the table, then upsert twice on the same unique name: first call
# inserts, second call takes the ODKU UPDATE branch. The returned row's id
# is the whole question -- it must be the id of the row the server actually
# touched.
run_raw("DROP TABLE IF EXISTS $table");
{
  my $f = $async->deploy_async($h->schema);
  eval { $h->await($f); 1 } or diag "deploy: $@";
  ok !$f->is_failed, 'deployed the upsert test table';
}

my $rs = $h->schema->resultset('Artist');

# conflict_target => 'any': the only target MySQL's grammar can honour. With
# the plan now running on the async path, an explicit ['name'] target would be
# REFUSED here -- the table has a primary key AND the UNIQUE(name) key, so a
# collision could also happen on the PK and the engine has no way to say which
# (the exact validation the sync path already performs; t/24-upsert-mysql.t
# section 1 pins the sync half).
my $row1 = $h->await($rs->upsert_async(
  { name => 'Thelonious', genre => 'bebop' },
  { conflict_target => 'any' },
));
ok $row1, 'first upsert_async (insert branch) returned a row';
my $id1 = $row1->id;
ok defined $id1 && $id1 =~ /^\d+$/,
  "insert branch returned an id ($id1)";

my $row2 = $h->await($rs->upsert_async(
  { name => 'Thelonious', genre => 'hard-bop' },
  { conflict_target => 'any' },
));
ok $row2, 'second upsert_async (ODKU update branch) returned a row';
my $id2 = $row2->id;

# The fix (karr #45): the backend folds _mysql_upsert_plan's identity_column
# into the on_conflict structure before rendering, so the UPDATE branch
# carries the `id` = LAST_INSERT_ID(`id`) no-op and reports the touched row.
# A second id different from the first (or 0, a fresh session's LII) would
# mean the fold regressed -- the ODKU branch silently un-names the row again.
diag "first id: $id1, second id: " . (defined $id2 ? $id2 : 'undef');
diag 'server: ' . ($sync->_server_info->{dbms_version} // 'unknown');
is $id2, $id1,
  '§4 identity path survives the async round-trip: the ODKU UPDATE branch '
  . 'reported the id of the row the server actually touched (not a fresh LII)';

# Ground truth on the wire: exactly one row, genre updated.
my $count = run_raw("SELECT COUNT(*) FROM $table");
is $count->[0], 1, 'exactly one row after insert + update upserts';
my $genre = run_raw("SELECT genre FROM $table WHERE id = $id1");
is $genre->[0], 'hard-bop', 'the ODKU UPDATE branch really updated the row';

# Cleanup (DROP + disconnect) runs in the END block above.

done_testing;
