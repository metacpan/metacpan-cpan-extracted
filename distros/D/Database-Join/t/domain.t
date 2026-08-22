#!/usr/bin/perl

# Domain tests for Database::Join using Equivalence Partitioning (EP) and
# Boundary Value Analysis (BVA).  Each parameter's valid and invalid partitions
# are tested with representative values; exact boundary edges are exercised
# wherever a numerical range, array size, or string length applies.

use strict;
use warnings;

use Test::Most tests => 79;
use Readonly;
use Scalar::Util qw(blessed);

use_ok('Database::Join');

# ---------------------------------------------------------------------------
# Inline test double: configurable in-memory Database::Abstraction subclass.
# Supports equality filtering and operator hashrefs (>, <, >=, <=, !=).
# ---------------------------------------------------------------------------
{
	package DomainDA;
	use parent -norequire, 'Database::Abstraction';

	Readonly::Scalar my $UPDATED => '2026-01-01';

	sub new {
		my ($class, %args) = @_;
		return bless {
			cols    => $args{cols}    // ['entry'],
			rows    => $args{rows}    // [],
			id      => $args{id}      // 'entry',
			updated => $args{updated} // $UPDATED,
			schema  => $args{schema}  // {},
		}, $class;
	}

	sub columns { return $_[0]->{cols} }
	sub schema  { return $_[0]->{schema} }
	sub updated { return $_[0]->{updated} }

	sub selectall_arrayref {
		my ($self, $criteria) = @_;
		$criteria //= {};
		my @results;
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
			push @results, { %{$row} };
		}
		return \@results;
	}

	sub DESTROY {}
}

# ---------------------------------------------------------------------------
# Wrong-class sentinel: blessed but not a Database::Abstraction subclass.
# ---------------------------------------------------------------------------
{
	package WrongClass;
	sub new { return bless {}, shift }
}

# ---------------------------------------------------------------------------
# Constants — no magic strings in test bodies.
# ---------------------------------------------------------------------------

Readonly::Scalar my $JC => 'entry';

Readonly::Scalar my $LONG_COLNAME => 'x' x 255;	# 255-char boundary for join_column length

Readonly::Hash my %ERR => (
	no_databases     => qr/At least one Database::Abstraction object is required/,
	invalid_db       => qr/databases\[\d+\] is not a Database::Abstraction object/,
	join_col_missing => qr/join_column "[^"]*" is absent from databases\[\d+\]/,
	join_col_refval  => qr/join_column "\(join_map\[\d+\] must be a string\)" is absent from databases\[\d+\]/,
	remove_join_col  => qr/Cannot remove join_column/,
	unknown_col      => qr/Column "[^"]+" is not present in any configured database/,
);

# Shared two-DB fixture with overlapping key set {k1, k2}.
sub _dbs {
	my $p = DomainDA->new(
		cols => [$JC, 'name'],
		rows => [
			{ $JC => 'k1', name => 'Alice' },
			{ $JC => 'k2', name => 'Bob'   },
		],
	);
	my $s = DomainDA->new(
		cols => [$JC, 'score'],
		rows => [
			{ $JC => 'k1', score => 90 },
			{ $JC => 'k2', score => 70 },
		],
	);
	return ($p, $s);
}

# Capture carp/warn into @warns; returns the arrayref for inspection.
sub _capture_warnings (&) {		## no critic (Prototypes)
	my ($code) = @_;
	my @warns;
	local $SIG{__WARN__} = sub { push @warns, @_ };
	$code->();
	return \@warns;
}

# ==========================================================================
# Section 1: `databases` parameter — type domain and size domain
#
# BVA: size minimum is 1; empty arrayref (size 0) is invalid.
# EP valid: blessed DA::Abstraction subclass elements.
# EP invalid: scalar, hashref, undef for the parameter itself; undef /
#   unblessed / wrong-class for individual elements.
# ==========================================================================

note '--- Section 1: databases parameter (type + size) ---';

# EP invalid: scalar passed where arrayref required
throws_ok {
	Database::Join->new(databases => 'scalar', join_column => $JC)
} qr/databases/i, 'databases: scalar rejected (EP invalid-type)';

# EP invalid: hashref passed where arrayref required
throws_ok {
	Database::Join->new(databases => {}, join_column => $JC)
} qr/databases/i, 'databases: hashref rejected (EP invalid-type)';

# EP invalid: absent / undef — required parameter
throws_ok {
	Database::Join->new(join_column => $JC)
} qr/databases/i, 'databases: absent/undef rejected (EP invalid-type)';

# BVA boundary below-minimum: size 0
throws_ok {
	Database::Join->new(databases => [], join_column => $JC)
} $ERR{no_databases}, 'databases: [] (size 0) croaks error_no_databases (BVA min-1)';

# BVA minimum valid: size 1
{
	my ($p) = _dbs();
	my $j = Database::Join->new(databases => [$p], join_column => $JC);
	isa_ok($j, 'Database::Join', 'databases: size 1 succeeds (BVA min)');
}

# EP valid typical: size 2
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	isa_ok($j, 'Database::Join', 'databases: size 2 succeeds (EP valid-typical)');
}

# BVA large: size 10 (no documented upper bound; proves no N-squared crash)
{
	my @large = map {
		DomainDA->new(
			cols => [$JC, "col$_"],
			rows => [{ $JC => 'k1', "col$_" => $_ }],
		)
	} 1 .. 10;
	my $j = Database::Join->new(databases => \@large, join_column => $JC);
	isa_ok($j, 'Database::Join', 'databases: size 10 succeeds (BVA large)');
}

# EP invalid element: undef at index 0
throws_ok {
	Database::Join->new(databases => [undef], join_column => $JC)
} $ERR{invalid_db}, 'databases: undef element at [0] croaks invalid_db';

# EP invalid element: unblessed hashref at index 0
throws_ok {
	Database::Join->new(databases => [{}], join_column => $JC)
} $ERR{invalid_db}, 'databases: unblessed hashref at [0] croaks invalid_db';

# EP invalid element: wrong ISA class at index 1 (valid at [0])
# Verifies the error references the correct failing index.
{
	my ($p) = _dbs();
	throws_ok {
		Database::Join->new(databases => [$p, WrongClass->new()], join_column => $JC)
	} $ERR{invalid_db}, 'databases: wrong-class element at [1] croaks invalid_db';
}

# ==========================================================================
# Section 2: `join_column` parameter — string domain
#
# EP valid: any non-empty string present in every component DA.
# EP invalid: string absent from any DA → croak join_col_missing.
# BVA string-length: empty '' (below minimum meaningful length), length-1,
#   length-255 (no documented upper bound; proves long names are accepted).
# ==========================================================================

note '--- Section 2: join_column parameter ---';

# EP valid: absent → default 'entry' used; verify via columns()
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s]);
	ok((grep { $_ eq 'entry' } @{ $j->columns() }),
		"join_column: absent → default 'entry' present in columns()");
}

# BVA length-1: single-char column name that exists in every DA
{
	my $p = DomainDA->new(cols => ['e', 'name'],  rows => [{ e => 'k1', name => 'A' }]);
	my $s = DomainDA->new(cols => ['e', 'score'], rows => [{ e => 'k1', score => 1 }]);
	my $j = Database::Join->new(databases => [$p, $s], join_column => 'e');
	isa_ok($j, 'Database::Join', 'join_column: length-1 name succeeds (BVA min-length)');
}

# BVA length-255: long column name present in every DA
{
	my $p = DomainDA->new(cols => [$LONG_COLNAME, 'name'],  rows => [{ $LONG_COLNAME => 'k1', name => 'A' }]);
	my $s = DomainDA->new(cols => [$LONG_COLNAME, 'score'], rows => [{ $LONG_COLNAME => 'k1', score => 1 }]);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $LONG_COLNAME);
	isa_ok($j, 'Database::Join', 'join_column: 255-char name succeeds (BVA max-length)');
}

# BVA length-0: empty string is treated as a column name absent from every DA
{
	my ($p, $s) = _dbs();
	throws_ok {
		Database::Join->new(databases => [$p, $s], join_column => '')
	} $ERR{join_col_missing}, "join_column: '' absent from DA → croaks join_col_missing (BVA below-min)";
}

# EP invalid: column name not found in DB[0]
{
	my ($p, $s) = _dbs();
	throws_ok {
		Database::Join->new(databases => [$p, $s], join_column => 'no_such_col')
	} $ERR{join_col_missing}, 'join_column: absent from DB[0] → croaks join_col_missing';
}

# EP invalid: column present in DB[0] but absent from DB[1]
# Proves the check visits every DB, not just the first.
{
	my $p = DomainDA->new(cols => [$JC, 'name'], rows => [{ $JC => 'k1', name => 'A' }]);
	my $s = DomainDA->new(cols => ['tid', 'score'], rows => [{ tid => 'k1', score => 1 }]);
	throws_ok {
		Database::Join->new(databases => [$p, $s], join_column => $JC)
	} $ERR{join_col_missing}, 'join_column: absent from DB[1] only → croaks join_col_missing at [1]';
}

# ==========================================================================
# Section 3: `join_type` parameter — enum domain
#
# EP valid: exactly 'inner', 'left', 'outer' (case-sensitive).
# EP invalid: any other string, including case variants.
# ==========================================================================

note '--- Section 3: join_type enum domain ---';

# EP absent → default 'left': secondary-only key is excluded
{
	my $p = DomainDA->new(cols => [$JC, 'name'],  rows => [{ $JC => 'k1', name => 'A' }]);
	my $s = DomainDA->new(cols => [$JC, 'score'], rows => [{ $JC => 'k2', score => 99 }]);
	my $j = Database::Join->new(databases => [$p, $s]);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 1, "join_type: absent → default 'left' (secondary-only k2 excluded)");
}

# EP valid: 'inner'
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'inner');
	isa_ok($j, 'Database::Join', "join_type: 'inner' accepted (EP valid)");
}

# EP valid: 'outer'
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'outer');
	isa_ok($j, 'Database::Join', "join_type: 'outer' accepted (EP valid)");
}

# EP invalid: uppercase variant — enum is case-sensitive
{
	my ($p, $s) = _dbs();
	throws_ok {
		Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'INNER')
	} qr/join_type|INNER|enum|must be one of/i, "join_type: 'INNER' rejected (EP invalid-case)";
}

# EP invalid: unknown value
{
	my ($p, $s) = _dbs();
	throws_ok {
		Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'cross')
	} qr/join_type|cross|enum|must be one of/i, "join_type: 'cross' rejected (EP invalid-unknown)";
}

# BVA below-minimum: empty string
{
	my ($p, $s) = _dbs();
	throws_ok {
		Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => '')
	} qr/join_type|enum|must be one of/i, "join_type: '' rejected (EP invalid-empty)";
}

# ==========================================================================
# Section 4: `join_map` parameter — value type domain
#
# EP valid: string values (any column name that exists in the target DA).
# EP invalid: reference values — hashref, arrayref, coderef → croak with the
#   heap-address guard message so no memory address leaks to callers.
# BVA: out-of-range index (beyond the databases array) is silently ignored.
# ==========================================================================

note '--- Section 4: join_map value domain ---';

# EP absent → {} default; construction succeeds
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	isa_ok($j, 'Database::Join', 'join_map: absent → default {} succeeds');
}

# EP valid: {} empty hashref → same semantics as absent
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, join_map => {});
	isa_ok($j, 'Database::Join', 'join_map: {} empty → succeeds (EP valid-empty)');
}

# EP invalid: hashref value — must be rejected before heap address can appear in error
{
	my ($p, $s) = _dbs();
	throws_ok {
		Database::Join->new(databases => [$p, $s], join_column => $JC,
			join_map => { 0 => {} })
	} $ERR{join_col_refval}, 'join_map: hashref value → croaks with type-guard message (EP invalid)';
}

# EP invalid: arrayref value
{
	my ($p, $s) = _dbs();
	throws_ok {
		Database::Join->new(databases => [$p, $s], join_column => $JC,
			join_map => { 0 => [] })
	} $ERR{join_col_refval}, 'join_map: arrayref value → croaks (EP invalid)';
}

# EP invalid: coderef value
{
	my ($p, $s) = _dbs();
	throws_ok {
		Database::Join->new(databases => [$p, $s], join_column => $JC,
			join_map => { 0 => sub {} })
	} $ERR{join_col_refval}, 'join_map: coderef value → croaks (EP invalid)';
}

# BVA: out-of-range key (index beyond the databases array) is silently ignored
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => $JC,
		join_map    => { 99 => 'entry' },
	);
	isa_ok($j, 'Database::Join', 'join_map: out-of-range key silently ignored (BVA)');
}

# ==========================================================================
# Section 5: `remove_columns` constructor parameter domain
#
# EP valid: arrayref of column-name strings (existing or non-existing).
# EP invalid: arrayref containing the join_column itself → croak.
# BVA: empty arrayref [] is a valid no-op.
# ==========================================================================

note '--- Section 5: remove_columns constructor parameter ---';

# EP absent → all columns retained
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	ok((grep { $_ eq 'name' } @{ $j->columns() }),
		"remove_columns: absent → 'name' still in columns() (EP absent)");
}

# BVA empty []: no columns removed
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, remove_columns => []);
	ok((grep { $_ eq 'name' } @{ $j->columns() }),
		'remove_columns: [] empty → all columns retained (BVA min)');
}

# EP invalid: join_col itself → croak at construction time
{
	my ($p, $s) = _dbs();
	throws_ok {
		Database::Join->new(databases => [$p, $s], join_column => $JC,
			remove_columns => [$JC])
	} $ERR{remove_join_col}, 'remove_columns: [join_col] → croaks remove_join_col (EP invalid)';
}

# EP valid: non-existent column → idempotent, no croak
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(
		databases      => [$p, $s],
		join_column    => $JC,
		remove_columns => ['no_such_column'],
	);
	isa_ok($j, 'Database::Join', 'remove_columns: [nonexistent] → idempotent (EP valid-nonexistent)');
}

# EP valid: existing data column → removed from columns()
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(
		databases      => [$p, $s],
		join_column    => $JC,
		remove_columns => ['name'],
	);
	ok(!(grep { $_ eq 'name' } @{ $j->columns() }),
		"remove_columns: ['name'] → 'name' absent from columns() (EP valid)");
}

# ==========================================================================
# Section 6: `remove_column` method parameter domain
#
# EP valid: any non-join-column string (existing or not) is handled safely.
# EP invalid: join_col → croak; is idempotent on repeated calls.
# BVA: undef and '' are explicit no-ops (defined boundary of "empty input").
# ==========================================================================

note '--- Section 6: remove_column method parameter ---';

# BVA below-minimum: undef → safe no-op, returns $self
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $ret = $j->remove_column(undef);
	is($ret, $j, 'remove_column(undef): no-op, returns $self (BVA below-min)');
}

# BVA minimum: '' → safe no-op, returns $self
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $ret = $j->remove_column('');
	is($ret, $j, "remove_column(''): no-op, returns \$self (BVA length-0)");
}

# EP invalid: join_col → croak remove_join_col
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	throws_ok { $j->remove_column($JC) }
		$ERR{remove_join_col}, 'remove_column(join_col): croaks remove_join_col (EP invalid)';
}

# EP valid: non-existent column → idempotent, column count unchanged
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $before = scalar @{ $j->columns() };
	$j->remove_column('no_such_column');
	is(scalar @{ $j->columns() }, $before,
		'remove_column(nonexistent): column count unchanged (EP valid-nonexistent)');
}

# EP valid: existing column → absent from columns()
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	$j->remove_column('name');
	ok(!(grep { $_ eq 'name' } @{ $j->columns() }),
		"remove_column('name'): absent from columns() after removal");
}

# EP valid idempotent: same column removed twice → no error on second call
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	$j->remove_column('score');
	my $ret = $j->remove_column('score');
	is($ret, $j, 'remove_column twice: idempotent, $self returned on second call');
}

# ==========================================================================
# Section 7: query criteria value domain
#
# EP valid: no args, positional scalar, named pairs, operator hashrefs.
# EP invalid: unknown column → carp + criterion ignored.
# BVA: positional '0' (false-but-defined) tests join-key false-string boundary.
# ==========================================================================

note '--- Section 7: query criteria value domain ---';

# EP: no args → all rows
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 2, 'criteria: no args → all 2 rows (EP no-args)');
}

# BVA: positional '0' — false-but-defined join-key value; must not be treated as "no arg"
{
	my $p = DomainDA->new(
		cols => [$JC, 'name'],
		rows => [{ $JC => '0', name => 'Zero' }, { $JC => '1', name => 'One' }],
	);
	my $s = DomainDA->new(
		cols => [$JC, 'score'],
		rows => [{ $JC => '0', score => 0 }, { $JC => '1', score => 1 }],
	);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $rows = $j->selectall_arrayref('0');
	is(scalar @{$rows}, 1, "criteria: positional '0' filters to 1 row (BVA false-string)");
	is($rows->[0]{name}, 'Zero', "criteria: positional '0' retrieves correct row");
}

# EP: equality criterion on secondary column
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $rows = $j->selectall_arrayref(score => 90);
	is(scalar @{$rows}, 1, 'criteria: equality on secondary column → 1 matching row (EP equality)');
}

# EP: operator hashref (>) on secondary column
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $rows = $j->selectall_arrayref(score => { '>' => 80 });
	is(scalar @{$rows}, 1, 'criteria: operator > on secondary column → 1 row (EP operator)');
}

# EP invalid: unknown column → carp warn_unknown_column + criterion ignored
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $rows;
	my $warns = _capture_warnings { $rows = $j->selectall_arrayref(ghost => 'x') };
	ok scalar @{$warns}, 'criteria: unknown column → carp emitted (EP invalid-column)';
	like $warns->[0], $ERR{unknown_col}, 'criteria: carp message matches warn_unknown_column';
	is(scalar @{$rows}, 2, 'criteria: unknown column criterion ignored → all rows returned');
}

# EP: join_col criterion → broadcast to all DBs
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $rows = $j->selectall_arrayref($JC => 'k1');
	is(scalar @{$rows}, 1, 'criteria: join_col criterion broadcast → 1 matching row');
}

# EP: criterion on removed column → carp + criterion ignored (all rows)
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	$j->remove_column('name');
	my $rows;
	my $warns = _capture_warnings { $rows = $j->selectall_arrayref(name => 'Alice') };
	ok scalar @{$warns}, 'criteria: removed-col criterion → carp emitted';
	like $warns->[0], $ERR{unknown_col}, 'criteria: removed-col carp message matches warn_unknown_column';
	is(scalar @{$rows}, 2, 'criteria: removed-col criterion ignored → all rows returned');
}

# ==========================================================================
# Section 8: `join_type` behavioral domain
#
# Tests the key-set semantics of each valid join_type value at the boundary
# conditions (empty primary, disjoint key sets, three-way overlap).
# ==========================================================================

note '--- Section 8: join_type behavioral key-set domain ---';

# Fixture: partially-overlapping key sets.
# Primary   has: k1, k2        (k2 is primary-only)
# Secondary has: k1, k3        (k3 is secondary-only)
# Shared:        k1

Readonly::Hash my %PARTIAL => (
	primary   => [{ $JC => 'k1', name  => 'A' }, { $JC => 'k2', name  => 'B' }],
	secondary => [{ $JC => 'k1', score => 10  }, { $JC => 'k3', score => 30 }],
);

# EP 'left': shared + primary-only keys present; secondary-only excluded
{
	my $p = DomainDA->new(cols => [$JC, 'name'],  rows => $PARTIAL{primary});
	my $s = DomainDA->new(cols => [$JC, 'score'], rows => $PARTIAL{secondary});
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'left');
	my %keys = map { $_->{$JC} => 1 } @{ $j->selectall_arrayref() };
	ok( $keys{k1}, "join_type 'left': shared key k1 present");
	ok( $keys{k2}, "join_type 'left': primary-only key k2 present");
	ok(!$keys{k3}, "join_type 'left': secondary-only key k3 excluded");
}

# EP 'inner': only shared key present; both primary-only and secondary-only excluded
{
	my $p = DomainDA->new(cols => [$JC, 'name'],  rows => $PARTIAL{primary});
	my $s = DomainDA->new(cols => [$JC, 'score'], rows => $PARTIAL{secondary});
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'inner');
	my %keys = map { $_->{$JC} => 1 } @{ $j->selectall_arrayref() };
	ok( $keys{k1}, "join_type 'inner': shared key k1 present");
	ok(!$keys{k2}, "join_type 'inner': primary-only k2 excluded");
	ok(!$keys{k3}, "join_type 'inner': secondary-only k3 excluded");
}

# EP 'outer': all keys from every DB are included
{
	my $p = DomainDA->new(cols => [$JC, 'name'],  rows => $PARTIAL{primary});
	my $s = DomainDA->new(cols => [$JC, 'score'], rows => $PARTIAL{secondary});
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'outer');
	my %keys = map { $_->{$JC} => 1 } @{ $j->selectall_arrayref() };
	ok($keys{k1} && $keys{k2} && $keys{k3},
		"join_type 'outer': all three keys present (union)");
}

# BVA 'left' with empty primary → 0 results (primary defines the key set)
{
	my $p = DomainDA->new(cols => [$JC, 'name'],  rows => []);
	my $s = DomainDA->new(cols => [$JC, 'score'], rows => [{ $JC => 'k1', score => 1 }]);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'left');
	is(scalar @{ $j->selectall_arrayref() }, 0,
		"join_type 'left': empty primary → 0 results (BVA empty-primary)");
}

# BVA 'inner' with disjoint key sets → 0 results (no intersection)
{
	my $p = DomainDA->new(cols => [$JC, 'name'],  rows => [{ $JC => 'k1', name => 'A' }]);
	my $s = DomainDA->new(cols => [$JC, 'score'], rows => [{ $JC => 'k2', score => 1 }]);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'inner');
	is(scalar @{ $j->selectall_arrayref() }, 0,
		"join_type 'inner': disjoint key sets → 0 results (BVA no-overlap)");
}

# ==========================================================================
# Section 9: `add_database` parameter domain
#
# EP valid: positional blessed DA; named 'database =>' form.
# EP invalid: non-ref non-key scalar, wrong ISA, DA missing join_col.
# EP valid: join_column => param remaps the column name for the new DA.
# ==========================================================================

note '--- Section 9: add_database parameter domain ---';

# EP valid: positional blessed DA
{
	my ($p, $s) = _dbs();
	my $j   = Database::Join->new(databases => [$p], join_column => $JC);
	my $ret = $j->add_database($s);
	is($ret, $j, 'add_database: positional blessed DA → returns $self');
}

# EP valid: named 'database =>' form
{
	my ($p, $s) = _dbs();
	my $j   = Database::Join->new(databases => [$p], join_column => $JC);
	my $ret = $j->add_database(database => $s);
	is($ret, $j, 'add_database: named database=> form → returns $self');
}

# EP invalid: non-ref first arg that is not a recognised named-pair key
{
	my ($p) = _dbs();
	my $j = Database::Join->new(databases => [$p], join_column => $JC);
	throws_ok { $j->add_database('not_a_key') }
		$ERR{invalid_db},
		'add_database: non-ref non-key scalar → croaks invalid_db';
}

# EP invalid: blessed object with wrong class (not a DA::Abstraction subclass)
{
	my ($p) = _dbs();
	my $j = Database::Join->new(databases => [$p], join_column => $JC);
	throws_ok { $j->add_database(WrongClass->new()) }
		$ERR{invalid_db}, 'add_database: wrong-class object → croaks invalid_db';
}

# EP invalid: DA that does not have the join_column in its column list
{
	my ($p) = _dbs();
	my $j   = Database::Join->new(databases => [$p], join_column => $JC);
	my $bad = DomainDA->new(cols => ['tid', 'data'], rows => [{ tid => 'k1', data => 'x' }]);
	throws_ok { $j->add_database($bad) }
		$ERR{join_col_missing}, 'add_database: DA missing join_col → croaks join_col_missing';
}

# EP valid: join_column => param allows a differently-named join key in the new DA
{
	my ($p) = _dbs();
	my $j = Database::Join->new(databases => [$p], join_column => $JC);
	my $s = DomainDA->new(
		cols => ['tid', 'score'],
		rows => [{ tid => 'k1', score => 99 }],
	);
	my $ret = $j->add_database($s, join_column => 'tid');
	is($ret, $j, 'add_database: join_column=> alias accepted → returns $self');
}

# ==========================================================================
# Section 10: `filters` parameter domain
#
# EP valid: absent, {}, {i => {}}, {i => {col => val}}.
# BVA: per-db empty {} is a no-op; secondary filter acts as inner-join partner.
# ==========================================================================

note '--- Section 10: filters parameter domain ---';

# EP absent → all rows from every DB included
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	is(scalar @{ $j->selectall_arrayref() }, 2,
		'filters: absent → all 2 rows included (EP absent)');
}

# EP valid: {} global empty → all rows (no-op)
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, filters => {});
	is(scalar @{ $j->selectall_arrayref() }, 2,
		'filters: {} global empty → all rows (EP valid-empty)');
}

# EP valid: {0 => {col => val}} → primary filter restricts result set
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => $JC,
		filters     => { 0 => { name => 'Alice' } },
	);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 1, "filters: {0 => {name=>'Alice'}} → 1 row (EP primary-filter)");
	is($rows->[0]{name}, 'Alice', 'filters: correct row returned');
}

# BVA: secondary filter forces inner-join semantics regardless of join_type
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => $JC,
		join_type   => 'left',
		filters     => { 1 => { score => 90 } },
	);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 1, 'filters: secondary filter → inner-join partner (k2 excluded)');
}

# EP valid: {0 => {}} per-db empty criteria hashref → no-op filter
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => $JC,
		filters     => { 0 => {} },
	);
	is(scalar @{ $j->selectall_arrayref() }, 2,
		'filters: {0 => {}} empty per-db criteria → all rows (EP per-db-empty)');
}

# ==========================================================================
# Section 11: Combinatorial boundary interactions
#
# Each test fixes one parameter at an edge value while varying another,
# probing interactions that might not surface in isolated section tests.
# ==========================================================================

note '--- Section 11: Combinatorial boundary interactions ---';

# Combinatorial: n=1 DB + join_type='inner' → all primary rows returned.
# (No secondary to intersect; inner semantics must not drop primary rows.)
{
	my ($p) = _dbs();
	my $j = Database::Join->new(databases => [$p], join_column => $JC, join_type => 'inner');
	is(scalar @{ $j->selectall_arrayref() }, 2,
		'combinatorial: n=1 DB + inner → all primary rows (no secondary to intersect)');
}

# Combinatorial: join_map (cross-name join) + equality criterion on join_col
{
	my $p = DomainDA->new(
		cols => [$JC, 'name'],
		rows => [{ $JC => 'k1', name => 'A' }, { $JC => 'k2', name => 'B' }],
	);
	my $s = DomainDA->new(
		cols => ['tid', 'score'],
		rows => [{ tid => 'k1', score => 10 }, { tid => 'k2', score => 20 }],
	);
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => $JC,
		join_map    => { 1 => 'tid' },
	);
	my $rows = $j->selectall_arrayref($JC => 'k1');
	is(scalar @{$rows}, 1, 'combinatorial: join_map + join_col criterion → 1 correct row');
}

# Combinatorial: remove_columns + query on the removed column → carp + ignored
{
	my ($p, $s) = _dbs();
	my $j = Database::Join->new(
		databases      => [$p, $s],
		join_column    => $JC,
		remove_columns => ['score'],
	);
	my $rows;
	my $warns = _capture_warnings { $rows = $j->selectall_arrayref(score => 90) };
	ok scalar @{$warns},       'combinatorial: removed-col criterion → carp emitted';
	like $warns->[0], $ERR{unknown_col}, 'combinatorial: carp message is warn_unknown_column';
	is(scalar @{$rows}, 2,    'combinatorial: removed-col criterion ignored → all rows returned');
}

# Combinatorial: filter on secondary + outer join → filter overrides outer key-set
# The filtered secondary acts as an inner-join partner so k2 is excluded despite 'outer'.
{
	my $p = DomainDA->new(
		cols => [$JC, 'name'],
		rows => [{ $JC => 'k1', name => 'A' }, { $JC => 'k2', name => 'B' }],
	);
	my $s = DomainDA->new(
		cols => [$JC, 'score'],
		rows => [{ $JC => 'k1', score => 10 }],
	);
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => $JC,
		join_type   => 'outer',
		filters     => { 1 => { score => 10 } },
	);
	my %keys = map { $_->{$JC} => 1 } @{ $j->selectall_arrayref() };
	ok(!$keys{k2},
		'combinatorial: filtered secondary + outer → k2 excluded (filter overrides outer)');
}
