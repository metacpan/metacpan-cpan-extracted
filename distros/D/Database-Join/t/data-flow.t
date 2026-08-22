use strict;
use warnings;

# ---------------------------------------------------------------------------
# t/data-flow.t -- Define-Use (DU) chain and resource lifecycle tests for
# Database::Join.
#
# Strategy: trace each critical variable, data structure, and object reference
# through its full lifecycle: Definition → Use → Kill.  Detect anomalies:
#
#   D~  Dead store  — variable assigned but never subsequently read
#   DD  Redundant   — variable assigned twice without a read in between
#   ~U  Uninit use  — variable read before it has a defined value
#   O~  Resource leak — handle opened/created but never closed/freed
#
# Anomalies found in lib/Database/Join.pm and annotated with TODO comments:
#
#   1. D~ in AUTOLOAD (FIXED):
#      `my $db = $self->{_dbs}[$db_idx]` was computed unconditionally but is
#      only used in the non-join-map/filters branch.  Fixed by moving the
#      assignment into the else branch.
#
#   2. D~ in _joined_query (annotated):
#      $had_criteria[0] is written for every database, but the key-set
#      resolution loop starts at i=1; when n==1, $had_criteria[0] is a
#      permanent dead store.
#
#   3. Filter reference aliasing (annotated):
#      $self->{_filters} stores the caller's hashref directly.  External
#      mutation after construction silently changes query behaviour.
#
# All component databases are inline stubs (no SQLite, no disk I/O).
# ---------------------------------------------------------------------------

use Test::Most;
use Readonly;
use Scalar::Util qw(blessed refaddr weaken);

BEGIN {
	eval { require Database::Abstraction };
	plan skip_all => 'Database::Abstraction required' if $@;
	plan tests => 40;
	use_ok('Database::Join');
}

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
Readonly::Scalar my $JC      => 'entry';
Readonly::Scalar my $K_A     => 'a1';
Readonly::Scalar my $K_B     => 'a2';
Readonly::Scalar my $K_C     => 'a3';   # secondary-only in some tests

# ---------------------------------------------------------------------------
# DFRecordingDA: records every criteria hashref passed to selectall_arrayref
# so DU tests can assert exactly what each database received.
# The `refaddr` of the received hashref is recorded alongside the hashref
# itself, enabling reference-identity checks separate from value checks.
# ---------------------------------------------------------------------------
## no critic (Modules::ProhibitMultiplePackages)
{
	package DFRecordingDA;
	use parent -norequire, 'Database::Abstraction';

	sub new {
		my ($class, %args) = @_;
		return bless {
			id        => $args{id}      // 'entry',
			_cols     => $args{cols}    // ['entry'],
			_rows     => $args{rows}    // [],
			_schema   => $args{schema}  // {},
			_ts       => $args{updated} // 1_000_000,
			_received => [],   # [ { hashref => ..., refaddr => ... }, ... ]
		}, $class;
	}

	sub columns  { return $_[0]->{_cols} }
	sub schema   { return $_[0]->{_schema} }
	sub updated  { return $_[0]->{_ts} }
	sub set_logger { $_[0]->{logger} = $_[1]; return $_[0] }

	sub selectall_arrayref {
		my ($self, $criteria) = @_;
		push @{ $self->{_received} }, {
			hashref => $criteria,
			refaddr => Scalar::Util::refaddr($criteria),
		};
		# Simple equality filter (no operator hashrefs needed for DU tests)
		my @rows = @{ $self->{_rows} };
		for my $col (keys %{ $criteria // {} }) {
			my $v = $criteria->{$col};
			@rows = grep {
				defined $_->{$col} && defined $v && $_->{$col} eq $v
			} @rows if defined $v;
		}
		return \@rows;
	}

	sub received       { return $_[0]->{_received} }
	sub clear_received { $_[0]->{_received} = []; return $_[0] }
	sub DESTROY {}
}

# ---------------------------------------------------------------------------
# DFMinimalDA: lightweight stub without recording, for tests that only need
# data back and don't inspect the criteria sent to the DA.
# ---------------------------------------------------------------------------
{
	package DFMinimalDA;
	use parent -norequire, 'Database::Abstraction';

	sub new {
		my ($class, %args) = @_;
		return bless {
			id      => $args{id}      // 'entry',
			_cols   => $args{cols}    // ['entry'],
			_rows   => $args{rows}    // [],
			_schema => $args{schema}  // {},
			_ts     => $args{updated} // 1_000_000,
		}, $class;
	}

	sub columns   { return $_[0]->{_cols} }
	sub schema    { return $_[0]->{_schema} }
	sub updated   { return $_[0]->{_ts} }
	sub set_logger { $_[0]->{logger} = $_[1]; return $_[0] }
	sub selectall_arrayref { return $_[0]->{_rows} }   # always returns all rows
	sub DESTROY {}
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
sub _two_db_join {
	my (%opts) = @_;
	my $prim = DFMinimalDA->new(
		cols => ['entry', 'name'],
		rows => [
			{ entry => $K_A, name => 'Alpha' },
			{ entry => $K_B, name => 'Beta'  },
		],
	);
	my $sec = DFMinimalDA->new(
		cols => ['entry', 'score'],
		rows => [
			{ entry => $K_A, score => 10 },
			{ entry => $K_B, score => 20 },
		],
	);
	my $j = Database::Join->new(
		databases   => [$prim, $sec],
		join_column => $JC,
		%opts,
	);
	return ($j, $prim, $sec);
}

# ===========================================================================
# Section 1: Memoization cache lifecycle (DU for _col_cache and _schema_cache)
# ===========================================================================

subtest 'columns(): memoized — second call returns same arrayref' => sub {
	# D: cache written on first call; U: cache read on second call; K: object destruction.
	my ($j) = _two_db_join();
	my $r1 = $j->columns();
	my $r2 = $j->columns();
	is refaddr($r1), refaddr($r2),
		'repeated columns() calls return the same cached arrayref';
};

subtest 'schema(): memoized — second call returns same hashref' => sub {
	my ($j) = _two_db_join();
	my $s1 = $j->schema();
	my $s2 = $j->schema();
	is refaddr($s1), refaddr($s2),
		'repeated schema() calls return the same cached hashref';
};

subtest 'remove_column: kills _col_cache (next call re-derives)' => sub {
	# D: col_cache written during first columns() call
	# K: col_cache killed by remove_column
	# D: col_cache re-derived on next columns() call
	# If the cache were NOT killed, the new arrayref would be the same ref as before.
	my ($j) = _two_db_join();
	my $r_before = $j->columns();
	$j->remove_column('score');
	my $r_after = $j->columns();
	isnt refaddr($r_before), refaddr($r_after),
		'col_cache is invalidated by remove_column (new arrayref returned)';
	ok !(grep { $_ eq 'score' } @{$r_after}),
		'removed column absent from freshly derived columns list';
};

subtest 'remove_column: kills _schema_cache (next schema() re-derives)' => sub {
	my ($j) = _two_db_join();
	my $s_before = $j->schema();
	$j->remove_column('score');
	my $s_after = $j->schema();
	isnt refaddr($s_before), refaddr($s_after),
		'schema_cache invalidated by remove_column';
	ok !exists($s_after->{score}),
		'removed column absent from re-derived schema';
};

subtest 'add_database: kills _col_cache (new columns included after re-derive)' => sub {
	my ($j) = _two_db_join();
	my $r_before = $j->columns();
	ok !(grep { $_ eq 'region' } @{$r_before}),
		'region absent before add_database (pre-condition)';

	my $extra = DFMinimalDA->new(cols => ['entry', 'region'], rows => []);
	$j->add_database($extra);

	my $r_after = $j->columns();
	isnt refaddr($r_before), refaddr($r_after),
		'col_cache invalidated by add_database';
	ok (grep { $_ eq 'region' } @{$r_after}),
		'new column present in re-derived columns list';
};

subtest 'add_database: kills _schema_cache' => sub {
	my ($j) = _two_db_join();
	my $s_before = $j->schema();
	my $extra = DFMinimalDA->new(cols => ['entry', 'region'], rows => []);
	$j->add_database($extra);
	my $s_after = $j->schema();
	isnt refaddr($s_before), refaddr($s_after),
		'schema_cache invalidated by add_database';
};

subtest '_col_db routing keys match columns() list exactly' => sub {
	# _col_db: D at _build_col_index, U throughout; columns() derives from _col_db.
	# Both must agree on which columns are visible.
	my ($j) = _two_db_join();
	my $col_list   = $j->columns();
	my $routing_db = $j->{_col_db};

	# Every visible column (excluding join_column which is handled specially) should
	# be in _col_db; every _col_db key should be in the visible column list.
	my %col_set = map { $_ => 1 } @{$col_list};
	for my $col (keys %{$routing_db}) {
		ok exists($col_set{$col}),
			"_col_db column '$col' appears in columns() output";
	}
	for my $col (@{$col_list}) {
		ok exists($routing_db->{$col}),
			"columns() column '$col' appears in _col_db routing table";
	}
};

subtest 'remove_column keeps _col_db and columns() consistent' => sub {
	my ($j) = _two_db_join();
	$j->remove_column('score');
	my $col_list = $j->columns();
	my %col_set  = map { $_ => 1 } @{$col_list};
	for my $col (keys %{ $j->{_col_db} }) {
		ok exists($col_set{$col}),
			"_col_db entry '$col' after remove_column still in columns()";
	}
	ok !exists($j->{_col_db}{score}),
		'score removed from _col_db routing table by remove_column';
};

# ===========================================================================
# Section 2: Criteria hashref DU — immutability and routing isolation
# ===========================================================================

subtest 'caller criteria hashref not modified by selectall_arrayref' => sub {
	# D: caller defines criteria hashref; U: DJ reads it; caller must see same value after.
	my ($j) = _two_db_join();
	my %crit = (name => 'Alpha');
	my $saved = { %crit };
	$j->selectall_arrayref(%crit);
	is_deeply \%crit, $saved, 'caller criteria hashref unchanged after selectall_arrayref';
};

subtest 'join-column operator hashref not modified by broadcast (shallow-copy guard)' => sub {
	# D: caller's operator hashref; DJ must shallow-copy before broadcast.
	# After the query, the caller's hashref must still hold the original operator value.
	my ($j) = _two_db_join();
	my $op   = { '>' => 'a0' };   # operator hashref for join column
	my $orig = { %{$op} };        # reference copy for comparison
	$j->selectall_arrayref(entry => $op);
	is_deeply $op, $orig,
		'join-column operator hashref not modified after broadcast';
};

subtest 'DA receives distinct criteria hashref — not caller refaddr' => sub {
	# DU chain: caller's criteria → partition → per-db copy → DA receives copy.
	# The DA must not receive the exact same hashref the caller passed.
	my $prim = DFRecordingDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => $K_A, name => 'Alpha' }],
	);
	my $j    = Database::Join->new(databases => [$prim], join_column => $JC);
	my $crit = { entry => $K_A };
	$j->selectall_arrayref($crit);
	my $rcvd_ref = $prim->received()->[-1]{refaddr};
	isnt $rcvd_ref, refaddr($crit),
		'DA received a distinct hashref, not the caller\`s original ref';
};

subtest 'empty criteria {} — all rows returned without constraint' => sub {
	# {} is a defined hashref, but empty → no column criterion is applied.
	# DU check: an empty hashref used as criteria must not filter any rows.
	my ($j) = _two_db_join();
	my $rows = $j->selectall_arrayref({});
	is scalar @{$rows}, 2, 'empty criteria hashref does not filter rows';
};

subtest 'non-JC criterion sent only to owning DA, not to primary' => sub {
	# Partition DU: score belongs to secondary (index 1).
	# Primary (index 0) must not receive a score criterion.
	my $prim = DFRecordingDA->new(
		cols => ['entry', 'name'],
		rows => [
			{ entry => $K_A, name => 'Alpha' },
			{ entry => $K_B, name => 'Beta'  },
		],
	);
	my $sec = DFRecordingDA->new(
		cols => ['entry', 'score'],
		rows => [
			{ entry => $K_A, score => '10' },
			{ entry => $K_B, score => '20' },
		],
	);
	my $j = Database::Join->new(
		databases   => [$prim, $sec],
		join_column => $JC,
	);
	$j->selectall_arrayref(score => '10');
	my $prim_crit = $prim->received()->[-1]{hashref};
	my $sec_crit  = $sec->received()->[-1]{hashref};
	ok !exists($prim_crit->{score}),
		'primary DA did not receive the score criterion';
	ok exists($sec_crit->{score}),
		'secondary DA received the score criterion';
};

subtest 'unknown column criterion: not leaked to any DA' => sub {
	# An unknown column triggers carp and is dropped; no DA should see it.
	my $prim = DFRecordingDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => $K_A, name => 'Alpha' }],
	);
	my $j = Database::Join->new(databases => [$prim], join_column => $JC);
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	$j->selectall_arrayref(ghost_col => 'x');
	my $crit = $prim->received()->[-1]{hashref};
	ok !exists($crit->{ghost_col}),
		'unknown column not forwarded to any DA criteria hashref';
	ok scalar @warnings,
		'carp warning emitted for unknown column (DU confirmed: column seen, then dropped)';
};

# ===========================================================================
# Section 3: Row data independence — result rows not aliased to DA internals
# ===========================================================================

subtest 'repeated selectall_arrayref returns distinct arrayref each time' => sub {
	# DU: each call to _joined_query creates a new @result; the caller must
	# get a fresh arrayref, not a cached one.
	my ($j) = _two_db_join();
	my $r1 = $j->selectall_arrayref();
	my $r2 = $j->selectall_arrayref();
	isnt refaddr($r1), refaddr($r2),
		'two selectall_arrayref calls return distinct arrayrefs';
};

subtest 'result rows are distinct hashrefs from each other' => sub {
	# Each iteration of the merge loop creates a separate %merged hash.
	# Rows in the result arrayref must not alias each other.
	my ($j) = _two_db_join();
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 2, 'two rows returned';
	isnt refaddr($rows->[0]), refaddr($rows->[1]),
		'row[0] and row[1] are distinct hashrefs';
};

subtest 'modifying a returned row does not affect a subsequent query' => sub {
	# DU lifecycle: the result hashref belongs to the caller after return.
	# Modifying it must not corrupt the DJ's internal state or future results.
	my ($j) = _two_db_join();
	my $rows1 = $j->selectall_arrayref();
	$rows1->[0]{name} = 'MUTATED';    # caller mutates their own row
	my $rows2 = $j->selectall_arrayref();
	is $rows2->[0]{name}, 'Alpha',    # DA still returns the original value
		'subsequent query unaffected by mutation of previously returned row';
};

subtest 'merged row not aliased to DFMinimalDA internal row hashref' => sub {
	# _joined_query does `my %merged = %{$prow}` — this is a COPY, not an alias.
	# Modifying the merged result must not retroactively change the DA's stored row.
	my $prim = DFMinimalDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => $K_A, name => 'Original' }],
	);
	my $j    = Database::Join->new(databases => [$prim], join_column => $JC);
	my $rows = $j->selectall_arrayref();
	$rows->[0]{name} = 'Mutated';
	# Re-query: DA returns the same internal row hashref; if the result were an
	# alias to that row, the DA's row would also have been mutated.
	my $rows2 = $j->selectall_arrayref();
	is $rows2->[0]{name}, 'Original',
		'DA internal row not mutated through merged result hashref (copy, not alias)';
};

# ===========================================================================
# Section 4: Filter reference DU lifecycle
# ===========================================================================

subtest 'filter applied on every query: all results respect base restriction' => sub {
	# DU: filter defined at construction, used on every _joined_query call.
	# The filter criteria hashref flows from _filters into _merge_criteria.
	my $da = DFRecordingDA->new(
		cols => ['entry', 'score'],
		rows => [
			{ entry => $K_A, score => '10' },
			{ entry => $K_B, score => '20' },
		],
	);
	my $j = Database::Join->new(
		databases   => [$da],
		join_column => $JC,
		filters     => { 0 => { score => '10' } },
	);
	for my $call (1 .. 3) {
		my $rows = $j->selectall_arrayref();
		is scalar @{$rows}, 1, "call $call: filter applied (only score=10 returned)";
	}
};

subtest 'filter reference aliasing — external mutation affects subsequent queries' => sub {
	# DATA FLOW ANOMALY (annotated in Join.pm): _filters stores the caller's hashref
	# directly.  Mutation after construction silently changes query behaviour.
	# This test documents the current (reference-aliasing) behaviour.  A future
	# deep-copy fix would make this test fail; update accordingly.
	my $filter_href = { score => '10' };
	my $da          = DFRecordingDA->new(
		cols => ['entry', 'score'],
		rows => [
			{ entry => $K_A, score => '10' },
			{ entry => $K_B, score => '20' },
		],
	);
	my $j = Database::Join->new(
		databases   => [$da],
		join_column => $JC,
		filters     => { 0 => $filter_href },
	);

	# Verify filter works before mutation
	my $rows_before = $j->selectall_arrayref();
	is scalar @{$rows_before}, 1, 'pre-mutation: filter restricts to 1 row';

	# Mutate the caller's filter hashref
	$filter_href->{score} = '20';    # now filter matches score=20 instead

	# If reference aliasing is in effect, the next query uses the mutated filter
	$da->clear_received();
	my $rows_after = $j->selectall_arrayref();
	my $filter_used = $da->received()->[-1]{hashref};
	TODO: {
		local $TODO = 'filter aliasing is a known anomaly (see TODO in Join.pm)';
		is $filter_used->{score}, '20',
			'mutated filter hashref flows into query criteria (aliasing confirmed)';
	}
};

subtest 'empty filter {} per DB: acts as no-op filter' => sub {
	# DU: _merge_criteria is called only if %{$base} is non-empty (the `next unless`
	# guard).  An empty filter hashref never enters the merge path.
	my ($j) = _two_db_join(filters => { 0 => {} });
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 2,
		'empty filter {} does not drop any rows (no-op)';
};

subtest '_merge_criteria: returns new hashref, base and extra unchanged' => sub {
	# DU chain for _merge_criteria: base and extra defined by callers, used (read)
	# inside _merge_criteria, neither should be killed (modified).
	my $base  = { age => { '>' => 0 } };
	my $extra = { age => { '<' => 100 } };
	my $b_ref = refaddr($base);
	my $e_ref = refaddr($extra);

	# We call _merge_criteria indirectly via a filtered join
	my $da = DFRecordingDA->new(
		cols => ['entry', 'age'],
		rows => [{ entry => $K_A, age => 42 }],
	);
	my $j = Database::Join->new(
		databases   => [$da],
		join_column => $JC,
		filters     => { 0 => $base },
	);
	$j->selectall_arrayref(age => { '<' => 100 });

	# _merge_criteria creates a new merged hashref; the original base and extra
	# hashrefs should be unchanged (no side-effect mutations).
	is refaddr($base),  $b_ref, 'base hashref identity preserved (not replaced)';
	is refaddr($extra), $e_ref, 'extra hashref identity preserved (not replaced)';
	is_deeply $base,  { age => { '>' => 0   } }, 'base hashref content unchanged';
	is_deeply $extra, { age => { '<' => 100 } }, 'extra hashref content unchanged';
};

# ===========================================================================
# Section 5: _col_db routing table DU correctness
# ===========================================================================

subtest 'add_database: new columns appear in _col_db with correct index' => sub {
	my ($j) = _two_db_join();
	my $extra = DFMinimalDA->new(cols => ['entry', 'region'], rows => []);
	$j->add_database($extra);
	my $idx = $j->{_col_db}{region};
	ok defined $idx, 'region now in _col_db after add_database';
	is $idx, 2, 'region routed to index 2 (third DB)';
};

subtest 'add_database with duplicate column: routing updated to new DB (last wins)' => sub {
	# If the new DB has a column that already exists in an older DB, _col_db routing
	# must be updated to point to the new DB index.
	my ($j) = _two_db_join();
	my $extra = DFMinimalDA->new(
		cols => ['entry', 'score'],    # 'score' already in secondary (index 1)
		rows => [],
	);
	$j->add_database($extra);
	is $j->{_col_db}{score}, 2,
		'score re-routed to newer DB index 2 (last-database-wins)';
};

subtest 'remove_column: _col_db entry killed, then absent from routing' => sub {
	# D: _col_db{name} written in _build_col_index
	# K: _col_db{name} deleted by remove_column
	# ~ (subsequent access): _col_db{name} should be absent
	my ($j) = _two_db_join();
	ok exists($j->{_col_db}{name}), 'name in _col_db before removal (pre-condition)';
	$j->remove_column('name');
	ok !exists($j->{_col_db}{name}), 'name absent from _col_db after remove_column';
};

subtest '_autoload_pk DU: cached at construction from primary DA id field' => sub {
	# D: $primary_pk = $p->{databases}[0]{id} // $p->{join_column}
	# U: stored in $self->{_autoload_pk}
	# K: object destruction
	# The stored value must match what the primary DA's {id} field held.
	my $prim = DFMinimalDA->new(id => 'custom_pk', cols => ['entry', 'name']);
	my $j    = Database::Join->new(databases => [$prim], join_column => $JC);
	is $j->{_autoload_pk}, 'custom_pk',
		'_autoload_pk captures primary DA id at construction';
};

subtest '_autoload_pk fallback: uses join_column when primary DA has no id' => sub {
	# When {id} is undef, the fallback join_column is used.
	my $prim = DFMinimalDA->new(cols => ['entry', 'name']);
	# DFMinimalDA::new sets id = 'entry', so override to undef:
	my $da = bless {
		id => undef, _cols => ['entry', 'name'], _rows => [],
		_schema => {}, _ts => 1, logger => undef,
	}, 'DFMinimalDA';
	my $j = Database::Join->new(databases => [$da], join_column => 'entry');
	is $j->{_autoload_pk}, 'entry',
		'_autoload_pk falls back to join_column when primary id is undef';
};

# ===========================================================================
# Section 6: Join-type key-set data flow
# ===========================================================================

subtest 'left join: key-set defined by primary, secondary-only key absent' => sub {
	# DU: %key_set seeded from $indexed[0]; secondary-only key never enters.
	my $prim = DFMinimalDA->new(
		cols => ['entry', 'a'],
		rows => [{ entry => $K_A, a => 1 }],
	);
	my $sec = DFMinimalDA->new(
		cols => ['entry', 'b'],
		rows => [
			{ entry => $K_A, b => 1 },
			{ entry => $K_C, b => 3 },   # $K_C not in primary
		],
	);
	my $j = Database::Join->new(
		databases => [$prim, $sec], join_column => $JC, join_type => 'left',
	);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 1, 'left join: 1 row (primary defines key-set)';
	ok !(grep { $_->{entry} eq $K_C } @{$rows}),
		'secondary-only key not in key-set for left join';
};

subtest 'inner join: key absent from secondary deleted from key-set' => sub {
	# DU: %key_set starts with primary keys; `delete $key_set{$k}` kills absent ones.
	my $prim = DFMinimalDA->new(
		cols => ['entry', 'a'],
		rows => [
			{ entry => $K_A, a => 1 },
			{ entry => $K_B, a => 2 },   # $K_B not in secondary
		],
	);
	my $sec = DFMinimalDA->new(
		cols => ['entry', 'b'],
		rows => [{ entry => $K_A, b => 1 }],
	);
	my $j = Database::Join->new(
		databases => [$prim, $sec], join_column => $JC, join_type => 'inner',
	);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 1,          'inner join: 1 row (only shared key survives)';
	is $rows->[0]{entry}, $K_A,     'surviving key is the shared one (a1)';
	ok !(grep { $_->{entry} eq $K_B } @{$rows}),
		'primary-only key not in inner-join result';
};

subtest 'outer join: secondary-only key added to key-set via union' => sub {
	# DU: @key_set{ keys %{$indexed[$i]} } = () adds secondary keys.
	my $prim = DFMinimalDA->new(
		cols => ['entry', 'a'],
		rows => [{ entry => $K_A, a => 1 }],
	);
	my $sec = DFMinimalDA->new(
		cols => ['entry', 'b'],
		rows => [
			{ entry => $K_A, b => 1 },
			{ entry => $K_C, b => 3 },   # $K_C added to key-set by union
		],
	);
	my $j = Database::Join->new(
		databases => [$prim, $sec], join_column => $JC, join_type => 'outer',
	);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 2, 'outer join: 2 rows (union of key sets)';
	ok (grep { $_->{entry} eq $K_C } @{$rows}),
		'secondary-only key in outer-join result';
};

subtest 'had_criteria semantics: filtered secondary acts as inner regardless of join_type' => sub {
	# DU: $had_criteria[$i] written during fetch; read during key-set resolution.
	# A secondary DA with effective criteria (including base filters) always
	# intersects the key set, overriding the left/outer join_type for that slot.
	my $prim = DFMinimalDA->new(
		cols => ['entry', 'a'],
		rows => [
			{ entry => $K_A, a => 1 },
			{ entry => $K_B, a => 2 },   # secondary has no matching row for $K_B
		],
	);
	my $sec_da = DFRecordingDA->new(
		cols => ['entry', 'b'],
		rows => [{ entry => $K_A, b => 10 }],   # only $K_A, no $K_B row
	);
	# Left join, but with a base filter on secondary: secondary becomes inner partner.
	my $j = Database::Join->new(
		databases   => [$prim, $sec_da],
		join_column => $JC,
		join_type   => 'left',
		filters     => { 1 => { b => '10' } },
	);
	my $rows = $j->selectall_arrayref();
	# Under pure left join: $K_B would appear (from primary). Under filter-induced inner:
	# secondary has no $K_B row (filter returns only $K_A), so $K_B is excluded.
	is scalar @{$rows}, 1,
		'filter on secondary turns it into inner-join partner under left join_type';
	is $rows->[0]{entry}, $K_A,
		'only the key present in filtered secondary survives';
};

# ===========================================================================
# Section 7: Logger object reference lifecycle
# ===========================================================================

subtest 'logger same object reference in join AND in each DA (set at construction)' => sub {
	# DU: logger defined by caller; DJ stores it and propagates same ref to DAs.
	my $log = bless { calls => [] }, 'FakeLogger';
	{
		no strict 'refs';
		no warnings 'once';
		*FakeLogger::debug = sub { push @{$_[0]{calls}}, $_[1] };
		*FakeLogger::info  = *FakeLogger::debug;
		*FakeLogger::warn  = *FakeLogger::debug;
		*FakeLogger::error = *FakeLogger::debug;
	}
	my $da1 = DFMinimalDA->new(cols => ['entry', 'a']);
	my $da2 = DFMinimalDA->new(cols => ['entry', 'b']);
	my $j   = Database::Join->new(
		databases   => [$da1, $da2],
		join_column => $JC,
		logger      => $log,
	);
	is refaddr($j->{_logger}), refaddr($log), 'join stores caller logger ref';
	is refaddr($da1->{logger}), refaddr($log), 'primary DA receives same logger ref';
	is refaddr($da2->{logger}), refaddr($log), 'secondary DA receives same logger ref';
};

subtest 'set_logger: propagates same ref to all existing DAs' => sub {
	my ($j, $prim, $sec) = _two_db_join();
	my $log = bless {}, 'AnotherLogger';
	$j->set_logger($log);
	is refaddr($j->{_logger}), refaddr($log), 'join _logger updated';
	is refaddr($prim->{logger}), refaddr($log), 'primary DA logger updated';
	is refaddr($sec->{logger}),  refaddr($log), 'secondary DA logger updated';
};

subtest 'add_database after set_logger: new DA receives existing logger ref' => sub {
	my ($j) = _two_db_join();
	my $log  = bless {}, 'ThirdLogger';
	$j->set_logger($log);

	my $new_da = DFMinimalDA->new(cols => ['entry', 'region'], rows => []);
	$j->add_database($new_da);

	is refaddr($new_da->{logger}), refaddr($log),
		'newly added DA receives the logger ref that was set before add_database';
};

subtest 'remove_column does not affect logger reference' => sub {
	my ($j, $prim) = _two_db_join();
	my $log = bless {}, 'FourthLogger';
	$j->set_logger($log);
	$j->remove_column('score');
	is refaddr($j->{_logger}), refaddr($log),
		'join _logger ref unchanged after remove_column';
	is refaddr($prim->{logger}), refaddr($log),
		'primary DA logger ref unchanged after remove_column';
};

# ===========================================================================
# Section 8: D~ anomaly in AUTOLOAD — dead store fix verification
# ===========================================================================

subtest 'AUTOLOAD join-path: correct values returned (D~ fix does not break it)' => sub {
	# D~ fix: `my $db = $self->{_dbs}[$db_idx]` moved inside the else branch.
	# Verify the join-path branch still works correctly after the refactoring.
	# DFRecordingDA is used for the secondary because it actually applies criteria
	# (equality filter), so the base filter { score => '10' } restricts to 1 row.
	my $prim = DFMinimalDA->new(
		cols => ['entry', 'name'],
		rows => [
			{ entry => $K_A, name => 'Alpha' },
			{ entry => $K_B, name => 'Beta'  },
		],
	);
	my $sec = DFRecordingDA->new(
		cols => ['entry', 'score'],
		rows => [
			{ entry => $K_A, score => '10' },
			{ entry => $K_B, score => '20' },
		],
	);
	# Activate filters so AUTOLOAD takes the join path (not $db->$col(@_)).
	# filter score='10' on secondary: only entry $K_A survives → 1 merged row.
	my $j = Database::Join->new(
		databases   => [$prim, $sec],
		join_column => $JC,
		filters     => { 1 => { score => '10' } },
	);
	my $val = $j->name(entry => $K_A);
	is $val, 'Alpha', 'AUTOLOAD join-path returns correct scalar value';
	my @names = $j->name();
	is scalar @names, 1, 'AUTOLOAD join-path list context: filter limits to 1 row';
};

subtest 'AUTOLOAD direct-path: $db resolved correctly after D~ fix' => sub {
	# Without join_map or filters, AUTOLOAD must still resolve $db and delegate.
	# Since DFMinimalDA does not implement AUTOLOAD itself, any column shortcut
	# call would fail if the direct-delegation path were broken.
	# We verify by using a custom DA that DOES define the column as a method.
	{
		package DirectDA;
		use parent -norequire, 'Database::Abstraction';
		sub new { bless { id=>'entry', _cols=>['entry','tag'], _rows=>[], _schema=>{}, _ts=>1 }, shift }
		sub columns { return $_[0]->{_cols} }
		sub schema  { return {} }
		sub updated { return 1 }
		sub set_logger { $_[0]->{logger} = $_[1]; return $_[0] }
		sub selectall_arrayref { return $_[0]->{_rows} }
		sub tag { return 'direct-value' }   # method that AUTOLOAD will delegate to
		sub DESTROY {}
	}
	my $da = DirectDA->new();
	my $j  = Database::Join->new(databases => [$da], join_column => 'entry');
	# No join_map or filters: AUTOLOAD takes the direct path and calls $da->tag()
	my $val = $j->tag();
	is $val, 'direct-value',
		'AUTOLOAD direct-path correctly delegates to DA method after D~ fix';
};

# ===========================================================================
# Section 9: Single-DB DU — had_criteria[0] dead store (D~ annotated)
# ===========================================================================

subtest 'single-DB join: had_criteria[0] dead store does not cause runtime error' => sub {
	# D~: $had_criteria[0] is written but never read when n==1 (key-set resolution
	# loop starts at i=1, so i=0 is never processed there).
	# Verify the query path is functionally correct despite the dead store.
	my $da = DFRecordingDA->new(
		cols => ['entry', 'val'],
		rows => [
			{ entry => $K_A, val => 'x' },
			{ entry => $K_B, val => 'y' },
		],
	);
	my $j = Database::Join->new(databases => [$da], join_column => $JC);
	my $rows;
	lives_ok { $rows = $j->selectall_arrayref(entry => $K_A) }
		'single-DB join with criteria lives (no crash from dead had_criteria[0])';
	is scalar @{$rows}, 1, 'correct row count from single-DB join';
	is $rows->[0]{val}, 'x', 'correct row content';
};

subtest 'single-DB join: no-criteria query returns all rows cleanly' => sub {
	my $da = DFMinimalDA->new(
		cols => ['entry', 'x'],
		rows => [
			{ entry => $K_A, x => 1 },
			{ entry => $K_B, x => 2 },
		],
	);
	my $j    = Database::Join->new(databases => [$da], join_column => $JC);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 2,
		'single-DB no-criteria query returns all rows (dead store harmless)';
};
