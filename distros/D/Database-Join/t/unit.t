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
	plan tests => 129;
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

	# collision_prefix semantics (POD: "collision_prefix - preserve colliding columns")
	'cp:new_param_stored'        => 1,  # constructor stores the hashref
	'cp:columns_show_both'       => 1,  # both plain and prefixed names visible
	'cp:join_col_not_prefixed'   => 1,  # join_column never gains a prefix
	'cp:non_collision_plain'     => 1,  # non-colliding secondary column stays plain
	'cp:index0_ignored'          => 1,  # index-0 entry is silently ignored
	'cp:schema_prefixed_key'     => 1,  # schema keyed under prefixed name
	'cp:rows_both_values'        => 1,  # merged row carries both values
	'cp:criterion_prefixed_routes' => 1, # criterion on "pfx.col" routes to correct DA
	'cp:remove_prefixed_col'     => 1,  # remove_column on published prefixed name works

	# backend parameter states (POD: "new() -- backend / max_array_rows / tmpdir")
	'new:backend_default_auto'                => 1,
	'new:backend_array_accepted'              => 1,
	'new:backend_sqlite_accepted'             => 1,
	'new:error_invalid_backend'               => 1,
	'new:max_array_rows_default'              => 1,
	'new:max_array_rows_stored'               => 1,
	'new:tmpdir_stored'                       => 1,
	'backend:array_path_no_dbi'               => 1,
	'backend:sqlite_path_uses_dbi'            => 1,
	'backend:auto_below_threshold_uses_array' => 1,
	'backend:auto_above_threshold_uses_sqlite'=> 1,
	'backend:results_identical'               => 1,
	'backend:error_sqlite_connect'            => 1,

	# sort_by parameter (POD section: "selectall_arrayref / Input / Optional parameter")
	'ob:asc_array'            => 1,  # sort_by 'col' ASC on array path
	'ob:desc_array'           => 1,  # sort_by ['col','DESC'] on array path
	'ob:asc_sqlite'           => 1,  # sort_by ASC on SQLite path
	'ob:desc_sqlite'          => 1,  # sort_by DESC on SQLite path
	'ob:unknown_col_carp'     => 1,  # unknown column => carp + default join_col sort
	'ob:invalid_dir_carp'     => 1,  # invalid direction => carp + ASC fallback
	'ob:count_drops_silently' => 1,  # count() silently drops sort_by

	# limit / offset pagination (POD section: "selectall_arrayref / Input / Optional parameters")
	'pg:limit_array'          => 1,  # limit on array path returns at most N rows
	'pg:offset_array'         => 1,  # offset on array path skips first M rows
	'pg:limit_sqlite'         => 1,  # limit on SQLite path returns at most N rows
	'pg:offset_sqlite'        => 1,  # offset on SQLite path skips first M rows
	'pg:limit_offset_combined'=> 1,  # limit+offset together selects the right window
	'pg:invalid_limit_carp'   => 1,  # invalid limit => carp + all rows returned
	'pg:invalid_offset_carp'  => 1,  # invalid offset => carp + no rows skipped
	'pg:count_drops_silently' => 1,  # count() ignores limit/offset, returns total

	# dbi_source() — composable nested joins (POD section: "dbi_source")
	'ds:array_returns_undef'    => 1,  # array backend → undef
	'ds:sqlite_returns_hashref' => 1,  # sqlite backend → {dbh, table}
	'ds:nested_join_works'      => 1,  # parent join can ATTACH child _dj_result
	'ds:auto_forces_sqlite'     => 1,  # auto backend forces SQLite for dbi_source

	# parallel => 1 constructor flag (POD section: "new() -- parallel")
	'par:constructor_accepted'     => 1,  # parallel => 1 accepted without error
	'par:two_db_no_effect'         => 1,  # n <= 2 databases: no threading, results correct
	'par:three_db_correct_results' => 1,  # n > 2 databases: results same as sequential

	# schema type consistency validation (warn_schema_type_mismatch)
	'st:carp_on_mismatch'     => 1,  # carp when shared column types differ at construction
	'st:no_carp_same_type'    => 1,  # no carp when shared column types agree
	'st:join_col_exempt'      => 1,  # join column itself is not checked
	'st:prefixed_exempt'      => 1,  # collision_prefix columns are exempt
	'st:add_db_emits_carp'    => 1,  # add_database also checks the new database
);

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
Readonly::Scalar my $JC          => 'entry';
Readonly::Scalar my $COL_A       => 'name';
Readonly::Scalar my $COL_B       => 'score';
Readonly::Scalar my $COL_C       => 'tier';
Readonly::Scalar my $TS_OLD      => 1_000_000;
Readonly::Scalar my $TS_NEW      => 2_000_000;
Readonly::Scalar my $CP_PREFIX   => 'b';         # collision_prefix value used in cp tests
Readonly::Scalar my $COL_SHARED  => 'notes';     # the column that collides between two DBs
Readonly::Scalar my $COL_PFX     => "b.notes";   # published prefixed name of the collision

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
# MinimalDA3: MinimalDA subclass that directly defines count() so that
# Database::Join's 'auto' backend threshold check can size datasets without
# fetching all rows (defined &{"${pkg}::count"} check in _sqlite_join).
# ---------------------------------------------------------------------------
{
	package MinimalDA3;
	use parent -norequire, 'MinimalDA';

	sub count { return scalar @{ $_[0]->{_rows} } }
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

# Three-row variant: three distinct names makes ascending/descending sort
# unambiguous.  Used exclusively for sort_by tests (Section 19).
sub _three_row_join {
	my (%opts) = @_;
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A, $COL_C],
		rows => [
			{ entry => 'K1', name => 'Carol', tier => 'silver' },
			{ entry => 'K2', name => 'Alice', tier => 'gold'   },
			{ entry => 'K3', name => 'Bob',   tier => 'bronze' },
		],
	);
	my $db_b = MinimalDA->new(
		cols => [$JC, $COL_B],
		rows => [
			{ entry => 'K1', score => 88 },
			{ entry => 'K2', score => 95 },
			{ entry => 'K3', score => 70 },
		],
	);
	return Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		join_type   => 'inner',
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
		qr/databases\[0\] does not support/,
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

subtest 'new: backend defaults to "auto"' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	is($j->{_backend}, 'auto', 'backend defaults to "auto" when omitted');
	delete $LEDGER{'new:backend_default_auto'};
};

subtest 'new: backend => "array" accepted and stored' => sub {
	plan tests => 1;
	my $j = _two_db_join(backend => 'array');
	is($j->{_backend}, 'array', 'backend "array" accepted and stored');
	delete $LEDGER{'new:backend_array_accepted'};
};

subtest 'new: backend => "sqlite" accepted and stored' => sub {
	plan tests => 1;
	my $j = _two_db_join(backend => 'sqlite');
	is($j->{_backend}, 'sqlite', 'backend "sqlite" accepted and stored');
	delete $LEDGER{'new:backend_sqlite_accepted'};
};

subtest 'new: error_invalid_backend -- unrecognised backend string rejected' => sub {
	plan tests => 1;
	my $db = MinimalDA->new(cols => [$JC], rows => []);
	throws_ok {
		Database::Join->new(databases => [$db], join_column => $JC, backend => 'sql')
	} qr/must be one of array, sqlite, auto/,
	  'new() croaks with error_invalid_backend for an unrecognised backend string';
	delete $LEDGER{'new:error_invalid_backend'};
};

subtest 'new: max_array_rows defaults to 10,000' => sub {
	plan tests => 1;
	my $j = _two_db_join();
	is($j->{_max_array_rows}, 10_000, 'max_array_rows defaults to 10,000 when omitted');
	delete $LEDGER{'new:max_array_rows_default'};
};

subtest 'new: max_array_rows and tmpdir stored when supplied' => sub {
	plan tests => 2;
	my $j = _two_db_join(max_array_rows => 500, tmpdir => '/tmp');
	is($j->{_max_array_rows}, 500,   'max_array_rows stored correctly');
	is($j->{_tmpdir},         '/tmp', 'tmpdir stored correctly');
	delete $LEDGER{'new:max_array_rows_stored'};
	delete $LEDGER{'new:tmpdir_stored'};
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
	plan tests => 2;
	my $db0 = MinimalDA->new(
		cols   => [$JC, $COL_A],
		schema => { $JC => { type => 'TEXT' }, $COL_A => { type => 'VARCHAR' } },
	);
	my $db1 = MinimalDA->new(
		cols   => [$JC, $COL_A],
		schema => { $JC => { type => 'TEXT' }, $COL_A => { type => 'CHAR' } },
	);
	# Capture the type-mismatch carp; the warning is expected here and is tested
	# explicitly in Section S23.  Capture it so it does not pollute test output.
	my @warns;
	my $j = do {
		local $SIG{__WARN__} = sub { push @warns, $_[0] };
		Database::Join->new(databases => [$db0, $db1], join_column => $JC);
	};
	is($j->schema()->{$COL_A}{type}, 'CHAR',
		'schema() uses the last database when the same column appears in multiple databases');
	ok(scalar @warns, 'type mismatch between DAs triggers a carp at construction');
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
		qr/does not support the selectall_arrayref/,
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
# SECTION 16 -- collision_prefix semantics
#
# Exercises every documented behaviour of the collision_prefix parameter.
# Uses two databases that share the column 'notes'.  With collision_prefix =>
# { 1 => 'b' } the secondary's copy is published as 'b.notes'; without it the
# last-database-wins default applies.
# ===========================================================================

# Helper: two-DB join where both databases have a 'notes' column.
sub _collision_join {
	my (%opts) = @_;
	my $db_a = MinimalDA->new(
		cols   => [$JC, $COL_SHARED, 'amount'],
		rows   => [ { entry => 'K1', notes => 'note-a', amount => 10 } ],
		schema => {
			$JC        => { type => 'TEXT' },
			$COL_SHARED => { type => 'TEXT' },
			amount      => { type => 'INTEGER' },
		},
	);
	my $db_b = MinimalDA->new(
		cols   => [$JC, $COL_SHARED, 'price'],
		rows   => [ { entry => 'K1', notes => 'note-b', price => 5 } ],
		schema => {
			$JC        => { type => 'TEXT' },
			$COL_SHARED => { type => 'TEXT' },
			price       => { type => 'INTEGER' },
		},
	);
	return Database::Join->new(
		databases        => [$db_a, $db_b],
		join_column      => $JC,
		collision_prefix => { 1 => $CP_PREFIX },
		%opts,
	);
}

subtest 'collision_prefix: constructor parameter stored in object' => sub {
	plan tests => 1;
	my $j = _collision_join();
	is_deeply($j->{_collision_prefix}, { 1 => $CP_PREFIX },
		'new() stores collision_prefix verbatim in the object');
	delete $LEDGER{'cp:new_param_stored'};
};

subtest 'collision_prefix: columns() shows both original and prefixed names' => sub {
	plan tests => 2;
	# POD: "Both values are then visible: the original column keeps its name (from
	# the earlier database), and the collision gets the prefixed name."
	my $j     = _collision_join();
	my %col_h = map { $_ => 1 } @{ $j->columns() };
	ok($col_h{$COL_SHARED}, "original '$COL_SHARED' present in columns() (from primary DB)");
	ok($col_h{$COL_PFX},    "prefixed '$COL_PFX' present in columns() (collision from secondary)");
	delete $LEDGER{'cp:columns_show_both'};
};

subtest 'collision_prefix: join_column never gains a prefix' => sub {
	plan tests => 1;
	# POD states the join_column is the shared merge key; it must not be renamed.
	my $j     = _collision_join();
	my %col_h = map { $_ => 1 } @{ $j->columns() };
	ok(!$col_h{"$CP_PREFIX.$JC"},
		"prefixed join_column '$CP_PREFIX.$JC' is absent from columns()");
	delete $LEDGER{'cp:join_col_not_prefixed'};
};

subtest 'collision_prefix: non-colliding secondary column published plain (no prefix)' => sub {
	plan tests => 1;
	# POD: "Non-colliding columns from a secondary database are always added as-is
	# with no prefix, whether or not collision_prefix is configured."
	my $j     = _collision_join();
	my %col_h = map { $_ => 1 } @{ $j->columns() };
	ok($col_h{price} && !$col_h{"$CP_PREFIX.price"},
		"non-colliding secondary column 'price' present plain with no prefix");
	delete $LEDGER{'cp:non_collision_plain'};
};

subtest 'collision_prefix: index-0 entry is silently ignored (primary never prefixed)' => sub {
	plan tests => 1;
	# POD: "An index-0 entry is meaningless and silently ignored."
	# With only an index-0 prefix, last-DB-wins applies as if collision_prefix were absent.
	my $db_a = MinimalDA->new(cols => [$JC, $COL_SHARED], rows => [
		{ entry => 'K1', notes => 'note-a' },
	]);
	my $db_b = MinimalDA->new(cols => [$JC, $COL_SHARED], rows => [
		{ entry => 'K1', notes => 'note-b' },
	]);
	my $j = Database::Join->new(
		databases        => [$db_a, $db_b],
		join_column      => $JC,
		collision_prefix => { 0 => $CP_PREFIX },  # index 0 is silently ignored
	);
	# Last-DB-wins should apply: 'notes' from db_b overwrites db_a's.
	my %col_h = map { $_ => 1 } @{ $j->columns() };
	ok(!$col_h{"$CP_PREFIX.$COL_SHARED"},
		"no prefixed column created when only index-0 entry given (silently ignored)");
	delete $LEDGER{'cp:index0_ignored'};
};

subtest 'collision_prefix: schema() keyed under published prefixed name' => sub {
	plan tests => 2;
	my $j = _collision_join();
	my $s = $j->schema();
	ok(exists $s->{$COL_PFX},    "schema() has entry for prefixed name '$COL_PFX'");
	ok(exists $s->{$COL_SHARED}, "schema() also has entry for plain '$COL_SHARED' (from primary)");
	delete $LEDGER{'cp:schema_prefixed_key'};
};

subtest 'collision_prefix: merged row carries both the primary and prefixed secondary values' => sub {
	plan tests => 2;
	# POD example: "$row->{notes} -- from primary; $row->{'b.notes'} -- from secondary"
	my $j   = _collision_join();
	my $row = $j->fetchrow_hashref(entry => 'K1');
	is($row->{$COL_SHARED}, 'note-a',
		"merged row has primary value under plain name '$COL_SHARED'");
	is($row->{$COL_PFX}, 'note-b',
		"merged row has secondary value under prefixed name '$COL_PFX'");
	delete $LEDGER{'cp:rows_both_values'};
};

subtest 'collision_prefix: criterion on prefixed name routes to the correct secondary DA' => sub {
	plan tests => 2;
	# POD example: "$join->selectall_arrayref('products.product' => 'widget')"
	# "Internally routes as: product => 'widget' to the secondary database"
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_SHARED],
		rows => [
			{ entry => 'K1', notes => 'note-a1' },
			{ entry => 'K2', notes => 'note-a2' },
		],
	);
	my $db_b = MinimalDA->new(
		cols => [$JC, $COL_SHARED],
		rows => [
			{ entry => 'K1', notes => 'note-b1' },
			{ entry => 'K2', notes => 'note-b2' },
		],
	);
	my $j    = Database::Join->new(
		databases        => [$db_a, $db_b],
		join_column      => $JC,
		collision_prefix => { 1 => $CP_PREFIX },
	);
	my $rows = $j->selectall_arrayref($COL_PFX => 'note-b1');
	is(scalar @{$rows}, 1,      "criterion '$COL_PFX => note-b1' returns exactly 1 row");
	is($rows->[0]{entry}, 'K1', 'correct row (K1) returned');
	delete $LEDGER{'cp:criterion_prefixed_routes'};
};

subtest 'collision_prefix: remove_column on the prefixed name hides that column' => sub {
	plan tests => 2;
	# POD: "remove_column operates on published names.  To suppress a prefixed
	# collision column entirely, pass the prefixed name."
	my $j = _collision_join();
	$j->remove_column($COL_PFX);
	my %col_h = map { $_ => 1 } @{ $j->columns() };
	ok(!$col_h{$COL_PFX},    "prefixed '$COL_PFX' absent from columns() after remove_column");
	ok($col_h{$COL_SHARED},  "plain '$COL_SHARED' still present (primary unaffected)");
	delete $LEDGER{'cp:remove_prefixed_col'};
};

# ===========================================================================
# SECTION 17 -- backend dispatch
# Tests that the three backend modes route queries correctly.
# Strategy: pass a non-existent tmpdir to prove the array path (which does
# not touch the filesystem) succeeds, while the SQLite path fails with the
# documented error_sqlite_connect.  The results-identical test uses the
# default (writable) tmpdir so both paths complete successfully.
# ===========================================================================

subtest 'backend array: query succeeds with non-writable tmpdir (array path ignores tmpdir)' => sub {
	plan tests => 2;
	# If the SQLite path were taken, File::Temp->new(DIR => ...) would fail.
	# Succeeding here proves the array path was chosen.
	my $j    = _two_db_join(backend => 'array', tmpdir => '/nonexistent/__no_such_dir__');
	my $rows;
	lives_ok { $rows = $j->selectall_arrayref() }
		'backend=array: query succeeds despite a non-writable tmpdir (tmpdir unused)';
	is(scalar @{$rows}, 2, 'backend=array: correct number of rows returned');
	delete $LEDGER{'backend:array_path_no_dbi'};
};

subtest 'backend sqlite: produces correct merged results' => sub {
	plan tests => 2;
	# Force the SQLite path unconditionally and verify it returns the same rows
	# as the default (array) path would.
	my $j    = _two_db_join(backend => 'sqlite');
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 2, 'backend=sqlite: correct number of rows');
	my %by_key = map { $_->{$JC} => $_ } @{$rows};
	is($by_key{K1}{$COL_B}, 95, 'backend=sqlite: merged column value correct for K1');
	delete $LEDGER{'backend:sqlite_path_uses_dbi'};
};

subtest 'backend auto below threshold: array path used (non-writable tmpdir ok)' => sub {
	plan tests => 2;
	# MinimalDA3 provides its own count(), so auto mode can size each DA
	# without fetching rows.  2+2=4 rows total; threshold=1000 => array path.
	# A non-writable tmpdir proves the array path was taken (SQLite would fail).
	my $db_a = MinimalDA3->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'K1', name => 'Alice' },
			{ entry => 'K2', name => 'Bob'   },
		],
	);
	my $db_b = MinimalDA3->new(
		cols => [$JC, $COL_B],
		rows => [
			{ entry => 'K1', score => 95 },
			{ entry => 'K2', score => 70 },
		],
	);
	my $j = Database::Join->new(
		databases      => [$db_a, $db_b],
		join_column    => $JC,
		backend        => 'auto',
		max_array_rows => 1_000,
		tmpdir         => '/nonexistent/__no_such_dir__',
	);
	my $rows;
	lives_ok { $rows = $j->selectall_arrayref() }
		'auto below threshold: succeeds despite non-writable tmpdir (array path, tmpdir not accessed)';
	is(scalar @{$rows}, 2, 'auto below threshold: correct row count');
	delete $LEDGER{'backend:auto_below_threshold_uses_array'};
};

subtest 'backend auto above threshold: SQLite path taken (triggers error_sqlite_connect)' => sub {
	plan tests => 1;
	# 2+2=4 rows total; threshold=1 => SQLite path.  A non-writable tmpdir
	# proves SQLite was chosen: if the array path were used it would succeed.
	my $db_a = MinimalDA3->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'K1', name => 'Alice' },
			{ entry => 'K2', name => 'Bob'   },
		],
	);
	my $db_b = MinimalDA3->new(
		cols => [$JC, $COL_B],
		rows => [
			{ entry => 'K1', score => 95 },
			{ entry => 'K2', score => 70 },
		],
	);
	my $j = Database::Join->new(
		databases      => [$db_a, $db_b],
		join_column    => $JC,
		backend        => 'auto',
		max_array_rows => 1,
		tmpdir         => '/nonexistent/__no_such_dir__',
	);
	# The SQLite path is taken, so File::Temp attempts to create a temp file
	# in the non-existent directory and dies.  Any die/croak from the module
	# proves the SQLite path was chosen (the array path would have succeeded).
	throws_ok { $j->selectall_arrayref() }
		qr/does not exist|Failed to open/,
		'auto above threshold: SQLite path taken — query throws when tmpdir is not accessible';
	delete $LEDGER{'backend:auto_above_threshold_uses_sqlite'};
};

subtest 'backend sqlite and array paths: identical results for the same query' => sub {
	plan tests => 1;
	# Both paths must be semantically equivalent; this is an explicit
	# result-identity invariant stated in the POD.
	my $rows_array  = _two_db_join(backend => 'array')->selectall_arrayref();
	my $rows_sqlite = _two_db_join(backend => 'sqlite')->selectall_arrayref();
	is_deeply($rows_array, $rows_sqlite,
		'SQLite and array backends return identical merged rows for the same query');
	delete $LEDGER{'backend:results_identical'};
};

subtest 'error_sqlite_connect: DBI::connect failure croaks with the documented message' => sub {
	plan tests => 1;
	# Trigger error_sqlite_connect by letting File::Temp succeed (default tmpdir)
	# but making DBI->connect return undef.  The module must then croak with
	# the message documented under MESSAGES for error_sqlite_connect.
	my $j = _two_db_join(backend => 'sqlite');
	my $orig_connect;
	{
		no strict 'refs';
		no warnings 'redefine';
		$orig_connect = \&DBI::connect;
		*DBI::connect  = sub { return undef };
	}
	my $err;
	eval { $j->selectall_arrayref() };
	$err = $@;
	{
		no strict 'refs';
		no warnings 'redefine';
		*DBI::connect = $orig_connect;
	}
	my ($first_line) = split /\n/, ($err // ''), 2;
	like($first_line, qr/Failed to open temporary SQLite database/,
		'error_sqlite_connect: documented message fires when DBI::connect returns undef');
	delete $LEDGER{'backend:error_sqlite_connect'};
};

# ===========================================================================
# SECTION 19 -- sort_by parameter (7 tests)
#
# POD guarantees: all query methods accept sort_by => 'col' (ascending)
# or sort_by => ['col', 'DESC'] (descending).  An unknown column or an
# invalid direction emits a carp and falls back to the default join_column
# ascending sort.  count() silently drops sort_by.
#
# Both the array backend (Perl sort) and the SQLite backend (SQL ORDER BY)
# are exercised so identical semantics are confirmed on each path.
# ===========================================================================

subtest 'sort_by ASC on array path: rows sorted by named column ascending' => sub {
	plan tests => 2;
	my $j    = _three_row_join(backend => 'array');
	my $rows = $j->selectall_arrayref(sort_by => $COL_A);
	my @names = map { $_->{$COL_A} } @{$rows};
	is_deeply(\@names, [qw(Alice Bob Carol)],
		'sort_by name ASC (array): ascending alphabetical order');
	is(scalar @{$rows}, 3, 'all 3 rows present');
	delete $LEDGER{'ob:asc_array'};
};

subtest 'sort_by DESC on array path: rows sorted by named column descending' => sub {
	plan tests => 1;
	my $j    = _three_row_join(backend => 'array');
	my $rows = $j->selectall_arrayref(sort_by => [$COL_A, 'DESC']);
	my @names = map { $_->{$COL_A} } @{$rows};
	is_deeply(\@names, [qw(Carol Bob Alice)],
		'sort_by name DESC (array): descending alphabetical order');
	delete $LEDGER{'ob:desc_array'};
};

subtest 'sort_by ASC on SQLite path: SQL ORDER BY applied correctly' => sub {
	plan tests => 2;
	my $j    = _three_row_join(backend => 'sqlite');
	my $rows = $j->selectall_arrayref(sort_by => $COL_A);
	my @names = map { $_->{$COL_A} } @{$rows};
	is_deeply(\@names, [qw(Alice Bob Carol)],
		'sort_by name ASC (SQLite): ascending order from SQL ORDER BY');
	is(scalar @{$rows}, 3, 'all 3 rows returned');
	delete $LEDGER{'ob:asc_sqlite'};
};

subtest 'sort_by DESC on SQLite path: SQL ORDER BY DESC reverses order' => sub {
	plan tests => 2;
	my $j    = _three_row_join(backend => 'sqlite');
	my $rows = $j->selectall_arrayref(sort_by => [$COL_A, 'DESC']);
	my @names = map { $_->{$COL_A} } @{$rows};
	is_deeply(\@names, [qw(Carol Bob Alice)],
		'sort_by name DESC (SQLite): descending order from SQL ORDER BY');
	is(scalar @{$rows}, 3, 'all 3 rows returned');
	delete $LEDGER{'ob:desc_sqlite'};
};

subtest 'sort_by unknown column: carp emitted, result returned in default order' => sub {
	plan tests => 3;
	# POD: "An unknown column emits a carp warning and falls back to the default
	# join_column ascending sort."  The query must not croak.
	my $j = _three_row_join(backend => 'array');
	my @warnings;
	my $rows;
	lives_ok {
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		$rows = $j->selectall_arrayref(sort_by => 'no_such_column');
	} 'unknown sort_by column does not croak';
	my @ob_warns = grep { /sort_by.*not in the merged view/i } @warnings;
	ok(scalar @ob_warns,
		'carp fired for unknown sort_by column (documented warning)');
	is(scalar @{$rows}, 3, 'all 3 rows returned despite bad sort_by');
	delete $LEDGER{'ob:unknown_col_carp'};
};

subtest 'sort_by invalid direction: carp emitted, ASC fallback used' => sub {
	plan tests => 3;
	# POD: "An invalid direction emits a carp warning and falls back to the
	# default join_column ascending sort."
	my $j = _three_row_join(backend => 'array');
	my @warnings;
	my $rows;
	lives_ok {
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		$rows = $j->selectall_arrayref(sort_by => [$COL_A, 'SIDEWAYS']);
	} 'invalid sort_by direction does not croak';
	my @dir_warns = grep { /direction.*not supported|not supported.*direction/i } @warnings;
	ok(scalar @dir_warns,
		'carp fired for unsupported direction (documented warning)');
	# With ASC fallback the result is still sorted ascending
	my @names = map { $_->{$COL_A} } @{$rows};
	is_deeply(\@names, [qw(Alice Bob Carol)],
		'invalid direction falls back to ASC: ascending order returned');
	delete $LEDGER{'ob:invalid_dir_carp'};
};

subtest 'count: sort_by parameter is silently dropped' => sub {
	plan tests => 2;
	# POD: "count() ignores sort_by as row ordering does not affect a count."
	# No carp must fire, and the count must be the correct total.
	my $j = _three_row_join(backend => 'array');
	my @warnings;
	my $n;
	lives_ok {
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		$n = $j->count(sort_by => $COL_A);
	} 'count with sort_by does not croak';
	my @ob_warns = grep { /sort_by/i } @warnings;
	is(scalar @ob_warns, 0,
		'count: no carp for sort_by — it is silently dropped before criteria routing');
	delete $LEDGER{'ob:count_drops_silently'};
};

# ===========================================================================
# SECTION 21 -- dbi_source() composable nested joins
#   Verifies the public API of dbi_source(): return value shape, array-backend
#   undef, and that a parent join can ATTACH a child join and query rows.
#   Uses the _three_row_join() fixture (Carol/K1, Alice/K2, Bob/K3).
# ===========================================================================

subtest 'dbi_source: array backend returns undef' => sub {
	plan tests => 1;
	my $j = _three_row_join(backend => 'array');
	is($j->dbi_source(), undef,
		'dbi_source() returns undef when backend is array');
	delete $LEDGER{'ds:array_returns_undef'};
};

subtest 'dbi_source: sqlite backend returns {dbh, table} hashref' => sub {
	plan tests => 4;
	my $j   = _three_row_join(backend => 'sqlite');
	my $src = $j->dbi_source();
	ok(defined $src,                'dbi_source() returns a defined value');
	is(ref($src), 'HASH',           'return value is a hashref');
	ok(defined $src->{dbh},         'hashref has a dbh key');
	is($src->{table}, '_dj_result', 'hashref table is _dj_result');
	delete $LEDGER{'ds:sqlite_returns_hashref'};
};

subtest 'dbi_source: parent join ATTACHes child and queries merged columns' => sub {
	plan tests => 3;
	# Child exposes entry/name/score.  Add a rank source for the parent.
	my $db_rank = MinimalDA->new(
		cols => [$JC, 'rank'],
		rows => [
			{ entry => 'K1', rank => 10 },
			{ entry => 'K2', rank => 20 },
			{ entry => 'K3', rank => 30 },
		],
	);
	my $child  = _three_row_join(backend => 'sqlite');
	my $parent = Database::Join->new(
		databases   => [$child, $db_rank],
		join_column => $JC,
		backend     => 'sqlite',
		join_type   => 'inner',
	);
	my $rows = $parent->selectall_arrayref();
	is(scalar @{$rows}, 3, 'nested join returns 3 rows');
	my ($carol) = grep { $_->{$JC} eq 'K1' } @{$rows};
	is($carol->{$COL_A}, 'Carol', 'name column visible through nested join');
	is($carol->{rank},   10,      'rank column from parent source also present');
	delete $LEDGER{'ds:nested_join_works'};
};

subtest 'dbi_source: auto backend forces SQLite path (dbi_source always usable)' => sub {
	plan tests => 2;
	my $j   = _three_row_join(backend => 'auto');
	my $src = $j->dbi_source();
	ok(defined $src && ref($src) eq 'HASH',
		'auto backend: dbi_source() returns hashref (SQLite forced)');
	is($src->{table}, '_dj_result', 'auto backend: table is _dj_result');
	delete $LEDGER{'ds:auto_forces_sqlite'};
};

# ===========================================================================
# SECTION 20 -- limit / offset pagination parameters
#   Three-row fixture (Carol/K1, Alice/K2, Bob/K3, inner join, sorted by
#   join_column ascending by default).  limit and offset are tested on both
#   the array and SQLite backends, along with carp-on-invalid and the
#   count() silent-drop requirement.
# ===========================================================================

subtest 'limit on array path: returns at most N rows' => sub {
	plan tests => 2;
	my $j    = _three_row_join(backend => 'array');
	my $rows = $j->selectall_arrayref(limit => 2);
	is(scalar @{$rows}, 2, 'limit=2: 2 rows returned on array path');
	is($rows->[0]{name}, 'Carol', 'first row is Carol (K1, join_col order)');
	delete $LEDGER{'pg:limit_array'};
};

subtest 'offset on array path: skips first M rows' => sub {
	plan tests => 2;
	my $j    = _three_row_join(backend => 'array');
	my $rows = $j->selectall_arrayref(offset => 1);
	is(scalar @{$rows}, 2, 'offset=1 skips 1 row, 2 remain on array path');
	is($rows->[0]{name}, 'Alice', 'first remaining is Alice (K2)');
	delete $LEDGER{'pg:offset_array'};
};

subtest 'limit on SQLite path: returns at most N rows' => sub {
	plan tests => 2;
	my $j    = _three_row_join(backend => 'sqlite');
	my $rows = $j->selectall_arrayref(limit => 1);
	is(scalar @{$rows}, 1, 'limit=1: 1 row returned on SQLite path');
	is($rows->[0]{name}, 'Carol', 'the one row is Carol (K1)');
	delete $LEDGER{'pg:limit_sqlite'};
};

subtest 'offset on SQLite path: skips first M rows' => sub {
	plan tests => 2;
	my $j    = _three_row_join(backend => 'sqlite');
	my $rows = $j->selectall_arrayref(offset => 2);
	is(scalar @{$rows}, 1, 'offset=2 skips 2 rows, 1 remains on SQLite path');
	is($rows->[0]{name}, 'Bob', 'the remaining row is Bob (K3)');
	delete $LEDGER{'pg:offset_sqlite'};
};

subtest 'limit + offset combined: returns the correct window' => sub {
	plan tests => 3;
	my $j    = _three_row_join(backend => 'sqlite');
	# Skip Carol/K1 (offset=1), take 1 row (limit=1) → Alice/K2
	my $rows = $j->selectall_arrayref(limit => 1, offset => 1);
	is(scalar @{$rows}, 1, 'limit=1 offset=1: 1 row in the window');
	is($rows->[0]{name}, 'Alice', 'window row is Alice (K2)');
	# Verify array path gives the same window
	my $j2    = _three_row_join(backend => 'array');
	my $rows2 = $j2->selectall_arrayref(limit => 1, offset => 1);
	is($rows2->[0]{name}, 'Alice', 'array path: same window (Alice/K2)');
	delete $LEDGER{'pg:limit_offset_combined'};
};

subtest 'invalid limit emits carp and is ignored (all rows returned)' => sub {
	plan tests => 3;
	my $j = _three_row_join(backend => 'array');
	my @warnings;
	my $rows;
	lives_ok {
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		$rows = $j->selectall_arrayref(limit => 0);
	} 'limit=0 does not croak';
	like($warnings[0], qr/limit must be a positive integer/, 'carp emitted for limit=0');
	is(scalar @{$rows}, 3, 'limit=0 ignored: all 3 rows returned');
	delete $LEDGER{'pg:invalid_limit_carp'};
};

subtest 'invalid offset emits carp and is ignored (no rows skipped)' => sub {
	plan tests => 3;
	my $j = _three_row_join(backend => 'array');
	my @warnings;
	my $rows;
	lives_ok {
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		$rows = $j->selectall_arrayref(offset => -1);
	} 'offset=-1 does not croak';
	like($warnings[0], qr/offset must be a non-negative integer/, 'carp emitted for offset=-1');
	is(scalar @{$rows}, 3, 'offset=-1 ignored: all 3 rows returned');
	delete $LEDGER{'pg:invalid_offset_carp'};
};

subtest 'count() ignores limit and offset: returns total matching rows' => sub {
	plan tests => 2;
	my $j = _three_row_join(backend => 'array');
	my @warnings;
	my $n;
	lives_ok {
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		$n = $j->count(limit => 1, offset => 1);
	} 'count() with limit+offset does not croak';
	is($n, 3, 'count() ignores limit/offset: reports all 3 rows');
	delete $LEDGER{'pg:count_drops_silently'};
};

# ===========================================================================
# SECTION 23 -- Schema type consistency validation (warn_schema_type_mismatch)
#   When two databases share a column name without a collision_prefix, their
#   schema() types are compared at new() / add_database() time.  A type
#   mismatch emits warn_schema_type_mismatch (carp) to alert the caller before
#   silent type coercion produces unexpected query results.
#   The join column itself and any collision_prefix-renamed columns are exempt.
# ===========================================================================

subtest 'schema type mismatch: carp emitted when shared column types differ' => sub {
	plan tests => 2;
	my $db0 = MinimalDA->new(
		cols   => [$JC, $COL_B],
		schema => { $JC => { type => 'TEXT' }, $COL_B => { type => 'INTEGER' } },
	);
	my $db1 = MinimalDA->new(
		cols   => [$JC, $COL_B],
		schema => { $JC => { type => 'TEXT' }, $COL_B => { type => 'TEXT' } },
	);
	my @warns;
	local $SIG{__WARN__} = sub { push @warns, $_[0] };
	my $j = Database::Join->new(databases => [$db0, $db1], join_column => $JC);
	ok(scalar @warns, 'carp fired when shared column types differ at construction');
	like($warns[0], qr/has type.*but type|type.*mismatch/i,
		'carp message describes the type mismatch');
	delete $LEDGER{'st:carp_on_mismatch'};
};

subtest 'schema type mismatch: no carp when shared column types agree' => sub {
	plan tests => 1;
	my $db0 = MinimalDA->new(
		cols   => [$JC, $COL_B],
		schema => { $JC => { type => 'TEXT' }, $COL_B => { type => 'INTEGER' } },
	);
	my $db1 = MinimalDA->new(
		cols   => [$JC, $COL_B],
		schema => { $JC => { type => 'TEXT' }, $COL_B => { type => 'INTEGER' } },
	);
	my @warns;
	local $SIG{__WARN__} = sub { push @warns, $_[0] };
	Database::Join->new(databases => [$db0, $db1], join_column => $JC);
	is(scalar @warns, 0, 'no carp when shared column types agree');
	delete $LEDGER{'st:no_carp_same_type'};
};

subtest 'schema type mismatch: join column type difference is exempt from check' => sub {
	plan tests => 1;
	# The join column is structural, not a data column.  Differing types
	# in different DAs (e.g. pk => 1 in one, pk => 0 in another) must not
	# generate a spurious mismatch warning.
	my $db0 = MinimalDA->new(
		cols   => [$JC, $COL_A],
		schema => { $JC => { type => 'INTEGER' }, $COL_A => { type => 'TEXT' } },
	);
	my $db1 = MinimalDA->new(
		cols   => [$JC, $COL_B],
		schema => { $JC => { type => 'TEXT'    }, $COL_B => { type => 'INTEGER' } },
	);
	my @warns;
	local $SIG{__WARN__} = sub { push @warns, $_[0] };
	Database::Join->new(databases => [$db0, $db1], join_column => $JC);
	is(scalar @warns, 0, 'join column type mismatch does not trigger a carp');
	delete $LEDGER{'st:join_col_exempt'};
};

subtest 'schema type mismatch: collision_prefix columns are exempt from check' => sub {
	plan tests => 1;
	# With collision_prefix configured, the secondary column is published under
	# a prefixed name.  No silent merge occurs, so no warning should fire.
	my $db0 = MinimalDA->new(
		cols   => [$JC, $COL_A],
		schema => { $JC => { type => 'TEXT' }, $COL_A => { type => 'INTEGER' } },
	);
	my $db1 = MinimalDA->new(
		cols   => [$JC, $COL_A],
		schema => { $JC => { type => 'TEXT' }, $COL_A => { type => 'TEXT' } },
	);
	my @warns;
	local $SIG{__WARN__} = sub { push @warns, $_[0] };
	Database::Join->new(
		databases        => [$db0, $db1],
		join_column      => $JC,
		collision_prefix => { 1 => 'b' },
	);
	is(scalar @warns, 0,
		'no carp when the colliding column is protected by collision_prefix');
	delete $LEDGER{'st:prefixed_exempt'};
};

subtest 'schema type mismatch: add_database() also validates the new database' => sub {
	plan tests => 2;
	my $db0 = MinimalDA->new(
		cols   => [$JC, $COL_B],
		schema => { $JC => { type => 'TEXT' }, $COL_B => { type => 'INTEGER' } },
		rows   => [{ entry => 'K1', score => 10 }],
	);
	my $db1 = MinimalDA->new(
		cols   => [$JC, $COL_A],
		schema => { $JC => { type => 'TEXT' }, $COL_A => { type => 'TEXT' } },
		rows   => [{ entry => 'K1', name => 'Alice' }],
	);
	# Create with no shared columns; no warning at this point.
	my $j;
	{
		my @warns;
		local $SIG{__WARN__} = sub { push @warns, $_[0] };
		$j = Database::Join->new(databases => [$db0], join_column => $JC);
		is(scalar @warns, 0, 'no warning at construction with a single database');
	}
	# Now add a database that shares COL_B but with a different type.
	my $db2 = MinimalDA->new(
		cols   => [$JC, $COL_B],
		schema => { $JC => { type => 'TEXT' }, $COL_B => { type => 'REAL' } },
		rows   => [{ entry => 'K1', score => 9.5 }],
	);
	my @warns2;
	{
		local $SIG{__WARN__} = sub { push @warns2, $_[0] };
		$j->add_database($db2);
	}
	ok(scalar @warns2, 'add_database() emits carp when new DB introduces type mismatch');
	delete $LEDGER{'st:add_db_emits_carp'};
};

# ---------------------------------------------------------------------------
# Helper: three-database join — primary + 2 secondaries (n > 2 threshold).
# Used exclusively for parallel => 1 tests (Section S22).
# ---------------------------------------------------------------------------
sub _three_db_join {
	my (%opts) = @_;
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
	my $db_c = MinimalDA->new(
		cols => [$JC, $COL_C],
		rows => [
			{ entry => 'K1', tier => 'gold'   },
			{ entry => 'K2', tier => 'silver' },
		],
	);
	return Database::Join->new(
		databases   => [$db_a, $db_b, $db_c],
		join_column => $JC,
		join_type   => 'inner',
		%opts,
	);
}

# ===========================================================================
# SECTION 22 -- parallel => 1 constructor flag
#   The parallel flag enables concurrent Perl-thread fetching of secondary DAs
#   when n > 2 databases are joined.  With n <= 2 (one secondary), the flag
#   has no effect and the sequential path is used.  Results must be identical
#   to sequential regardless of whether the threads module is installed.
# ===========================================================================

subtest 'parallel: constructor accepts parallel => 1 (no croak)' => sub {
	plan tests => 2;
	my $j;
	lives_ok { $j = _two_db_join(parallel => 1) }
		'parallel => 1 accepted by constructor without croak';
	isa_ok($j, 'Database::Join');
	delete $LEDGER{'par:constructor_accepted'};
};

subtest 'parallel: 2-db join with parallel => 1 returns correct results (n <= 2 threshold)' => sub {
	plan tests => 2;
	# n = 2 (1 secondary): the n > 2 guard prevents threading even with parallel => 1.
	# Results must still be correct.
	my $j    = _two_db_join(parallel => 1, join_type => 'inner');
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 2, 'parallel => 1, 2-db join: 2 rows returned');
	my @entries = sort map { $_->{entry} } @{$rows};
	is_deeply(\@entries, [qw(K1 K2)],
		'parallel => 1, 2-db join: correct entry keys');
	delete $LEDGER{'par:two_db_no_effect'};
};

subtest 'parallel: 3-db join with parallel => 1 returns same results as sequential' => sub {
	plan tests => 3;
	# n = 3 (2 secondaries): threading attempted (or falls back to sequential if
	# threads not installed).  Either way, the merged result must be identical.
	my $j_par = _three_db_join(parallel => 1, backend => 'array');
	my $j_seq = _three_db_join(parallel => 0, backend => 'array');
	my $rows_par = $j_par->selectall_arrayref();
	my $rows_seq = $j_seq->selectall_arrayref();
	is(scalar @{$rows_par}, scalar @{$rows_seq},
		'parallel 3-db join: same row count as sequential');
	my @ent_par = sort map { $_->{entry} } @{$rows_par};
	my @ent_seq = sort map { $_->{entry} } @{$rows_seq};
	is_deeply(\@ent_par, \@ent_seq,
		'parallel 3-db join: same entry keys as sequential');
	# Verify all three columns are present in the merged row.
	my ($row) = grep { $_->{entry} eq 'K1' } @{$rows_par};
	ok(defined $row->{name} && defined $row->{score} && defined $row->{tier},
		'parallel 3-db join: merged row contains all three DA columns');
	delete $LEDGER{'par:three_db_correct_results'};
};

# ===========================================================================
# SECTION 18 -- API ledger verification (must be last)
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
