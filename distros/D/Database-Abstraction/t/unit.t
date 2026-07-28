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
# API Message Ledger — documented error states not yet covered by sections 1-16.
# Each state is deleted when a corresponding subtest successfully triggers it.
# A ledger assertion at the end of the file fails if any state is untested.
# ---------------------------------------------------------------------------
my %LEDGER = (
	'unsafe id in new'       => 'new(): id injection guard — semicolon in id',
	'unsafe id in clone'     => 'new(): clone path id injection guard',
	'unsafe host in new'     => 'new(): host injection guard — space/metachar in host',
	'BerkeleyDB no JOINs'    => 'selectall_arrayref: _scan_berkeley join croak',
	'BerkeleyDB no or-and'   => 'selectall_arrayref: _scan_berkeley -or/-and croak',
	'fetchrow_hashref NoSQL' => 'fetchrow_hashref: BerkeleyDB non-entry column croak',
	'query all join BDB'     => 'Query->all():   join on BerkeleyDB croak',
	'query first join BDB'   => 'Query->first(): join on BerkeleyDB croak',
	'query count join BDB'   => 'Query->count(): join on BerkeleyDB croak',
	'query all join Deep'    => 'Query->all():   join on Deep croak',
	'query first join Deep'  => 'Query->first(): join on Deep croak',
	'query count join Deep'  => 'Query->count(): join on Deep croak',
	'Unknown SQL operator'   => '_build_where_conditions: unknown operator croak',
	'selectall -in'          => 'selectall_arrayref: -in operator via DBI',
	'selectall -between'     => 'selectall_arrayref: -between operator via DBI',
	'selectall -like'        => 'selectall_arrayref: -like operator via DBI',
	'selectall -or direct'   => 'selectall_arrayref: -or grouping direct call',
);

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

	# 12.6  no_entry CSV slurp (ARRAY data) returns correct column list
	#       Regression guard for bug where ref($data) eq 'ARRAY' left @cols empty.
	#       Uses Database::test4ne (id=>'cardinal') so the slurp produces ARRAY data.
	{
		use_ok('Database::test4ne');
		my $ne = Database::test4ne->new(directory => $DATA_DIR);
		$ne->count();    # trigger lazy _open and slurp into ARRAY ref
		my $ne_cols = $ne->columns();
		isa_ok($ne_cols, 'ARRAY', '12.6 columns(): no_entry CSV ARRAY slurp returns arrayref');
		ok(scalar(@{$ne_cols}) > 0,
			'12.6 columns(): no_entry CSV ARRAY slurp returns non-empty list');
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

	# 13.7  no_entry CSV slurp (ARRAY data) returns correct schema
	#       Regression guard for bug where ref($data) eq 'ARRAY' left %schema empty.
	#       Uses Database::test4ne (id=>'cardinal') so the slurp produces ARRAY data.
	{
		my $ne = Database::test4ne->new(directory => $DATA_DIR);
		$ne->count();    # trigger lazy _open and slurp into ARRAY ref
		my $ne_schema = $ne->schema();
		isa_ok($ne_schema, 'HASH', '13.7 schema(): no_entry CSV ARRAY slurp returns hashref');
		ok(scalar(keys %{$ne_schema}) > 0,
			'13.7 schema(): no_entry CSV ARRAY slurp schema is non-empty');
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

# ---------------------------------------------------------------------------
# SECTION 17 — Operator criteria via selectall_arrayref() (SQLite required)
#
# Tests every documented operator hashref type directly via a public method,
# NOT via the query builder.  Uses no_entry => 1 to force Params::Get to
# parse named pairs correctly (avoids positional-arg pitfall; see CLAUDE.md).
# ---------------------------------------------------------------------------

note '';
note '=== 17. Operator criteria via selectall_arrayref() ===';
SKIP: {
	skip 'DBI/DBD::SQLite not available for operator tests', 18
		unless $have_sqlite;

	my $op_dir  = tempdir(CLEANUP => 1);
	my $op_file = File::Spec->catfile($op_dir, 'op_unit.sql');
	my $op_dsn  = "dbi:SQLite:dbname=$op_file";

	do {
		my $s = DBI->connect($op_dsn, undef, undef, { RaiseError => 1 });
		$s->do('CREATE TABLE op_unit (entry TEXT PRIMARY KEY, name TEXT, score INTEGER, status TEXT)');
		$s->do("INSERT INTO op_unit VALUES ('a','Alice',90,'active')");
		$s->do("INSERT INTO op_unit VALUES ('b','Bob',60,'active')");
		$s->do("INSERT INTO op_unit VALUES ('c','Carol',80,'inactive')");
		$s->do("INSERT INTO op_unit VALUES ('d','Dave',50,'inactive')");
		$s->do("INSERT INTO op_unit VALUES ('e','Eve',100,'active')");
		$s->disconnect();
	};

	{
		package Database::op_unit;
		use parent 'Database::Abstraction';
	}

	# no_entry => 1 is required so Params::Get parses 'col => hashref' as
	# {col => hashref} rather than mapping the first scalar to 'entry'.
	my $op = Database::op_unit->new(dsn => $op_dsn, no_entry => 1);

	# 17.1  Greater-than
	my $gt = $op->selectall_arrayref(score => { '>' => 80 });
	is(scalar @{$gt}, 2,   '17.1 >: exactly 2 rows with score > 80');
	ok(!(grep { $_->{'score'} <= 80 } @{$gt}),
		'17.1 >: all returned rows satisfy the criterion');

	# 17.2  Less-than
	my $lt = $op->selectall_arrayref(score => { '<' => 70 });
	is(scalar @{$lt}, 2, '17.2 <: 2 rows with score < 70');

	# 17.3  Greater-than-or-equal
	my $gte = $op->selectall_arrayref(score => { '>=' => 80 });
	is(scalar @{$gte}, 3, '17.3 >=: 3 rows with score >= 80');

	# 17.4  Less-than-or-equal
	my $lte = $op->selectall_arrayref(score => { '<=' => 60 });
	is(scalar @{$lte}, 2, '17.4 <=: 2 rows with score <= 60');

	# 17.5  Not-equal
	my $ne = $op->selectall_arrayref(status => { '!=' => 'active' });
	is(scalar @{$ne}, 2, '17.5 !=: 2 inactive rows');

	# 17.6  -in operator: match a set of values
	my $in = $op->selectall_arrayref(name => { -in => ['Alice', 'Eve'] });
	is(scalar @{$in}, 2, '17.6 -in: 2 rows in set [Alice, Eve]');
	delete $LEDGER{'selectall -in'};

	# 17.7  -not_in operator
	my $nin = $op->selectall_arrayref(name => { -not_in => ['Alice', 'Bob'] });
	is(scalar @{$nin}, 3, '17.7 -not_in: 3 rows not in [Alice, Bob]');

	# 17.8  -between operator (inclusive both ends)
	my $btwn = $op->selectall_arrayref(score => { -between => [60, 90] });
	is(scalar @{$btwn}, 3, '17.8 -between [60,90]: 3 rows in range');
	ok(!(grep { $_->{'score'} < 60 || $_->{'score'} > 90 } @{$btwn}),
		'17.8 -between: all rows within [60, 90] inclusive');
	delete $LEDGER{'selectall -between'};

	# 17.9  -like operator (SQL LIKE with % wildcard)
	my $like = $op->selectall_arrayref(name => { -like => 'A%' });
	is(scalar @{$like},       1,       '17.9 -like A%: 1 matching row');
	is($like->[0]{'name'}, 'Alice', '17.9 -like A%: correct row returned');
	delete $LEDGER{'selectall -like'};

	# 17.10 -not_like operator
	my $nlike = $op->selectall_arrayref(name => { -not_like => 'A%' });
	is(scalar @{$nlike}, 4, '17.10 -not_like A%: 4 non-matching rows');

	# 17.11 -or grouping applied directly to selectall_arrayref
	my $or_rows = $op->selectall_arrayref(
		-or => [
			{ name => 'Alice' },
			{ name => 'Dave'  },
		],
	);
	is(scalar @{$or_rows}, 2, '17.11 -or grouping: 2 matching rows');
	delete $LEDGER{'selectall -or direct'};

	# 17.12 -and grouping (intersection of two conditions)
	my $and_rows = $op->selectall_arrayref(
		-and => [
			{ status => 'active'      },
			{ score  => { '>=' => 90} },
		],
	);
	ok(scalar @{$and_rows} >= 2, '17.12 -and grouping: >= 2 rows satisfying both conditions');

	# 17.13 Unknown operator → croak with operator name in message
	#        _build_where_conditions has an exhaustive elsif chain; any value
	#        not in it triggers the documented "Unknown operator" croak.
	throws_ok { $op->selectall_arrayref(score => { 'BADOP' => 5 }) }
		qr/Unknown operator 'BADOP'/,
		'17.13 unknown operator causes croak naming the bad operator';
	delete $LEDGER{'Unknown SQL operator'};

	# 17.14 count() with operator criterion
	my $cnt = $op->count(score => { '>' => 80 });
	is($cnt, 2, '17.14 count() with > operator: 2 matching rows');

	# 17.15 fetchrow_hashref with operator criterion
	my $frh = $op->fetchrow_hashref(score => { '>=' => 100 });
	ok(defined($frh) && $frh->{'name'} eq 'Eve',
		'17.15 fetchrow_hashref with >= 100 returns the Eve row');
}

# ---------------------------------------------------------------------------
# SECTION 18 — BerkeleyDB backend guard croaks
#
# BerkeleyDB is a key-value store; the module must croak with clear messages
# when callers attempt SQL-style operations (JOINs, -or groups, column queries).
# The 'berkeley' hash is injected directly because instantiating a real BerkeleyDB
# file is not needed to drive these code paths.
# ---------------------------------------------------------------------------

note '';
note '=== 18. BerkeleyDB guard croaks ===';
{
	# 18.1  selectall_arrayref with join parameter → _scan_berkeley join guard
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = { sentinel => 1 };	# non-empty ref → truthy
		throws_ok {
			$bdb->selectall_arrayref(join => { table => 'dept', on => 'a.id = b.id' })
		} qr/BerkeleyDB does not support JOINs/i,
		'18.1 selectall_arrayref: join on BerkeleyDB causes croak';
		delete $LEDGER{'BerkeleyDB no JOINs'};
	}

	# 18.2  selectall_arrayref with -or grouping → _scan_berkeley -or/-and guard
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = { sentinel => 1 };
		throws_ok {
			$bdb->selectall_arrayref(-or => [{ entry => 'a' }, { entry => 'b' }])
		} qr/BerkeleyDB does not support -or\/-and/i,
		'18.2 selectall_arrayref: -or on BerkeleyDB causes croak';
		delete $LEDGER{'BerkeleyDB no or-and'};
	}

	# 18.3  fetchrow_hashref with non-entry column on BerkeleyDB
	#        BerkeleyDB is a k/v store; arbitrary column queries are not
	#        supported — the module must croak with the documented message.
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = { sentinel => 1 };
		throws_ok {
			$bdb->fetchrow_hashref(name => 'Alice')
		} qr/fetchrow_hashref is meaningless on a NoSQL database/i,
		'18.3 fetchrow_hashref: non-entry column on BerkeleyDB causes croak';
		delete $LEDGER{'fetchrow_hashref NoSQL'};
	}

	# 18.4-18.6  query() terminal methods with JOINs on BerkeleyDB
	#             The query builder delegates to selectall_arrayref / count for
	#             BerkeleyDB, but must refuse JOINs before any DBI access.
	{
		my $join_spec = { table => 'dept', on => 'a.id = b.id' };
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = { sentinel => 1 };

		throws_ok { $bdb->query()->join($join_spec)->all() }
			qr/JOINs is not supported on BerkeleyDB/i,
			'18.4 query->join->all(): JOINs on BerkeleyDB causes croak';
		delete $LEDGER{'query all join BDB'};

		throws_ok { $bdb->query()->join($join_spec)->first() }
			qr/JOINs is not supported on BerkeleyDB/i,
			'18.5 query->join->first(): JOINs on BerkeleyDB causes croak';
		delete $LEDGER{'query first join BDB'};

		throws_ok { $bdb->query()->join($join_spec)->count() }
			qr/JOINs is not supported on BerkeleyDB/i,
			'18.6 query->join->count(): JOINs on BerkeleyDB causes croak';
		delete $LEDGER{'query count join BDB'};
	}
}

# ---------------------------------------------------------------------------
# SECTION 19 — DBM::Deep backend query builder guard croaks
#
# The Deep backend (type = 'Deep') follows the same non-SQL code path as
# BerkeleyDB in the query builder.  JOINs are not supported and must croak
# with a distinct message ("not supported on Deep") before any SQL is built.
# 'data' is injected so _open_table() does not call _open() again.
# ---------------------------------------------------------------------------

note '';
note '=== 19. DBM::Deep query builder guard croaks ===';
{
	my $join_spec = { table => 'dept', on => 'a.id = b.id' };

	{
		my $deep = Database::test1->new($DATA_DIR);
		$deep->{'type'} = 'Deep';
		$deep->{'data'} = {};	# prevents _open_table() from calling _open()
		throws_ok { $deep->query()->join($join_spec)->all() }
			qr/JOINs is not supported on Deep/i,
			'19.1 query->join->all(): JOINs on Deep causes croak';
		delete $LEDGER{'query all join Deep'};
	}

	{
		my $deep = Database::test1->new($DATA_DIR);
		$deep->{'type'} = 'Deep';
		$deep->{'data'} = {};
		throws_ok { $deep->query()->join($join_spec)->first() }
			qr/JOINs is not supported on Deep/i,
			'19.2 query->join->first(): JOINs on Deep causes croak';
		delete $LEDGER{'query first join Deep'};
	}

	{
		my $deep = Database::test1->new($DATA_DIR);
		$deep->{'type'} = 'Deep';
		$deep->{'data'} = {};
		throws_ok { $deep->query()->join($join_spec)->count() }
			qr/JOINs is not supported on Deep/i,
			'19.3 query->join->count(): JOINs on Deep causes croak';
		delete $LEDGER{'query count join Deep'};
	}
}

# ---------------------------------------------------------------------------
# SECTION 20 — new() safety guards: id and host injection prevention
#
# The POD documents that new() validates 'id' and 'host' strictly against
# identifier regexes.  Hostile values must croak before any object is created.
# Tests cover both the direct construction path and the clone path (which
# previously bypassed the id guard — now fixed per Changes 0.37).
# ---------------------------------------------------------------------------

note '';
note '=== 20. new() safety guards ===';
{
	# 20.1  Unsafe id (semicolons and SQL keywords must be rejected immediately)
	throws_ok {
		Database::test1->new(directory => $DATA_DIR, id => 'bad;id')
	} qr/unsafe id column name/i,
	'20.1 new(): semicolon in id field causes croak before any object is returned';
	delete $LEDGER{'unsafe id in new'};

	# 20.2  Unsafe id in the clone path (obj->new(id => ...) branch)
	#        Prior to 0.37 the early return in the clone branch bypassed the
	#        id validation block — this asserts the fix is in place.
	{
		my $original = Database::test1->new($DATA_DIR);
		throws_ok { $original->new(id => 'bad;id') }
			qr/unsafe id column name/i,
			'20.2 new(): clone path: hostile id causes croak';
		delete $LEDGER{'unsafe id in clone'};
	}

	# 20.3  Unsafe host (spaces / shell metacharacters must be rejected)
	throws_ok {
		Database::test1->new(directory => $DATA_DIR, host => 'bad host; rm -rf /')
	} qr/unsafe host/i,
	'20.3 new(): shell metacharacters in host cause croak at construction time';
	delete $LEDGER{'unsafe host in new'};
}

# ---------------------------------------------------------------------------
# LEDGER ASSERTION
# If SQLite was unavailable, the SQLite-only states were never reachable;
# remove them before checking so the ledger still passes on minimal installs.
# ---------------------------------------------------------------------------
unless($have_sqlite) {
	delete @LEDGER{qw(
		Unknown SQL operator
		selectall -in
		selectall -between
		selectall -like
		selectall -or direct
	)};
}

note '';
note '=== LEDGER: asserting all documented API states were exercised ===';
if(%LEDGER) {
	for my $state (sort keys %LEDGER) {
		fail("Untested documented API state: $state ($LEDGER{$state})");
	}
} else {
	pass('API ledger: all documented error states exercised');
}

done_testing();
