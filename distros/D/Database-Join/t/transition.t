#!/usr/bin/perl

# t/transition.t — Finite State Machine transition tests for Database::Join.
#
# Validates every documented state transition derived from the Z calculus
# FORMAL SPECIFICATION in lib/Database/Join.pm:
#
#   FSM 1 — Object Lifecycle  (ΔDatabase_Join / ΞDatabase_Join schemas)
#   FSM 2 — SQLite Cache Lifecycle  (_cache_fresh / _build_sqlite_cache)
#   FSM 3 — Column Visibility  (ΔDatabase_Join RemoveColumn schema)
#
# Each subtest is named after the transition it covers:
#   "State: <source> -> Trigger: <op> -> State: <destination>"

use strict;
use warnings;

use Test::Most tests => 54;
use Readonly;
use Scalar::Util qw(blessed refaddr);

use_ok('Database::Join');

# ---------------------------------------------------------------------------
# Inline test doubles
# ---------------------------------------------------------------------------

{
	package TransDA;
	use parent -norequire, 'Database::Abstraction';
	sub new {
		my ($class, %a) = @_;
		return bless {
			cols    => $a{cols}    // ['entry'],
			rows    => $a{rows}    // [],
			id      => $a{id}      // 'entry',
			schema  => $a{schema}  // {},
			updated => $a{updated} // 1,
			_calls  => 0,
			_logger => undef,
		}, $class;
	}
	sub columns    { return $_[0]->{cols} }
	sub schema     { return $_[0]->{schema} // {} }
	sub updated    { return $_[0]->{updated} }
	sub call_count { return $_[0]->{_calls} }
	sub set_logger { $_[0]->{_logger} = $_[1]; return $_[0] }
	sub selectall_arrayref {
		my ($self, $crit) = @_;
		$self->{_calls}++;
		$crit //= {};
		my @out;
		ROW: for my $row (@{ $self->{rows} }) {
			for my $col (keys %{$crit}) {
				my $v = $crit->{$col};
				if (ref($v) eq 'HASH') {
					for my $op (keys %{$v}) {
						my $rhs = $v->{$op};
						if ($op eq '>')  { next ROW unless defined $row->{$col} && $row->{$col} >  $rhs }
						elsif ($op eq '<') { next ROW unless defined $row->{$col} && $row->{$col} < $rhs }
					}
				} elsif (defined $v) {
					next ROW unless defined $row->{$col} && $row->{$col} eq $v;
				}
			}
			push @out, { %{$row} };
		}
		return \@out;
	}
	sub DESTROY {}
}

# DA with mutable updated() — exercises FRESH→STALE→FRESH cache transitions
{
	package TransUpdDA;
	use parent -norequire, 'TransDA';
	sub set_updated { $_[0]->{updated} = $_[1]; return $_[0] }
	sub DESTROY {}
}

# WhiteBox subclass to call _cache_fresh() (Sub::Protected method)
{
	package Database::Join::TransBox;
	use parent -norequire, 'Database::Join';
	sub expose_cache_fresh { my $self = shift; return $self->_cache_fresh(@_) }
}

# ---------------------------------------------------------------------------
# Shared constants
# ---------------------------------------------------------------------------

Readonly::Scalar my $JC => 'entry';

Readonly::Hash my %ERR => (
	no_dbs          => qr/At least one Database::Abstraction object is required/,
	remove_join_col => qr/Cannot remove join_column/,
	invalid_db      => qr/databases\[\d+\] does not support/,
	join_col_absent => qr/join_column "[^"]*" is absent from databases/,
);

# Standard two-DA fixture: primary (name), secondary (score), left join.
sub _mk_join {
	my %o = @_;
	my $p = TransDA->new(
		cols => [$JC, 'name'],
		rows => [
			{ $JC => 'k1', name => 'Alice' },
			{ $JC => 'k2', name => 'Bob'   },
		],
	);
	my $s = TransDA->new(
		cols => [$JC, 'score'],
		rows => [ { $JC => 'k1', score => 90 } ],
	);
	return ($p, $s, Database::Join->new(databases => [$p, $s], join_column => $JC, %o));
}

# SQLite-backend fixture (uses TransBox so _cache_fresh is callable)
sub _mk_sqlite_join {
	my $p = TransDA->new(
		cols => [$JC, 'name'],
		rows => [ { $JC => 'k1', name => 'Alice' } ],
	);
	my $s = TransDA->new(
		cols => [$JC, 'score'],
		rows => [ { $JC => 'k1', score => 90 } ],
	);
	my $j = Database::Join::TransBox->new(
		databases => [$p, $s],
		join_column => $JC,
		backend     => 'sqlite',
	);
	return ($p, $s, $j);
}

# ==========================================================================
# FSM 1 — Object Lifecycle
# ==========================================================================
# States: CONSTRUCTED | COL_REMOVED | DB_ADDED
#
# Valid transitions (from Z schemas):
#   UNINITIALIZED   -> new()                -> CONSTRUCTED
#   CONSTRUCTED     -> selectall_arrayref() -> CONSTRUCTED (ΞDatabase_Join — no change)
#   CONSTRUCTED     -> remove_column()      -> COL_REMOVED
#   COL_REMOVED     -> remove_column()      -> COL_REMOVED (chainable)
#   CONSTRUCTED     -> add_database()       -> DB_ADDED
#   DB_ADDED        -> add_database()       -> DB_ADDED (chainable)
#   COL_REMOVED     -> add_database()       -> DB_ADDED (respects removed set)
#   DB_ADDED        -> remove_column()      -> COL_REMOVED
#   Any             -> DESTROY             -> DESTROYED
#
# Illegal transitions (guard clauses croak; state unchanged):
#   UNINITIALIZED   -> new(databases=>[])   -> croak (no object created)
#   CONSTRUCTED     -> remove_column(jc)   -> croak (join_col irremovable)
#   CONSTRUCTED     -> add_database(scalar)-> croak
#   UNINITIALIZED   -> new(jc absent)      -> croak
# ==========================================================================

note '=== FSM 1: Object Lifecycle ===';

# T01 — State: UNINITIALIZED → Trigger: new() → State: CONSTRUCTED
{
	note 'T01: UNINITIALIZED -> new() -> CONSTRUCTED';
	my ($p, $s, $j) = _mk_join();
	ok(blessed($j),                  'T01a: object is blessed (CONSTRUCTED)');
	is($j->{_join_col}, $JC,        'T01b: _join_col set to join_column');
	ok(defined $j->{_col_db}{$JC},  'T01c: join_col present in _col_db');
	ok(defined $j->{_col_db}{name}, 'T01d: primary col "name" in _col_db');
	ok(defined $j->{_col_db}{score},'T01e: secondary col "score" in _col_db');
}

# T02 — State: CONSTRUCTED → Trigger: selectall_arrayref() → State: CONSTRUCTED
# ΞDatabase_Join schema: read-only operations must not mutate _col_db.
{
	note 'T02: CONSTRUCTED -> selectall_arrayref() -> CONSTRUCTED (state unchanged)';
	my ($p, $s, $j) = _mk_join();
	my %col_db_snap = %{ $j->{_col_db} };
	$j->selectall_arrayref();
	is_deeply($j->{_col_db}, \%col_db_snap,
		'T02: ΞDatabase_Join — _col_db unchanged after read-only query');
}

# T03 — State: CONSTRUCTED → Trigger: remove_column('name') → State: COL_REMOVED
{
	note 'T03: CONSTRUCTED -> remove_column(col) -> COL_REMOVED';
	my ($p, $s, $j) = _mk_join();
	$j->columns();   # populate _col_cache
	$j->schema();    # populate _schema_cache
	$j->remove_column('name');
	ok(!defined $j->{_col_db}{name},  'T03a: col removed from _col_db');
	ok($j->{_removed_cols}{name},     'T03b: col recorded in _removed_cols');
	ok(!defined $j->{_col_cache},     'T03c: _col_cache invalidated');
	ok(!defined $j->{_schema_cache},  'T03d: _schema_cache invalidated');
	ok(!(grep { $_ eq 'name' } @{ $j->columns() }),
		'T03e: col absent from columns() output');
}

# T04 — State: COL_REMOVED → Trigger: remove_column (another col) → State: COL_REMOVED
{
	note 'T04: COL_REMOVED -> remove_column() -> COL_REMOVED (chainable)';
	my ($p, $s, $j) = _mk_join();
	$j->remove_column('name');
	my $ret = $j->remove_column('score');
	is($ret, $j, 'T04a: remove_column returns $self (chainable)');
	ok($j->{_removed_cols}{name},  'T04b: first removal still recorded');
	ok($j->{_removed_cols}{score}, 'T04c: second removal recorded');
}

# T05 — State: CONSTRUCTED → Trigger: add_database($db) → State: DB_ADDED
{
	note 'T05: CONSTRUCTED -> add_database() -> DB_ADDED';
	my ($p, undef, $j) = _mk_join();
	my $extra = TransDA->new(
		cols => [$JC, 'tag'], rows => [{ $JC => 'k1', tag => 'vip' }]);
	my $ret = $j->add_database($extra);
	is($ret, $j,                     'T05a: add_database returns $self');
	is(scalar @{ $j->{_dbs} }, 3,   'T05b: _dbs extended to 3');
	ok(defined $j->{_col_db}{tag},   'T05c: new col "tag" routed in _col_db');
}

# T06 — State: DB_ADDED → Trigger: add_database($db) → State: DB_ADDED (chainable)
{
	note 'T06: DB_ADDED -> add_database() -> DB_ADDED (chained)';
	my ($p, undef, $j) = _mk_join();
	$j->add_database(TransDA->new(cols => [$JC, 'tag'],   rows => []));
	$j->add_database(TransDA->new(cols => [$JC, 'badge'], rows => []));
	is(scalar @{ $j->{_dbs} }, 4,  'T06a: two chained add_database calls → 4 DAs');
	ok(defined $j->{_col_db}{badge},'T06b: second-added col routed correctly');
}

# T07 — State: COL_REMOVED → Trigger: add_database() → State: DB_ADDED
# Key invariant: the new DA's columns must respect _removed_cols — a column
# that was removed cannot be restored by adding another DA that also has it.
{
	note 'T07: COL_REMOVED -> add_database() -> DB_ADDED (removed set preserved)';
	my ($p, $s, $j) = _mk_join();
	$j->remove_column('name');
	# New DA also has 'name' — must remain removed (line 1674 of Join.pm)
	my $extra = TransDA->new(cols => [$JC, 'name', 'tag'], rows => []);
	$j->add_database($extra);
	ok(!defined $j->{_col_db}{name}, 'T07a: removed col "name" still absent from _col_db');
	ok(defined  $j->{_col_db}{tag},  'T07b: non-removed new col "tag" added normally');
}

# T08 — State: DB_ADDED → Trigger: remove_column() → State: COL_REMOVED
{
	note 'T08: DB_ADDED -> remove_column() -> COL_REMOVED';
	my ($p, $s, $j) = _mk_join();
	$j->add_database(TransDA->new(cols => [$JC, 'tag'], rows => []));
	$j->remove_column('tag');
	ok(!defined $j->{_col_db}{tag},  'T08a: newly added col removed from _col_db');
	ok($j->{_removed_cols}{tag},     'T08b: col recorded in _removed_cols');
}

# T09 — State: CONSTRUCTED → Trigger: DESTROY (no cache) → State: DESTROYED
{
	note 'T09: CONSTRUCTED -> DESTROY -> DESTROYED (no crash, no cache)';
	my ($p, $s, $j) = _mk_join();
	lives_ok { undef $j } 'T09: object destruction without cache → no crash';
}

# --- Illegal transitions ---------------------------------------------------

# T10 — Illegal: UNINITIALIZED → new(databases=>[]) → croak
# Pre-condition (#dbs ≥ 1) violated; no object is created.
{
	note 'T10 (illegal): new(databases=>[]) → croak (pre-condition violated)';
	throws_ok {
		Database::Join->new(databases => [], join_column => $JC)
	} $ERR{no_dbs}, 'T10: empty databases array → croak error_no_databases';
}

# T11 — Illegal: CONSTRUCTED → remove_column(join_col) → croak; state unchanged
# join_col ∉ removed is a permanent invariant; the guard prevents the transition.
{
	note 'T11 (illegal): CONSTRUCTED -> remove_column(join_col) -> croak; state UNCHANGED';
	my ($p, $s, $j) = _mk_join();
	throws_ok { $j->remove_column($JC) }
		$ERR{remove_join_col}, 'T11a: remove join_col → croak';
	ok(defined $j->{_col_db}{$JC},
		'T11b: join_col still in _col_db (failed transition left state intact)');
}

# T12 — Illegal: CONSTRUCTED → add_database(scalar) → croak
{
	note 'T12 (illegal): CONSTRUCTED -> add_database(scalar) -> croak';
	my ($p, $s, $j) = _mk_join();
	throws_ok { $j->add_database('not_a_key') }
		$ERR{invalid_db}, 'T12: non-ref first arg → croak error_invalid_db';
}

# T13 — Illegal: UNINITIALIZED → new() with join_col absent from DA → croak
{
	note 'T13 (illegal): new() with join_col absent from first DA → croak';
	my $p = TransDA->new(cols => ['id', 'name'], rows => []);  # 'entry' not present
	throws_ok {
		Database::Join->new(databases => [$p], join_column => $JC)
	} $ERR{join_col_absent}, 'T13: join_col absent from DA → croak';
}

# ==========================================================================
# FSM 2 — SQLite Cache Lifecycle
# ==========================================================================
# States: ABSENT | FRESH | STALE
#
# Valid transitions:
#   ABSENT  -> first SQLite-path query  -> FRESH   (_build_sqlite_cache)
#   FRESH   -> same-data query          -> FRESH   (_cache_fresh → reuse)
#   FRESH   -> source updated() changes -> STALE   (timestamp mismatch)
#   STALE   -> next query               -> FRESH   (_build_sqlite_cache rebuilds)
#   FRESH   -> add_database()           -> ABSENT  (cache evicted, line 1683)
#   ABSENT  -> DESTROY                  -> ABSENT  (no-op, no crash)
#   FRESH   -> DESTROY                  -> ABSENT  (File::Temp unlinked)
# ==========================================================================

note '=== FSM 2: SQLite Cache Lifecycle ===';

# T14 — State: ABSENT → Trigger: first SQLite-path query → State: FRESH
{
	note 'T14: ABSENT -> selectall_arrayref (backend=sqlite) -> FRESH';
	my ($p, $s, $j) = _mk_sqlite_join();
	ok(!defined $j->{_sqlite_cache}, 'T14a: cache ABSENT before first query');
	$j->selectall_arrayref();
	ok(defined  $j->{_sqlite_cache}, 'T14b: cache exists after first query');
	is($j->expose_cache_fresh(), 1,  'T14c: _cache_fresh() confirms FRESH state');
}

# T15 — State: FRESH → Trigger: same-data query → State: FRESH (cache reused)
{
	note 'T15: FRESH -> selectall_arrayref (same data) -> FRESH (cache reused)';
	my ($p, $s, $j) = _mk_sqlite_join();
	$j->selectall_arrayref();
	my $addr_v1 = refaddr($j->{_sqlite_cache});
	$j->selectall_arrayref();
	is(refaddr($j->{_sqlite_cache}), $addr_v1,
		'T15: cache hashref address unchanged — cache reused, not rebuilt');
}

# T16 — State: FRESH → Trigger: source updated() changes → State: STALE
#        State: STALE → Trigger: next query → State: FRESH (rebuilt)
{
	note 'T16: FRESH -> (updated() bumped) -> STALE -> selectall_arrayref -> FRESH';
	my $p = TransUpdDA->new(
		cols => [$JC, 'name'], rows => [{ $JC => 'k1', name => 'Alice' }],
		updated => 100,
	);
	my $s = TransDA->new(
		cols => [$JC, 'score'], rows => [{ $JC => 'k1', score => 90 }],
	);
	my $j = Database::Join::TransBox->new(
		databases => [$p, $s], join_column => $JC, backend => 'sqlite',
	);

	$j->selectall_arrayref();                 # ABSENT → FRESH
	my $addr_v1 = refaddr($j->{_sqlite_cache});
	is($j->expose_cache_fresh(), 1, 'T16a: cache FRESH after first query');

	$p->set_updated(999);                     # trigger: timestamp changes → STALE
	is($j->expose_cache_fresh(), 0, 'T16b: cache STALE after source updated() change');

	$j->selectall_arrayref();                 # STALE → FRESH (rebuild)
	is($j->expose_cache_fresh(), 1, 'T16c: cache FRESH again after rebuild');
	ok(refaddr($j->{_sqlite_cache}) != $addr_v1,
		'T16d: cache address changed — a new hashref was allocated (rebuild confirmed)');
}

# T17 — State: FRESH → Trigger: add_database() → State: ABSENT (cache evicted)
{
	note 'T17: FRESH -> add_database() -> ABSENT (cache evicted)';
	my ($p, $s, $j) = _mk_sqlite_join();
	$j->selectall_arrayref();
	ok(defined $j->{_sqlite_cache}, 'T17a: cache FRESH before add_database');
	$j->add_database(TransDA->new(cols => [$JC, 'tag'], rows => []));
	ok(!defined $j->{_sqlite_cache},'T17b: cache ABSENT after add_database (evicted)');
}

# T18 — State: ABSENT → Trigger: DESTROY → State: DESTROYED (no crash)
{
	note 'T18: ABSENT -> DESTROY -> DESTROYED (no cache, no crash)';
	my ($p, $s, $j) = _mk_sqlite_join();
	ok(!defined $j->{_sqlite_cache}, 'T18a: cache ABSENT before destroy');
	lives_ok { undef $j } 'T18b: DESTROY without cache → no crash';
}

# T19 — State: FRESH → Trigger: DESTROY → State: DESTROYED
# File::Temp object is released: the UNLINK=1 temp file is deleted on destroy.
{
	note 'T19: FRESH -> DESTROY -> DESTROYED (File::Temp released, temp file unlinked)';
	my $filename;
	{
		my ($p, $s, $j) = _mk_sqlite_join();
		$j->selectall_arrayref();             # FRESH: temp file created
		$filename = $j->{_sqlite_cache}{tmpfile}->filename;
		ok(-e $filename, 'T19a: temp file exists while object is FRESH');
		lives_ok { undef $j } 'T19b: DESTROY with active cache → no crash';
		# $j destroyed → its _sqlite_cache hashref released → File::Temp destructs
	}
	ok(!-e $filename, 'T19c: temp file unlinked after Database::Join DESTROY');
}

# ==========================================================================
# FSM 3 — Column Visibility
# ==========================================================================
# States per-column: VISIBLE | REMOVED
#
# Valid transitions (from RemoveColumn Z schema):
#   VISIBLE -> selectall_arrayref() -> VISIBLE  (ΞDatabase_Join: read-only)
#   VISIBLE -> remove_column(col)   -> REMOVED
#   REMOVED -> remove_column(col)   -> REMOVED  (idempotent)
#
# Illegal (guard clauses):
#   VISIBLE(join_col) -> remove_column(join_col) -> croak; join_col stays VISIBLE
#
# Documented non-transition (no API for it):
#   REMOVED -> (no trigger)         -> VISIBLE  (not possible; one-way transition)
# ==========================================================================

note '=== FSM 3: Column Visibility ===';

# T20 — State: VISIBLE → Trigger: selectall_arrayref() → State: VISIBLE
# ΞDatabase_Join: query operations must not change column visibility.
{
	note 'T20: VISIBLE -> selectall_arrayref() -> VISIBLE (ΞDatabase_Join)';
	my ($p, $s, $j) = _mk_join();
	$j->selectall_arrayref();
	ok((grep { $_ eq 'name' } @{ $j->columns() }),
		'T20: "name" stays VISIBLE after read-only query');
}

# T21 — State: VISIBLE → Trigger: remove_column('name') → State: REMOVED
{
	note 'T21: VISIBLE -> remove_column() -> REMOVED';
	my ($p, $s, $j) = _mk_join();
	$j->remove_column('name');
	ok(!(grep { $_ eq 'name' } @{ $j->columns() }),
		'T21a: "name" REMOVED from columns()');
	ok(!exists $j->schema()->{name},
		'T21b: "name" REMOVED from schema()');
	my $row = $j->selectall_arrayref()->[0] // {};
	ok(!exists $row->{name},
		'T21c: "name" REMOVED from query result rows');
}

# T22 — State: REMOVED → Trigger: remove_column(same col) → State: REMOVED (idempotent)
{
	note 'T22: REMOVED -> remove_column(same col) -> REMOVED (idempotent, no crash)';
	my ($p, $s, $j) = _mk_join();
	$j->remove_column('name');
	my $ret;
	lives_ok { $ret = $j->remove_column('name') }
		'T22a: second remove_column on same col → no crash';
	is($ret, $j, 'T22b: idempotent removal still returns $self');
}

# T23 — Illegal: VISIBLE(join_col) → remove_column(join_col) → croak; stays VISIBLE
# Invariant from Z spec: join_col ∉ removed must hold at all times.
{
	note 'T23 (illegal): join_col VISIBLE -> remove_column(join_col) -> croak; stays VISIBLE';
	my ($p, $s, $j) = _mk_join();
	throws_ok { $j->remove_column($JC) }
		$ERR{remove_join_col}, 'T23a: remove join_col → croak';
	ok((grep { $_ eq $JC } @{ $j->columns() }),
		'T23b: join_col still VISIBLE — failed transition left state intact');
}

# T24 — REMOVED → VISIBLE: not possible (one-way transition, no restore API)
# Attempting to restore a removed column by adding a DA that also has it
# must NOT restore visibility — _removed_cols is consulted by add_database
# before updating _col_db (see lib/Database/Join.pm line 1674).
# TODO: FSM Discrepancy — there is no REMOVED→VISIBLE transition in the documented API.
{
	note 'T24: REMOVED -> add_database(DA with same col) -> REMOVED (stays removed; one-way)';
	my ($p, $s, $j) = _mk_join();
	$j->remove_column('name');
	# Add a fresh DA that also has 'name' — should NOT restore it
	$j->add_database(TransDA->new(
		cols => [$JC, 'name'], rows => [{ $JC => 'k1', name => 'Restored' }]));
	ok(!(grep { $_ eq 'name' } @{ $j->columns() }),
		'T24: REMOVED→VISIBLE blocked — add_database respects _removed_cols');
}

done_testing();
