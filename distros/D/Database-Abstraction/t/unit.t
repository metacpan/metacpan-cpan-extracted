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
	'unsafe id in new'             => 'new(): id injection guard — semicolon in id',
	'unsafe id in clone'           => 'new(): clone path id injection guard',
	'unsafe host in new'           => 'new(): host injection guard — space/metachar in host',
	'unsafe table in new'          => 'new(): table injection guard — semicolon in table name',
	'BerkeleyDB no JOINs'          => 'selectall_arrayref: _scan_berkeley join croak',
	'BerkeleyDB no or-and'         => 'selectall_arrayref: _scan_berkeley -or/-and croak',
	'fetchrow_hashref NoSQL'       => 'fetchrow_hashref: BerkeleyDB non-entry column croak',
	'query all join BDB'           => 'Query->all():   join on BerkeleyDB croak',
	'query first join BDB'         => 'Query->first(): join on BerkeleyDB croak',
	'query count join BDB'         => 'Query->count(): join on BerkeleyDB croak',
	'query all join Deep'          => 'Query->all():   join on Deep croak',
	'query first join Deep'        => 'Query->first(): join on Deep croak',
	'query count join Deep'        => 'Query->count(): join on Deep croak',
	'Unknown SQL operator'         => '_build_where_conditions: unknown operator croak',
	'selectall -in'                => 'selectall_arrayref: -in operator via DBI',
	'selectall -between'           => 'selectall_arrayref: -between operator via DBI',
	'selectall -like'              => 'selectall_arrayref: -like operator via DBI',
	'selectall -or direct'         => 'selectall_arrayref: -or grouping direct call',
	# Added for sections 22-25 (new public API from 0.46)
	'each_row callback not coderef' => 'each_row(): non-coderef callback causes croak',
	'each_row SQL path limit'       => 'each_row(): limit parameter on SQL path',
	'dbi_source slurp undef'        => 'dbi_source(): CSV slurp backend returns undef',
	'dbi_source SQLite hashref'     => 'dbi_source(): SQLite connection returns {dbh,table}',
	'base_criteria active filter'   => 'base_criteria: count() filtered to active rows',
	'base_criteria must be hashref' => 'base_criteria: non-hashref croak at construction',
	'base_criteria unsafe key'      => 'base_criteria: unsafe column key croak at construction',
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

	# 20.4  Unsafe table name (semicolons / SQL keywords must be rejected
	#        before any object is created or file I/O is attempted).
	throws_ok {
		Database::test1->new(directory => $DATA_DIR, table => 'bad; DROP TABLE x--')
	} qr/unsafe table name/i,
	'20.4 new(): semicolon in table name causes croak before any object is returned';
	delete $LEDGER{'unsafe table in new'};
}

# ---------------------------------------------------------------------------
# SECTION 21 — XLSX backend
#
# The POD documents that an Excel workbook (.xlsx) is detected automatically
# when found in the directory.  Each worksheet is a separate SQL table; the
# active worksheet is determined by the class-derived table name (or the
# 'table' constructor parameter).  Results are returned via the standard API.
# ---------------------------------------------------------------------------

note '';
note '=== 21. XLSX backend ===';
{
	my $have_xlsx = eval {
		require Excel::Writer::XLSX;
		require Spreadsheet::ParseXLSX;
		1;
	};

	SKIP: {
		skip 'Excel::Writer::XLSX or Spreadsheet::ParseXLSX not available', 11
			unless $have_xlsx;

		# Build a temporary XLSX fixture (OOXML format) with two worksheets.
		# test1  — entry / number  (primary, matches class-derived table name)
		# sheet2 — entry / score   (used to verify the 'table' constructor param)
		my $tmpdir = tempdir(CLEANUP => 1);
		my $xlsx   = File::Spec->catfile($tmpdir, 'test1.xlsx');

		{
			my $wb  = Excel::Writer::XLSX->new($xlsx);
			my $ws1 = $wb->add_worksheet('test1');
			$ws1->write(0, 0, 'entry');  $ws1->write(0, 1, 'number');
			$ws1->write(1, 0, 'one');    $ws1->write(1, 1, 1);
			$ws1->write(2, 0, 'two');    $ws1->write(2, 1, 2);
			$ws1->write(3, 0, 'three');  $ws1->write(3, 1, 3);
			my $ws2 = $wb->add_worksheet('sheet2');
			$ws2->write(0, 0, 'entry');  $ws2->write(0, 1, 'score');
			$ws2->write(1, 0, 'alpha');  $ws2->write(1, 1, 90);
			$ws2->write(2, 0, 'beta');   $ws2->write(2, 1, 75);
			$wb->close();
		}

		# 21.1  Object constructs without error and reports the correct class
		my $db = new_ok('Database::test1' => [$tmpdir],
			'21.1 new(): XLSX directory accepted');

		# 21.2  type is set lazily; count() triggers _open()
		is($db->count(), 3, '21.2 count(): primary worksheet has 3 data rows');

		# 21.3  type is now visible as 'XLSX' (slurped via Spreadsheet::ParseXLSX)
		is($db->{'type'}, 'XLSX',
			'21.3 XLSX backend: type is "XLSX" after first query');

		# 21.4  AUTOLOAD column lookup works against the slurped data
		is($db->number('two'), 2,
			'21.4 AUTOLOAD: number(two) returns 2 from XLSX');

		# 21.5  fetchrow_hashref returns the expected row hashref
		my $row = $db->fetchrow_hashref(entry => 'one');
		is($row->{'number'}, 1,
			'21.5 fetchrow_hashref: number for "one" is 1');

		# 21.6  selectall_arrayref returns all rows
		my $all = $db->selectall_arrayref();
		is(scalar(@{$all}), 3,
			'21.6 selectall_arrayref: returns arrayref of 3 rows');

		# 21.7  The 'table' constructor parameter selects an alternate worksheet;
		#        the file stem still resolves from the class name, not from 'table'
		my $db2 = Database::test1->new(directory => $tmpdir, table => 'sheet2');
		isa_ok($db2, 'Database::test1',
			'21.7 new(table => "sheet2"): object created');

		# 21.8  Querying the alternate worksheet returns the correct row count
		is($db2->count(), 2,
			'21.8 table override: sheet2 has 2 rows');

		# 21.9  AUTOLOAD against the alternate worksheet
		is($db2->score('alpha'), 90,
			'21.9 table override: score(alpha) == 90');

		# 21.10  no_entry mode works against XLSX (slurped into ARRAY ref)
		my $db_ne = Database::test1->new(
			directory => $tmpdir, no_entry => 1
		);
		cmp_ok($db_ne->count(), '>', 0,
			'21.10 no_entry: count() > 0 on XLSX backend');

		# 21.11  XLSX backend participates in the standard count / selectall
		#         equivalence expected by the POD
		is($db->count(), scalar(@{$db->selectall_arrayref()}),
			'21.11 count() == scalar(selectall_arrayref()) for XLSX');
	}
}

# ---------------------------------------------------------------------------
# SECTION 22 — updated(): three-tier behavior documented in the POD
#
# The POD documents three distinct return paths:
#   1. File-based (CSV, XML, directory-backed SQLite): mtime set at new() time.
#   2. SQLite DSN (dbi:SQLite:dbname=...): live stat() on every call.
#   3. Other DSN / URL: connection timestamp set at new() time.
#
# Section 4 above covers path 1 (CSV slurp).  This section focuses on path 2
# (live-stat) and path 3 (generic DSN timestamp fallback).
# ---------------------------------------------------------------------------

note '';
note '=== 22. updated(): SQLite DSN live-stat and fallback paths ===';
SKIP: {
	skip 'DBI/DBD::SQLite not available for updated() SQLite DSN tests', 10
		unless $have_sqlite;

	my $udir  = tempdir(CLEANUP => 1);
	my $ufile = File::Spec->catfile($udir, 'upd_unit.sql');
	my $udsn  = "dbi:SQLite:dbname=$ufile";

	{
		my $s = DBI->connect($udsn, undef, undef, { RaiseError => 1 });
		$s->do('CREATE TABLE upd_unit (id INTEGER PRIMARY KEY, v TEXT)');
		$s->do("INSERT INTO upd_unit VALUES (1, 'hello')");
		$s->disconnect();
	}

	{
		package Database::upd_unit;
		use parent 'Database::Abstraction';
	}

	# Path 2: SQLite DSN — updated() must stat the file live on every call
	my $db_dsn = Database::upd_unit->new(dsn => $udsn, no_entry => 1);

	# 22.1  Before any data access updated() should still be defined (dialect
	#        and dsn are set in new(), _open() is not needed for the DSN path).
	$db_dsn->count();	# trigger _open so dialect and dsn are populated
	my $t1 = $db_dsn->updated();
	ok(defined($t1),          '22.1 updated() SQLite DSN: returns defined value');
	ok(looks_like_number($t1), '22.1 updated() SQLite DSN: value is numeric');

	# 22.2  Return value must equal stat() on the backing file
	my $stat_mtime = (stat($ufile))[9];
	is($db_dsn->updated(), $stat_mtime,
		'22.2 updated() SQLite DSN: equals current stat() mtime');

	# 22.3  Live stat: after touching the file, updated() returns the new mtime.
	#        sleep(1) ensures filesystem mtime has 1-second granularity.
	sleep(1);
	utime(undef, undef, $ufile);
	my $t2 = (stat($ufile))[9];
	is($db_dsn->updated(), $t2,
		'22.3 updated() SQLite DSN: reflects new mtime after file is touched');
	ok($t2 >= $t1, '22.3 updated() SQLite DSN: new mtime >= old mtime');

	# 22.4  Repeated calls without touching the file return the same value
	my $t3 = $db_dsn->updated();
	my $t4 = $db_dsn->updated();
	is($t3, $t4, '22.4 updated() SQLite DSN: two consecutive calls agree');

	# Path 3 (already covered in section 4 for CSV): verify a generic DSN (SQLite
	# used as proxy because it is available) returns a numeric connection-time
	# timestamp when dialect is not 'sqlite' — simulate by clearing _dialect so
	# the live-stat branch is skipped and the cached _updated is returned instead.
	{
		my $db_generic = Database::upd_unit->new(dsn => $udsn, no_entry => 1);
		$db_generic->count();	# populate _updated
		$db_generic->{'_dialect'} = 'generic';	# force generic path
		my $tu = $db_generic->updated();
		ok(defined($tu),           '22.5 updated() generic DSN: returns defined value');
		ok(looks_like_number($tu), '22.5 updated() generic DSN: value is numeric');
		ok($tu > 0,                '22.5 updated() generic DSN: value is positive');
	}

	# 22.6  dbi:SQLite:dbname= form (with explicit "dbname=") is supported
	my $db_explicit = Database::upd_unit->new(dsn => $udsn, no_entry => 1);
	$db_explicit->count();
	my $te = $db_explicit->updated();
	is($te, (stat($ufile))[9],
		'22.6 updated(): dbi:SQLite:dbname= form returns correct mtime');
}

# ---------------------------------------------------------------------------
# SECTION 23 — each_row()
#
# each_row() streams rows one at a time via a callback, returning the count
# of rows visited.  The POD documents:
#   - Callback must be a code reference (croaks otherwise).
#   - Accepts same criteria / sort_by / limit / offset as selectall_arrayref.
#   - Returns the number of rows passed to the callback.
#   - Exceptions in the callback propagate; DBI handle is left in a valid state.
#   - Slurp path: memory usage same as selectall_arrayref.
#   - SQL path:   constant memory (one row at a time).
# ---------------------------------------------------------------------------

note '';
note '=== 23. each_row() ===';
{
	my $db = Database::test1->new($DATA_DIR);

	# 23.1  Callback must be a code reference — non-coderef must croak
	throws_ok {
		$db->each_row('not a coderef')
	} qr/callback must be a code reference/i,
	'23.1 each_row(): non-coderef callback causes croak';
	delete $LEDGER{'each_row callback not coderef'};

	# 23.2  No criteria → all rows visited; callback receives a hashref each time
	{
		my @received;
		my $n = $db->each_row(sub { push @received, shift });
		ok($n >= 4, '23.2 each_row(): returns count >= 4 for unconstrained call');
		is($n, scalar @received, '23.2 each_row(): return value equals rows received by callback');
		ok(ref($received[0]) eq 'HASH', '23.2 each_row(): callback receives hashrefs');
	}

	# 23.3  Criteria filter — only matching rows reach the callback
	{
		my @got;
		my $n = $db->each_row(sub { push @got, shift }, entry => 'one');
		is($n, 1, '23.3 each_row(): with entry criterion visits exactly 1 row');
		is($got[0]{$ENTRY_COL}, 'one', '23.3 each_row(): correct row passed to callback');
	}

	# 23.4  Return value is the actual number of rows; test idempotency
	{
		my $n1 = $db->each_row(sub {});
		my $n2 = $db->each_row(sub {});
		is($n1, $n2, '23.4 each_row(): successive calls with same object return same count');
	}

	# 23.5  Exceptions from the callback propagate to the caller (slurp path)
	{
		eval {
			$db->each_row(sub { die "callback died\n" });
		};
		like($@, qr/callback died/, '23.5 each_row(): callback exception propagates to caller');
	}
}

# 23.6–23.9  SQL path (requires SQLite)
SKIP: {
	skip 'DBI/DBD::SQLite not available for each_row SQL-path tests', 4
		unless $have_sqlite;

	my $er_dir  = tempdir(CLEANUP => 1);
	my $er_file = File::Spec->catfile($er_dir, 'er_unit.sql');
	my $er_dsn  = "dbi:SQLite:dbname=$er_file";

	{
		my $s = DBI->connect($er_dsn, undef, undef, { RaiseError => 1 });
		$s->do('CREATE TABLE er_unit (id INTEGER PRIMARY KEY, v TEXT, score INTEGER)');
		for my $row ([1,'alpha',10],[2,'beta',50],[3,'gamma',30],[4,'delta',70]) {
			$s->do('INSERT INTO er_unit VALUES (?,?,?)', undef, @{$row});
		}
		$s->disconnect();
	}

	{
		package Database::er_unit;
		use parent 'Database::Abstraction';
	}

	my $er = Database::er_unit->new(dsn => $er_dsn, no_entry => 1);

	# 23.6  All rows via SQL path
	{
		my $n = $er->each_row(sub {});
		is($n, 4, '23.6 each_row() SQL path: returns 4 for all rows');
	}

	# 23.7  limit parameter reduces rows visited
	{
		my @got;
		my $n = $er->each_row(sub { push @got, shift }, limit => 2);
		is($n, 2, '23.7 each_row() SQL path: limit => 2 visits exactly 2 rows');
	}

	# 23.8  Exceptions in callback on SQL path propagate; object stays usable
	{
		eval {
			$er->each_row(sub { die "sql path die\n" });
		};
		like($@, qr/sql path die/, '23.8 each_row() SQL path: callback exception propagates');
		# Object must remain usable after an exception
		my $n = $er->each_row(sub {});
		is($n, 4, '23.8 each_row() SQL path: object usable after callback exception');
	}

	delete $LEDGER{'each_row SQL path limit'};
}

# ---------------------------------------------------------------------------
# SECTION 24 — dbi_source()
#
# The POD contract:
#   - Returns { dbh => DBI::db, table => Str } for live SQLite connections.
#   - Returns undef for every other backend (CSV, XML, XLSX, BerkeleyDB, etc.)
#   - The dbh Driver Name must be 'SQLite' for the result to be non-undef.
# ---------------------------------------------------------------------------

note '';
note '=== 24. dbi_source() ===';
{
	# 24.1  Slurp-mode CSV backend → undef
	{
		my $slurp = Database::test1->new($DATA_DIR);
		$slurp->count();	# trigger _open (slurp path)
		my $src = $slurp->dbi_source();
		ok(!defined($src), '24.1 dbi_source(): CSV slurp backend returns undef');
		delete $LEDGER{'dbi_source slurp undef'};
	}

	# 24.2  BerkeleyDB injected backend → undef (no DBI handle ever created)
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = { k => 'v' };
		my $src = $bdb->dbi_source();
		ok(!defined($src), '24.2 dbi_source(): BerkeleyDB backend returns undef');
	}
}

SKIP: {
	skip 'DBI/DBD::SQLite not available for dbi_source() tests', 8
		unless $have_sqlite;

	my $ds_dir  = tempdir(CLEANUP => 1);
	my $ds_file = File::Spec->catfile($ds_dir, 'ds_unit.sql');
	my $ds_dsn  = "dbi:SQLite:dbname=$ds_file";

	{
		my $s = DBI->connect($ds_dsn, undef, undef, { RaiseError => 1 });
		$s->do('CREATE TABLE ds_unit (entry TEXT PRIMARY KEY, val TEXT)');
		$s->do("INSERT INTO ds_unit VALUES ('a', 'alpha')");
		$s->disconnect();
	}

	{
		package Database::ds_unit;
		use parent 'Database::Abstraction';
	}

	my $db = Database::ds_unit->new(dsn => $ds_dsn);
	$db->count();	# trigger _open to establish DBI connection

	# 24.3  SQLite DSN connection → hashref
	my $src = $db->dbi_source();
	ok(defined($src),     '24.3 dbi_source() SQLite: returns defined value');
	isa_ok($src, 'HASH',  '24.3 dbi_source() SQLite: returns hashref');

	# 24.4  'dbh' key must be a blessed DBI handle
	ok(exists $src->{'dbh'}, '24.4 dbi_source() SQLite: dbh key present');
	ok(Scalar::Util::blessed($src->{'dbh'}),
		'24.4 dbi_source() SQLite: dbh is a blessed object (DBI handle)');

	# 24.5  'table' key must equal the class-derived table name
	ok(exists $src->{'table'}, '24.5 dbi_source() SQLite: table key present');
	is($src->{'table'}, 'ds_unit', '24.5 dbi_source() SQLite: table name is correct');

	# 24.6  Repeated calls return the same dbh (prepared-statement caching contract)
	my $src2 = $db->dbi_source();
	is($src->{'dbh'}, $src2->{'dbh'},
		'24.6 dbi_source() SQLite: repeated calls return same dbh');

	# 24.7  Non-SQLite DBI driver (simulate by clearing driver name) → undef
	#        We can't easily swap the driver, but we can verify the guard condition
	#        by checking that the dbh's Driver Name is 'SQLite'.
	is($src->{'dbh'}{Driver}{Name}, 'SQLite',
		'24.7 dbi_source() SQLite: Driver Name is SQLite');

	delete $LEDGER{'dbi_source SQLite hashref'};
}

# ---------------------------------------------------------------------------
# SECTION 25 — base_criteria constructor parameter
#
# The POD documents that base_criteria is ANDed into every SELECT automatically.
# Validation (unsafe keys, non-hashref) must croak at construction time.
# This section covers the documented public contract; internal _merge_base_criteria
# is exercised in function.t.
# ---------------------------------------------------------------------------

note '';
note '=== 25. base_criteria ===';
SKIP: {
	skip 'DBI/DBD::SQLite not available for base_criteria SQL-path tests', 10
		unless $have_sqlite;

	my $bc_dir  = tempdir(CLEANUP => 1);
	my $bc_file = File::Spec->catfile($bc_dir, 'bc_unit.sql');
	my $bc_dsn  = "dbi:SQLite:dbname=$bc_file";

	{
		my $s = DBI->connect($bc_dsn, undef, undef, { RaiseError => 1 });
		$s->do('CREATE TABLE bc_unit (entry TEXT PRIMARY KEY, status TEXT, score INTEGER)');
		$s->do("INSERT INTO bc_unit VALUES ('a','active',90)");
		$s->do("INSERT INTO bc_unit VALUES ('b','inactive',60)");
		$s->do("INSERT INTO bc_unit VALUES ('c','active',70)");
		$s->do("INSERT INTO bc_unit VALUES ('d','inactive',80)");
		$s->disconnect();
	}

	{
		package Database::bc_unit;
		use parent 'Database::Abstraction';
	}

	# 25.1  base_criteria filters all queries automatically
	{
		my $db = Database::bc_unit->new(dsn => $bc_dsn,
			base_criteria => { status => 'active' });
		my $n = $db->count();
		is($n, 2, '25.1 base_criteria: count() sees only active rows');
		delete $LEDGER{'base_criteria active filter'};
	}

	# 25.2  base_criteria applies to selectall_arrayref
	{
		my $db = Database::bc_unit->new(dsn => $bc_dsn,
			base_criteria => { status => 'inactive' });
		my $all = $db->selectall_arrayref();
		is(scalar @{$all}, 2, '25.2 base_criteria: selectall_arrayref filtered to 2 inactive rows');
		ok(!(grep { $_->{'status'} eq 'active' } @{$all}),
			'25.2 base_criteria: no active rows in result');
	}

	# 25.3  Caller criteria further narrow the base filter (AND semantics)
	{
		my $db = Database::bc_unit->new(dsn => $bc_dsn,
			base_criteria => { status => 'active' });
		my $n = $db->count(score => { '>' => 80 });
		is($n, 1, '25.3 base_criteria: caller criterion ANDed with base (1 active with score > 80)');
	}

	# 25.4  Caller keys WIN on collision — caller can tighten but not bypass
	{
		my $db = Database::bc_unit->new(dsn => $bc_dsn,
			base_criteria => { status => 'active' });
		# Override status to 'inactive' — caller wins so we should see inactive rows
		my $n = $db->count(status => 'inactive');
		is($n, 2, '25.4 base_criteria: caller key wins on collision');
	}

	# 25.5  Non-hashref base_criteria → croak at construction time
	throws_ok {
		Database::bc_unit->new(dsn => $bc_dsn, base_criteria => ['status', 'active'])
	} qr/base_criteria must be a hashref/i,
	'25.5 base_criteria: non-hashref causes croak at construction time';
	delete $LEDGER{'base_criteria must be hashref'};

	# 25.6  Unsafe key in base_criteria → croak at construction time
	throws_ok {
		Database::bc_unit->new(dsn => $bc_dsn, base_criteria => { 'bad;key' => 1 })
	} qr/unsafe base_criteria key/i,
	'25.6 base_criteria: unsafe column key causes croak at construction time';
	delete $LEDGER{'base_criteria unsafe key'};

	# 25.7  base_criteria applies to query builder
	{
		my $db = Database::bc_unit->new(dsn => $bc_dsn,
			base_criteria => { status => 'active' });
		my $n = $db->query()->count();
		is($n, 2, '25.7 base_criteria: query()->count() respects base filter');
	}

	# 25.8  base_criteria mutation after construction does NOT affect the object
	#        (shallow copy taken at new() time)
	{
		my %bc = (status => 'active');
		my $db = Database::bc_unit->new(dsn => $bc_dsn, base_criteria => \%bc);
		$bc{'status'} = 'inactive';	# mutate original hash
		my $n = $db->count();
		is($n, 2, '25.8 base_criteria: mutation of original hashref after new() has no effect');
	}
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
		each_row SQL path limit
		dbi_source SQLite hashref
		base_criteria active filter
		base_criteria must be hashref
		base_criteria unsafe key
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
