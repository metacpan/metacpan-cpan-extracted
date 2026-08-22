use strict;
use warnings;

# t/integration.t -- Black-box, end-to-end integration tests for Database::Join.
#
# Strategy: exercise multi-step workflows and cross-method interactions using
# two data sources:
#
#   SQLite-backed databases (via Database::Abstraction) for realistic full-stack
#   tests covering the complete query pipeline.
#
#   InMemDA in-process stubs for concurrency, stateful-mutation, optional-feature,
#   and join_map tests where fine-grained control over the data is needed.
#
# The three SQLite fixtures form a deliberate coverage matrix:
#
#   intcust (3 rows) + intscore (3 rows)  -- all keys overlap (inner == left)
#   intcust (3 rows) + intregion (2 rows) -- c003 missing from intregion, so
#                                            left != inner != outer

use Test::Most;
use Test::Returns;
use Test::Mockingbird;
use Test::Without::Module;
use Readonly;
use Scalar::Util qw(blessed refaddr);

BEGIN {
	eval { require DBD::SQLite; require DBI; require Database::Abstraction };
	plan skip_all => 'DBD::SQLite, DBI, and Database::Abstraction required' if $@;
	plan tests => 54;
	use_ok('Database::Join');
}

use DBI;
use File::Temp qw(tempdir);

# ---------------------------------------------------------------------------
# SQLite-backed DA stubs.  -norequire because Database::Abstraction was
# already require()d in the BEGIN block above.
#
# Class-name last-component must match the SQL filename exactly (case-sensitive).
# Using all-lowercase names to match the intcust.sql / intscore.sql filenames.
# ---------------------------------------------------------------------------
{
	package Database::intcust;
	use parent -norequire, 'Database::Abstraction';
}
{
	package Database::intscore;
	use parent -norequire, 'Database::Abstraction';
}
{
	package Database::intregion;
	use parent -norequire, 'Database::Abstraction';
}

# ---------------------------------------------------------------------------
# InMemDA: in-process stub for tests that do not need SQLite.
# Implements the subset of the Database::Abstraction API that Database::Join
# calls: columns, schema, updated, set_logger, selectall_arrayref.
# Operator hashrefs (>, <, >=, <=, !=) are supported for numeric columns.
# ---------------------------------------------------------------------------
{
	package InMemDA;
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

	sub columns  { return $_[0]->{_cols} }
	sub schema   { return $_[0]->{_schema} }
	sub updated  { return $_[0]->{_ts} }
	sub set_logger { $_[0]->{_logger} = $_[1]; return $_[0] }

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
# Fake logger: records calls so that set_logger propagation can be verified
# without triggering real logging side-effects.
# Database::Abstraction calls $logger->debug/info/warn/error at query time,
# so all four levels must exist.
# ---------------------------------------------------------------------------
{
	package IntFakeLogger;
	sub new   { return bless { _calls => [] }, shift }
	sub debug { push @{$_[0]->{_calls}}, ['debug', $_[1]] }
	sub info  { push @{$_[0]->{_calls}}, ['info',  $_[1]] }
	sub warn  { push @{$_[0]->{_calls}}, ['warn',  $_[1]] }
	sub error { push @{$_[0]->{_calls}}, ['error', $_[1]] }
}

# ---------------------------------------------------------------------------
# Constants -- no magic numbers or strings in test assertions.
# ---------------------------------------------------------------------------
Readonly::Scalar my $JC         => 'entry';
Readonly::Scalar my $ALICE_KEY  => 'c001';
Readonly::Scalar my $BOB_KEY    => 'c002';
Readonly::Scalar my $CAROL_KEY  => 'c003';
Readonly::Scalar my $ALL_CUST   => 3;   # total rows in intcust
Readonly::Scalar my $ALL_SCORED => 3;   # total rows in intscore
Readonly::Scalar my $REGIOND    => 2;   # rows in intregion (c003 absent)
Readonly::Scalar my $GOLD_COUNT => 2;   # Alice and Carol are tier=gold

# ---------------------------------------------------------------------------
# SQLite fixture setup
#
#   intcust:   entry | name  | email                | tier
#              c001  | Alice | alice@example.com    | gold
#              c002  | Bob   | bob@example.com      | silver
#              c003  | Carol | carol@example.com    | gold
#
#   intscore:  entry | score | age_days
#              c001  | 95    | 90
#              c002  | 70    | 30
#              c003  | 55    | 120
#
#   intregion: entry | region | country
#              c001  | north  | US
#              c002  | south  | UK
#              (c003 deliberately absent -- makes left/inner/outer distinguishable)
# ---------------------------------------------------------------------------

my $dir = tempdir(CLEANUP => 1);

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/intcust.sql", q{}, q{},
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE intcust (entry TEXT PRIMARY KEY, name TEXT, email TEXT, tier TEXT)');
	$dbh->do(q{INSERT INTO intcust VALUES ('c001','Alice','alice@example.com','gold')});
	$dbh->do(q{INSERT INTO intcust VALUES ('c002','Bob',  'bob@example.com',  'silver')});
	$dbh->do(q{INSERT INTO intcust VALUES ('c003','Carol','carol@example.com','gold')});
	$dbh->disconnect;
}

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/intscore.sql", q{}, q{},
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE intscore (entry TEXT PRIMARY KEY, score INTEGER, age_days INTEGER)');
	$dbh->do(q{INSERT INTO intscore VALUES ('c001',95,90)});
	$dbh->do(q{INSERT INTO intscore VALUES ('c002',70,30)});
	$dbh->do(q{INSERT INTO intscore VALUES ('c003',55,120)});
	$dbh->disconnect;
}

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/intregion.sql", q{}, q{},
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE intregion (entry TEXT PRIMARY KEY, region TEXT, country TEXT)');
	$dbh->do(q{INSERT INTO intregion VALUES ('c001','north','US')});
	$dbh->do(q{INSERT INTO intregion VALUES ('c002','south','UK')});
	$dbh->disconnect;
}

# max_slurp_size => 1 forces the SQL path in Database::Abstraction, bypassing
# the in-memory slurp cache that would otherwise deduplicate rows by entry.
my $cust   = Database::intcust->new(  directory => $dir, max_slurp_size => 1 );
my $score  = Database::intscore->new( directory => $dir, max_slurp_size => 1 );
my $region = Database::intregion->new(directory => $dir, max_slurp_size => 1 );

# ---------------------------------------------------------------------------
# Shared left join used across multiple subtests in section 2.
# ---------------------------------------------------------------------------
my $left_join = Database::Join->new(
	databases   => [ $cust, $score ],
	join_column => $JC,
	join_type   => 'left',
);

diag("SQLite fixture dir: $dir") if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 2 -- Two-database SQLite left join, end-to-end (7 subtests)
#
# Validates the full stack from construction through every public query method.
# Using $cust + $score ensures all primary rows have a matching secondary row,
# so left == inner for this pair -- keeping assertions straightforward.
# ===========================================================================

subtest 'two-DB join: selectall_arrayref returns all primary rows' => sub {
	plan tests => 2;
	my $rows = $left_join->selectall_arrayref();
	returns_ok($rows, { type => 'arrayref' }, 'selectall_arrayref returns an arrayref');
	is(scalar @{$rows}, $ALL_CUST, 'left join returns all 3 customer rows');
};

subtest 'two-DB join: merged rows contain columns from both databases' => sub {
	plan tests => 3;
	my $rows = $left_join->selectall_arrayref($JC => $ALICE_KEY);
	is(scalar @{$rows}, 1, 'one row returned for Alice key');
	is($rows->[0]{name},  'Alice', 'name column (from intcust) present in merged row');
	is($rows->[0]{score}, 95,      'score column (from intscore) present in merged row');
};

subtest 'two-DB join: fetchrow_hashref returns a hashref for a specific key' => sub {
	plan tests => 2;
	my $row = $left_join->fetchrow_hashref($JC => $BOB_KEY);
	returns_ok($row, { type => 'hashref' }, 'fetchrow_hashref returns a hashref');
	is($row->{name}, 'Bob', 'correct customer returned by key lookup');
};

subtest 'two-DB join: count() with and without criteria' => sub {
	plan tests => 2;
	is($left_join->count(),           $ALL_CUST,   'count() with no criteria returns all rows');
	is($left_join->count(tier => 'gold'), $GOLD_COUNT, 'count() with tier=gold criterion filters correctly');
};

subtest 'two-DB join: columns() is sorted and contains each join key exactly once' => sub {
	plan tests => 3;
	my $cols = $left_join->columns();
	returns_ok($cols, { type => 'arrayref' }, 'columns() returns an arrayref');
	is_deeply($cols, [sort @{$cols}], 'columns() list is sorted alphabetically');
	is(scalar(grep { $_ eq $JC } @{$cols}), 1, 'join_column appears exactly once in columns()');
};

subtest 'two-DB join: schema() merges metadata from both databases' => sub {
	plan tests => 2;
	my $schema = $left_join->schema();
	returns_ok($schema, { type => 'hashref' }, 'schema() returns a hashref');
	ok(exists $schema->{score} && exists $schema->{name},
		'schema contains keys from both component databases');
};

subtest 'two-DB join: updated() returns the maximum component timestamp' => sub {
	plan tests => 2;
	my $ts = $left_join->updated();
	ok(defined $ts && $ts > 0, 'updated() returns a positive value');
	ok($ts >= $cust->updated() && $ts >= $score->updated(),
		'updated() is >= each individual component updated() value');
};

diag('section 2 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 3 -- Three-database join via incremental add_database (5 subtests)
#
# Verifies that add_database correctly extends the merged view at each step
# and that the end state equals an equivalent all-at-once construction.
# ===========================================================================

subtest 'add_database: single-DB join exposes only primary columns' => sub {
	plan tests => 1;
	my $j = Database::Join->new(databases => [$cust], join_column => $JC);
	ok(!grep({ $_ eq 'score' } @{ $j->columns() }),
		'score column absent before add_database adds intscore');
};

subtest 'add_database: second DB extends columns and preserves row count' => sub {
	plan tests => 2;
	my $j = Database::Join->new(databases => [$cust], join_column => $JC);
	$j->add_database($score);
	ok( grep({ $_ eq 'score' } @{ $j->columns() }),
		'score column visible after add_database($score)');
	is($j->count(), $ALL_CUST, 'all customer rows still visible after second DB added');
};

subtest 'add_database: chaining adds third DB and merges its data' => sub {
	plan tests => 2;
	my $j = Database::Join->new(databases => [$cust], join_column => $JC);
	$j->add_database($score)->add_database($region);
	ok( grep({ $_ eq 'region' } @{ $j->columns() }),
		'region column visible after chaining two add_database calls');
	my $alice = $j->fetchrow_hashref($JC => $ALICE_KEY);
	is($alice->{region}, 'north', 'three-way merged row has correct region value for Alice');
};

subtest 'add_database: chain result equals direct three-DB construction' => sub {
	plan tests => 1;
	my $chain = Database::Join->new(databases => [$cust], join_column => $JC);
	$chain->add_database($score)->add_database($region);
	my $direct = Database::Join->new(
		databases => [$cust, $score, $region], join_column => $JC, join_type => 'left',
	);
	is($chain->count(), $direct->count(),
		'incremental add_database chain yields the same row count as direct construction');
};

subtest 'add_database: remove_columns option hides columns from the new DB' => sub {
	plan tests => 2;
	my $j = Database::Join->new(databases => [$cust], join_column => $JC);
	$j->add_database($score, remove_columns => ['age_days']);
	ok(!grep({ $_ eq 'age_days' } @{ $j->columns() }),
		'age_days hidden when add_database is called with remove_columns');
	ok( grep({ $_ eq 'score'    } @{ $j->columns() }),
		'score still visible after age_days is hidden via remove_columns');
};

diag('section 3 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 4 -- Join type semantics with realistic data (4 subtests)
#
# intcust has 3 rows; intregion has only 2 (c003 absent).  This gives
# distinct row counts for each join type, making each type cleanly testable.
# ===========================================================================

subtest 'join_type left: all primary rows, undef for missing secondary data' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases => [$cust, $region], join_column => $JC, join_type => 'left'
	);
	is($j->count(), $ALL_CUST, 'left join returns all 3 customers');
	my $rows  = $j->selectall_arrayref();
	my ($carol) = grep { $_->{entry} eq $CAROL_KEY } @{$rows};
	ok(!defined $carol->{region},
		'Carol row has undef region (no intregion row for c003)');
};

subtest 'join_type inner: only keys present in all component databases' => sub {
	plan tests => 1;
	my $j = Database::Join->new(
		databases => [$cust, $region], join_column => $JC, join_type => 'inner'
	);
	is($j->count(), $REGIOND,
		'inner join returns only the 2 customers that have a region record');
};

subtest 'join_type outer: all keys from any component database' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases => [$cust, $region], join_column => $JC, join_type => 'outer'
	);
	# intregion has no extra-only keys, so outer == left == 3 here
	is($j->count(), $ALL_CUST, 'outer join returns all 3 customers');
	my $rows    = $j->selectall_arrayref();
	my ($carol) = grep { $_->{entry} eq $CAROL_KEY } @{$rows};
	ok(!defined $carol->{region},
		'Carol outer-join row has undef region column');
};

subtest 'join_type: criterion on secondary column forces inner-join semantics for that query' => sub {
	plan tests => 1;
	# Even with join_type => 'left', a WHERE clause on a secondary column means
	# that database acted as a constraint for this query.  Only c001 (US) qualifies.
	my $j = Database::Join->new(
		databases => [$cust, $region], join_column => $JC, join_type => 'left'
	);
	my $rows = $j->selectall_arrayref(country => 'US');
	is(scalar @{$rows}, 1,
		'criterion on secondary column forces inner semantics (only US customer returned)');
};

diag('section 4 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 5 -- Permanent per-database filters (5 subtests)
#
# Filters are evaluated every query.  A filtered database always acts as an
# inner-join partner regardless of join_type.  Two operator hashrefs on the
# same column combine with AND semantics; a plain scalar replaces the filter.
# ===========================================================================

subtest 'filter: restricts secondary DB, enforcing inner-join semantics on it' => sub {
	plan tests => 1;
	# score > 60: Alice (95) and Bob (70) pass; Carol (55) fails.
	# Even though join_type is left, the filtered intscore acts as inner partner.
	my $j = Database::Join->new(
		databases => [$cust, $score], join_column => $JC, join_type => 'left',
		filters   => { 1 => { score => { '>' => 60 } } },
	);
	is($j->count(), 2,
		'filter on secondary DB excludes Carol (score=55 fails score>60)');
};

subtest 'filter: two operator hashrefs on same column combine with AND semantics' => sub {
	plan tests => 1;
	# Base filter: score > 60.  Query: score < 80.  AND: 60 < score < 80.
	# Bob (70) qualifies; Alice (95) fails < 80; Carol (55) fails the base.
	my $j = Database::Join->new(
		databases => [$cust, $score], join_column => $JC, join_type => 'left',
		filters   => { 1 => { score => { '>' => 60 } } },
	);
	my $rows = $j->selectall_arrayref(score => { '<' => 80 });
	is(scalar @{$rows}, 1,
		'AND-merged operator hashrefs: only Bob (60 < 70 < 80) survives both constraints');
};

subtest 'filter: scalar query criterion replaces base operator filter for that column' => sub {
	plan tests => 1;
	# Base filter: score > 80 (excludes Bob=70, Carol=55).
	# Query: score = 70 (plain scalar).  Scalar wins, so Bob IS returned.
	my $j = Database::Join->new(
		databases => [$cust, $score], join_column => $JC, join_type => 'left',
		filters   => { 1 => { score => { '>' => 80 } } },
	);
	my $rows = $j->selectall_arrayref(score => 70);
	is(scalar @{$rows}, 1,
		'scalar query criterion replaces base filter operator (Bob score=70 returned)');
};

subtest 'filter: add_database filter option is equivalent to constructor filters' => sub {
	plan tests => 1;
	my $via_ctor = Database::Join->new(
		databases => [$cust, $score], join_column => $JC,
		filters   => { 1 => { score => { '>' => 60 } } },
	);
	my $via_add = Database::Join->new(databases => [$cust], join_column => $JC);
	$via_add->add_database($score, filter => { score => { '>' => 60 } });
	is($via_add->count(), $via_ctor->count(),
		'add_database filter option produces the same row count as constructor filters');
};

subtest 'filter: primary-database filter constrains the primary key set' => sub {
	plan tests => 1;
	# Filtering DB 0 (intcust) to tier=gold limits the key set to Alice and Carol.
	my $j = Database::Join->new(
		databases => [$cust, $score], join_column => $JC, join_type => 'left',
		filters   => { 0 => { tier => 'gold' } },
	);
	is($j->count(), $GOLD_COUNT,
		'primary-DB filter restricts key set to gold-tier customers only');
};

diag('section 5 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 6 -- Column removal cascade (5 subtests)
#
# remove_column must propagate to columns(), schema(), result rows, and the
# routing table.  Criteria targeting a removed column are silently carp()ed
# and dropped.  The join_column itself cannot be removed.
# ===========================================================================

subtest 'remove_column: column absent from columns(), schema(), and query results' => sub {
	plan tests => 3;
	my $j = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	$j->remove_column('email');
	ok(!grep({ $_ eq 'email' } @{ $j->columns() }),
		'email absent from columns() after remove_column');
	ok(!exists $j->schema()->{email},
		'email absent from schema() after remove_column');
	my $rows = $j->selectall_arrayref();
	ok(!exists $rows->[0]{email},
		'email absent from result row after remove_column');
};

subtest 'remove_column: criterion on removed column dropped with carp warning' => sub {
	plan tests => 2;
	my $j = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	$j->remove_column('email');
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $rows = $j->selectall_arrayref(email => 'alice@example.com');
	is(scalar @{$rows}, $ALL_CUST,
		'all rows returned when criterion targets a removed column');
	ok(@warnings,
		'carp warning emitted when criterion targets a removed column');
};

subtest 'remove_column: cannot remove the join_column' => sub {
	plan tests => 1;
	my $j = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	throws_ok { $j->remove_column($JC) }
		qr/Cannot remove join_column/,
		'remove_column() croaks when asked to remove the join key';
};

subtest 'remove_column: chaining removes multiple columns in one expression' => sub {
	plan tests => 2;
	my $j = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	$j->remove_column('email')->remove_column('age_days');
	ok(!grep({ $_ eq 'email'    } @{ $j->columns() }), 'email removed by chaining');
	ok(!grep({ $_ eq 'age_days' } @{ $j->columns() }), 'age_days removed by chaining');
};

subtest 'remove_column: idempotent and safe for non-existent column names' => sub {
	plan tests => 2;
	my $j = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	lives_ok { $j->remove_column('email'); $j->remove_column('email') }
		'removing the same column twice does not croak';
	lives_ok { $j->remove_column('no_such_column') }
		'removing a non-existent column does not croak';
};

diag('section 6 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 7 -- join_map: joining on differently-named key columns (3 subtests)
#
# Uses InMemDA stubs to isolate join_map semantics from storage.  The local
# alias (the name used inside a specific database) must never appear in
# columns(), schema(), or any merged result row.
# ===========================================================================

subtest 'join_map: local alias absent from columns(), schema(), and result rows' => sub {
	plan tests => 3;
	my $db0 = InMemDA->new(
		cols => [$JC, 'city'],
		rows => [ { entry => 'TX', city => 'Austin' } ],
	);
	my $db1 = InMemDA->new(
		cols   => ['ref_id', 'pop_m'],
		rows   => [ { ref_id => 'TX', pop_m => 29 } ],
		schema => { ref_id => {}, pop_m => {} },
	);
	my $j = Database::Join->new(
		databases   => [$db0, $db1],
		join_column => $JC,
		join_map    => { 1 => 'ref_id' },
	);
	ok(!grep({ $_ eq 'ref_id' } @{ $j->columns() }),
		'local alias ref_id absent from columns()');
	ok(!exists $j->schema()->{ref_id},
		'local alias ref_id absent from schema()');
	my $row = $j->fetchrow_hashref('TX');
	ok(!exists $row->{ref_id},
		'local alias ref_id absent from merged result row');
};

subtest 'join_map: canonical join_column name used throughout the merged view' => sub {
	plan tests => 2;
	my $db0 = InMemDA->new(
		cols => [$JC, 'city'],
		rows => [ { entry => 'CA', city => 'LA' } ],
	);
	my $db1 = InMemDA->new(
		cols => ['ref_id', 'pop_m'],
		rows => [ { ref_id => 'CA', pop_m => 39 } ],
	);
	my $j = Database::Join->new(
		databases   => [$db0, $db1],
		join_column => $JC,
		join_map    => { 1 => 'ref_id' },
	);
	my $row = $j->fetchrow_hashref('CA');
	is($row->{entry}, 'CA', 'canonical join_column (entry) present in merged row');
	is($row->{pop_m}, 39,   'secondary DB column value correctly merged via join_map');
};

subtest 'join_map: add_database join_column option is equivalent to constructor join_map' => sub {
	plan tests => 1;
	my $db0 = InMemDA->new(
		cols => [$JC, 'city'],
		rows => [ { entry => 'TX', city => 'Austin' }, { entry => 'CA', city => 'LA' } ],
	);
	my $db1 = InMemDA->new(
		cols => ['ref_id', 'pop_m'],
		rows => [ { ref_id => 'TX', pop_m => 29  }, { ref_id => 'CA', pop_m => 39 } ],
	);
	my $via_ctor = Database::Join->new(
		databases => [$db0, $db1], join_column => $JC,
		join_map  => { 1 => 'ref_id' },
	);
	my $via_add = Database::Join->new(databases => [$db0], join_column => $JC);
	$via_add->add_database($db1, join_column => 'ref_id');
	is($via_add->count(), $via_ctor->count(),
		'join_map and add_database join_column produce the same row count');
};

diag('section 7 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 8 -- AUTOLOAD column-shortcut method dispatch (4 subtests)
#
# AUTOLOAD maps unknown method names to columns.  It uses a fast-path direct
# DA delegation when no join_map or filters are active, and falls back to the
# full _joined_query path when they are.  Private names and unknown columns
# must croak immediately.
# ===========================================================================

subtest 'AUTOLOAD: scalar context returns the column value for a specific key' => sub {
	plan tests => 1;
	my $j    = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	my $name = $j->name($JC => $ALICE_KEY);
	is($name, 'Alice', 'AUTOLOAD scalar context returns the correct column value');
};

subtest 'AUTOLOAD: list context returns column values from all merged rows' => sub {
	plan tests => 2;
	my $j      = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	my @names  = $j->name();
	is(scalar @names, $ALL_CUST, 'AUTOLOAD list context returns one value per merged row');
	ok((grep { $_ eq 'Alice' } @names) && (grep { $_ eq 'Bob' } @names),
		'list includes values from multiple rows');
};

subtest 'AUTOLOAD: routes through _joined_query when filters restrict the key set' => sub {
	plan tests => 1;
	# score > 80 passes only Alice (95); the filter uses the full join path.
	my $j = Database::Join->new(
		databases => [$cust, $score], join_column => $JC,
		filters   => { 1 => { score => { '>' => 80 } } },
	);
	my @names = $j->name();
	is_deeply([sort @names], [sort ('Alice')],
		'AUTOLOAD with active filter returns only names from qualifying rows');
};

subtest 'AUTOLOAD: croaks for unknown column and for private method names' => sub {
	plan tests => 2;
	my $j = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	throws_ok { $j->no_such_column_xyz() }
		qr/unknown column/i,
		'AUTOLOAD croaks for a method name not matching any known column';
	throws_ok { $j->_internal_thing() }
		qr/cannot call private/i,
		'AUTOLOAD croaks immediately for a method name starting with underscore';
};

diag('section 8 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 9 -- Logger propagation across the object lifecycle (3 subtests)
#
# set_logger must reach all current component databases immediately and must
# also propagate to databases added later via add_database.
# ===========================================================================

subtest 'set_logger: propagates to all current component databases' => sub {
	plan tests => 2;
	my $j   = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	my $log = IntFakeLogger->new();
	$j->set_logger($log);
	# DA stores the logger at $self->{'logger'} (not '_logger')
	is(refaddr($cust->{'logger'}),  refaddr($log), 'intcust DA stores the logger');
	is(refaddr($score->{'logger'}), refaddr($log), 'intscore DA stores the logger');
};

subtest 'set_logger: returns $self to support method chaining' => sub {
	plan tests => 1;
	my $j   = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	my $log = IntFakeLogger->new();
	is(refaddr($j->set_logger($log)), refaddr($j), 'set_logger() returns $self');
};

subtest 'add_database: propagates existing logger to the newly added database' => sub {
	plan tests => 1;
	my $j   = Database::Join->new(databases => [$cust], join_column => $JC);
	my $log = IntFakeLogger->new();
	$j->set_logger($log);
	$j->add_database($score);
	is(refaddr($score->{'logger'}), refaddr($log),
		'add_database propagates the existing logger to the new component database');
};

diag('section 9 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 10 -- Two independent join objects must not share mutable state (5 subtests)
#
# Both joins are built from the same component-database objects.  Any mutation
# on one join (add_database, remove_column, set_logger, filtered query) must
# not affect the other.  This guards against accidental sharing of _col_db,
# _removed_cols, _col_cache, and _filters.
# ===========================================================================

subtest 'concurrency: two joins from the same DBs have independent column caches' => sub {
	plan tests => 1;
	my $j1 = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	my $j2 = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	$j1->columns();   # prime j1's cache
	$j2->columns();   # prime j2's cache
	isnt(refaddr($j1->{_col_cache}), refaddr($j2->{_col_cache}),
		'each join holds a separate column-cache arrayref');
};

subtest 'concurrency: remove_column on one join does not affect the other' => sub {
	plan tests => 2;
	my $j1 = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	my $j2 = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	$j1->remove_column('email');
	ok(!grep({ $_ eq 'email' } @{ $j1->columns() }), 'email removed from j1');
	ok( grep({ $_ eq 'email' } @{ $j2->columns() }), 'email still present in j2');
};

subtest 'concurrency: add_database on one join does not affect the other' => sub {
	plan tests => 2;
	my $j1 = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	my $j2 = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	$j1->add_database($region);
	ok( grep({ $_ eq 'region' } @{ $j1->columns() }), 'region added to j1');
	ok(!grep({ $_ eq 'region' } @{ $j2->columns() }), 'region absent from j2');
};

subtest 'concurrency: simultaneous queries on different joins return independent results' => sub {
	plan tests => 2;
	my $j1 = Database::Join->new(
		databases => [$cust, $score], join_column => $JC, join_type => 'inner'
	);
	my $j2 = Database::Join->new(
		databases => [$cust, $region], join_column => $JC, join_type => 'inner'
	);
	is($j1->count(), $ALL_SCORED, 'j1 (cust+score inner) returns all 3 scored rows');
	is($j2->count(), $REGIOND,    'j2 (cust+region inner) returns only 2 regional rows');
};

subtest 'concurrency: two joins with different filters are fully independent' => sub {
	plan tests => 2;
	my $j_gold   = Database::Join->new(
		databases => [$cust, $score], join_column => $JC,
		filters   => { 0 => { tier => 'gold' } },
	);
	my $j_silver = Database::Join->new(
		databases => [$cust, $score], join_column => $JC,
		filters   => { 0 => { tier => 'silver' } },
	);
	is($j_gold->count(),   $GOLD_COUNT, 'gold-filtered join returns gold-tier rows only');
	is($j_silver->count(), 1,           'silver-filtered join returns silver-tier row only');
};

diag('section 10 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 11 -- Stateful lifecycle: the view changes as the join evolves (4 subtests)
#
# Tests that columns(), count(), and updated() all reflect the current state
# of the join after each mutation (add_database, remove_column).
# ===========================================================================

subtest 'lifecycle: columns() expands after add_database' => sub {
	plan tests => 2;
	my $j = Database::Join->new(databases => [$cust], join_column => $JC);
	my $n_before = scalar @{ $j->columns() };
	$j->add_database($score);
	ok(scalar @{ $j->columns() } > $n_before,
		'column count is larger after add_database');
	ok( grep({ $_ eq 'score' } @{ $j->columns() }),
		'score column visible after add_database');
};

subtest 'lifecycle: query results change after remove_column' => sub {
	plan tests => 2;
	my $j = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	my $before = $j->fetchrow_hashref($JC => $ALICE_KEY);
	ok(exists $before->{email}, 'email present in row before remove_column');
	$j->remove_column('email');
	my $after = $j->fetchrow_hashref($JC => $ALICE_KEY);
	ok(!exists $after->{email}, 'email absent from row after remove_column');
};

subtest 'lifecycle: count() changes when a filter restricts the secondary DB' => sub {
	plan tests => 2;
	# Build a join, then build a second join with a score filter and verify the
	# counts are different.  This tests the runtime effect of different filter
	# configurations rather than mutating a single join.
	my $j_all = Database::Join->new(
		databases => [$cust, $score], join_column => $JC
	);
	my $j_filtered = Database::Join->new(
		databases => [$cust, $score], join_column => $JC,
		filters   => { 1 => { score => { '>' => 80 } } },
	);
	is($j_all->count(), $ALL_CUST,
		'unfiltered join returns all customers');
	is($j_filtered->count(), 1,
		'score>80 filter returns only Alice (score=95)');
};

subtest 'lifecycle: updated() increases after add_database adds a newer component' => sub {
	plan tests => 1;
	my $j = Database::Join->new(databases => [$cust], join_column => $JC);
	my $ts_before = $j->updated();
	my $newer_db  = InMemDA->new(
		cols    => [$JC, 'tag'],
		rows    => [],
		updated => $ts_before + 1_000_000,  # guaranteed newer than any SQLite mtime
	);
	$j->add_database($newer_db);
	ok($j->updated() > $ts_before,
		'updated() grows after add_database introduces a newer component database');
};

diag('section 11 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 12 -- Optional runtime i18n feature (4 subtests)
#
# The i18n parameter is purely optional.  Three documented paths exist:
#   (1) no i18n object -- messages come from the %MESSAGES dictionary verbatim
#   (2) i18n object with translate() -- every message is delegated
#   (3) i18n object without translate() -- graceful fallback to %MESSAGES
# All three must produce correct (not broken) behaviour.
# ===========================================================================

subtest 'i18n: without i18n object errors come from %MESSAGES verbatim' => sub {
	plan tests => 1;
	throws_ok { Database::Join->new(databases => [], join_column => $JC) }
		qr/At least one Database::Abstraction/,
		'without i18n, error text matches the %MESSAGES dictionary entry';
};

subtest 'i18n: with translate() present, error messages are delegated to it' => sub {
	plan tests => 1;
	my $i18n = bless {}, 'IntTestI18N';
	{
		no strict 'refs';
		no warnings 'once';
		*IntTestI18N::can       = sub { $_[1] eq 'translate' ? sub {} : undef };
		*IntTestI18N::translate = sub { "XLAT:$_[1]" };
	}
	throws_ok {
		Database::Join->new(databases => [], join_column => $JC, i18n => $i18n)
	} qr/XLAT:error_no_databases/,
		'with i18n object, error message key is passed through translate()';
};

subtest 'i18n: without translate() the module falls back to %MESSAGES strings' => sub {
	plan tests => 1;
	my $no_tr = bless {}, 'IntNoTransI18N';
	{
		no strict 'refs';
		no warnings 'once';
		*IntNoTransI18N::can = sub { undef };
	}
	throws_ok {
		Database::Join->new(databases => [], join_column => $JC, i18n => $no_tr)
	} qr/At least one Database::Abstraction/,
		'i18n object without translate() causes graceful fallback to %MESSAGES';
};

subtest 'i18n: join with i18n object (no translate) still functions normally' => sub {
	plan tests => 1;
	my $stub = bless {}, 'IntPassThroughI18N';
	{
		no strict 'refs';
		no warnings 'once';
		*IntPassThroughI18N::can = sub { undef };
	}
	my $j = Database::Join->new(
		databases => [$cust, $score], join_column => $JC, i18n => $stub,
	);
	is($j->count(), $ALL_CUST,
		'join with i18n stub (no translate) correctly queries all rows');
};

diag('section 12 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 13 -- Test::Without::Module: storage-agnostic behaviour (2 subtests)
#
# Database::Join is indifferent to the underlying storage mechanism of its
# component databases.  These tests confirm it works without DBD::SQLite (using
# InMemDA stubs) and has no hidden dependency on i18n CPAN modules.
# ===========================================================================

subtest 'Database::Join works when DBD::SQLite is blocked (InMemDA stubs only)' => sub {
	plan tests => 3;
	# Simulate an environment where no SQLite driver is available.
	# Database::Join itself never calls SQLite -- only the component databases do.
	# With InMemDA stubs, the join must function fully.
	Test::Without::Module->import('DBD::SQLite');
	my $db_a = InMemDA->new(
		cols => [$JC, 'city'],
		rows => [ { entry => 'TX', city => 'Austin' }, { entry => 'CA', city => 'LA' } ],
	);
	my $db_b = InMemDA->new(
		cols => [$JC, 'pop_m'],
		rows => [ { entry => 'TX', pop_m => 29 }, { entry => 'CA', pop_m => 39 } ],
	);
	my $j = Database::Join->new(databases => [$db_a, $db_b], join_column => $JC);
	is($j->count(), 2, 'count() works with DBD::SQLite blocked');
	is_deeply(
		[sort @{ $j->columns() }],
		[sort ($JC, 'city', 'pop_m')],
		'columns() correct with DBD::SQLite blocked',
	);
	my $row = $j->fetchrow_hashref('TX');
	is($row->{city}, 'Austin', 'fetchrow_hashref returns correct data with DBD::SQLite blocked');
	Test::Without::Module->unimport('DBD::SQLite');
};

subtest 'Database::Join has no hidden dependency on Locale::Maketext or similar' => sub {
	plan tests => 2;
	# Block a common i18n CPAN module to confirm Database::Join does not require
	# it.  The i18n feature is a runtime-optional parameter, not a module import.
	Test::Without::Module->import('Locale::Maketext');
	ok(defined $Database::Join::VERSION,
		'Database::Join::VERSION defined with Locale::Maketext blocked');
	isa_ok(
		Database::Join->new(databases => [$cust, $score], join_column => $JC),
		'Database::Join',
		'new() succeeds with Locale::Maketext blocked',
	);
	Test::Without::Module->unimport('Locale::Maketext');
};

diag('section 13 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 14 -- Mockingbird spy: verify calling conventions and routing (2 subtests)
#
# spy() wraps a live function and records each call without changing its
# return value.  This lets us assert on HOW Database::Join calls the component
# databases rather than just what it returns.
#
# CRITICAL: spy must target the DEFINING class (Database::Abstraction), not a
# subclass (Database::intcust).  When a method is inherited, \&Child::method
# produces a dispatch stub whose calling it after the spy wrapper is installed
# resolves back through the method dispatch chain and hits the wrapper itself
# -- infinite recursion.  Spying at the defining class captures the real
# coderef as $orig, and no recursive dispatch occurs.
#
# We filter by refaddr($self) to isolate calls originating from each
# component database object.
#
# Two invariants from CLAUDE.md are verified here:
#   (1) Criteria are always passed as a hashref, never as a flat list.
#   (2) A column criterion is routed only to the database that owns that column.
# ===========================================================================

subtest 'spy: DA->selectall_arrayref always receives a hashref, not a flat list' => sub {
	plan tests => 2;
	# Spy at the defining class so $orig is the real coderef (not a dispatch stub).
	my $get_all_calls = spy 'Database::Abstraction::selectall_arrayref';

	my $j = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	$j->selectall_arrayref(score => { '>' => 80 });

	restore_all();

	# Each spy record: [ 'Pkg::method', $self, $criteria_hashref ]
	my $cust_addr  = refaddr($cust);
	my $score_addr = refaddr($score);
	my (@cust_crits, @score_crits);
	for my $rec ($get_all_calls->()) {
		my ($method, $self, $crit) = @{$rec};
		push @cust_crits,  $crit if refaddr($self) == $cust_addr;
		push @score_crits, $crit if refaddr($self) == $score_addr;
	}

	ok(ref($cust_crits[0])  eq 'HASH',
		'intcust DA->selectall_arrayref called with hashref criteria (not a flat list)');
	ok(ref($score_crits[0]) eq 'HASH',
		'intscore DA->selectall_arrayref called with hashref criteria (not a flat list)');
};

subtest 'spy: column criterion routed only to the database that owns that column' => sub {
	plan tests => 2;
	my $get_all_calls = spy 'Database::Abstraction::selectall_arrayref';

	my $j = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	# tier belongs to intcust; score belongs to intscore.  Each criterion must
	# be sent to exactly one database and not leak across the partition.
	$j->selectall_arrayref(tier => 'gold');

	restore_all();

	my $cust_addr  = refaddr($cust);
	my $score_addr = refaddr($score);
	my (@cust_crits, @score_crits);
	for my $rec ($get_all_calls->()) {
		my ($method, $self, $crit) = @{$rec};
		push @cust_crits,  $crit if refaddr($self) == $cust_addr;
		push @score_crits, $crit if refaddr($self) == $score_addr;
	}

	ok( exists $cust_crits[0]{tier},
		'tier criterion routed to intcust (the database that owns the tier column)');
	ok(!exists $score_crits[0]{tier},
		'tier criterion NOT forwarded to intscore (which does not own tier)');
};

diag('section 14 done -- integration tests complete') if $ENV{TEST_VERBOSE};
