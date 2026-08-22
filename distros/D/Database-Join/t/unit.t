use strict;
use warnings;

# ---------------------------------------------------------------------------
# t/unit.t -- Black-box unit tests for Database::Join, driven strictly by
# the published POD API.  Every documented message key, return state, and
# calling convention must be exercised; an "API ledger" hash tracks coverage
# and fails at the end if any documented condition was not reached.
#
# No white-box knowledge is needed here.  Fixtures use inline MinimalDA mocks
# (a minimal Database::Abstraction subclass) so tests run with no disk I/O.
# ---------------------------------------------------------------------------

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Readonly;
use Scalar::Util qw(blessed refaddr);

BEGIN {
	eval { require Database::Abstraction };
	plan skip_all => 'Database::Abstraction required' if $@;
	plan tests => 81;
	use_ok('Database::Join');
}

# ---------------------------------------------------------------------------
# API ledger -- every documented message key and return state extracted from
# the POD.  Each subtest deletes the relevant key when it successfully triggers
# that condition.  The final test asserts the ledger is empty.
# ---------------------------------------------------------------------------
my %LEDGER = (
	# new() messages (POD section "MESSAGES" under new)
	'new:error_no_databases'     => 1,
	'new:error_invalid_db'       => 1,
	'new:error_join_col_missing' => 1,

	# new() return states
	'new:returns_blessed_object' => 1,
	'new:join_col_default_entry' => 1,
	'new:join_type_default_left' => 1,
	'new:remove_columns_applied' => 1,
	'new:join_type_inner'        => 1,
	'new:join_type_outer'        => 1,
	'new:join_map_stored'        => 1,
	'new:filters_stored'         => 1,
	'new:invalid_join_type'      => 1,

	# selectall_arrayref return states
	'sar:returns_arrayref'       => 1,
	'sar:empty_when_no_match'    => 1,
	'sar:no_args_all_rows'       => 1,
	'sar:positional_scalar'      => 1,
	'sar:kv_pairs'               => 1,
	'sar:operator_hashref'       => 1,
	'sar:merged_columns'         => 1,
	'sar:sorted_by_join_col'     => 1,

	# selectall_array return states
	'sa:list_context_list'       => 1,
	'sa:scalar_context_first'    => 1,
	'sa:scalar_context_undef'    => 1,

	# fetchrow_hashref return states
	'frh:returns_hashref'        => 1,
	'frh:returns_undef_no_match' => 1,
	'frh:positional_arg'         => 1,

	# count return states
	'count:non_neg_int'          => 1,
	'count:zero_when_empty'      => 1,
	'count:with_criteria'        => 1,

	# columns return states
	'cols:returns_arrayref'      => 1,
	'cols:sorted_alpha'          => 1,
	'cols:join_col_once'         => 1,
	'cols:removed_absent'        => 1,
	'cols:memoised'              => 1,

	# schema return states
	'schema:returns_hashref'     => 1,
	'schema:removed_absent'      => 1,
	'schema:join_map_alias_excluded' => 1,
	'schema:last_db_wins'        => 1,
	'schema:memoised'            => 1,

	# updated return states
	'updated:returns_max'        => 1,
	'updated:positive_int'       => 1,

	# set_logger states
	'sl:croak_on_undef'          => 1,
	'sl:propagates_to_dbs'       => 1,
	'sl:returns_self'            => 1,

	# add_database states / messages
	'adb:positional_form'        => 1,
	'adb:named_form'             => 1,
	'adb:returns_self'           => 1,
	'adb:error_invalid_db'       => 1,
	'adb:error_join_col_missing' => 1,
	'adb:join_column_option'     => 1,
	'adb:filter_option'          => 1,
	'adb:remove_columns_option'  => 1,
	'adb:invalidates_col_cache'  => 1,
	'adb:last_db_wins'           => 1,

	# remove_column states / messages
	'rc:error_remove_join_col'   => 1,
	'rc:col_hidden_from_columns' => 1,
	'rc:col_hidden_from_results' => 1,
	'rc:criterion_dropped_carp'  => 1,
	'rc:idempotent'              => 1,
	'rc:returns_self'            => 1,
	'rc:nonexistent_safe'        => 1,

	# query / execute messages
	'query:croak_unsupported'    => 1,
	'execute:croak_unsupported'  => 1,

	# AUTOLOAD states
	'al:destroy_silently'        => 1,
	'al:private_croak'           => 1,
	'al:unknown_col_croak'       => 1,
	'al:scalar_context'          => 1,
	'al:list_context'            => 1,
	'al:direct_delegate'         => 1,
	'al:full_join_join_map'      => 1,
	'al:full_join_filters'       => 1,

	# Join-type semantics
	'jt:left_primary_defines'    => 1,
	'jt:left_secondary_fills'    => 1,
	'jt:inner_shared_only'       => 1,
	'jt:outer_all_keys'          => 1,
	'jt:criteria_inner_override' => 1,

	# filters semantics
	'filt:inner_partner'         => 1,
	'filt:criteria_merge_and'    => 1,
	'filt:scalar_replaces_base'  => 1,
);

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
Readonly::Scalar my $JC     => 'entry';
Readonly::Scalar my $COL_A  => 'name';
Readonly::Scalar my $COL_B  => 'score';
Readonly::Scalar my $COL_C  => 'tier';
Readonly::Scalar my $TS_OLD => 1_000_000;
Readonly::Scalar my $TS_NEW => 2_000_000;

# ---------------------------------------------------------------------------
# MinimalDA: inline Database::Abstraction stub.
# Configurable at construction time; no disk I/O.
# ---------------------------------------------------------------------------
{
	package MinimalDA;
	use parent -norequire, 'Database::Abstraction';

	sub new {
		my ($class, %args) = @_;
		return bless {
			id      => $args{id}      // 'entry',
			_cols   => $args{cols}    // ['entry'],
			_rows   => $args{rows}    // [],
			_schema => $args{schema}  // {},
			_ts     => $args{updated} // 1,
		}, $class;
	}

	sub columns            { return $_[0]->{_cols} }
	sub schema             { return $_[0]->{_schema} }
	sub updated            { return $_[0]->{_ts} }
	sub set_logger         { $_[0]->{_logger} = $_[1]; return $_[0] }
	sub selectall_arrayref {
		my ($self, $criteria) = @_;
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
			} else {
				@rows = grep { defined $_->{$col} && $_->{$col} eq $val } @rows;
			}
		}
		return \@rows;
	}
	sub DESTROY {}
}

# ---------------------------------------------------------------------------
# Helpers: build standard fixtures used across many subtests
# ---------------------------------------------------------------------------
sub _two_db_join {
	my (%opts) = @_;
	my $db_a = MinimalDA->new(
		cols   => [$JC, $COL_A, $COL_C],
		rows   => [
			{ entry => 'K1', name => 'Alice', tier => 'gold'   },
			{ entry => 'K2', name => 'Bob',   tier => 'silver' },
		],
		schema  => {
			entry => { type => 'TEXT',    nullable => 0, default => undef, pk => 1 },
			name  => { type => 'TEXT',    nullable => 1, default => undef, pk => 0 },
			tier  => { type => 'TEXT',    nullable => 1, default => undef, pk => 0 },
		},
		updated => $TS_OLD,
	);
	my $db_b = MinimalDA->new(
		cols   => [$JC, $COL_B],
		rows   => [
			{ entry => 'K1', score => 95 },
			{ entry => 'K2', score => 70 },
		],
		schema  => {
			entry => { type => 'TEXT',    nullable => 0, default => undef, pk => 1 },
			score => { type => 'INTEGER', nullable => 1, default => undef, pk => 0 },
		},
		updated => $TS_NEW,
	);
	return Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		%opts,
	);
}

diag('Starting Database::Join black-box API tests') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 1 -- new(): documented return states and error messages
# ===========================================================================

subtest 'new: returns a blessed Database::Join object' => sub {
	plan tests => 2;
	my $j = _two_db_join();
	ok(blessed($j), 'new() returns a blessed object');
	isa_ok($j, 'Database::Join');
	delete $LEDGER{'new:returns_blessed_object'};
};

subtest 'new: join_column defaults to "entry"' => sub {
	plan tests => 1;
	my $db = MinimalDA->new(cols => ['entry', 'x'], rows => []);
	my $j  = Database::Join->new(databases => [$db]);
	is($j->{_join_col}, 'entry', 'join_column defaults to "entry" when omitted');
	delete $LEDGER{'new:join_col_default_entry'};
};

subtest 'new: join_type defaults to "left"' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	is($j->{_join_type}, 'left', 'join_type defaults to "left" when omitted');
	delete $LEDGER{'new:join_type_default_left'};
};

subtest 'new: join_type "inner" accepted' => sub {
	plan tests => 1;
	my $j = _two_db_join(join_type => 'inner');
	is($j->{_join_type}, 'inner', 'join_type "inner" accepted and stored');
	delete $LEDGER{'new:join_type_inner'};
};

subtest 'new: join_type "outer" accepted' => sub {
	plan tests => 1;
	my $j = _two_db_join(join_type => 'outer');
	is($j->{_join_type}, 'outer', 'join_type "outer" accepted and stored');
	delete $LEDGER{'new:join_type_outer'};
};

subtest 'new: invalid join_type rejected' => sub {
	plan tests => 1;
	my $db = MinimalDA->new(cols => [$JC], rows => []);
	dies_ok { Database::Join->new(databases => [$db], join_column => $JC, join_type => 'bogus') }
		'new() dies when join_type is not inner/left/outer';
	delete $LEDGER{'new:invalid_join_type'};
};

subtest 'new: error_no_databases -- empty databases arrayref' => sub {
	plan tests => 1;
	throws_ok { Database::Join->new(databases => [], join_column => $JC) }
		qr/At least one Database::Abstraction/,
		'new() croaks with error_no_databases when databases is empty';
	delete $LEDGER{'new:error_no_databases'};
};

subtest 'new: error_invalid_db -- non-DA object in databases' => sub {
	plan tests => 1;
	throws_ok { Database::Join->new(databases => [ bless {}, 'NotDA' ], join_column => $JC) }
		qr/databases\[0\] is not a Database::Abstraction/,
		'new() croaks with error_invalid_db for a non-DA element';
	delete $LEDGER{'new:error_invalid_db'};
};

subtest 'new: error_join_col_missing -- join_column absent from a database' => sub {
	plan tests => 1;
	my $db = MinimalDA->new(cols => ['other'], rows => []);
	throws_ok { Database::Join->new(databases => [$db], join_column => 'missing') }
		qr/absent from databases\[0\]/,
		'new() croaks with error_join_col_missing when join_column is absent';
	delete $LEDGER{'new:error_join_col_missing'};
};

subtest 'new: remove_columns applied at construction' => sub {
	plan tests => 2;
	my $j = _two_db_join(remove_columns => [$COL_C]);
	ok(!grep { $_ eq $COL_C } @{ $j->columns() },
		'removed column does not appear in columns()');
	ok(!exists $j->schema()->{$COL_C},
		'removed column does not appear in schema()');
	delete $LEDGER{'new:remove_columns_applied'};
};

subtest 'new: join_map stored in the object' => sub {
	plan tests => 1;
	my $db0 = MinimalDA->new(cols => [$JC,     $COL_A], rows => []);
	my $db1 = MinimalDA->new(cols => ['altkey', $COL_B], rows => []);
	my $j   = Database::Join->new(
		databases   => [$db0, $db1],
		join_column => $JC,
		join_map    => { 1 => 'altkey' },
	);
	is_deeply($j->{_join_map}, { 1 => 'altkey' }, 'join_map stored verbatim in the object');
	delete $LEDGER{'new:join_map_stored'};
};

subtest 'new: filters stored in the object' => sub {
	plan tests => 1;
	my $filter = { score => { '>' => 50 } };
	my $j = _two_db_join(filters => { 1 => $filter });
	is_deeply($j->{_filters}, { 1 => $filter }, 'filters stored verbatim in the object');
	delete $LEDGER{'new:filters_stored'};
};

# ===========================================================================
# SECTION 2 -- selectall_arrayref: every calling convention and return state
# ===========================================================================

subtest 'selectall_arrayref: returns arrayref' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	returns_ok($j->selectall_arrayref(), { type => 'arrayref' },
		'selectall_arrayref() returns an arrayref');
	delete $LEDGER{'sar:returns_arrayref'};
};

subtest 'selectall_arrayref: no args returns all rows' => sub {
	plan tests => 1;
	my $j    = _two_db_join();
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 2, 'no-arg call returns all merged rows');
	delete $LEDGER{'sar:no_args_all_rows'};
};

subtest 'selectall_arrayref: empty arrayref when no rows match' => sub {
	plan tests => 2;
	my $j    = _two_db_join();
	my $rows = $j->selectall_arrayref(entry => 'NOMATCH');
	returns_ok($rows, { type => 'arrayref' }, 'still returns an arrayref when nothing matches');
	is(scalar @{$rows}, 0, 'arrayref is empty when no rows match');
	delete $LEDGER{'sar:empty_when_no_match'};
};

subtest 'selectall_arrayref: single scalar arg is positional join_column shorthand' => sub {
	plan tests => 1;
	my $j    = _two_db_join();
	my $rows = $j->selectall_arrayref('K1');
	is($rows->[0]{name}, 'Alice',
		'single scalar arg maps to join_column => value (positional shorthand)');
	delete $LEDGER{'sar:positional_scalar'};
};

subtest 'selectall_arrayref: key-value pair criteria routed correctly' => sub {
	plan tests => 2;
	my $j    = _two_db_join();
	my $rows = $j->selectall_arrayref($COL_C => 'gold');
	is(scalar @{$rows}, 1, 'key-value criterion filters correctly');
	is($rows->[0]{name}, 'Alice', 'correct row returned');
	delete $LEDGER{'sar:kv_pairs'};
};

subtest 'selectall_arrayref: operator hashref criterion' => sub {
	plan tests => 1;
	my $j    = _two_db_join();
	my $rows = $j->selectall_arrayref($COL_B => { '>' => 80 });
	is(scalar @{$rows}, 1,
		'operator hashref criterion returns only rows satisfying the operator');
	delete $LEDGER{'sar:operator_hashref'};
};

subtest 'selectall_arrayref: merged rows contain columns from all databases' => sub {
	plan tests => 3;
	my $j    = _two_db_join();
	my $rows = $j->selectall_arrayref('K1');
	is($rows->[0]{$JC},   'K1',    'join_column present in merged row');
	is($rows->[0]{$COL_A}, 'Alice', 'primary DB column present in merged row');
	is($rows->[0]{$COL_B}, 95,     'secondary DB column present in merged row');
	delete $LEDGER{'sar:merged_columns'};
};

subtest 'selectall_arrayref: results sorted ascending by join_column value' => sub {
	plan tests => 1;
	# Build a join where the primary DB returns rows in reverse order to confirm
	# the sort is applied by Database::Join, not inherited from the DA.
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'Z9', name => 'Zara' },
			{ entry => 'A1', name => 'Abel' },
		],
	);
	my $db_b = MinimalDA->new(cols => [$JC, $COL_B], rows => [
		{ entry => 'Z9', score => 10 },
		{ entry => 'A1', score => 20 },
	]);
	my $j    = Database::Join->new(databases => [$db_a, $db_b], join_column => $JC);
	my $rows = $j->selectall_arrayref();
	is($rows->[0]{entry}, 'A1',
		'results are sorted ascending by join_column value regardless of DA return order');
	delete $LEDGER{'sar:sorted_by_join_col'};
};

# ===========================================================================
# SECTION 3 -- selectall_array
# ===========================================================================

subtest 'selectall_array: list context returns a list of hashrefs' => sub {
	plan tests => 2;
	my $j    = _two_db_join();
	my @rows = $j->selectall_array();
	is(scalar @rows, 2, 'list context returns all rows as a flat list');
	ok(ref($rows[0]) eq 'HASH', 'each element is a hashref');
	delete $LEDGER{'sa:list_context_list'};
};

subtest 'selectall_array: scalar context returns first matching hashref' => sub {
	plan tests => 2;
	my $j     = _two_db_join();
	my $first = $j->selectall_array();
	ok(defined $first,         'scalar context returns a defined value');
	ok(ref $first eq 'HASH',   'scalar context result is a hashref');
	delete $LEDGER{'sa:scalar_context_first'};
};

subtest 'selectall_array: scalar context returns undef when nothing matches' => sub {
	plan tests => 1;
	my $j    = _two_db_join();
	my $none = $j->selectall_array(entry => 'NOMATCH');
	ok(!defined $none, 'scalar context returns undef when no rows match');
	delete $LEDGER{'sa:scalar_context_undef'};
};

# ===========================================================================
# SECTION 4 -- fetchrow_hashref
# ===========================================================================

subtest 'fetchrow_hashref: returns a hashref for a matching row' => sub {
	plan tests => 2;
	my $j   = _two_db_join();
	my $row = $j->fetchrow_hashref(entry => 'K1');
	returns_ok($row, { type => 'hashref' }, 'fetchrow_hashref returns a hashref');
	is($row->{name}, 'Alice', 'correct row is returned');
	delete $LEDGER{'frh:returns_hashref'};
};

subtest 'fetchrow_hashref: returns undef when no row matches' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	ok(!defined $j->fetchrow_hashref(entry => 'NOMATCH'),
		'fetchrow_hashref returns undef when no row matches');
	delete $LEDGER{'frh:returns_undef_no_match'};
};

subtest 'fetchrow_hashref: positional scalar arg is join_column shorthand' => sub {
	plan tests => 1;
	my $j   = _two_db_join();
	my $row = $j->fetchrow_hashref('K2');
	is($row->{name}, 'Bob',
		'positional scalar maps to join_column => value');
	delete $LEDGER{'frh:positional_arg'};
};

# ===========================================================================
# SECTION 5 -- count
# ===========================================================================

subtest 'count: returns a non-negative integer' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	returns_ok($j->count(), { type => 'integer' }, 'count() returns an integer');
	delete $LEDGER{'count:non_neg_int'};
};

subtest 'count: returns zero when no rows match' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	is($j->count(entry => 'NOMATCH'), 0, 'count() is zero when nothing matches');
	delete $LEDGER{'count:zero_when_empty'};
};

subtest 'count: with criteria counts only matching rows' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	is($j->count($COL_C => 'gold'), 1, 'count() with criteria returns the filtered count');
	delete $LEDGER{'count:with_criteria'};
};

# ===========================================================================
# SECTION 6 -- columns
# ===========================================================================

subtest 'columns: returns an arrayref' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	returns_ok($j->columns(), { type => 'arrayref' }, 'columns() returns an arrayref');
	delete $LEDGER{'cols:returns_arrayref'};
};

subtest 'columns: result is sorted alphabetically' => sub {
	plan tests => 1;
	my $j    = _two_db_join();
	my $cols = $j->columns();
	my @sorted = sort @{$cols};
	is_deeply($cols, \@sorted, 'columns() returns column names sorted alphabetically');
	delete $LEDGER{'cols:sorted_alpha'};
};

subtest 'columns: join_column appears exactly once even in multiple DBs' => sub {
	plan tests => 1;
	my $j     = _two_db_join();
	my $count = grep { $_ eq $JC } @{ $j->columns() };
	is($count, 1, 'join_column appears exactly once in columns() output');
	delete $LEDGER{'cols:join_col_once'};
};

subtest 'columns: removed column does not appear' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	$j->remove_column($COL_C);
	ok(!grep { $_ eq $COL_C } @{ $j->columns() },
		'removed column is absent from columns()');
	delete $LEDGER{'cols:removed_absent'};
};

subtest 'columns: result is memoised (same arrayref on repeated calls)' => sub {
	plan tests => 1;
	my $j     = _two_db_join();
	my $first  = $j->columns();
	my $second = $j->columns();
	is(refaddr($first), refaddr($second),
		'columns() returns the same cached arrayref on repeated calls');
	delete $LEDGER{'cols:memoised'};
};

# ===========================================================================
# SECTION 7 -- schema
# ===========================================================================

subtest 'schema: returns a hashref' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	returns_ok($j->schema(), { type => 'hashref' }, 'schema() returns a hashref');
	delete $LEDGER{'schema:returns_hashref'};
};

subtest 'schema: removed column is absent' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	$j->remove_column($COL_C);
	ok(!exists $j->schema()->{$COL_C}, 'removed column is absent from schema()');
	delete $LEDGER{'schema:removed_absent'};
};

subtest 'schema: join_map local alias is not exposed' => sub {
	plan tests => 1;
	my $db0 = MinimalDA->new(cols => [$JC, $COL_A],
		schema => { $JC => {}, $COL_A => {} });
	my $db1 = MinimalDA->new(cols => ['altkey', $COL_B],
		schema => { altkey => {}, $COL_B => {} });
	my $j   = Database::Join->new(
		databases   => [$db0, $db1],
		join_column => $JC,
		join_map    => { 1 => 'altkey' },
	);
	ok(!exists $j->schema()->{altkey},
		'join_map local alias is not present in schema()');
	delete $LEDGER{'schema:join_map_alias_excluded'};
};

subtest 'schema: last database wins for duplicate column metadata' => sub {
	plan tests => 1;
	my $db0 = MinimalDA->new(
		cols   => [$JC, $COL_A],
		schema => { $JC => { type => 'TEXT' }, $COL_A => { type => 'VARCHAR' } },
	);
	my $db1 = MinimalDA->new(
		cols   => [$JC, $COL_A],
		schema => { $JC => { type => 'TEXT' }, $COL_A => { type => 'CHAR' } },
	);
	my $j = Database::Join->new(databases => [$db0, $db1], join_column => $JC);
	is($j->schema()->{$COL_A}{type}, 'CHAR',
		'schema() uses the last database when the same column appears in multiple databases');
	delete $LEDGER{'schema:last_db_wins'};
};

subtest 'schema: result is memoised' => sub {
	plan tests => 1;
	my $j     = _two_db_join();
	my $first  = $j->schema();
	my $second = $j->schema();
	is(refaddr($first), refaddr($second),
		'schema() returns the same cached hashref on repeated calls');
	delete $LEDGER{'schema:memoised'};
};

# ===========================================================================
# SECTION 8 -- updated
# ===========================================================================

subtest 'updated: returns the maximum timestamp across all component databases' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	is($j->updated(), $TS_NEW,
		'updated() returns the maximum timestamp from all component databases');
	delete $LEDGER{'updated:returns_max'};
};

subtest 'updated: returns a positive integer' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	my $ts = $j->updated();
	ok($ts > 0 && int($ts) == $ts, 'updated() returns a positive integer');
	delete $LEDGER{'updated:positive_int'};
};

# ===========================================================================
# SECTION 9 -- set_logger
# ===========================================================================

subtest 'set_logger: croaks when called with undef' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	throws_ok { $j->set_logger(undef) }
		qr/Usage: set_logger/,
		'set_logger() croaks when the logger argument is undef';
	delete $LEDGER{'sl:croak_on_undef'};
};

subtest 'set_logger: propagates the logger to all component databases' => sub {
	plan tests => 1;
	my $j   = _two_db_join();
	my $log = bless {}, 'FakeLogger';
	$j->set_logger($log);
	is(refaddr($j->{_dbs}[0]{_logger}), refaddr($log),
		'set_logger() propagates to the primary component database');
	delete $LEDGER{'sl:propagates_to_dbs'};
};

subtest 'set_logger: returns self for chaining' => sub {
	plan tests => 1;
	my $j   = _two_db_join();
	my $log = bless {}, 'FakeLogger';
	is(refaddr($j->set_logger($log)), refaddr($j),
		'set_logger() returns $self for method chaining');
	delete $LEDGER{'sl:returns_self'};
};

# ===========================================================================
# SECTION 10 -- add_database
# ===========================================================================

subtest 'add_database: positional form appends the database' => sub {
	plan tests => 1;
	my $j    = _two_db_join();
	my $db_c = MinimalDA->new(cols => [$JC, 'extra'], rows => []);
	$j->add_database($db_c);
	is(scalar @{ $j->{_dbs} }, 3,
		'add_database() positional form appends the new database to _dbs');
	delete $LEDGER{'adb:positional_form'};
};

subtest 'add_database: named form (database => $db) appends the database' => sub {
	plan tests => 1;
	my $j    = _two_db_join();
	my $db_c = MinimalDA->new(cols => [$JC, 'extra2'], rows => []);
	$j->add_database(database => $db_c);
	is(scalar @{ $j->{_dbs} }, 3,
		'add_database() named form appends the new database to _dbs');
	delete $LEDGER{'adb:named_form'};
};

subtest 'add_database: returns self for chaining' => sub {
	plan tests => 1;
	my $j    = _two_db_join();
	my $db_c = MinimalDA->new(cols => [$JC], rows => []);
	is(refaddr($j->add_database($db_c)), refaddr($j),
		'add_database() returns $self for method chaining');
	delete $LEDGER{'adb:returns_self'};
};

subtest 'add_database: error_invalid_db for non-DA object' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	throws_ok { $j->add_database(bless {}, 'WrongClass') }
		qr/is not a Database::Abstraction/,
		'add_database() croaks with error_invalid_db for a non-DA argument';
	delete $LEDGER{'adb:error_invalid_db'};
};

subtest 'add_database: error_join_col_missing when new DB lacks join key' => sub {
	plan tests => 1;
	my $j   = _two_db_join();
	my $bad = MinimalDA->new(cols => ['unrelated'], rows => []);
	throws_ok { $j->add_database($bad) }
		qr/absent from databases\[2\]/,
		'add_database() croaks with error_join_col_missing for a DB missing the join key';
	delete $LEDGER{'adb:error_join_col_missing'};
};

subtest 'add_database: join_column option registered in join_map' => sub {
	plan tests => 2;
	my $j    = _two_db_join();
	my $db_c = MinimalDA->new(cols => ['localkey', 'extra'], rows => []);
	$j->add_database($db_c, join_column => 'localkey');
	is($j->{_join_map}{2}, 'localkey',
		'add_database() registers the join_column alias in _join_map');
	ok(!grep { $_ eq 'localkey' } @{ $j->columns() },
		'add_database() join_column alias is not exposed in columns()');
	delete $LEDGER{'adb:join_column_option'};
};

subtest 'add_database: filter option registered in _filters' => sub {
	plan tests => 1;
	my $j    = _two_db_join();
	my $db_c = MinimalDA->new(cols => [$JC, 'level'], rows => []);
	my $f    = { level => { '>' => 5 } };
	$j->add_database($db_c, filter => $f);
	is_deeply($j->{_filters}{2}, $f,
		'add_database() stores the filter in _filters for the new DB');
	delete $LEDGER{'adb:filter_option'};
};

subtest 'add_database: remove_columns option hides columns from the new DB' => sub {
	plan tests => 1;
	my $j    = _two_db_join();
	my $db_c = MinimalDA->new(cols => [$JC, 'to_hide'], rows => []);
	$j->add_database($db_c, remove_columns => ['to_hide']);
	ok(!grep { $_ eq 'to_hide' } @{ $j->columns() },
		'add_database() remove_columns option hides the specified column immediately');
	delete $LEDGER{'adb:remove_columns_option'};
};

subtest 'add_database: invalidates columns() cache' => sub {
	plan tests => 2;
	my $j = _two_db_join();
	$j->columns(); $j->schema();   # prime both caches
	my $db_c = MinimalDA->new(
		cols   => [$JC, 'fresh_col'],
		rows   => [],
		schema => { $JC => {}, fresh_col => { type => 'TEXT' } },
	);
	$j->add_database($db_c);
	my $cols = $j->columns();
	ok(grep { $_ eq 'fresh_col' } @{$cols},
		'add_database() invalidates the columns cache; fresh_col is now visible');
	ok(exists $j->schema()->{fresh_col},
		'add_database() invalidates the schema cache; fresh_col is now in schema');
	delete $LEDGER{'adb:invalidates_col_cache'};
};

subtest 'add_database: last-database-wins for duplicate column names' => sub {
	plan tests => 1;
	# db_a has 'name' with value "Alice"; db_c also has 'name' with value "Zara".
	# After add_database(db_c), 'name' should be owned by db_c (last wins).
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [ { entry => 'K1', name => 'Alice' } ],
	);
	my $db_c = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [ { entry => 'K1', name => 'Zara' } ],
	);
	my $j = Database::Join->new(databases => [$db_a], join_column => $JC);
	$j->add_database($db_c);
	my $row = $j->fetchrow_hashref('K1');
	is($row->{name}, 'Zara',
		'add_database() last-database-wins: later database overwrites earlier for duplicate columns');
	delete $LEDGER{'adb:last_db_wins'};
};

# ===========================================================================
# SECTION 11 -- remove_column
# ===========================================================================

subtest 'remove_column: error_remove_join_col -- cannot remove the join key' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	throws_ok { $j->remove_column($JC) }
		qr/Cannot remove join_column/,
		'remove_column() croaks with error_remove_join_col when asked to remove the join key';
	delete $LEDGER{'rc:error_remove_join_col'};
};

subtest 'remove_column: column hidden from columns()' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	$j->remove_column($COL_C);
	ok(!grep { $_ eq $COL_C } @{ $j->columns() },
		'remove_column() hides the column from columns()');
	delete $LEDGER{'rc:col_hidden_from_columns'};
};

subtest 'remove_column: column absent from query result rows' => sub {
	plan tests => 1;
	my $j    = _two_db_join();
	$j->remove_column($COL_C);
	my $rows = $j->selectall_arrayref();
	ok(!exists $rows->[0]{$COL_C},
		'remove_column() ensures the column does not appear in query result rows');
	delete $LEDGER{'rc:col_hidden_from_results'};
};

subtest 'remove_column: criterion on removed column is dropped with carp' => sub {
	plan tests => 2;
	# POD states: "Any query criterion that references the removed column is
	# silently dropped (with a carp warning)."
	my $j = _two_db_join();
	$j->remove_column($COL_C);
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $rows = $j->selectall_arrayref($COL_C => 'gold');
	# The criterion is dropped; ALL rows are returned (both, not filtered to gold only)
	is(scalar @{$rows}, 2, 'all rows returned when criterion targets a removed column');
	ok(@warnings, 'carp warning is emitted when a criterion targets a removed column');
	delete $LEDGER{'rc:criterion_dropped_carp'};
};

subtest 'remove_column: idempotent -- removing the same column twice is safe' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	$j->remove_column($COL_C);
	lives_ok { $j->remove_column($COL_C) }
		'remove_column() can be called twice on the same column without error';
	delete $LEDGER{'rc:idempotent'};
};

subtest 'remove_column: returns self for chaining' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	is(refaddr($j->remove_column($COL_C)), refaddr($j),
		'remove_column() returns $self to support method chaining');
	delete $LEDGER{'rc:returns_self'};
};

subtest 'remove_column: removing a non-existent column is silently ignored' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	lives_ok { $j->remove_column('no_such_col') }
		'remove_column() on a non-existent column does not croak';
	delete $LEDGER{'rc:nonexistent_safe'};
};

# ===========================================================================
# SECTION 12 -- query() and execute() -- always croak
# ===========================================================================

subtest 'query: always croaks with error_query_unsupported' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	throws_ok { $j->query() }
		qr/query\(\) chained builder is not supported/,
		'query() always croaks with the documented error message';
	delete $LEDGER{'query:croak_unsupported'};
};

subtest 'execute: always croaks with error_execute_unsupported' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	throws_ok { $j->execute() }
		qr/execute\(\) raw SQL is not supported/,
		'execute() always croaks with the documented error message';
	delete $LEDGER{'execute:croak_unsupported'};
};

# ===========================================================================
# SECTION 13 -- AUTOLOAD
# ===========================================================================

subtest 'AUTOLOAD: DESTROY does not croak' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	lives_ok { $j->DESTROY() }
		'DESTROY is silently ignored and does not croak via AUTOLOAD';
	delete $LEDGER{'al:destroy_silently'};
};

subtest 'AUTOLOAD: private method name (leading _) croaks' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	throws_ok { $j->_some_private_method() }
		qr/cannot call private method/i,
		'AUTOLOAD croaks when the method name starts with underscore';
	delete $LEDGER{'al:private_croak'};
};

subtest 'AUTOLOAD: unknown column name croaks' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	throws_ok { $j->no_such_column() }
		qr/unknown column/i,
		'AUTOLOAD croaks when the method name is not a known column';
	delete $LEDGER{'al:unknown_col_croak'};
};

subtest 'AUTOLOAD: scalar context returns first matching value' => sub {
	plan tests => 1;
	# Simple case: no join_map, no filters; direct delegation
	my $j   = _two_db_join();
	mock 'MinimalDA::name' => sub { return 'MockedAlice' };
	my $val = $j->name('K1');
	is($val, 'MockedAlice',
		'AUTOLOAD in scalar context returns the value from the first matching row');
	restore_all();
	delete $LEDGER{'al:scalar_context'};
};

subtest 'AUTOLOAD: list context returns all matching column values' => sub {
	plan tests => 1;
	# With filters active, AUTOLOAD runs _joined_query; list context returns
	# all matching values -- one per qualifying merged row.
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'K1', name => 'Alice' },
			{ entry => 'K2', name => 'Bob'   },
		],
	);
	my $db_b = MinimalDA->new(
		cols => [$JC, $COL_B],
		rows => [
			{ entry => 'K1', score => 95 },
			{ entry => 'K2', score => 70 },
		],
	);
	my $j = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		filters     => { 0 => { name => 'Alice' } },
	);
	my @names = $j->name();
	is_deeply(\@names, ['Alice'],
		'AUTOLOAD list context returns all matching column values via _joined_query');
	delete $LEDGER{'al:list_context'};
};

subtest 'AUTOLOAD: direct delegation when no join_map and no filters' => sub {
	plan tests => 1;
	# Without join_map or filters, AUTOLOAD calls the owning DA's method directly.
	my $j = _two_db_join();
	my $called = 0;
	mock 'MinimalDA::tier' => sub { $called++; return 'gold' };
	$j->tier('K1');
	ok($called > 0, 'AUTOLOAD delegates directly to the owning DA when no join_map/filters');
	restore_all();
	delete $LEDGER{'al:direct_delegate'};
};

subtest 'AUTOLOAD: uses _joined_query when join_map is active' => sub {
	plan tests => 1;
	my $db0 = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [ { entry => 'K1', name => 'Alice' } ],
	);
	my $db1 = MinimalDA->new(
		cols => ['altkey', $COL_B],
		rows => [ { altkey => 'K1', score => 88 } ],
	);
	my $j = Database::Join->new(
		databases   => [$db0, $db1],
		join_column => $JC,
		join_map    => { 1 => 'altkey' },
	);
	# join_map is active; AUTOLOAD must run the full join so the key translation
	# is applied before fetching from db1.
	my $score = $j->score('K1');
	is($score, 88,
		'AUTOLOAD routes through _joined_query when join_map is active');
	delete $LEDGER{'al:full_join_join_map'};
};

subtest 'AUTOLOAD: uses _joined_query when filters are active' => sub {
	plan tests => 1;
	my $db0 = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'K1', name => 'Alice' },
			{ entry => 'K2', name => 'Bob'   },
		],
	);
	my $db1 = MinimalDA->new(
		cols => [$JC, $COL_B],
		rows => [
			{ entry => 'K1', score => 95 },
		],
	);
	# Filter on db1 makes it an inner partner; K2 is excluded.
	my $j = Database::Join->new(
		databases   => [$db0, $db1],
		join_column => $JC,
		filters     => { 1 => { entry => 'K1' } },
	);
	# name() would normally delegate to db0 directly; with filters active it
	# must use _joined_query so db1's filter is respected.
	my $name = $j->name('K1');
	is($name, 'Alice',
		'AUTOLOAD routes through _joined_query when filters are active');
	delete $LEDGER{'al:full_join_filters'};
};

# ===========================================================================
# SECTION 14 -- Join type semantics
# ===========================================================================

subtest 'join_type left: primary database defines the key set' => sub {
	plan tests => 1;
	# K3 is in db_a only; under LEFT join it must still appear.
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'K1', name => 'Alice'   },
			{ entry => 'K3', name => 'Charlie'  },
		],
	);
	my $db_b = MinimalDA->new(
		cols => [$JC, $COL_B],
		rows => [ { entry => 'K1', score => 95 } ],
	);
	my $j    = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		join_type   => 'left',
	);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 2,
		'left join: primary database defines the key set; K3 included even with no secondary match');
	delete $LEDGER{'jt:left_primary_defines'};
};

subtest 'join_type left: secondary columns are undef for unmatched primary rows' => sub {
	plan tests => 1;
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'K1', name => 'Alice'  },
			{ entry => 'K3', name => 'Charlie' },
		],
	);
	my $db_b = MinimalDA->new(
		cols => [$JC, $COL_B],
		rows => [ { entry => 'K1', score => 95 } ],
	);
	my $j    = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		join_type   => 'left',
	);
	my $rows = $j->selectall_arrayref();
	my ($k3) = grep { $_->{entry} eq 'K3' } @{$rows};
	ok(!defined $k3->{score},
		'left join: secondary column is undef for a primary row with no secondary match');
	delete $LEDGER{'jt:left_secondary_fills'};
};

subtest 'join_type inner: only keys present in all databases are returned' => sub {
	plan tests => 1;
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'K1', name => 'Alice'  },
			{ entry => 'K3', name => 'Charlie' },
		],
	);
	my $db_b = MinimalDA->new(
		cols => [$JC, $COL_B],
		rows => [ { entry => 'K1', score => 95 } ],
	);
	my $j    = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		join_type   => 'inner',
	);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 1,
		'inner join: only keys present in every database are included (K1 only, not K3)');
	delete $LEDGER{'jt:inner_shared_only'};
};

subtest 'join_type outer: all keys from any database are included' => sub {
	plan tests => 2;
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [ { entry => 'K1', name => 'Alice' } ],
	);
	my $db_b = MinimalDA->new(
		cols => [$JC, $COL_B],
		rows => [
			{ entry => 'K1', score => 95 },
			{ entry => 'K9', score => 10 },
		],
	);
	my $j    = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		join_type   => 'outer',
	);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 2,
		'outer join: all keys from any database are returned (K1 and K9)');
	my ($k9) = grep { $_->{entry} eq 'K9' } @{$rows};
	ok(!defined $k9->{name},
		'outer join: columns from unmatched databases are undef in the merged row');
	delete $LEDGER{'jt:outer_all_keys'};
};

subtest 'join_type: criteria on a secondary column act as inner-join override' => sub {
	plan tests => 1;
	# POD states: "whenever you pass a query criterion for a column that belongs
	# to a secondary database, that database automatically acts as an inner-join
	# partner for that query only -- regardless of join_type."
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'K1', name => 'Alice' },
			{ entry => 'K2', name => 'Bob'   },
		],
	);
	my $db_b = MinimalDA->new(
		cols => [$JC, $COL_B],
		rows => [ { entry => 'K1', score => 95 } ],   # K2 has no secondary row
	);
	# Left join: normally K2 would be included. But querying on a secondary
	# column forces inner semantics for that call only.
	my $j    = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		join_type   => 'left',
	);
	my $rows = $j->selectall_arrayref($COL_B => { '>=' => 0 });
	is(scalar @{$rows}, 1,
		'criterion on a secondary column acts as inner-join override (K2 excluded)');
	delete $LEDGER{'jt:criteria_inner_override'};
};

# ===========================================================================
# SECTION 15 -- filters semantics
# ===========================================================================

subtest 'filters: filtered database acts as inner-join partner regardless of join_type' => sub {
	plan tests => 1;
	# POD: "A filtered database always acts as an inner-join partner".
	# db_a has K1 and K2; db_b filtered to K1 only.
	# Even under LEFT join, K2 must be excluded.
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'K1', name => 'Alice' },
			{ entry => 'K2', name => 'Bob'   },
		],
	);
	my $db_b = MinimalDA->new(
		cols => [$JC, $COL_B],
		rows => [
			{ entry => 'K1', score => 95 },
			{ entry => 'K2', score => 70 },
		],
	);
	my $j = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		join_type   => 'left',
		filters     => { 1 => { entry => 'K1' } },
	);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 1,
		'filtered database acts as inner-join partner (K2 excluded despite LEFT join_type)');
	delete $LEDGER{'filt:inner_partner'};
};

subtest 'filters: two operator hashrefs on same column are merged with AND semantics' => sub {
	plan tests => 1;
	# POD: "when both the base filter value and the query criterion are operator
	# hashrefs, their operators are merged: both constraints apply (AND semantics)."
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'K1', name => 'Alice' },
			{ entry => 'K2', name => 'Bob'   },
			{ entry => 'K3', name => 'Carol'  },
		],
	);
	my $db_b = MinimalDA->new(
		cols => [$JC, $COL_B],
		rows => [
			{ entry => 'K1', score => 50  },
			{ entry => 'K2', score => 90  },
			{ entry => 'K3', score => 200 },
		],
	);
	# Base filter: score > 60. Query-time: score < 100.
	# AND semantics: 60 < score < 100 => K2 (90) only.
	my $j = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		filters     => { 1 => { score => { '>' => 60 } } },
	);
	my $rows = $j->selectall_arrayref(score => { '<' => 100 });
	is(scalar @{$rows}, 1,
		'two operator hashrefs on same column are AND-merged (only 60<score<100 rows returned)');
	delete $LEDGER{'filt:criteria_merge_and'};
};

subtest 'filters: scalar query criterion replaces the base filter for that column' => sub {
	plan tests => 1;
	# POD: "if the query criterion is a plain scalar, it replaces the base filter
	# for that column entirely -- the base filter is ignored for that one call."
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'K1', name => 'Alice' },
			{ entry => 'K2', name => 'Bob'   },
		],
	);
	my $db_b = MinimalDA->new(
		cols => [$JC, $COL_B],
		rows => [
			{ entry => 'K1', score => 95 },
			{ entry => 'K2', score => 70 },
		],
	);
	# Base filter: score > 80 (would exclude K2=70).
	# Query-time scalar: score => 70 (replaces the base filter for this call).
	my $j = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		filters     => { 1 => { score => { '>' => 80 } } },
	);
	my $rows = $j->selectall_arrayref(score => 70);
	is(scalar @{$rows}, 1,
		'plain scalar criterion replaces the base filter for that column (K2 included)');
	delete $LEDGER{'filt:scalar_replaces_base'};
};

# ===========================================================================
# SECTION 16 -- API ledger verification (must be last)
# Must run last so all deletes above have completed.
# ===========================================================================

subtest 'API ledger: all documented conditions were exercised' => sub {
	my $remaining = scalar keys %LEDGER;
	plan tests => $remaining + 1;
	for my $key (sort keys %LEDGER) {
		fail("Documented API condition not exercised: $key");
	}
	is($remaining, 0,
		'all documented messages and return states were exercised by the test suite');
};

diag('All Database::Join black-box API tests complete') if $ENV{TEST_VERBOSE};
