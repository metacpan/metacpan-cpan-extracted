use strict;
use warnings;

# ---------------------------------------------------------------------------
# t/function.t -- White-box unit tests for every sub in lib/Database/Join.pm
#
# Strategy: "Protected" helpers cannot be called from outside the package
# hierarchy, so we use Database::Join::WhiteBox (defined below) -- a thin
# subclass that re-exposes each helper under a public "expose_*" name.  All
# other public methods are tested on real Database::Join objects built with
# inline MinimalDA mocks.
#
# MinimalDA is an in-process stub that inherits from Database::Abstraction
# purely to satisfy the isa() check.  Its selectall_arrayref, columns(), and
# schema() are configurable at construction time so each subtest can control
# exactly what the component database returns.
#
# Test::Mockingbird is used to mock List::Util::max (used by updated()) and
# to spy on internal call chains.  Test::Returns validates return-type
# contracts.  Test::Memory::Cycle verifies no circular references exist.
# ---------------------------------------------------------------------------

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Memory::Cycle;
use Readonly;
use Scalar::Util qw(blessed refaddr);

BEGIN {
	eval { require Database::Abstraction };
	plan skip_all => 'Database::Abstraction required' if $@;
	plan tests => 119;
	use_ok('Database::Join');
}

# ---------------------------------------------------------------------------
# Constants -- prevent magic strings from appearing in the body below
# ---------------------------------------------------------------------------
Readonly::Scalar my $JC       => 'entry';          # canonical join column
Readonly::Scalar my $JC_ALT   => 'statecode';      # alternative join_column name
Readonly::Scalar my $JC_ALIAS => 'id';             # local alias used by DB 1 in join_map tests
Readonly::Scalar my $COL_A    => 'name';
Readonly::Scalar my $COL_B    => 'score';
Readonly::Scalar my $COL_C    => 'tier';
Readonly::Scalar my $TS_A     => 1_000_000;
Readonly::Scalar my $TS_B     => 2_000_000;

# ---------------------------------------------------------------------------
# MinimalDA: inline Database::Abstraction subclass used as a mock component.
# Configurable columns/rows/schema/updated at construction time.
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

	sub columns         { return $_[0]->{_cols} }
	sub schema          { return $_[0]->{_schema} }
	sub updated         { return $_[0]->{_ts} }
	sub set_logger      { $_[0]->{_logger} = $_[1]; return $_[0] }
	sub selectall_arrayref {
		my ($self, $criteria) = @_;
		my @rows = @{ $self->{_rows} };
		# Simple equality filter for tests that need it
		for my $col (keys %{ $criteria // {} }) {
			my $val = $criteria->{$col};
			next if ref $val;
			@rows = grep { defined $_->{$col} && $_->{$col} eq $val } @rows;
		}
		return \@rows;
	}
	sub DESTROY {}
}

# ---------------------------------------------------------------------------
# WhiteBox shim: subclass that exposes protected methods for unit testing.
# Protected subs check caller; calling them through a subclass passes the check.
# ---------------------------------------------------------------------------
{
	package Database::Join::WhiteBox;
	use parent -norequire, 'Database::Join';
	sub expose_msg              { shift; Database::Join::_msg(@_) }
	sub expose_merge_criteria   { shift; Database::Join::_merge_criteria(@_) }
	sub expose_parse_query_args { my $self = shift; return $self->_parse_query_args(@_) }
	sub expose_partition        { my $self = shift; return $self->_partition_criteria(@_) }
	sub expose_fetch_indexed    { my $self = shift; return $self->_fetch_indexed(@_) }
	sub expose_joined_query      { my $self = shift; return $self->_joined_query(@_) }
	sub expose_err               { my $self = shift; return $self->_err(@_) }
	sub expose_build_col_index   { my $self = shift; return $self->_build_col_index(@_) }
}

# Convenience builder for a bare WhiteBox skeleton (no databases needed for
# pure-helper tests that don't touch _dbs).
sub _bare_whitebox {
	my (%extra) = @_;
	return bless {
		_join_col     => $JC,
		_join_type    => 'left',
		_join_map     => {},
		_filters      => {},
		_dbs          => [],
		_col_db       => {},
		_db_cols      => [],
		_removed_cols => {},
		_col_cache    => undef,
		_schema_cache => undef,
		_autoload_pk  => $JC,
		_logger       => undef,
		_i18n         => undef,
		%extra,
	}, 'Database::Join::WhiteBox';
}

# Convenience: build a standard two-DB join for integration-style subtests
sub _make_join {
	my (%opts) = @_;
	my $db_a = MinimalDA->new(
		cols   => [$JC, $COL_A, $COL_C],
		rows   => [
			{ entry => 'K1', name => 'Alice', tier => 'gold'   },
			{ entry => 'K2', name => 'Bob',   tier => 'silver' },
		],
		schema => {
			entry => { type => 'TEXT', nullable => 0, default => undef, pk => 1 },
			name  => { type => 'TEXT', nullable => 1, default => undef, pk => 0 },
			tier  => { type => 'TEXT', nullable => 1, default => undef, pk => 0 },
		},
		updated => $TS_A,
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
		updated => $TS_B,
	);
	return Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		%opts,
	);
}

diag('Starting Database::Join white-box function tests') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 1 -- _msg (5 tests)
# Tests the i18n message formatting helper in isolation via WhiteBox.
# ===========================================================================
subtest '_msg: known key, no sprintf args' => sub {
	plan tests => 1;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_msg(undef, 'error_no_databases');
	is($got, 'At least one Database::Abstraction object is required',
		'_msg returns the exact string from %MESSAGES');
};

subtest '_msg: known key, sprintf substitution' => sub {
	plan tests => 1;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_msg(undef, 'error_invalid_db', 3);
	like($got, qr/databases\[3\]/, '_msg substitutes the index correctly');
};

subtest '_msg: unknown key falls back to error_unknown_message' => sub {
	plan tests => 1;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_msg(undef, 'no_such_key_xyz');
	like($got, qr/no_such_key_xyz/, '_msg embeds the unknown key name in the fallback message');
};

subtest '_msg: i18n object with translate() receives the call' => sub {
	plan tests => 2;
	my $wb   = _bare_whitebox();
	my $calls = 0;
	my $i18n = bless {}, 'FakeI18N';
	{
		no strict 'refs';
		*FakeI18N::can = sub { return $_[1] eq 'translate' ? sub { 'translated' } : undef };
		*FakeI18N::translate = sub { $calls++; return 'translated' };
	}
	my $got = $wb->expose_msg($i18n, 'error_no_databases');
	is($got,   'translated', '_msg delegates to i18n->translate()');
	is($calls, 1,            '_msg calls translate exactly once');
};

subtest '_msg: i18n object without translate() falls back to %MESSAGES' => sub {
	plan tests => 1;
	my $wb   = _bare_whitebox();
	my $i18n = bless {}, 'NoTranslateI18N';
	{
		no strict 'refs';
		*NoTranslateI18N::can = sub { return undef };
	}
	my $got = $wb->expose_msg($i18n, 'error_no_databases');
	like($got, qr/Database::Abstraction/, '_msg uses %MESSAGES when i18n lacks translate()');
};

# ===========================================================================
# SECTION 2 -- _merge_criteria (6 tests)
# Tests the AND-semantics merging of two per-database criteria hashrefs.
# ===========================================================================
subtest '_merge_criteria: disjoint columns both survive' => sub {
	plan tests => 2;
	my $wb   = _bare_whitebox();
	my $got  = $wb->expose_merge_criteria({ name => 'Alice' }, { score => 80 });
	is($got->{name},  'Alice', 'base column survives when not in extra');
	is($got->{score}, 80,      'extra column survives when not in base');
};

subtest '_merge_criteria: both operator hashrefs -- operators combined (AND semantics)' => sub {
	plan tests => 2;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_merge_criteria(
		{ score => { '>' => 60 } },
		{ score => { '<' => 365 } },
	);
	ok(exists $got->{score}{'>'}, 'base operator key present in merged result');
	ok(exists $got->{score}{'<'}, 'extra operator key present in merged result');
};

subtest '_merge_criteria: base is hashref, extra is scalar -- extra wins' => sub {
	plan tests => 1;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_merge_criteria(
		{ score => { '>' => 60 } },
		{ score => 75 },
	);
	is($got->{score}, 75, 'scalar query-time criterion replaces operator hashref base filter');
};

subtest '_merge_criteria: extra is hashref, base is scalar -- extra wins' => sub {
	plan tests => 1;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_merge_criteria(
		{ score => 75 },
		{ score => { '>' => 60 } },
	);
	is_deeply($got->{score}, { '>' => 60 }, 'hashref query-time criterion replaces scalar base');
};

subtest '_merge_criteria: both scalars -- extra overwrites base' => sub {
	plan tests => 1;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_merge_criteria({ name => 'Alice' }, { name => 'Bob' });
	is($got->{name}, 'Bob', 'extra scalar overwrites base scalar');
};

subtest '_merge_criteria: returns a new independent hashref (does not mutate base)' => sub {
	plan tests => 2;
	my $wb   = _bare_whitebox();
	my $base = { name => 'Alice' };
	my $got  = $wb->expose_merge_criteria($base, { name => 'Bob' });
	is($got->{name},  'Bob',   'merged result has extra value');
	is($base->{name}, 'Alice', '_merge_criteria did not mutate the base hashref');
};

# ===========================================================================
# SECTION 3 -- _parse_query_args (5 tests)
# Tests the three calling conventions normalised into a single criteria hashref.
# ===========================================================================
subtest '_parse_query_args: no args returns empty hashref' => sub {
	plan tests => 2;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_parse_query_args(undef);
	returns_ok($got, { type => 'hashref' }, '_parse_query_args returns a hashref');
	is_deeply($got, {}, 'no args produces an empty criteria hashref');
};

subtest '_parse_query_args: single scalar uses join_column as key' => sub {
	plan tests => 1;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_parse_query_args(undef, 'K1');
	is_deeply($got, { $JC => 'K1' }, 'single scalar maps to { join_col => value }');
};

subtest '_parse_query_args: single scalar with explicit positional key' => sub {
	plan tests => 1;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_parse_query_args('name', 'Alice');
	is_deeply($got, { name => 'Alice' }, 'explicit positional key overrides join_column');
};

subtest '_parse_query_args: key/value pairs parsed correctly' => sub {
	plan tests => 1;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_parse_query_args(undef, name => 'Alice', score => 80);
	is_deeply($got, { name => 'Alice', score => 80 }, 'kv pairs produce correct criteria hashref');
};

subtest '_parse_query_args: operator hashref preserved intact' => sub {
	plan tests => 1;
	my $wb   = _bare_whitebox();
	my $op   = { '>' => 80 };
	my $got  = $wb->expose_parse_query_args(undef, score => $op);
	is_deeply($got->{score}, $op, 'operator hashref passes through _parse_query_args unchanged');
};

# ===========================================================================
# SECTION 4 -- new() constructor (10 tests)
# Tests parameter validation, defaults, and internal-field initialisation.
# ===========================================================================
subtest 'new: empty databases arrayref croaks' => sub {
	plan tests => 1;
	throws_ok { Database::Join->new(databases => [], join_column => $JC) }
		qr/At least one Database::Abstraction/,
		'new() croaks when databases is empty';
};

subtest 'new: non-DA object in databases croaks with index' => sub {
	plan tests => 1;
	throws_ok { Database::Join->new(databases => [ bless({}, 'NotDA') ], join_column => $JC) }
		qr/not a Database::Abstraction/i,
		'new() croaks when a databases element is not a DA subclass';
};

subtest 'new: join_column absent from primary DB croaks' => sub {
	plan tests => 1;
	my $db = MinimalDA->new(cols => ['other'], rows => []);
	throws_ok { Database::Join->new(databases => [$db], join_column => 'missing_col') }
		qr/absent from databases\[0\]/,
		'new() croaks when join_column is missing from the primary database';
};

subtest 'new: join_map value is a reference croaks (heap-address guard)' => sub {
	plan tests => 1;
	my $db0 = MinimalDA->new(cols => [$JC, $COL_A], rows => []);
	my $db1 = MinimalDA->new(cols => [$JC, $COL_B], rows => []);
	throws_ok {
		Database::Join->new(
			databases   => [$db0, $db1],
			join_column => $JC,
			join_map    => { 1 => { evil => 1 } },  # value is a hashref, not a string
		);
	} qr/absent from databases\[1\]/,
		'new() croaks cleanly when a join_map value is a reference (no heap address in message)';
};

subtest 'new: join_column defaults to "entry"' => sub {
	plan tests => 1;
	my $db = MinimalDA->new(cols => ['entry', 'x'], rows => []);
	my $j  = Database::Join->new(databases => [$db]);
	is($j->{_join_col}, 'entry', 'join_column defaults to "entry" when not supplied');
};

subtest 'new: join_type defaults to "left"' => sub {
	plan tests => 1;
	my $db = MinimalDA->new(cols => [$JC], rows => []);
	my $j  = Database::Join->new(databases => [$db], join_column => $JC);
	is($j->{_join_type}, 'left', 'join_type defaults to "left" when not supplied');
};

subtest 'new: invalid join_type rejected by enum check' => sub {
	plan tests => 1;
	my $db = MinimalDA->new(cols => [$JC], rows => []);
	dies_ok { Database::Join->new(databases => [$db], join_column => $JC, join_type => 'bogus') }
		'new() dies when join_type is not one of inner/left/outer';
};

subtest 'new: _autoload_pk cached from primary DB {id} field' => sub {
	plan tests => 2;
	my $db = MinimalDA->new(id => 'custom_pk', cols => [$JC, $COL_A], rows => []);
	my $j  = Database::Join->new(databases => [$db], join_column => $JC);
	# _autoload_pk must equal the id field of the first DA, not join_column,
	# because AUTOLOAD positional args target the primary DB's primary key.
	is($j->{_autoload_pk}, 'custom_pk',
		'_autoload_pk is set from the primary DB {id} field at construction');
	isnt($j->{_autoload_pk}, $JC,
		'_autoload_pk differs from join_column when the primary DB has its own id');
};

subtest 'new: remove_columns applied immediately' => sub {
	plan tests => 2;
	my $db = MinimalDA->new(cols => [$JC, $COL_A, $COL_C], rows => []);
	my $j  = Database::Join->new(
		databases      => [$db],
		join_column    => $JC,
		remove_columns => [$COL_C],
	);
	ok(exists $j->{_removed_cols}{$COL_C},  'removed column is in _removed_cols');
	ok(!exists $j->{_col_db}{$COL_C},       'removed column is absent from _col_db');
};

subtest 'new: filters and join_map stored in object' => sub {
	plan tests => 2;
	my $db0 = MinimalDA->new(cols => [$JC,       $COL_A], rows => []);
	my $db1 = MinimalDA->new(cols => [$JC_ALIAS, $COL_B], rows => []);
	my $j   = Database::Join->new(
		databases   => [$db0, $db1],
		join_column => $JC,
		join_map    => { 1 => $JC_ALIAS },
		filters     => { 0 => { name => 'Alice' } },
	);
	is_deeply($j->{_join_map}, { 1 => $JC_ALIAS },       'join_map stored verbatim');
	is_deeply($j->{_filters},  { 0 => { name => 'Alice' } }, 'filters stored verbatim');
};

# ===========================================================================
# SECTION 5 -- columns() (5 tests)
# Tests the memoised, sorted, deduplicated column list.
# ===========================================================================
subtest 'columns: sorted alphabetically' => sub {
	plan tests => 1;
	my $j    = _make_join();
	my $cols = $j->columns();
	my @sorted = sort @{$cols};
	is_deeply($cols, \@sorted, 'columns() returns column names in ascending alphabetical order');
};

subtest 'columns: join_col appears exactly once' => sub {
	plan tests => 1;
	my $j     = _make_join();
	my $count = grep { $_ eq $JC } @{ $j->columns() };
	is($count, 1, 'join_column appears exactly once in columns() even though both DBs have it');
};

subtest 'columns: removed column is absent' => sub {
	plan tests => 1;
	my $j = _make_join();
	$j->remove_column($COL_C);
	ok(!grep { $_ eq $COL_C } @{ $j->columns() }, 'removed column does not appear in columns()');
};

subtest 'columns: memoised -- repeated call returns same arrayref' => sub {
	plan tests => 1;
	my $j     = _make_join();
	my $first = $j->columns();
	my $second = $j->columns();
	is(refaddr($first), refaddr($second), 'columns() returns the same cached arrayref on repeated calls');
};

subtest 'columns: cache invalidated by remove_column' => sub {
	plan tests => 2;
	my $j     = _make_join();
	my $first = $j->columns();
	$j->remove_column($COL_C);
	my $second = $j->columns();
	isnt(refaddr($first), refaddr($second), 'remove_column() invalidates the columns() cache');
	ok(!grep { $_ eq $COL_C } @{$second}, 'freshly rebuilt columns() omits the removed column');
};

# ===========================================================================
# SECTION 6 -- schema() (5 tests)
# Tests the memoised merged schema hashref.
# ===========================================================================
subtest 'schema: merged from all DBs' => sub {
	plan tests => 2;
	my $j = _make_join();
	my $s = $j->schema();
	returns_ok($s, { type => 'hashref' }, 'schema() returns a hashref');
	ok(exists $s->{$COL_B}, 'secondary DB column appears in merged schema');
};

subtest 'schema: removed column absent' => sub {
	plan tests => 1;
	my $j = _make_join();
	$j->remove_column($COL_C);
	ok(!exists $j->schema()->{$COL_C}, 'removed column is absent from schema()');
};

subtest 'schema: join_map local alias excluded' => sub {
	plan tests => 1;
	my $db0 = MinimalDA->new(cols => [$JC, $COL_A], rows => [],
		schema => { $JC => {}, $COL_A => {} });
	my $db1 = MinimalDA->new(cols => [$JC_ALIAS, $COL_B], rows => [],
		schema => { $JC_ALIAS => {}, $COL_B => {} });
	my $j   = Database::Join->new(
		databases   => [$db0, $db1],
		join_column => $JC,
		join_map    => { 1 => $JC_ALIAS },
	);
	ok(!exists $j->schema()->{$JC_ALIAS},
		'join_map local alias is excluded from the merged schema');
};

subtest 'schema: last DB wins for duplicate column metadata' => sub {
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
		'last database wins when the same column appears in multiple databases');
};

subtest 'schema: memoised' => sub {
	plan tests => 1;
	my $j     = _make_join();
	my $first  = $j->schema();
	my $second = $j->schema();
	is(refaddr($first), refaddr($second), 'schema() returns the same cached hashref on repeated calls');
};

# ===========================================================================
# SECTION 7 -- updated() (3 tests)
# Tests that updated() returns the maximum across all component databases.
# ===========================================================================
subtest 'updated: returns max of all component timestamps' => sub {
	plan tests => 1;
	my $j = _make_join();
	is($j->updated(), $TS_B,
		'updated() returns the largest timestamp from any component database');
};

subtest 'updated: single DB returns its own timestamp' => sub {
	plan tests => 1;
	my $db = MinimalDA->new(cols => [$JC], rows => [], updated => $TS_A);
	my $j  = Database::Join->new(databases => [$db], join_column => $JC);
	is($j->updated(), $TS_A, 'updated() with a single DB returns that DB timestamp');
};

subtest 'updated: return type is a scalar number' => sub {
	plan tests => 1;
	my $j = _make_join();
	returns_ok($j->updated(), { type => 'integer' }, 'updated() returns an integer scalar');
};

# ===========================================================================
# SECTION 8 -- set_logger() (4 tests)
# ===========================================================================
subtest 'set_logger: croak on undef logger' => sub {
	plan tests => 1;
	my $j = _make_join();
	throws_ok { $j->set_logger(undef) }
		qr/Usage: set_logger/,
		'set_logger() croaks when called with undef';
};

subtest 'set_logger: stores logger in self' => sub {
	plan tests => 1;
	my $j   = _make_join();
	my $log = bless {}, 'FakeLogger';
	$j->set_logger($log);
	is(refaddr($j->{_logger}), refaddr($log), 'set_logger() stores the logger object in _logger');
};

subtest 'set_logger: propagates to all component DBs' => sub {
	plan tests => 1;
	my $j    = _make_join();
	my $log  = bless {}, 'FakeLogger';
	$j->set_logger($log);
	# Verify at least one component DB received the logger via MinimalDA::set_logger
	is(refaddr($j->{_dbs}[0]{_logger}), refaddr($log),
		'set_logger() propagates the logger to the primary component database');
};

subtest 'set_logger: returns self for chaining' => sub {
	plan tests => 1;
	my $j   = _make_join();
	my $log = bless {}, 'FakeLogger';
	is(refaddr($j->set_logger($log)), refaddr($j), 'set_logger() returns $self for method chaining');
};

# ===========================================================================
# SECTION 9 -- remove_column() (7 tests)
# ===========================================================================
subtest 'remove_column: croaks when trying to remove join_column' => sub {
	plan tests => 1;
	my $j = _make_join();
	throws_ok { $j->remove_column($JC) }
		qr/Cannot remove join_column/,
		'remove_column() croaks when the column to remove is the join key';
};

subtest 'remove_column: marks column in _removed_cols' => sub {
	plan tests => 1;
	my $j = _make_join();
	$j->remove_column($COL_A);
	ok($j->{_removed_cols}{$COL_A}, 'remove_column() adds the column to _removed_cols');
};

subtest 'remove_column: removes column from _col_db' => sub {
	plan tests => 1;
	my $j = _make_join();
	$j->remove_column($COL_A);
	ok(!exists $j->{_col_db}{$COL_A}, 'remove_column() deletes the column from _col_db routing table');
};

subtest 'remove_column: invalidates _col_cache' => sub {
	plan tests => 2;
	my $j = _make_join();
	$j->columns();  # prime cache
	ok(defined $j->{_col_cache}, 'precondition: _col_cache is populated before remove_column');
	$j->remove_column($COL_A);
	ok(!defined $j->{_col_cache}, 'remove_column() clears _col_cache');
};

subtest 'remove_column: invalidates _schema_cache' => sub {
	plan tests => 2;
	my $j = _make_join();
	$j->schema();   # prime cache
	ok(defined $j->{_schema_cache}, 'precondition: _schema_cache is populated');
	$j->remove_column($COL_A);
	ok(!defined $j->{_schema_cache}, 'remove_column() clears _schema_cache');
};

subtest 'remove_column: idempotent -- double removal is safe' => sub {
	plan tests => 1;
	my $j = _make_join();
	$j->remove_column($COL_C);
	lives_ok { $j->remove_column($COL_C) }
		'remove_column() can be called twice on the same column without croaking';
};

subtest 'remove_column: returns self for chaining' => sub {
	plan tests => 1;
	my $j = _make_join();
	is(refaddr($j->remove_column($COL_C)), refaddr($j), 'remove_column() returns $self for chaining');
};

# ===========================================================================
# SECTION 10 -- add_database() (9 tests)
# ===========================================================================
subtest 'add_database: positional form adds the database' => sub {
	plan tests => 1;
	my $j   = _make_join();
	my $db3 = MinimalDA->new(cols => [$JC, 'extra'], rows => []);
	$j->add_database($db3);
	is(scalar @{ $j->{_dbs} }, 3, 'add_database() positional form appends the new database');
};

subtest 'add_database: named form (database => $db) works' => sub {
	plan tests => 1;
	my $j   = _make_join();
	my $db3 = MinimalDA->new(cols => [$JC, 'extra'], rows => []);
	$j->add_database(database => $db3);
	is(scalar @{ $j->{_dbs} }, 3, 'add_database() named form appends the new database');
};

subtest 'add_database: non-reference first arg that is not a key name croaks' => sub {
	plan tests => 1;
	my $j = _make_join();
	throws_ok { $j->add_database('not_a_key') }
		qr/not a Database::Abstraction/i,
		'add_database() croaks when an unrecognised string is the first argument';
};

subtest 'add_database: non-DA blessed object croaks' => sub {
	plan tests => 1;
	my $j = _make_join();
	throws_ok { $j->add_database(bless {}, 'WrongClass') }
		qr/not a Database::Abstraction/i,
		'add_database() croaks when the database object is not a DA subclass';
};

subtest 'add_database: missing join column croaks' => sub {
	plan tests => 1;
	my $j   = _make_join();
	my $bad = MinimalDA->new(cols => ['other'], rows => []);
	throws_ok { $j->add_database($bad) }
		qr/absent from databases\[2\]/,
		'add_database() croaks when the new database lacks the join_column';
};

subtest 'add_database: join_column option stored in _join_map' => sub {
	plan tests => 1;
	my $j   = _make_join();
	my $db3 = MinimalDA->new(cols => [$JC_ALIAS, 'extra'], rows => []);
	$j->add_database($db3, join_column => $JC_ALIAS);
	is($j->{_join_map}{2}, $JC_ALIAS,
		'add_database() registers the join_column alias in _join_map at the new DB index');
};

subtest 'add_database: filter option stored in _filters' => sub {
	plan tests => 1;
	my $j   = _make_join();
	my $db3 = MinimalDA->new(cols => [$JC, 'level'], rows => []);
	my $f   = { level => { '>' => 5 } };
	$j->add_database($db3, filter => $f);
	is_deeply($j->{_filters}{2}, $f, 'add_database() stores the filter in _filters for the new DB index');
};

subtest 'add_database: invalidates caches' => sub {
	plan tests => 2;
	my $j = _make_join();
	$j->columns(); $j->schema();  # prime caches
	my $db3 = MinimalDA->new(cols => [$JC, 'new_col'], rows => []);
	$j->add_database($db3);
	ok(!defined $j->{_col_cache},    'add_database() clears _col_cache');
	ok(!defined $j->{_schema_cache}, 'add_database() clears _schema_cache');
};

subtest 'add_database: returns self for chaining' => sub {
	plan tests => 1;
	my $j   = _make_join();
	my $db3 = MinimalDA->new(cols => [$JC], rows => []);
	is(refaddr($j->add_database($db3)), refaddr($j), 'add_database() returns $self for chaining');
};

# ===========================================================================
# SECTION 11 -- _partition_criteria (5 tests)
# ===========================================================================
subtest '_partition_criteria: non-join column routed to owning DB only' => sub {
	plan tests => 2;
	my $wb = _bare_whitebox(
		_dbs    => [
			MinimalDA->new(cols => [$JC, $COL_A], rows => []),
			MinimalDA->new(cols => [$JC, $COL_B], rows => []),
		],
		_col_db => { $JC => 0, $COL_A => 0, $COL_B => 1 },
	);
	my $result = $wb->expose_partition({ $COL_A => 'Alice' });
	is_deeply($result->[0], { $COL_A => 'Alice' }, 'primary DB receives the criterion');
	is_deeply($result->[1], {},                     'secondary DB receives no criterion');
};

subtest '_partition_criteria: join_col broadcast to all DBs' => sub {
	plan tests => 2;
	my $wb = _bare_whitebox(
		_dbs    => [
			MinimalDA->new(cols => [$JC, $COL_A], rows => []),
			MinimalDA->new(cols => [$JC, $COL_B], rows => []),
		],
		_col_db => { $JC => 0, $COL_A => 0, $COL_B => 1 },
	);
	my $result = $wb->expose_partition({ $JC => 'K1' });
	ok(exists $result->[0]{$JC}, 'join_col criterion broadcast to primary DB');
	ok(exists $result->[1]{$JC}, 'join_col criterion broadcast to secondary DB');
};

subtest '_partition_criteria: operator hashref broadcast is shallow-copied' => sub {
	plan tests => 1;
	# Each recipient must receive an independent copy of the hashref so a
	# malicious DA cannot corrupt other DAs by mutating the hashref contents.
	my $wb = _bare_whitebox(
		_dbs    => [
			MinimalDA->new(cols => [$JC, $COL_A], rows => []),
			MinimalDA->new(cols => [$JC, $COL_B], rows => []),
		],
		_col_db => { $JC => 0, $COL_A => 0, $COL_B => 1 },
	);
	my $op     = { '>' => 'K0' };
	my $result = $wb->expose_partition({ $JC => $op });
	isnt(refaddr($result->[0]{$JC}), refaddr($result->[1]{$JC}),
		'each DB receives an independent copy of the broadcast operator hashref');
};

subtest '_partition_criteria: unknown column produces carp, not sent to any DB' => sub {
	plan tests => 2;
	my $wb = _bare_whitebox(
		_dbs    => [ MinimalDA->new(cols => [$JC], rows => []) ],
		_col_db => { $JC => 0 },
	);
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $result = $wb->expose_partition({ no_such_col => 'x' });
	ok(@warnings,                          'unknown column triggers a carp warning');
	ok(!exists $result->[0]{no_such_col}, 'unknown column is not sent to any DB');
};

subtest '_partition_criteria: join_map alias used in broadcast' => sub {
	plan tests => 1;
	my $wb = _bare_whitebox(
		_join_col => $JC,
		_join_map => { 1 => $JC_ALIAS },
		_dbs      => [
			MinimalDA->new(cols => [$JC,       $COL_A], rows => []),
			MinimalDA->new(cols => [$JC_ALIAS, $COL_B], rows => []),
		],
		_col_db   => { $JC => 0, $COL_A => 0, $COL_B => 1 },
	);
	my $result = $wb->expose_partition({ $JC => 'K1' });
	ok(exists $result->[1]{$JC_ALIAS},
		'join_col broadcast uses the local alias for the DB registered in join_map');
};

# ===========================================================================
# SECTION 12 -- _fetch_indexed (4 tests)
# ===========================================================================
subtest '_fetch_indexed: indexes rows by join_col value' => sub {
	plan tests => 2;
	my $db = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'K1', name => 'Alice' },
			{ entry => 'K2', name => 'Bob' },
		],
	);
	my $wb  = _bare_whitebox(_dbs => [$db], _join_map => {});
	my $idx = $wb->expose_fetch_indexed(0, {});
	is(scalar keys %{$idx}, 2,               '_fetch_indexed produces one bucket per distinct key');
	is($idx->{K1}[0]{name}, 'Alice',         'correct row accessible under its join_col value');
};

subtest '_fetch_indexed: row with undef join key is skipped' => sub {
	plan tests => 1;
	my $db = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [ { entry => undef, name => 'Ghost' } ],
	);
	my $wb  = _bare_whitebox(_dbs => [$db], _join_map => {});
	my $idx = $wb->expose_fetch_indexed(0, {});
	is(scalar keys %{$idx}, 0, 'row with undef join_col value is silently skipped');
};

subtest '_fetch_indexed: uses join_map alias for indexing' => sub {
	plan tests => 1;
	my $db = MinimalDA->new(
		cols => [$JC_ALIAS, $COL_B],
		rows => [ { $JC_ALIAS => 'K1', score => 99 } ],
	);
	my $wb  = _bare_whitebox(_dbs => [$db], _join_map => { 0 => $JC_ALIAS });
	my $idx = $wb->expose_fetch_indexed(0, {});
	ok(exists $idx->{K1}, '_fetch_indexed uses the join_map alias to index rows correctly');
};

subtest '_fetch_indexed: DA returning undef treated as empty' => sub {
	plan tests => 1;
	my $db = bless {
		_cols => [$JC],
		_schema => {},
		_ts => 1,
		_rows => [],
	}, 'MinimalDA';
	# Override selectall_arrayref to return undef (simulates DA corner case)
	my $orig;
	mock 'MinimalDA::selectall_arrayref' => sub { return undef };
	my $wb  = _bare_whitebox(_dbs => [$db], _join_map => {});
	my $idx = $wb->expose_fetch_indexed(0, {});
	is(scalar keys %{$idx}, 0, '_fetch_indexed handles undef return from DA gracefully');
	restore_all();
};

# ===========================================================================
# SECTION 13 -- selectall_arrayref, selectall_array, fetchrow_hashref, count
# ===========================================================================
subtest 'selectall_arrayref: returns arrayref of hashrefs' => sub {
	plan tests => 2;
	my $j    = _make_join();
	my $rows = $j->selectall_arrayref();
	returns_ok($rows, { type => 'arrayref' }, 'selectall_arrayref returns an arrayref');
	is(scalar @{$rows}, 2, 'all rows returned when no criteria');
};

subtest 'selectall_arrayref: rows contain merged columns' => sub {
	plan tests => 2;
	my $j    = _make_join();
	my $rows = $j->selectall_arrayref(entry => 'K1');
	is(scalar @{$rows}, 1, 'one row matches entry=K1');
	is($rows->[0]{name}, 'Alice', 'primary DB column present in merged row');
};

subtest 'selectall_arrayref: positional shorthand (single scalar)' => sub {
	plan tests => 1;
	my $j    = _make_join();
	my $rows = $j->selectall_arrayref('K2');
	is($rows->[0]{name}, 'Bob', 'single scalar arg is treated as join_col value');
};

subtest 'selectall_array: list context returns all rows as list' => sub {
	plan tests => 1;
	my $j    = _make_join();
	my @rows = $j->selectall_array();
	is(scalar @rows, 2, 'selectall_array in list context returns all rows as a flat list');
};

subtest 'selectall_array: scalar context returns first row' => sub {
	plan tests => 2;
	my $j    = _make_join();
	my $first = $j->selectall_array();
	ok(defined $first,      'selectall_array in scalar context returns a defined value');
	ok(ref $first eq 'HASH', 'selectall_array scalar context result is a hashref');
};

subtest 'fetchrow_hashref: returns first matching row' => sub {
	plan tests => 1;
	my $j   = _make_join();
	my $row = $j->fetchrow_hashref('K1');
	is($row->{name}, 'Alice', 'fetchrow_hashref returns the correct matching row');
};

subtest 'fetchrow_hashref: returns undef when no row matches' => sub {
	plan tests => 1;
	my $j   = _make_join();
	my $row = $j->fetchrow_hashref('NOMATCH');
	ok(!defined $row, 'fetchrow_hashref returns undef when no row matches the criteria');
};

subtest 'count: returns integer count' => sub {
	plan tests => 2;
	my $j = _make_join();
	returns_ok($j->count(), { type => 'integer' }, 'count() returns an integer');
	is($j->count(), 2, 'count() returns the correct row count with no criteria');
};

subtest 'count: count with criteria' => sub {
	plan tests => 1;
	my $j = _make_join();
	is($j->count(entry => 'K1'), 1, 'count() with criteria returns the filtered row count');
};

# ===========================================================================
# SECTION 14 -- _joined_query join semantics (6 tests)
# ===========================================================================
subtest '_joined_query: left join -- primary key set, secondary fills in' => sub {
	plan tests => 2;
	my $db_a = MinimalDA->new(cols => [$JC, $COL_A],
		rows => [ { entry => 'K1', name => 'Alice' },
		          { entry => 'K3', name => 'Charlie' } ]);
	my $db_b = MinimalDA->new(cols => [$JC, $COL_B],
		rows => [ { entry => 'K1', score => 95 } ]);
	my $j = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		join_type   => 'left',
	);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 2, 'left join includes both primary rows');
	ok(!defined $rows->[1]{score}, 'secondary column is undef for primary row with no secondary match');
};

subtest '_joined_query: inner join -- only shared keys returned' => sub {
	plan tests => 1;
	my $db_a = MinimalDA->new(cols => [$JC, $COL_A],
		rows => [ { entry => 'K1', name => 'Alice' },
		          { entry => 'K3', name => 'Charlie' } ]);
	my $db_b = MinimalDA->new(cols => [$JC, $COL_B],
		rows => [ { entry => 'K1', score => 95 } ]);
	my $j = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		join_type   => 'inner',
	);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 1, 'inner join returns only keys present in every database');
};

subtest '_joined_query: outer join -- all keys from any database' => sub {
	plan tests => 2;
	my $db_a = MinimalDA->new(cols => [$JC, $COL_A],
		rows => [ { entry => 'K1', name => 'Alice' } ]);
	my $db_b = MinimalDA->new(cols => [$JC, $COL_B],
		rows => [ { entry => 'K1', score => 95 }, { entry => 'K9', score => 10 } ]);
	my $j = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		join_type   => 'outer',
	);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 2, 'outer join returns keys from both databases');
	my ($k9) = grep { $_->{entry} eq 'K9' } @{$rows};
	ok(!defined $k9->{name}, 'outer-only key has undef primary column');
};

subtest '_joined_query: filter overlay gives inner semantics regardless of join_type' => sub {
	plan tests => 1;
	my $j = Database::Join->new(
		databases   => [
			MinimalDA->new(cols => [$JC, $COL_A], rows => [
				{ entry => 'K1', name => 'Alice' },
				{ entry => 'K2', name => 'Bob' },
			]),
			MinimalDA->new(cols => [$JC, $COL_B], rows => [
				{ entry => 'K1', score => 95 },
			]),
		],
		join_column => $JC,
		join_type   => 'left',
		# Filter on DB 1 makes it an inner partner -- K2 is excluded
		filters     => { 1 => { entry => 'K1' } },
	);
	my $rows = $j->selectall_arrayref();
	is(scalar @{$rows}, 1, 'filtered secondary DB acts as inner partner, K2 excluded');
};

subtest '_joined_query: removed columns stripped from result rows' => sub {
	plan tests => 1;
	my $j = _make_join();
	$j->remove_column($COL_C);
	my $rows = $j->selectall_arrayref();
	ok(!exists $rows->[0]{$COL_C}, 'removed column is absent from every merged result row');
};

subtest '_joined_query: join_map alias renamed to canonical in merged row' => sub {
	plan tests => 2;
	my $db0 = MinimalDA->new(cols => [$JC, $COL_A],
		rows => [ { entry => 'K1', name => 'Alice' } ]);
	my $db1 = MinimalDA->new(cols => [$JC_ALIAS, $COL_B],
		rows => [ { $JC_ALIAS => 'K1', score => 99 } ]);
	my $j   = Database::Join->new(
		databases   => [$db0, $db1],
		join_column => $JC,
		join_map    => { 1 => $JC_ALIAS },
	);
	my $row = $j->fetchrow_hashref('K1');
	ok(!exists $row->{$JC_ALIAS},  'join_map local alias not exposed in merged row');
	is($row->{$JC}, 'K1',          'canonical join_column present in merged row with correct value');
};

# ===========================================================================
# SECTION 15 -- query() and execute() stubs (2 tests)
# ===========================================================================
subtest 'query: always croaks with explanatory message' => sub {
	plan tests => 1;
	my $j = _make_join();
	throws_ok { $j->query() }
		qr/not supported/i,
		'query() always croaks (chained builder is not implemented)';
};

subtest 'execute: always croaks with explanatory message' => sub {
	plan tests => 1;
	my $j = _make_join();
	throws_ok { $j->execute() }
		qr/not supported/i,
		'execute() always croaks (raw SQL is not implemented)';
};

# ===========================================================================
# SECTION 16 -- AUTOLOAD (6 tests)
# ===========================================================================
subtest 'AUTOLOAD: DESTROY is silently ignored (no croak)' => sub {
	plan tests => 1;
	my $j = _make_join();
	lives_ok { $j->DESTROY() } 'DESTROY does not croak via AUTOLOAD';
};

subtest 'AUTOLOAD: private method name (leading _) croaks immediately' => sub {
	plan tests => 1;
	my $j = _make_join();
	throws_ok { $j->_some_private_method() }
		qr/cannot call private method/i,
		'AUTOLOAD rejects private method names (leading underscore)';
};

subtest 'AUTOLOAD: unknown column name croaks' => sub {
	plan tests => 1;
	my $j = _make_join();
	throws_ok { $j->no_such_column() }
		qr/unknown column/i,
		'AUTOLOAD croaks when the method name is not a known column';
};

subtest 'AUTOLOAD: direct delegation when no join_map and no filters (scalar)' => sub {
	plan tests => 1;
	# Without join_map/filters, AUTOLOAD delegates to the owning DA directly.
	# The owning DA for 'score' is db_b; $j->score('K1') calls $db_b->score('K1').
	my $db_a = MinimalDA->new(cols => [$JC, $COL_A], rows => []);
	my $db_b = MinimalDA->new(cols => [$JC, $COL_B], rows => []);
	mock 'MinimalDA::score' => sub { return 'mocked_score' };
	my $j   = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
	);
	my $val = $j->score('K1');
	is($val, 'mocked_score', 'AUTOLOAD delegates directly to the owning DA when no join_map/filters');
	restore_all();
};

subtest 'AUTOLOAD: uses _joined_query when join_map is active (scalar context)' => sub {
	plan tests => 1;
	my $db_a = MinimalDA->new(cols => [$JC, $COL_A],
		rows => [ { entry => 'K1', name => 'Alice' } ]);
	my $db_b = MinimalDA->new(cols => [$JC_ALIAS, $COL_B],
		rows => [ { $JC_ALIAS => 'K1', score => 88 } ]);
	my $j = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		join_map    => { 1 => $JC_ALIAS },
	);
	# join_map is active, so AUTOLOAD must run _joined_query and return the
	# column value from the merged row rather than delegating directly to db_b.
	my $score = $j->score('K1');   # 'K1' is the entry (primary key of db_a)
	is($score, 88, 'AUTOLOAD routes through _joined_query when join_map is active');
};

subtest 'AUTOLOAD: list context returns all matching values when join_map active' => sub {
	plan tests => 1;
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'K1', name => 'Alice' },
			{ entry => 'K2', name => 'Bob' },
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
		filters     => { 1 => { entry => 'K1' } },  # activate full-join AUTOLOAD path
	);
	my @scores = $j->score();
	is_deeply([sort { $a <=> $b } @scores], [95],
		'AUTOLOAD list context returns all matching column values via _joined_query');
};

# ===========================================================================
# SECTION 17 -- Memory cycles (1 test)
# ===========================================================================
subtest 'no circular references in Database::Join object' => sub {
	plan tests => 1;
	my $j = _make_join();
	memory_cycle_ok($j, 'Database::Join has no circular references that would prevent GC');
};

# ===========================================================================
# SECTION 18 -- _err helper (3 tests)
# _err is a thin convenience wrapper around _msg that reads _i18n from self
# so callers do not have to extract it at every error site.  Testing it
# separately proves the coupling to $self->{_i18n} is correct.
# ===========================================================================
subtest '_err: produces the same string as _msg when _i18n is undef' => sub {
	plan tests => 1;
	my $wb       = _bare_whitebox();  # _i18n is undef
	my $from_err = $wb->expose_err('error_no_databases');
	my $from_msg = $wb->expose_msg(undef, 'error_no_databases');
	is($from_err, $from_msg,
		'_err() produces the same result as _msg() when _i18n is undef');
};

subtest '_err: reads _i18n from self automatically (no explicit arg needed)' => sub {
	plan tests => 1;
	# Build an i18n stub that prefixes every message key with "i18n:".
	# _err should pick up self->{_i18n} without the caller supplying it.
	my $i18n = bless {}, 'AutoI18N';
	{
		no strict 'refs';
		*AutoI18N::can = sub { $_[1] eq 'translate' ? sub {} : undef };
		*AutoI18N::translate = sub { "i18n:$_[1]" };
	}
	my $wb  = _bare_whitebox(_i18n => $i18n);
	my $got = $wb->expose_err('error_no_databases');
	is($got, 'i18n:error_no_databases',
		'_err() reads _i18n from $self->{_i18n} without the caller passing it');
};

subtest '_err: passes sprintf args through to the message formatter' => sub {
	plan tests => 1;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_err('error_invalid_db', 7);
	like($got, qr/databases\[7\]/,
		'_err() passes sprintf args through to the underlying message string');
};

# ===========================================================================
# SECTION 19 -- _build_col_index (6 tests)
# _build_col_index is the most complex constructor step: it populates _col_db
# (column-to-db-index routing) and _db_cols (per-db column presence) from
# the columns() of each component database, validates the join key is present,
# and applies join_map aliases.  Testing it directly (via expose_build_col_index)
# isolates construction-time logic from the rest of new().
# ===========================================================================
subtest '_build_col_index: populates _col_db with correct database indices' => sub {
	plan tests => 2;
	# db_a owns COL_A; db_b owns COL_B.  After indexing, _col_db must reflect
	# last-DB-wins for the shared join_col and correct indices for unique cols.
	my $wb = _bare_whitebox(
		_join_col => $JC,
		_join_map => {},
		_dbs      => [
			MinimalDA->new(cols => [$JC, $COL_A], rows => []),
			MinimalDA->new(cols => [$JC, $COL_B], rows => []),
		],
		_col_db   => {},
		_db_cols  => [],
	);
	$wb->expose_build_col_index();
	is($wb->{_col_db}{$COL_A}, 0,
		'_build_col_index routes COL_A to DB 0 (first database)');
	is($wb->{_col_db}{$COL_B}, 1,
		'_build_col_index routes COL_B to DB 1 (second database)');
};

subtest '_build_col_index: populates _db_cols with per-db column presence hashes' => sub {
	plan tests => 2;
	my $wb = _bare_whitebox(
		_join_col => $JC,
		_join_map => {},
		_dbs      => [
			MinimalDA->new(cols => [$JC, $COL_A], rows => []),
			MinimalDA->new(cols => [$JC, $COL_B], rows => []),
		],
		_col_db   => {},
		_db_cols  => [],
	);
	$wb->expose_build_col_index();
	ok($wb->{_db_cols}[0]{$COL_A},
		'_db_cols[0] shows COL_A is present in DB 0');
	ok($wb->{_db_cols}[1]{$COL_B},
		'_db_cols[1] shows COL_B is present in DB 1');
};

subtest '_build_col_index: last-DB-wins for duplicate non-join columns' => sub {
	plan tests => 1;
	# Both databases have COL_A.  After indexing, _col_db should point to DB 1.
	my $wb = _bare_whitebox(
		_join_col => $JC,
		_join_map => {},
		_dbs      => [
			MinimalDA->new(cols => [$JC, $COL_A], rows => []),
			MinimalDA->new(cols => [$JC, $COL_A], rows => []),
		],
		_col_db   => {},
		_db_cols  => [],
	);
	$wb->expose_build_col_index();
	is($wb->{_col_db}{$COL_A}, 1,
		'_build_col_index last-DB-wins: duplicate column is owned by the later database');
};

subtest '_build_col_index: join_map local alias excluded from _col_db' => sub {
	plan tests => 2;
	# DB 1 uses $JC_ALIAS as its join key.  That alias is NOT a data column
	# and must not appear in _col_db; the canonical join_col name must appear.
	my $wb = _bare_whitebox(
		_join_col => $JC,
		_join_map => { 1 => $JC_ALIAS },
		_dbs      => [
			MinimalDA->new(cols => [$JC,       $COL_A], rows => []),
			MinimalDA->new(cols => [$JC_ALIAS, $COL_B], rows => []),
		],
		_col_db   => {},
		_db_cols  => [],
	);
	$wb->expose_build_col_index();
	ok(!exists $wb->{_col_db}{$JC_ALIAS},
		'_build_col_index excludes the join_map local alias from _col_db');
	is($wb->{_col_db}{$COL_B}, 1,
		'_build_col_index still routes data columns from the join_map DB correctly');
};

subtest '_build_col_index: croaks when join_column is absent from a database' => sub {
	plan tests => 1;
	my $wb = _bare_whitebox(
		_join_col => $JC,
		_join_map => {},
		_dbs      => [
			MinimalDA->new(cols => ['other_col'], rows => []),
		],
		_col_db   => {},
		_db_cols  => [],
	);
	throws_ok { $wb->expose_build_col_index() }
		qr/absent from databases\[0\]/,
		'_build_col_index croaks when join_column is missing from a component database';
};

subtest '_build_col_index: croaks when join_map value is a reference (heap-address guard)' => sub {
	plan tests => 1;
	# A reference as the local join-key name would stringify to "HASH(0x...)",
	# leaking a heap address into the error message.  The guard must croak first.
	my $wb = _bare_whitebox(
		_join_col => $JC,
		_join_map => { 1 => { ref_val => 1 } },   # value is a hashref, not a string
		_dbs      => [
			MinimalDA->new(cols => [$JC, $COL_A], rows => []),
			MinimalDA->new(cols => [$JC, $COL_B], rows => []),
		],
		_col_db   => {},
		_db_cols  => [],
	);
	throws_ok { $wb->expose_build_col_index() }
		qr/absent from databases\[1\]/,
		'_build_col_index croaks cleanly when a join_map value is a reference';
};

# ===========================================================================
# SECTION 20 -- Additional %MESSAGES key coverage (4 tests)
# The %MESSAGES dictionary defines all user-facing strings.  Sections 1-16
# tested error_no_databases, error_invalid_db, and error_join_col_missing.
# These tests cover the remaining documented message keys.
# ===========================================================================
subtest '_msg: warn_unknown_column contains the column name' => sub {
	plan tests => 1;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_msg(undef, 'warn_unknown_column', 'mystery_col');
	like($got, qr/mystery_col/,
		'warn_unknown_column message embeds the unrecognised column name');
};

subtest '_msg: error_query_unsupported mentions query()' => sub {
	plan tests => 1;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_msg(undef, 'error_query_unsupported');
	like($got, qr/query\(\)/,
		'error_query_unsupported message identifies the unsupported method');
};

subtest '_msg: error_execute_unsupported mentions execute()' => sub {
	plan tests => 1;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_msg(undef, 'error_execute_unsupported');
	like($got, qr/execute\(\)/,
		'error_execute_unsupported message identifies the unsupported method');
};

subtest '_msg: error_remove_join_col embeds the column name' => sub {
	plan tests => 1;
	my $wb  = _bare_whitebox();
	my $got = $wb->expose_msg(undef, 'error_remove_join_col', 'my_join_key');
	like($got, qr/my_join_key/,
		'error_remove_join_col message embeds the column name that was passed');
};

# ===========================================================================
# SECTION 21 -- Global variable isolation (3 tests)
# Public query methods and internal helpers use map/for/grep internally.
# Setting $_ to a sentinel before the call and checking it after guarantees
# that the implementation does not accidentally clobber caller-owned globals.
# ===========================================================================
subtest 'selectall_arrayref: does not clobber $_' => sub {
	plan tests => 1;
	my $j = _make_join();
	local $_ = 'caller_sentinel';
	$j->selectall_arrayref(entry => 'K1');
	is($_, 'caller_sentinel',
		'selectall_arrayref() does not modify $_ in the calling scope');
};

subtest '_partition_criteria: does not clobber $_' => sub {
	plan tests => 1;
	my $wb = _bare_whitebox(
		_dbs    => [
			MinimalDA->new(cols => [$JC, $COL_A], rows => []),
			MinimalDA->new(cols => [$JC, $COL_B], rows => []),
		],
		_col_db => { $JC => 0, $COL_A => 0, $COL_B => 1 },
	);
	local $_ = 'caller_sentinel';
	$wb->expose_partition({ $COL_A => 'Alice' });
	is($_, 'caller_sentinel',
		'_partition_criteria() does not modify $_ in the calling scope');
};

subtest '_joined_query: does not clobber $_ (exercised via selectall_arrayref)' => sub {
	plan tests => 1;
	my $j = _make_join();
	local $_ = 'caller_sentinel';
	$j->selectall_arrayref();
	is($_, 'caller_sentinel',
		'_joined_query() does not modify $_ in the calling scope');
};

# ===========================================================================
# SECTION 22 -- _fetch_indexed additional coverage (3 tests)
# These tests address gaps in Section 12: the return type, multiple rows
# stored under the same join-key bucket, and the critical requirement that
# criteria are passed to the DA as a hashref (not a flat hash expansion).
# ===========================================================================
subtest '_fetch_indexed: return type is a hashref' => sub {
	plan tests => 1;
	my $db  = MinimalDA->new(cols => [$JC, $COL_A], rows => []);
	my $wb  = _bare_whitebox(_dbs => [$db], _join_map => {});
	my $idx = $wb->expose_fetch_indexed(0, {});
	returns_ok($idx, { type => 'hashref' },
		'_fetch_indexed returns a hashref keyed on join_col values');
};

subtest '_fetch_indexed: multiple rows with the same join_col value are all stored' => sub {
	plan tests => 2;
	# When a DA returns two rows with identical join keys (e.g. a city appearing
	# in two states), both must be preserved in the indexed bucket.
	my $db = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [
			{ entry => 'K1', name => 'Alice' },
			{ entry => 'K1', name => 'AlsoAlice' },
		],
	);
	my $wb  = _bare_whitebox(_dbs => [$db], _join_map => {});
	my $idx = $wb->expose_fetch_indexed(0, {});
	is(scalar @{ $idx->{K1} }, 2,
		'both rows stored under the K1 bucket (not deduplicated)');
	is($idx->{K1}[1]{name}, 'AlsoAlice',
		'second row is accessible at index 1 in the bucket');
};

subtest '_fetch_indexed: passes criteria as a hashref to DA->selectall_arrayref' => sub {
	plan tests => 1;
	# CLAUDE.md: "Always pass criteria to Database::Abstraction methods as a
	# hashref, never as a flat hash expansion" -- verify via Mockingbird.
	my $received;
	my $db = MinimalDA->new(cols => [$JC, $COL_A], rows => []);
	mock 'MinimalDA::selectall_arrayref' => sub { $received = $_[1]; return [] };
	my $wb       = _bare_whitebox(_dbs => [$db], _join_map => {});
	my $criteria = { $COL_A => 'Alice' };
	$wb->expose_fetch_indexed(0, $criteria);
	is_deeply($received, $criteria,
		'_fetch_indexed passes the criteria hashref verbatim to DA->selectall_arrayref');
	restore_all();
};

# ===========================================================================
# SECTION 23 -- updated() with Mockingbird (2 tests)
# These tests use Mockingbird to intercept Database::Join::max (the imported
# copy of List::Util::max) and verify that updated() delegates aggregation to
# max() rather than implementing its own comparison loop.
# ===========================================================================
subtest 'updated: delegates to max() for aggregation (confirmed via Mockingbird)' => sub {
	plan tests => 2;
	my @received;
	# Mock the copy of max() that Database::Join imported into its namespace.
	mock 'Database::Join::max' => sub { @received = @_; return 42 };
	my $j  = _make_join();
	my $ts = $j->updated();
	is($ts, 42,
		'updated() returns whatever max() returns (Mockingbird intercept confirmed)');
	is(scalar @received, 2,
		'max() received exactly one argument per component database (2 DBs in _make_join)');
	restore_all();
};

subtest 'updated: passes all component timestamps to max()' => sub {
	plan tests => 1;
	# Build a 3-DB join to confirm the timestamp of every database reaches max().
	my @received;
	my $db_a = MinimalDA->new(cols => [$JC],        rows => [], updated => 100);
	my $db_b = MinimalDA->new(cols => [$JC, 'x'],   rows => [], updated => 200);
	my $db_c = MinimalDA->new(cols => [$JC, 'y'],   rows => [], updated => 300);
	my $j    = Database::Join->new(databases => [$db_a, $db_b, $db_c], join_column => $JC);
	mock 'Database::Join::max' => sub { @received = @_; return 300 };
	$j->updated();
	is_deeply([ sort { $a <=> $b } @received ], [100, 200, 300],
		'updated() passes the updated() value of every component database to max()');
	restore_all();
};

# ===========================================================================
# SECTION 24 -- remove_column edge cases (2 tests)
# The POD says "Removing a column that does not exist in any database is
# silently ignored".  The code path `if (defined $col && length $col)` also
# makes undef and empty-string no-ops.  Verify both to ensure robustness.
# ===========================================================================
subtest 'remove_column: undef argument is a silent no-op returning self' => sub {
	plan tests => 2;
	my $j = _make_join();
	lives_ok { $j->remove_column(undef) }
		'remove_column(undef) does not croak';
	is(refaddr($j->remove_column(undef)), refaddr($j),
		'remove_column(undef) returns $self (no-op, chainable)');
};

subtest 'remove_column: empty string argument is a silent no-op returning self' => sub {
	plan tests => 2;
	my $j = _make_join();
	lives_ok { $j->remove_column('') }
		'remove_column("") does not croak';
	is(refaddr($j->remove_column('')), refaddr($j),
		'remove_column("") returns $self (no-op, chainable)');
};

# ===========================================================================
# SECTION 25 -- AUTOLOAD returns undef / empty list when no rows match (2 tests)
# When join_map or filters is active, AUTOLOAD routes through _joined_query.
# Testing the no-match case ensures the code handles an empty result set
# correctly without warnings and returns the correct typed empty value.
# ===========================================================================
subtest 'AUTOLOAD: returns undef in scalar context when join_map active and no rows match' => sub {
	plan tests => 1;
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [ { entry => 'K1', name => 'Alice' } ],
	);
	my $db_b = MinimalDA->new(
		cols => [$JC_ALIAS, $COL_B],
		rows => [ { $JC_ALIAS => 'K1', score => 88 } ],
	);
	my $j = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		join_map    => { 1 => $JC_ALIAS },
	);
	my $val = $j->score('NOMATCH');
	ok(!defined $val,
		'AUTOLOAD returns undef in scalar context when join_map active and no row matches');
};

subtest 'AUTOLOAD: returns empty list in list context when join_map active and no rows match' => sub {
	plan tests => 1;
	my $db_a = MinimalDA->new(
		cols => [$JC, $COL_A],
		rows => [ { entry => 'K1', name => 'Alice' } ],
	);
	my $db_b = MinimalDA->new(
		cols => [$JC_ALIAS, $COL_B],
		rows => [ { $JC_ALIAS => 'K1', score => 88 } ],
	);
	my $j = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => $JC,
		join_map    => { 1 => $JC_ALIAS },
	);
	my @vals = $j->score('NOMATCH');
	is(scalar @vals, 0,
		'AUTOLOAD returns an empty list in list context when join_map active and no row matches');
};

# ===========================================================================
# SECTION 26 -- _partition_criteria return type (1 test)
# Verifies the structural contract: an arrayref with one slot per DB.
# Test::Returns enforces the type so any refactoring that changes the return
# form will be caught immediately.
# ===========================================================================
subtest '_partition_criteria: return type is an arrayref' => sub {
	plan tests => 2;
	my $wb = _bare_whitebox(
		_dbs    => [
			MinimalDA->new(cols => [$JC, $COL_A], rows => []),
			MinimalDA->new(cols => [$JC, $COL_B], rows => []),
		],
		_col_db => { $JC => 0, $COL_A => 0, $COL_B => 1 },
	);
	my $result = $wb->expose_partition({ $COL_A => 'Alice' });
	returns_ok($result, { type => 'arrayref' },
		'_partition_criteria returns an arrayref');
	is(scalar @{$result}, 2,
		'_partition_criteria arrayref has exactly one slot per component database');
};

diag('All white-box function tests complete') if $ENV{TEST_VERBOSE};
