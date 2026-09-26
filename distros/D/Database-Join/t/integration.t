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
	plan tests => 104;
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

diag('section 14 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 15 -- collision_prefix: end-to-end workflow (5 subtests)
#
# collision_prefix maps a zero-based DB index to a prefix string.  When a
# column in a secondary database collides with a column already in the merged
# view, the secondary's copy is published as "prefix.col" so both values
# survive in every merged row.  Non-colliding columns are always plain.
# The join_column itself is never prefixed.  Index-0 entries are silently ignored.
# ===========================================================================

Readonly::Scalar my $CP_PFX    => 'ext';
Readonly::Scalar my $COL_NOTES => 'notes';
Readonly::Scalar my $COL_PFX_N => "$CP_PFX.$COL_NOTES";

# Two in-memory DAs that both carry a 'notes' column.  DA-A also has 'amount';
# DA-B also has 'price'.  Only 'notes' collides, so only it gets a prefix.
my $cp_db_a = InMemDA->new(
	cols => [$JC, $COL_NOTES, 'amount'],
	rows => [
		{ entry => 'K1', notes => 'note-a1', amount => 10 },
		{ entry => 'K2', notes => 'note-a2', amount => 20 },
	],
);
my $cp_db_b = InMemDA->new(
	cols => [$JC, $COL_NOTES, 'price'],
	rows => [
		{ entry => 'K1', notes => 'note-b1', price =>  5 },
		{ entry => 'K2', notes => 'note-b2', price => 15 },
	],
);

subtest 'collision_prefix: columns() shows both the plain and prefixed names' => sub {
	plan tests => 3;
	my $j = Database::Join->new(
		databases        => [$cp_db_a, $cp_db_b],
		join_column      => $JC,
		collision_prefix => { 1 => $CP_PFX },
	);
	my %col_h = map { $_ => 1 } @{ $j->columns() };
	ok($col_h{$COL_NOTES},        "plain '$COL_NOTES' (primary DB) in columns()");
	ok($col_h{$COL_PFX_N},        "prefixed '$COL_PFX_N' (secondary collision) in columns()");
	ok(!$col_h{"$CP_PFX.$JC"},    "join_column '$JC' never gains a prefix");
};

subtest 'collision_prefix: merged row carries both the primary and prefixed secondary values' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases        => [$cp_db_a, $cp_db_b],
		join_column      => $JC,
		collision_prefix => { 1 => $CP_PFX },
	);
	my $row = $j->fetchrow_hashref($JC => 'K1');
	is($row->{$COL_NOTES}, 'note-a1', "plain 'notes' holds the primary-DB value");
	is($row->{$COL_PFX_N}, 'note-b1', "prefixed '$COL_PFX_N' holds the secondary-DB value");
};

subtest 'collision_prefix: criterion on prefixed name routes to the secondary database' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases        => [$cp_db_a, $cp_db_b],
		join_column      => $JC,
		collision_prefix => { 1 => $CP_PFX },
	);
	my $rows = $j->selectall_arrayref($COL_PFX_N => 'note-b2');
	is(scalar @{$rows}, 1,      "criterion on '$COL_PFX_N' returns exactly 1 row");
	is($rows->[0]{$JC},  'K2',  'correct row (K2) returned when filtering on prefixed name');
};

subtest 'collision_prefix: remove_column on the prefixed name hides it; plain name survives' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases        => [$cp_db_a, $cp_db_b],
		join_column      => $JC,
		collision_prefix => { 1 => $CP_PFX },
	);
	$j->remove_column($COL_PFX_N);
	my %col_h = map { $_ => 1 } @{ $j->columns() };
	ok(!$col_h{$COL_PFX_N}, "prefixed '$COL_PFX_N' absent from columns() after remove_column");
	ok($col_h{$COL_NOTES},  "plain '$COL_NOTES' still present after removing the prefixed name");
};

subtest 'collision_prefix: add_database applies pre-declared prefix for the new index' => sub {
	plan tests => 2;
	# Pre-declare collision_prefix at construction time, then add the secondary DB later.
	# The prefix registered for index 1 must be applied when add_database runs.
	my $j = Database::Join->new(
		databases        => [$cp_db_a],
		join_column      => $JC,
		collision_prefix => { 1 => $CP_PFX },
	);
	$j->add_database($cp_db_b);
	my %col_h = map { $_ => 1 } @{ $j->columns() };
	ok($col_h{$COL_PFX_N},   "prefixed '$COL_PFX_N' appears after add_database");
	my $row = $j->fetchrow_hashref($JC => 'K1');
	is($row->{$COL_PFX_N}, 'note-b1',
		"merged row holds the correct value under the prefixed name after add_database");
};

diag('section 15 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 16 -- Miscellaneous public API surface (5 subtests)
#
# Rounds out the API coverage:
#   selectall_array (list-context counterpart to selectall_arrayref),
#   remove_columns constructor parameter (hide columns at birth),
#   positional single-arg shorthand (POD states it equals the named-pair form),
#   and the two documented unsupported-method croak paths (query, execute).
# ===========================================================================

subtest 'selectall_array: returns a flat list of row hashrefs (not a reference)' => sub {
	plan tests => 3;
	# POD: selectall_array is the list-context counterpart to selectall_arrayref.
	# It returns a list of hashrefs in list context.
	my @rows = $left_join->selectall_array();
	ok(scalar @rows > 0,        'selectall_array returns a non-empty list');
	ok(ref($rows[0]) eq 'HASH', 'each element is a hashref');
	is(scalar @rows, $ALL_CUST, 'same row count as selectall_arrayref with no criteria');
};

subtest 'remove_columns constructor parameter hides columns from the very first query' => sub {
	plan tests => 2;
	# remove_columns (constructor) must apply before any query is issued.
	my $j = Database::Join->new(
		databases      => [$cust, $score],
		join_column    => $JC,
		remove_columns => ['email', 'age_days'],
	);
	my %col_h = map { $_ => 1 } @{ $j->columns() };
	ok(!$col_h{email},    'email hidden by remove_columns constructor parameter');
	ok(!$col_h{age_days}, 'age_days hidden by remove_columns constructor parameter');
};

subtest 'selectall_arrayref: positional single-arg is shorthand for join_column criterion' => sub {
	plan tests => 2;
	# POD: selectall_arrayref('k1') is syntactic sugar for selectall_arrayref(entry => 'k1')
	my $by_shorthand = $left_join->selectall_arrayref($ALICE_KEY);
	my $by_pair      = $left_join->selectall_arrayref($JC => $ALICE_KEY);
	is(scalar @{$by_shorthand}, 1,         'positional shorthand returns exactly 1 row');
	is_deeply($by_shorthand, $by_pair,     'positional shorthand equals the named-pair form');
};

subtest 'query(): croaks with the documented unsupported-operation message' => sub {
	plan tests => 1;
	# POD: query() is not implemented on Database::Join; callers must use selectall_arrayref.
	my $j = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	throws_ok { $j->query() }
		qr/not supported on Database::Join/,
		'query() croaks with the documented message';
};

subtest 'execute(): croaks with the documented unsupported-operation message' => sub {
	plan tests => 1;
	# POD: execute() raw SQL is not implemented on Database::Join.
	my $j = Database::Join->new(databases => [$cust, $score], join_column => $JC);
	throws_ok { $j->execute() }
		qr/not supported on Database::Join/,
		'execute() croaks with the documented message';
};

diag('section 16 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 17 -- SQLite backend dispatch and object lifecycle (7 subtests)
#
# Exercises the three backend modes (array / sqlite / auto), verifies that
# the per-object temp-file is created on first query and removed on DESTROY,
# and confirms that add_database() invalidates the cache so the next query
# sees the new source.
#
# Path-disambiguation technique from CLAUDE.md: passing
#   tmpdir => '/nonexistent/__no_such_dir__'
# proves which path a query took without inspecting internals:
#   array path  -- tmpdir never accessed  → query succeeds
#   sqlite path -- File::Temp dies        → query croaks
# ===========================================================================

# Shared InMemDA fixtures for section 17 (isolated from the SQLite-backed DAs
# used earlier so test state does not bleed between sections).
my $s17_db_a = InMemDA->new(
	cols => [$JC, 'city'],
	rows => [
		{ entry => 'TX', city => 'Austin' },
		{ entry => 'CA', city => 'LA'     },
	],
	updated => 1_000_000,
);
my $s17_db_b = InMemDA->new(
	cols => [$JC, 'pop_m'],
	rows => [
		{ entry => 'TX', pop_m => 29 },
		{ entry => 'CA', pop_m => 39 },
	],
	updated => 1_000_000,
);

Readonly::Scalar my $BAD_TMPDIR => '/nonexistent/__no_such_dir__';
Readonly::Scalar my $S17_ROWS   => 2;   # two states in the fixture

subtest 'backend=array: query succeeds with an invalid tmpdir (array path never touches it)' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases => [$s17_db_a, $s17_db_b],
		join_column => $JC,
		backend     => 'array',
		tmpdir      => $BAD_TMPDIR,
	);
	my $rows;
	lives_ok { $rows = $j->selectall_arrayref() }
		'backend=array succeeds despite invalid tmpdir (tmpdir never accessed)';
	is(scalar @{$rows}, $S17_ROWS,
		'backend=array returns the correct row count');
};

subtest 'backend=auto: InMemDA stubs (no count()) fall back to the array path' => sub {
	plan tests => 1;
	# InMemDA does not define count() in its own package, so 'auto' cannot
	# determine the row count and conservatively uses the array path.
	# Proof: query succeeds even though tmpdir does not exist.
	my $j = Database::Join->new(
		databases => [$s17_db_a, $s17_db_b],
		join_column => $JC,
		backend     => 'auto',
		tmpdir      => $BAD_TMPDIR,
	);
	lives_ok { $j->selectall_arrayref() }
		'backend=auto falls back to array when DA cannot supply a row count';
};

subtest 'backend=sqlite: produces the same rows as backend=array (semantic equivalence)' => sub {
	plan tests => 2;
	my $j_arr = Database::Join->new(
		databases => [$s17_db_a, $s17_db_b],
		join_column => $JC, backend => 'array',
	);
	my $j_sql = Database::Join->new(
		databases => [$s17_db_a, $s17_db_b],
		join_column => $JC, backend => 'sqlite',
	);
	is($j_sql->count(), $j_arr->count(),
		'SQLite path returns the same row count as the array path');
	my @sql_keys = sort map { $_->{$JC} } @{ $j_sql->selectall_arrayref() };
	my @arr_keys = sort map { $_->{$JC} } @{ $j_arr->selectall_arrayref() };
	is_deeply(\@sql_keys, \@arr_keys,
		'SQLite and array paths return rows for the same join-key values');
};

subtest 'backend=sqlite: temp .db file exists while the join object is alive' => sub {
	plan tests => 2;
	my $tmpdir = tempdir(CLEANUP => 1);
	my $j = Database::Join->new(
		databases   => [$s17_db_a, $s17_db_b],
		join_column => $JC,
		backend     => 'sqlite',
		tmpdir      => $tmpdir,
	);
	$j->selectall_arrayref();   # triggers cache build → temp file created
	my @files = glob("$tmpdir/*.db");
	is(scalar @files, 1, 'exactly one .db temp file present after first query');
	ok(-f $files[0],            'temp .db file is a regular file');
};

subtest 'backend=sqlite: temp .db file removed after the join object is destroyed' => sub {
	plan tests => 1;
	my $tmpdir = tempdir(CLEANUP => 1);
	{
		my $j = Database::Join->new(
			databases   => [$s17_db_a, $s17_db_b],
			join_column => $JC,
			backend     => 'sqlite',
			tmpdir      => $tmpdir,
		);
		$j->selectall_arrayref();   # builds cache → temp file created
	}   # $j goes out of scope → DESTROY disconnects and releases File::Temp
	my @files = glob("$tmpdir/*.db");
	is(scalar @files, 0, 'no .db files remain after the join object is destroyed');
};

subtest 'backend=sqlite: add_database invalidates cache; new columns visible on next query' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases   => [$s17_db_a],
		join_column => $JC,
		backend     => 'sqlite',
	);
	$j->selectall_arrayref();   # build initial cache (only city column)
	ok(!grep({ $_ eq 'pop_m' } @{ $j->columns() }),
		'pop_m absent from columns() before add_database');
	$j->add_database($s17_db_b);
	ok( grep({ $_ eq 'pop_m' } @{ $j->columns() }),
		'pop_m visible after add_database invalidates the cache');
};

subtest 'error_invalid_backend: croaks with the documented message' => sub {
	plan tests => 1;
	throws_ok {
		Database::Join->new(
			databases   => [$s17_db_a, $s17_db_b],
			join_column => $JC,
			backend     => 'bogus',
		)
	} qr/backend.*(?:array|sqlite|auto)/i,
		'invalid backend value croaks mentioning the allowed values';
};

diag('section 17 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 18 -- SQLite backend: criteria and operator filtering (4 subtests)
#
# Query-time criteria go into per-call SQL WHERE clauses on the SQLite path.
# These tests verify that equality, operator-hashref, and compound criteria
# produce the same results as the array path, and that unsafe operators are
# silently dropped without causing an exception.
# ===========================================================================

# Shared fixtures for section 18.
my $s18_db_a = InMemDA->new(
	cols => [$JC, 'name', 'tier'],
	rows => [
		{ entry => 'A', name => 'Alpha', tier => 'gold'   },
		{ entry => 'B', name => 'Beta',  tier => 'silver' },
		{ entry => 'C', name => 'Gamma', tier => 'gold'   },
	],
	updated => 2_000_000,
);
my $s18_db_b = InMemDA->new(
	cols => [$JC, 'score'],
	rows => [
		{ entry => 'A', score => 95 },
		{ entry => 'B', score => 70 },
		{ entry => 'C', score => 55 },
	],
	updated => 2_000_000,
);

Readonly::Scalar my $S18_ALL   => 3;
Readonly::Scalar my $S18_GOLD  => 2;
Readonly::Scalar my $S18_HI    => 1;   # score > 80: only Alpha

subtest 'backend=sqlite: equality criterion returns the matching row' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases => [$s18_db_a, $s18_db_b],
		join_column => $JC, backend => 'sqlite',
	);
	my $rows = $j->selectall_arrayref(tier => 'gold');
	is(scalar @{$rows}, $S18_GOLD, 'tier=gold returns the two gold-tier rows');
	ok((grep { $_->{tier} eq 'gold' } @{$rows}) == $S18_GOLD,
		'all returned rows have tier=gold');
};

subtest 'backend=sqlite: operator-hashref criterion (>) filters correctly' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases => [$s18_db_a, $s18_db_b],
		join_column => $JC, backend => 'sqlite',
	);
	my $rows = $j->selectall_arrayref(score => { '>' => 80 });
	is(scalar @{$rows}, $S18_HI,
		'score > 80 returns exactly one row (Alpha with score=95)');
	is($rows->[0]{name}, 'Alpha', 'returned row is Alpha');
};

subtest 'backend=sqlite: compound criteria on two columns filter with AND semantics' => sub {
	plan tests => 1;
	# tier=gold AND score < 90: Alpha (95 fails < 90), Beta (silver fails), Gamma (55 passes).
	# Expected: only Gamma.
	my $j = Database::Join->new(
		databases => [$s18_db_a, $s18_db_b],
		join_column => $JC, backend => 'sqlite',
	);
	my $rows = $j->selectall_arrayref(tier => 'gold', score => { '<' => 90 });
	is(scalar @{$rows}, 1,
		'tier=gold AND score<90 returns exactly one row (Gamma)');
};

subtest 'backend=sqlite: unsafe operator key is silently dropped (no SQL injection, no croak)' => sub {
	plan tests => 2;
	# A hashref criterion with an operator key not in %SAFE_SQL_OPS must be
	# dropped before interpolation.  The query must succeed and return all rows
	# (no WHERE predicate applied for the invalid operator).
	my $j = Database::Join->new(
		databases => [$s18_db_a, $s18_db_b],
		join_column => $JC, backend => 'sqlite',
	);
	my $rows;
	lives_ok { $rows = $j->selectall_arrayref(score => { 'DROP TABLE t1;--' => 99 }) }
		'unsafe operator key does not croak';
	is(scalar @{$rows}, $S18_ALL,
		'all rows returned when the only operator key is unsafe (no WHERE clause applied)');
};

diag('section 18 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 19 -- SQLite backend with advanced features (3 subtests)
#
# Confirms that collision_prefix, join_map, and permanent filters all work
# correctly end-to-end on the SQLite path, producing identical semantics to
# the in-memory array path.
# ===========================================================================

subtest 'backend=sqlite: collision_prefix preserved in merged rows' => sub {
	plan tests => 3;
	# Two databases both have a 'notes' column.  With collision_prefix => {1 => 'ext'},
	# the merged row must carry 'notes' (primary) and 'ext.notes' (secondary).
	my $db0 = InMemDA->new(
		cols => [$JC, 'notes', 'amount'],
		rows => [ { entry => 'K1', notes => 'note-a', amount => 10 } ],
		updated => 3_000_000,
	);
	my $db1 = InMemDA->new(
		cols => [$JC, 'notes', 'price'],
		rows => [ { entry => 'K1', notes => 'note-b', price => 5 } ],
		updated => 3_000_000,
	);
	my $j = Database::Join->new(
		databases        => [$db0, $db1],
		join_column      => $JC,
		backend          => 'sqlite',
		collision_prefix => { 1 => 'ext' },
	);
	my $row = $j->fetchrow_hashref($JC => 'K1');
	is($row->{notes},      'note-a', "plain 'notes' holds the primary-DB value on SQLite path");
	is($row->{'ext.notes'}, 'note-b', "'ext.notes' holds the secondary-DB value on SQLite path");
	ok(!exists $row->{'ext.entry'},
		'join_column is never prefixed even when collision_prefix is active');
};

subtest 'backend=sqlite: join_map ON clause correctly links differently-named key columns' => sub {
	plan tests => 2;
	# DB 0 uses 'entry' as join key; DB 1 uses 'ref_id'.
	# The SQLite JOIN ON clause must use the local alias for each source.
	my $db0 = InMemDA->new(
		cols => [$JC, 'city'],
		rows => [
			{ entry => 'TX', city => 'Austin' },
			{ entry => 'CA', city => 'LA'     },
		],
		updated => 3_000_000,
	);
	my $db1 = InMemDA->new(
		cols => ['ref_id', 'pop_m'],
		rows => [
			{ ref_id => 'TX', pop_m => 29 },
			{ ref_id => 'CA', pop_m => 39 },
		],
		updated => 3_000_000,
	);
	my $j = Database::Join->new(
		databases   => [$db0, $db1],
		join_column => $JC,
		join_map    => { 1 => 'ref_id' },
		backend     => 'sqlite',
	);
	is($j->count(), 2, 'join_map join: SQLite path returns both rows');
	my $row = $j->fetchrow_hashref('TX');
	is($row->{pop_m}, 29, 'join_map join: TX row has correct pop_m on SQLite path');
};

subtest 'backend=sqlite: permanent filter restricts rows from the secondary source' => sub {
	plan tests => 2;
	# filter on DB 1: score > 60.  Alice=95 and Beta=70 pass; Gamma=55 fails.
	# On the SQLite path, filter criteria are applied at spill time.
	my $db0 = InMemDA->new(
		cols => [$JC, 'name'],
		rows => [
			{ entry => 'A', name => 'Alice' },
			{ entry => 'B', name => 'Beta'  },
			{ entry => 'C', name => 'Gamma' },
		],
		updated => 3_000_000,
	);
	my $db1 = InMemDA->new(
		cols => [$JC, 'score'],
		rows => [
			{ entry => 'A', score => 95 },
			{ entry => 'B', score => 70 },
			{ entry => 'C', score => 55 },
		],
		updated => 3_000_000,
	);
	my $j = Database::Join->new(
		databases   => [$db0, $db1],
		join_column => $JC,
		backend     => 'sqlite',
		join_type   => 'left',
		filters     => { 1 => { score => { '>' => 60 } } },
	);
	# The filtered secondary DA acts as an inner-join partner: Gamma (score=55)
	# is excluded because it has no row in the filtered secondary result.
	is($j->count(), 2,
		'filter applied at spill time: only 2 rows survive score>60 on SQLite path');
	my @names = sort map { $_->{name} } @{ $j->selectall_arrayref() };
	is_deeply(\@names, ['Alice', 'Beta'],
		'surviving rows are Alice (score=95) and Beta (score=70)');
};

diag('section 19 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 20 -- limit / offset pagination (5 subtests)
#
# selectall_arrayref and selectall_array accept limit => N (positive integer)
# and offset => M (non-negative integer).  The SQLite path appends LIMIT/OFFSET
# as bind parameters; the array path uses splice().  Both paths must agree on
# the resulting row count for the same arguments.
# ===========================================================================

Readonly::Scalar my $S20_TOTAL  => 5;
Readonly::Scalar my $S20_LIMIT  => 2;
Readonly::Scalar my $S20_OFFSET => 2;

# Five-row fixture: enough rows to distinguish limit, offset, and page cases.
my $s20_db_a = InMemDA->new(
	cols    => [$JC, 'label'],
	rows    => [ map { { entry => "P$_", label => "Label$_" } } (1..5) ],
	updated => 4_000_000,
);
my $s20_db_b = InMemDA->new(
	cols    => [$JC, 'val'],
	rows    => [ map { { entry => "P$_", val => $_ * 10 } } (1..5) ],
	updated => 4_000_000,
);

subtest 'limit: array path returns first N rows' => sub {
	plan tests => 1;
	my $j = Database::Join->new(
		databases => [$s20_db_a, $s20_db_b], join_column => $JC,
		backend   => 'array',
	);
	my $rows = $j->selectall_arrayref(limit => $S20_LIMIT);
	is(scalar @{$rows}, $S20_LIMIT,
		"limit => $S20_LIMIT returns $S20_LIMIT rows on the array path");
};

subtest 'offset: array path skips first N rows' => sub {
	plan tests => 1;
	my $j = Database::Join->new(
		databases => [$s20_db_a, $s20_db_b], join_column => $JC,
		backend   => 'array',
	);
	my $rows = $j->selectall_arrayref(offset => $S20_OFFSET);
	is(scalar @{$rows}, $S20_TOTAL - $S20_OFFSET,
		"offset => $S20_OFFSET skips first $S20_OFFSET rows on the array path");
};

subtest 'limit+offset: array path returns a middle page' => sub {
	plan tests => 1;
	# limit=2, offset=2 on 5 rows means rows 3 and 4 -- exactly 2 rows returned.
	my $j = Database::Join->new(
		databases => [$s20_db_a, $s20_db_b], join_column => $JC,
		backend   => 'array',
	);
	my $page = $j->selectall_arrayref(limit => 2, offset => 2);
	is(scalar @{$page}, 2, 'limit=2 offset=2 on 5 rows returns exactly 2 rows');
};

subtest 'limit: SQLite path row count equals array path row count' => sub {
	plan tests => 1;
	# Verify semantic equivalence between paths; row ordering is not compared
	# here (no ORDER BY) to keep the test independent of sort order.
	my $j_arr = Database::Join->new(
		databases => [$s20_db_a, $s20_db_b], join_column => $JC,
		backend   => 'array',
	);
	my $j_sql = Database::Join->new(
		databases => [$s20_db_a, $s20_db_b], join_column => $JC,
		backend   => 'sqlite',
	);
	is(scalar @{ $j_sql->selectall_arrayref(limit => $S20_LIMIT) },
	   scalar @{ $j_arr->selectall_arrayref(limit => $S20_LIMIT) },
	   'limit on SQLite path yields the same row count as the array path');
};

subtest 'limit+offset: SQLite path row count equals array path row count' => sub {
	plan tests => 1;
	my $j_arr = Database::Join->new(
		databases => [$s20_db_a, $s20_db_b], join_column => $JC,
		backend   => 'array',
	);
	my $j_sql = Database::Join->new(
		databases => [$s20_db_a, $s20_db_b], join_column => $JC,
		backend   => 'sqlite',
	);
	is(scalar @{ $j_sql->selectall_arrayref(limit => 2, offset => 1) },
	   scalar @{ $j_arr->selectall_arrayref(limit => 2, offset => 1) },
	   'limit+offset on SQLite path yields the same row count as the array path');
};

diag('section 20 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 21 -- sort_by: ascending and descending sort (4 subtests)
#
# sort_by => 'col' sorts ascending; sort_by => ['col', 'DESC'] descending.
# The SQLite backend generates an ORDER BY clause; the array backend uses
# Perl string cmp.  Using single-character keys (A, B, C) means both paths
# agree: string comparison and SQL TEXT comparison produce the same ordering.
# ===========================================================================

Readonly::Scalar my $S21_A_KEY => 'A';
Readonly::Scalar my $S21_B_KEY => 'B';
Readonly::Scalar my $S21_C_KEY => 'C';

# Rows deliberately inserted in non-sorted order (C, A, B) to verify that
# sort_by is reordering and not just preserving insertion order.
my $s21_db_a = InMemDA->new(
	cols    => [$JC, 'name'],
	rows    => [
		{ entry => $S21_C_KEY, name => 'Charlie' },
		{ entry => $S21_A_KEY, name => 'Alice'   },
		{ entry => $S21_B_KEY, name => 'Bob'     },
	],
	updated => 5_000_000,
);
my $s21_db_b = InMemDA->new(
	cols    => [$JC, 'rank'],
	rows    => [
		{ entry => $S21_C_KEY, rank => 3 },
		{ entry => $S21_A_KEY, rank => 1 },
		{ entry => $S21_B_KEY, rank => 2 },
	],
	updated => 5_000_000,
);

subtest 'sort_by: array path returns rows in ascending column order' => sub {
	plan tests => 1;
	my $j = Database::Join->new(
		databases => [$s21_db_a, $s21_db_b], join_column => $JC,
		backend   => 'array',
	);
	my @keys = map { $_->{$JC} } @{ $j->selectall_arrayref(sort_by => $JC) };
	is_deeply(\@keys, [$S21_A_KEY, $S21_B_KEY, $S21_C_KEY],
		'sort_by ascending on the array path sorts A < B < C');
};

subtest 'sort_by: array path returns rows in descending column order' => sub {
	plan tests => 1;
	my $j = Database::Join->new(
		databases => [$s21_db_a, $s21_db_b], join_column => $JC,
		backend   => 'array',
	);
	my @keys = map { $_->{$JC} } @{ $j->selectall_arrayref(sort_by => [$JC, 'DESC']) };
	is_deeply(\@keys, [$S21_C_KEY, $S21_B_KEY, $S21_A_KEY],
		'sort_by descending on the array path sorts C > B > A');
};

subtest 'sort_by: SQLite path ascending matches array path result order' => sub {
	plan tests => 1;
	my $j_arr = Database::Join->new(
		databases => [$s21_db_a, $s21_db_b], join_column => $JC, backend => 'array',
	);
	my $j_sql = Database::Join->new(
		databases => [$s21_db_a, $s21_db_b], join_column => $JC, backend => 'sqlite',
	);
	my @arr = map { $_->{$JC} } @{ $j_arr->selectall_arrayref(sort_by => $JC) };
	my @sql = map { $_->{$JC} } @{ $j_sql->selectall_arrayref(sort_by => $JC) };
	is_deeply(\@sql, \@arr,
		'sort_by ascending: SQLite path produces the same key sequence as array path');
};

subtest 'sort_by: SQLite path descending matches array path result order' => sub {
	plan tests => 1;
	my $j_arr = Database::Join->new(
		databases => [$s21_db_a, $s21_db_b], join_column => $JC, backend => 'array',
	);
	my $j_sql = Database::Join->new(
		databases => [$s21_db_a, $s21_db_b], join_column => $JC, backend => 'sqlite',
	);
	my @arr = map { $_->{$JC} } @{ $j_arr->selectall_arrayref(sort_by => [$JC, 'DESC']) };
	my @sql = map { $_->{$JC} } @{ $j_sql->selectall_arrayref(sort_by => [$JC, 'DESC']) };
	is_deeply(\@sql, \@arr,
		'sort_by descending: SQLite path produces the same key sequence as array path');
};

diag('section 21 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 22 -- schema type consistency validation (3 subtests)
#
# _validate_schema_types fires at new() and add_database() time.  For every
# column shared across two DAs (without collision_prefix), it compares the
# schema() type strings and carps warn_schema_type_mismatch when they differ.
# The join_column itself and any column that has a collision_prefix are exempt.
# ===========================================================================

# Two DAs that both expose a 'score' column with conflicting types.
# Without collision_prefix the merge is last-DB-wins (no croak), but the type
# mismatch triggers a carp during construction and during add_database.
my $s22_mismatch_a = InMemDA->new(
	cols    => [$JC, 'score'],
	rows    => [ { entry => 'X', score => '10' } ],
	schema  => { score => { type => 'TEXT' } },
	updated => 6_000_000,
);
my $s22_mismatch_b = InMemDA->new(
	cols    => [$JC, 'score'],
	rows    => [ { entry => 'X', score => 10 } ],
	schema  => { score => { type => 'INTEGER' } },
	updated => 6_000_000,
);
# Two DAs where both declare the same type -- no carp expected.
my $s22_same_a = InMemDA->new(
	cols    => [$JC, 'score'],
	rows    => [ { entry => 'X', score => 10 } ],
	schema  => { score => { type => 'INTEGER' } },
	updated => 6_000_000,
);
my $s22_same_b = InMemDA->new(
	cols    => [$JC, 'score'],
	rows    => [ { entry => 'X', score => 10 } ],
	schema  => { score => { type => 'INTEGER' } },
	updated => 6_000_000,
);

subtest 'schema type validation: carp emitted when shared column has mismatched types' => sub {
	plan tests => 2;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $j = Database::Join->new(
		databases => [$s22_mismatch_a, $s22_mismatch_b], join_column => $JC,
	);
	ok(@warnings, 'warn_schema_type_mismatch carp fires at construction time');
	like($warnings[0], qr/score/i,
		'carp message names the mismatched column (score)');
};

subtest 'schema type validation: no carp when all shared column types agree' => sub {
	plan tests => 1;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $j = Database::Join->new(
		databases => [$s22_same_a, $s22_same_b], join_column => $JC,
	);
	ok(!@warnings, 'no warn_schema_type_mismatch when both DAs declare the same type');
};

subtest 'schema type validation: add_database also fires carp for type mismatch' => sub {
	plan tests => 2;
	# Build the join with only the first DA (no mismatch possible with one source),
	# then add the second DA whose type conflicts.
	my $j;
	{
		local $SIG{__WARN__} = sub {};  # suppress any construction-time noise
		$j = Database::Join->new(databases => [$s22_mismatch_a], join_column => $JC);
	}
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	$j->add_database($s22_mismatch_b);
	ok(@warnings, 'warn_schema_type_mismatch carp fires during add_database');
	like($warnings[0], qr/score/i,
		'add_database carp message names the mismatched column (score)');
};

diag('section 22 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 23 -- parallel => 1 constructor flag (3 subtests)
#
# When parallel => 1 is set and there are three or more databases (primary +
# two or more secondaries), secondary DA fetches are issued concurrently when
# the threads module is available; otherwise the module falls back to sequential
# with a carp.  Either way the result must be semantically identical.
# ===========================================================================

subtest 'parallel: 2-DB join with parallel=1 executes without error and returns correct data' => sub {
	plan tests => 2;
	# Parallel threshold requires >=2 secondaries, so this is a no-op for the
	# parallel flag.  Verifies the constructor accepts the flag and behaves normally.
	my $j;
	lives_ok {
		$j = Database::Join->new(
			databases => [$cust, $score], join_column => $JC, parallel => 1,
		);
	} 'parallel => 1 accepted in the constructor (2-DB join)';
	is($j->count(), $ALL_CUST,
		'parallel => 1 (2-DB, threshold not met) returns the correct row count');
};

subtest 'parallel: 3-DB join with parallel=1 returns the same row count as parallel=0' => sub {
	plan tests => 1;
	local $SIG{__WARN__} = sub {};   # suppress carp if threads module unavailable
	my $j_seq = Database::Join->new(
		databases => [$cust, $score, $region], join_column => $JC,
		join_type => 'inner', parallel => 0,
	);
	my $j_par = Database::Join->new(
		databases => [$cust, $score, $region], join_column => $JC,
		join_type => 'inner', parallel => 1,
	);
	is($j_par->count(), $j_seq->count(),
		'parallel=1 (3-DB inner join) returns the same count as parallel=0');
};

subtest 'parallel: 3-DB join with parallel=1 returns the same merged rows as parallel=0' => sub {
	plan tests => 1;
	local $SIG{__WARN__} = sub {};   # suppress carp if threads module unavailable
	my $j_seq = Database::Join->new(
		databases => [$cust, $score, $region], join_column => $JC,
		join_type => 'inner', parallel => 0,
	);
	my $j_par = Database::Join->new(
		databases => [$cust, $score, $region], join_column => $JC,
		join_type => 'inner', parallel => 1,
	);
	my @seq_keys = sort map { $_->{$JC} } @{ $j_seq->selectall_arrayref() };
	my @par_keys = sort map { $_->{$JC} } @{ $j_par->selectall_arrayref() };
	is_deeply(\@par_keys, \@seq_keys,
		'parallel=1 and parallel=0 return rows with identical join-key sets');
};

diag('section 23 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 24 -- dbi_source() on Database::Join itself (3 subtests)
#
# A Database::Join object with a sqlite backend implements dbi_source(),
# returning { dbh => $dbh, table => '_dj_result' } pointing at a materialised
# view in its temp SQLite file.  The array backend returns undef.  The parent
# can ATTACH the file and query _dj_result directly to compose nested joins.
# ===========================================================================

my $s24_db_a = InMemDA->new(
	cols    => [$JC, 'city'],
	rows    => [
		{ entry => 'TX', city => 'Austin' },
		{ entry => 'CA', city => 'LA'     },
	],
	updated => 7_000_000,
);
my $s24_db_b = InMemDA->new(
	cols    => [$JC, 'pop_m'],
	rows    => [
		{ entry => 'TX', pop_m => 29 },
		{ entry => 'CA', pop_m => 39 },
	],
	updated => 7_000_000,
);

Readonly::Scalar my $S24_ROWS => 2;

subtest 'dbi_source: returns undef for the array backend' => sub {
	plan tests => 1;
	my $j = Database::Join->new(
		databases => [$s24_db_a, $s24_db_b], join_column => $JC,
		backend   => 'array',
	);
	$j->selectall_arrayref();   # trigger any lazy initialisation
	ok(!defined $j->dbi_source(),
		'dbi_source() returns undef on the array backend');
};

subtest 'dbi_source: returns a hashref with dbh and table keys for the sqlite backend' => sub {
	plan tests => 3;
	my $j = Database::Join->new(
		databases => [$s24_db_a, $s24_db_b], join_column => $JC,
		backend   => 'sqlite',
	);
	$j->selectall_arrayref();   # build the SQLite cache and materialise _dj_result
	my $src = $j->dbi_source();
	ok(defined $src,                    'dbi_source() returns a defined value on sqlite backend');
	ok(ref($src) eq 'HASH',             'dbi_source() return value is a hashref');
	is($src->{table}, '_dj_result',     "dbi_source()->{table} is '_dj_result'");
};

subtest 'dbi_source: the returned DBI handle can query _dj_result directly' => sub {
	plan tests => 2;
	# Proves that _dj_result is a real table accessible via the returned handle,
	# enabling a parent Database::Join to compose nested joins without copying rows.
	my $j = Database::Join->new(
		databases => [$s24_db_a, $s24_db_b], join_column => $JC,
		backend   => 'sqlite',
	);
	$j->selectall_arrayref();   # materialise _dj_result
	my $src = $j->dbi_source();
	ok($src->{dbh}->isa('DBI::db'),
		'dbi_source()->{dbh} is a live DBI::db handle');
	my ($count) = $src->{dbh}->selectrow_array(
		sprintf('SELECT COUNT(*) FROM "%s"', $src->{table})
	);
	is($count, $S24_ROWS,
		'COUNT(*) on _dj_result returns the correct number of materialised rows');
};

diag('section 24 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 25 -- IS NULL / IS NOT NULL / IN / NOT IN operators (4 subtests)
#
# These operator-hashref forms were added in 0.007.0 for the SQLite backend.
# IS NULL / IS NOT NULL generate no bind parameter (fixed SQL keywords).
# IN / NOT IN take an arrayref value; each element becomes a separate bind
# parameter so injection via list elements is impossible.
# ===========================================================================

# InMemDA rows with deliberate undef values: when spilled to SQLite these become
# NULL, allowing IS NULL / IS NOT NULL to be tested end-to-end.
my $s25_db_a = InMemDA->new(
	cols    => [$JC, 'name'],
	rows    => [
		{ entry => 'A', name => 'Alpha' },
		{ entry => 'B', name => undef   },   # NULL in SQLite after spill
		{ entry => 'C', name => 'Gamma' },
	],
	updated => 8_000_000,
);
my $s25_db_b = InMemDA->new(
	cols    => [$JC, 'score'],
	rows    => [
		{ entry => 'A', score => 95 },
		{ entry => 'B', score => 70 },
		{ entry => 'C', score => 55 },
	],
	updated => 8_000_000,
);

Readonly::Scalar my $S25_NULL_COUNT    => 1;   # rows with name IS NULL (entry B)
Readonly::Scalar my $S25_NOTNULL_COUNT => 2;   # rows with name IS NOT NULL (A and C)
Readonly::Scalar my $S25_IN_COUNT      => 2;   # score IN (70, 95) -- entries A and B
Readonly::Scalar my $S25_NOTIN_COUNT   => 2;   # score NOT IN (95) -- entries B and C

subtest 'IS NULL: SQLite path returns only rows where the column value is NULL' => sub {
	plan tests => 2;
	my $j = Database::Join->new(
		databases => [$s25_db_a, $s25_db_b], join_column => $JC,
		backend   => 'sqlite',
	);
	my $rows = $j->selectall_arrayref(name => { 'IS NULL' => undef });
	is(scalar @{$rows}, $S25_NULL_COUNT,
		"IS NULL returns $S25_NULL_COUNT row (entry B has a NULL name)");
	is($rows->[0]{$JC}, 'B', 'IS NULL returns the correct row (entry B)');
};

subtest 'IS NOT NULL: SQLite path returns only rows where the column value is not NULL' => sub {
	plan tests => 1;
	my $j = Database::Join->new(
		databases => [$s25_db_a, $s25_db_b], join_column => $JC,
		backend   => 'sqlite',
	);
	my $rows = $j->selectall_arrayref(name => { 'IS NOT NULL' => undef });
	is(scalar @{$rows}, $S25_NOTNULL_COUNT,
		"IS NOT NULL returns $S25_NOTNULL_COUNT rows (A and C have non-NULL names)");
};

subtest 'IN: SQLite path returns only rows whose column value is in the list' => sub {
	plan tests => 1;
	# score IN (70, 95): entries A (95) and B (70) qualify; C (55) does not.
	my $j = Database::Join->new(
		databases => [$s25_db_a, $s25_db_b], join_column => $JC,
		backend   => 'sqlite',
	);
	my $rows = $j->selectall_arrayref(score => { 'IN' => [70, 95] });
	is(scalar @{$rows}, $S25_IN_COUNT,
		"IN (70, 95) returns $S25_IN_COUNT rows (entries A and B)");
};

subtest 'NOT IN: SQLite path returns only rows whose column value is not in the list' => sub {
	plan tests => 1;
	# score NOT IN (95): entries B (70) and C (55) qualify; A (95) does not.
	my $j = Database::Join->new(
		databases => [$s25_db_a, $s25_db_b], join_column => $JC,
		backend   => 'sqlite',
	);
	my $rows = $j->selectall_arrayref(score => { 'NOT IN' => [95] });
	is(scalar @{$rows}, $S25_NOTIN_COUNT,
		"NOT IN (95) returns $S25_NOTIN_COUNT rows (entries B and C)");
};

diag('section 25 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 26 -- count() correctness on the SQLite backend (2 subtests)
#
# count() on the SQLite path executes SELECT COUNT(*) against the cached join
# tables rather than fetching all rows.  The result must agree with the length
# of selectall_arrayref for equivalent criteria.
# ===========================================================================

subtest 'count(): SQLite backend count agrees with selectall_arrayref length (no criteria)' => sub {
	plan tests => 1;
	# Reuse the s18 fixtures (Alpha/Beta/Gamma with tier and score) which are
	# already built -- no new fixture needed.
	my $j = Database::Join->new(
		databases => [$s18_db_a, $s18_db_b], join_column => $JC,
		backend   => 'sqlite',
	);
	is($j->count(),
	   scalar @{ $j->selectall_arrayref() },
	   'count() on SQLite path equals the length of selectall_arrayref() with no criteria');
};

subtest 'count(): SQLite backend count with criteria agrees with filtered selectall_arrayref' => sub {
	plan tests => 1;
	my $j = Database::Join->new(
		databases => [$s18_db_a, $s18_db_b], join_column => $JC,
		backend   => 'sqlite',
	);
	my $filtered = $j->selectall_arrayref(tier => 'gold');
	is($j->count(tier => 'gold'),
	   scalar @{$filtered},
	   'count(tier => gold) on SQLite path equals the filtered selectall_arrayref length');
};

diag('section 26 done') if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 27 -- updated() resilience: missing and throwing implementations (2 subtests)
#
# updated() silently skips component DAs that do not implement updated() or
# whose updated() throws an exception.  Returns undef when no component DA
# implements updated() at all.  Regression for the 0.007.0 fix.
# ===========================================================================

# IntBareDA: a minimal duck-type DA with NO updated() method.  Has only the
# two methods Database::Join requires by its duck-type guard: columns() and
# selectall_arrayref().
{
	package IntBareDA;
	sub new {
		my ($class, %args) = @_;
		return bless { _cols => $args{cols} // [], _rows => $args{rows} // [] }, $class;
	}
	sub columns            { return $_[0]->{_cols} }
	sub schema             { return {} }
	sub selectall_arrayref { return $_[0]->{_rows} }
	sub DESTROY {}
}

# IntThrowUpdDA: inherits from InMemDA but overrides updated() to die,
# exercising the "skip DAs whose updated() throws" branch.
{
	package IntThrowUpdDA;
	our @ISA = ('InMemDA');
	sub updated { die "simulated updated() failure\n" }
	sub DESTROY {}
}

subtest 'updated(): returns undef when no component DA implements updated()' => sub {
	plan tests => 1;
	# IntBareDA has no updated() method; the join must return undef, not croak.
	my $db = IntBareDA->new(
		cols => [$JC, 'x'],
		rows => [ { entry => 'K', x => 1 } ],
	);
	my $j = Database::Join->new(databases => [$db], join_column => $JC);
	ok(!defined $j->updated(),
		'updated() returns undef when no component DA implements updated()');
};

subtest 'updated(): silently skips a component DA whose updated() throws' => sub {
	plan tests => 2;
	# One good DA with a known timestamp; one that throws from updated().
	# The join must return the good timestamp without propagating the exception.
	Readonly::Scalar my $GOOD_TS => 9_999_999;
	my $good_db = InMemDA->new(
		cols    => [$JC, 'x'],
		rows    => [ { entry => 'K', x => 1 } ],
		updated => $GOOD_TS,
	);
	my $bad_db = IntThrowUpdDA->new(
		cols    => [$JC, 'y'],
		rows    => [ { entry => 'K', y => 2 } ],
		updated => 0,   # irrelevant -- updated() will die before returning
	);
	my $j = Database::Join->new(databases => [$good_db, $bad_db], join_column => $JC);
	my $ts;
	lives_ok { $ts = $j->updated() }
		'updated() does not propagate a die thrown by a component DA';
	is($ts, $GOOD_TS,
		'updated() returns the good component timestamp, silently skipping the one that threw');
};

diag('section 27 done -- integration tests complete') if $ENV{TEST_VERBOSE};
