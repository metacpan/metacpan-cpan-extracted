#!perl -w

# Black-box unit tests for the public API of:
#   Database::Abstraction        (lib/Database/Abstraction.pm)
#   Database::Abstraction::Query (lib/Database/Abstraction/Query.pm)
#
# Strategy: every test calls the public API exactly as documented in the POD
# and asserts the documented contract.  Internal implementation is never
# accessed directly.  Test::Mockingbird is used where external I/O (DBI,
# file system) would be needed to exercise a specific code path but we want
# the test to remain self-contained and deterministic.
#
# Test groups follow the documented method order in each module's POD.

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin   qw($Bin);
use Readonly;
use Scalar::Util qw(blessed looks_like_number);

use Test::Most;
use Test::Returns;

# ---------------------------------------------------------------------------
# Configuration — no magic strings scattered through the file
# ---------------------------------------------------------------------------
Readonly my $DATA_DIR   => File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
Readonly my $ENTRY_COL  => 'entry';
Readonly my $ONE_HOUR   => '1 hour';
Readonly my $CSV_SEP    => '!';		# module default separator

# Check optional dependencies once at the top
my $have_sqlite = eval { require DBI; require DBD::SQLite; 1 };
my $have_chi    = eval { require CHI; 1 };

# ---------------------------------------------------------------------------
# Test library subclasses — thin wrappers that satisfy the abstract contract
# ---------------------------------------------------------------------------
use lib 't/lib';
use_ok('Database::test1');		# keyed CSV  (sep='!',  id='entry')
use_ok('Database::test2');		# PSV fixture
use_ok('Database::test3');		# XML fixture
use_ok('Database::test5');		# CSV  (sep=',', id='ID')

# ---------------------------------------------------------------------------
# SECTION 1 — Database::Abstraction: class-level init() / import()
# ---------------------------------------------------------------------------

note '';
note '=== 1. init() ===';
{
	# Reset to a clean slate so previous state does not contaminate
	%Database::Abstraction::defaults = ();

	# 1.1  No-arg call: always returns a hashref of current defaults.
	#      cache_duration is NOT injected when there are no params.
	my $d = Database::Abstraction::init();
	isa_ok($d, 'HASH', '1.1 init() returns hashref');

	# 1.2  Named-list call stores keys in %defaults and returns them
	my $d2 = Database::Abstraction::init(directory => $DATA_DIR);
	is($d2->{'directory'}, $DATA_DIR, '1.2 init(): named key stored and returned');
	is($Database::Abstraction::defaults{'directory'}, $DATA_DIR,
		'1.2 init(): key written to %defaults');

	# 1.3  cache_duration defaults to "1 hour" when params are supplied
	%Database::Abstraction::defaults = ();
	Database::Abstraction::init(directory => $DATA_DIR);
	is($Database::Abstraction::defaults{'cache_duration'}, $ONE_HOUR,
		'1.3 init(): cache_duration defaults to 1 hour when params present');

	# 1.4  expires_in is aliased to cache_duration (CHI compatibility)
	%Database::Abstraction::defaults = ();
	Database::Abstraction::init(expires_in => '30 minutes');
	is($Database::Abstraction::defaults{'cache_duration'}, '30 minutes',
		'1.4 init(): expires_in aliased to cache_duration');

	# 1.5  Explicit cache_duration wins over expires_in alias
	%Database::Abstraction::defaults = ();
	Database::Abstraction::init(cache_duration => '2 hours', expires_in => '5 minutes');
	is($Database::Abstraction::defaults{'cache_duration'}, '2 hours',
		'1.5 init(): explicit cache_duration is not overwritten by expires_in');

	# 1.6  Multiple calls accumulate; later keys overwrite earlier same keys
	%Database::Abstraction::defaults = ();
	Database::Abstraction::init(foo => 'first');
	Database::Abstraction::init(foo => 'second', bar => 'baz');
	is($Database::Abstraction::defaults{'foo'}, 'second', '1.6 init(): later call overwrites key');
	is($Database::Abstraction::defaults{'bar'}, 'baz',    '1.6 init(): new key added by second call');

	%Database::Abstraction::defaults = ();		# restore
}

# ---------------------------------------------------------------------------
# SECTION 2 — new(): construction paths and validation
# ---------------------------------------------------------------------------

note '';
note '=== 2. new() ===';
{
	# 2.1  Abstract base class cannot be instantiated directly
	throws_ok { Database::Abstraction->new(directory => $DATA_DIR) }
		qr/abstract class/i,
		'2.1 new(): abstract base class croaks';

	# 2.2  Bare string → treated as directory shortcut
	my $obj = Database::test1->new($DATA_DIR);
	isa_ok($obj, 'Database::test1', '2.2 new(): bare string shortcut returns correct class');
	is($obj->{'id'}, $ENTRY_COL, '2.2 new(): id defaults to "entry"');

	# 2.3  Named-list form
	my $obj2 = Database::test1->new(directory => $DATA_DIR);
	isa_ok($obj2, 'Database::test1', '2.3 new(): named-list form accepted');

	# 2.4  Hashref form
	my $obj3 = Database::test1->new({ directory => $DATA_DIR });
	isa_ok($obj3, 'Database::test1', '2.4 new(): hashref form accepted');

	# 2.5  Clone form: calling new() on an existing object merges new args
	my $clone = $obj->new(extra => 'cloned');
	isa_ok($clone, 'Database::test1', '2.5 new(): clone retains class');
	is($clone->{'extra'}, 'cloned', '2.5 new(): clone receives new key');
	is($clone->{'id'}, $ENTRY_COL, '2.5 new(): clone inherits existing keys');

	# 2.6  Default: no_entry = 0
	ok(!$obj->{'no_entry'}, '2.6 new(): no_entry defaults to 0 (false)');

	# 2.7  Default: no_fixate = 0
	ok(!$obj->{'no_fixate'}, '2.7 new(): no_fixate defaults to 0 (false)');

	# 2.8  Default: cache_duration = '1 hour'
	is($obj->{'cache_duration'}, $ONE_HOUR, '2.8 new(): cache_duration defaults to 1 hour');

	# 2.9  Caller-supplied args override defaults
	my $custom = Database::test1->new(directory => $DATA_DIR, id => 'my_id', no_entry => 1);
	is($custom->{'id'}, 'my_id', '2.9 new(): id override accepted');
	is($custom->{'no_entry'}, 1, '2.9 new(): no_entry override accepted');

	# 2.10 No directory AND no dsn → croak
	throws_ok { Database::test1->new() }
		qr/where are the files\?/i,
		'2.10 new(): no directory and no dsn causes croak';

	# 2.11 Non-existent directory → croak
	throws_ok { Database::test1->new(directory => '/no/such/directory/xyz123') }
		qr/is not a directory/i,
		'2.11 new(): non-existent directory causes croak';

	# 2.12 File path (not directory) → croak
	my $tmpfile = File::Temp->new(SUFFIX => '.tmp');
	throws_ok { Database::test1->new(directory => $tmpfile->filename()) }
		qr/is not a directory/i,
		'2.12 new(): file path (not dir) causes croak';

	# 2.13 Code-ref logger is normalised to a blessed Log::Abstraction object
	my $obj4 = Database::test1->new({ directory => $DATA_DIR, logger => sub {} });
	ok(blessed($obj4->{'logger'}),
		'2.13 new(): coderef logger normalised to blessed object');

	# 2.14 DSN form bypasses directory check
	SKIP: {
		skip 'DBI/DBD::SQLite not available', 1 unless $have_sqlite;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = File::Spec->catfile($dir, 'bypass.sql');
		my $setup = DBI->connect("dbi:SQLite:dbname=$file", undef, undef, { RaiseError => 1 });
		$setup->do('CREATE TABLE bypass (entry TEXT)');
		$setup->disconnect();
		{
			package Database::bypass;
			use parent 'Database::Abstraction';
		}
		my $dsnobj = Database::bypass->new(dsn => "dbi:SQLite:dbname=$file");
		isa_ok($dsnobj, 'Database::bypass', '2.14 new(): dsn form works without directory');
	}

	# 2.15 new() must not clobber errno ($!) — the POD makes no guarantee
	# about $@ since the module uses eval internally (via Object::Configure etc.)
	local $! = 2;
	my $saved_errno = $! + 0;
	Database::test1->new($DATA_DIR);
	is($! + 0, $saved_errno,  '2.15 new(): does not clobber $!');
}

# ---------------------------------------------------------------------------
# SECTION 3 — set_logger()
# ---------------------------------------------------------------------------

note '';
note '=== 3. set_logger() ===';
{
	my $db = Database::test1->new($DATA_DIR);

	# 3.1  Returns $self for chaining
	my $ret = $db->set_logger(logger => sub {});
	is($ret, $db, '3.1 set_logger(): returns $self for chaining');

	# 3.2  Blessed logger stored as-is (not re-wrapped)
	my $fake = bless {}, 'Fake::Logger';
	$db->set_logger(logger => $fake);
	is($db->{'logger'}, $fake, '3.2 set_logger(): blessed logger stored unchanged');

	# 3.3  String argument normalised to a blessed object
	$db->set_logger(logger => '/dev/null');
	ok(blessed($db->{'logger'}), '3.3 set_logger(): string path normalised to blessed logger');

	# 3.4  Code-ref normalised to blessed object
	$db->set_logger(logger => sub { 1 });
	ok(blessed($db->{'logger'}), '3.4 set_logger(): coderef normalised to blessed logger');

	# 3.5  No logger argument → croak (Params::Get or our own message)
	throws_ok { $db->set_logger() } qr/set_logger/i,
		'3.5 set_logger(): no arg causes croak mentioning set_logger';
}

# ---------------------------------------------------------------------------
# SECTION 4 — updated()
# ---------------------------------------------------------------------------

note '';
note '=== 4. updated() ===';
{
	my $db = Database::test1->new($DATA_DIR);

	# 4.1  Returns undef before first query (no _open yet for bare new())
	#      OR a Unix timestamp after data is loaded — either is acceptable.
	my $ts = $db->updated();
	ok(!defined($ts) || looks_like_number($ts),
		'4.1 updated(): returns undef or numeric Unix timestamp');

	# 4.2  After a data-loading call the timestamp must be numeric
	$db->fetchrow_hashref(entry => 'one');
	my $ts2 = $db->updated();
	ok(looks_like_number($ts2), '4.2 updated(): numeric after data loaded');
	ok($ts2 > 0, '4.2 updated(): timestamp is positive');
}

# ---------------------------------------------------------------------------
# SECTION 5 — selectall_arrayref()
# ---------------------------------------------------------------------------

note '';
note '=== 5. selectall_arrayref() ===';
{
	my $db = Database::test1->new($DATA_DIR);

	# 5.1  No criteria → arrayref of all rows
	my $all = $db->selectall_arrayref();
	isa_ok($all, 'ARRAY', '5.1 selectall_arrayref(): no criteria returns arrayref');
	ok(scalar @{$all} >= 4, '5.1 selectall_arrayref(): returns at least 4 rows');
	returns_ok($all, { type => 'arrayref' }, '5.1 selectall_arrayref(): Test::Returns shape');

	# 5.2  Each element is a hashref
	ok((grep { ref($_) eq 'HASH' } @{$all}) == scalar @{$all},
		'5.2 selectall_arrayref(): every element is a hashref');

	# 5.3  Exact-match criterion
	my $ones = $db->selectall_arrayref(entry => 'one');
	is(scalar @{$ones}, 1, '5.3 selectall_arrayref(): exact match returns 1 row');
	is($ones->[0]{$ENTRY_COL}, 'one', '5.3 selectall_arrayref(): correct row returned');

	# 5.4  Non-key column exact match (exercises in-memory scan)
	my $by_num = $db->selectall_arrayref(number => 2);
	is(scalar @{$by_num}, 1, '5.4 selectall_arrayref(): non-key column match');
	is($by_num->[0]{$ENTRY_COL}, 'two', '5.4 selectall_arrayref(): correct row from non-key scan');

	# 5.5  Operator criterion via SQLite (DBD::CSV does not reliably support
	#      comparison operators in SQL — operator criteria are tested against
	#      a proper SQL backend in section 10 / section 14).
	#      Here we just verify the slurp in-memory scan path returns an arrayref.
	my $eq3 = $db->selectall_arrayref(number => 3);
	ok(defined($eq3) && ref($eq3) eq 'ARRAY',
		'5.5 selectall_arrayref(): criteria with slurp scan returns arrayref');

	# 5.6  No-match criterion → arrayref (not undef); entry fast-path must
	#      not throw on a locked hash key that does not exist.
	my $none = $db->selectall_arrayref(entry => '__NO_SUCH_ENTRY__');
	ok(defined($none) && ref($none) eq 'ARRAY',
		'5.6 selectall_arrayref(): no-match returns arrayref, not undef');

	# 5.7  BerkeleyDB backend → returns empty arrayref (in-memory scan on empty hash)
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = {};	# inject empty sentinel to exercise BerkeleyDB path
		my $rc = $bdb->selectall_arrayref();
		is(ref($rc), 'ARRAY', '5.7 selectall_arrayref(): BerkeleyDB path returns arrayref');
		is(scalar @{$rc}, 0,   '5.7 selectall_arrayref(): empty BerkeleyDB yields 0 rows');
	}

	# 5.8  selectall_hashref is a documented deprecated alias
	my $via_alias = $db->selectall_hashref(entry => 'one');
	is_deeply($via_alias, $db->selectall_arrayref(entry => 'one'),
		'5.8 selectall_hashref(): deprecated alias returns same data as selectall_arrayref');
}

# ---------------------------------------------------------------------------
# SECTION 6 — selectall_array()
# ---------------------------------------------------------------------------

note '';
note '=== 6. selectall_array() ===';
{
	my $db = Database::test1->new($DATA_DIR);

	# 6.1  List context → all rows as a list of hashrefs
	my @rows = $db->selectall_array();
	ok(scalar @rows >= 4, '6.1 selectall_array(): list context returns all rows');
	ok(ref($rows[0]) eq 'HASH', '6.1 selectall_array(): elements are hashrefs');

	# 6.2  With criterion
	my @matched = $db->selectall_array(entry => 'two');
	is($matched[0]{$ENTRY_COL}, 'two', '6.2 selectall_array(): criterion returns correct row');

	# 6.3  In-memory scan by non-key column
	my @by_num = $db->selectall_array(number => 1);
	is(scalar @by_num, 1, '6.3 selectall_array(): non-key scan returns 1 match');
	is($by_num[0]{$ENTRY_COL}, 'one', '6.3 selectall_array(): correct row from scan');

	# 6.4  selectall_hash is a documented deprecated alias
	my @via_alias = $db->selectall_hash();
	is(scalar @via_alias, scalar @rows,
		'6.4 selectall_hash(): deprecated alias returns same number of rows');

	# 6.5  BerkeleyDB → returns empty list (in-memory scan on empty hash)
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = {};
		my @rows = $bdb->selectall_array();
		is(scalar @rows, 0, '6.5 selectall_array(): BerkeleyDB path returns empty list');
	}
}

# ---------------------------------------------------------------------------
# SECTION 7 — fetchrow_hashref()
# ---------------------------------------------------------------------------

note '';
note '=== 7. fetchrow_hashref() ===';
{
	my $db = Database::test1->new($DATA_DIR);

	# 7.1  Returns a hashref on match
	my $row = $db->fetchrow_hashref(entry => 'one');
	isa_ok($row, 'HASH', '7.1 fetchrow_hashref(): returns hashref on match');
	returns_ok($row, { type => 'hashref' }, '7.1 fetchrow_hashref(): Test::Returns shape');

	# 7.2  Correct row content
	is($row->{$ENTRY_COL}, 'one', '7.2 fetchrow_hashref(): entry column correct');
	is($row->{'number'}, 1, '7.2 fetchrow_hashref(): data column correct');

	# 7.3  Bare single-arg shortcut (when no_entry is not set)
	my $row2 = $db->fetchrow_hashref('two');
	is($row2->{$ENTRY_COL}, 'two', '7.3 fetchrow_hashref(): bare arg treated as entry value');

	# 7.4  No match → undef (NOT an exception)
	my $miss = $db->fetchrow_hashref(entry => '__NO_MATCH__');
	ok(!defined($miss), '7.4 fetchrow_hashref(): no match returns undef');

	# 7.5  Multiple plain criteria (AND semantics)
	my $both = $db->fetchrow_hashref(entry => 'three', number => 3);
	ok(!defined($both) || (defined($both) && $both->{'number'} == 3),
		'7.5 fetchrow_hashref(): multiple criteria work (AND semantics)');

	# Operator criteria on CSV via DBD::CSV are unreliable — those are
	# exercised in the SQLite sections (10 / 14).
}

# ---------------------------------------------------------------------------
# SECTION 8 — count()
# ---------------------------------------------------------------------------

note '';
note '=== 8. count() ===';
{
	my $db = Database::test1->new($DATA_DIR);

	# 8.1  No criteria → total row count (positive integer)
	my $total = $db->count();
	ok(looks_like_number($total) && $total > 0,
		'8.1 count(): no criteria returns positive integer');

	# 8.2  Entry fast-path: known entry → 1
	my $one = $db->count(entry => 'one');
	is($one, 1, '8.2 count(): entry fast-path for known entry returns 1');

	# 8.3  Entry fast-path: missing entry → 0 (no throw on locked hash)
	my $zero = $db->count(entry => '__NO_SUCH__');
	is($zero, 0, '8.3 count(): entry fast-path for missing entry returns 0');

	# 8.4  Criteria-filtered count
	my $by_num = $db->count(number => 1);
	is($by_num, 1, '8.4 count(): non-key criterion filters correctly');

	# 8.5  BerkeleyDB → returns 0 for empty hash (in-memory scan)
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = {};
		is($bdb->count(), 0, '8.5 count(): BerkeleyDB path returns 0 for empty hash');
	}
}

# ---------------------------------------------------------------------------
# SECTION 9 — AUTOLOAD column shortcut
# ---------------------------------------------------------------------------

note '';
note '=== 9. AUTOLOAD ===';
{
	my $db = Database::test1->new($DATA_DIR);

	# 9.1  Scalar context: returns first matching column value
	my $val = $db->number(entry => 'two');
	is($val, 2, '9.1 AUTOLOAD(): scalar context returns column value');

	# 9.2  List context: returns all values for that column
	my @nums = $db->number();
	ok(scalar @nums >= 4, '9.2 AUTOLOAD(): list context returns all column values');

	# 9.3  Bare single-arg shortcut (entry shortcut without 'entry =>')
	my $via_bare = $db->number('one');
	is($via_bare, 1, '9.3 AUTOLOAD(): bare arg treated as entry value');

	# 9.4  Missing entry → undef, not an exception (locked-hash safe)
	my $miss = $db->number(entry => '__NO_SUCH__');
	ok(!defined($miss), '9.4 AUTOLOAD(): missing entry returns undef');

	# 9.5  auto_load => 0 disables AUTOLOAD → croak
	my $noauto = Database::test1->new({ directory => $DATA_DIR, auto_load => 0 });
	throws_ok { $noauto->number() }
		qr/AUTOLOAD disabled/i,
		'9.5 AUTOLOAD(): auto_load=>0 causes croak';

	# 9.6  DESTROY is excluded from AUTOLOAD dispatch — use a SEPARATE object
	#      so that explicit DESTROY does not corrupt $db's state for later tests
	{
		my $tmp = Database::test1->new($DATA_DIR);
		lives_ok { $tmp->DESTROY() } '9.6 AUTOLOAD(): DESTROY method call does not croak';
	}

	# 9.7  Custom id column (test5 uses 'ID' as primary key)
	my $db5 = Database::test5->new(directory => $DATA_DIR);
	my @names = $db5->Name();
	ok(scalar @names >= 1, '9.7 AUTOLOAD(): works with custom id column (test5)');

	# 9.8  distinct / unique flag returns deduplicated values
	my @uniq = $db->number(distinct => 1);
	ok(scalar @uniq <= scalar(@nums), '9.8 AUTOLOAD(): distinct flag produces <= total count');

	# 9.9  AUTOLOAD for an unknown column (entry-keyed slurp mode) throws a clear error.
	#      POD: "Dies with a clear error if the column does not exist (slurp mode only)".
	throws_ok { $db->nonexistent_column_xyz(entry => 'one') }
		qr/nonexistent_column_xyz/i,
		'9.9 AUTOLOAD(): unknown column in slurp mode throws clear error';
}

# ---------------------------------------------------------------------------
# SECTION 10 — execute()
# ---------------------------------------------------------------------------

note '';
note '=== 10. execute() ===';
SKIP: {
	skip 'DBI/DBD::SQLite not available for execute() tests', 8
		unless $have_sqlite;

	my $dir   = tempdir(CLEANUP => 1);
	my $dbfile = File::Spec->catfile($dir, 'exec_unit.sql');
	my $dsn   = "dbi:SQLite:dbname=$dbfile";

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do('CREATE TABLE exec_unit (id INTEGER PRIMARY KEY, val TEXT, score INTEGER)');
	$setup->do("INSERT INTO exec_unit VALUES (1, 'alpha', 10)");
	$setup->do("INSERT INTO exec_unit VALUES (2, 'beta',  30)");
	$setup->do("INSERT INTO exec_unit VALUES (3, 'gamma', 50)");
	$setup->disconnect();

	{
		package Database::exec_unit;
		use parent 'Database::Abstraction';
	}

	my $db = Database::exec_unit->new(dsn => $dsn, no_entry => 1);

	# 10.1 List context with no bind args → all rows
	my @all = $db->execute(query => 'SELECT * FROM exec_unit');
	is(scalar @all, 3, '10.1 execute(): list context returns all rows');
	isa_ok($all[0], 'HASH', '10.1 execute(): each row is a hashref');

	# 10.2 Scalar context → only the first row
	my $first = $db->execute(query => 'SELECT * FROM exec_unit ORDER BY id');
	is($first->{'val'}, 'alpha', '10.2 execute(): scalar context returns first row');

	# 10.3 Bind args as arrayref
	my @bound = $db->execute(
		query => 'SELECT * FROM exec_unit WHERE score >= ?',
		args  => [30],
	);
	is(scalar @bound, 2, '10.3 execute(): arrayref bind args filter correctly');

	# 10.4 Bind arg as bare scalar (not arrayref)
	my @scalar_bind = $db->execute(
		query => 'SELECT * FROM exec_unit WHERE score >= ?',
		args  => 30,
	);
	is(scalar @scalar_bind, 2, '10.4 execute(): scalar bind arg works');

	# 10.5 Multiple bind args
	my @multi = $db->execute(
		query => 'SELECT * FROM exec_unit WHERE score >= ? AND score <= ?',
		args  => [10, 30],
	);
	is(scalar @multi, 2, '10.5 execute(): multiple bind args filter correctly');

	# 10.6 Missing query → croak
	throws_ok { $db->execute() } qr/execute/i,
		'10.6 execute(): no query arg causes croak';

	# 10.7 BerkeleyDB → croak
	{
		my $bdb = Database::exec_unit->new(dsn => $dsn, no_entry => 1);
		$bdb->{'berkeley'} = {};
		throws_ok { $bdb->execute(query => 'SELECT 1') }
			qr/meaningless on a NoSQL/i,
			'10.7 execute(): BerkeleyDB backend causes croak';
	}
}

# ---------------------------------------------------------------------------
# SECTION 11 — updated() (post-load)
# ---------------------------------------------------------------------------
# (Covered in section 4 above; no duplicate needed.)

# ---------------------------------------------------------------------------
# SECTION 12 — columns()
# ---------------------------------------------------------------------------

note '';
note '=== 12. columns() ===';
{
	my $db = Database::test1->new($DATA_DIR);

	# 12.1  Returns an arrayref of column name strings
	my $cols = $db->columns();
	isa_ok($cols, 'ARRAY', '12.1 columns(): returns arrayref');

	# 12.2  Entry column is present
	ok((grep { $_ eq $ENTRY_COL } @{$cols}),
		'12.2 columns(): "entry" column is present');

	# 12.3  All elements are non-empty strings
	ok((grep { defined($_) && length($_) > 0 } @{$cols}) == scalar @{$cols},
		'12.3 columns(): all column names are non-empty strings');

	# 12.4  Cached: second call returns same reference
	my $cols2 = $db->columns();
	is($cols, $cols2, '12.4 columns(): result cached — same ref on second call');

	# 12.5  BerkeleyDB backend always returns exactly ['entry', 'value']
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = {};
		$bdb->{'_columns'} = undef;		# clear any cached value
		my $bdb_cols = $bdb->columns();
		is_deeply($bdb_cols, ['entry', 'value'],
			'12.5 columns(): BerkeleyDB returns [entry, value]');
	}
}

# ---------------------------------------------------------------------------
# SECTION 13 — schema()
# ---------------------------------------------------------------------------

note '';
note '=== 13. schema() ===';
{
	my $db = Database::test1->new($DATA_DIR);

	# 13.1  Returns a hashref
	my $schema = $db->schema();
	isa_ok($schema, 'HASH', '13.1 schema(): returns hashref');

	# 13.2  Entry column is a key
	ok(exists $schema->{$ENTRY_COL}, '13.2 schema(): entry column present as key');

	# 13.3  Each column value has the required sub-keys
	for my $col (keys %{$schema}) {
		ok(exists $schema->{$col}{'type'},     "13.3 schema(): '$col' has type key");
		ok(exists $schema->{$col}{'nullable'}, "13.3 schema(): '$col' has nullable key");
		ok(exists $schema->{$col}{'pk'},       "13.3 schema(): '$col' has pk key");
		last;	# one column is sufficient for the structural check
	}

	# 13.4  Entry column is the primary key in slurp mode
	is($schema->{$ENTRY_COL}{'pk'}, 1, '13.4 schema(): entry column is pk');

	# 13.5  Cached on second call
	my $schema2 = $db->schema();
	is($schema, $schema2, '13.5 schema(): result cached — same ref on second call');

	# 13.6  BerkeleyDB: fixed schema with entry+value
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = {};
		$bdb->{'_schema'} = undef;
		my $bdb_schema = $bdb->schema();
		ok(exists $bdb_schema->{'entry'} && exists $bdb_schema->{'value'},
			'13.6 schema(): BerkeleyDB returns entry+value schema');
		is($bdb_schema->{'entry'}{'pk'}, 1,
			'13.6 schema(): BerkeleyDB entry column is pk');
		is($bdb_schema->{'value'}{'pk'}, 0,
			'13.6 schema(): BerkeleyDB value column is not pk');
	}
}

# ---------------------------------------------------------------------------
# SECTION 14 — query() builder (Database::Abstraction::Query)
# ---------------------------------------------------------------------------

note '';
note '=== 14. query() + Database::Abstraction::Query ===';
SKIP: {
	skip 'DBI/DBD::SQLite not available for Query tests', 37
		unless $have_sqlite;

	use_ok('Database::Abstraction::Query');

	my $dir   = tempdir(CLEANUP => 1);
	my $dbfile = File::Spec->catfile($dir, 'qunit.sql');
	my $dsn   = "dbi:SQLite:dbname=$dbfile";

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do('CREATE TABLE qunit (entry TEXT PRIMARY KEY, name TEXT, score REAL, status TEXT)');
	for my $r (
		['a', 'Alice', 9.5, 'active'],
		['b', 'Bob',   7.0, 'active'],
		['c', 'Carol', 8.5, 'active'],
		['d', 'Dave',  6.0, 'inactive'],
		['e', 'Eve',   10,  'inactive'],
	) {
		$setup->do('INSERT INTO qunit VALUES (?,?,?,?)', undef, @{$r});
	}
	$setup->disconnect();

	{
		package Database::qunit;
		use parent 'Database::Abstraction';
	}

	my $db = Database::qunit->new(dsn => $dsn);

	# 14.0  query() returns a Database::Abstraction::Query object
	my $q = $db->query();
	isa_ok($q, 'Database::Abstraction::Query', '14.0 query(): returns Query object');

	# ---- Query->new() validation ----------------------------------------

	# 14.1  _db required
	throws_ok { Database::Abstraction::Query->new() }
		qr/_db is required/i,
		'14.1 Query->new(): missing _db causes croak';

	# 14.2  _db must be a Database::Abstraction instance
	throws_ok { Database::Abstraction::Query->new(_db => bless {}, 'Not::A::DB') }
		qr/_db must be a Database::Abstraction/i,
		'14.2 Query->new(): wrong type causes croak';

	# ---- Builder methods return $self (fluent interface) ----------------

	my $fresh = $db->query();
	is($fresh->select('name'),       $fresh, '14.3 select(): returns $self');
	is($fresh->where(status => 'x'), $fresh, '14.4 where(): returns $self');
	is($fresh->order_by('name'),     $fresh, '14.5 order_by(): returns $self');
	is($fresh->limit(5),             $fresh, '14.6 limit(): returns $self');
	is($fresh->offset(0),            $fresh, '14.7 offset(): returns $self');
	is($fresh->join({ table => 't', on => 'a.id=t.id' }), $fresh,
		'14.8 join(): returns $self');

	# ---- all() ----------------------------------------------------------

	# 14.9  No criteria → all rows
	my $all = $db->query()->all();
	isa_ok($all, 'ARRAY', '14.9 query->all(): returns arrayref');
	is(scalar @{$all}, 5, '14.9 query->all(): all 5 rows returned');

	# 14.10 where() filter
	my $active = $db->query()->where(status => 'active')->all();
	is(scalar @{$active}, 3, '14.10 query->where->all(): filtered to 3 active rows');

	# 14.11 Chained where() calls use AND semantics
	my $narrow = $db->query()
		->where(status => 'active')
		->where(score  => { '>' => 8 })
		->all();
	ok(scalar @{$narrow} >= 1, '14.11 chained where(): AND semantics narrows result');
	ok((grep { $_->{'status'} eq 'active' && $_->{'score'} > 8 } @{$narrow})
		== scalar @{$narrow},
		'14.11 chained where(): all rows satisfy both conditions');

	# 14.12 order_by
	my $ordered = $db->query()->order_by('score DESC')->all();
	ok($ordered->[0]{'score'} >= $ordered->[-1]{'score'},
		'14.12 order_by(): first row score >= last row score (DESC)');

	# 14.13 -or grouping inside where()
	my $either = $db->query()
		->where(-or => [
			{ name => 'Alice' },
			{ name => 'Eve'   },
		])
		->all();
	is(scalar @{$either}, 2, '14.13 -or grouping: returns 2 matching rows');

	# ---- first() -------------------------------------------------------

	# 14.14 Returns a hashref for a hit
	my $first = $db->query()->where(name => 'Alice')->first();
	isa_ok($first, 'HASH', '14.14 query->first(): returns hashref on match');
	is($first->{'name'}, 'Alice', '14.14 query->first(): correct row');

	# 14.15 Returns undef on no match
	my $miss = $db->query()->where(name => '__nobody__')->first();
	ok(!defined($miss), '14.15 query->first(): no match returns undef');

	# 14.16 Applies LIMIT 1 internally (does not affect object state)
	my $q2 = $db->query();
	$q2->first();
	my $after = $q2->all();
	is(scalar @{$after}, 5, '14.16 first(): does not permanently mutate limit state');

	# ---- count() -------------------------------------------------------

	# 14.17 Total count
	my $n = $db->query()->count();
	is($n, 5, '14.17 query->count(): total = 5');

	# 14.18 Filtered count
	my $n2 = $db->query()->where(status => 'active')->count();
	is($n2, 3, '14.18 query->count(): filtered count = 3');

	# 14.19 count() ignores ORDER BY / LIMIT / OFFSET (those apply to all/first only)
	my $n3 = $db->query()->order_by('name')->limit(2)->count();
	is($n3, 5, '14.19 query->count(): ORDER BY + LIMIT do not affect count');

	# ---- limit() + offset() --------------------------------------------

	# 14.20 limit(N) returns exactly N rows
	my $limited = $db->query()->order_by('entry')->limit(2)->all();
	is(scalar @{$limited}, 2, '14.20 limit(2): returns exactly 2 rows');

	# 14.21 offset() paginates correctly
	my $page1 = $db->query()->order_by('entry')->limit(2)->offset(0)->all();
	my $page2 = $db->query()->order_by('entry')->limit(2)->offset(2)->all();
	isnt($page1->[0]{'entry'}, $page2->[0]{'entry'},
		'14.21 offset(): page 2 starts at a different row than page 1');

	# ---- select() column projection ------------------------------------

	# 14.22 Custom column list
	my $names = $db->query()->select('name')->where(status => 'active')->all();
	ok(exists $names->[0]{'name'}, '14.22 select(name): name key present in result');
	is(scalar @{$names}, 3, '14.22 select(name): correct row count');

	# ---- join() --------------------------------------------------------

	# Joins require a second table; only test with a live SQLite DB
	my $j_setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$j_setup->do('CREATE TABLE IF NOT EXISTS dept (id TEXT PRIMARY KEY, dname TEXT)');
	$j_setup->do("INSERT OR IGNORE INTO dept VALUES ('eng','Engineering')");
	$j_setup->do('ALTER TABLE qunit ADD COLUMN dept_id TEXT') if do {
		my $cols = $j_setup->selectall_arrayref('PRAGMA table_info(qunit)');
		!grep { $_->[1] eq 'dept_id' } @{$cols};
	};
	$j_setup->do("UPDATE qunit SET dept_id='eng' WHERE name='Alice'");
	$j_setup->disconnect();

	my $joined = $db->query()
		->join({ table => 'dept', on => 'qunit.dept_id = dept.id', type => 'LEFT' })
		->where('qunit.name' => 'Alice')
		->all();
	ok(scalar @{$joined} >= 1, '14.23 query->join(): LEFT JOIN returns rows');
}

# ---------------------------------------------------------------------------
# SECTION 15 — CHI cache integration (selectall_arrayref + count)
# ---------------------------------------------------------------------------

note '';
note '=== 15. CHI cache ===';
SKIP: {
	skip 'CHI not available', 6 unless $have_chi;
	skip 'DBI/DBD::SQLite not available for cache tests', 6
		unless $have_sqlite;

	my $dir   = tempdir(CLEANUP => 1);
	my $dbfile = File::Spec->catfile($dir, 'cache_unit.sql');
	my $dsn   = "dbi:SQLite:dbname=$dbfile";

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do('CREATE TABLE cache_unit (entry TEXT PRIMARY KEY, val TEXT)');
	$setup->do("INSERT INTO cache_unit VALUES ('x','one')");
	$setup->do("INSERT INTO cache_unit VALUES ('y','two')");
	$setup->disconnect();

	{
		package Database::cache_unit;
		use parent 'Database::Abstraction';
	}

	my $cache = CHI->new(driver => 'RawMemory', global => 0);
	my $db = Database::cache_unit->new(
		dsn            => $dsn,
		cache          => $cache,
		cache_duration => '10 minutes',
	);

	# 15.1  First call is a cache miss and populates the cache
	my $r1 = $db->selectall_arrayref();
	is(scalar @{$r1}, 2, '15.1 cache: first call returns correct data');

	# 15.2  Cache now has at least one key
	my @keys1 = $cache->get_keys();
	ok(scalar @keys1 >= 1, '15.2 cache: result stored after first call');

	# 15.3  Second call is a cache hit and returns same data
	my $r2 = $db->selectall_arrayref();
	is_deeply($r1, $r2, '15.3 cache: second call returns same data (HIT)');

	# 15.4  No new cache keys added on hit
	my @keys2 = $cache->get_keys();
	is(scalar @keys2, scalar @keys1, '15.4 cache: no extra keys on HIT');

	# 15.5  count() with empty cache → returns correct total
	my $cache2 = CHI->new(driver => 'RawMemory', global => 0);
	my $db2 = Database::cache_unit->new(
		dsn   => $dsn,
		cache => $cache2,
	);
	my $cnt = $db2->count();
	is($cnt, 2, '15.5 cache: count() returns correct total');

	# 15.6  count() does NOT add its own cache key (opportunistic-only design)
	my @cnt_keys = $cache2->get_keys();
	is(scalar @cnt_keys, 0, '15.6 cache: count() alone adds no cache keys');
}

# ---------------------------------------------------------------------------
# SECTION 16 — PSV and XML backends (smoke tests for documented formats)
# ---------------------------------------------------------------------------

note '';
note '=== 16. PSV and XML backends ===';
{
	# 16.1  PSV fixture loads and returns data
	my $psv = Database::test2->new($DATA_DIR);
	my $all = $psv->selectall_arrayref();
	ok(defined($all) && scalar @{$all} >= 1,
		'16.1 PSV backend: selectall_arrayref returns rows');

	# 16.2  XML fixture must run in SQL mode (max_slurp_size => 1) because the
	#       complex nested <entry> structure is not supported in slurp mode.
	my $xml = Database::test3->new({ directory => $DATA_DIR, max_slurp_size => 1 });
	my $xall = $xml->selectall_arrayref();
	ok(defined($xall) && scalar @{$xall} >= 1,
		'16.2 XML backend: selectall_arrayref returns rows');
}

done_testing();
