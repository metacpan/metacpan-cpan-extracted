#!/usr/bin/perl

# Transaction-flow tests for Database::Join.
# Tests walk entities through complete lifecycle phases, verify state
# consistency at every boundary, test mid-flight failure and recovery,
# and assert idempotency across repeated state transitions.

use strict;
use warnings;

use Test::Most tests => 180;
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

# DA with count() defined in its own package — required so that
# defined &{"TransCountDA::count"} is true (the backend='auto' threshold
# probe checks for a directly-defined count(), not an inherited one).
{
	package TransCountDA;
	use parent -norequire, 'TransactionDA';
	sub count   { return scalar @{ $_[0]->{rows} } }
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

# ============================================================================
# Section 11: Primary DA Mid-Flight Failure
# When the primary (first) DA fails, the fetch loop exits immediately and the
# secondary DA is never reached.
# Lifecycle: baseline → enable primary failure → verify secondary not invoked
# → disable → full recovery; result must be identical to baseline.
# ============================================================================
note '--- S11: Primary DA Mid-Flight Failure ---';

my $p11 = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [ {%ALICE}, {%BOB} ],
);
my $s11 = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [
		{ entry => $K1, score => $SCORE_HIGH },
		{ entry => $K2, score => $SCORE_LOW  },
	],
);
my $j11 = Database::Join->new(databases => [$p11, $s11], join_column => 'entry');

# Phase 1: Baseline — capture call counts before failure injection
my $baseline11 = $j11->selectall_arrayref();
is(scalar @{$baseline11}, 2, 'S11-P1a: baseline → 2 rows');				# T88
is($p11->call_count(), 1, 'S11-P1b: primary called once during baseline');		# T89
is($s11->call_count(), 1, 'S11-P1c: secondary called once during baseline');		# T90

# Phase 2: Enable failure on primary; secondary must not be called at all
$p11->set_fail(1);
throws_ok {
	$j11->selectall_arrayref()
} qr/TransactionDA: simulated mid-flight failure/,
	'S11-P2: primary DA failure → exception propagates to caller';			# T91

# Primary count increments (was invoked and threw); secondary count is unchanged
is($p11->call_count(), 2, 'S11-P3: primary call count incremented by the failed attempt');	# T92
is($s11->call_count(), 1, 'S11-P4: secondary NOT reached when primary fails first');	# T93

# Phase 3: Recovery — disable failure; join object state must be uncorrupted
$p11->set_fail(0);
my $recovery11 = $j11->selectall_arrayref();
is(scalar @{$recovery11}, 2, 'S11-P5a: after primary recovery, query returns 2 rows');	# T94
is_deeply($recovery11, $baseline11,
	'S11-P5b: recovered result identical to pre-failure baseline');			# T95

# ============================================================================
# Section 12: collision_prefix Transaction Lifecycle
# Lifecycle: construct with collision_prefix → columns()/schema() naming →
# merged row carries both prefixed and plain columns → query by prefixed
# criterion routes to secondary and returns the correct row.
# ============================================================================
note '--- S12: collision_prefix Transaction Lifecycle ---';

my $p12 = TransactionDA->new(
	cols   => ['entry', 'notes'],
	rows   => [
		{ entry => $K1, notes => 'prim-k1' },
		{ entry => $K2, notes => 'prim-k2' },
	],
	schema => { entry => { type => 'text' }, notes => { type => 'text' } },
);
my $s12 = TransactionDA->new(
	cols   => ['entry', 'notes', 'score'],
	rows   => [
		{ entry => $K1, notes => 'sec-k1', score => $SCORE_HIGH },
		{ entry => $K2, notes => 'sec-k2', score => $SCORE_LOW  },
	],
	schema => {
		entry => { type => 'text' },
		notes => { type => 'text', len => 50 },
		score => { type => 'int' },
	},
);
my $j12 = Database::Join->new(
	databases        => [$p12, $s12],
	join_column      => 'entry',
	collision_prefix => { 1 => 'sec' },
);

# Phase 1: columns() reflects collision renaming; non-colliding col stays plain
my %cols12 = map { $_ => 1 } @{ $j12->columns() };
ok($cols12{notes},        'S12-P1a: primary "notes" in columns() (plain, no prefix)');		# T96
ok($cols12{'sec.notes'},  'S12-P1b: secondary "notes" in columns() as "sec.notes"');		# T97
ok($cols12{score},        'S12-P1c: non-colliding "score" in columns() plain');		# T98
ok(!$cols12{'sec.score'}, 'S12-P1d: "sec.score" absent ("score" did not collide)');		# T99

# Phase 2: Merged row carries both plain and prefixed columns
my $row12 = $j12->fetchrow_hashref(entry => $K1);
is($row12->{notes},       'prim-k1',   'S12-P2a: primary "notes" value preserved in row');	# T100
is($row12->{'sec.notes'}, 'sec-k1',    'S12-P2b: secondary "notes" under "sec.notes" key');	# T101
is($row12->{score},       $SCORE_HIGH, 'S12-P2c: non-colliding "score" value correct');	# T102

# Phase 3: Query by prefixed criterion routes to secondary, returns correct row
my $rows12c = $j12->selectall_arrayref('sec.notes' => 'sec-k1');
is(scalar @{$rows12c}, 1, 'S12-P3a: query by prefixed col "sec.notes" → 1 row');		# T103
is($rows12c->[0]{entry}, $K1, 'S12-P3b: the matching row is entry=k1');			# T104

# ============================================================================
# Section 13: join_type Lifecycle
# Three separate join objects over the same DAs verify left/inner/outer
# key-set semantics. k1: in both DAs; k2: primary only; k3: secondary only.
# ============================================================================
note '--- S13: join_type Lifecycle ---';

my $p13 = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [
		{ entry => $K1, name => 'Alice' },
		{ entry => $K2, name => 'Bob'   },
	],
);
my $s13 = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [
		{ entry => $K1, score => $SCORE_HIGH },
		{ entry => $K3, score => $SCORE_MID  },
	],
);

# Left join (default): primary defines key set → k1+k2; k3 (secondary only) excluded
my $j13l = Database::Join->new(
	databases => [$p13, $s13], join_column => 'entry', join_type => 'left');
my $rows13l = $j13l->selectall_arrayref();
is(scalar @{$rows13l}, 2, 'S13-P1a: left join → 2 rows (k1+k2, k3 excluded)');		# T105
my %keys13l = map { $_->{entry} => 1 } @{$rows13l};
ok($keys13l{$K1},  'S13-P1b: k1 in left join result (present in both DAs)');			# T106
ok($keys13l{$K2},  'S13-P1c: k2 in left join result (primary only)');				# T107
ok(!$keys13l{$K3}, 'S13-P1d: k3 absent from left join (secondary only → excluded)');		# T108

# Inner join: intersection of keys → k1 only
my $j13i = Database::Join->new(
	databases => [$p13, $s13], join_column => 'entry', join_type => 'inner');
my $rows13i = $j13i->selectall_arrayref();
is(scalar @{$rows13i}, 1, 'S13-P2a: inner join → 1 row (only k1 in both DAs)');		# T109
is($rows13i->[0]{entry}, $K1, 'S13-P2b: inner join returns k1 (the shared key)');		# T110

# Outer join: union of all keys → k1+k2+k3; sparse fields for non-present DAs
my $j13o = Database::Join->new(
	databases => [$p13, $s13], join_column => 'entry', join_type => 'outer');
my $rows13o = $j13o->selectall_arrayref();
is(scalar @{$rows13o}, 3, 'S13-P3a: outer join → 3 rows (union: k1+k2+k3)');			# T111
my %keys13o = map { $_->{entry} => 1 } @{$rows13o};
ok($keys13o{$K3}, 'S13-P3b: k3 present in outer join (secondary-only key)');			# T112
my ($k2_row13) = grep { $_->{entry} eq $K2 } @{$rows13o};
ok(!defined $k2_row13->{score},
	'S13-P3c: k2 row (primary only) → score undef in outer join');				# T113

# ============================================================================
# Section 14: add_database Combined filter + remove_columns Lifecycle
# Lifecycle: single-DA join → add_database with both filter and remove_columns
# → verify hidden col absent → filter acts as inner-join constraint →
# removed col absent from returned rows.
# ============================================================================
note '--- S14: add_database Combined filter + remove_columns ---';

my $p14 = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [ {%ALICE}, {%BOB} ],
);
my $s14 = TransactionDA->new(
	cols => ['entry', 'score', 'tag'],
	rows => [
		{ entry => $K1, score => $SCORE_HIGH, tag => 'gold'   },
		{ entry => $K2, score => $SCORE_LOW,  tag => 'silver' },
	],
);
my $j14 = Database::Join->new(databases => [$p14], join_column => 'entry');

$j14->add_database($s14,
	filter         => { score => { '>=' => $SCORE_MID } },
	remove_columns => ['tag'],
);

# 'tag' hidden by remove_columns; 'score' exposed
my %cols14 = map { $_ => 1 } @{ $j14->columns() };
ok(!$cols14{tag},  'S14-P2a: "tag" hidden by remove_columns in add_database');			# T114
ok($cols14{score}, 'S14-P2b: "score" present after add_database');				# T115

# filter score>=80 → secondary acts as inner-join constraint; k2 (score=70) excluded
my $rows14a = $j14->selectall_arrayref();
is(scalar @{$rows14a}, 1,
	'S14-P3: add_database filter acts as inner-join constraint → 1 row');			# T116
is($rows14a->[0]{entry}, $K1,
	'S14-P4: only k1 survives the score>=80 filter');					# T117

# 'tag' absent from returned rows even though the secondary DA column exists
ok(!exists $rows14a->[0]{tag},
	'S14-P5: "tag" absent from merged row (removed by add_database remove_columns)');	# T118

# ============================================================================
# Section 15: Broadcast Copy Isolation Lifecycle
# The join_column criterion (when an operator hashref) is shallow-copied per
# recipient DA so a DA mutating its received copy cannot corrupt the copy
# sent to subsequent DAs.
# Lifecycle: 3-DA join where the middle DA (PoisonDA) injects a poison key into
# its copy; the last DA (SnapshotDA) records the exact criterion it received and
# the poison key must be absent from that snapshot.
# ============================================================================
note '--- S15: Broadcast Copy Isolation ---';

{
	package PoisonDA;
	use parent -norequire, 'TransactionDA';
	# Mutates the received entry operator hashref by adding a poison key, then
	# delegates to the normal filter logic.  If broadcast copy is not working,
	# subsequent DAs would also receive the poisoned hashref.
	sub selectall_arrayref {
		my ($self, $criteria) = @_;
		if (ref $criteria->{entry} eq 'HASH') {
			$criteria->{entry}{_poison} = 'yes';
		}
		return $self->SUPER::selectall_arrayref($criteria);
	}
}

{
	package SnapshotDA;
	use parent -norequire, 'TransactionDA';
	sub new {
		my ($class, %args) = @_;
		my $self = $class->SUPER::new(%args);
		$self->{_snapshot} = undef;
		return $self;
	}
	# Records a snapshot of the entry operator hashref at call time so the test
	# can inspect exactly what this DA received (before any of its own processing).
	sub selectall_arrayref {
		my ($self, $criteria) = @_;
		if (ref $criteria->{entry} eq 'HASH') {
			$self->{_snapshot} = { %{ $criteria->{entry} } };
		}
		return $self->SUPER::selectall_arrayref($criteria);
	}
	sub snapshot { return $_[0]->{_snapshot} }
}

Readonly::Scalar my $EK1 => 1;
Readonly::Scalar my $EK2 => 2;

my $p15 = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [
		{ entry => $EK1, name => 'Alice' },
		{ entry => $EK2, name => 'Bob'   },
	],
);
my $m15 = PoisonDA->new(
	cols => ['entry', 'score'],
	rows => [
		{ entry => $EK1, score => $SCORE_HIGH },
		{ entry => $EK2, score => $SCORE_LOW  },
	],
);
my $l15 = SnapshotDA->new(
	cols => ['entry', 'rank'],
	rows => [
		{ entry => $EK1, rank => 1 },
		{ entry => $EK2, rank => 2 },
	],
);
my $j15 = Database::Join->new(
	databases   => [$p15, $m15, $l15],
	join_column => 'entry',
	join_type   => 'inner',
);

my $rows15 = $j15->selectall_arrayref(entry => { '>=' => $EK1 });
is(scalar @{$rows15}, 2,
	'S15-P1: 3-DA inner join with entry operator hashref → 2 rows');			# T119
my $snap15 = $l15->snapshot();
ok(defined $snap15,
	'S15-P2: SnapshotDA captured a snapshot of its received entry criterion');		# T120
ok(!exists $snap15->{_poison},
	'S15-P3: broadcast copy isolated — poison key absent from SnapshotDA snapshot');	# T121
ok(exists $snap15->{'>='},
	'S15-P4: original ">=" operator preserved in SnapshotDA snapshot');			# T122

# ============================================================================
# Section 16: updated() Tracking Lifecycle
# Lifecycle: construct with two DAs → updated() = max of initial timestamps →
# add_database with higher timestamp → updated() increases →
# add_database with lower timestamp → updated() unchanged.
# ============================================================================
note '--- S16: updated() Tracking Lifecycle ---';

Readonly::Scalar my $TS_LOW  => 100;
Readonly::Scalar my $TS_MID  => 200;
Readonly::Scalar my $TS_HIGH => 300;

my $p16 = TransactionDA->new(
	cols    => ['entry', 'name'],
	rows    => [ { entry => $K1, name => 'Alice' } ],
	updated => $TS_MID,
);
my $s16 = TransactionDA->new(
	cols    => ['entry', 'score'],
	rows    => [ { entry => $K1, score => $SCORE_HIGH } ],
	updated => $TS_LOW,
);
my $j16 = Database::Join->new(databases => [$p16, $s16], join_column => 'entry');

# Phase 1: updated() = max(TS_MID, TS_LOW) = TS_MID
is($j16->updated(), $TS_MID,
	'S16-P1: initial updated() = max of primary and secondary timestamps');		# T123

# Phase 2: add_database with HIGHER timestamp → updated() increases to new max
my $t16a = TransactionDA->new(
	cols    => ['entry', 'rank'],
	rows    => [ { entry => $K1, rank => 1 } ],
	updated => $TS_HIGH,
);
$j16->add_database($t16a);
is($j16->updated(), $TS_HIGH,
	'S16-P2: add_database with higher timestamp → updated() increases');		# T124

# Phase 3: add_database with LOWER timestamp → updated() unchanged
my $t16b = TransactionDA->new(
	cols    => ['entry', 'flag'],
	rows    => [ { entry => $K1, flag => 'x' } ],
	updated => $TS_LOW,
);
$j16->add_database($t16b);
is($j16->updated(), $TS_HIGH,
	'S16-P3: add_database with lower timestamp leaves updated() at prior max');	# T125

# Phase 4: Single-DA join → updated() equals that DA timestamp exactly
my $j16s = Database::Join->new(
	databases => [
		TransactionDA->new(
			cols    => ['entry', 'x'],
			rows    => [ { entry => $K1, x => 1 } ],
			updated => $TS_MID,
		),
	],
	join_column => 'entry',
);
is($j16s->updated(), $TS_MID,
	'S16-P4: single-DA join → updated() equals that DA timestamp');			# T126

# ============================================================================
# Section 17: Outer Join Sparse Row Idempotency
# Lifecycle: outer join where primary has k1+k2 and secondary has k1+k3 →
# first query produces 3 rows with undef fields for absent DAs → repeated
# queries return identical sparse structure → count() agrees.
# ============================================================================
note '--- S17: Outer Join Sparse Row Idempotency ---';

my $p17 = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [
		{ entry => $K1, name => 'Alice' },
		{ entry => $K2, name => 'Bob'   },
	],
);
my $s17 = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [
		{ entry => $K1, score => $SCORE_HIGH },
		{ entry => $K3, score => $SCORE_MID  },
	],
);
my $j17 = Database::Join->new(
	databases   => [$p17, $s17],
	join_column => 'entry',
	join_type   => 'outer',
);

# Phase 1: Outer join returns all 3 distinct keys (union of both DAs)
my $rows17a = $j17->selectall_arrayref();
is(scalar @{$rows17a}, 3, 'S17-P1: outer join → 3 rows (union: k1+k2+k3)');		# T127

# Phase 2: Sparse rows — primary-only k2 has no score; secondary-only k3 has no name
my ($k2_17) = grep { $_->{entry} eq $K2 } @{$rows17a};
my ($k3_17) = grep { $_->{entry} eq $K3 } @{$rows17a};
ok(!defined $k2_17->{score}, 'S17-P2a: k2 (primary only) → score undef in outer join row');	# T128
ok(!defined $k3_17->{name},  'S17-P2b: k3 (secondary only) → name undef in outer join row');	# T129

# Phase 3: Repeated query produces identical sparse structure (idempotent)
my $rows17b = $j17->selectall_arrayref();
is_deeply($rows17a, $rows17b,
	'S17-P3: repeated outer join query → identical sparse row structure');		# T130

# Phase 4: count() consistent with selectall_arrayref() length for outer join
is($j17->count(), scalar @{ $j17->selectall_arrayref() },
	'S17-P4: count() agrees with selectall_arrayref() length in outer join');	# T131

# ---------------------------------------------------------------------------
# S18: SQLite Backend Cache Lifecycle
#
# Transaction sequence: construct(backend='sqlite') → first query builds cache
# (ABSENT→FRESH) → second query reuses cache (FRESH→FRESH) → add_database
# invalidates cache (FRESH→ABSENT) → third query rebuilds cache (ABSENT→FRESH)
# and the newly added column appears in all rows.
# ---------------------------------------------------------------------------
note '--- S18: SQLite Backend Cache Lifecycle ---';

my $p18 = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [{ entry => $K1, name => 'Alice' }, { entry => $K2, name => 'Bob' }],
);
my $s18 = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [{ entry => $K1, score => $SCORE_HIGH }],
);
my $j18 = Database::Join->new(
	databases   => [$p18, $s18],
	join_column => 'entry',
	backend     => 'sqlite',
);

# Phase 1: ABSENT — no cache before first query
ok(!defined $j18->{_sqlite_cache},
	'S18-P1: SQLite cache ABSENT before first query');				# T132

# Phase 2: First query → FRESH; cache is populated; rows are correct
my $rows18a = $j18->selectall_arrayref();
ok(defined $j18->{_sqlite_cache},
	'S18-P2a: cache built after first query (FRESH)');				# T133
is(scalar @{$rows18a}, 2,
	'S18-P2b: first query returns 2 merged rows');					# T134

# Phase 3: Second query reuses cache — refaddr of the cache hashref is unchanged
my $addr18 = refaddr($j18->{_sqlite_cache});
my $rows18b = $j18->selectall_arrayref();
is(refaddr($j18->{_sqlite_cache}), $addr18,
	'S18-P3a: cache refaddr unchanged on second query (FRESH→FRESH)');		# T135
is_deeply($rows18a, $rows18b,
	'S18-P3b: second query returns identical rows to first');			# T136

# Phase 4: add_database invalidates the cache (FRESH→ABSENT)
my $t18 = TransactionDA->new(
	cols => ['entry', 'tag'],
	rows => [{ entry => $K1, tag => 'vip' }, { entry => $K2, tag => 'std' }],
);
$j18->add_database($t18);
ok(!defined $j18->{_sqlite_cache},
	'S18-P4: add_database invalidates SQLite cache (FRESH→ABSENT)');		# T137

# Phase 5: Next query rebuilds cache (ABSENT→FRESH); new column appears in rows
my $rows18c = $j18->selectall_arrayref();
ok(defined $j18->{_sqlite_cache},
	'S18-P5a: cache rebuilt after add_database query (ABSENT→FRESH)');		# T138
my ($k1_18) = grep { $_->{entry} eq $K1 } @{$rows18c};
is($k1_18->{tag}, 'vip',
	'S18-P5b: k1 row carries "tag" column from newly added DA');			# T139

# ---------------------------------------------------------------------------
# S19: SQLite Backend + Filter — criteria separation
#
# Filter criteria are applied at cache-build (spill) time; query-time criteria
# are applied as SQL WHERE clauses each call.  Both constraints must compose
# correctly: filter limits the spilled rows, WHERE limits the returned rows.
# ---------------------------------------------------------------------------
note '--- S19: SQLite Backend + Filter Criteria Separation ---';

my $p19 = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [{ entry => $K1, name => 'Alice' }, { entry => $K2, name => 'Bob' }],
);
my $s19 = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [
		{ entry => $K1, score => $SCORE_HIGH },	# 90 — above filter (>60) and WHERE (>=80)
		{ entry => $K2, score => $SCORE_LOW  },	# 70 — above filter (>60), below WHERE (>=80)
	],
);
my $j19 = Database::Join->new(
	databases   => [$p19, $s19],
	join_column => 'entry',
	backend     => 'sqlite',
	filters     => { 1 => { score => { '>' => 60 } } },
);

# Phase 1: No query-time criteria — filter alone; both rows pass score>60
my $rows19a = $j19->selectall_arrayref();
is(scalar @{$rows19a}, 2,
	'S19-P1: filter(score>60) alone → 2 rows (both pass)');			# T140

# Phase 2: Add WHERE criterion score>=80; only k1 (90) survives the AND
my $rows19b = $j19->selectall_arrayref(score => { '>=' => $SCORE_MID });
is(scalar @{$rows19b}, 1,
	'S19-P2a: filter(score>60) AND WHERE(score>=80) → 1 row');			# T141
is($rows19b->[0]{entry}, $K1,
	'S19-P2b: qualifying row is entry=k1 (score=90)');				# T142

# Phase 3: Repeated call with same criteria is idempotent (cache must survive)
my $rows19c = $j19->selectall_arrayref(score => { '>=' => $SCORE_MID });
is_deeply($rows19b, $rows19c,
	'S19-P3: repeated WHERE query returns identical rows (cache reused)');		# T143

# ---------------------------------------------------------------------------
# S20: backend='auto' Threshold Routing Lifecycle
#
# When total row count <= max_array_rows the array path is taken and tmpdir is
# never accessed; when count > max_array_rows the SQLite path is taken and a
# bad tmpdir causes File::Temp to croak.  TransCountDA is used because the
# module checks defined &{"${pkg}::count"} (not $db->can('count')) to detect
# a directly-defined count() method.
# ---------------------------------------------------------------------------
note '--- S20: backend=auto Threshold Routing ---';

Readonly::Scalar my $BAD_TMPDIR => '/nonexistent/__txn_test_dir__';

# Phase 1: count <= threshold → array path; bad tmpdir never accessed → lives
{
	my $pa = TransCountDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => $K1, name => 'Alice' }, { entry => $K2, name => 'Bob' }],
	);
	my $sa = TransCountDA->new(
		cols => ['entry', 'score'],
		rows => [{ entry => $K1, score => $SCORE_HIGH }],
	);
	# total rows = 3; max_array_rows=10 → 3 <= 10 → array path
	my $ja = Database::Join->new(
		databases      => [$pa, $sa],
		join_column    => 'entry',
		backend        => 'auto',
		max_array_rows => 10,
		tmpdir         => $BAD_TMPDIR,
	);
	my $rows;
	lives_ok { $rows = $ja->selectall_arrayref() }
		'S20-P1a: auto + count<=threshold → array path; bad tmpdir never accessed';	# T144
	is(scalar @{$rows}, 2,
		'S20-P1b: array path returns 2 merged rows');					# T145
}

# Phase 2: count > threshold → SQLite path; bad tmpdir → File::Temp croak
{
	my $pb = TransCountDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => $K1, name => 'Alice' }],
	);
	my $sb = TransCountDA->new(
		cols => ['entry', 'score'],
		rows => [{ entry => $K1, score => $SCORE_HIGH }],
	);
	# total rows = 2; max_array_rows=0 → 2 > 0 → SQLite path → File::Temp croak
	my $jb = Database::Join->new(
		databases      => [$pb, $sb],
		join_column    => 'entry',
		backend        => 'auto',
		max_array_rows => 0,
		tmpdir         => $BAD_TMPDIR,
	);
	my $err;
	eval { $jb->selectall_arrayref() };
	$err = $@;
	my ($first_line) = split /\n/, ($err // ''), 2;
	like($first_line, qr/does not exist|no such file|cannot|failed/i,
		'S20-P2: auto + count>threshold → SQLite path; bad tmpdir → croak');		# T146
}

# ============================================================================
# S21: sort_by Transaction Lifecycle
#
# Lifecycle phases:
#   CONSTRUCT → DEFAULT-SORT → VALID-ASC → VALID-DESC → INVALID-DIR → UNKNOWN-COL
#
# Each phase verifies that the query results match the ordering implied by the
# current sort_by parameter, and that invalid inputs trigger a carp without
# aborting the transaction or leaving the object in a broken state.
# ============================================================================

note '--- S21: sort_by Transaction Lifecycle ---';

Readonly::Scalar my $L_ALPHA => 'alpha';
Readonly::Scalar my $L_BETA  => 'beta';
Readonly::Scalar my $L_GAMMA => 'gamma';

# Fixture: join_col order (k1 < k2 < k3) is the reverse of label ASC order
# (alpha=k3 < beta=k2 < gamma=k1). Every phase has a distinct observable output.
my $ob21 = TransactionDA->new(
	cols => ['entry', 'label'],
	rows => [
		{ entry => $K3, label => $L_ALPHA },
		{ entry => $K1, label => $L_GAMMA },
		{ entry => $K2, label => $L_BETA  },
	],
);
my $j21 = Database::Join->new(
	databases   => [$ob21],
	join_column => 'entry',
	backend     => 'array',
);

# Phase 1: CONSTRUCT — object built; column routing table populated correctly.
ok(defined $j21, 'S21-P1: sort_by lifecycle: join object constructed');		# T147

# Phase 2: DEFAULT-SORT — no sort_by; join_col ASC is the default ordering.
# k1 < k2 < k3 → k1 must come first.
{
	my $rows = $j21->selectall_arrayref();
	is($rows->[0]{entry}, $K1, 'S21-P2: default sort_by → join_col ASC → k1 first');	# T148
}

# Phase 3: VALID-ASC — sort_by = 'label' (string form) → Schwarzian ASC.
# alpha(k3) < beta(k2) < gamma(k1): k3 must come first.
{
	my $rows = $j21->selectall_arrayref(sort_by => 'label');
	is($rows->[0]{label}, $L_ALPHA,
		'S21-P3: sort_by label ASC → alpha first (non-join-col Schwarzian)');		# T149
}

# Phase 4: VALID-DESC — sort_by = ['label','DESC'] → Schwarzian DESC.
# gamma(k1) > beta(k2) > alpha(k3): gamma must come first.
{
	my $rows = $j21->selectall_arrayref(sort_by => ['label', 'DESC']);
	is($rows->[0]{label}, $L_GAMMA,
		'S21-P4: sort_by label DESC → gamma first (Schwarzian DESC)');			# T150
}

# Phase 5: INVALID-DIR — direction 'UP' is not ASC or DESC → carp; ASC fallback.
# Object remains operational; result is label ASC (alpha first).
{
	my @warns;
	{ local $SIG{__WARN__} = sub { push @warns, @_ };
	  my $rows = $j21->selectall_arrayref(sort_by => ['label', 'UP']);
	  is($rows->[0]{label}, $L_ALPHA,
		'S21-P5b: invalid direction carps + ASC fallback → alpha first');		# T152
	}
	ok(scalar @warns,
		'S21-P5a: sort_by direction "UP" → carp emitted; object still operational');	# T151
}

# Phase 6: UNKNOWN-COL — sort_by column not in the view → carp; join_col fallback.
# k1 must come first (join_col ASC default).
{
	my @warns;
	{ local $SIG{__WARN__} = sub { push @warns, @_ };
	  my $rows = $j21->selectall_arrayref(sort_by => 'nonexistent');
	  is($rows->[0]{entry}, $K1,
		'S21-P6b: unknown sort_by col → join_col ASC fallback → k1 first');		# T154
	}
	ok(scalar @warns,
		'S21-P6a: unknown sort_by column → carp; object continues to function');	# T153
}

# ============================================================================
# S22: Pagination Lifecycle (limit + offset)
#
# Lifecycle phases:
#   FULL → PAGE-1 → PAGE-2 → LAST-PAGE (partial) → PAST-END → IDEMPOTENT
#
# Verifies that sequential pagination walks through all rows without overlap or
# gaps, and that repeating the same page query returns identical results
# (idempotency — no hidden mutable state inside the join object).
# ============================================================================

note '--- S22: Pagination Lifecycle ---';

Readonly::Scalar my $PG_SIZE    => 2;
Readonly::Scalar my $PG_TOTAL   => 5;

my $pg22 = TransactionDA->new(
	cols => ['entry', 'v'],
	rows => [
		{ entry => 'p1', v => 10 },
		{ entry => 'p2', v => 20 },
		{ entry => 'p3', v => 30 },
		{ entry => 'p4', v => 40 },
		{ entry => 'p5', v => 50 },
	],
);
my $j22 = Database::Join->new(
	databases   => [$pg22],
	join_column => 'entry',
	backend     => 'array',
);

# Phase 1: FULL — establish baseline: all 5 rows returned without pagination.
{
	my $full = $j22->selectall_arrayref();
	is(scalar @{$full}, $PG_TOTAL,
		'S22-P1: full result returns all 5 rows (pagination baseline)');		# T155
}

# Phase 2: PAGE-1 — offset=0, limit=2 → first two rows (p1, p2).
my $page1_22;
{
	$page1_22 = $j22->selectall_arrayref(offset => 0, limit => $PG_SIZE);
	is(scalar @{$page1_22}, $PG_SIZE,
		'S22-P2a: page 1 (offset=0, limit=2) → 2 rows');				# T156
	is($page1_22->[0]{entry}, 'p1',
		'S22-P2b: page 1 starts at p1 (first row)');					# T157
}

# Phase 3: PAGE-2 — offset=2, limit=2 → rows 3-4 (p3, p4); no overlap with page 1.
{
	my $page2 = $j22->selectall_arrayref(offset => $PG_SIZE, limit => $PG_SIZE);
	is(scalar @{$page2}, $PG_SIZE,
		'S22-P3a: page 2 (offset=2, limit=2) → 2 rows; no overlap with page 1');	# T158
	is($page2->[0]{entry}, 'p3',
		'S22-P3b: page 2 starts at p3 (third row, not seen on page 1)');		# T159
}

# Phase 4: LAST-PAGE (partial) — offset=4, limit=2: only 1 row remaining (p5).
{
	my $last = $j22->selectall_arrayref(offset => $PG_TOTAL - 1, limit => $PG_SIZE);
	is(scalar @{$last}, 1,
		'S22-P4: last page (offset=4, limit=2) → 1 row (partial page at boundary)');	# T160
}

# Phase 5: PAST-END — offset=5 (== total row count) → empty result.
{
	my $gone = $j22->selectall_arrayref(offset => $PG_TOTAL, limit => $PG_SIZE);
	is(scalar @{$gone}, 0,
		'S22-P5: past-end offset (offset=5) → empty result (BVA: offset=N)');		# T161
}

# Phase 6: IDEMPOTENT — page 1 repeated → identical result; no hidden mutable state.
{
	my $repeat = $j22->selectall_arrayref(offset => 0, limit => $PG_SIZE);
	is_deeply($repeat, $page1_22,
		'S22-P6: repeating page 1 query returns identical rows (idempotency)');		# T162
}

# ============================================================================
# S23: Combined sort_by + Pagination Transaction Lifecycle
#
# Lifecycle phases:
#   SORTED-FULL → SORTED-PAGE-1 → SORTED-PAGE-2
#
# Verifies that sort order is preserved across page boundaries: each page is a
# contiguous, non-overlapping window into the sorted result set.  The sort key
# (label) is in the reverse of join_col order, so any ordering bug would be
# visible as a wrong first element on each page.
# ============================================================================

note '--- S23: Combined sort_by + Pagination Lifecycle ---';

# Fixture: label ASC order (apple < cherry < mango < zebra) is the reverse of
# join_col ASC order (k1 < k2 < k3 < k4), making sort/page bugs visible.
# Labels were chosen so alphabetical order is unambiguous (no a<b<d<g confusion).
my $op23 = TransactionDA->new(
	cols => ['entry', 'label'],
	rows => [
		{ entry => 'k4', label => 'apple'  },
		{ entry => 'k3', label => 'cherry' },
		{ entry => 'k2', label => 'mango'  },
		{ entry => 'k1', label => 'zebra'  },
	],
);
my $j23 = Database::Join->new(
	databases   => [$op23],
	join_column => 'entry',
	backend     => 'array',
);

Readonly::Scalar my $OP_SIZE => 2;

# Phase 1: SORTED-FULL — full label ASC result; first=apple, last=zebra.
{
	my $full = $j23->selectall_arrayref(sort_by => 'label');
	is($full->[0]{label}, 'apple',
		'S23-P1a: sorted full result → apple first (label ASC)');			# T163
	is($full->[-1]{label}, 'zebra',
		'S23-P1b: sorted full result → zebra last (label ASC)');			# T164
}

# Phase 2: SORTED-PAGE-1 — sort_by=label ASC + offset=0, limit=2 → apple, cherry.
{
	my $pg1 = $j23->selectall_arrayref(sort_by => 'label', offset => 0, limit => $OP_SIZE);
	is(scalar @{$pg1}, $OP_SIZE,
		'S23-P2a: sorted page 1 → 2 rows');						# T165
	is($pg1->[0]{label}, 'apple',
		'S23-P2b: sorted page 1 starts at apple (sort preserved at page boundary)');	# T166
}

# Phase 3: SORTED-PAGE-2 — sort_by=label ASC + offset=2, limit=2 → mango, zebra.
# This proves the sort is applied before pagination (not after), so page 2 sees
# the NEXT two labels in sorted order, not the next two join_col values.
{
	my $pg2 = $j23->selectall_arrayref(sort_by => 'label', offset => $OP_SIZE, limit => $OP_SIZE);
	is(scalar @{$pg2}, $OP_SIZE,
		'S23-P3a: sorted page 2 → 2 rows');						# T167
	is($pg2->[0]{label}, 'mango',
		'S23-P3b: sorted page 2 starts at mango (no overlap; sort preserved)');		# T168
}

# ============================================================================
# S24: Parallel Dispatch Lifecycle (thread failure → sequential re-fetch)
#
# Lifecycle phases:
#   CONSTRUCT → PARALLEL-QUERY → IDEMPOTENT-QUERY → ADD-DB → POST-ADD-QUERY
#
# Verifies that with parallel=1 and 3 databases, the result always matches the
# sequential (parallel=0) equivalent — even when threads cannot clone DBI-backed
# DA objects (the Windows re-fetch fallback).  The invariant:
#
#   parallel_result ≡ sequential_result  for any n >= 3
#
# is the core correctness guarantee of the fix in _joined_query_array.
# ============================================================================

note '--- S24: Parallel Dispatch Lifecycle ---';

# Three TransactionDA stubs: purely in-memory, thread-clonable on all platforms.
my $par24_prim = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [
		{ entry => $K1, name => 'Alice' },
		{ entry => $K2, name => 'Bob'   },
	],
);
my $par24_sec1 = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [
		{ entry => $K1, score => $SCORE_HIGH },
		{ entry => $K2, score => $SCORE_LOW  },
	],
);
my $par24_sec2 = TransactionDA->new(
	cols => ['entry', 'tier'],
	rows => [
		{ entry => $K1, tier => 'gold'   },
		{ entry => $K2, tier => 'silver' },
	],
);

# Phase 1: CONSTRUCT — with parallel=1; three DAs (gate n>2 is open).
my $j24_par;
my @warns24;
{ local $SIG{__WARN__} = sub { push @warns24, @_ };
  $j24_par = Database::Join->new(
	databases   => [$par24_prim, $par24_sec1, $par24_sec2],
	join_column => 'entry',
	join_type   => 'inner',
	backend     => 'array',
	parallel    => 1,
  );
}
ok(defined $j24_par,
	'S24-P1: parallel=1 join with 3 DAs constructed without error');		# T169

# Phase 2: PARALLEL-QUERY — result must equal sequential equivalent.
# (On Linux with threads: parallel dispatch.  On Windows or without threads:
# sequential re-fetch fallback.  Result must be identical either way.)
my $j24_seq = Database::Join->new(
	databases => [
		TransactionDA->new(cols => ['entry','name'],  rows => [{ entry => $K1, name => 'Alice' }, { entry => $K2, name => 'Bob' }]),
		TransactionDA->new(cols => ['entry','score'], rows => [{ entry => $K1, score => $SCORE_HIGH }, { entry => $K2, score => $SCORE_LOW }]),
		TransactionDA->new(cols => ['entry','tier'],  rows => [{ entry => $K1, tier => 'gold' }, { entry => $K2, tier => 'silver' }]),
	],
	join_column => 'entry',
	join_type   => 'inner',
	backend     => 'array',
	parallel    => 0,
);
{ local $SIG{__WARN__} = sub { push @warns24, @_ };
  my $par_rows = $j24_par->selectall_arrayref();
  my $seq_rows = $j24_seq->selectall_arrayref();
  is(scalar @{$par_rows}, scalar @{$seq_rows},
	'S24-P2a: parallel=1 result row count == sequential row count');		# T170
  my @par_keys = sort map { $_->{entry} } @{$par_rows};
  my @seq_keys = sort map { $_->{entry} } @{$seq_rows};
  is_deeply(\@par_keys, \@seq_keys,
	'S24-P2b: parallel=1 join_col set identical to sequential (thread-or-re-fetch)');	# T171
}

# Phase 3: IDEMPOTENT-QUERY — repeating the query on the same parallel join
# object returns the same row count (no hidden mutable state altered by the
# first dispatch).
{ local $SIG{__WARN__} = sub { push @warns24, @_ };
  my $par_rows2 = $j24_par->selectall_arrayref();
  is(scalar @{$par_rows2}, 2,
	'S24-P3: second parallel query returns same row count (idempotent dispatch)');	# T172
}

# Phase 4: ADD-DB → POST-ADD-QUERY — adding a fourth database to the parallel
# join does not corrupt existing results.
my $par24_sec3 = TransactionDA->new(
	cols => ['entry', 'region'],
	rows => [
		{ entry => $K1, region => 'north' },
		{ entry => $K2, region => 'south' },
	],
);
{ local $SIG{__WARN__} = sub { push @warns24, @_ };
  $j24_par->add_database($par24_sec3);
  my $after = $j24_par->selectall_arrayref();
  is(scalar @{$after}, 2,
	'S24-P4a: after add_database, parallel join still returns 2 correct rows');	# T173
  ok((grep { defined $_->{region} } @{$after}) == 2,
	'S24-P4b: fourth DA column (region) present in merged rows after add_database');	# T174
}

# ============================================================================
# S25: Pagination Mid-Flight Failure and Recovery
#
# Lifecycle phases:
#   SUCCEED → INJECT-FAILURE → CROAK-PROPAGATED → RESET → RECOVER
#
# Verifies that a DA failure during a paginated query propagates the exception
# cleanly (no silent partial result, no dangling state), and that after the
# failure is cleared the join object returns to full operational status with
# exactly the same paginated result as before the failure.
# ============================================================================

note '--- S25: Pagination Mid-Flight Failure and Recovery ---';

Readonly::Scalar my $PF_LIMIT => 2;

my $pf25_prim = TransactionDA->new(
	cols => ['entry', 'name'],
	rows => [
		{ entry => $K1, name => 'Alice' },
		{ entry => $K2, name => 'Bob'   },
		{ entry => $K3, name => 'Carol' },
	],
);
my $pf25_sec = TransactionDA->new(
	cols => ['entry', 'score'],
	rows => [
		{ entry => $K1, score => $SCORE_HIGH },
		{ entry => $K2, score => $SCORE_LOW  },
		{ entry => $K3, score => $SCORE_MID  },
	],
);
my $j25 = Database::Join->new(
	databases   => [$pf25_prim, $pf25_sec],
	join_column => 'entry',
	backend     => 'array',
);

# Phase 1: SUCCEED — paginated query returns the expected 2 rows.
my $pf25_baseline;
{
	$pf25_baseline = $j25->selectall_arrayref(limit => $PF_LIMIT);
	is(scalar @{$pf25_baseline}, $PF_LIMIT,
		'S25-P1: paginated query (limit=2) succeeds → 2 rows (pre-failure baseline)');	# T175
}

# Phase 2: INJECT-FAILURE — make the secondary DA croak on its next call.
$pf25_sec->set_fail(1);

# Phase 3: CROAK-PROPAGATED — the paginated query must propagate the error; no
# silent empty result that could mask a data-source problem.
{
	my $err;
	eval { $j25->selectall_arrayref(limit => $PF_LIMIT) };
	$err = $@;
	my ($first_line) = split /\n/, ($err // ''), 2;
	like($first_line, qr/mid-flight failure/i,
		'S25-P3: mid-flight DA failure during paginated query → croak propagated');	# T176
}

# Phase 4: RESET — restore the secondary DA to healthy state.
$pf25_sec->set_fail(0);

# Phase 5: RECOVER — the same paginated query now returns the same result as the
# pre-failure baseline, proving the join object is fully operational again.
{
	my $recovered = $j25->selectall_arrayref(limit => $PF_LIMIT);
	is(scalar @{$recovered}, $PF_LIMIT,
		'S25-P5a: post-recovery paginated query returns 2 rows again');			# T177
	is_deeply($recovered, $pf25_baseline,
		'S25-P5b: recovered result identical to pre-failure baseline (full recovery)');	# T178
}

# Phase 6: IDEMPOTENT-AFTER-RECOVERY — one more repeated paginated query to
# confirm that the recovery itself left no residual state (not a one-shot fix).
{
	my $second = $j25->selectall_arrayref(limit => $PF_LIMIT);
	is(scalar @{$second}, $PF_LIMIT,
		'S25-P6: second post-recovery query returns same count (stable recovery)');	# T179
	is($second->[0]{entry}, $pf25_baseline->[0]{entry},
		'S25-P6b: first row unchanged across repeated post-recovery queries');		# T180
}
