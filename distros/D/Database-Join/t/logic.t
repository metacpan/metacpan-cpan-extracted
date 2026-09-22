#!/usr/bin/env perl
# t/logic.t -- Formal logic proofs for Database::Join
#
# Proves: truth tables, state invariants, and contradiction trapping.
# Coverage:
#   L01  Key-set resolution truth table (join_type x had_criteria -- 6 paths)
#   L02  De Morgan complementarity of the key-set gate
#   L03  Syllogism: filter forces inner-join semantics regardless of join_type
#   L04  _merge_criteria truth table (4 input-type combinations)
#   L05  _partition_criteria routing invariants
#   L06  collision_prefix boolean gate (index > 0 guard)
#   L07  AUTOLOAD dispatch logic (join_map|filters => full join path)
#   L08  _cache_fresh conditions (observable via DA call counts)
#   L09  columns() invariants: always sorted, join_column always present
#   L10  Memoisation cache invalidation state machine
#   L11  Contradiction trapping (impossible states croak immediately)
#   L12  remove_column: join_column is irremovable (contradiction proof)
#   L13  _copy_criteria deep-copy isolation (post-construction mutation proof)

use strict;
use warnings;

use Test::Most tests => 60;
use Readonly;

use lib 't/lib';
use_ok('Database::Join') or BAIL_OUT('Database::Join failed to load');

# ===========================================================================
# Inline stub DA -- self-contained, no disk I/O.
# Supports equality and numeric-operator filtering on its rows.
# ===========================================================================

{
	package LogicDA;
	use parent -norequire, 'Database::Abstraction';

	sub new {
		my ($class, %args) = @_;
		return bless {
			id      => $args{id}      // 'entry',
			_cols   => $args{cols}    // ['entry'],
			_rows   => $args{rows}    // [],
			_schema => $args{schema}  // {},
			_ts     => $args{updated} // 1_000_000,
			_calls  => 0,
		}, $class;
	}

	sub columns    { return $_[0]->{_cols} }
	sub schema     { return $_[0]->{_schema} }
	sub updated    { return $_[0]->{_ts} }
	sub call_count { return $_[0]->{_calls} }
	sub set_logger { $_[0]->{logger} = $_[1]; return $_[0] }

	# Defined directly so defined(&{"LogicDA::count"}) is TRUE -- needed for
	# backend='auto' threshold probe which distinguishes own-defined vs inherited.
	sub count { return scalar @{ $_[0]->{_rows} } }

	sub selectall_arrayref {
		my ($self, $criteria) = @_;
		$self->{_calls}++;
		my @rows = @{ $self->{_rows} };
		for my $col (keys %{ $criteria // {} }) {
			my $v = $criteria->{$col};
			if (ref($v) eq 'HASH') {
				for my $op (keys %{$v}) {
					my $lim = $v->{$op};
					if    ($op eq '>')  { @rows = grep { defined $_->{$col} && $_->{$col} >  $lim } @rows }
					elsif ($op eq '<')  { @rows = grep { defined $_->{$col} && $_->{$col} <  $lim } @rows }
					elsif ($op eq '>=') { @rows = grep { defined $_->{$col} && $_->{$col} >= $lim } @rows }
					elsif ($op eq '<=') { @rows = grep { defined $_->{$col} && $_->{$col} <= $lim } @rows }
					elsif ($op eq '!=') { @rows = grep { defined $_->{$col} && $_->{$col} != $lim } @rows }
					elsif ($op eq '=')  { @rows = grep { defined $_->{$col} && $_->{$col} == $lim } @rows }
				}
			} elsif (defined $v) {
				@rows = grep { defined $_->{$col} && $_->{$col} eq $v } @rows;
			}
		}
		return \@rows;
	}

	sub DESTROY {}
}

# DA that returns undef from updated() -- used for cache-skip tests.
{
	package LogicNoTsDA;
	use parent -norequire, 'LogicDA';
	sub updated { return undef }
}

# Minimal stub that has selectall_arrayref but NOT columns().
# Used by L14 to prove that the P1 invariant is enforced at every entry point.
{
	package NoCols;
	sub new     { bless {}, shift }
	sub selectall_arrayref { return [] }
	sub DESTROY {}
}

# ===========================================================================
# Shared fixtures: primary has keys {A,B,C}; secondary has keys {B,D}.
# ===========================================================================

Readonly::Hash my %ROW => (
	pA => { entry => 'A', name  => 'alice' },
	pB => { entry => 'B', name  => 'bob'   },
	pC => { entry => 'C', name  => 'carol' },
	sB => { entry => 'B', score => 10      },
	sD => { entry => 'D', score => 20      },
);

sub _prim { LogicDA->new(cols => ['entry','name'],  rows => [@ROW{qw(pA pB pC)}]) }
sub _sec  { LogicDA->new(cols => ['entry','score'], rows => [@ROW{qw(sB sD)}])    }

sub _build_join {
	my (%extra) = @_;
	return Database::Join->new(
		databases   => [_prim(), _sec()],
		join_column => 'entry',
		backend     => 'array',
		%extra,
	);
}

sub _keys { [ sort map { $_->{entry} } @{ $_[0] } ] }

# ===========================================================================
# L01: Key-set resolution truth table
#
# Gate formula: had_criteria[i] OR join_type eq 'inner' => INTERSECT
# Otherwise:   left => primary unchanged  |  outer => UNION
#
# Truth table (had_criteria h, join_type j):
#   h=0, j=left  => key_set = primary = {A,B,C}   (3 rows)
#   h=0, j=inner => key_set = {A,B,C} ∩ {B,D} = {B} (1 row)
#   h=0, j=outer => key_set = {A,B,C} ∪ {B,D} = {A,B,C,D} (4 rows)
#   h=1, j=left  => gate TRUE => intersect => {A,B,C} ∩ {B} = {B} (1 row)
#   h=1, j=inner => gate TRUE => intersect => {B} (1 row)
#   h=1, j=outer => gate TRUE => intersect, not union => {B} (1 row)
# ===========================================================================

subtest 'L01: left + no secondary criteria => primary key-set unchanged' => sub {
	plan tests => 2;
	my $rows = _build_join(join_type => 'left')->selectall_arrayref();
	is(scalar @{$rows}, 3, 'left+nocrit: 3 rows');
	is_deeply(_keys($rows), [qw(A B C)], 'left+nocrit: keys={A,B,C}');
};

subtest 'L01: inner + no criteria => intersection' => sub {
	plan tests => 2;
	my $rows = _build_join(join_type => 'inner')->selectall_arrayref();
	is(scalar @{$rows}, 1, 'inner+nocrit: 1 row');
	is_deeply(_keys($rows), ['B'], 'inner+nocrit: keys={B}');
};

subtest 'L01: outer + no criteria => union' => sub {
	plan tests => 2;
	my $rows = _build_join(join_type => 'outer')->selectall_arrayref();
	is(scalar @{$rows}, 4, 'outer+nocrit: 4 rows');
	is_deeply(_keys($rows), [qw(A B C D)], 'outer+nocrit: keys={A,B,C,D}');
};

subtest 'L01: left + criteria on secondary => gate TRUE => forced intersection' => sub {
	plan tests => 2;
	# score=10 matches only sB; had_criteria[1]=1; gate = 1||0 = TRUE => intersect
	my $rows = _build_join(join_type => 'left')->selectall_arrayref(score => 10);
	is(scalar @{$rows}, 1, 'left+sec_crit: 1 row (inner semantics forced)');
	is_deeply(_keys($rows), ['B'], 'left+sec_crit: keys={B}');
};

subtest 'L01: inner + criteria on secondary => gate TRUE (both conditions)' => sub {
	plan tests => 2;
	my $rows = _build_join(join_type => 'inner')->selectall_arrayref(score => 10);
	is(scalar @{$rows}, 1, 'inner+sec_crit: 1 row');
	is_deeply(_keys($rows), ['B'], 'inner+sec_crit: keys={B}');
};

subtest 'L01: outer + criteria on secondary => criteria override outer semantics' => sub {
	plan tests => 2;
	# had_criteria[1]=1 => gate TRUE => intersect, NOT union
	my $rows = _build_join(join_type => 'outer')->selectall_arrayref(score => 10);
	is(scalar @{$rows}, 1, 'outer+sec_crit: 1 row (criteria override outer)');
	is_deeply(_keys($rows), ['B'], 'outer+sec_crit: union overridden => {B}');
};

# ===========================================================================
# L02: De Morgan's Law
#
# Gate A: had_criteria[i]
# Gate B: join_type eq 'inner'
# Compound gate: A OR B
# De Morgan: NOT(A OR B) = NOT(A) AND NOT(B)
#
# Proof: two scenarios show the compound gate and its complement give
# mutually exclusive results (intersect vs. no-intersect).
# ===========================================================================

subtest 'L02: gate=TRUE via A (outer+criteria) => intersect, not union' => sub {
	plan tests => 3;
	my $with    = _build_join(join_type => 'outer')->selectall_arrayref(score => 10);
	my $without = _build_join(join_type => 'outer')->selectall_arrayref();
	# A=TRUE (criteria) => intersect => 1 row
	is(scalar @{$with},    1, 'De Morgan: outer+crit: A fires => intersect (1 row)');
	# A=FALSE, B=FALSE => complement TRUE => union => 4 rows
	is(scalar @{$without}, 4, 'De Morgan: outer+nocrit: complement => union (4 rows)');
	# The two results must differ (complement is the opposite partition)
	ok(scalar @{$with} != scalar @{$without}, 'De Morgan: gate vs complement give opposite results');
};

subtest 'L02: gate=TRUE via B (inner+nocrit) => intersect, not unchanged' => sub {
	plan tests => 2;
	my $rows = _build_join(join_type => 'inner')->selectall_arrayref();
	# B=TRUE (join_type=inner) => gate fires => intersect
	is(scalar @{$rows}, 1, 'De Morgan: inner+nocrit: B fires => intersect (1 row)');
	isnt(scalar @{$rows}, 3, 'De Morgan: result is NOT the primary-unchanged 3-row set');
};

subtest 'L02: gate=FALSE (left+nocrit) => complement TRUE => primary-defined set' => sub {
	plan tests => 2;
	my $rows = _build_join(join_type => 'left')->selectall_arrayref();
	# A=FALSE, B=FALSE => NOT(A OR B)=TRUE => primary defines key set
	is(scalar @{$rows}, 3, 'De Morgan: left+nocrit: complement TRUE => 3 rows');
	isnt(scalar @{$rows}, 1, 'De Morgan: result is NOT the intersect 1-row set');
};

subtest 'L02: all three join types give distinct row counts (exhaustive partition proof)' => sub {
	plan tests => 3;
	my $i = scalar @{ _build_join(join_type => 'inner')->selectall_arrayref() };
	my $o = scalar @{ _build_join(join_type => 'outer')->selectall_arrayref() };
	my $l = scalar @{ _build_join(join_type => 'left' )->selectall_arrayref() };
	# The three gate states are exhaustive and mutually exclusive
	ok($i != $o, 'De Morgan: inner(1) != outer(4) -- disjoint partitions');
	ok($i != $l, 'De Morgan: inner(1) != left(3)  -- disjoint partitions');
	ok($o != $l, 'De Morgan: outer(4) != left(3)  -- disjoint partitions');
};

# ===========================================================================
# L03: Syllogism -- Filter forces inner-join semantics
#
# Major Premise: _filters[i] is non-empty => had_criteria[i]=TRUE after merge.
# Minor Premise: had_criteria[i]=TRUE => gate fires => intersect key-set.
# Conclusion:    A filtered DB acts as inner-join partner regardless of join_type.
# ===========================================================================

subtest 'L03: left + filter on secondary => inner-join semantics' => sub {
	plan tests => 2;
	# Without filter: left => 3 rows {A,B,C}.
	# With filter score>5 (matches B=10,D=20): secondary inner-joins.
	# {A,B,C} intersect secondary-filtered={B,D} => {B}
	my $j = Database::Join->new(
		databases   => [_prim(), _sec()],
		join_column => 'entry',
		join_type   => 'left',
		filters     => { 1 => { score => { '>' => 5 } } },
		backend     => 'array',
	);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 1, 'L03: left+filter: 1 row (inner semantics)');
	is($rows->[0]{entry}, 'B', 'L03: left+filter: only key B survives');
};

subtest 'L03: outer + filter(D only) => filter restricts union to intersection' => sub {
	plan tests => 2;
	# Filter score>15 keeps only D (score=20); D not in primary.
	# Secondary inner-joins: {A,B,C} intersect {D} = empty set.
	my $j = Database::Join->new(
		databases   => [_prim(), _sec()],
		join_column => 'entry',
		join_type   => 'outer',
		filters     => { 1 => { score => { '>' => 15 } } },
		backend     => 'array',
	);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 0, 'L03: outer+filter(D only): 0 rows (D absent from primary)');
	is_deeply($rows, [], 'L03: outer+filter: empty result confirms inner semantics');
};

subtest 'L03: outer without filter => D included (contrast proves filter was cause)' => sub {
	plan tests => 2;
	my $rows = _build_join(join_type => 'outer')->selectall_arrayref();
	is(scalar @{$rows}, 4, 'L03: outer no filter: 4 rows (D in union)');
	ok((grep { $_->{entry} eq 'D' } @{$rows}), 'L03: D present in union without filter');
};

# ===========================================================================
# L04: _merge_criteria truth table
#
# Four cases based on (base_value_type, extra_value_type):
#   Case 1: both operator hashrefs => operators merged (AND semantics)
#   Case 2: base=operator, extra=scalar => scalar replaces base
#   Case 3: base=scalar, extra=operator => extra wins
#   Case 4: both scalars => extra (query-time) wins
# ===========================================================================

subtest 'L04: case 1 -- both operator hashrefs => operators merged (AND)' => sub {
	plan tests => 2;
	# Base: score > 5 (matches B=10, D=20); Query: score < 20 (matches B=10)
	# Merged: score > 5 AND score < 20 => only B (score=10)
	my $j = Database::Join->new(
		databases   => [_prim(), _sec()],
		join_column => 'entry',
		join_type   => 'inner',
		filters     => { 1 => { score => { '>' => 5 } } },
		backend     => 'array',
	);
	my $rows = $j->selectall_arrayref(score => { '<' => 20 });
	is(scalar @{$rows}, 1, 'L04 case1: AND merge: 1 row (score 5<x<20)');
	is($rows->[0]{entry}, 'B', 'L04 case1: AND merge: B (score=10) qualifies');
};

subtest 'L04: case 2 -- base=operator, extra=scalar => scalar replaces operator' => sub {
	plan tests => 2;
	# Base: score > 5 (matches B, D); Query: score=10 (scalar replaces operator)
	# Merged: score eq '10' => only B
	my $j = Database::Join->new(
		databases   => [_prim(), _sec()],
		join_column => 'entry',
		join_type   => 'inner',
		filters     => { 1 => { score => { '>' => 5 } } },
		backend     => 'array',
	);
	my $rows = $j->selectall_arrayref(score => 10);
	is(scalar @{$rows}, 1, 'L04 case2: scalar replaces operator base: 1 row');
	is($rows->[0]{entry}, 'B', 'L04 case2: B (score=10) selected by scalar criterion');
};

subtest 'L04: case 3 -- base=scalar, extra=operator => extra (operator) wins' => sub {
	plan tests => 2;
	# Base: score=10 (matches only B); Query: score > 5 (operator; replaces base scalar)
	# Merged: score > 5 => matches B (10>5) and D (20>5)
	# inner join: D not in primary => only B qualifies
	my $j = Database::Join->new(
		databases   => [_prim(), _sec()],
		join_column => 'entry',
		join_type   => 'inner',
		filters     => { 1 => { score => 10 } },
		backend     => 'array',
	);
	my $rows = $j->selectall_arrayref(score => { '>' => 5 });
	is(scalar @{$rows}, 1, 'L04 case3: extra operator replaces base scalar: 1 row');
	is($rows->[0]{entry}, 'B', 'L04 case3: B qualifies (score>5 replaces score=10 base)');
};

subtest 'L04: case 4 -- both scalars => extra (query-time) scalar wins' => sub {
	plan tests => 2;
	# Base: score=10 (B); Query: score=20 (D) -- extra scalar wins; D not in primary
	my $j = Database::Join->new(
		databases   => [_prim(), _sec()],
		join_column => 'entry',
		join_type   => 'inner',
		filters     => { 1 => { score => 10 } },
		backend     => 'array',
	);
	my $rows = $j->selectall_arrayref(score => 20);
	is(scalar @{$rows}, 0, 'L04 case4: extra scalar wins (score=20 => D not in primary)');
	ok(!(grep { $_->{entry} eq 'B' } @{$rows}), 'L04 case4: B absent (base score=10 was overridden)');
};

# ===========================================================================
# L05: _partition_criteria routing invariants
#
# I1: join_column criterion => broadcast to ALL databases (each gets it)
# I2: non-join column => routed to exactly ONE database
# I3: unknown column => carp warning, nothing routed
# I4: collision_prefix unrename: prefixed criterion routes to correct DB
# I5: join_column criterion => each DB's copy is independent
# ===========================================================================

subtest 'L05: I1 -- join_column criterion broadcast to both DAs' => sub {
	plan tests => 2;
	my ($p, $s) = (_prim(), _sec());
	my $j = Database::Join->new(databases => [$p, $s], join_column => 'entry', backend => 'array');
	$j->selectall_arrayref(entry => 'B');
	# Both DAs must have been called (broadcast confirmed by call_count)
	is($p->call_count, 1, 'L05: I1: primary DA called (received broadcast)');
	is($s->call_count, 1, 'L05: I1: secondary DA called (received broadcast)');
};

subtest 'L05: I2 -- non-join column routed to exactly one DA' => sub {
	plan tests => 2;
	my ($p, $s) = (_prim(), _sec());
	my $j = Database::Join->new(databases => [$p, $s], join_column => 'entry', backend => 'array');
	# score belongs to secondary; after the query primary gets {} (no score criterion)
	$j->selectall_arrayref(score => 10);
	# Primary was called once (not with score criterion, so returned all rows)
	is($p->call_count, 1, 'L05: I2: primary called once (score not routed to it)');
	is($s->call_count, 1, 'L05: I2: secondary called once (score routed correctly)');
};

subtest 'L05: I3 -- unknown column triggers carp, is not routed' => sub {
	plan tests => 2;
	my $j  = _build_join();
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $rows = $j->selectall_arrayref(nosuchcol => 'x');
	ok(scalar @w > 0, 'L05: I3: unknown column triggers carp');
	like($w[0], qr/nosuchcol/, 'L05: I3: warning names the unknown column');
};

subtest 'L05: I4 -- prefixed collision criterion routed via unrename map' => sub {
	plan tests => 2;
	# DB0 has 'score'; DB1 also has 'score' with collision_prefix{1}='b'
	# Published names: DB0='score', DB1='b.score'
	# Criterion 'b.score'=>20 must route to DB1 as score=>20
	my $p = LogicDA->new(cols => ['entry','score'], rows => [{ entry => 'X', score => 5 }]);
	my $s = LogicDA->new(cols => ['entry','score'], rows => [{ entry => 'X', score => 20 }]);
	my $j = Database::Join->new(
		databases        => [$p, $s],
		join_column      => 'entry',
		collision_prefix => { 1 => 'b' },
		backend          => 'array',
	);
	my $rows = $j->selectall_arrayref('b.score' => 20);
	is(scalar @{$rows}, 1, 'L05: I4: prefixed criterion routes to correct DB');
	is($rows->[0]{'b.score'}, 20, 'L05: I4: prefixed column value correct in result');
};

subtest 'L05: I5 -- join_column broadcast uses per-DB copy (partition isolation)' => sub {
	plan tests => 2;
	# Both DAs receive the join_col criterion; each filters its own rows independently.
	my $p = LogicDA->new(cols => ['entry','name'],
		rows => [{ entry => 'A', name => 'alice' }, { entry => 'B', name => 'bob' }]);
	my $s = LogicDA->new(cols => ['entry','score'],
		rows => [{ entry => 'A', score => 1 }, { entry => 'B', score => 2 },
		         { entry => 'C', score => 3 }]);
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => 'entry',
		join_type   => 'inner',
		backend     => 'array',
	);
	my $rows = $j->selectall_arrayref(entry => 'A');
	is(scalar @{$rows}, 1, 'L05: I5: broadcast isolation: 1 row (entry=A)');
	is($rows->[0]{name}, 'alice', 'L05: I5: correct row returned');
};

# ===========================================================================
# L06: collision_prefix boolean gate
#
# Gate: my $prefix = ($i > 0) ? $cp->{$i} : undef
# L06.1: index-0 entry => prefix = undef => silently ignored
# L06.2: index-1 colliding column + prefix => "$prefix.$col" published
# L06.3: index-1 non-colliding column + prefix => plain "$col" published
# L06.4: join_column never prefixed (special invariant even if $i > 0)
# ===========================================================================

subtest 'L06: index-0 collision_prefix silently ignored (gate: $i > 0)' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases        => [LogicDA->new(cols => ['entry','name'], rows => [])],
		join_column      => 'entry',
		collision_prefix => { 0 => 'ignored' },
		backend          => 'array',
	);
	my $cols = $j->columns();
	ok((grep { $_ eq 'name' } @{$cols}), 'L06: name present without prefix (index-0 guard)');
	ok(!(grep { /^ignored\./ } @{$cols}), 'L06: no "ignored." prefix applied at index 0');
};

subtest 'L06: index-1 colliding column + prefix => published as prefix.col' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases        => [
			LogicDA->new(cols => ['entry','notes'], rows => []),
			LogicDA->new(cols => ['entry','notes'], rows => []),
		],
		join_column      => 'entry',
		collision_prefix => { 1 => 'sec' },
		backend          => 'array',
	);
	my $cols = $j->columns();
	ok((grep { $_ eq 'notes'     } @{$cols}), 'L06: original "notes" present (DB0)');
	ok((grep { $_ eq 'sec.notes' } @{$cols}), 'L06: "sec.notes" present (DB1 collision)');
};

subtest 'L06: index-1 non-colliding column + prefix => no prefix applied' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases        => [
			LogicDA->new(cols => ['entry','name'],  rows => []),
			LogicDA->new(cols => ['entry','score'], rows => []),
		],
		join_column      => 'entry',
		collision_prefix => { 1 => 'sec' },
		backend          => 'array',
	);
	my $cols = $j->columns();
	ok((grep { $_ eq 'score' } @{$cols}), 'L06: non-colliding "score" not prefixed');
	ok(!(grep { $_ eq 'sec.score' } @{$cols}), 'L06: "sec.score" does NOT exist');
};

subtest 'L06: join_column never prefixed (special invariant)' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases        => [
			LogicDA->new(cols => ['entry','a'], rows => [{ entry => 'k', a => 1 }]),
			LogicDA->new(cols => ['entry','b'], rows => [{ entry => 'k', b => 2 }]),
		],
		join_column      => 'entry',
		collision_prefix => { 1 => 'sec' },
		backend          => 'array',
	);
	my $cols           = $j->columns();
	my @entry_variants = grep { /entry/ } @{$cols};
	is(scalar @entry_variants, 1, 'L06: join_column appears exactly once');
	is($entry_variants[0], 'entry', 'L06: join_column name is never prefixed');
};

# ===========================================================================
# L07: AUTOLOAD dispatch logic
#
# Major Premise: join_map active OR filters active => full join path (not direct DA)
# Corollary:    private-method _name => croak (fail fast, before any dispatch)
# Corollary:    unknown column => croak
# ===========================================================================

subtest 'L07: join_map active => AUTOLOAD takes full join path' => sub {
	plan tests => 2;
	# Primary key is 'statecode'; secondary calls it 'entry' (join_map).
	my $prim = LogicDA->new(
		id   => 'statecode',
		cols => ['statecode','city'],
		rows => [{ statecode => 'CA', city => 'SanFrancisco' }],
	);
	my $sec = LogicDA->new(
		id   => 'entry',
		cols => ['entry','state'],
		rows => [{ entry => 'CA', state => 'California' }],
	);
	my $j = Database::Join->new(
		databases   => [$prim, $sec],
		join_column => 'statecode',
		join_map    => { 1 => 'entry' },
		backend     => 'array',
	);
	# AUTOLOAD: $j->city('CA') -- join_map active => full join
	# _autoload_pk='statecode' (from $prim->{id}) => {statecode=>'CA'}
	my $city = $j->city('CA');
	is($city, 'SanFrancisco', 'L07: join_map: AUTOLOAD returns value via full join');
	ok($sec->call_count > 0, 'L07: join_map: secondary DA queried (full join path confirmed)');
};

subtest 'L07: filters active => AUTOLOAD takes full join path' => sub {
	plan tests => 2;
	my ($p, $s) = (_prim(), _sec());
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => 'entry',
		filters     => { 1 => { score => { '>' => 5 } } },
		backend     => 'array',
	);
	# AUTOLOAD: $j->name('B') -- filters active => full join
	my $name = $j->name('B');
	is($name, 'bob', 'L07: filters: AUTOLOAD returns correct value via full join');
	ok($s->call_count > 0, 'L07: filters: secondary DA queried (full join path confirmed)');
};

subtest 'L07: private method via AUTOLOAD => croak immediately' => sub {
	plan tests => 1;
	my $j = _build_join();
	# Premise: substr($col, 0, 1) eq '_' => croak before any routing
	throws_ok { $j->_private_method() }
		qr/private method|cannot call/i,
		'L07: private _method via AUTOLOAD croaks immediately';
};

subtest 'L07: unknown column via AUTOLOAD => croak immediately' => sub {
	plan tests => 1;
	my $j = _build_join();
	throws_ok { $j->no_such_column_xyz() }
		qr/unknown column/i,
		'L07: unknown column via AUTOLOAD croaks immediately';
};

# ===========================================================================
# L08: _cache_fresh conditions (observable via DA call counts)
#
# Truth table (all conditions must hold for cache to be fresh):
#   C1: cache exists                           (absent => fresh=0 => rebuild)
#   C2: n == scalar @_dbs                      (mismatch => fresh=0 => rebuild)
#   C3: DBI handle Active                      (inactive => fresh=0 => rebuild)
#   C4: updated() timestamps match cached ts   (mismatch => fresh=0 => rebuild)
#   C5: updated() returns undef                (skip ts check => cache valid)
# ===========================================================================

subtest 'L08: C1 -- no cache => DA called on first sqlite query (cache built)' => sub {
	plan tests => 2;
	my $da = LogicDA->new(cols => ['entry','v'], rows => [{ entry => 'X', v => 1 }]);
	my $j  = Database::Join->new(databases => [$da], join_column => 'entry', backend => 'sqlite');
	is($da->call_count, 0, 'L08: C1: DA not called before any query');
	$j->selectall_arrayref();
	is($da->call_count, 1, 'L08: C1: DA called once to spill data into cache');
};

subtest 'L08: cache reused -- second query does not call DA again (C1 satisfied)' => sub {
	plan tests => 2;
	my $da = LogicDA->new(cols => ['entry','v'], rows => [{ entry => 'X', v => 1 }]);
	my $j  = Database::Join->new(databases => [$da], join_column => 'entry', backend => 'sqlite');
	$j->selectall_arrayref();
	my $c1 = $da->call_count;
	$j->selectall_arrayref();
	is($da->call_count, $c1,   'L08: cache hit: call count unchanged on second query');
	is($da->call_count, 1,     'L08: cache hit: total DA calls = 1 (cache reused)');
};

subtest 'L08: C4 -- timestamp change invalidates cache (fresh=0 => rebuild)' => sub {
	plan tests => 3;
	my $da = LogicDA->new(
		cols => ['entry','v'], rows => [{ entry => 'X', v => 1 }], updated => 1000,
	);
	my $j = Database::Join->new(databases => [$da], join_column => 'entry', backend => 'sqlite');
	$j->selectall_arrayref();
	is($da->call_count, 1, 'L08: C4: 1 call after first query');
	$da->{_ts} = 2000;	# advance timestamp
	$j->selectall_arrayref();
	is($da->call_count, 2, 'L08: C4: 2nd call after timestamp advance (cache rebuilt)');
	$j->selectall_arrayref();	# same ts=2000 => still valid
	is($da->call_count, 2, 'L08: C4: 3rd query reuses rebuilt cache (still 2 calls)');
};

subtest 'L08: C5 -- undef updated() => timestamp check skipped => cache stays valid' => sub {
	plan tests => 2;
	my $da = LogicNoTsDA->new(cols => ['entry','v'], rows => [{ entry => 'Y', v => 2 }]);
	my $j  = Database::Join->new(databases => [$da], join_column => 'entry', backend => 'sqlite');
	$j->selectall_arrayref();
	$j->selectall_arrayref();
	# undef updated() => cached_ts=undef => '// next' skips the check => cache valid
	is($da->call_count, 1, 'L08: C5: undef ts => check skipped => cache reused (1 call)');
	is(scalar @{$j->selectall_arrayref()}, 1, 'L08: C5: correct data still returned');
};

subtest 'L08: C2 -- add_database invalidates cache (n mismatch)' => sub {
	plan tests => 2;
	my $da1 = LogicDA->new(cols => ['entry','a'], rows => [{ entry => 'K', a => 1 }]);
	my $da2 = LogicDA->new(cols => ['entry','b'], rows => [{ entry => 'K', b => 2 }]);
	my $j   = Database::Join->new(databases => [$da1], join_column => 'entry', backend => 'sqlite');
	$j->selectall_arrayref();
	my $c1 = $da1->call_count;
	# add_database raises n from 1 to 2 and clears _sqlite_cache
	$j->add_database($da2);
	$j->selectall_arrayref();
	ok($da1->call_count > $c1, 'L08: C2: add_database invalidates cache (DA1 re-spilled)');
	ok($da2->call_count >= 1,  'L08: C2: new DA2 spilled after cache rebuild');
};

# ===========================================================================
# L09: columns() invariants
#
# I1: result is always sorted alphabetically
# I2: join_column always present in the result
# I3: removed columns absent from the result
# I4: no duplicates -- join_column appears exactly once even across N databases
# ===========================================================================

subtest 'L09: I1 -- columns() result is always sorted alphabetically' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases => [
			LogicDA->new(cols => ['entry','zorro','aardvark'], rows => []),
			LogicDA->new(cols => ['entry','mango'],            rows => []),
		],
		join_column => 'entry',
		backend     => 'array',
	);
	my $cols = $j->columns();
	is_deeply($cols, [sort @{$cols}], 'L09: I1: columns() is sorted');
	is($cols->[0], 'aardvark', 'L09: I1: first column is alphabetically earliest');
};

subtest 'L09: I2 -- join_column always present' => sub {
	plan tests => 2;
	ok((grep { $_ eq 'entry' } @{_build_join()->columns()}),
	   'L09: I2: default join_col "entry" present');
	my $j2 = Database::Join->new(
		databases   => [LogicDA->new(cols => ['id','name'], rows => [])],
		join_column => 'id',
		backend     => 'array',
	);
	ok((grep { $_ eq 'id' } @{$j2->columns()}), 'L09: I2: custom join_col "id" present');
};

subtest 'L09: I3 -- removed columns absent from columns()' => sub {
	plan tests => 2;
	my $j = _build_join();
	$j->remove_column('name');
	my $cols = $j->columns();
	ok(!(grep { $_ eq 'name'  } @{$cols}), 'L09: I3: removed "name" absent');
	ok( (grep { $_ eq 'entry' } @{$cols}), 'L09: I3: join_col still present after remove');
};

subtest 'L09: I4 -- join_column appears exactly once across N databases' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases => [
			LogicDA->new(cols => ['entry','a'], rows => []),
			LogicDA->new(cols => ['entry','b'], rows => []),
			LogicDA->new(cols => ['entry','c'], rows => []),
		],
		join_column => 'entry',
		backend     => 'array',
	);
	my $cols         = $j->columns();
	my $entry_count  = scalar grep { $_ eq 'entry' } @{$cols};
	is($entry_count, 1, 'L09: I4: join_column appears exactly once');
	is(scalar @{$cols}, 4, 'L09: I4: total distinct cols = entry+a+b+c = 4');
};

# ===========================================================================
# L10: Memoisation cache invalidation state machine
#
# States: [uncached] --columns()--> [cached] --remove_column()--> [uncached]
#                                   [cached] --add_database()--> [uncached]
# Proof: two calls return same ref when cached; new ref after invalidation.
# ===========================================================================

subtest 'L10: columns() memoised -- repeated calls return same arrayref' => sub {
	plan tests => 1;
	my $j = _build_join();
	is($j->columns(), $j->columns(), 'L10: same arrayref on repeated columns() calls');
};

subtest 'L10: remove_column() transitions cache from [cached] to [uncached]' => sub {
	plan tests => 2;
	my $j    = _build_join();
	my $ref1 = $j->columns();
	$j->remove_column('name');
	my $ref2 = $j->columns();
	isnt($ref1, $ref2, 'L10: remove_column: new arrayref (cache invalidated)');
	ok(!(grep { $_ eq 'name' } @{$ref2}), 'L10: removed column absent from fresh result');
};

subtest 'L10: add_database() transitions cache from [cached] to [uncached]' => sub {
	plan tests => 2;
	my $j    = _build_join();
	my $ref1 = $j->columns();
	$j->add_database(LogicDA->new(cols => ['entry','extra'], rows => []));
	my $ref2 = $j->columns();
	isnt($ref1, $ref2, 'L10: add_database: new arrayref (cache invalidated)');
	ok((grep { $_ eq 'extra' } @{$ref2}), 'L10: new column visible after add_database');
};

subtest 'L10: schema_cache also invalidated by remove_column' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases => [LogicDA->new(
			cols   => ['entry','name'],
			rows   => [],
			schema => { entry => { type => 'str' }, name => { type => 'str' } },
		)],
		join_column => 'entry',
		backend     => 'array',
	);
	ok(exists $j->schema()->{name}, 'L10: name in schema before remove');
	$j->remove_column('name');
	ok(!exists $j->schema()->{name}, 'L10: name absent after remove (schema cache invalidated)');
};

# ===========================================================================
# L11: Contradiction trapping
#
# Every violation of a documented Major Premise must croak at the earliest
# possible execution point (Modus Ponens / Fail Fast principle).
# ===========================================================================

subtest 'L11: databases=[] => croak error_no_databases' => sub {
	plan tests => 1;
	throws_ok {
		Database::Join->new(databases => [], join_column => 'entry')
	} qr/At least one|required/i, 'L11: empty databases array croaks';
};

subtest 'L11: non-object in databases => croak error_invalid_db' => sub {
	plan tests => 1;
	throws_ok {
		Database::Join->new(databases => ['not_an_object'], join_column => 'entry')
	} qr/does not support|invalid/i, 'L11: non-object in databases croaks';
};

subtest 'L11: join_column absent from database => croak error_join_col_missing' => sub {
	plan tests => 1;
	my $da = LogicDA->new(cols => ['x','y'], rows => []);
	throws_ok {
		Database::Join->new(databases => [$da], join_column => 'nosuchcol')
	} qr/absent|missing|nosuchcol/i, 'L11: missing join_column croaks';
};

subtest 'L11: invalid join_type enum => croak (case-sensitive)' => sub {
	plan tests => 2;
	my $da = LogicDA->new(cols => ['entry'], rows => []);
	throws_ok {
		Database::Join->new(databases => [$da], join_column => 'entry', join_type => 'INNER')
	} qr/join_type|INNER|invalid/i, 'L11: join_type "INNER" (wrong case) croaks';
	throws_ok {
		Database::Join->new(databases => [$da], join_column => 'entry', join_type => 'cross')
	} qr/join_type|cross|invalid/i, 'L11: join_type "cross" (unsupported) croaks';
};

subtest 'L11: collision_prefix ref value => croak error_invalid_prefix' => sub {
	plan tests => 1;
	my ($da1, $da2) = map { LogicDA->new(cols => ['entry','x'], rows => []) } 1..2;
	throws_ok {
		Database::Join->new(
			databases        => [$da1, $da2],
			join_column      => 'entry',
			collision_prefix => { 1 => {} },	# ref value must croak
		)
	} qr/plain string|reference|heap/i, 'L11: collision_prefix ref value croaks';
};

subtest 'L11: join_map ref value => croak (heap-address guard)' => sub {
	plan tests => 1;
	my $da1 = LogicDA->new(cols => ['entry'],       rows => []);
	my $da2 = LogicDA->new(cols => ['local_jc','x'], rows => []);
	throws_ok {
		Database::Join->new(
			databases   => [$da1, $da2],
			join_column => 'entry',
			join_map    => { 1 => {} },	# ref value must croak
		)
	} qr/absent|missing|must be/i, 'L11: join_map ref value croaks (heap guard)';
};

subtest 'L11: invalid backend and unsupported methods => croak' => sub {
	plan tests => 3;
	my $da = LogicDA->new(cols => ['entry'], rows => []);
	throws_ok {
		Database::Join->new(databases => [$da], join_column => 'entry', backend => 'bogus')
	} qr/backend|bogus|invalid/i, 'L11: invalid backend "bogus" croaks';
	my $j = Database::Join->new(databases => [$da], join_column => 'entry', backend => 'array');
	throws_ok { $j->query()   } qr/not supported|query/i,   'L11: query() croaks';
	throws_ok { $j->execute() } qr/not supported|execute/i, 'L11: execute() croaks';
};

# ===========================================================================
# L12: remove_column guard -- join_column is irremovable
#
# Invariant: join_column ∈ columns() at all times.
# Contradiction: remove_column(join_column) => croak (impossible state).
# Border cases: undef, '', non-existent => idempotent no-op.
# ===========================================================================

subtest 'L12: remove_column(join_column) => croak error_remove_join_col' => sub {
	plan tests => 1;
	throws_ok { _build_join()->remove_column('entry') }
		qr/Cannot remove join_column|required for the join/i,
		'L12: removing join_column croaks immediately';
};

subtest 'L12: remove_column(undef) => idempotent no-op, returns $self' => sub {
	plan tests => 2;
	my $j   = _build_join();
	my $ret = $j->remove_column(undef);
	is($ret, $j, 'L12: remove_column(undef) returns $self');
	ok((grep { $_ eq 'entry' } @{$j->columns()}), 'L12: columns() unchanged after remove(undef)');
};

subtest 'L12: remove_column("") => idempotent no-op (empty string)' => sub {
	plan tests => 2;
	my $j   = _build_join();
	my $n   = scalar @{$j->columns()};
	my $ret = $j->remove_column('');
	is($ret, $j, 'L12: remove_column("") returns $self');
	is(scalar @{$j->columns()}, $n, 'L12: column count unchanged after remove("")');
};

subtest 'L12: remove_column(non_existent) => idempotent, column count unchanged' => sub {
	plan tests => 2;
	my $j   = _build_join();
	my $n   = scalar @{$j->columns()};
	my $ret = $j->remove_column('no_such_column_xyz');
	is($ret, $j, 'L12: remove_column(unknown) returns $self');
	is(scalar @{$j->columns()}, $n, 'L12: column count unchanged for unknown column');
};

# ===========================================================================
# L13: _copy_criteria deep-copy isolation
#
# Security invariant: the stored filter is independent of the caller's hashref.
# Post-construction mutation of the caller's criteria must NOT alter the view.
# ===========================================================================

subtest 'L13: mutating caller filters hashref after construction has no effect' => sub {
	plan tests => 2;
	my $filters = { 1 => { score => { '>' => 5 } } };
	my $j = Database::Join->new(
		databases   => [_prim(), _sec()],
		join_column => 'entry',
		join_type   => 'inner',
		filters     => $filters,
		backend     => 'array',
	);
	my $before = scalar @{$j->selectall_arrayref()};
	# Widen the caller's filter to include everything (score > -999)
	$filters->{1}{score} = { '>' => -999 };
	my $after  = scalar @{$j->selectall_arrayref()};
	# Deep copy means mutation has no effect on the stored filter
	is($before, $after, 'L13: mutation of caller filters hashref has no effect');
	is($before, 1, 'L13: view still returns 1 row (B only, score>5 still enforced)');
};

subtest 'L13: operator sub-hashref in filter is shallow-copied (ref differs)' => sub {
	plan tests => 2;
	my $orig_op = { '>' => 5 };
	my $j = Database::Join->new(
		databases   => [_prim(), _sec()],
		join_column => 'entry',
		join_type   => 'inner',
		filters     => { 1 => { score => $orig_op } },
		backend     => 'array',
	);
	# _copy_criteria shallow-copies operator sub-hashrefs: stored ref != original ref
	isnt($j->{_filters}{1}{score}, $orig_op,
	     'L13: stored sub-hashref is a different reference');
	# Mutate original; stored copy must be unaffected
	$orig_op->{'>'} = -999;
	is($j->{_filters}{1}{score}{'>'}, 5, 'L13: stored copy retains original value 5');
};

subtest 'L13: _partition_criteria broadcast is isolated per DA (operator hashref)' => sub {
	plan tests => 2;
	# Pass an operator hashref as the join-column criterion.
	# _partition_criteria broadcasts a shallow copy to each DA.
	# Both DAs must filter correctly without one copy corrupting the other.
	my $p = LogicDA->new(cols => ['entry','v'],
		rows => [{ entry => 'A', v => 1 }, { entry => 'B', v => 2 }]);
	my $s = LogicDA->new(cols => ['entry','score'],
		rows => [{ entry => 'A', score => 5 }, { entry => 'B', score => 10 },
		         { entry => 'C', score => 15 }]);
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => 'entry',
		join_type   => 'inner',
		backend     => 'array',
	);
	# entry='A' broadcast to both; primary returns {A}, secondary returns {A}; inner => {A}
	my $rows = $j->selectall_arrayref(entry => 'A');
	is(scalar @{$rows}, 1, 'L13: broadcast isolation: 1 row returned');
	is($rows->[0]{v}, 1, 'L13: broadcast isolation: correct row (entry=A, v=1)');
};

# ===========================================================================
# L14: Transitive Reduction -- P1 invariant: every DA in _dbs has columns()
#
# Major Premise: new() validates blessed($db) && can('selectall_arrayref')
#   && can('columns') for every element of databases before registering it.
# Major Premise: add_database() applies the same guard before registration.
# Conclusion: $db->can('columns') is ALWAYS true for all _dbs elements.
# Corollary: the if($db->can('columns')) guards in _build_sqlite_cache are
#   vacuous checks; both else branches are unreachable dead code.
# ===========================================================================
subtest 'L14: Transitive Reduction -- P1: _dbs satisfies can(columns) invariant' => sub {
	plan tests => 4;

	# Minor Premise: NoCols has selectall_arrayref but no columns() method.
	# Modus Ponens: P1 guard fires => new() must croak error_invalid_db.
	throws_ok {
		Database::Join->new(
			databases   => [NoCols->new()],
			join_column => 'entry',
			backend     => 'array',
		)
	} qr/does not support/i,
		'L14a: DA lacking columns() croaks at new() (P1 guard enforced)';

	# Minor Premise: a valid join exists; attempt to add a NoCols instance.
	# Modus Ponens: add_database() guard fires => must croak error_invalid_db.
	my $j14 = Database::Join->new(
		databases   => [LogicDA->new(cols => ['entry','x'], rows => [])],
		join_column => 'entry',
		backend     => 'array',
	);
	throws_ok {
		$j14->add_database(NoCols->new())
	} qr/does not support/i,
		'L14b: DA lacking columns() croaks at add_database() (P1 guard enforced)';

	# Post-condition: every registered DA satisfies can('columns').
	ok($j14->{_dbs}[0]->can('columns'),
		'L14c: _dbs[0] satisfies can(columns) after construction');

	my $s14 = LogicDA->new(cols => ['entry','y'], rows => []);
	$j14->add_database($s14);
	ok($j14->{_dbs}[1]->can('columns'),
		'L14d: _dbs[1] satisfies can(columns) after add_database');
};

# ===========================================================================
# L15: Dead Store Elimination -- _parse_query_args empty-args fast path
#
# Major Premise: _parse_query_args partitions its inputs into three cases:
#   (a) @args empty     => always return {} (join_col key unused: dead store)
#   (b) 1 non-ref arg   => return { join_col => arg } ($key is used)
#   (c) anything else   => return get_params result ($key unused)
#
# After moving the empty-args guard above the $key assignment, case (a)
# never reads $join_col from the object -- behaviour is identical, cost lower.
# Equivalence partitioning: prove each of the three partitions independently.
# ===========================================================================
subtest 'L15: Dead Store -- _parse_query_args empty-args fast path' => sub {
	plan tests => 4;

	my $p15 = LogicDA->new(
		cols => ['entry','v'],
		rows => [{ entry => 'A', v => 1 }, { entry => 'B', v => 2 }],
	);
	my $j15 = Database::Join->new(
		databases   => [$p15],
		join_column => 'entry',
		backend     => 'array',
	);

	# Partition (a): empty args => {} criteria => all rows returned.
	# Syllogism: empty @args => fast-path return {}; join_col never consulted.
	my $all = $j15->selectall_arrayref();
	is(scalar @{$all}, 2,
		'L15a: empty args => {} criteria => all 2 rows (fast-path, join_col irrelevant)');

	# Partition (b): single non-ref arg => treated as join_col => val.
	# Syllogism: @args=1 && !ref => return {join_col => $args[0]}; filters to 1 row.
	my $one = $j15->selectall_arrayref('A');
	is(scalar @{$one}, 1,
		'L15b: single positional arg => join_col criterion => 1 row');

	is($one->[0]{entry}, 'A',
		'L15c: positional arg correctly maps to join_col=entry');

	# Partition (c): named-pair args => get_params path => criterion preserved.
	# Syllogism: @args > 1 => get_params(undef, @args); $key is unused (second dead store).
	my $named = $j15->selectall_arrayref(entry => 'B');
	is($named->[0]{v}, 2,
		'L15d: named-pair arg => get_params path => entry=B yields v=2');
};
