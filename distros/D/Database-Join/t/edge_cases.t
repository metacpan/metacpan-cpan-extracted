use strict;
use warnings;

# ---------------------------------------------------------------------------
# t/edge_cases.t -- Destructive, pathological, boundary-condition, and
# security tests for Database::Join.
#
# Strategy: actively attempt to break or subvert Database::Join via:
#   * Hostile constructor inputs (empty databases, wrong types, bad join_map)
#   * Boundary data values in join keys ("0", 0, "", undef, whitespace)
#   * Global state abuse ($_, $@, list-vs-scalar context confusion)
#   * Mocked upstream failures (DA returning undef, non-arrayref, or croaking)
#   * Security: heap-address leak guard, criteria broadcast mutation isolation
#   * AUTOLOAD adversarial: _private names, DESTROY, removed/unknown columns
#   * join_map / _merge_criteria corner cases and filter + outer-join interplay
#
# All component databases are inline MockEdgeDA stubs (no SQLite involved) for
# deterministic, zero-disk-I/O, instantly reproducible execution.
# ---------------------------------------------------------------------------

use Test::Most;
use Test::Mockingbird qw(spy restore_all);
use Readonly;
use Scalar::Util qw(blessed looks_like_number refaddr);

BEGIN {
	eval { require Database::Abstraction };
	plan skip_all => 'Database::Abstraction required' if $@;
	plan tests => 70;
	use_ok('Database::Join');
}

# ---------------------------------------------------------------------------
# Readonly attack payloads and structural constants
# ---------------------------------------------------------------------------
Readonly::Scalar my $JC          => 'entry';    # canonical join column
Readonly::Scalar my $K_ALPHA     => 'k001';
Readonly::Scalar my $K_BETA      => 'k002';
Readonly::Scalar my $K_GAMMA     => 'k003';
Readonly::Scalar my $KEY_ZERO    => '0';        # false-but-defined join key

Readonly::Scalar my $ERR_NO_DBS      => qr/At least one Database::Abstraction/;
Readonly::Scalar my $ERR_INVALID_DB  => qr/is not a Database::Abstraction/;
Readonly::Scalar my $ERR_MISSING_JC  => qr/is absent from databases/;
Readonly::Scalar my $ERR_REMOVE_JC   => qr/Cannot remove join_column/;
Readonly::Scalar my $ERR_PRIVATE     => qr/cannot call private method/;
Readonly::Scalar my $ERR_UNKNOWN_COL => qr/unknown column/;
Readonly::Scalar my $ERR_QUERY       => qr/query\(\) chained builder is not supported/;
Readonly::Scalar my $ERR_EXECUTE     => qr/execute\(\) raw SQL is not supported/;
Readonly::Scalar my $ERR_HEAP        => qr/\(join_map\[0\] must be a string\)/;

# ---------------------------------------------------------------------------
# MockEdgeDA: configurable in-process stub with explicit failure modes.
#
# Constructor options:
#   cols      => \@list     -- columns() return value
#   rows      => \@hrefs    -- data for selectall_arrayref
#   id        => 'colname'  -- internal primary-key field (_autoload_pk source)
#   updated   => $epoch     -- updated() return value
#   schema    => \%or_undef -- schema() return value (undef to simulate failure)
#   return    => $anything  -- literal return from selectall_arrayref (overrides rows)
#   croak_msg => 'text'     -- selectall_arrayref will croak with this message
# ---------------------------------------------------------------------------
## no critic (Modules::ProhibitMultiplePackages)
{
	package MockEdgeDA;
	use parent -norequire, 'Database::Abstraction';
	use Carp qw(croak);

	sub new {
		my ($class, %args) = @_;
		return bless {
			id      => $args{id}        // 'entry',
			_cols   => $args{cols}      // ['entry'],
			_rows   => $args{rows}      // [],
			_schema => $args{schema},           # deliberately no default -- undef is valid input
			_ts     => $args{updated}   // 1_000_000,
			_return => $args{return},
			_do_ret => (exists $args{return}),  # distinguish return=>undef from absent key
			_croak  => $args{croak_msg},
		}, $class;
	}

	sub columns   { return $_[0]->{_cols} }
	sub schema    { return $_[0]->{_schema} }
	sub updated   { return $_[0]->{_ts} }
	sub set_logger { $_[0]->{_logger} = $_[1]; return $_[0] }

	sub selectall_arrayref {
		my ($self, $criteria) = @_;
		croak($self->{_croak})   if $self->{_croak};
		return $self->{_return}  if $self->{_do_ret};
		my @rows = @{ $self->{_rows} };
		for my $col (keys %{ $criteria // {} }) {
			my $val = $criteria->{$col};
			if (ref($val) eq 'HASH') {
				for my $op (keys %{$val}) {
					my $v = $val->{$op};
					if    ($op eq '>')  { @rows = grep { defined $_->{$col} && $_->{$col} >  $v } @rows }
					elsif ($op eq '<')  { @rows = grep { defined $_->{$col} && $_->{$col} <  $v } @rows }
					elsif ($op eq '>=') { @rows = grep { defined $_->{$col} && $_->{$col} >= $v } @rows }
					elsif ($op eq '<=') { @rows = grep { defined $_->{$col} && $_->{$col} <= $v } @rows }
					elsif ($op eq '!=') { @rows = grep { defined $_->{$col} && $_->{$col} != $v } @rows }
				}
			} elsif (defined $val) {
				@rows = grep { defined $_->{$col} && $_->{$col} eq $val } @rows;
			} else {
				@rows = grep { !defined $_->{$col} } @rows;
			}
		}
		return \@rows;
	}

	sub DESTROY {}
}

# MutateCriteriaDA: simulates a hostile DA that mutates the criteria hashref
# it receives.  Used to prove that the broadcast shallow-copy mechanism
# prevents one DA from corrupting the criteria delivered to sibling databases.
{
	package MutateCriteriaDA;
	use parent -norequire, 'Database::Abstraction';

	sub new {
		my ($class, %args) = @_;
		return bless {
			id    => $args{id}   // 'entry',
			_cols => $args{cols} // ['entry'],
			_rows => $args{rows} // [],
		}, $class;
	}

	sub columns   { return $_[0]->{_cols} }
	sub schema    { return {} }
	sub updated   { return 1 }
	sub set_logger { $_[0]->{_logger} = $_[1]; return $_[0] }

	sub selectall_arrayref {
		my ($self, $criteria) = @_;
		# HOSTILE: overwrite the '>' operator inside the entry criteria hashref to
		# attempt to corrupt sibling databases' criteria for the same broadcast key.
		if (ref($criteria) eq 'HASH' && ref($criteria->{entry}) eq 'HASH') {
			$criteria->{entry}{'>'} = 999_999;
		}
		return $self->{_rows};
	}

	sub DESTROY {}
}

# ---------------------------------------------------------------------------
# Helper: build a minimal two-DB join with stock fixtures.
# Returns ($join, $primary_da, $secondary_da).
# ---------------------------------------------------------------------------
sub _minimal_join {
	my (%opts) = @_;
	my $prim = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [
			{ entry => $K_ALPHA, name => 'Alice' },
			{ entry => $K_BETA,  name => 'Bob'   },
		],
	);
	my $sec = MockEdgeDA->new(
		cols => ['entry', 'score'],
		rows => [
			{ entry => $K_ALPHA, score => 90 },
			{ entry => $K_BETA,  score => 70 },
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
# Section 1: Constructor hostility
# ===========================================================================

subtest 'constructor: empty databases arrayref croaks error_no_databases' => sub {
	# An empty arrayref satisfies the type check but fails the emptiness guard.
	throws_ok { Database::Join->new(databases => []) }
		$ERR_NO_DBS, 'empty databases => [] croaks';
};

subtest 'constructor: undef element in databases croaks error_invalid_db' => sub {
	throws_ok { Database::Join->new(databases => [undef]) }
		$ERR_INVALID_DB, 'databases => [undef] croaks';
};

subtest 'constructor: unblessed scalar in databases croaks' => sub {
	throws_ok { Database::Join->new(databases => [42]) }
		$ERR_INVALID_DB, 'databases => [42] (scalar) croaks';
};

subtest 'constructor: unblessed hashref in databases croaks' => sub {
	throws_ok { Database::Join->new(databases => [{}]) }
		$ERR_INVALID_DB, 'databases => [{}] (plain hashref) croaks';
};

subtest 'constructor: blessed object of wrong class croaks' => sub {
	# An object that is blessed but does not inherit Database::Abstraction.
	my $alien = bless {}, 'SomeUnrelatedClass';
	throws_ok { Database::Join->new(databases => [$alien]) }
		$ERR_INVALID_DB, 'non-DA blessed object croaks';
};

subtest 'constructor: invalid join_type enum croaks' => sub {
	my $da = MockEdgeDA->new(cols => ['entry', 'name']);
	throws_ok {
		Database::Join->new(databases => [$da], join_type => 'CROSS')
	} qr/must be one of|invalid|enum/i, 'unknown join_type enum croaks';
};

subtest 'constructor: join_map reference value triggers heap-address guard' => sub {
	# A hashref value in join_map would stringify to "HASH(0x...)" in error messages,
	# leaking a heap address to the caller.  The guard catches this early.
	my $da = MockEdgeDA->new(cols => ['entry', 'name']);
	throws_ok {
		Database::Join->new(
			databases   => [$da],
			join_column => 'entry',
			join_map    => { 0 => { nested => 'oops' } },   # ref value, not string
		)
	} $ERR_HEAP, 'ref-valued join_map triggers early croak';

	# The error message must NOT contain a heap address (e.g. "HASH(0x7f...")
	my $msg = '';
	eval {
		Database::Join->new(
			databases   => [$da],
			join_column => 'entry',
			join_map    => { 0 => [1, 2, 3] },
		);
	};
	$msg = $@ // '';
	unlike $msg, qr/0x[0-9a-f]{4,}/i, 'error message contains no heap address';
};

subtest 'constructor: remove_columns containing join_column croaks' => sub {
	my $da = MockEdgeDA->new(cols => ['entry', 'name']);
	throws_ok {
		Database::Join->new(
			databases      => [$da],
			join_column    => 'entry',
			remove_columns => ['entry'],
		)
	} $ERR_REMOVE_JC, 'remove_columns => [join_col] croaks';
};

subtest 'constructor: DA missing join_column in its columns() croaks' => sub {
	# A DA whose columns() list does not include the join column cannot participate.
	my $da = MockEdgeDA->new(cols => ['name', 'tier']);   # no 'entry'
	throws_ok {
		Database::Join->new(databases => [$da], join_column => 'entry')
	} $ERR_MISSING_JC, 'DA missing join_column croaks error_join_col_missing';
};

subtest 'constructor: databases arg is a scalar (not arrayref) croaks' => sub {
	throws_ok {
		Database::Join->new(databases => 'not-an-arrayref')
	} qr/arrayref|ARRAY|invalid/i, 'databases => scalar croaks validate_strict';
};

subtest 'constructor: single-database array succeeds' => sub {
	# A join over a single database is degenerate but valid.
	my $da = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => $K_ALPHA, name => 'Alice' }],
	);
	my $j;
	lives_ok { $j = Database::Join->new(databases => [$da]) }
		'single-element databases constructs without error';
	is $j->count(), 1, 'single-DB join counts one row';
};

subtest 'constructor: same DA object twice succeeds (no uniqueness requirement)' => sub {
	# Nothing in the API forbids using the same DA object in both slots.
	my $da = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => $K_ALPHA, name => 'Alice' }],
	);
	my $j;
	lives_ok { $j = Database::Join->new(databases => [$da, $da]) }
		'duplicate DA object in databases array is accepted';
};

# ===========================================================================
# Section 2: remove_column hostility
# ===========================================================================

subtest 'remove_column: undef argument is safe no-op' => sub {
	my ($j) = _minimal_join();
	my $ret;
	lives_ok { $ret = $j->remove_column(undef) } 'remove_column(undef) lives';
	is refaddr($ret), refaddr($j), 'returns $self for chaining';
};

subtest 'remove_column: empty-string argument is safe no-op' => sub {
	my ($j) = _minimal_join();
	my $ret;
	lives_ok { $ret = $j->remove_column('') } q{remove_column('') lives};
	is refaddr($ret), refaddr($j), 'returns $self for chaining';
};

subtest 'remove_column: removing join_column croaks' => sub {
	my ($j) = _minimal_join();
	throws_ok { $j->remove_column($JC) } $ERR_REMOVE_JC, 'remove join_column croaks';
};

subtest 'remove_column: nonexistent column is idempotent' => sub {
	my ($j) = _minimal_join();
	my $cols_before = $j->columns();
	lives_ok { $j->remove_column('no_such_column_xyz') }
		'remove nonexistent column lives';
	is_deeply $j->columns(), $cols_before,
		'columns() unchanged after removing nonexistent column';
};

subtest 'remove_column: double removal is idempotent' => sub {
	my ($j) = _minimal_join();
	$j->remove_column('score');
	my $cols_after_first = $j->columns();
	lives_ok { $j->remove_column('score') } 'second removal of same column lives';
	is_deeply $j->columns(), $cols_after_first,
		'columns() unchanged after redundant removal';
};

# ===========================================================================
# Section 3: Query argument hostility
# ===========================================================================

subtest q{selectall_arrayref: positional '0' finds rows with entry='0'} => sub {
	# The false-but-defined string "0" is a valid join key.
	# Positional shorthand: selectall_arrayref('0') should find entry='0' rows.
	my $da = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [
			{ entry => $KEY_ZERO, name => 'Zero' },
			{ entry => 'one',     name => 'One'  },
		],
	);
	my $j = Database::Join->new(databases => [$da], join_column => $JC);
	my $rows = $j->selectall_arrayref($KEY_ZERO);
	is scalar @{$rows}, 1,            "one row returned for entry='$KEY_ZERO'";
	is $rows->[0]{name}, 'Zero',      'correct row name';
};

subtest 'selectall_arrayref: undef positional arg matches nothing' => sub {
	# Positional undef → criteria { entry => undef }.
	# DA rows with entry=undef are skipped by _fetch_indexed (next unless defined $key).
	my ($j) = _minimal_join();
	my $rows;
	lives_ok { $rows = $j->selectall_arrayref(undef) }
		'selectall_arrayref(undef) lives';
	is scalar @{$rows}, 0,
		'undef positional arg matches no rows (join-key undef rows are skipped)';
};

subtest 'selectall_arrayref: no args returns all rows' => sub {
	my ($j) = _minimal_join();
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 2, 'no-arg selectall_arrayref returns all 2 rows';
};

subtest 'selectall_arrayref: criterion on removed column carps and is ignored' => sub {
	my ($j) = _minimal_join();
	$j->remove_column('score');
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $rows = $j->selectall_arrayref(score => { '>' => 0 });
	ok scalar @warnings,                'carp warning emitted for removed-column criterion';
	like $warnings[0], qr/score/,       'warning mentions the removed column name';
	is scalar @{$rows}, 2,             'all rows returned despite bogus criterion';
};

subtest 'count: returns integer regardless of calling context' => sub {
	my ($j) = _minimal_join();
	my $scalar_count = $j->count();
	ok looks_like_number($scalar_count), 'count() in scalar context returns a number';
	is $scalar_count, 2,                  'correct count in scalar context';
	# In list context the return is still a scalar (due to 'return scalar @{$rows}')
	my @list_result = $j->count();
	is scalar @list_result, 1,            'count() in list context returns one element';
	is $list_result[0], 2,                'that element is the correct count';
};

subtest 'fetchrow_hashref: returns undef when nothing matches' => sub {
	my ($j) = _minimal_join();
	my $row = $j->fetchrow_hashref(entry => 'no-such-key-zzz');
	ok !defined($row), 'fetchrow_hashref returns undef for missing key';
};

subtest 'query: always croaks with explanatory message' => sub {
	my ($j) = _minimal_join();
	throws_ok { $j->query() } $ERR_QUERY, 'query() croaks with expected message';
};

subtest 'execute: always croaks with explanatory message' => sub {
	my ($j) = _minimal_join();
	throws_ok { $j->execute() } $ERR_EXECUTE, 'execute() croaks with expected message';
};

# ===========================================================================
# Section 4: Global state protection ($_, $@)
# ===========================================================================

subtest 'selectall_arrayref: does not corrupt caller $_ ' => sub {
	my ($j) = _minimal_join();
	local $_ = 'sentinel-value';
	$j->selectall_arrayref();
	is $_, 'sentinel-value', '$_ unchanged after selectall_arrayref';
};

subtest 'columns: does not corrupt caller $_' => sub {
	my ($j) = _minimal_join();
	local $_ = 'sentinel-value';
	$j->columns();
	is $_, 'sentinel-value', '$_ unchanged after columns()';
};

subtest 'selectall_arrayref: does not set $@ on success' => sub {
	my ($j) = _minimal_join();
	# Clear $@ then verify it stays clear after a successful query.
	eval {};
	my $pre_err = $@;
	$j->selectall_arrayref();
	is $@, $pre_err, '$@ unchanged by a successful selectall_arrayref';
};

subtest 'count: $_ is clean on entry and exit' => sub {
	my ($j) = _minimal_join();
	local $_ = 42;
	$j->count();
	is $_, 42, '$_ = 42 preserved through count()';
};

# ===========================================================================
# Section 5: AUTOLOAD adversarial
#
# Without join_map or filters, AUTOLOAD delegates directly to the owning DA's
# method, which MockEdgeDA does not implement.  A minimal filter on the
# secondary DB forces AUTOLOAD through _joined_query so MockEdgeDA's
# selectall_arrayref handles the retrieval instead.
# ===========================================================================

# Build a join that uses _joined_query for AUTOLOAD (filters active).
# The filter score >= 0 is always true for our fixtures (scores 90 and 70).
sub _autoload_join {
	my $prim = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [
			{ entry => $K_ALPHA, name => 'Alice' },
			{ entry => $K_BETA,  name => 'Bob'   },
		],
	);
	my $sec = MockEdgeDA->new(
		cols => ['entry', 'score'],
		rows => [
			{ entry => $K_ALPHA, score => 90 },
			{ entry => $K_BETA,  score => 70 },
		],
	);
	return Database::Join->new(
		databases   => [$prim, $sec],
		join_column => $JC,
		filters     => { 1 => { score => { '>=' => 0 } } },
	);
}

subtest 'AUTOLOAD: private method name croaks immediately' => sub {
	my $j = _autoload_join();
	throws_ok { $j->_col_db() } $ERR_PRIVATE, '_col_db via AUTOLOAD croaks';
	throws_ok { $j->_dbs()    } $ERR_PRIVATE, '_dbs via AUTOLOAD croaks';
};

subtest 'AUTOLOAD: DESTROY returns without action' => sub {
	my $j = _autoload_join();
	# DESTROY must be trapped before the private-method guard to avoid spurious croaks.
	lives_ok { $j->DESTROY() } 'explicit DESTROY call lives';
};

subtest 'AUTOLOAD: unknown column name croaks' => sub {
	my $j = _autoload_join();
	throws_ok { $j->completely_unknown_column_zzzz() }
		$ERR_UNKNOWN_COL, 'unknown column via AUTOLOAD croaks';
};

subtest 'AUTOLOAD: scalar context returns first matching value' => sub {
	my $j   = _autoload_join();
	my $val = $j->name(entry => $K_ALPHA);
	is $val, 'Alice', 'AUTOLOAD scalar context returns first matching value';
};

subtest 'AUTOLOAD: list context returns all matching values' => sub {
	my $j      = _autoload_join();
	my @names  = $j->name();    # no criteria → all rows
	is scalar @names, 2, 'AUTOLOAD list context returns all values';
	ok((grep { $_ eq 'Alice' } @names), 'Alice present in list');
	ok((grep { $_ eq 'Bob'   } @names), 'Bob present in list');
};

subtest 'AUTOLOAD: no match in scalar context returns undef (not empty list)' => sub {
	my $j   = _autoload_join();
	my $val = $j->name(entry => 'no-match-xyz');
	ok !defined($val), 'AUTOLOAD scalar context returns undef for no-match';
};

subtest 'AUTOLOAD: removed column name croaks (deleted from routing table)' => sub {
	my $j = _autoload_join();
	$j->remove_column('score');
	throws_ok { $j->score() } $ERR_UNKNOWN_COL,
		'AUTOLOAD on removed column croaks because _col_db entry is deleted';
};

subtest 'AUTOLOAD: no match in list context returns empty list (not undef)' => sub {
	my $j    = _autoload_join();
	my @vals = $j->name(entry => 'no-match-xyz');
	is scalar @vals, 0, 'AUTOLOAD list context returns empty list for no-match';
};

# ===========================================================================
# Section 6: Mocked upstream failures
# ===========================================================================

subtest 'upstream: selectall_arrayref returns undef => treated as empty result' => sub {
	# The `$rows //= []` guard in _fetch_indexed must absorb a undef return.
	my $broken = MockEdgeDA->new(
		cols   => ['entry', 'score'],
		return => undef,           # forces selectall_arrayref to return undef
	);
	my $good = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => $K_ALPHA, name => 'Alice' }],
	);
	my $j = Database::Join->new(
		databases   => [$good, $broken],
		join_column => $JC,
		join_type   => 'left',
	);
	my $rows;
	lives_ok { $rows = $j->selectall_arrayref() }
		'query lives when secondary DA returns undef from selectall_arrayref';
	is scalar @{$rows}, 1,
		'primary row present even though secondary returned undef';
	ok !exists($rows->[0]{score}),
		'score column absent (secondary returned no data)';
};

subtest 'upstream: selectall_arrayref returns non-arrayref scalar propagates error' => sub {
	# If a DA returns a plain string instead of an arrayref, dereferencing it will
	# croak with "Not an ARRAY reference".  The error should propagate clearly.
	my $broken = MockEdgeDA->new(
		cols   => ['entry', 'score'],
		return => 'ERROR_STRING',   # non-arrayref
	);
	my $good = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => $K_ALPHA, name => 'Alice' }],
	);
	my $j = Database::Join->new(databases => [$good, $broken], join_column => $JC);
	throws_ok { $j->selectall_arrayref() }
		qr/ARRAY|not an array|not a ref/i,
		'non-arrayref DA return propagates as a clear error';
};

subtest 'upstream: selectall_arrayref croaks => exception propagates to caller' => sub {
	my $broken = MockEdgeDA->new(
		cols      => ['entry', 'score'],
		croak_msg => 'DB connection timed out',
	);
	my $good = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => $K_ALPHA, name => 'Alice' }],
	);
	my $j = Database::Join->new(databases => [$good, $broken], join_column => $JC);
	throws_ok { $j->selectall_arrayref() }
		qr/DB connection timed out/,
		'croak from DA propagates unchanged to the caller';
};

subtest 'upstream: DA columns() returns empty list => join_col_missing croak' => sub {
	my $da = MockEdgeDA->new(cols => []);   # no columns at all, not even entry
	throws_ok {
		Database::Join->new(databases => [$da], join_column => 'entry')
	} $ERR_MISSING_JC, 'empty columns() causes join_col_missing croak';
};

subtest 'upstream: DA schema() returns undef => schema() call does not crash' => sub {
	# A DA that returns undef from schema() must not cause Database::Join::schema()
	# to dereference undef as a hashref.
	my $da = MockEdgeDA->new(cols => ['entry', 'x'], schema => undef);
	my $j = Database::Join->new(databases => [$da], join_column => $JC);
	my $s;
	lives_ok { $s = $j->schema() } 'schema() lives when component DA returns undef schema';
	ok ref($s) eq 'HASH', 'schema() still returns a hashref';
};

subtest 'upstream: DA returns rows without join_column key => silently skipped' => sub {
	# Rows that lack the join key entirely cannot participate in the join.
	my $da = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [
			{ name => 'Ghost' },          # no 'entry' key at all
			{ entry => $K_ALPHA, name => 'Alice' },
		],
	);
	my $j  = Database::Join->new(databases => [$da], join_column => $JC);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 1, 'row missing join_column key is silently dropped';
	is $rows->[0]{name}, 'Alice', 'valid row survives';
};

subtest 'upstream: DA returns rows with undef join_column value => silently skipped' => sub {
	# `next unless defined $key` in _fetch_indexed guards this case.
	my $da = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [
			{ entry => undef,    name => 'Phantom' },   # explicit undef key
			{ entry => $K_BETA,  name => 'Bob'     },
		],
	);
	my $j = Database::Join->new(databases => [$da], join_column => $JC);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 1, 'row with undef join_column value is silently dropped';
	is $rows->[0]{name}, 'Bob', 'valid row survives';
};

subtest 'upstream: updated() propagation — max across all DAs' => sub {
	# updated() calls max() over each DA's updated(); undef values should not
	# crash (List::Util::max ignores undef in recent versions, or warns but proceeds).
	my $da1 = MockEdgeDA->new(cols => ['entry'],         updated => 1_000);
	my $da2 = MockEdgeDA->new(cols => ['entry', 'info'], updated => 2_000);
	my $j = Database::Join->new(databases => [$da1, $da2], join_column => $JC);
	my $ts;
	lives_ok { $ts = $j->updated() } 'updated() lives with two defined timestamps';
	is $ts, 2_000, 'updated() returns max of component timestamps';
};

# ===========================================================================
# Section 7: Security / criteria isolation
# ===========================================================================

subtest 'security: join_map ref value guard prevents heap address in error message' => sub {
	my $da = MockEdgeDA->new(cols => ['entry', 'x']);
	my $msg = '';
	eval {
		Database::Join->new(
			databases   => [$da],
			join_column => 'entry',
			join_map    => { 0 => [] },   # arrayref value, not string
		);
	};
	$msg = $@ // '';
	unlike $msg, qr/0x[0-9a-f]{4,}/i,
		'heap address not present in join_map-ref error message';
	like $msg, qr/must be a string/,
		'error message explains what went wrong';
};

subtest 'security: mutating DA cannot corrupt sibling criteria (broadcast copy)' => sub {
	# MutateCriteriaDA overwrites the '>' operator inside the entry criteria hashref.
	# Database::Join shallow-copies each operator hashref before broadcasting to each
	# database, so a mutation inside DA[0]'s copy must not affect DA[1]'s copy.
	#
	# Setup: mutator (primary, index 0) receives {entry => {'>' => 0}} and mutates it
	# to {'>' => 999_999} then returns all its rows unconditionally.
	# spy_da (secondary, index 1) receives a separate shallow copy.
	# If that copy is independent, spy_da sees '>' => 0 → both entries (1 and 2) pass.
	# If that copy is shared with the primary's, spy_da sees '>' => 999_999 → both fail.
	# Inner join: secondary's result determines whether keys survive.
	# Independent copy → 2 rows; shared (corrupted) → 0 rows.
	Readonly::Scalar my $ENTRY_A => 1;
	Readonly::Scalar my $ENTRY_B => 2;
	my $mutator = MutateCriteriaDA->new(
		cols => ['entry', 'name'],
		rows => [
			{ entry => $ENTRY_A, name => 'Alice' },
			{ entry => $ENTRY_B, name => 'Bob'   },
		],
	);
	my $spy_da = MockEdgeDA->new(
		cols => ['entry', 'score'],
		rows => [
			{ entry => $ENTRY_A, score => 50 },
			{ entry => $ENTRY_B, score => 80 },
		],
	);
	my $j = Database::Join->new(
		databases   => [$mutator, $spy_da],   # mutator = primary (fetched first)
		join_column => $JC,
		join_type   => 'inner',
	);
	my $rows;
	lives_ok {
		$rows = $j->selectall_arrayref(entry => { '>' => 0 });
	} 'query lives despite mutating primary DA';
	is scalar @{$rows}, 2,
		'sibling DA criteria were not corrupted: both rows returned';
};

subtest 'security: unknown column in criteria carps but does not crash' => sub {
	my ($j) = _minimal_join();
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $rows;
	lives_ok { $rows = $j->selectall_arrayref('no_such_col' => 'val') }
		'query with unknown column criterion lives';
	ok scalar @warnings, 'carp warning emitted for unknown column';
	like $warnings[0], qr/no_such_col/, 'warning mentions the unknown column';
};

subtest 'security: SQL-like column name injected in criteria triggers carp, no crash' => sub {
	my ($j) = _minimal_join();
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	lives_ok { $j->selectall_arrayref(q{'; DROP TABLE users; --} => 'x') }
		'SQL injection string as column name does not crash';
	ok scalar @warnings, 'carp warning emitted';
};

subtest 'security: AUTOLOAD private method guard fires before column lookup' => sub {
	my ($j) = _minimal_join();
	# _score looks like a real column with a leading underscore.
	# The private-method guard must fire before _col_db is consulted.
	throws_ok { $j->_score() }
		$ERR_PRIVATE, 'private-method guard prevents reaching column lookup';
};

subtest 'security: very large value in criteria does not cause abnormal behaviour' => sub {
	my ($j) = _minimal_join();
	my $large_val = 'x' x 65_536;    # 64 KiB string
	my $rows;
	lives_ok { $rows = $j->selectall_arrayref(entry => $large_val) }
		'64 KiB criteria value does not crash';
	is scalar @{$rows}, 0, 'no rows match the oversized value (as expected)';
};

# ===========================================================================
# Section 8: Boundary join-key values in data
# ===========================================================================

subtest 'boundary: join key "0" (false string) is indexed and returned' => sub {
	# "next unless defined $key" must not filter out the defined-but-false "0".
	my $da = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => '0', name => 'Zero' }],
	);
	my $j    = Database::Join->new(databases => [$da], join_column => $JC);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 1, 'join key "0" is not silently dropped';
	is $rows->[0]{name}, 'Zero', 'row with join key "0" survives';
};

subtest 'boundary: join key 0 (numeric zero) is indexed and returned' => sub {
	my $da = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => 0, name => 'NumZero' }],
	);
	my $j    = Database::Join->new(databases => [$da], join_column => $JC);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 1, 'numeric join key 0 is not dropped';
};

subtest 'boundary: join key "" (empty string) is indexed under "" key' => sub {
	# An empty-string join key IS defined, so the row survives _fetch_indexed.
	my $da = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [
			{ entry => '',       name => 'EmptyKey' },
			{ entry => $K_ALPHA, name => 'Alpha'    },
		],
	);
	my $j    = Database::Join->new(databases => [$da], join_column => $JC);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 2, 'empty-string join key row is included in results';
};

subtest 'boundary: two rows with distinct whitespace keys are kept separate' => sub {
	# "  k " and "k" are different strings; the join must not normalise whitespace.
	my $da = MockEdgeDA->new(
		cols => ['entry', 'val'],
		rows => [
			{ entry => '  k ', val => 'padded' },
			{ entry => 'k',    val => 'plain'  },
		],
	);
	my $j    = Database::Join->new(databases => [$da], join_column => $JC);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 2, 'whitespace-padded and unpadded keys remain separate';
};

subtest 'boundary: merge preserves all column values including 0 and ""' => sub {
	# Falsy column values (0, "") must not be silently dropped or overwritten.
	my $prim = MockEdgeDA->new(
		cols => ['entry', 'score'],
		rows => [{ entry => $K_ALPHA, score => 0 }],
	);
	my $sec = MockEdgeDA->new(
		cols => ['entry', 'label'],
		rows => [{ entry => $K_ALPHA, label => '' }],
	);
	my $j    = Database::Join->new(databases => [$prim, $sec], join_column => $JC);
	my $row  = $j->fetchrow_hashref(entry => $K_ALPHA);
	ok defined($row->{score}),   'score key exists in merged row';
	is $row->{score}, 0,         'score value 0 preserved';
	ok defined($row->{label}),   'label key exists in merged row';
	is $row->{label}, '',        'label value "" preserved';
};

subtest 'boundary: join keys "0", "0.0", "00" are distinct string keys' => sub {
	my $da = MockEdgeDA->new(
		cols => ['entry', 'tag'],
		rows => [
			{ entry => '0',   tag => 'zero'    },
			{ entry => '0.0', tag => 'floatzero'},
			{ entry => '00',  tag => 'doublezero'},
		],
	);
	my $j    = Database::Join->new(databases => [$da], join_column => $JC);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 3, 'three distinct string keys are all preserved';
};

# ===========================================================================
# Section 9: join_map hostility
# ===========================================================================

subtest 'join_map: value equal to join_column name itself is a no-op alias' => sub {
	# join_map => { 1 => 'entry' } when join_column is also 'entry' means no
	# renaming is needed; the code should still work correctly.
	my $prim = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => $K_ALPHA, name => 'Alice' }],
	);
	my $sec = MockEdgeDA->new(
		cols => ['entry', 'score'],
		rows => [{ entry => $K_ALPHA, score => 99 }],
	);
	my $j = Database::Join->new(
		databases   => [$prim, $sec],
		join_column => 'entry',
		join_map    => { 1 => 'entry' },   # alias equals the canonical name
	);
	my $row = $j->fetchrow_hashref(entry => $K_ALPHA);
	ok defined $row,          'construction and query succeed with identity join_map';
	is $row->{name},  'Alice', 'primary column present';
	is $row->{score}, 99,      'secondary column present';
};

subtest 'join_map: index beyond databases array bound is silently unused' => sub {
	# join_map entries for indices that have no corresponding database are stored
	# internally but never used (no DB at that index is ever iterated).
	my $da = MockEdgeDA->new(
		cols => ['entry', 'x'],
		rows => [{ entry => $K_ALPHA, x => 1 }],
	);
	my $j;
	lives_ok {
		$j = Database::Join->new(
			databases   => [$da],
			join_column => 'entry',
			join_map    => { 99 => 'ref_id' },   # index 99 has no database
		);
	} 'join_map entry for out-of-range index does not crash construction';
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 1, 'query succeeds with orphaned join_map entry';
};

subtest 'join_map: cross-column-name join routes keys correctly' => sub {
	# DB 0 uses 'entry'; DB 1 uses 'ref_id' for the same join concept.
	# join_map => { 1 => 'ref_id' } tells the join to translate.
	my $prim = MockEdgeDA->new(
		cols => ['entry', 'city'],
		rows => [
			{ entry => 'TX', city => 'Houston' },
			{ entry => 'CA', city => 'LA'      },
		],
	);
	my $sec = MockEdgeDA->new(
		id   => 'ref_id',
		cols => ['ref_id', 'population'],
		rows => [
			{ ref_id => 'TX', population => 7_000_000 },
			{ ref_id => 'CA', population => 39_000_000 },
		],
	);
	my $j = Database::Join->new(
		databases   => [$prim, $sec],
		join_column => 'entry',
		join_map    => { 1 => 'ref_id' },
	);
	is $j->count(), 2, 'cross-name join returns all rows';
	my $row_tx = $j->fetchrow_hashref(entry => 'TX');
	is $row_tx->{city},       'Houston',   'primary column correct for TX';
	is $row_tx->{population}, 7_000_000,   'secondary column correct for TX';
	ok !exists($row_tx->{ref_id}),         'local alias ref_id not exposed in result';
};

subtest 'join_map: ref_id not exposed in columns() list' => sub {
	my $prim = MockEdgeDA->new(cols => ['entry', 'city']);
	my $sec  = MockEdgeDA->new(id => 'ref_id', cols => ['ref_id', 'pop']);
	my $j    = Database::Join->new(
		databases   => [$prim, $sec],
		join_column => 'entry',
		join_map    => { 1 => 'ref_id' },
	);
	my $cols = $j->columns();
	ok !(grep { $_ eq 'ref_id' } @{$cols}),
		'join_map alias column not present in columns()';
	ok  (grep { $_ eq 'entry'  } @{$cols}),
		'canonical join_column present in columns()';
};

# ===========================================================================
# Section 10: _merge_criteria corner cases (exercised via filters)
# ===========================================================================

subtest '_merge_criteria: both values empty hashrefs => empty merged result' => sub {
	# Filters merge with query-time criteria.  Two empty hashrefs merge to empty.
	my $da = MockEdgeDA->new(
		cols => ['entry', 'score'],
		rows => [
			{ entry => $K_ALPHA, score => 10 },
			{ entry => $K_BETA,  score => 20 },
		],
	);
	my $j = Database::Join->new(
		databases   => [$da],
		join_column => $JC,
		filters     => { 0 => {} },   # empty filter
	);
	# Empty filter merged with empty query criteria should return all rows.
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 2, 'empty filter does not drop rows';
};

subtest '_merge_criteria: conflicting operator keys — extra (query-time) wins' => sub {
	# Base filter: score > 0.  Query-time: score > 15.
	# After merge the combined hashref has { '>' => 15 } (extra wins for same key).
	my $da = MockEdgeDA->new(
		cols => ['entry', 'score'],
		rows => [
			{ entry => $K_ALPHA, score => 10 },
			{ entry => $K_BETA,  score => 20 },
		],
	);
	my $j = Database::Join->new(
		databases   => [$da],
		join_column => $JC,
		filters     => { 0 => { score => { '>' => 0 } } },   # base: score > 0
	);
	# Query-time: score > 15 → only k002 (score 20) should survive
	my $rows = $j->selectall_arrayref(score => { '>' => 15 });
	is scalar @{$rows}, 1, 'query-time operator wins for same key (score > 15 not > 0)';
	is $rows->[0]{entry}, $K_BETA, 'correct row (score 20) returned';
};

subtest '_merge_criteria: different operators combined (AND semantics)' => sub {
	# Base filter: score > 0.  Query-time: score < 20.
	# Merged: { '>' => 0, '<' => 20 } → only score in (0,20) survives.
	my $da = MockEdgeDA->new(
		cols => ['entry', 'score'],
		rows => [
			{ entry => $K_ALPHA, score => 10  },   # 0 < 10 < 20  → included
			{ entry => $K_BETA,  score => 20  },   # not < 20     → excluded
			{ entry => $K_GAMMA, score => 100 },   # not < 20     → excluded
		],
	);
	my $j = Database::Join->new(
		databases   => [$da],
		join_column => $JC,
		filters     => { 0 => { score => { '>' => 0 } } },
	);
	my $rows = $j->selectall_arrayref(score => { '<' => 20 });
	is scalar @{$rows}, 1, 'AND semantics: only score in (0,20) survives';
	is $rows->[0]{entry}, $K_ALPHA, 'correct row returned';
};

subtest '_merge_criteria: base hashref + scalar extra => scalar (query-time) wins' => sub {
	# If base has an operator hashref for a column, but the query-time value for
	# the same column is a plain scalar, the scalar overwrites the operator hashref.
	my $da = MockEdgeDA->new(
		cols => ['entry', 'score'],
		rows => [
			{ entry => $K_ALPHA, score => 10 },
			{ entry => $K_BETA,  score => 20 },
		],
	);
	# Base filter selects all with score > 5 (both rows).
	# Query-time overrides with exact match score = 10.
	my $j = Database::Join->new(
		databases   => [$da],
		join_column => $JC,
		filters     => { 0 => { score => { '>' => 5 } } },
	);
	my $rows = $j->selectall_arrayref(score => 10);
	is scalar @{$rows}, 1, 'scalar query-time value overwrites base operator hashref';
	is $rows->[0]{entry}, $K_ALPHA, 'correct row returned';
};

# ===========================================================================
# Section 11: Outer-join / key-set edge cases
# ===========================================================================

subtest 'outer join: key only in secondary appears in result' => sub {
	# Under outer join, keys present only in the secondary database must appear.
	my $prim = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => $K_ALPHA, name => 'Alice' }],
	);
	my $sec = MockEdgeDA->new(
		cols => ['entry', 'score'],
		rows => [
			{ entry => $K_ALPHA, score => 90 },
			{ entry => $K_GAMMA, score => 55 },   # k003 not in primary
		],
	);
	my $j = Database::Join->new(
		databases   => [$prim, $sec],
		join_column => $JC,
		join_type   => 'outer',
	);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 2, 'outer join returns 2 rows (1 primary-only + 1 shared)';
	my ($gamma_row) = grep { $_->{entry} eq $K_GAMMA } @{$rows};
	ok defined $gamma_row, 'secondary-only key k003 appears in outer-join result';
	is $gamma_row->{score}, 55, 'secondary column value correct';
	ok !exists($gamma_row->{name}),
		'primary column absent (no primary row for that key)';
};

subtest 'inner join: secondary with no matching rows produces empty result' => sub {
	my $prim = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => $K_ALPHA, name => 'Alice' }],
	);
	my $sec = MockEdgeDA->new(
		cols => ['entry', 'score'],
		rows => [],   # no rows at all
	);
	my $j = Database::Join->new(
		databases   => [$prim, $sec],
		join_column => $JC,
		join_type   => 'inner',
	);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 0, 'inner join with empty secondary returns 0 rows';
};

subtest 'left join: key only in secondary is absent from result' => sub {
	my $prim = MockEdgeDA->new(
		cols => ['entry', 'name'],
		rows => [{ entry => $K_ALPHA, name => 'Alice' }],
	);
	my $sec = MockEdgeDA->new(
		cols => ['entry', 'score'],
		rows => [
			{ entry => $K_ALPHA, score => 90 },
			{ entry => $K_GAMMA, score => 55 },   # k003 not in primary
		],
	);
	my $j = Database::Join->new(
		databases   => [$prim, $sec],
		join_column => $JC,
		join_type   => 'left',
	);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 1, 'left join returns only primary keys';
	ok !(grep { $_->{entry} eq $K_GAMMA } @{$rows}),
		'secondary-only key k003 absent from left-join result';
};

subtest 'outer join: three DBs all different key sets returns union' => sub {
	my $da1 = MockEdgeDA->new(
		cols => ['entry', 'a'],
		rows => [{ entry => 'x1', a => 1 }],
	);
	my $da2 = MockEdgeDA->new(
		cols => ['entry', 'b'],
		rows => [{ entry => 'x2', b => 2 }],
	);
	my $da3 = MockEdgeDA->new(
		cols => ['entry', 'c'],
		rows => [{ entry => 'x3', c => 3 }],
	);
	my $j = Database::Join->new(
		databases   => [$da1, $da2, $da3],
		join_column => $JC,
		join_type   => 'outer',
	);
	my $rows = $j->selectall_arrayref();
	is scalar @{$rows}, 3, 'outer join over 3 DBs with disjoint keys returns 3 rows';
	my %by_key = map { $_->{entry} => $_ } @{$rows};
	is $by_key{x1}{a}, 1, 'x1 row has column a';
	is $by_key{x2}{b}, 2, 'x2 row has column b';
	is $by_key{x3}{c}, 3, 'x3 row has column c';
};
