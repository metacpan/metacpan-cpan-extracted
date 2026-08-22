#!/usr/bin/perl

# Control-Flow Path Coverage for Database::Join.
# One test case per uniquely identifiable execution path through the CFG.

use strict;
use warnings;

use Test::Most tests => 85;
use Readonly;
use Scalar::Util qw(blessed refaddr);

use_ok('Database::Join');

# ---------------------------------------------------------------------------
# Inline test doubles
# ---------------------------------------------------------------------------

{
	package PathDA;
	use parent -norequire, 'Database::Abstraction';

	sub new {
		my ($class, %a) = @_;
		return bless {
			cols    => $a{cols}    // ['entry'],
			rows    => $a{rows}    // [],
			id      => $a{id},		# may be undef to test fallback path
			schema  => $a{schema}  // {},
			updated => $a{updated} // 1,
			_logger => undef,
		}, $class;
	}
	sub columns          { return $_[0]->{cols} }
	sub schema           { return $_[0]->{schema} }	# may return undef explicitly
	sub updated          { return $_[0]->{updated} }
	sub set_logger       { $_[0]->{_logger} = $_[1]; return $_[0] }
	sub get_logger       { return $_[0]->{_logger} }

	sub selectall_arrayref {
		my ($self, $criteria) = @_;
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

# DA with a real column method for AUTOLOAD direct-delegation path
{
	package PathDirectDA;
	use parent -norequire, 'Database::Abstraction';

	sub new {
		my ($class, %a) = @_;
		return bless {
			cols    => $a{cols}  // ['entry', 'score'],
			rows    => $a{rows}  // [],
			id      => $a{id}    // 'entry',
			_calls  => 0,
			_logger => undef,
		}, $class;
	}
	sub columns    { return $_[0]->{cols} }
	sub schema     { return {} }
	sub updated    { return 1 }
	sub set_logger { $_[0]->{_logger} = $_[1]; return $_[0] }
	sub get_logger { return $_[0]->{_logger} }
	sub calls      { return $_[0]->{_calls} }

	# Real column method — AUTOLOAD delegates here on the direct path
	sub score {
		my ($self, @args) = @_;
		$self->{_calls}++;
		return wantarray ? (90, 70) : 90;
	}

	sub selectall_arrayref {
		my ($self, $criteria) = @_;
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

# i18n mock that has translate → exercises the translate branch in _msg
{
	package MockI18N;
	sub new       { bless { keys => [] }, shift }
	sub translate { my ($self, $key, @a) = @_; push @{$self->{keys}}, $key; return "TRANSLATED:$key" }
}

# i18n mock WITHOUT translate → exercises the fallback-to-%MESSAGES branch
{
	package MockI18NBlind;
	sub new { bless {}, shift }
	# deliberately omits translate
}

# Logger mock with set_logger/get_logger — verifies propagation paths
{
	package MockLogger;
	sub new { bless {}, shift }
	sub debug {}
	sub info  {}
}

# WhiteBox subclass to call Sub::Protected helpers directly
{
	package Database::Join::PathBox;
	use parent -norequire, 'Database::Join';

	sub expose_msg   { shift; return Database::Join::_msg(@_) }
	sub expose_merge { shift; return Database::Join::_merge_criteria(@_) }
	sub expose_parse { my $self = shift; return $self->_parse_query_args(@_) }
	sub expose_part  { my $self = shift; return $self->_partition_criteria(@_) }
	sub expose_fetch { my $self = shift; return $self->_fetch_indexed(@_) }
}

# ---------------------------------------------------------------------------
# Shared constants
# ---------------------------------------------------------------------------

Readonly::Scalar my $JC => 'entry';

Readonly::Hash my %ERR => (
	private_method  => qr/cannot call private method/i,
	unknown_col_al  => qr/unknown column/i,
	remove_join_col => qr/Cannot remove join_column/,
	unknown_col_carp => qr/not present in any configured database/,
	set_logger      => qr/Usage: set_logger/,
	invalid_db      => qr/databases\[\d+\] is not a Database::Abstraction object/,
	join_col_miss   => qr/join_column "[^"]*" is absent from databases\[\d+\]/,
);

# Standard two-DB fixture
sub _std_dbs {
	my $p = PathDA->new(
		cols => [$JC, 'name'],
		rows => [
			{ $JC => 'k1', name => 'Alice' },
			{ $JC => 'k2', name => 'Bob'   },
		],
		id => 'entry',
	);
	my $s = PathDA->new(
		cols => [$JC, 'score'],
		rows => [
			{ $JC => 'k1', score => 90 },
			{ $JC => 'k2', score => 70 },
		],
		id => 'entry',
	);
	return ($p, $s);
}

sub _std_join {
	my %opt = @_;
	my ($p, $s) = _std_dbs();
	return Database::Join->new(
		databases   => [$p, $s],
		join_column => $JC,
		%opt,
	);
}

sub _capture_warn (&) {		## no critic (Prototypes)
	my ($code) = @_;
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	$code->();
	return \@w;
}

# ==========================================================================
# Section 1: new() execution paths
# ==========================================================================

note '--- Section 1: new() execution paths ---';

# PATH-new-1: databases[0]{id} is defined → _autoload_pk captures it
{
	my $p = PathDA->new(cols => [$JC, 'name'], rows => [], id => 'myid');
	my $s = PathDA->new(cols => [$JC, 'tag'],  rows => [], id => 'entry');
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	is($j->{_autoload_pk}, 'myid',
		'new PATH-1: _autoload_pk = databases[0]{id} when id is set');
}

# PATH-new-2: databases[0]{id} is undef → _autoload_pk falls back to join_column
{
	my $p = PathDA->new(cols => [$JC, 'name'], rows => [], id => undef);
	my $s = PathDA->new(cols => [$JC, 'tag'],  rows => [], id => undef);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	is($j->{_autoload_pk}, $JC,
		'new PATH-2: _autoload_pk falls back to join_column when {id} is undef');
}

# PATH-new-3: logger provided → propagated to both component DAs at construction
{
	my $log = MockLogger->new();
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, logger => $log);
	is($j->{_logger}, $log, 'new PATH-3a: logger stored in join object');
	is($p->get_logger(), $log, 'new PATH-3b: logger propagated to primary DA');
	is($s->get_logger(), $log, 'new PATH-3c: logger propagated to secondary DA');
}

# PATH-new-4: no logger → DAs retain undef logger (propagation branch skipped)
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	ok(!defined $p->get_logger(),
		'new PATH-4: no logger supplied → DA logger remains undef');
}

# PATH-new-5: remove_columns applied at construction
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(
		databases      => [$p, $s],
		join_column    => $JC,
		remove_columns => ['name'],
	);
	ok(!(grep { $_ eq 'name' } @{ $j->columns() }),
		"new PATH-5: remove_columns=['name'] → 'name' excluded at construction");
}

# PATH-new-6: no remove_columns → all columns present
{
	my $j = _std_join();
	ok((grep { $_ eq 'name' } @{ $j->columns() }),
		'new PATH-6: no remove_columns → all columns visible');
}

# ==========================================================================
# Section 2: columns() execution paths
# ==========================================================================

note '--- Section 2: columns() execution paths ---';

# PATH-cols-1: second call hits cache (same arrayref returned)
{
	my $j = _std_join();
	my $c1 = $j->columns();
	my $c2 = $j->columns();
	is(refaddr($c1), refaddr($c2), 'columns PATH-1: cache hit → same arrayref ref');
}

# PATH-cols-2: no join_map → every non-removed col appears (including join_col)
{
	my $j = _std_join();
	my %cols = map { $_ => 1 } @{ $j->columns() };
	ok($cols{$JC} && $cols{name} && $cols{score},
		'columns PATH-2: no join_map → entry, name, score all present');
}

# PATH-cols-3: join_map alias NOT in columns(); canonical join_col IS present
{
	my $p = PathDA->new(cols => [$JC, 'name'],  rows => []);
	my $s = PathDA->new(cols => ['tid', 'score'], rows => []);
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => $JC,
		join_map    => { 1 => 'tid' },
	);
	my %cols = map { $_ => 1 } @{ $j->columns() };
	ok(!$cols{tid}, 'columns PATH-3a: join_map alias "tid" excluded from columns()');
	ok($cols{$JC},  'columns PATH-3b: canonical join_col "entry" present');
}

# PATH-cols-4: deduplication — same column name in two DBs appears exactly once
{
	my $p = PathDA->new(cols => [$JC, 'shared'], rows => []);
	my $s = PathDA->new(cols => [$JC, 'shared'], rows => []);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my @shared = grep { $_ eq 'shared' } @{ $j->columns() };
	is(scalar @shared, 1, 'columns PATH-4: duplicate col from two DBs appears once');
}

# PATH-cols-5: removed column excluded; cache invalidated after remove_column
{
	my $j = _std_join();
	my $before = scalar @{ $j->columns() };
	$j->remove_column('name');
	my $after = scalar @{ $j->columns() };
	is($after, $before - 1, 'columns PATH-5: cache recomputed after remove_column, count decremented');
}

# ==========================================================================
# Section 3: schema() execution paths
# ==========================================================================

note '--- Section 3: schema() execution paths ---';

# PATH-schema-1: second call hits cache (same hashref)
{
	my $j = _std_join();
	my $s1 = $j->schema();
	my $s2 = $j->schema();
	is(refaddr($s1), refaddr($s2), 'schema PATH-1: cache hit → same hashref ref');
}

# PATH-schema-2: no join_map → hash-slice path; both DAs' cols appear in schema
{
	my $p = PathDA->new(
		cols   => [$JC, 'name'],
		schema => { $JC => { type => 'text' }, name => { type => 'text' } },
		rows   => [],
	);
	my $s = PathDA->new(
		cols   => [$JC, 'score'],
		schema => { $JC => { type => 'text' }, score => { type => 'int' } },
		rows   => [],
	);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $sch = $j->schema();
	ok(exists $sch->{name},  'schema PATH-2a: no join_map → "name" in schema');
	ok(exists $sch->{score}, 'schema PATH-2b: no join_map → "score" in schema');
}

# PATH-schema-3: join_map alias → filter-loop path; alias absent; canonical present
{
	my $p = PathDA->new(
		cols   => [$JC, 'name'],
		schema => { $JC => { type => 'text' }, name => { type => 'text' } },
		rows   => [],
	);
	my $s = PathDA->new(
		cols   => ['tid', 'score'],
		schema => { tid => { type => 'text' }, score => { type => 'int' } },
		rows   => [],
	);
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => $JC,
		join_map    => { 1 => 'tid' },
	);
	my $sch = $j->schema();
	ok(!exists $sch->{tid}, 'schema PATH-3a: join_map → alias "tid" absent from schema');
	ok(exists $sch->{$JC},  'schema PATH-3b: canonical join_col present in schema');
}

# PATH-schema-4: removed col deleted from merged schema
{
	my $j = _std_join();
	$j->remove_column('name');
	ok(!exists $j->schema()->{name}, 'schema PATH-4: removed col absent from schema');
}

# PATH-schema-5: DA schema() returns undef → guard treats it as {} (no crash)
{
	my $p = PathDA->new(cols => [$JC, 'name'], rows => [], schema => undef);
	my $s = PathDA->new(cols => [$JC, 'score'], rows => []);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $sch = $j->schema();
	ok(ref($sch) eq 'HASH', 'schema PATH-5: undef DA schema → no crash, returns hashref');
}

# ==========================================================================
# Section 4: _parse_query_args() behavioural paths
# (tested via selectall_arrayref / fetchrow_hashref return values)
# ==========================================================================

note '--- Section 4: _parse_query_args() paths ---';

# PATH-pqa-1: no args → {} → all rows returned
{
	my $j = _std_join();
	is(scalar @{ $j->selectall_arrayref() }, 2,
		'_parse_query_args PATH-1: no args → {} → all 2 rows');
}

# PATH-pqa-2: single non-ref positional arg → {join_col => val}
{
	my $j = _std_join();
	my $rows = $j->selectall_arrayref('k1');
	is(scalar @{$rows}, 1, '_parse_query_args PATH-2: positional scalar → 1 row by join_col');
}

# PATH-pqa-3: named pairs → criteria hashref
{
	my $j = _std_join();
	my $rows = $j->selectall_arrayref(score => 90);
	is(scalar @{$rows}, 1, '_parse_query_args PATH-3: named pairs → 1 row matching score=90');
}

# PATH-pqa-4: single ref arg (operator hashref) → get_params path
{
	my $j = _std_join();
	my $rows = $j->selectall_arrayref(score => { '>=' => 70 });
	is(scalar @{$rows}, 2, '_parse_query_args PATH-4: operator hashref → 2 rows (score>=70)');
}

# ==========================================================================
# Section 5: _partition_criteria() paths
# ==========================================================================

note '--- Section 5: _partition_criteria() paths ---';

# PATH-part-1: join_col scalar → broadcast to all DBs
{
	my $j = _std_join();
	my $rows = $j->selectall_arrayref($JC => 'k1');
	is(scalar @{$rows}, 1, '_partition PATH-1: join_col scalar broadcast → 1 row');
}

# PATH-part-2: join_col HASH → shallow-copy broadcast per DB
# Verify via two numeric keys so comparison operators work correctly.
{
	my $p = PathDA->new(
		cols => [$JC, 'name'],
		rows => [{ $JC => 1, name => 'A' }, { $JC => 2, name => 'B' }],
	);
	my $s = PathDA->new(
		cols => [$JC, 'score'],
		rows => [{ $JC => 1, score => 90 }, { $JC => 2, score => 70 }],
	);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $rows = $j->selectall_arrayref($JC => { '>=' => 1 });
	is(scalar @{$rows}, 2,
		'_partition PATH-2: join_col HASH (operator) broadcast → both rows qualify');
}

# PATH-part-3: non-join col → routed to owning DB only
{
	my $j = _std_join();
	my $rows = $j->selectall_arrayref(score => 90);
	is(scalar @{$rows}, 1, '_partition PATH-3: non-join col routed to owning DB → 1 row');
}

# PATH-part-4: unknown column → carp with warn_unknown_column
{
	my $j = _std_join();
	my $rows;
	my $warns = _capture_warn { $rows = $j->selectall_arrayref(ghost => 'x') };
	ok(scalar @{$warns},          '_partition PATH-4a: unknown col → carp emitted');
	like($warns->[0], $ERR{unknown_col_carp},
		'_partition PATH-4b: carp message is warn_unknown_column');
}

# ==========================================================================
# Section 6: _fetch_indexed() paths
# ==========================================================================

note '--- Section 6: _fetch_indexed() paths ---';

# PATH-fi-1: row with undef join key → skipped from indexed → not in results
{
	my $p = PathDA->new(
		cols => [$JC, 'name'],
		rows => [{ $JC => 'k1', name => 'A' }, { $JC => undef, name => 'Ghost' }],
	);
	my $s = PathDA->new(
		cols => [$JC, 'score'],
		rows => [{ $JC => 'k1', score => 90 }],
	);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'left');
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 1, '_fetch_indexed PATH-1: row with undef join key excluded');
}

# PATH-fi-2: normal rows all indexed → both appear in results
{
	my $j = _std_join();
	is(scalar @{ $j->selectall_arrayref() }, 2,
		'_fetch_indexed PATH-2: normal rows → both indexed and returned');
}

# PATH-fi-3: multiple rows with same join key → all preserved (one-to-many)
{
	my $p = PathDA->new(
		cols => [$JC, 'name'],
		rows => [
			{ $JC => 'k1', name => 'Alice'   },
			{ $JC => 'k1', name => 'Alias-A' },
		],
	);
	my $s = PathDA->new(
		cols => [$JC, 'score'],
		rows => [{ $JC => 'k1', score => 90 }],
	);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 2, '_fetch_indexed PATH-3: two primary rows same key → 2 merged rows');
}

# PATH-fi-4: DA selectall_arrayref returns undef → guard replaces with [] → empty result
{
	my $p = PathDA->new(cols => [$JC, 'name'], rows => []);
	my $s = PathDA->new(cols => [$JC, 'score'], rows => []);
	# Patch selectall_arrayref to return undef on primary
	no warnings 'redefine';
	local *PathDA::selectall_arrayref = sub { return undef };
	use warnings 'redefine';
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 0, '_fetch_indexed PATH-4: DA returns undef → guarded to [] → empty result');
}

# ==========================================================================
# Section 7: _joined_query() key-set paths
# ==========================================================================

note '--- Section 7: _joined_query() key-set paths ---';

# PATH-jq-1: n=1 (secondary loop range 1..0 — never enters); all primary rows returned
{
	my $p = PathDA->new(cols => [$JC, 'name'],
		rows => [{ $JC => 'k1', name => 'A' }, { $JC => 'k2', name => 'B' }]);
	my $j = Database::Join->new(databases => [$p], join_column => $JC);
	is(scalar @{ $j->selectall_arrayref() }, 2,
		'_joined_query PATH-1: n=1 → secondary loop skipped, all primary rows returned');
}

# PATH-jq-2: n=2, left, no secondary criteria → primary-only key present
{
	my $p = PathDA->new(cols => [$JC, 'name'],
		rows => [{ $JC => 'k1', name => 'A' }, { $JC => 'k2', name => 'B' }]);
	my $s = PathDA->new(cols => [$JC, 'score'],
		rows => [{ $JC => 'k1', score => 90 }]);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'left');
	my %keys = map { $_->{$JC} => 1 } @{ $j->selectall_arrayref() };
	ok($keys{k1} && $keys{k2},
		'_joined_query PATH-2: left, no secondary criteria → k2 (primary-only) kept');
}

# PATH-jq-3: n=2, inner → primary-only key excluded (intersect path)
{
	my $p = PathDA->new(cols => [$JC, 'name'],
		rows => [{ $JC => 'k1', name => 'A' }, { $JC => 'k2', name => 'B' }]);
	my $s = PathDA->new(cols => [$JC, 'score'],
		rows => [{ $JC => 'k1', score => 90 }]);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'inner');
	my %keys = map { $_->{$JC} => 1 } @{ $j->selectall_arrayref() };
	ok($keys{k1} && !$keys{k2},
		'_joined_query PATH-3: inner → k2 (primary-only) excluded by intersect');
}

# PATH-jq-4: n=2, outer → secondary-only key included (union path)
{
	my $p = PathDA->new(cols => [$JC, 'name'],
		rows => [{ $JC => 'k1', name => 'A' }]);
	my $s = PathDA->new(cols => [$JC, 'score'],
		rows => [{ $JC => 'k1', score => 90 }, { $JC => 'k2', score => 70 }]);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'outer');
	my %keys = map { $_->{$JC} => 1 } @{ $j->selectall_arrayref() };
	ok($keys{k1} && $keys{k2},
		'_joined_query PATH-4: outer → k2 (secondary-only) included via union');
}

# PATH-jq-5: n=2, left, but secondary has criteria → had_criteria forces intersect
{
	my $p = PathDA->new(cols => [$JC, 'name'],
		rows => [{ $JC => 'k1', name => 'A' }, { $JC => 'k2', name => 'B' }]);
	my $s = PathDA->new(cols => [$JC, 'score'],
		rows => [{ $JC => 'k1', score => 90 }, { $JC => 'k2', score => 70 }]);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'left');
	# score=90 criterion goes to secondary → had_criteria[1] = true → intersect
	my $rows = $j->selectall_arrayref(score => 90);
	is(scalar @{$rows}, 1,
		'_joined_query PATH-5: left + secondary criteria → had_criteria forces intersect');
}

# PATH-jq-6: filter overlay → $per_db merged with base filter; restricts key set
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => $JC,
		join_type   => 'left',
		filters     => { 1 => { score => 90 } },
	);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 1,
		'_joined_query PATH-6: filter overlay forces had_criteria → only k1 returned');
}

# PATH-jq-7: join_map → alias renamed to canonical join_col in merged row
{
	my $p = PathDA->new(cols => [$JC, 'name'],
		rows => [{ $JC => 'k1', name => 'A' }]);
	my $s = PathDA->new(cols => ['tid', 'score'],
		rows => [{ tid => 'k1', score => 99 }]);
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => $JC,
		join_map    => { 1 => 'tid' },
	);
	my $row = $j->fetchrow_hashref($JC => 'k1');
	ok(exists $row->{$JC},    '_joined_query PATH-7a: canonical join_col "entry" in merged row');
	ok(!exists $row->{tid},   '_joined_query PATH-7b: alias "tid" NOT in merged row');
}

# PATH-jq-8: outer join + key absent from primary → synthetic [{}] row from secondary only
{
	my $p = PathDA->new(cols => [$JC, 'name'],  rows => []);
	my $s = PathDA->new(cols => [$JC, 'score'], rows => [{ $JC => 'k1', score => 42 }]);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC, join_type => 'outer');
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 1, '_joined_query PATH-8a: outer + empty primary → 1 synthetic row');
	ok(exists $rows->[0]{score}, '_joined_query PATH-8b: synthetic row has secondary col');
}

# PATH-jq-9: removed cols stripped from every merged row
{
	my $j = _std_join(remove_columns => ['name']);
	my $rows = $j->selectall_arrayref();
	ok(!exists $rows->[0]{name},
		'_joined_query PATH-9: removed col absent from merged rows');
}

# PATH-jq-10: n=3, inner → only keys common to all three DBs survive
{
	my $a = PathDA->new(cols => [$JC, 'x'],
		rows => [{ $JC => 'k1', x => 1 }, { $JC => 'k2', x => 2 }]);
	my $b = PathDA->new(cols => [$JC, 'y'],
		rows => [{ $JC => 'k1', y => 3 }]);
	my $c = PathDA->new(cols => [$JC, 'z'],
		rows => [{ $JC => 'k1', z => 4 }, { $JC => 'k3', z => 5 }]);
	my $j = Database::Join->new(databases => [$a, $b, $c], join_column => $JC, join_type => 'inner');
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 1, '_joined_query PATH-10: n=3 inner → only k1 (in all three)');
}

# ==========================================================================
# Section 8: _merge_criteria() paths
# ==========================================================================

note '--- Section 8: _merge_criteria() paths ---';

# PATH-mc-1: column only in extra (query) → passes through; base empty
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(
		databases => [$p, $s], join_column => $JC,
		filters   => { 1 => {} },		# empty base filter → _merge_criteria sees empty base
	);
	my $rows = $j->selectall_arrayref(score => 90);
	is(scalar @{$rows}, 1, '_merge_criteria PATH-1: extra-only col → query criterion applied');
}

# PATH-mc-2: column only in base filter → preserved with no query override
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(
		databases => [$p, $s], join_column => $JC,
		filters   => { 1 => { score => 90 } },
	);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 1, '_merge_criteria PATH-2: base-only filter col → restricts to 1 row');
}

# PATH-mc-3: both values are operator hashrefs → combined with AND semantics
# filter: score > 75; query: score < 95 → only score=90 qualifies
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(
		databases => [$p, $s], join_column => $JC,
		filters   => { 1 => { score => { '>' => 75 } } },
	);
	my $rows = $j->selectall_arrayref(score => { '<' => 95 });
	is(scalar @{$rows}, 1,
		'_merge_criteria PATH-3: both operator hashrefs AND-combined → 1 row (90>75 AND 90<95)');
}

# PATH-mc-4: base is operator HASH, extra is scalar → scalar overwrites base
# filter: score > 60 (both qualify); query: score = 70 (scalar overwrites → only 70)
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(
		databases => [$p, $s], join_column => $JC,
		filters   => { 1 => { score => { '>' => 60 } } },
	);
	my $rows = $j->selectall_arrayref(score => 70);
	is(scalar @{$rows}, 1,
		'_merge_criteria PATH-4: base HASH overwritten by scalar → only score=70 returned');
}

# ==========================================================================
# Section 9: _msg() execution paths
# ==========================================================================

note '--- Section 9: _msg() paths ---';

# PATH-msg-1: i18n with translate → translate is called; custom message returned
{
	my $i18n = MockI18N->new();
	my $err;
	eval {
		Database::Join->new(databases => [], join_column => $JC, i18n => $i18n)
	};
	$err = $@;
	like($err, qr/TRANSLATED:/,
		'_msg PATH-1a: i18n translate called → error starts with TRANSLATED:');
	ok((grep { $_ eq 'error_no_databases' } @{$i18n->{keys}}),
		'_msg PATH-1b: translate received error_no_databases key');
}

# PATH-msg-2: i18n WITHOUT translate → fallback to %MESSAGES text
{
	my $blind = MockI18NBlind->new();
	my $err;
	eval {
		Database::Join->new(databases => [], join_column => $JC, i18n => $blind)
	};
	$err = $@;
	like($err, qr/At least one Database::Abstraction object is required/,
		'_msg PATH-2: no translate method → standard %MESSAGES text used');
}

# PATH-msg-3: no i18n → %MESSAGES text
{
	my $err;
	eval { Database::Join->new(databases => [], join_column => $JC) };
	$err = $@;
	like($err, qr/At least one Database::Abstraction object is required/,
		'_msg PATH-3: no i18n → standard %MESSAGES text');
}

# PATH-msg-4: known key + sprintf args → formatted string
# error_invalid_db = 'databases[%d] is not a Database::Abstraction object'
{
	my $err;
	eval { Database::Join->new(databases => [{}], join_column => $JC) };
	$err = $@;
	like($err, qr/databases\[0\] is not a Database::Abstraction object/,
		'_msg PATH-4: known key + %d arg → sprintf formats correctly');
}

# PATH-msg-5: unknown message key → error_unknown_message format
# Requires WhiteBox access to _msg
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join::PathBox->new(databases => [$p, $s], join_column => $JC);
	my $msg = $j->expose_msg(undef, 'totally_unknown_key_xyz');
	like($msg, qr/Unknown message key/i,
		'_msg PATH-5: unknown key → error_unknown_message format');
}

# ==========================================================================
# Section 10: AUTOLOAD execution paths
# ==========================================================================

note '--- Section 10: AUTOLOAD paths ---';

# PATH-al-1: object destruction does not croak (DESTROY short-circuit in AUTOLOAD)
{
	my $j = _std_join();
	lives_ok { undef $j } 'AUTOLOAD PATH-1: object destruction → no croak';
}

# PATH-al-2: private method name → croak before _col_db lookup
{
	my $j = _std_join();
	throws_ok { $j->_join_col() }
		$ERR{private_method}, 'AUTOLOAD PATH-2: private method → croak';
}

# PATH-al-3: unknown public column → croak unknown column
{
	my $j = _std_join();
	throws_ok { $j->ghost_column() }
		$ERR{unknown_col_al}, 'AUTOLOAD PATH-3: unknown column → croak';
}

# PATH-al-4: join_map active → _joined_query path (scalar context → first value)
{
	my $p = PathDA->new(cols => [$JC, 'name'],
		rows => [{ $JC => 'k1', name => 'Alice' }]);
	my $s = PathDA->new(cols => ['tid', 'score'],
		rows => [{ tid => 'k1', score => 99 }]);
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => $JC,
		join_map    => { 1 => 'tid' },
	);
	my $score = $j->score($JC => 'k1');
	is($score, 99, 'AUTOLOAD PATH-4: join_map active → _joined_query, scalar returns first value');
}

# PATH-al-5: filters active → _joined_query path
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(
		databases => [$p, $s],
		join_column => $JC,
		filters   => { 1 => { score => { '>=' => 0 } } },
	);
	my $name = $j->name($JC => 'k1');
	is($name, 'Alice', 'AUTOLOAD PATH-5: filters active → _joined_query, correct value');
}

# PATH-al-6: neither join_map nor filters → direct DA delegation
{
	my $p = PathDA->new(cols => [$JC, 'name'],
		rows => [{ $JC => 'k1', name => 'Alice' }]);
	my $s = PathDirectDA->new(
		cols => [$JC, 'score'],
		rows => [{ $JC => 'k1', score => 90 }],
	);
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	# No join_map, no filters → AUTOLOAD calls $s->score(@_) directly
	my $score = $j->score();
	is($score, 90, 'AUTOLOAD PATH-6: direct delegation to owning DA method');
	ok($s->calls() > 0, 'AUTOLOAD PATH-6b: DA score() method was called directly');
}

# PATH-al-7: join_map path, list context → all column values returned
{
	my $p = PathDA->new(cols => [$JC, 'name'],
		rows => [{ $JC => 'k1', name => 'Alice' }, { $JC => 'k2', name => 'Bob' }]);
	my $s = PathDA->new(cols => ['tid', 'score'],
		rows => [{ tid => 'k1', score => 90 }, { tid => 'k2', score => 70 }]);
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => $JC,
		join_map    => { 1 => 'tid' },
	);
	my @scores = $j->score();
	is(scalar @scores, 2, 'AUTOLOAD PATH-7: list context → all values returned');
}

# PATH-al-8: join_map path, scalar context → undef when no rows match
{
	my $p = PathDA->new(cols => [$JC, 'name'],
		rows => [{ $JC => 'k1', name => 'Alice' }]);
	my $s = PathDA->new(cols => ['tid', 'score'],
		rows => [{ tid => 'k1', score => 99 }]);
	my $j = Database::Join->new(
		databases   => [$p, $s],
		join_column => $JC,
		join_map    => { 1 => 'tid' },
	);
	my $score = $j->score($JC => 'nonexistent');
	ok(!defined $score, 'AUTOLOAD PATH-8: scalar context, no match → undef');
}

# ==========================================================================
# Section 11: set_logger() execution paths
# ==========================================================================

note '--- Section 11: set_logger() paths ---';

# PATH-sl-1: undef logger → croak 'Usage: set_logger'
{
	my $j = _std_join();
	throws_ok { $j->set_logger(undef) }
		$ERR{set_logger}, 'set_logger PATH-1: undef → croak';
}

# PATH-sl-2: valid logger → stored in join and propagated to all DAs
{
	my ($p, $s) = _std_dbs();
	my $j   = Database::Join->new(databases => [$p, $s], join_column => $JC);
	my $log = MockLogger->new();
	my $ret = $j->set_logger($log);
	is($ret,             $j,   'set_logger PATH-2a: returns $self');
	is($j->{_logger},   $log,  'set_logger PATH-2b: logger stored in join');
	is($p->get_logger(), $log,  'set_logger PATH-2c: logger propagated to primary DA');
	is($s->get_logger(), $log,  'set_logger PATH-2d: logger propagated to secondary DA');
}

# ==========================================================================
# Section 12: add_database() execution paths
# ==========================================================================

note '--- Section 12: add_database() paths ---';

# PATH-ad-1: positional ref arg → extraced before get_params, new cols appear
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(databases => [$p], join_column => $JC);
	my $ret = $j->add_database($s);
	is($ret, $j, 'add_database PATH-1: positional arg → returns $self');
	ok((grep { $_ eq 'score' } @{ $j->columns() }),
		'add_database PATH-1b: new col "score" visible after add');
}

# PATH-ad-2: named 'database =>' form → same result
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(databases => [$p], join_column => $JC);
	my $ret = $j->add_database(database => $s);
	is($ret, $j, 'add_database PATH-2: named form → returns $self');
}

# PATH-ad-3: non-ref first arg, not a recognised key → croak invalid_db
{
	my ($p) = _std_dbs();
	my $j = Database::Join->new(databases => [$p], join_column => $JC);
	throws_ok { $j->add_database('not_a_key') }
		$ERR{invalid_db}, 'add_database PATH-3: unknown non-ref first arg → croak invalid_db';
}

# PATH-ad-4: join_column param → registers alias in _join_map
{
	my ($p) = _std_dbs();
	my $j = Database::Join->new(databases => [$p], join_column => $JC);
	my $s = PathDA->new(cols => ['tid', 'score'], rows => [{ tid => 'k1', score => 5 }]);
	$j->add_database($s, join_column => 'tid');
	is($j->{_join_map}{1}, 'tid',
		'add_database PATH-4: join_column param → _join_map entry set');
}

# PATH-ad-5: filter param → registers in _filters
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(databases => [$p], join_column => $JC);
	$j->add_database($s, filter => { score => 90 });
	ok(defined $j->{_filters}{1},
		'add_database PATH-5: filter param → _filters entry registered');
}

# PATH-ad-6: join has logger → logger propagated to new DA
{
	my ($p, $s) = _std_dbs();
	my $log = MockLogger->new();
	my $j   = Database::Join->new(databases => [$p], join_column => $JC, logger => $log);
	my $new = PathDA->new(cols => [$JC, 'tag'], rows => []);
	$j->add_database($new);
	is($new->get_logger(), $log,
		'add_database PATH-6: join has logger → propagated to newly added DA');
}

# PATH-ad-7: no logger on join → new DA logger remains undef
{
	my ($p, $s) = _std_dbs();
	my $j   = Database::Join->new(databases => [$p], join_column => $JC);
	my $new = PathDA->new(cols => [$JC, 'tag'], rows => []);
	$j->add_database($new);
	ok(!defined $new->get_logger(),
		'add_database PATH-7: no logger on join → new DA logger stays undef');
}

# PATH-ad-8: remove_columns for new DA → col hidden immediately
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(databases => [$p], join_column => $JC);
	$j->add_database($s, remove_columns => ['score']);
	ok(!(grep { $_ eq 'score' } @{ $j->columns() }),
		'add_database PATH-8: remove_columns for new DA → col immediately hidden');
}

# PATH-ad-9: no remove_columns → new col visible
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(databases => [$p], join_column => $JC);
	$j->add_database($s);
	ok((grep { $_ eq 'score' } @{ $j->columns() }),
		'add_database PATH-9: no remove_columns → new col visible');
}

# PATH-ad-10: alias col (local_jc ne join_col) skipped in _col_db update loop
{
	my ($p) = _std_dbs();
	my $j = Database::Join->new(databases => [$p], join_column => $JC);
	my $s = PathDA->new(cols => ['tid', 'score'], rows => [{ tid => 'k1', score => 5 }]);
	$j->add_database($s, join_column => 'tid');
	# 'tid' is the local alias; it should not appear as a data column in _col_db
	ok(!defined $j->{_col_db}{tid},
		'add_database PATH-10: alias col "tid" skipped in _col_db update loop');
}

# ==========================================================================
# Section 13: _build_col_index() population paths
# ==========================================================================

note '--- Section 13: _build_col_index() population paths ---';

# PATH-bci-1: non-join cols from each DB appear in _col_db at correct index
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	is($j->{_col_db}{name},  0, '_build_col_index PATH-1a: "name" routes to DB[0]');
	is($j->{_col_db}{score}, 1, '_build_col_index PATH-1b: "score" routes to DB[1]');
}

# PATH-bci-2: join_col itself appears in _col_db (routed to whichever DB last defines it)
{
	my ($p, $s) = _std_dbs();
	my $j = Database::Join->new(databases => [$p, $s], join_column => $JC);
	ok(defined $j->{_col_db}{$JC}, '_build_col_index PATH-2: join_col "entry" present in _col_db');
}

done_testing();
