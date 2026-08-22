#!/usr/bin/perl

# Transaction-flow tests for Database::Join.
# Tests walk entities through complete lifecycle phases, verify state
# consistency at every boundary, test mid-flight failure and recovery,
# and assert idempotency across repeated state transitions.

use strict;
use warnings;

use Test::Most tests => 87;
use Readonly;
use Scalar::Util qw(refaddr);
use Carp qw(croak);

use_ok('Database::Join');	# T1

# ---------------------------------------------------------------------------
# Inline component DA — configurable rows, fail-on-demand for mid-flight tests
# ---------------------------------------------------------------------------
{
	package TransactionDA;
	use parent -norequire, 'Database::Abstraction';
	use Carp qw(croak);

	sub new {
		my ($class, %args) = @_;
		return bless {
			cols    => $args{cols}    // ['entry'],
			rows    => $args{rows}    // [],
			id      => $args{id}      // 'entry',
			schema  => $args{schema}  // {},
			updated => $args{updated} // 1,
			_fail   => $args{fail}    // 0,
			_calls  => 0,
			_logger => undef,
		}, $class;
	}

	sub columns    { return $_[0]->{cols} }
	sub schema     { return $_[0]->{schema} }
	sub updated    { return $_[0]->{updated} }
	sub set_logger { $_[0]->{_logger} = $_[1]; return $_[0] }
	sub get_logger { return $_[0]->{_logger} }
	sub call_count { return $_[0]->{_calls} }
	sub set_fail   { $_[0]->{_fail} = $_[1]; return $_[0] }
	sub reset_calls { $_[0]->{_calls} = 0; return $_[0] }

	sub selectall_arrayref {
		my ($self, $criteria) = @_;
		$self->{_calls}++;
		croak 'TransactionDA: simulated mid-flight failure' if $self->{_fail};
		$criteria //= {};
		my @out;
		ROW: for my $row (@{ $self->{rows} }) {
			for my $col (keys %{$criteria}) {
				my $val = $criteria->{$col};
				if (ref $val eq 'HASH') {
					for my $op (keys %{$val}) {
						my $rhs = $val->{$op};
						if    ($op eq '>')  { next ROW unless defined $row->{$col} && $row->{$col} >  $rhs }
						elsif ($op eq '<')  { next ROW unless defined $row->{$col} && $row->{$col} <  $rhs }
						elsif ($op eq '>=') { next ROW unless defined $row->{$col} && $row->{$col} >= $rhs }
						elsif ($op eq '<=') { next ROW unless defined $row->{$col} && $row->{$col} <= $rhs }
						elsif ($op eq '!=') { next ROW unless defined $row->{$col} && $row->{$col} != $rhs }
					}
				} elsif (!defined $val) {
					next ROW if defined $row->{$col};
				} else {
					next ROW unless defined $row->{$col} && $row->{$col} eq $val;
				}
			}
			push @out, { %{$row} };
		}
		return \@out;
	}

	sub DESTROY {}
}

# ---------------------------------------------------------------------------
# Inline mock logger — records calls and carries an identity string
# ---------------------------------------------------------------------------
{
	package MockLogger;
	sub new  { bless { id => $_[1] }, shift }
	sub debug {}
	sub info  {}
	sub id    { return $_[0]->{id} }
}

# ---------------------------------------------------------------------------
# Readonly constants for row fixtures and key values
# ---------------------------------------------------------------------------
Readonly::Scalar my $K1 => 'k1';
Readonly::Scalar my $K2 => 'k2';
Readonly::Scalar my $K3 => 'k3';

Readonly::Hash my %ALICE => ( entry => $K1, name => 'Alice' );
Readonly::Hash my %BOB   => ( entry => $K2, name => 'Bob'   );

Readonly::Scalar my $SCORE_HIGH => 90;
Readonly::Scalar my $SCORE_LOW  => 70;
Readonly::Scalar my $SCORE_MID  => 80;

# ============================================================================
# Section 1: Construction Transaction
# Lifecycle: attempt bad construction → nothing leaks; then good construction →
# object enters OPERATIONAL state with correct internal routing table.
# ============================================================================
note '--- S1: Construction Transaction ---';

# Failed construction: empty databases → croak, no object escapes into scope
throws_ok {	# T2
	Database::Join->new(databases => [], join_column => 'entry')
} qr/At least one Database::Abstraction object is required/,
	'S1-P1: empty databases array → croak before any object exists';

# Build two DAs that cover independent columns
my $p1 = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [ {%ALICE}, {%BOB} ],
);
my $s1 = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [
		{ entry => $K1, score => $SCORE_HIGH },
		{ entry => $K2, score => $SCORE_LOW  },
	],
);

my $j1 = Database::Join->new(databases => [$p1, $s1], join_column => 'entry');
isa_ok($j1, 'Database::Join', 'S1-P2: successful construction');	# T3

# Post-construction state invariants
my %cols1 = map { $_ => 1 } @{ $j1->columns() };
ok($cols1{entry}, 'S1-P3a: join_col "entry" appears in columns()');	# T4
ok($cols1{name},  'S1-P3b: primary col "name" in columns()');	# T5
ok($cols1{score}, 'S1-P3c: secondary col "score" in columns()');	# T6
is($j1->{_join_type}, 'left',  'S1-P3d: default join_type stored as "left"');	# T7
is($j1->{_join_col},  'entry', 'S1-P3e: join_col stored correctly');	# T8
is($j1->{_col_db}{name},  0, 'S1-P3f: "name" routed to DB index 0');	# T9
is($j1->{_col_db}{score}, 1, 'S1-P3g: "score" routed to DB index 1');	# T10

# First query validates full join execution from fresh-constructed state
my $rows1_init = $j1->selectall_arrayref();
is(scalar @{$rows1_init}, 2, 'S1-P4: initial query returns 2 merged rows');	# T11

# ============================================================================
# Section 2: Build -> Extend -> Query Lifecycle
# Lifecycle: 1-DB join → query baseline → add_database → verify new cols →
# query again → add 3rd DB → query again. Each phase asserts state consistency.
# ============================================================================
note '--- S2: Build/Extend/Query Lifecycle ---';

my $p2 = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [ {%ALICE}, {%BOB} ],
);
my $j2 = Database::Join->new(databases => [$p2], join_column => 'entry');

# Phase 1: single-DB baseline
my %cols2_pre = map { $_ => 1 } @{ $j2->columns() };
ok(!$cols2_pre{score}, 'S2-P1a: before add_database, "score" absent from columns');	# T12
my $rows2_pre = $j2->selectall_arrayref();
is(scalar @{$rows2_pre}, 2, 'S2-P1b: single-DB join returns 2 rows');	# T13

# Phase 2: extend with secondary DA
my $s2 = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [
		{ entry => $K1, score => $SCORE_HIGH },
		{ entry => $K2, score => $SCORE_LOW  },
	],
);
$j2->add_database($s2);
my %cols2_post = map { $_ => 1 } @{ $j2->columns() };
ok($cols2_post{score}, 'S2-P2a: after add_database, "score" in columns');	# T14
my $rows2_mid = $j2->selectall_arrayref();
is(scalar @{$rows2_mid}, 2, 'S2-P2b: after add_database, row count unchanged');	# T15
my ($alice2) = grep { $_->{name} eq 'Alice' } @{$rows2_mid};
is($alice2->{score}, $SCORE_HIGH, 'S2-P2c: Alice row contains score from secondary DA');	# T16

# Phase 3: extend again with tertiary DA
my $t2 = TransactionDA->new(
	cols => ['entry', 'rank'],
	rows => [ { entry => $K1, rank => 1 }, { entry => $K2, rank => 2 } ],
);
$j2->add_database($t2);
my $rows2_final = $j2->selectall_arrayref();
is(scalar @{$rows2_final}, 2, 'S2-P3a: after 2nd add_database, row count still 2');	# T17
my ($k1_row2) = grep { $_->{entry} eq $K1 } @{$rows2_final};
is($k1_row2->{rank}, 1, 'S2-P3b: k1 row carries rank=1 from tertiary DA');	# T18
my @arr2 = $j2->selectall_array();
is(scalar @arr2, 2, 'S2-P3c: selectall_array after 3-DB lifecycle returns 2 elements');	# T19

# ============================================================================
# Section 3: Filter -> Compound Query Lifecycle
# Lifecycle: construct with per-DB base filter → query without extra criteria →
# query with AND-merged criteria → query with scalar-overwrite → query on
# independent col → count() consistency.
# ============================================================================
note '--- S3: Filter/Compound-Query Lifecycle ---';

my $p3 = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [ {%ALICE}, {%BOB} ],
);
my $s3 = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [
		{ entry => $K1, score => $SCORE_HIGH },
		{ entry => $K2, score => $SCORE_LOW  },
	],
);
# Base filter on secondary: score > 60 (both 70 and 90 qualify)
my $j3 = Database::Join->new(
	databases   => [$p3, $s3],
	join_column => 'entry',
	filters     => { 1 => { score => { '>' => 60 } } },
);

# Phase 1: filter alone
my $rows3a = $j3->selectall_arrayref();
is(scalar @{$rows3a}, 2, 'S3-P1: base filter score>60 → 2 rows qualify');	# T20

# Phase 2: filter AND query with different operator → _merge_criteria AND semantics
my $rows3b = $j3->selectall_arrayref(score => { '<' => $SCORE_MID + 5 });
is(scalar @{$rows3b}, 1, 'S3-P2a: filter(>60) AND query(<85) merged → 1 row');	# T21
is($rows3b->[0]{entry}, $K2, 'S3-P2b: the qualifying row is k2 (score=70)');	# T22

# Phase 3: filter AND query with same operator key → extra overwrites base
my $rows3c = $j3->selectall_arrayref(score => { '>' => $SCORE_MID });
is(scalar @{$rows3c}, 1, 'S3-P3: same op key >80 overwrites filter >60 → 1 row');	# T23

# Phase 4: query overwrites filter to a value no row satisfies
my $rows3d = $j3->selectall_arrayref(score => { '>' => 100 });
is(scalar @{$rows3d}, 0, 'S3-P4: query >100 overwrites filter → 0 rows');	# T24

# Phase 5: criterion on primary col (independent routing) while filter active on secondary
my $rows3e = $j3->selectall_arrayref(name => 'Alice');
is(scalar @{$rows3e}, 1, 'S3-P5: name=Alice on primary + filter on secondary → 1 row');	# T25

# Phase 6: join_col broadcast + filter
my $rows3f = $j3->selectall_arrayref(entry => $K1);
is(scalar @{$rows3f}, 1, 'S3-P6: entry=k1 broadcast + filter → 1 row');	# T26

# Phase 7: count() consistency
is($j3->count(), 2, 'S3-P7a: count() with base filter alone → 2');	# T27
is($j3->count(score => { '>' => $SCORE_MID }), 1, 'S3-P7b: count() after criterion merge → 1');	# T28

# ============================================================================
# Section 4: Cache Coherence Lifecycle
# Lifecycle: populate columns() cache → verify hit → remove_column → cache busted
# → verify rebuild → add_database → cache busted again → verify rebuild.
# ============================================================================
note '--- S4: Cache Coherence Lifecycle ---';

my $p4 = TransactionDA->new(
	cols   => ['entry', 'name'],
	rows   => [ { entry => $K1, name => 'Alice' } ],
	schema => { entry => { type => 'text' }, name => { type => 'text' } },
);
my $s4 = TransactionDA->new(
	cols   => ['entry', 'score'],
	rows   => [ { entry => $K1, score => $SCORE_HIGH } ],
	schema => { entry => { type => 'text' }, score => { type => 'int' } },
);
my $j4 = Database::Join->new(databases => [$p4, $s4], join_column => 'entry');

# Phase 1: Populate and verify cache hit
my $cols4a = $j4->columns();
my $cols4b = $j4->columns();
is(refaddr($cols4a), refaddr($cols4b), 'S4-P1a: consecutive columns() → same cached ref');	# T29

my $sch4a = $j4->schema();
my $sch4b = $j4->schema();
is(refaddr($sch4a), refaddr($sch4b), 'S4-P1b: consecutive schema() → same cached ref');	# T30

# Phase 2: remove_column invalidates both caches
$j4->remove_column('name');
my $cols4c = $j4->columns();
isnt(refaddr($cols4c), refaddr($cols4a), 'S4-P2a: remove_column → col cache invalidated');	# T31
ok(!(grep { $_ eq 'name' } @{$cols4c}), 'S4-P2b: rebuilt columns() excludes removed col');	# T32

# Phase 3: Repeated call re-caches the post-removal list
my $cols4d = $j4->columns();
is(refaddr($cols4c), refaddr($cols4d), 'S4-P3: columns() re-cached after remove_column');	# T33

# Phase 4: add_database busts the cache again
my $t4 = TransactionDA->new(
	cols => ['entry', 'rank'],
	rows => [ { entry => $K1, rank => 7 } ],
);
$j4->add_database($t4);
my $cols4e = $j4->columns();
isnt(refaddr($cols4e), refaddr($cols4d), 'S4-P4a: add_database → cache invalidated again');	# T34
ok((grep { $_ eq 'rank' } @{$cols4e}), 'S4-P4b: rebuilt columns() includes new col');	# T35

# Phase 5: schema() rebuilt without previously removed col
ok(!exists $j4->schema()->{name}, 'S4-P5: schema() rebuilt and lacks removed col "name"');	# T36

# ============================================================================
# Section 5: Mid-Flight DA Failure and Recovery
# Lifecycle: baseline query → enable DA failure mid-flight → verify exception
# propagates → verify DA call counts → disable failure → verify full recovery.
# Asserts that local variables in _joined_query are stack-unwound cleanly and
# no persistent partial state is left on the join object.
# ============================================================================
note '--- S5: Mid-Flight DA Failure and Recovery ---';

my $p5 = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [ {%ALICE}, {%BOB} ],
);
my $s5 = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [
		{ entry => $K1, score => $SCORE_HIGH },
		{ entry => $K2, score => $SCORE_LOW  },
	],
);
my $j5 = Database::Join->new(databases => [$p5, $s5], join_column => 'entry');

# Phase 1: Baseline — verify normal operation and capture call counts
my $baseline5 = $j5->selectall_arrayref();
is(scalar @{$baseline5}, 2, 'S5-P1a: baseline query → 2 rows');	# T37
is($p5->call_count(), 1, 'S5-P1b: primary DA called once during baseline');	# T38
is($s5->call_count(), 1, 'S5-P1c: secondary DA called once during baseline');	# T39

# Phase 2: Enable mid-flight failure on secondary DA → exception must propagate
$s5->set_fail(1);
throws_ok {	# T40
	$j5->selectall_arrayref()
} qr/TransactionDA: simulated mid-flight failure/,
	'S5-P2: mid-flight secondary DA failure → exception propagates to caller';

# Both DAs were invoked: primary succeeds, secondary fails
is($p5->call_count(), 2, 'S5-P3: primary was called during the failed query');	# T41
is($s5->call_count(), 2, 'S5-P4: secondary was invoked and then failed');	# T42

# Phase 3: Disable failure → full recovery; state not corrupted
$s5->set_fail(0);
my $recovery5 = $j5->selectall_arrayref();
is(scalar @{$recovery5}, 2, 'S5-P5: after recovery, query returns 2 rows');	# T43
is_deeply($recovery5, $baseline5, 'S5-P6: recovered result identical to baseline');	# T44
is($j5->{_col_db}{score}, 1, 'S5-P7: _col_db routing intact after mid-flight failure');	# T45

# ============================================================================
# Section 6: Idempotency
# Lifecycle: repeated identical queries return independent arrayrefs with the
# same content; remove_column called N times leaves the same stable state;
# count() agrees with selectall_arrayref() length after all mutations.
# ============================================================================
note '--- S6: Idempotency ---';

my $p6 = TransactionDA->new(
	cols => ['entry', 'name', 'tag'],
	rows => [
		{ entry => $K1, name => 'Alice', tag => 'A' },
		{ entry => $K2, name => 'Bob',   tag => 'B' },
	],
);
my $s6 = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [
		{ entry => $K1, score => $SCORE_HIGH },
		{ entry => $K2, score => $SCORE_LOW  },
	],
);
my $j6 = Database::Join->new(databases => [$p6, $s6], join_column => 'entry');

# Phase 1: Repeated queries produce independent refs with identical content
my $q6a = $j6->selectall_arrayref();
my $q6b = $j6->selectall_arrayref();
isnt(refaddr($q6a), refaddr($q6b), 'S6-P1a: repeated query → distinct arrayrefs');	# T46
is_deeply($q6a, $q6b, 'S6-P1b: repeated query → identical content');	# T47

# Phase 2: remove_column N times → idempotent stable state
$j6->remove_column('tag');
my $count6_r1 = scalar @{ $j6->columns() };
$j6->remove_column('tag');	# 2nd call — idempotent
my $count6_r2 = scalar @{ $j6->columns() };
$j6->remove_column('tag');	# 3rd call — still idempotent
my $count6_r3 = scalar @{ $j6->columns() };
is($count6_r1, $count6_r2, 'S6-P2a: 2nd remove_column idempotent (same column count)');	# T48
is($count6_r2, $count6_r3, 'S6-P2b: 3rd remove_column idempotent');	# T49

# Phase 3: Query results stable across calls after idempotent state changes
my $q6c = $j6->selectall_arrayref();
my $q6d = $j6->selectall_arrayref();
is(scalar @{$q6c}, 2, 'S6-P3a: row count stable after idempotent removes');	# T50
is_deeply($q6c, $q6d, 'S6-P3b: query content consistent after idempotent removes');	# T51

# Phase 4: count() agrees with selectall_arrayref() length
is($j6->count(), scalar @{ $j6->selectall_arrayref() },
	'S6-P4: count() equals length of selectall_arrayref()');	# T52

# Phase 5: fetchrow_hashref idempotent for same key
my $frow6a = $j6->fetchrow_hashref(entry => $K1);
my $frow6b = $j6->fetchrow_hashref(entry => $K1);
is_deeply($frow6a, $frow6b, 'S6-P5: fetchrow_hashref idempotent for same key');	# T53

# ============================================================================
# Section 7: Logger Lifecycle
# Lifecycle: build without logger → query works → set_logger → verify propagation
# to all existing DAs → add_database → verify new DA inherits logger →
# set_logger again → verify all DAs (including the late addition) updated.
# ============================================================================
note '--- S7: Logger Lifecycle ---';

my $log7a = MockLogger->new('first');
my $log7b = MockLogger->new('second');

my $p7 = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [ { entry => $K1, name => 'Alice' } ],
);
my $s7 = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [ { entry => $K1, score => $SCORE_HIGH } ],
);
my $j7 = Database::Join->new(databases => [$p7, $s7], join_column => 'entry');

# Phase 1: No logger — DAs are loggerless; queries still work
ok(!defined $p7->get_logger(), 'S7-P1a: primary DA has no logger initially');	# T54
ok(!defined $s7->get_logger(), 'S7-P1b: secondary DA has no logger initially');	# T55
is(scalar @{ $j7->selectall_arrayref() }, 1, 'S7-P1c: query succeeds without logger');	# T56

# Phase 2: set_logger propagates to all existing DAs simultaneously
$j7->set_logger($log7a);
is($j7->{_logger}->id(), 'first', 'S7-P2a: logger stored on join object');	# T57
is($p7->get_logger()->id(), 'first', 'S7-P2b: logger propagated to primary DA');	# T58
is($s7->get_logger()->id(), 'first', 'S7-P2c: logger propagated to secondary DA');	# T59

# Phase 3: add_database after set_logger → new DA inherits current logger
my $t7 = TransactionDA->new(
	cols => ['entry', 'rank'],
	rows => [ { entry => $K1, rank => 1 } ],
);
$j7->add_database($t7);
is($t7->get_logger()->id(), 'first', 'S7-P3: newly added DA inherits existing logger');	# T60

# Phase 4: set_logger again → all DAs (including the late addition) updated
$j7->set_logger($log7b);
is($p7->get_logger()->id(), 'second', 'S7-P4a: original primary DA logger updated');	# T61
is($t7->get_logger()->id(), 'second', 'S7-P4b: late-added DA logger also updated');	# T62

# ============================================================================
# Section 8: Multi-Object Isolation
# Lifecycle: two independent join objects built from the same component DAs →
# operations on one must not corrupt the other's column view, cache, or
# query results.
# ============================================================================
note '--- S8: Multi-Object Isolation ---';

my $pShared = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [ {%ALICE}, {%BOB} ],
);
my $sShared = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [
		{ entry => $K1, score => $SCORE_HIGH },
		{ entry => $K2, score => $SCORE_LOW  },
	],
);
my $ja = Database::Join->new(databases => [$pShared, $sShared], join_column => 'entry');
my $jb = Database::Join->new(databases => [$pShared, $sShared], join_column => 'entry');

# Phase 1: Both objects see the same data initially
is(scalar @{ $ja->selectall_arrayref() }, 2, 'S8-P1a: join_a returns 2 rows');	# T63
is(scalar @{ $jb->selectall_arrayref() }, 2, 'S8-P1b: join_b returns 2 rows');	# T64

# Phase 2: remove_column on join_a leaves join_b's view intact
$ja->remove_column('name');
ok(!(grep { $_ eq 'name' } @{ $ja->columns() }), 'S8-P2a: "name" removed from join_a');	# T65
ok((grep { $_ eq 'name' } @{ $jb->columns() }),  'S8-P2b: "name" still present in join_b');	# T66

# Phase 3: Query results reflect independent column views
my $row_a8 = $ja->fetchrow_hashref(entry => $K1);
my $row_b8 = $jb->fetchrow_hashref(entry => $K1);
ok(!exists $row_a8->{name}, 'S8-P3a: join_a row lacks "name" (removed from that view)');	# T67
ok(exists  $row_b8->{name}, 'S8-P3b: join_b row still has "name"');	# T68

# Phase 4: add_database to join_b only — join_a column index unaffected
my $new8 = TransactionDA->new(
	cols => ['entry', 'rank'],
	rows => [ { entry => $K1, rank => 99 } ],
);
$jb->add_database($new8);
ok((grep { $_ eq 'rank' } @{ $jb->columns() }),
	'S8-P4a: join_b now has "rank" after add_database');	# T69
ok(!(grep { $_ eq 'rank' } @{ $ja->columns() }),
	'S8-P4b: join_a does not see "rank" — column indices are independent');	# T70

# Phase 5: Column counts diverge confirming isolation
my $ja_ncols = scalar @{ $ja->columns() };
my $jb_ncols = scalar @{ $jb->columns() };
isnt($ja_ncols, $jb_ncols,
	'S8-P5: join_a and join_b have different column counts after diverged operations');	# T71

# ============================================================================
# Section 9: join_map Cross-Name Lifecycle
# Lifecycle: construct with join_map alias → verify alias hidden → query via
# canonical join_col → merged rows carry canonical not alias → add_database
# with second alias → verify canonical-only exposure continues.
# ============================================================================
note '--- S9: join_map Cross-Name Lifecycle ---';

# Primary uses 'entry'; secondary uses 'tid' as its join key
my $p9 = TransactionDA->new(
	cols => ['entry', 'city'],
	rows => [ { entry => $K1, city => 'London' }, { entry => $K2, city => 'Paris' } ],
);
my $s9 = TransactionDA->new(
	cols => ['tid', 'score'],
	rows => [
		{ tid => $K1, score => $SCORE_HIGH },
		{ tid => $K2, score => $SCORE_LOW  },
	],
);
my $j9 = Database::Join->new(
	databases   => [$p9, $s9],
	join_column => 'entry',
	join_map    => { 1 => 'tid' },
);

# Phase 1: columns() exposes canonical name, hides alias
my %cols9 = map { $_ => 1 } @{ $j9->columns() };
ok(!$cols9{tid},  'S9-P1a: alias "tid" absent from columns()');	# T72
ok($cols9{entry}, 'S9-P1b: canonical "entry" present in columns()');	# T73

# Phase 2: Query routes correctly despite alias mismatch
my $rows9a = $j9->selectall_arrayref(entry => $K1);
is(scalar @{$rows9a}, 1, 'S9-P2a: query on canonical join_col with join_map → 1 row');	# T74
ok(!exists $rows9a->[0]{tid},   'S9-P2b: alias "tid" absent from merged row');	# T75
ok(exists  $rows9a->[0]{entry}, 'S9-P2c: canonical "entry" present in merged row');	# T76
is($rows9a->[0]{score}, $SCORE_HIGH, 'S9-P2d: score fetched correctly via alias routing');	# T77

# Phase 3: add_database with a second alias → canonical-only exposure continues
my $t9 = TransactionDA->new(
	cols => ['ref', 'rank'],
	rows => [ { ref => $K1, rank => 1 }, { ref => $K2, rank => 2 } ],
);
$j9->add_database($t9, join_column => 'ref');
my %cols9b = map { $_ => 1 } @{ $j9->columns() };
ok(!$cols9b{ref},  'S9-P3a: 2nd alias "ref" also absent from columns()');	# T78
ok($cols9b{rank},  'S9-P3b: data col "rank" from 3rd DA in columns()');	# T79

# ============================================================================
# Section 10: State Recovery After Mid-Flight Failure
# Lifecycle: establish baseline → trigger mid-flight croak → disable failure →
# re-query → assert result identical to baseline and all DA call counts are
# consistent with exactly three query rounds (baseline, failed, recovery).
# Since all intermediate state in _joined_query is held in local variables,
# Perl's stack unwind guarantees no persistent partial state.
# ============================================================================
note '--- S10: State Recovery After Mid-Flight Failure ---';

my $p10 = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [ {%ALICE}, {%BOB} ],
);
my $s10 = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [
		{ entry => $K1, score => $SCORE_HIGH },
		{ entry => $K2, score => $SCORE_LOW  },
	],
);
my $j10 = Database::Join->new(databases => [$p10, $s10], join_column => 'entry');

# Phase 1: Establish baseline and capture initial call counts
my $baseline10 = $j10->selectall_arrayref();
is(scalar @{$baseline10}, 2, 'S10-P1: baseline query → 2 rows');	# T80

# Phase 2: Mid-flight croak — captured via eval to allow continued assertions
$s10->set_fail(1);
my $caught10 = 0;
eval { $j10->selectall_arrayref() };
$caught10 = 1 if $@;
ok($caught10, 'S10-P2: exception caught during mid-flight DA failure');	# T81

# Phase 3: Disable failure; verify full recovery and state integrity
$s10->set_fail(0);
my $recovery10 = $j10->selectall_arrayref();
is(scalar @{$recovery10}, 2, 'S10-P3a: after recovery, query returns 2 rows');	# T82
is_deeply($recovery10, $baseline10, 'S10-P3b: recovered result identical to baseline');	# T83

# Internal routing state not corrupted by the failed query
is($j10->{_col_db}{score}, 1, 'S10-P4: _col_db score routing intact after recovery');	# T84

# DA call counts: baseline(p=1,s=1) + failed(p=2,s=2) + recovery(p=3,s=3) = 6 total
# Primary is called before secondary in the fetch loop, so p always increments even
# when s croaks.
is($p10->call_count(), 3, 'S10-P5a: primary DA called 3 times (baseline, failed, recovery)');	# T85
is($s10->call_count(), 3, 'S10-P5b: secondary DA called 3 times (2nd was the croak)');	# T86

# Final cross-check: columns() still reports correct view after all failure/recovery cycles
ok((grep { $_ eq 'score' } @{ $j10->columns() }),
	'S10-P6: columns() correct after full failure/recovery lifecycle');	# T87
