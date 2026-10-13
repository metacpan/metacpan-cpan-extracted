#!perl -w

# White-box unit tests for every sub in:
#   lib/Database/Abstraction.pm
#   lib/Database/Abstraction/Query.pm
#
# Strategy: each logical section corresponds to one sub or a closely
# related group of subs.  Private helpers are exercised by calling them
# directly on a blessed test object (white-box) rather than routing
# through the public API, so we can isolate the logic without spinning
# up a real database for every test.
#
# Mocking policy:
#   - Concrete fixture files in t/data/ are used for integration-level
#     tests where the real backend logic is being exercised.
#   - Test::Returns validates return-value shapes (scalar / arrayref / hashref).
#   - Test::Memory::Cycle catches circular references that would leak.

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Scalar::Util qw(blessed looks_like_number);
use Readonly;

use Test::Most;
use Test::Returns;
use Test::Returns;
use Test::Memory::Cycle;

# ---------------------------------------------------------------------------
# Constants for magic values
# ---------------------------------------------------------------------------
Readonly my $DATA_DIR   => File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
Readonly my $ENTRY_COL  => 'entry';
Readonly my $DEFAULT_SEP => '!';

# ---------------------------------------------------------------------------
# Prerequisite check: DBI + DBD::SQLite needed for SQL-path tests
# ---------------------------------------------------------------------------
my $have_sqlite = eval { require DBI; require DBD::SQLite; 1 };

# No fixed plan — done_testing() at EOF counts actual tests run.
# SKIP blocks vary the count depending on which optional modules are present.

use lib 't/lib';
use_ok('Database::test1');		# CSV slurp fixture
use_ok('Database::test4ne');		# no_entry CSV, id=>'cardinal' — produces ARRAY slurp
use_ok('Database::test5');		# CSV with custom id ('ID'), sep ','

# ---------------------------------------------------------------------------
# PART A — Database::Abstraction
# ---------------------------------------------------------------------------

note '';
note '=== Database::Abstraction ===';

# ---- A1: init() -----------------------------------------------------------
note '--- A1: init()';
{
	# Reset defaults so tests are deterministic
	%Database::Abstraction::defaults = ();

	my $d = Database::Abstraction::init(directory => $DATA_DIR);
	returns_is($d, { type => 'hashref' }, 'init() returns a hashref');
	is($Database::Abstraction::defaults{'directory'}, $DATA_DIR, 'init(): directory stored in %defaults');

	# expires_in aliased to cache_duration
	Database::Abstraction::init(expires_in => '30 minutes');
	is($Database::Abstraction::defaults{'cache_duration'}, '30 minutes',
		'init(): expires_in copied to cache_duration');

	# cache_duration is NOT set when init() is called with no args —
	# the default only fires when params are present (the || guard inside the if block)
	%Database::Abstraction::defaults = ();
	Database::Abstraction::init();
	ok(!exists $Database::Abstraction::defaults{'cache_duration'},
		'init(): no-arg call leaves cache_duration unset (default fires only with params)');

	# Existing keys must be merged (not replaced)
	Database::Abstraction::init(foo => 'bar');
	is($Database::Abstraction::defaults{'cache_duration'}, '1 hour',
		'init(): merge preserves pre-existing defaults');
	is($Database::Abstraction::defaults{'foo'}, 'bar', 'init(): new key added');

	%Database::Abstraction::defaults = ();		# restore
}

# ---- A2: new() --- construction paths ------------------------------------
note '--- A2: new()';
{
	# Direct instantiation of abstract base must die
	throws_ok { Database::Abstraction->new(directory => $DATA_DIR) }
		qr/abstract class/i,
		'new(): abstract base class cannot be instantiated directly';

	# Bare-string shortcut
	my $obj = Database::test1->new($DATA_DIR);
	returns_is($obj, { type => 'object', isa => 'Database::test1' }, 'new(): bare string → directory');
	is($obj->{'id'}, $ENTRY_COL, 'new(): id defaults to "entry"');
	ok(!$obj->{'no_entry'}, 'new(): no_entry defaults to 0');
	is($obj->{'cache_duration'}, '1 hour', 'new(): cache_duration defaults to 1 hour');

	# Hashref form
	my $obj2 = Database::test1->new({ directory => $DATA_DIR });
	returns_is($obj2, { type => 'object', isa => 'Database::test1' }, 'new(): hashref args accepted');

	# Named-list form
	my $obj3 = Database::test1->new(directory => $DATA_DIR);
	returns_is($obj3, { type => 'object', isa => 'Database::test1' }, 'new(): named-list args accepted');

	# Clone form: $obj->new(extra_key => 1) merges into a new object
	my $clone = $obj->new(extra_key => 'clone_val');
	returns_is($clone, { type => 'object', isa => 'Database::test1' }, 'new(): clone retains class');
	is($clone->{'extra_key'}, 'clone_val', 'new(): clone merges extra key');
	is($clone->{'id'}, $ENTRY_COL, 'new(): clone inherits id');

	# No directory → croak
	throws_ok { Database::test1->new() }
		qr/where are the files\?/i,
		'new(): no directory or dsn causes croak';

	# Non-existent directory → croak
	throws_ok { Database::test1->new(directory => '/no/such/path/xyz') }
		qr/is not a directory/i,
		'new(): non-directory path causes croak';

	# Code-ref logger wrapped into Log::Abstraction object
	my @msgs;
	my $obj4 = Database::test1->new({ directory => $DATA_DIR, logger => sub { push @msgs, @_ } });
	ok(Scalar::Util::blessed($obj4->{'logger'}),
		'new(): coderef logger normalised to blessed object');

	memory_cycle_ok($obj, 'new(): no memory cycles in returned object');
}

# ---- A3: set_logger() ----------------------------------------------------
note '--- A3: set_logger()';
{
	my $db = Database::test1->new($DATA_DIR);

	# Valid blessed logger passes through unchanged
	my $fake_log = bless {}, 'Fake::Log';
	my $ret = $db->set_logger(logger => $fake_log);
	is($ret, $db, 'set_logger(): returns $self for chaining');
	is($db->{'logger'}, $fake_log, 'set_logger(): blessed logger stored as-is');

	# Non-blessed scalar (filename/string) → wrapped by Log::Abstraction
	$db->set_logger(logger => '/dev/null');
	ok(Scalar::Util::blessed($db->{'logger'}),
		'set_logger(): string logger wrapped in Log::Abstraction');

	# Missing logger → croak (message may come from Params::Get or our own croak;
	# either way "set_logger" must appear in the error text)
	throws_ok { $db->set_logger() }
		qr/set_logger/,
		'set_logger(): no logger arg causes croak';
}

# ---- A4: updated() -------------------------------------------------------
note '--- A4: updated()';
{
	my $db = Database::test1->new($DATA_DIR);
	# _updated may or may not be set until _open runs; just ensure it doesn't croak
	my $u = $db->updated();
	ok(!defined($u) || looks_like_number($u), 'updated(): returns undef or numeric timestamp');
}

# ---- A5: _log / _debug / _trace / _warn / _fatal -------------------------
note '--- A5: logging helpers';
{
	my @captured;
	my $db = Database::test1->new({
		directory => $DATA_DIR,
		logger    => sub { push @captured, join('', @_) },
	});

	# _debug appends to the internal messages array; the logger coderef is
	# wrapped by Log::Abstraction so we verify via messages, not @captured
	$db->_debug('hello debug');
	is(scalar @{$db->{'messages'}}, 1, '_debug(): appends to messages');
	like($db->{'messages'}[-1]{'message'}, qr/hello debug/, '_debug(): message stored correctly');

	# _trace calls through
	$db->_trace('trace me');
	like($db->{'messages'}[-1]{'message'}, qr/trace me/, '_trace(): stored in messages');

	# _warn emits carp (non-fatal) — catches with lives_ok
	lives_ok { $db->_warn('harmless warning') } '_warn(): does not croak';

	# _fatal croaks with the message
	throws_ok { $db->_fatal('kaboom') }
		qr/kaboom/,
		'_fatal(): croaks with supplied message';
}

# ---- A6: _has_complex_criteria() -----------------------------------------
note '--- A6: _has_complex_criteria()';
{
	my $db = Database::test1->new($DATA_DIR);

	ok(!$db->_has_complex_criteria(undef), 'no criteria → false');
	ok(!$db->_has_complex_criteria({}),    'empty hash → false');
	ok(!$db->_has_complex_criteria({ a => 'x' }), 'plain scalar → false');
	ok($db->_has_complex_criteria({ '-or' => [] }),  '-or → true');
	ok($db->_has_complex_criteria({ '-and' => [] }), '-and → true');
	ok($db->_has_complex_criteria({ a => { '>' => 1 } }), 'hashref value → true');
}

# ---- A7: _build_where() --------------------------------------------------
note '--- A7: _build_where()';
{
	my $db = Database::test1->new($DATA_DIR);

	# Empty params → empty string and no bind args
	my ($sql, $args) = $db->_build_where({});
	is($sql, '', '_build_where(): empty params → empty SQL');
	is(scalar @{$args}, 0, '_build_where(): empty params → no bind args');

	# Single plain equality
	($sql, $args) = $db->_build_where({ name => 'Alice' });
	like($sql, qr/name = \?/, '_build_where(): plain equality → = ?');
	is($args->[0], 'Alice', '_build_where(): bind value correct');

	# LIKE pattern when value has %
	($sql, $args) = $db->_build_where({ name => 'Al%' });
	like($sql, qr/name LIKE \?/, '_build_where(): wildcard → LIKE');

	# IS NULL when value is undef
	($sql, $args) = $db->_build_where({ name => undef });
	like($sql, qr/name IS NULL/, '_build_where(): undef → IS NULL');

	# -or grouping
	($sql, $args) = $db->_build_where({
		'-or' => [ { a => '1' }, { b => '2' } ]
	});
	like($sql, qr/\(.*OR.*/i, '_build_where(): -or group → OR clause');

	# -and grouping
	($sql, $args) = $db->_build_where({
		'-and' => [ { a => '1' }, { b => '2' } ]
	});
	like($sql, qr/\(.*AND.*/i, '_build_where(): -and group → AND clause');

	# Return value shape
	returns_ok($args, { type => 'arrayref' }, '_build_where(): bind args are arrayref');
}

# ---- A8: _build_where_conditions() ---------------------------------------
note '--- A8: _build_where_conditions()';
{
	my $db = Database::test1->new($DATA_DIR);

	# Each operator type
	my %cases = (
		'> operator'       => [{ score => { '>'  => 5  } }, qr/score > \?/],
		'< operator'       => [{ score => { '<'  => 5  } }, qr/score < \?/],
		'>= operator'      => [{ score => { '>=' => 5  } }, qr/score >= \?/],
		'<= operator'      => [{ score => { '<=' => 5  } }, qr/score <= \?/],
		'!= scalar'        => [{ score => { '!=' => 5  } }, qr/score != \?/],
		'!= undef IS NULL' => [{ score => { '!=' => undef } }, qr/score IS NOT NULL/],
		'-in list'         => [{ score => { '-in'  => [1,2] } }, qr/score IN \(\?,\s*\?\)/],
		'-not_in'          => [{ score => { '-not_in' => [1] } }, qr/score NOT IN \(\?\)/],
		'-between'         => [{ score => { '-between' => [1,9] } }, qr/score BETWEEN \? AND \?/],
		'-like pattern'    => [{ name  => { '-like' => 'A%' } }, qr/name LIKE \?/],
		'-not_like'        => [{ name  => { '-not_like' => 'Z%' } }, qr/name NOT LIKE \?/],
	);

	for my $label (sort keys %cases) {
		my ($params, $re) = @{$cases{$label}};
		my ($sql, $args) = $db->_build_where_conditions($params);
		like($sql, $re, "_build_where_conditions(): $label");
	}

	# SQL injection guard
	throws_ok {
		$db->_build_where_conditions({ 'bad; DROP TABLE--' => 'x' })
	} qr/unsafe column name/i, '_build_where_conditions(): rejects unsafe column name';

	# Unknown operator
	throws_ok {
		$db->_build_where_conditions({ col => { '-bogus' => 1 } })
	} qr/Unknown operator/i, '_build_where_conditions(): rejects unknown operator';

	# Non-hashref non-scalar value → croak
	throws_ok {
		$db->_build_where_conditions({ col => [1, 2, 3] })
	} qr/expected scalar or operator hashref/i,
		'_build_where_conditions(): arrayref value causes croak';
}

# ---- A9: _match_criterion() ----------------------------------------------
note '--- A9: _match_criterion()';
{
	my $db = Database::test1->new($DATA_DIR);

	# Scalar equality
	ok($db->_match_criterion('foo', 'foo'),  '_match_criterion(): equal scalars → 1');
	ok(!$db->_match_criterion('foo', 'bar'), '_match_criterion(): unequal scalars → 0');

	# NULL semantics
	ok($db->_match_criterion(undef, undef),  '_match_criterion(): undef==undef → 1');
	ok(!$db->_match_criterion(undef, 'x'),   '_match_criterion(): undef!=scalar → 0');
	ok(!$db->_match_criterion('x', undef),   '_match_criterion(): scalar!=undef → 0');

	# Operator hashrefs
	ok($db->_match_criterion(10, { '>'  => 5  }), '_match_criterion(): > true');
	ok(!$db->_match_criterion(3,  { '>'  => 5  }), '_match_criterion(): > false');
	ok($db->_match_criterion(5,  { '>=' => 5  }), '_match_criterion(): >= boundary');
	ok($db->_match_criterion(3,  { '<'  => 5  }), '_match_criterion(): < true');
	ok($db->_match_criterion(5,  { '<=' => 5  }), '_match_criterion(): <= boundary');
	ok($db->_match_criterion('b', { '!=' => 'a' }), '_match_criterion(): != true');
	ok(!$db->_match_criterion('a', { '!=' => 'a' }), '_match_criterion(): != false');
	# !={undef} means IS NOT NULL; undef row value is NULL → does not match
	ok(!$db->_match_criterion(undef, { '!=' => undef }), '_match_criterion(): IS NOT NULL rejects NULL row value');

	# -in / -not_in
	ok($db->_match_criterion('x', { '-in'     => ['x','y'] }), '_match_criterion(): -in hit');
	ok(!$db->_match_criterion('z', { '-in'     => ['x','y'] }), '_match_criterion(): -in miss');
	ok($db->_match_criterion('z', { '-not_in' => ['x','y'] }), '_match_criterion(): -not_in hit');
	ok(!$db->_match_criterion('x', { '-not_in' => ['x','y'] }), '_match_criterion(): -not_in miss');

	# -between
	ok($db->_match_criterion(5, { '-between' => [1, 9] }), '_match_criterion(): -between in range');
	ok(!$db->_match_criterion(0, { '-between' => [1, 9] }), '_match_criterion(): -between out of range');

	# -like / -not_like
	ok($db->_match_criterion('Alice', { '-like'     => 'Al%' }), '_match_criterion(): -like match');
	ok(!$db->_match_criterion('Bob',  { '-like'     => 'Al%' }), '_match_criterion(): -like no match');
	ok($db->_match_criterion('Bob',   { '-not_like' => 'Al%' }), '_match_criterion(): -not_like match');
}

# ---- A10: _build_joins() -------------------------------------------------
note '--- A10: _build_joins()';
{
	my $db = Database::test1->new($DATA_DIR);

	# Single hashref → INNER JOIN by default
	my $sql = $db->_build_joins({ table => 'dept', on => 'a.id = dept.id' });
	like($sql, qr/INNER JOIN dept ON \(a\.id = dept\.id\)/, '_build_joins(): default INNER JOIN');

	# Explicit LEFT JOIN
	$sql = $db->_build_joins({ table => 'dept', on => 'x.id = dept.id', type => 'LEFT' });
	like($sql, qr/LEFT JOIN dept/, '_build_joins(): explicit LEFT JOIN');

	# Case insensitivity for type
	$sql = $db->_build_joins({ table => 't', on => 'a.id = t.id', type => 'left' });
	like($sql, qr/LEFT JOIN/, '_build_joins(): lowercase type normalised');

	# Arrayref of specs → multiple JOIN clauses
	$sql = $db->_build_joins([
		{ table => 'a', on => 'x.id = a.id' },
		{ table => 'b', on => 'x.id = b.id', type => 'LEFT' },
	]);
	like($sql, qr/INNER JOIN a/, '_build_joins(): first join from array');
	like($sql, qr/LEFT JOIN b/,  '_build_joins(): second join from array');

	# Missing table → croak
	throws_ok { $db->_build_joins({ on => 'x.id = y.id' }) }
		qr/missing "table"/i, '_build_joins(): missing table causes croak';

	# Missing on → croak
	throws_ok { $db->_build_joins({ table => 'foo' }) }
		qr/missing "on"/i, '_build_joins(): missing on causes croak';

	# Invalid type → croak
	throws_ok { $db->_build_joins({ table => 'foo', on => 'x=y', type => 'DIAGONAL' }) }
		qr/Invalid JOIN type/i, '_build_joins(): invalid type causes croak';
}

# ---- A11: _quote_identifier() --------------------------------------------
note '--- A11: _quote_identifier()';
{
	my $db = Database::test1->new($DATA_DIR);

	# No connection open yet → ANSI double-quote fallback
	my $q = $db->_quote_identifier('my_col');
	is($q, '"my_col"', '_quote_identifier(): fallback uses ANSI double-quotes');
}

# ---- A12: _is_berkeley_db / _has_bdb_magic --------------------------------
note '--- A12: BerkeleyDB magic-number probes';
{
	my $db = Database::test1->new($DATA_DIR);

	# Non-existent file → silently returns false (no autodie exception)
	ok(!$db->_is_berkeley_db('/no/such/file.db'),
		'_is_berkeley_db(): non-existent file → 0 (silent)');

	# Regular text file → not a BDB
	my $tmpfile = File::Temp->new(SUFFIX => '.db');
	print {$tmpfile} "this is not a berkeley db file\n";
	$tmpfile->flush();
	ok(!$db->_is_berkeley_db($tmpfile->filename()),
		'_is_berkeley_db(): text file → 0');

	# _has_bdb_magic: file with < 4 bytes → offset-0 read guard fires → 0
	{
		my $tiny = File::Temp->new();
		print {$tiny} 'XY';
		$tiny->flush();
		open my $fh, '<', $tiny->filename();	## no critic
		binmode $fh;
		ok(!$db->_has_bdb_magic($fh), '_has_bdb_magic(): <4 bytes → 0');
		close $fh;
	}

	# _has_bdb_magic: 4 non-magic bytes at offset 0, file too short for offset 12 → 0
	{
		my $tiny2 = File::Temp->new();
		print {$tiny2} 'XYZW';	# 4 bytes, no BDB magic
		$tiny2->flush();
		open my $fh, '<', $tiny2->filename();	## no critic
		binmode $fh;
		ok(!$db->_has_bdb_magic($fh), '_has_bdb_magic(): non-magic 4 bytes, offset-12 empty → 0');
		close $fh;
	}
}

# ---- A13: fetchrow_hashref() with slurped data ---------------------------
note '--- A13: fetchrow_hashref() — slurp path';
{
	my $db = Database::test1->new($DATA_DIR);

	# Hit
	my $row = $db->fetchrow_hashref(entry => 'one');
	returns_is($row, { type => 'hashref' }, 'fetchrow_hashref(): returns hashref on hit');
	is($row->{$ENTRY_COL}, 'one', 'fetchrow_hashref(): correct row returned');

	# Miss → undef (not throw, even with locked hash)
	my $miss = $db->fetchrow_hashref(entry => '__nonexistent__');
	returns_is($miss, { type => 'void' }, 'fetchrow_hashref(): miss returns undef');

	# Bare single-arg shortcut (no_entry not set)
	my $row2 = $db->fetchrow_hashref('two');
	is($row2->{'number'}, 2, 'fetchrow_hashref(): bare arg used as entry');

	memory_cycle_ok($db, 'fetchrow_hashref(): no memory cycles after call');
}

# ---- A14: selectall_arrayref() — slurp path ------------------------------
note '--- A14: selectall_arrayref() — slurp path';
{
	my $db = Database::test1->new($DATA_DIR);

	# No criteria → all rows
	my $all = $db->selectall_arrayref();
	returns_is($all, { type => 'arrayref', min => 4 }, 'selectall_arrayref(): no criteria returns arrayref of ≥4 rows');

	# In-memory scan by non-key column
	my $matches = $db->selectall_arrayref(number => 1);
	is(scalar @{$matches}, 1, 'selectall_arrayref(): in-memory scan finds 1 match');
	is($matches->[0]{$ENTRY_COL}, 'one', 'selectall_arrayref(): correct row returned');

	# In-memory scan, no match → empty arrayref
	my $none = $db->selectall_arrayref(number => 9999);
	returns_ok($none, { type => 'arrayref' }, 'selectall_arrayref(): miss returns arrayref');
	is(scalar @{$none}, 0, 'selectall_arrayref(): miss returns empty arrayref');

	# Entry fast-path
	my $bykey = $db->selectall_arrayref(entry => 'two');
	is($bykey->[0]{$ENTRY_COL}, 'two', 'selectall_arrayref(): entry fast-path returns correct row');
}

# ---- A15: selectall_array() ----------------------------------------------
note '--- A15: selectall_array()';
{
	my $db = Database::test1->new($DATA_DIR);

	# List context → all rows
	my @rows = $db->selectall_array();
	ok(scalar @rows >= 4, 'selectall_array(): list context returns all rows');

	# In-memory scan
	my @one = $db->selectall_array(number => 1);
	is(scalar @one, 1, 'selectall_array(): in-memory scan returns 1 row');
	is($one[0]{$ENTRY_COL}, 'one', 'selectall_array(): correct row from in-memory scan');
}

# ---- A16: count() — slurp path -------------------------------------------
note '--- A16: count()';
{
	my $db = Database::test1->new($DATA_DIR);

	my $n = $db->count();
	ok($n > 0, 'count(): positive total');
	ok(looks_like_number($n), 'count(): returns a number');

	# Entry fast-path: known entry = 1
	my $one = $db->count(entry => 'one');
	is($one, 1, 'count(): entry fast-path for known entry returns 1');

	# Entry fast-path: unknown entry = 0
	my $zero = $db->count(entry => '__missing__');
	is($zero, 0, 'count(): entry fast-path for missing entry returns 0');
}

# ---- A17: AUTOLOAD — column shortcut -------------------------------------
note '--- A17: AUTOLOAD';
{
	my $db = Database::test1->new($DATA_DIR);

	# Scalar context → single value
	my $val = $db->number(entry => 'two');
	is($val, 2, 'AUTOLOAD(): scalar context returns column value');

	# List context → all values for that column
	my @nums = $db->number();
	ok(scalar @nums >= 4, 'AUTOLOAD(): list context returns multiple values');

	# Missing entry → undef (not throw)
	my $miss = $db->number(entry => '__nope__');
	returns_is($miss, { type => 'void' }, 'AUTOLOAD(): missing entry returns undef');

	# auto_load => 0 → croak
	my $noa = Database::test1->new({ directory => $DATA_DIR, auto_load => 0 });
	throws_ok { $noa->number() }
		qr/AUTOLOAD disabled/i,
		'AUTOLOAD(): auto_load=>0 causes croak';

	# Custom id column (test5: 'ID') — test5->new() requires named args
	my $db5 = Database::test5->new(directory => $DATA_DIR);
	my @names = $db5->Name();
	ok(scalar @names >= 1, 'AUTOLOAD(): custom id column (test5) returns names');
}

# ---- A18: execute() ------------------------------------------------------
note '--- A18: execute() — DSN path';
SKIP: {
	skip 'DBD::SQLite not available', 5 unless $have_sqlite;

	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'exec.sql');
	my $dsn  = "dbi:SQLite:dbname=$file";

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do('CREATE TABLE exec (id INTEGER PRIMARY KEY, val TEXT)');
	$setup->do("INSERT INTO exec VALUES (1, 'alpha')");
	$setup->do("INSERT INTO exec VALUES (2, 'beta')");
	$setup->disconnect();

	{
		package Database::exectest;
		use parent 'Database::Abstraction';
	}

	my $db = Database::exectest->new(dsn => $dsn, no_entry => 1);

	# List context → array of hashrefs
	my @rows = $db->execute(query => 'SELECT * FROM exec');
	is(scalar @rows, 2, 'execute(): list context returns all rows');
	returns_is($rows[0], { type => 'hashref' }, 'execute(): each row is a hashref');

	# Scalar context → first row only
	my $row = $db->execute(query => 'SELECT * FROM exec WHERE id = ?', args => [1]);
	is($row->{'val'}, 'alpha', 'execute(): scalar context + arrayref args returns first row');

	# Scalar bind arg (not arrayref)
	my $row2 = $db->execute(query => 'SELECT * FROM exec WHERE id = ?', args => 2);
	is($row2->{'val'}, 'beta', 'execute(): scalar args form works');

	# Missing query → croak (Params::Get or our own croak both mention "execute")
	throws_ok { $db->execute() }
		qr/execute/i,
		'execute(): no query arg causes croak';
}

# ---- A19: columns() and schema() — slurp mode ---------------------------
note '--- A19: columns() and schema()';
{
	my $db = Database::test1->new($DATA_DIR);

	my $cols = $db->columns();
	returns_is($cols, { type => 'arrayref' }, 'columns(): returns arrayref');
	ok(grep({ $_ eq $ENTRY_COL } @{$cols}), 'columns(): entry column present');

	# Cached on second call
	my $cols2 = $db->columns();
	is($cols, $cols2, 'columns(): returns cached ref on second call');

	my $schema = $db->schema();
	returns_is($schema, { type => 'hashref' }, 'schema(): returns hashref');
	ok(exists $schema->{$ENTRY_COL}, 'schema(): entry key present');
	ok(exists $schema->{$ENTRY_COL}{'type'}, 'schema(): type sub-key present');
	ok(exists $schema->{$ENTRY_COL}{'nullable'}, 'schema(): nullable sub-key present');
	ok(exists $schema->{$ENTRY_COL}{'pk'}, 'schema(): pk sub-key present');
	is($schema->{$ENTRY_COL}{'pk'}, 1, 'schema(): entry column is pk');

	# Cached on second call
	my $schema2 = $db->schema();
	is($schema, $schema2, 'schema(): cached ref returned on second call');
}

# ---- A19b: columns() and schema() — no_entry CSV ARRAY slurp path -------
# Bug fix: when $self->{'data'} is an ARRAY ref (no_entry CSV slurp), the
# ref($data) eq 'HASH' branch was skipped, returning empty results.
# The fix adds an elsif for ARRAY ref.
# Database::test4ne has id=>'cardinal' so test4.csv rows survive the slurp
# filter and are stored as an ARRAY ref.
note '--- A19b: columns() and schema() — ARRAY-ref slurp path';
{
	my $ne = Database::test4ne->new(directory => $DATA_DIR);
	$ne->count();    # trigger lazy _open and slurp into ARRAY ref

	is(ref($ne->{'data'}), 'ARRAY',
		'A19b pre-cond: data is ARRAY ref for test4ne');

	my $ne_cols = $ne->columns();
	returns_is($ne_cols, { type => 'arrayref' },
		'columns() ARRAY slurp: returns arrayref (not empty)');
	ok(scalar(@{$ne_cols}) > 0,
		'columns() ARRAY slurp: list is non-empty');

	my $ne_schema = $ne->schema();
	returns_is($ne_schema, { type => 'hashref' },
		'schema() ARRAY slurp: returns hashref (not empty)');
	ok(scalar(keys %{$ne_schema}) > 0,
		'schema() ARRAY slurp: schema is non-empty');
}

# ---- A20: query() — returns Query object ---------------------------------
note '--- A20: query()';
{
	my $db = Database::test1->new($DATA_DIR);

	# Mocking is not needed here; just verify the object type
	SKIP: {
		skip 'DBD::SQLite not available for query() path', 1 unless $have_sqlite;
		my $q = $db->query();
		returns_is($q, { type => 'object', isa => 'Database::Abstraction::Query' }, 'query(): returns Query object');
	}
}

# ---- A21: _open() caller-guard -------------------------------------------
note '--- A21: _open() access guard';
{
	# Calling _open from outside the class hierarchy must croak
	throws_ok { Database::Abstraction::_open(bless {}, 'Database::test1') }
		qr/Illegal Operation/i,
		'_open(): called from outside hierarchy croaks';
}

# ---------------------------------------------------------------------------
# PART B — Database::Abstraction::Query
# ---------------------------------------------------------------------------

note '';
note '=== Database::Abstraction::Query ===';

SKIP: {
	skip 'DBD::SQLite not available for Query tests', 22 unless $have_sqlite;

	use_ok('Database::Abstraction::Query');

	# Build a tiny SQLite fixture for all Query tests
	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'qtest.sql');
	my $dsn  = "dbi:SQLite:dbname=$file";

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do('CREATE TABLE qtest (entry TEXT PRIMARY KEY, name TEXT, score REAL, status TEXT)');
	for my $r (
		['a', 'Alice', 9.5, 'active'],
		['b', 'Bob',   7.0, 'active'],
		['c', 'Carol', 8.5, 'active'],
		['d', 'Dave',  6.0, 'inactive'],
		['e', 'Eve',   10,  'inactive'],
	) {
		$setup->do('INSERT INTO qtest VALUES (?,?,?,?)', undef, @{$r});
	}
	$setup->disconnect();

	{
		package Database::qtest;
		use parent 'Database::Abstraction';
	}

	my $db = Database::qtest->new(dsn => $dsn);

	# ---- B1: new() validation ----------------------------------------
	note '--- B1: Query->new()';

	throws_ok { Database::Abstraction::Query->new() }
		qr/_db is required/i,
		'Query->new(): missing _db causes croak';

	throws_ok { Database::Abstraction::Query->new(_db => bless {}, 'Not::A::DB') }
		qr/_db must be a Database::Abstraction/i,
		'Query->new(): wrong type causes croak';

	my $q = $db->query();
	returns_is($q, { type => 'object', isa => 'Database::Abstraction::Query' }, 'Query->new(): valid object');

	memory_cycle_ok($q, 'Query->new(): no memory cycles');

	# ---- B2: builder methods return $self ----------------------------
	note '--- B2: builder methods chain';

	is($q->select('name'), $q, 'select(): returns $self');
	is($q->where(status => 'active'), $q, 'where(): returns $self');
	is($q->order_by('name ASC'), $q, 'order_by(): returns $self');
	is($q->limit(10), $q, 'limit(): returns $self');
	is($q->offset(0), $q, 'offset(): returns $self');

	my $spec = { table => 't', on => 'x.id=t.id' };
	is($q->join($spec), $q, 'join(): returns $self');

	# ---- B3: all() ---------------------------------------------------
	note '--- B3: Query->all()';

	my $q2 = $db->query();
	my $all = $q2->all();
	returns_is($all, { type => 'arrayref', min => 5, max => 5 }, 'all(): returns 5-row arrayref');

	# where() + all()
	my $active = $db->query->where(status => 'active')->all();
	is(scalar @{$active}, 3, 'all(): with where filter returns 3 rows');

	# ---- B4: first() -------------------------------------------------
	note '--- B4: Query->first()';

	my $first = $db->query->where(name => 'Alice')->first();
	returns_is($first, { type => 'hashref' }, 'first(): returns hashref');
	is($first->{'name'}, 'Alice', 'first(): correct row returned');

	my $miss = $db->query->where(name => '__nobody__')->first();
	returns_is($miss, { type => 'void' }, 'first(): no match returns undef');

	# ---- B5: count() -------------------------------------------------
	note '--- B5: Query->count()';

	my $n = $db->query->count();
	is($n, 5, 'count(): all rows = 5');

	my $n2 = $db->query->where(status => 'active')->count();
	is($n2, 3, 'count(): filtered count = 3');

	# ---- B6: limit / offset ------------------------------------------
	note '--- B6: limit + offset';

	my $limited = $db->query->order_by('entry')->limit(2)->all();
	is(scalar @{$limited}, 2, 'limit(2): returns exactly 2 rows');

	my $paged = $db->query->order_by('entry')->limit(2)->offset(2)->all();
	is(scalar @{$paged}, 2, 'limit+offset: page 2 returns 2 rows');
	isnt($limited->[0]{'entry'}, $paged->[0]{'entry'},
		'limit+offset: page 2 starts at different row than page 1');

	# ---- B7: select() column projection ------------------------------
	note '--- B7: select() column projection';

	my $names = $db->query->select('name')->where(status => 'active')->all();
	ok(exists $names->[0]{'name'}, 'select(): name key present');

	# ---- B8: _apply_perl_sort_limit() --------------------------------
	note '--- B8: _apply_perl_sort_limit()';

	# Sort ASC: names must be in ascending alphabetical order after sort
	{
		my @rows = (
			{ name => 'Carol', score => 8 },
			{ name => 'Alice', score => 9 },
			{ name => 'Bob',   score => 7 },
		);
		Database::Abstraction::Query::_apply_perl_sort_limit(\@rows, 'name ASC', undef, undef);
		is($rows[0]{'name'}, 'Alice', '_apply_perl_sort_limit(): ASC → first is Alice');
		is($rows[2]{'name'}, 'Carol', '_apply_perl_sort_limit(): ASC → last is Carol');
	}

	# Sort DESC: scores in descending order
	{
		my @rows = (
			{ name => 'Carol', score => 8 },
			{ name => 'Alice', score => 9 },
			{ name => 'Bob',   score => 7 },
		);
		Database::Abstraction::Query::_apply_perl_sort_limit(\@rows, 'name DESC', undef, undef);
		is($rows[0]{'name'}, 'Carol', '_apply_perl_sort_limit(): DESC → first is Carol');
		is($rows[2]{'name'}, 'Alice', '_apply_perl_sort_limit(): DESC → last is Alice');
	}

	# Offset: skip the first N rows
	{
		my @rows = map { { n => $_ } } (1..5);
		Database::Abstraction::Query::_apply_perl_sort_limit(\@rows, undef, 2, undef);
		is(scalar @rows, 3, '_apply_perl_sort_limit(): offset 2 leaves 3 rows');
		is($rows[0]{'n'}, 3, '_apply_perl_sort_limit(): offset 2 → first row is n=3');
	}

	# Limit: keep only the first N rows
	{
		my @rows = map { { n => $_ } } (1..5);
		Database::Abstraction::Query::_apply_perl_sort_limit(\@rows, undef, undef, 3);
		is(scalar @rows, 3, '_apply_perl_sort_limit(): limit 3 → exactly 3 rows');
		is($rows[-1]{'n'}, 3, '_apply_perl_sort_limit(): limit 3 → last row is n=3');
	}

	# Sort + offset + limit combined: verify the complete pipeline
	{
		my @rows = map { { n => $_, name => chr(ord('e') - $_) } } (1..5);
		Database::Abstraction::Query::_apply_perl_sort_limit(\@rows, 'name ASC', 1, 2);
		is(scalar @rows, 2, '_apply_perl_sort_limit(): combined: 2 rows after offset+limit');
	}

	# ---- B9: _build_sql() internal SQL assembly ----------------------
	note '--- B9: _build_sql()';

	# SELECT * with no WHERE — CSV comment-row guard is added for CSV type,
	# but since the backend is SQLite here, no_entry matters.
	{
		my $q_bare = $db->query();
		my ($sql, $args, $tbl) = $q_bare->_build_sql(0);
		like($sql, qr/SELECT \* FROM qtest/i, '_build_sql(): SELECT * from correct table');
		is(scalar @{$args}, 0, '_build_sql(): no WHERE → no bind args');
		is($tbl, 'qtest', '_build_sql(): returns correct table name');
	}

	# SELECT * with WHERE clause
	{
		my $q_where = $db->query()->where(status => 'active');
		my ($sql, $args) = $q_where->_build_sql(0);
		like($sql, qr/WHERE/i, '_build_sql(): WHERE clause present when criteria set');
		is(scalar @{$args}, 1, '_build_sql(): one bind arg for equality criterion');
		is($args->[0], 'active', '_build_sql(): bind arg value correct');
	}

	# COUNT(*) mode (count_only = 1)
	{
		my $q_cnt = $db->query()->where(status => 'active');
		my ($sql) = $q_cnt->_build_sql(1);
		like($sql, qr/SELECT COUNT\(\*\)/i, '_build_sql(): count_only=1 → SELECT COUNT(*)');
		unlike($sql, qr/ORDER BY/i, '_build_sql(): count_only=1 → no ORDER BY');
	}

	# ORDER BY and LIMIT in non-count mode
	{
		my $q_paged = $db->query()->order_by('name ASC')->limit(3)->offset(1);
		my ($sql) = $q_paged->_build_sql(0);
		like($sql, qr/ORDER BY name ASC/i, '_build_sql(): ORDER BY clause included');
		like($sql, qr/LIMIT 3/,            '_build_sql(): LIMIT clause included');
		like($sql, qr/OFFSET 1/,           '_build_sql(): OFFSET clause included');
	}

	# ---- B10: BerkeleyDB delegation in terminal methods --------------
	note '--- B10: Query BerkeleyDB delegation';

	# Inject a BerkeleyDB-like state directly — the query builder must
	# delegate to selectall_arrayref / count instead of building SQL.
	{
		my $bdb = Database::qtest->new(dsn => $dsn);
		$bdb->{'berkeley'} = { k1 => 'v1', k2 => 'v2', k3 => 'v3' };

		# all() with no joins must return all injected rows
		my $bdb_all = $bdb->query()->all();
		is(scalar @{$bdb_all}, 3, 'Query BDB all(): returns all 3 rows from berkeley hash');
		returns_is($bdb_all->[0], { type => 'hashref' }, 'Query BDB all(): each row is a hashref');

		# first() must return the first element of the berkeley scan
		my $bdb_first = $bdb->query()->first();
		returns_is($bdb_first, { type => 'hashref' }, 'Query BDB first(): returns a hashref');

		# count() must return the total count without SQL
		my $bdb_count = $bdb->query()->count();
		is($bdb_count, 3, 'Query BDB count(): returns 3');

		# all() with where() filter applied to BerkeleyDB scan
		my $bdb_filtered = $bdb->query()->where(entry => 'k1')->all();
		is(scalar @{$bdb_filtered}, 1, 'Query BDB all(): where() filter applied in-memory');
		is($bdb_filtered->[0]{'value'}, 'v1', 'Query BDB all(): filtered row correct');
	}

	# ---- B11: where() hashref form -----------------------------------
	note '--- B11: where() hashref form';

	# where() must accept a single hashref as well as named pairs
	{
		my $by_hashref  = $db->query()->where({ status => 'active' })->count();
		my $by_namedpair = $db->query()->where(status => 'active')->count();
		is($by_hashref, $by_namedpair,
			'where(): hashref form yields same count as named-pair form');
	}

	# Multiple where() calls merge with AND semantics
	{
		my $n_combined = $db->query()
			->where(status => 'active')
			->where(score  => { '>=' => 8 })
			->count();
		ok($n_combined > 0 && $n_combined < 5,
			'where(): multiple calls merge with AND, narrowing result set');
	}

	# ---- B12: join() arrayref form -----------------------------------
	note '--- B12: join() arrayref form';

	{
		my $q_j = $db->query();
		# Single hashref form: one spec pushed
		$q_j->join({ table => 't1', on => 'a.id=t1.id' });
		is(scalar @{$q_j->{'_joins'}}, 1, 'join(): single hashref pushes one spec');

		# Arrayref form: multiple specs pushed in one call
		$q_j->join([
			{ table => 't2', on => 'a.id=t2.id' },
			{ table => 't3', on => 'a.id=t3.id', type => 'LEFT' },
		]);
		is(scalar @{$q_j->{'_joins'}}, 3, 'join(): arrayref form pushes two more specs');
		is($q_j->{'_joins'}[1]{'table'}, 't2', 'join(): arrayref first spec table correct');
		is($q_j->{'_joins'}[2]{'type'},  'LEFT', 'join(): arrayref second spec type correct');
	}
}

# ---------------------------------------------------------------------------
# PART A — new sections (A22 onward) for functions not yet covered above
# ---------------------------------------------------------------------------

note '';
note '=== Part A (continued) ===';

# ---- A22: import() ----------------------------------------------------------
note '--- A22: import()';
{
	my %saved = %Database::Abstraction::defaults;

	# Even-count args: calls init() via hashref derived from paired args.
	# We cannot easily assert what init() does because Object::Configure may
	# read config files; just verify it doesn't croak.
	lives_ok {
		Database::Abstraction::import('Database::test1', cache_duration => '2 hours');
	} 'import(): even-count key=value args do not croak';

	# Hashref arg: the single-hashref branch forwards to init()
	lives_ok {
		Database::Abstraction::import('Database::test1', { cache_duration => '3 hours' });
	} 'import(): single hashref arg does not croak';

	# No args: even-count (0) branch, effectively a no-op
	lives_ok {
		Database::Abstraction::import('Database::test1');
	} 'import(): no-arg call does not croak';

	%Database::Abstraction::defaults = %saved;
}

# ---- A23: _is_deep_db() comprehensive positive tests -----------------------
note '--- A23: _is_deep_db() comprehensive';
{
	my $db = Database::test1->new($DATA_DIR);

	# Non-existent file → 0 without raising an exception
	ok(!$db->_is_deep_db('/no/such/deep.db'),
		'_is_deep_db(): non-existent file → 0 (silent)');

	# Text file → 0
	{
		my $txt = File::Temp->new(SUFFIX => '.db');
		print {$txt} "not a deep db\n";
		$txt->flush();
		ok(!$db->_is_deep_db($txt->filename()),
			'_is_deep_db(): text content → 0');
	}

	# 3 bytes (too short to hold a 4-byte magic) → 0
	{
		my $tiny = File::Temp->new(SUFFIX => '.db');
		print {$tiny} 'XYZ';
		$tiny->flush();
		ok(!$db->_is_deep_db($tiny->filename()),
			'_is_deep_db(): 3-byte file (too short) → 0');
	}

	# 4 non-magic bytes → 0
	{
		my $nonmagic = File::Temp->new(SUFFIX => '.db');
		print {$nonmagic} 'ABCD';
		$nonmagic->flush();
		ok(!$db->_is_deep_db($nonmagic->filename()),
			'_is_deep_db(): 4 non-magic bytes → 0');
	}

	# DPDB — standard DBM::Deep file header → 1
	{
		my $f = File::Temp->new(SUFFIX => '.db');
		binmode $f;
		print {$f} 'DPDBextraignored';
		$f->flush();
		ok($db->_is_deep_db($f->filename()),
			'_is_deep_db(): DPDB magic → 1');
	}

	# DPDP — alternative DBM::Deep file header → 1
	{
		my $f = File::Temp->new(SUFFIX => '.db');
		binmode $f;
		print {$f} 'DPDPextraignored';
		$f->flush();
		ok($db->_is_deep_db($f->filename()),
			'_is_deep_db(): DPDP magic → 1');
	}
}

# ---- A24: _is_local_host() white-box tests ---------------------------------
note '--- A24: _is_local_host()';
{
	my $db = Database::test1->new($DATA_DIR);

	# Documented loopback literals always return true regardless of hostname
	ok($db->_is_local_host('localhost'),   '_is_local_host(): localhost → true');
	ok($db->_is_local_host('127.0.0.1'),   '_is_local_host(): 127.0.0.1 → true');
	ok($db->_is_local_host('::1'),         '_is_local_host(): ::1 (IPv6 loopback) → true');

	# user@host forms strip the prefix before comparison
	ok($db->_is_local_host('user@localhost'),   '_is_local_host(): user@localhost → true');
	ok($db->_is_local_host('njh@127.0.0.1'),    '_is_local_host(): user@127.0.0.1 → true');

	# Unambiguously remote names must return false
	ok(!$db->_is_local_host('remoteserver'),   '_is_local_host(): remote name → false');
	ok(!$db->_is_local_host('db.example.com'), '_is_local_host(): remote FQDN → false');
	ok(!$db->_is_local_host('192.168.1.1'),    '_is_local_host(): non-loopback IP → false');
}

# ---- A25: _scan_berkeley() comprehensive ------------------------------------
note '--- A25: _scan_berkeley()';
{
	# join parameter must croak before scanning begins
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = { x => 'y' };
		throws_ok {
			$bdb->_scan_berkeley({ join => { table => 't', on => 'x=y' } })
		} qr/BerkeleyDB does not support JOINs/i,
		'_scan_berkeley(): join param causes croak';
	}

	# -or must croak (BerkeleyDB cannot handle logical groupings)
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = { x => 'y' };
		throws_ok {
			$bdb->_scan_berkeley({ '-or' => [{ entry => 'x' }] })
		} qr/BerkeleyDB does not support -or\/-and/i,
		'_scan_berkeley(): -or param causes croak';
	}

	# -and must also croak
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = { x => 'y' };
		throws_ok {
			$bdb->_scan_berkeley({ '-and' => [{ entry => 'x' }] })
		} qr/BerkeleyDB does not support -or\/-and/i,
		'_scan_berkeley(): -and param causes croak';
	}

	# No criteria → all rows; each row has entry+value keys
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = { alice => 'Alice', bob => 'Bob', carol => 'Carol' };
		my $all = $bdb->_scan_berkeley({});
		is(scalar @{$all}, 3, '_scan_berkeley(): no criteria → 3 rows');
		returns_is($all, { type => 'arrayref', min => 3, max => 3 }, '_scan_berkeley(): returns 3-row arrayref');
		ok(exists $all->[0]{'entry'}, '_scan_berkeley(): each row has entry key');
		ok(exists $all->[0]{'value'}, '_scan_berkeley(): each row has value key');
	}

	# entry criterion selects exactly one row
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = { alice => 'Alice', bob => 'Bob' };
		my $filtered = $bdb->_scan_berkeley({ entry => 'alice' });
		is(scalar @{$filtered}, 1,       '_scan_berkeley(): entry criterion → 1 row');
		is($filtered->[0]{'value'}, 'Alice', '_scan_berkeley(): correct value returned');
	}

	# value criterion works on the non-key column
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = { alice => 'Alice', bob => 'Bob' };
		my $by_val = $bdb->_scan_berkeley({ value => 'Bob' });
		is(scalar @{$by_val}, 1,     '_scan_berkeley(): value criterion → 1 row');
		is($by_val->[0]{'entry'}, 'bob', '_scan_berkeley(): correct entry returned');
	}

	# Empty berkeley hash → empty arrayref (not undef)
	{
		my $bdb = Database::test1->new($DATA_DIR);
		$bdb->{'berkeley'} = {};
		my $empty = $bdb->_scan_berkeley({});
		is(scalar @{$empty}, 0, '_scan_berkeley(): empty hash → empty arrayref');
	}
}

# ---- A26: _like_match() DP matcher ------------------------------------------
note '--- A26: _like_match()';
{
	# _like_match() is a package-level function with no $self argument

	# Exact-match semantics
	ok(Database::Abstraction::_like_match('alice', 'alice'),
		'_like_match(): exact match → 1');
	ok(!Database::Abstraction::_like_match('alice', 'bob'),
		'_like_match(): exact non-match → 0');

	# % wildcard at end: prefix match
	ok(Database::Abstraction::_like_match('alice', 'al%'),
		'_like_match(): % end, prefix matches → 1');
	ok(!Database::Abstraction::_like_match('bob', 'al%'),
		'_like_match(): % end, prefix does not match → 0');

	# % wildcard at start: suffix match
	ok(Database::Abstraction::_like_match('alice', '%ce'),
		'_like_match(): % start, suffix matches → 1');
	ok(!Database::Abstraction::_like_match('alice', '%zz'),
		'_like_match(): % start, suffix does not match → 0');

	# % wildcard in middle
	ok(Database::Abstraction::_like_match('alice', 'al%ce'),
		'_like_match(): % middle, both parts match → 1');
	ok(!Database::Abstraction::_like_match('alice', 'al%zz'),
		'_like_match(): % middle, trailing part does not match → 0');

	# % matches empty sequence
	ok(Database::Abstraction::_like_match('',  '%'),
		'_like_match(): empty string matches bare % → 1');
	ok(Database::Abstraction::_like_match('x', '%'),
		'_like_match(): any string matches bare % → 1');
	ok(!Database::Abstraction::_like_match('', 'a%'),
		'_like_match(): empty string does not match non-empty prefix → 0');

	# _ single-character wildcard
	ok(Database::Abstraction::_like_match('alice', 'a_ice'),
		'_like_match(): _ matches one char → 1');
	ok(!Database::Abstraction::_like_match('ace', 'a_ice'),
		'_like_match(): _ requires exactly one char, not zero → 0');

	# Multiple % wildcards (exercises the row-vs-column DP traversal)
	ok(Database::Abstraction::_like_match('abcabc', '%a%b%'),
		'_like_match(): multiple % wildcards → 1');
	ok(!Database::Abstraction::_like_match('xyz', '%a%b%'),
		'_like_match(): multiple % wildcards, no match → 0');

	# Case insensitivity: SQL LIKE is case-insensitive
	ok(Database::Abstraction::_like_match('ALICE', 'al%'),
		'_like_match(): case-insensitive: ALICE matches al% → 1');
	ok(Database::Abstraction::_like_match('Alice', 'ALICE'),
		'_like_match(): case-insensitive: Alice matches ALICE → 1');

	# ReDoS guard: a pattern that would catastrophically backtrack with a
	# naive regex (%a%a%a%b on a long 'aaa...a' string) must complete promptly
	# because the DP algorithm is O(m*n), not exponential.
	my $long_a = 'a' x 20;
	ok(!Database::Abstraction::_like_match($long_a, '%a%a%a%a%a%b'),
		'_like_match(): ReDoS-inducing pattern completes quickly and returns correct 0');
}

# ---- A27: _has_bdb_magic() positive tests -----------------------------------
note '--- A27: _has_bdb_magic() positive cases';
{
	my $db = Database::test1->new($DATA_DIR);

	# BDB Btree big-endian magic: pack('N', 0x00061561) = "\x00\x06\x15\x61"
	{
		my $f = File::Temp->new(); binmode $f;
		print {$f} "\x00\x06\x15\x61EXTRA"; $f->flush();
		open my $fh, '<', $f->filename(); binmode $fh;
		ok($db->_has_bdb_magic($fh), '_has_bdb_magic(): BDB Btree big-endian magic → 1');
		close $fh;
	}

	# BDB Hash big-endian magic: pack('N', 0x00053162) = "\x00\x05\x31\x62"
	{
		my $f = File::Temp->new(); binmode $f;
		print {$f} "\x00\x05\x31\x62EXTRA"; $f->flush();
		open my $fh, '<', $f->filename(); binmode $fh;
		ok($db->_has_bdb_magic($fh), '_has_bdb_magic(): BDB Hash big-endian magic → 1');
		close $fh;
	}

	# BDB Btree little-endian magic: pack('V', 0x00061561) = "\x61\x15\x06\x00"
	{
		my $f = File::Temp->new(); binmode $f;
		print {$f} "\x61\x15\x06\x00EXTRA"; $f->flush();
		open my $fh, '<', $f->filename(); binmode $fh;
		ok($db->_has_bdb_magic($fh), '_has_bdb_magic(): BDB Btree little-endian magic → 1');
		close $fh;
	}

	# Btree fallback at offset 12: 4 non-magic bytes + 8 filler + "\x61\x15\x00\x00"
	# unpack('H*', "\x61\x15\x00\x00") = '61150000'; substr(…, 0, 4) = '6115' → match
	{
		my $f = File::Temp->new(); binmode $f;
		print {$f} 'xxxx';               # offset 0: non-magic
		print {$f} 'y' x 8;              # offset 4-11: filler
		print {$f} "\x61\x15\x00\x00";  # offset 12: Btree '6115' prefix
		$f->flush();
		open my $fh, '<', $f->filename(); binmode $fh;
		ok($db->_has_bdb_magic($fh), '_has_bdb_magic(): Btree fallback at offset 12 → 1');
		close $fh;
	}
}

# ---- A28: new() injection guards -------------------------------------------
note '--- A28: new() injection guards';
{
	# Semicolons and SQL keywords make the id column name dangerous
	throws_ok {
		Database::test1->new(directory => $DATA_DIR, id => 'bad;id')
	} qr/unsafe id column name/i,
	'new(): id with semicolon → croak before object returned';

	# SQL injection attempt in the clone path (fixed in 0.37)
	{
		my $original = Database::test1->new($DATA_DIR);
		throws_ok { $original->new(id => "x); DROP TABLE t--") }
			qr/unsafe id column name/i,
			'new(): clone path: SQL in id → croak';
	}

	# host validation: spaces and shell metacharacters must be rejected
	throws_ok {
		Database::test1->new(directory => $DATA_DIR, host => 'bad host; rm -rf /')
	} qr/unsafe host/i,
	'new(): host with shell metacharacters → croak at construction time';

	# A safe underscore-containing id must pass
	lives_ok {
		Database::test1->new(directory => $DATA_DIR, id => 'my_entry_col')
	} 'new(): underscored id does not croak';

	# table parameter: SQL injection in worksheet/table name must be rejected at
	# construction time, before any file I/O or DBI connect attempt.
	throws_ok {
		Database::test1->new(directory => $DATA_DIR, table => "scores; DROP TABLE t--")
	} qr/unsafe table name/i,
	'new(): table with SQL injection → croak at construction time';

	# A dotted qualified name (e.g. schema.table for DSN backends) must pass
	lives_ok {
		Database::test1->new(directory => $DATA_DIR, table => 'schema.my_table')
	} 'new(): dot-qualified table name does not croak';

	# A plain valid table name must pass without error
	lives_ok {
		Database::test1->new(directory => $DATA_DIR, table => 'sheet1')
	} 'new(): plain table name does not croak';
}

# ---- A29: columns() and schema() — SQLite DBI path -------------------------
note '--- A29: columns() and schema() — SQLite path';
SKIP: {
	skip 'DBD::SQLite not available for schema tests', 10 unless $have_sqlite;

	my $sch_dir  = tempdir(CLEANUP => 1);
	my $sch_file = File::Spec->catfile($sch_dir, 'colschema.sql');
	my $sch_dsn  = "dbi:SQLite:dbname=$sch_file";

	do {
		my $s = DBI->connect($sch_dsn, undef, undef, { RaiseError => 1 });
		$s->do('CREATE TABLE colschema (entry TEXT PRIMARY KEY NOT NULL, name TEXT, score INTEGER DEFAULT 0)');
		$s->do("INSERT INTO colschema VALUES ('a','Alpha',10)");
		$s->disconnect();
	};

	{
		package Database::colschema;
		use parent 'Database::Abstraction';
	}

	my $db = Database::colschema->new(dsn => $sch_dsn);

	# columns() — SQLite uses SELECT * WHERE 1=0 then $sth->{NAME}
	my $cols = $db->columns();
	returns_is($cols, { type => 'arrayref' }, 'columns() SQLite: returns arrayref');
	is(scalar @{$cols}, 3,  'columns() SQLite: exactly 3 columns');
	ok((grep { $_ eq 'entry' } @{$cols}), 'columns() SQLite: entry present');
	ok((grep { $_ eq 'name'  } @{$cols}), 'columns() SQLite: name present');
	ok((grep { $_ eq 'score' } @{$cols}), 'columns() SQLite: score present');

	# schema() — SQLite uses PRAGMA table_info
	my $schema = $db->schema();
	returns_is($schema, { type => 'hashref' }, 'schema() SQLite: returns hashref');
	ok(exists $schema->{'entry'}, 'schema() SQLite: entry key present');
	is($schema->{'entry'}{'pk'}, 1, 'schema() SQLite: entry is primary key');
	# PRAGMA table_info sets notnull=1 for NOT NULL; nullable = !notnull, which
	# is a Perl boolean false ('' or 0 depending on Perl version) — assert falsy
	ok(!$schema->{'entry'}{'nullable'}, 'schema() SQLite: NOT NULL column → nullable is false');
	ok(exists $schema->{'score'}{'default'}, 'schema() SQLite: score has default sub-key');
}

# ---- A30: DESTROY() — cleanup verification ----------------------------------
note '--- A30: DESTROY()';
{
	my $db = Database::test1->new($DATA_DIR);

	# Inject sentinel refs so we can check they are removed by DESTROY
	$db->{'_temp_fh'}      = \(my $dummy1);
	$db->{'_remote_tmpdir'} = \(my $dummy2);

	lives_ok { $db->DESTROY() } 'DESTROY(): does not croak on normal object';

	# After DESTROY all keys are cleared (the general cleanup loop runs)
	ok(!exists($db->{'_temp_fh'}),       'DESTROY(): _temp_fh key removed');
	ok(!exists($db->{'_remote_tmpdir'}), 'DESTROY(): _remote_tmpdir key removed');
}

# ---- A31: selectall_hashref() and selectall_hash() aliases -----------------
note '--- A31: selectall_hashref / selectall_hash aliases';
{
	my $db = Database::test1->new($DATA_DIR);

	# selectall_hashref is a documented backward-compat alias for selectall_arrayref
	my $ref1 = $db->selectall_hashref();
	my $ref2 = $db->selectall_arrayref();
	is(scalar @{$ref1}, scalar @{$ref2},
		'selectall_hashref(): returns same count as selectall_arrayref()');
	returns_is($ref1, { type => 'arrayref' }, 'selectall_hashref(): returns arrayref');

	# selectall_hash is a documented backward-compat alias for selectall_array
	my @arr1 = $db->selectall_hash();
	my @arr2 = $db->selectall_array();
	is(scalar @arr1, scalar @arr2,
		'selectall_hash(): returns same count as selectall_array()');
}

# ---- A32: XLSX / Spreadsheet::ParseXLSX backend ----------------------------
# Verify the _open() xlsx branch: lazy ParseXLSX require, type='XLSX',
# in-memory data populated, count/fetch/selectall work via slurp path,
# and the table-override constructor param queries a different worksheet while
# the filename stem still comes from the class name (not the table override).
note '--- A32: XLSX / Spreadsheet::ParseXLSX backend';
SKIP: {
	my $have_xlsx = eval { require Excel::Writer::XLSX; require Spreadsheet::ParseXLSX; 1 };
	skip 'Excel::Writer::XLSX or Spreadsheet::ParseXLSX not available', 18
		unless $have_xlsx;

	my $xdir = tempdir(CLEANUP => 1);
	my $xlsx = File::Spec->catfile($xdir, 'test1.xlsx');

	# Build a two-worksheet fixture using OOXML format (Excel::Writer::XLSX).
	# worksheet 'test1' — matches the class-derived table name for Database::test1
	# worksheet 'alt'   — used to verify the table-override path
	{
		my $wb = Excel::Writer::XLSX->new($xlsx);

		my $ws1 = $wb->add_worksheet('test1');
		$ws1->write(0, 0, 'entry'); $ws1->write(0, 1, 'score');
		$ws1->write(1, 0, 'a');     $ws1->write(1, 1, 10);
		$ws1->write(2, 0, 'b');     $ws1->write(2, 1, 20);
		$ws1->write(3, 0, 'c');     $ws1->write(3, 1, 30);

		my $ws2 = $wb->add_worksheet('alt');
		$ws2->write(0, 0, 'entry'); $ws2->write(0, 1, 'val');
		$ws2->write(1, 0, 'x');     $ws2->write(1, 1, 99);

		$wb->close();
	}

	ok(-r $xlsx, 'A32 pre-cond: test1.xlsx fixture created');

	# --- 32a: basic connection via class-derived table name --------------------
	# The first query triggers _open(); type must be 'XLSX' afterwards.
	my $db = Database::test1->new($xdir);
	my $n = $db->count();
	is($n, 3, 'XLSX _open(): count() returns 3 rows from test1 worksheet');
	is($db->{'type'}, 'XLSX', 'XLSX _open(): type is set to XLSX after first query');

	# XLSX path slurps into memory — data hash must be populated, no DBI handle
	ok(defined($db->{'data'}), 'XLSX _open(): data loaded into memory (slurp path)');

	# Spreadsheet::ParseXLSX must now be in %INC (lazy-loaded by _open())
	ok(exists $INC{'Spreadsheet/ParseXLSX.pm'}, 'XLSX _open(): ParseXLSX lazy-loaded into %INC');

	# --- 32b: fetchrow_hashref ---------------------------------------------------
	my $row = $db->fetchrow_hashref(entry => 'a');
	returns_is($row, { type => 'hashref' }, 'XLSX fetchrow_hashref(): returns hashref');
	is($row->{'score'}, 10, 'XLSX fetchrow_hashref(): correct column value returned');

	# Miss → undef
	my $miss = $db->fetchrow_hashref(entry => '__none__');
	returns_is($miss, { type => 'void' }, 'XLSX fetchrow_hashref(): miss returns undef');

	# --- 32c: selectall_arrayref ------------------------------------------------
	my $all = $db->selectall_arrayref();
	returns_is($all, { type => 'arrayref' }, 'XLSX selectall_arrayref(): returns arrayref');
	is(scalar @{$all}, 3, 'XLSX selectall_arrayref(): all 3 rows returned');

	# --- 32d: constructor table override — multi-worksheet access ---------------
	# Database::test1 has class name 'test1', so dbname must fall back to 'test1'
	# even when table => 'alt' is given, opening test1.xlsx and querying 'alt'.
	# If dbname had incorrectly been derived from the table override, _open()
	# would look for 'alt.xlsx' (which does not exist) and croak.
	my $alt_db = Database::test1->new(directory => $xdir, table => 'alt');
	my $n_alt = $alt_db->count();
	is($n_alt, 1, 'XLSX table override: alt worksheet has 1 row');
	is($alt_db->{'type'}, 'XLSX',
		'XLSX table override: type is XLSX (test1.xlsx opened, not alt.xlsx)');

	# Verify the cached table name is 'alt', not 'test1'
	is($alt_db->{'_table_name'}, 'alt',
		'XLSX table override: _table_name cached as alt');

	# XLSX slurp path: data hash populated (no DBI handle under 'alt')
	ok(defined($alt_db->{'data'}), 'XLSX table override: data populated from alt worksheet');

	# Fetch from the alt worksheet using the overridden table
	my $alt_row = $alt_db->fetchrow_hashref(entry => 'x');
	returns_is($alt_row, { type => 'hashref' }, 'XLSX table override: fetchrow_hashref returns hashref');
	is($alt_row->{'val'}, 99, 'XLSX table override: correct column value from alt worksheet');

	# --- 32e: memory cycle check ------------------------------------------------
	memory_cycle_ok($db, 'XLSX: no memory cycles in connected object');
}

# ---- A33: updated() — SQLite DSN live-stat path ----------------------------
# The new code (0.46) stats the backing file on every call when the dialect
# is 'sqlite' and the dsn matches dbi:SQLite:dbname=...  Non-SQLite backends
# and slurp-mode objects fall back to the cached _updated timestamp.
note '--- A33: updated() — SQLite DSN live-stat path';
SKIP: {
	skip 'DBD::SQLite not available for updated() live-stat tests', 8
		unless $have_sqlite;

	my $udir  = tempdir(CLEANUP => 1);
	my $ufile = File::Spec->catfile($udir, 'updtest.sql');
	my $udsn  = "dbi:SQLite:dbname=$ufile";

	my $setup = DBI->connect($udsn, undef, undef, { RaiseError => 1 });
	$setup->do('CREATE TABLE updtest (id INTEGER PRIMARY KEY, v TEXT)');
	$setup->do("INSERT INTO updtest VALUES (1, 'hello')");
	$setup->disconnect();

	{
		package Database::updtest;
		use parent 'Database::Abstraction';
	}

	my $db = Database::updtest->new(dsn => $udsn, no_entry => 1);

	# Trigger _open so dialect='sqlite' and dsn are stored in the object
	$db->count();

	# The file must exist on disk by this point
	ok(-f $ufile, 'A33 pre-cond: SQLite backing file exists');

	# updated() must return a defined numeric value (the file mtime)
	my $t1 = $db->updated();
	ok(defined($t1), 'updated() SQLite DSN: returns defined value');
	ok(looks_like_number($t1), 'updated() SQLite DSN: value is numeric (mtime)');

	# updated() must agree with stat() on the same file
	my $stat_mtime = (stat($ufile))[9];
	is($db->updated(), $stat_mtime, 'updated() SQLite DSN: equals live stat() mtime');

	# Advance mtime by at least one second, then verify updated() reflects it.
	# utime(undef, undef, $file) sets atime+mtime to now; sleep ensures the
	# 1-second granularity of filesystem mtimes gives us a different value.
	sleep(1);
	utime(undef, undef, $ufile);
	my $t2 = (stat($ufile))[9];
	is($db->updated(), $t2, 'updated() SQLite DSN: reflects new mtime after utime()');
	ok($t2 >= $t1, 'updated() SQLite DSN: new mtime >= old mtime');

	# Slurp-mode object (directory path, not DSN) must NOT go through the live-stat
	# branch — it falls back to $self->{'_updated'} set at _open() time.
	my $slurp_db = Database::test1->new($DATA_DIR);
	$slurp_db->count();	# trigger _open; _updated set to stat() mtime at load
	my $slurp_u = $slurp_db->updated();
	ok(defined($slurp_u), 'updated() slurp path: returns defined value');
	ok(looks_like_number($slurp_u), 'updated() slurp path: value is numeric timestamp');
}

# ---- A34: _parse_sort_by() --------------------------------------------------
# Package-level helper; call directly as a non-method sub.
note '--- A34: _parse_sort_by()';
{
	# undef → (undef, 'ASC') with no warning
	{
		my ($col, $dir) = Database::Abstraction::_parse_sort_by(undef, 'test');
		ok(!defined($col), '_parse_sort_by(): undef → col is undef');
		is($dir, 'ASC',    '_parse_sort_by(): undef → dir defaults to ASC');
	}

	# Plain scalar column name → (col, 'ASC')
	{
		my ($col, $dir) = Database::Abstraction::_parse_sort_by('score', 'test');
		is($col, 'score', '_parse_sort_by(): scalar → col returned');
		is($dir, 'ASC',   '_parse_sort_by(): scalar → direction defaults to ASC');
	}

	# Arrayref [col, 'DESC'] form
	{
		my ($col, $dir) = Database::Abstraction::_parse_sort_by(['name', 'DESC'], 'test');
		is($col, 'name', '_parse_sort_by(): arrayref → col returned');
		is($dir, 'DESC', '_parse_sort_by(): arrayref → direction DESC');
	}

	# Direction normalised to uppercase: 'asc' → 'ASC'
	{
		my ($col, $dir) = Database::Abstraction::_parse_sort_by(['name', 'asc'], 'test');
		is($dir, 'ASC', '_parse_sort_by(): lowercase direction normalised to ASC');
	}

	# Unsafe column name → (undef, 'ASC') with a carp (not a croak)
	{
		my ($col, $dir);
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		($col, $dir) = Database::Abstraction::_parse_sort_by('bad; DROP', 'test');
		ok(!defined($col), '_parse_sort_by(): unsafe col → col is undef');
		is($dir, 'ASC',    '_parse_sort_by(): unsafe col → dir defaults to ASC');
		ok(scalar @warnings, '_parse_sort_by(): unsafe col emits a carp warning');
	}

	# Invalid direction → (undef, 'ASC') with a carp
	{
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		my ($col, $dir) = Database::Abstraction::_parse_sort_by(['name', 'SIDEWAYS'], 'test');
		ok(!defined($col), '_parse_sort_by(): invalid direction → col is undef');
		is($dir, 'ASC',    '_parse_sort_by(): invalid direction → falls back to ASC');
		ok(scalar @warnings, '_parse_sort_by(): invalid direction emits a carp warning');
	}

	# Dotted qualified name passes $SAFE_QUALIFIED (e.g. schema.column)
	{
		my ($col, $dir) = Database::Abstraction::_parse_sort_by('t.score', 'test');
		is($col, 't.score', '_parse_sort_by(): qualified name accepted');
		is($dir, 'ASC',     '_parse_sort_by(): qualified name → direction ASC');
	}
}

# ---- A35: _merge_base_criteria() -------------------------------------------
# Private method; call directly for white-box coverage.
note '--- A35: _merge_base_criteria()';
{
	my $db = Database::test1->new($DATA_DIR);

	# No base_criteria set: params returned unchanged (same ref, no allocation)
	{
		my $p = { entry => 'x' };
		my $merged = $db->_merge_base_criteria($p);
		is($merged, $p, '_merge_base_criteria(): no base_criteria → original ref returned');
	}

	# With base_criteria: returns a NEW hashref combining both
	{
		$db->{'base_criteria'} = { status => 'active' };
		my $p = { entry => 'x' };
		my $merged = $db->_merge_base_criteria($p);
		isnt($merged, $p, '_merge_base_criteria(): with base_criteria → new hashref returned');
		is($merged->{'status'}, 'active', '_merge_base_criteria(): base_criteria key present in result');
		is($merged->{'entry'},  'x',      '_merge_base_criteria(): caller key present in result');
	}

	# Caller keys WIN on collision — callers can always narrow further
	{
		$db->{'base_criteria'} = { status => 'active', tier => 'gold' };
		my $p = { status => 'inactive' };	# caller overrides base
		my $merged = $db->_merge_base_criteria($p);
		is($merged->{'status'}, 'inactive',
			'_merge_base_criteria(): caller key wins on collision (expected from: '
			. 'CLAUDE.md "caller keys WIN on collision")');
		is($merged->{'tier'}, 'gold',
			'_merge_base_criteria(): non-colliding base_criteria key preserved');
	}

	# Clean up so we don't affect later tests
	delete $db->{'base_criteria'};
}

# ---- A36: dbi_source() ------------------------------------------------------
# Returns {dbh, table} for live SQLite connections; undef for all other backends.
note '--- A36: dbi_source()';
{
	# Slurp-mode object has no DBI handle → must return undef
	my $slurp = Database::test1->new($DATA_DIR);
	$slurp->count();	# trigger _open (slurp path)
	my $src = $slurp->dbi_source();
	returns_is($src, { type => 'void' }, 'dbi_source(): slurp backend → undef');
}

SKIP: {
	skip 'DBD::SQLite not available for dbi_source() tests', 5
		unless $have_sqlite;

	my $sdir = tempdir(CLEANUP => 1);
	my $sfile = File::Spec->catfile($sdir, 'dsrc.sql');
	my $sdsn  = "dbi:SQLite:dbname=$sfile";

	my $setup = DBI->connect($sdsn, undef, undef, { RaiseError => 1 });
	$setup->do('CREATE TABLE dsrc (id INTEGER PRIMARY KEY, v TEXT)');
	$setup->do("INSERT INTO dsrc VALUES (1, 'a')");
	$setup->disconnect();

	{
		package Database::dsrc;
		use parent 'Database::Abstraction';
	}

	my $db = Database::dsrc->new(dsn => $sdsn, no_entry => 1);
	$db->count();	# trigger _open

	# SQLite connection must return a valid source descriptor
	my $src = $db->dbi_source();
	returns_is($src, { type => 'hashref' }, 'dbi_source() SQLite: returns hashref');
	ok(exists $src->{'dbh'},   'dbi_source() SQLite: dbh key present');
	ok(exists $src->{'table'}, 'dbi_source() SQLite: table key present');
	is($src->{'table'}, 'dsrc', 'dbi_source() SQLite: table name is correct');

	# The dbh in the result must be a DBI handle (blessed object)
	ok(Scalar::Util::blessed($src->{'dbh'}), 'dbi_source() SQLite: dbh is a blessed DBI handle');
}

# ---- A37: _infer_type() -----------------------------------------------------
# Package-level function; call directly.  Tests all five return values.
note '--- A37: _infer_type()';
{
	# Empty/all-null input → TEXT (unknown type)
	is(Database::Abstraction::_infer_type([]),
		'TEXT', '_infer_type(): empty list → TEXT');
	is(Database::Abstraction::_infer_type([undef, '']),
		'TEXT', '_infer_type(): all null/empty → TEXT');

	# All values are integers (positive, negative, zero)
	is(Database::Abstraction::_infer_type([1, 2, -3, 0]),
		'INTEGER', '_infer_type(): integer values → INTEGER');

	# All values are real / floating-point numbers
	is(Database::Abstraction::_infer_type(['1.5', '-2.0', '3e10']),
		'REAL', '_infer_type(): real values → REAL');

	# Single non-integer in an otherwise integer set → REAL (not INTEGER)
	is(Database::Abstraction::_infer_type([1, 2, '3.5']),
		'REAL', '_infer_type(): one real value prevents INTEGER classification');

	# ISO 8601 timestamps (YYYY-MM-DDTHH:MM prefix sufficient)
	is(Database::Abstraction::_infer_type(['2024-01-15T12:30', '2024-06-01 09:00:00']),
		'TIMESTAMP', '_infer_type(): timestamp values → TIMESTAMP');

	# ISO dates (YYYY-MM-DD exact)
	is(Database::Abstraction::_infer_type(['2024-01-15', '2024-06-01']),
		'DATE', '_infer_type(): ISO date values → DATE');

	# Mixed text and numbers → TEXT (cannot be classified as a numeric type)
	is(Database::Abstraction::_infer_type(['hello', 'world', '1']),
		'TEXT', '_infer_type(): mixed text/number → TEXT');

	# Undef values are ignored; remaining values determine type
	is(Database::Abstraction::_infer_type([undef, '42', undef]),
		'INTEGER', '_infer_type(): undef values ignored, numeric wins → INTEGER');
}

# ---------------------------------------------------------------------------
# PART A (continued) — aggregate helpers added in 0.49
# ---------------------------------------------------------------------------

note '';
note '=== Aggregate helpers (0.49) ===';

# Magic strings used across the aggregate sections
Readonly my $ACTIVE   => 'active';
Readonly my $INACTIVE => 'inactive';
Readonly my $AGG_DB   => Database::test1->new($DATA_DIR);

# ---- A38: _validate_aggregate_spec() --------------------------------------
# Pure validation helper; no database access.  Test every croak guard and
# every valid branch; verify the returned \%spec structure precisely.
note '--- A38: _validate_aggregate_spec()';
{
	my $db = Database::test1->new($DATA_DIR);

	# Minimal valid spec: one measure, no by → grand total
	{
		my $p = { measures => [{ col => 'score', fn => 'sum', as => 'total' }] };
		my $spec;
		lives_ok { $spec = $db->_validate_aggregate_spec($p) }
			'_validate_aggregate_spec(): minimal valid spec does not croak';
		returns_is($spec, { type => 'hashref' }, '_validate_aggregate_spec(): returns hashref');
		is(ref($spec->{'by'}),       'ARRAY',  '_validate_aggregate_spec(): by is ARRAY');
		is(scalar @{$spec->{'by'}},  0,        '_validate_aggregate_spec(): empty by (grand total)');
		is(ref($spec->{'measures'}), 'ARRAY',  '_validate_aggregate_spec(): measures is ARRAY');
		is($spec->{'measures'}[0]{'fn'},  'sum',   '_validate_aggregate_spec(): fn stored');
		is($spec->{'measures'}[0]{'as'},  'total', '_validate_aggregate_spec(): as stored');
		is($spec->{'measures'}[0]{'col'}, 'score', '_validate_aggregate_spec(): col stored');
		is($spec->{'measures'}[0]{'sql'}, 'SUM(score)', '_validate_aggregate_spec(): sql expression correct');
		ok($spec->{'aliases'}{'total'}, '_validate_aggregate_spec(): alias registered');
		is(ref($spec->{'criteria'}), 'HASH', '_validate_aggregate_spec(): criteria is HASH');
	}

	# by with valid column names → stored in by list
	{
		my $p = {
			by       => ['status', 'region'],
			measures => [{ fn => 'count', as => 'n' }],
		};
		my $spec = $db->_validate_aggregate_spec($p);
		is(scalar @{$spec->{'by'}}, 2,        '_validate_aggregate_spec(): two by columns stored');
		is($spec->{'by'}[0]{'name'}, 'status', '_validate_aggregate_spec(): first by name correct');
		is($spec->{'by'}[1]{'name'}, 'region', '_validate_aggregate_spec(): second by name correct');
		ok($spec->{'by_names'}{'status'}, '_validate_aggregate_spec(): by_names hash populated');
	}

	# count without col → COUNT(*)
	{
		my $p = { measures => [{ fn => 'count', as => 'n' }] };
		my $spec = $db->_validate_aggregate_spec($p);
		is($spec->{'measures'}[0]{'sql'}, 'COUNT(*)',
			'_validate_aggregate_spec(): count without col → COUNT(*)');
		ok(!defined($spec->{'measures'}[0]{'col'}),
			'_validate_aggregate_spec(): count without col → col is undef');
	}

	# count with col → COUNT(col)
	{
		my $p = { measures => [{ fn => 'count', col => 'score', as => 'n' }] };
		my $spec = $db->_validate_aggregate_spec($p);
		is($spec->{'measures'}[0]{'sql'}, 'COUNT(score)',
			'_validate_aggregate_spec(): count with col → COUNT(col)');
	}

	# count_distinct → COUNT(DISTINCT col)
	{
		my $p = { measures => [{ fn => 'count_distinct', col => 'status', as => 'ud' }] };
		my $spec = $db->_validate_aggregate_spec($p);
		is($spec->{'measures'}[0]{'sql'}, 'COUNT(DISTINCT status)',
			'_validate_aggregate_spec(): count_distinct → COUNT(DISTINCT col)');
	}

	# All other valid functions emit correct SQL expressions
	for my $fn_case (
		['avg',  'score', 'AVG(score)'],
		['min',  'score', 'MIN(score)'],
		['max',  'score', 'MAX(score)'],
	) {
		my ($fn, $col, $expected_sql) = @{$fn_case};
		my $p = { measures => [{ fn => $fn, col => $col, as => 'v' }] };
		my $spec = $db->_validate_aggregate_spec($p);
		is($spec->{'measures'}[0]{'sql'}, $expected_sql,
			"_validate_aggregate_spec(): fn=$fn → $expected_sql");
	}

	# fn is case-insensitive (uppercased internally)
	{
		my $p = { measures => [{ fn => 'SUM', col => 'score', as => 'v' }] };
		my $spec;
		lives_ok { $spec = $db->_validate_aggregate_spec($p) }
			'_validate_aggregate_spec(): uppercase fn accepted';
		is($spec->{'measures'}[0]{'fn'}, 'sum',
			'_validate_aggregate_spec(): fn lowercased internally');
	}

	# remaining params become criteria (control keys deleted from hashref)
	{
		my $p = {
			measures => [{ fn => 'count', as => 'n' }],
			status   => $ACTIVE,
		};
		my $spec = $db->_validate_aggregate_spec($p);
		is($spec->{'criteria'}{'status'}, $ACTIVE,
			'_validate_aggregate_spec(): non-control key left in criteria');
		ok(!exists($spec->{'criteria'}{'measures'}),
			'_validate_aggregate_spec(): measures key removed from criteria');
	}

	# sort_by scalar → [col, 'ASC'], stored in spec->{'sort'}
	{
		my $p = {
			measures => [{ fn => 'count', as => 'n' }],
			by       => ['status'],
			sort_by  => 'status',
		};
		my $spec = $db->_validate_aggregate_spec($p);
		is(ref($spec->{'sort'}), 'ARRAY', '_validate_aggregate_spec(): sort stored as arrayref');
		is($spec->{'sort'}[0], 'status', '_validate_aggregate_spec(): sort col correct');
		is($spec->{'sort'}[1], 'ASC',    '_validate_aggregate_spec(): sort dir defaults to ASC');
	}

	# sort_by ['col', 'DESC'] form
	{
		my $p = {
			measures => [{ fn => 'sum', col => 'score', as => 'total' }],
			by       => ['status'],
			sort_by  => ['total', 'DESC'],
		};
		my $spec = $db->_validate_aggregate_spec($p);
		is($spec->{'sort'}[0], 'total', '_validate_aggregate_spec(): sort_by array col correct');
		is($spec->{'sort'}[1], 'DESC',  '_validate_aggregate_spec(): sort_by array dir correct');
	}

	# limit/offset stored and cast to int
	{
		my $p = {
			measures => [{ fn => 'count', as => 'n' }],
			limit    => 5,
			offset   => 10,
		};
		my $spec = $db->_validate_aggregate_spec($p);
		is($spec->{'limit'},  5,  '_validate_aggregate_spec(): limit stored');
		is($spec->{'offset'}, 10, '_validate_aggregate_spec(): offset stored');
	}

	# having stored when valid
	{
		my $p = {
			by       => ['status'],
			measures => [{ fn => 'sum', col => 'score', as => 'total' }],
			having   => { total => { '>' => 100 } },
		};
		my $spec = $db->_validate_aggregate_spec($p);
		ok(defined($spec->{'having'}), '_validate_aggregate_spec(): having stored');
		ok(exists($spec->{'having'}{'total'}), '_validate_aggregate_spec(): having key retained');
	}

	# having with group-by column key (not an alias) is valid
	{
		my $p = {
			by       => ['status'],
			measures => [{ fn => 'count', as => 'n' }],
			having   => { status => $ACTIVE },
		};
		lives_ok { $db->_validate_aggregate_spec($p) }
			'_validate_aggregate_spec(): having with group-by column key is valid';
	}

	# having with -or key is exempt from the allowlist check
	{
		my $p = {
			by       => ['status'],
			measures => [{ fn => 'count', as => 'n' }],
			having   => { '-or' => [{ status => $ACTIVE }] },
		};
		lives_ok { $db->_validate_aggregate_spec($p) }
			'_validate_aggregate_spec(): having with -or key is valid';
	}

	# ---- Negative tests ----

	# measures not provided → croak
	throws_ok {
		$db->_validate_aggregate_spec({})
	} qr/'measures' must be a non-empty arrayref/,
	'_validate_aggregate_spec(): missing measures → croak';

	# measures is a scalar → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => 'bad' })
	} qr/'measures' must be a non-empty arrayref/,
	'_validate_aggregate_spec(): scalar measures → croak';

	# measures is empty arrayref → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [] })
	} qr/'measures' must be a non-empty arrayref/,
	'_validate_aggregate_spec(): empty measures → croak';

	# individual measure not a hashref → croak with ref type
	throws_ok {
		$db->_validate_aggregate_spec({ measures => ['bad'] })
	} qr/measure must be a hashref/,
	'_validate_aggregate_spec(): measure as scalar → croak';

	# individual measure is an arrayref → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [[1,2]] })
	} qr/measure must be a hashref/,
	'_validate_aggregate_spec(): measure as arrayref → croak';

	# unknown function name → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [{ fn => 'bogus', col => 'x', as => 'v' }] })
	} qr/unknown measure function 'bogus'/,
	'_validate_aggregate_spec(): unknown fn → croak';

	# col required for sum but missing → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [{ fn => 'sum', as => 'v' }] })
	} qr/measure column is required for function 'sum'/,
	'_validate_aggregate_spec(): sum without col → croak';

	# col required for avg but missing → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [{ fn => 'avg', as => 'v' }] })
	} qr/measure column is required for function 'avg'/,
	'_validate_aggregate_spec(): avg without col → croak';

	# col required for min → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [{ fn => 'min', as => 'v' }] })
	} qr/measure column is required for function 'min'/,
	'_validate_aggregate_spec(): min without col → croak';

	# col required for max → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [{ fn => 'max', as => 'v' }] })
	} qr/measure column is required for function 'max'/,
	'_validate_aggregate_spec(): max without col → croak';

	# col required for count_distinct → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [{ fn => 'count_distinct', as => 'v' }] })
	} qr/measure column is required for function 'count_distinct'/,
	'_validate_aggregate_spec(): count_distinct without col → croak';

	# unsafe col (SQL injection in column name) → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [{ fn => 'sum', col => 'x; DROP TABLE t--', as => 'v' }] })
	} qr/unsafe measure column/,
	'_validate_aggregate_spec(): SQL injection in col → croak';

	# col with null byte → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [{ fn => 'sum', col => "score\x00", as => 'v' }] })
	} qr/unsafe measure column/,
	'_validate_aggregate_spec(): null byte in col → croak';

	# missing as → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [{ fn => 'sum', col => 'score' }] })
	} qr/measure 'as' is required/,
	'_validate_aggregate_spec(): missing as → croak';

	# empty as → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [{ fn => 'sum', col => 'score', as => '' }] })
	} qr/measure 'as' is required/,
	'_validate_aggregate_spec(): empty as → croak';

	# unsafe as (contains semicolon) → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [{ fn => 'sum', col => 'score', as => 'bad;alias' }] })
	} qr/unsafe measure alias/,
	'_validate_aggregate_spec(): SQL injection in as → croak';

	# as with dot (not a valid identifier) → croak (only $SAFE_IDENTIFIER, not $SAFE_QUALIFIED)
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [{ fn => 'sum', col => 'score', as => 'a.b' }] })
	} qr/unsafe measure alias/,
	'_validate_aggregate_spec(): dot in as → croak (SAFE_IDENTIFIER rejects dots)';

	# duplicate as across two measures → croak
	throws_ok {
		$db->_validate_aggregate_spec({ measures => [
			{ fn => 'sum', col => 'score', as => 'v' },
			{ fn => 'avg', col => 'score', as => 'v' },
		]})
	} qr/duplicate measure alias 'v'/,
	'_validate_aggregate_spec(): duplicate as → croak';

	# alias collides with a by column name → croak
	throws_ok {
		$db->_validate_aggregate_spec({
			by       => ['status'],
			measures => [{ fn => 'sum', col => 'score', as => 'status' }],
		})
	} qr/measure alias 'status' collides with a group-by column/,
	'_validate_aggregate_spec(): alias==by column → croak';

	# by is not an arrayref → croak
	throws_ok {
		$db->_validate_aggregate_spec({
			by       => 'status',
			measures => [{ fn => 'count', as => 'n' }],
		})
	} qr/'by' must be an arrayref/,
	'_validate_aggregate_spec(): by is a scalar → croak';

	# unsafe by column (space/semicolon) → croak
	throws_ok {
		$db->_validate_aggregate_spec({
			by       => ['status; DROP TABLE t--'],
			measures => [{ fn => 'count', as => 'n' }],
		})
	} qr/unsafe group-by column/,
	'_validate_aggregate_spec(): SQL injection in by column → croak';

	# having with unknown key (not in by or aliases) → croak
	throws_ok {
		$db->_validate_aggregate_spec({
			by       => ['status'],
			measures => [{ fn => 'sum', col => 'score', as => 'total' }],
			having   => { unknown_col => { '>' => 5 } },
		})
	} qr/having key 'unknown_col' is not a group-by column or measure alias/,
	'_validate_aggregate_spec(): having key not in allowlist → croak';

	# sort_by names a column not in by or aliases → croak
	throws_ok {
		$db->_validate_aggregate_spec({
			by       => ['status'],
			measures => [{ fn => 'count', as => 'n' }],
			sort_by  => 'bogus_col',
		})
	} qr/sort_by names 'bogus_col'/,
	'_validate_aggregate_spec(): sort_by not in by or aliases → croak';

	# limit with non-integer string → carp and ignored (not a croak)
	{
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		my $p = {
			measures => [{ fn => 'count', as => 'n' }],
			limit    => 'bad',
		};
		my $spec;
		lives_ok { $spec = $db->_validate_aggregate_spec($p) }
			'_validate_aggregate_spec(): non-integer limit does not croak';
		ok(!defined($spec->{'limit'}), '_validate_aggregate_spec(): bad limit → undef (ignored)');
		ok(scalar @warnings,           '_validate_aggregate_spec(): bad limit → carp warning emitted');
	}

	# offset with non-integer string → carp and ignored
	{
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		my $p = {
			measures => [{ fn => 'count', as => 'n' }],
			offset   => 'not_a_number',
		};
		my $spec;
		lives_ok { $spec = $db->_validate_aggregate_spec($p) }
			'_validate_aggregate_spec(): non-integer offset does not croak';
		ok(!defined($spec->{'offset'}), '_validate_aggregate_spec(): bad offset → undef (ignored)');
		ok(scalar @warnings,            '_validate_aggregate_spec(): bad offset → carp warning emitted');
	}
}

# ---- A39: _build_aggregate_sql() ------------------------------------------
# SQL assembly from a validated \%spec.  Tests cover SELECT list, GROUP BY,
# WHERE, HAVING, ORDER BY, LIMIT/OFFSET, and the CSV comment-row guard.
note '--- A39: _build_aggregate_sql()';
SKIP: {
	skip 'DBD::SQLite not available for _build_aggregate_sql() tests', 22
		unless $have_sqlite;

	my $adir  = File::Temp::tempdir(CLEANUP => 1);
	my $afile = File::Spec->catfile($adir, 'aggsql.sql');
	my $adsn  = "dbi:SQLite:dbname=$afile";
	{
		my $s = DBI->connect($adsn, undef, undef, { RaiseError => 1 });
		$s->do('CREATE TABLE aggsql (entry TEXT PRIMARY KEY, score REAL, status TEXT)');
		$s->do("INSERT INTO aggsql VALUES ('a',9.5,'active')");
		$s->do("INSERT INTO aggsql VALUES ('b',7.0,'inactive')");
		$s->disconnect();
	}

	{ package Database::aggsql; use parent 'Database::Abstraction'; }
	my $db = Database::aggsql->new(dsn => $adsn, no_entry => 1);
	$db->count();	# trigger _open so _table_name and DBI handle are populated

	my $table = 'aggsql';

	# Grand total: no by, one sum measure → no GROUP BY, no ORDER BY
	{
		my $p    = { measures => [{ fn => 'sum', col => 'score', as => 'total' }] };
		my $spec = $db->_validate_aggregate_spec($p);
		my ($sql, $args) = $db->_build_aggregate_sql($spec, '', $table, $db->{$table});
		like($sql, qr/SELECT SUM\(score\) AS total FROM aggsql/i,
			'_build_aggregate_sql(): grand total SELECT correct');
		unlike($sql, qr/GROUP BY/i,
			'_build_aggregate_sql(): no GROUP BY when by is empty');
		unlike($sql, qr/ORDER BY/i,
			'_build_aggregate_sql(): no ORDER BY when no by and no sort_by');
		is(scalar @{$args}, 0, '_build_aggregate_sql(): grand total → no bind args');
	}

	# Grouped by one column → GROUP BY + default ORDER BY
	{
		my $p    = {
			by       => ['status'],
			measures => [{ fn => 'count', as => 'n' }],
		};
		my $spec = $db->_validate_aggregate_spec($p);
		my ($sql, $args) = $db->_build_aggregate_sql($spec, '', $table, $db->{$table});
		like($sql, qr/SELECT status, COUNT\(\*\) AS n FROM aggsql/i,
			'_build_aggregate_sql(): grouped SELECT with by column first');
		like($sql, qr/GROUP BY status/i,
			'_build_aggregate_sql(): GROUP BY clause present');
		like($sql, qr/ORDER BY status/i,
			'_build_aggregate_sql(): default ORDER BY by-column');
	}

	# WHERE clause from criteria
	{
		my $p    = {
			by       => ['status'],
			measures => [{ fn => 'sum', col => 'score', as => 'total' }],
			status   => $ACTIVE,
		};
		my $spec = $db->_validate_aggregate_spec($p);
		my ($sql, $args) = $db->_build_aggregate_sql($spec, '', $table, $db->{$table});
		like($sql, qr/WHERE/i, '_build_aggregate_sql(): WHERE clause emitted for criteria');
		is(scalar @{$args}, 1, '_build_aggregate_sql(): one bind arg for criteria');
		is($args->[0], $ACTIVE, '_build_aggregate_sql(): bind arg value correct');
	}

	# HAVING with alias (substituted with aggregate expression) → CAST placeholder
	{
		my $p    = {
			by       => ['status'],
			measures => [{ fn => 'sum', col => 'score', as => 'total' }],
			having   => { total => { '>' => 20 } },
		};
		my $spec = $db->_validate_aggregate_spec($p);
		my ($sql, $args) = $db->_build_aggregate_sql($spec, '', $table, $db->{$table});
		like($sql, qr/HAVING SUM\(score\)/i,
			'_build_aggregate_sql(): HAVING uses expression, not alias (PostgreSQL rule)');
		like($sql, qr/CAST\(\? AS REAL\)/i,
			'_build_aggregate_sql(): CAST placeholder for aggregate HAVING comparison');
	}

	# sort_by DESC → ORDER BY ... DESC
	{
		my $p    = {
			by       => ['status'],
			measures => [{ fn => 'sum', col => 'score', as => 'total' }],
			sort_by  => ['total', 'DESC'],
		};
		my $spec = $db->_validate_aggregate_spec($p);
		my ($sql, $args) = $db->_build_aggregate_sql($spec, '', $table, $db->{$table});
		like($sql, qr/ORDER BY total DESC/i,
			'_build_aggregate_sql(): explicit sort_by DESC in ORDER BY');
	}

	# LIMIT and OFFSET → bound as ? placeholders
	{
		my $p    = {
			measures => [{ fn => 'count', as => 'n' }],
			limit    => 5,
			offset   => 10,
		};
		my $spec = $db->_validate_aggregate_spec($p);
		my ($sql, $args) = $db->_build_aggregate_sql($spec, '', $table, $db->{$table});
		like($sql, qr/LIMIT \?/,  '_build_aggregate_sql(): LIMIT bound as ?');
		like($sql, qr/OFFSET \?/, '_build_aggregate_sql(): OFFSET bound as ?');
		my @lim_off = grep { /\A\d+\z/ } @{$args};
		ok((grep { $_ == 5  } @{$args}), '_build_aggregate_sql(): limit=5 in bind args');
		ok((grep { $_ == 10 } @{$args}), '_build_aggregate_sql(): offset=10 in bind args');
	}

	# count_distinct → COUNT(DISTINCT col) in SELECT
	{
		my $p    = { measures => [{ fn => 'count_distinct', col => 'status', as => 'ud' }] };
		my $spec = $db->_validate_aggregate_spec($p);
		my ($sql) = $db->_build_aggregate_sql($spec, '', $table, $db->{$table});
		like($sql, qr/COUNT\(DISTINCT status\)/i,
			'_build_aggregate_sql(): count_distinct → COUNT(DISTINCT col)');
	}

	# Return contract: ($sql, \@args) — args is always an arrayref
	{
		my $p    = { measures => [{ fn => 'count', as => 'n' }] };
		my $spec = $db->_validate_aggregate_spec($p);
		my (undef, $args) = $db->_build_aggregate_sql($spec, '', $table, $db->{$table});
		returns_ok($args, { type => 'arrayref' }, '_build_aggregate_sql(): args return is arrayref');
	}
}

# ---- A40: _build_having_fragment() ----------------------------------------
# All operator branches and the CAST(? AS REAL) behaviour.  Both the
# "alias→aggregate-expression" path (cast) and the "group-by column" path
# (no cast) must be verified.
note '--- A40: _build_having_fragment()';
{
	my $db = Database::test1->new($DATA_DIR);

	# Map aliases to SQL expressions (simulating what _build_aggregate_sql passes)
	my %a2s = ( total => 'SUM(score)', mean => 'AVG(score)' );

	# Scalar equality on an alias key → expression substituted, CAST placeholder
	{
		my ($frag, $args) = $db->_build_having_fragment({ total => 5 }, \%a2s);
		like($frag, qr/SUM\(score\) = CAST\(\? AS REAL\)/,
			'_build_having_fragment(): alias scalar → expression with CAST');
		is($args->[0], 5, '_build_having_fragment(): scalar bind value correct');
	}

	# Scalar equality on a group-by column (not an alias) → bare ?
	{
		my ($frag, $args) = $db->_build_having_fragment({ status => $ACTIVE }, \%a2s);
		like($frag, qr/status = \?/,
			'_build_having_fragment(): group-by column → bare = ?');
		unlike($frag, qr/CAST/,
			'_build_having_fragment(): group-by column → no CAST');
		is($args->[0], $ACTIVE, '_build_having_fragment(): group-by bind value correct');
	}

	# undef → IS NULL (alias path: expression IS NULL)
	{
		my ($frag, $args) = $db->_build_having_fragment({ total => undef }, \%a2s);
		like($frag, qr/SUM\(score\) IS NULL/,
			'_build_having_fragment(): undef → IS NULL (alias substituted)');
		is(scalar @{$args}, 0, '_build_having_fragment(): IS NULL → no bind args');
	}

	# LIKE pattern with % → LIKE ? (bare ?, no CAST — text comparison)
	{
		my ($frag, $args) = $db->_build_having_fragment({ status => 'act%' }, \%a2s);
		like($frag, qr/status LIKE \?/,
			'_build_having_fragment(): % value on group-by key → LIKE ?');
	}

	# > operator with alias → CAST placeholder
	{
		my ($frag, $args) = $db->_build_having_fragment({ total => { '>' => 10 } }, \%a2s);
		like($frag, qr/SUM\(score\) > CAST\(\? AS REAL\)/,
			'_build_having_fragment(): > operator with alias → expression > CAST(?)');
		is($args->[0], 10, '_build_having_fragment(): > bind value');
	}

	# >= operator
	{
		my ($frag, $args) = $db->_build_having_fragment({ total => { '>=' => 10 } }, \%a2s);
		like($frag, qr/SUM\(score\) >= CAST\(\? AS REAL\)/,
			'_build_having_fragment(): >= operator with alias');
	}

	# < operator
	{
		my ($frag) = $db->_build_having_fragment({ total => { '<' => 10 } }, \%a2s);
		like($frag, qr/SUM\(score\) < CAST\(\? AS REAL\)/,
			'_build_having_fragment(): < operator with alias');
	}

	# != operator with value → != CAST(?)
	{
		my ($frag, $args) = $db->_build_having_fragment({ total => { '!=' => 0 } }, \%a2s);
		like($frag, qr/SUM\(score\) != CAST\(\? AS REAL\)/,
			'_build_having_fragment(): != operator with alias');
	}

	# != undef → IS NOT NULL
	{
		my ($frag, $args) = $db->_build_having_fragment({ total => { '!=' => undef } }, \%a2s);
		like($frag, qr/SUM\(score\) IS NOT NULL/,
			'_build_having_fragment(): != undef → IS NOT NULL');
		is(scalar @{$args}, 0, '_build_having_fragment(): IS NOT NULL → no bind args');
	}

	# -in operator → IN (CAST(?) list) for alias
	{
		my ($frag, $args) = $db->_build_having_fragment({ total => { '-in' => [10,20] } }, \%a2s);
		like($frag, qr/SUM\(score\) IN \(/,
			'_build_having_fragment(): -in with alias → IN clause');
		is(scalar @{$args}, 2, '_build_having_fragment(): -in → 2 bind args');
	}

	# -not_in operator
	{
		my ($frag, $args) = $db->_build_having_fragment({ total => { '-not_in' => [5] } }, \%a2s);
		like($frag, qr/SUM\(score\) NOT IN \(/,
			'_build_having_fragment(): -not_in with alias → NOT IN clause');
	}

	# -between operator → BETWEEN CAST(?) AND CAST(?)
	{
		my ($frag, $args) = $db->_build_having_fragment({ total => { '-between' => [5, 30] } }, \%a2s);
		like($frag, qr/SUM\(score\) BETWEEN/,
			'_build_having_fragment(): -between → BETWEEN clause');
		is(scalar @{$args}, 2, '_build_having_fragment(): -between → 2 bind args');
		is($args->[0], 5,  '_build_having_fragment(): -between lower bound');
		is($args->[1], 30, '_build_having_fragment(): -between upper bound');
	}

	# -like operator → LIKE ? (bare, not CAST)
	{
		my ($frag, $args) = $db->_build_having_fragment({ status => { '-like' => 'act%' } }, \%a2s);
		like($frag, qr/status LIKE \?/,
			'_build_having_fragment(): -like operator on group-by col');
	}

	# -not_like operator
	{
		my ($frag) = $db->_build_having_fragment({ status => { '-not_like' => 'z%' } }, \%a2s);
		like($frag, qr/status NOT LIKE \?/,
			'_build_having_fragment(): -not_like operator on group-by col');
	}

	# Multiple keys in having → joined with AND
	{
		my ($frag) = $db->_build_having_fragment(
			{ status => $ACTIVE, total => { '>' => 5 } }, \%a2s);
		like($frag, qr/AND/, '_build_having_fragment(): multiple keys → AND');
	}

	# Empty having → empty fragment and empty args
	{
		my ($frag, $args) = $db->_build_having_fragment({}, \%a2s);
		is($frag, '', '_build_having_fragment(): empty having → empty string');
		is(scalar @{$args}, 0, '_build_having_fragment(): empty having → no args');
	}

	# Unknown operator in hashref → croak
	throws_ok {
		$db->_build_having_fragment({ total => { '-bogus' => 5 } }, \%a2s)
	} qr/Unknown operator '-bogus'/,
	'_build_having_fragment(): unknown operator → croak';

	# Non-hashref, non-scalar value (arrayref) → croak
	throws_ok {
		$db->_build_having_fragment({ total => [1, 2] }, \%a2s)
	} qr/expected scalar or operator hashref/,
	'_build_having_fragment(): arrayref value → croak';
}

# ---- A41: _match_criteria() -----------------------------------------------
# Recursive in-memory criterion matcher with -or/-and support.
# Must use exists() guards on all row key accesses (fixated hash safety).
note '--- A41: _match_criteria()';
{
	my $db = Database::test1->new($DATA_DIR);

	# Empty criteria → always true (no keys to fail)
	ok($db->_match_criteria({ a => 1 }, {}),
		'_match_criteria(): empty criteria → true');

	# Simple scalar equality: match
	ok($db->_match_criteria({ status => $ACTIVE }, { status => $ACTIVE }),
		'_match_criteria(): scalar equality hit → true');

	# Simple scalar equality: no match
	ok(!$db->_match_criteria({ status => $INACTIVE }, { status => $ACTIVE }),
		'_match_criteria(): scalar equality miss → false');

	# Missing key treated as undef, matched against undef criterion
	ok($db->_match_criteria({}, { status => undef }),
		'_match_criteria(): missing key treated as undef, criterion is undef → true');

	# Missing key does not match a scalar criterion
	ok(!$db->_match_criteria({}, { status => $ACTIVE }),
		'_match_criteria(): missing key treated as undef, criterion is scalar → false');

	# Operator hashref: greater-than hit
	ok($db->_match_criteria({ score => 10 }, { score => { '>' => 5 } }),
		'_match_criteria(): > operator hit → true');

	# Operator hashref: greater-than miss
	ok(!$db->_match_criteria({ score => 3 }, { score => { '>' => 5 } }),
		'_match_criteria(): > operator miss → false');

	# -or grouping: at least one sub-criterion matches → true
	ok($db->_match_criteria(
		{ status => $INACTIVE },
		{ '-or' => [ { status => $ACTIVE }, { status => $INACTIVE } ] }
	), '_match_criteria(): -or, one match → true');

	# -or grouping: no sub-criterion matches → false
	ok(!$db->_match_criteria(
		{ status => 'pending' },
		{ '-or' => [ { status => $ACTIVE }, { status => $INACTIVE } ] }
	), '_match_criteria(): -or, no match → false');

	# -or grouping: empty list → no match (returns false because found=0)
	ok(!$db->_match_criteria({ status => $ACTIVE }, { '-or' => [] }),
		'_match_criteria(): -or with empty list → false');

	# -and grouping: all sub-criteria match → true
	ok($db->_match_criteria(
		{ status => $ACTIVE, score => 10 },
		{ '-and' => [ { status => $ACTIVE }, { score => { '>' => 5 } } ] }
	), '_match_criteria(): -and, all match → true');

	# -and grouping: one sub-criterion fails → false
	ok(!$db->_match_criteria(
		{ status => $ACTIVE, score => 3 },
		{ '-and' => [ { status => $ACTIVE }, { score => { '>' => 5 } } ] }
	), '_match_criteria(): -and, one fails → false');

	# -and grouping: empty list → all trivially satisfied → true
	ok($db->_match_criteria({ status => $ACTIVE }, { '-and' => [] }),
		'_match_criteria(): -and with empty list → true');

	# Nested -or inside -and: complex grouping
	ok($db->_match_criteria(
		{ status => $ACTIVE, score => 10 },
		{
			'-and' => [
				{ '-or' => [ { status => $ACTIVE }, { status => $INACTIVE } ] },
				{ score => { '>' => 5 } },
			],
		}
	), '_match_criteria(): nested -or inside -and, all match → true');

	# Nested -or fails first arm, passes second → overall match
	ok($db->_match_criteria(
		{ status => $INACTIVE, score => 10 },
		{
			'-and' => [
				{ '-or' => [ { status => $ACTIVE }, { status => $INACTIVE } ] },
				{ score => 10 },
			],
		}
	), '_match_criteria(): nested: second arm of -or matches → true');

	# Multiple top-level keys: all must match
	ok($db->_match_criteria(
		{ status => $ACTIVE, score => 10 },
		{ status => $ACTIVE, score => 10 }
	), '_match_criteria(): multiple keys, all match → true');

	# Multiple top-level keys: one fails
	ok(!$db->_match_criteria(
		{ status => $ACTIVE, score => 3 },
		{ status => $ACTIVE, score => { '>' => 5 } }
	), '_match_criteria(): multiple keys, one fails → false');

	# -like inside -or (delegates to _match_criterion)
	ok($db->_match_criteria(
		{ name => 'Alice' },
		{ '-or' => [ { name => { '-like' => 'Al%' } }, { name => 'Bob' } ] }
	), '_match_criteria(): -like inside -or → true when first arm matches');

	# Row with fixated key: exists() guard ensures missing key does not die
	{
		# Simulate a fixated row: the key 'missing_col' is absent; criterion demands
		# it equals 'x'.  Should return false, not die.
		ok(!$db->_match_criteria({ a => 1 }, { missing_col => 'x' }),
			'_match_criteria(): absent key vs scalar criterion → false (not die)');
	}
}

# ---- A42: _fold_aggregate() -----------------------------------------------
# Pure Perl fold; no DBI.  Tests each accumulator type and edge cases.
note '--- A42: _fold_aggregate()';
{
	my $db = Database::test1->new($DATA_DIR);

	# Helper: build a valid $spec from a simple params hashref
	my $mk_spec = sub {
		my ($by, @measures) = @_;
		my $p = { by => $by, measures => \@measures };
		return $db->_validate_aggregate_spec($p);
	};

	# Grand total sum: two rows, known scores
	{
		my $rows = [
			{ score => 9.5, status => $ACTIVE   },
			{ score => 7.0, status => $INACTIVE },
		];
		my $spec = $mk_spec->([], { fn => 'sum', col => 'score', as => 'total' });
		my $out  = $db->_fold_aggregate($rows, $spec);
		is(scalar @{$out}, 1,    '_fold_aggregate(): grand total → 1 row');
		is($out->[0]{'total'}, 16.5, '_fold_aggregate(): sum correct');
	}

	# Grand total count(*): all rows counted regardless of col value
	{
		my $rows = [{ score => undef, status => $ACTIVE }, { score => 7, status => $INACTIVE }];
		my $spec = $mk_spec->([], { fn => 'count', as => 'n' });
		my $out  = $db->_fold_aggregate($rows, $spec);
		is($out->[0]{'n'}, 2, '_fold_aggregate(): count(*) counts undef rows too');
	}

	# count(col): skips undef values
	{
		my $rows = [{ score => undef }, { score => 7 }];
		my $spec = $mk_spec->([], { fn => 'count', col => 'score', as => 'n' });
		my $out  = $db->_fold_aggregate($rows, $spec);
		is($out->[0]{'n'}, 1, '_fold_aggregate(): count(col) skips undef');
	}

	# count_distinct: only unique defined values
	{
		my $rows = [
			{ status => $ACTIVE   },
			{ status => $ACTIVE   },
			{ status => $INACTIVE },
			{ status => undef     },
		];
		my $spec = $mk_spec->([], { fn => 'count_distinct', col => 'status', as => 'ud' });
		my $out  = $db->_fold_aggregate($rows, $spec);
		is($out->[0]{'ud'}, 2, '_fold_aggregate(): count_distinct counts unique defined values');
	}

	# avg: correct arithmetic
	{
		my $rows = [{ score => 9 }, { score => 7 }, { score => 8 }];
		my $spec = $mk_spec->([], { fn => 'avg', col => 'score', as => 'mean' });
		my $out  = $db->_fold_aggregate($rows, $spec);
		ok(abs($out->[0]{'mean'} - 8.0) < 1e-9, '_fold_aggregate(): avg correct');
	}

	# avg with all undef → undef (§5.3 normalisation in _fold_aggregate)
	{
		my $rows = [{ score => undef }, { score => undef }];
		my $spec = $mk_spec->([], { fn => 'avg', col => 'score', as => 'mean' });
		my $out  = $db->_fold_aggregate($rows, $spec);
		ok(!defined($out->[0]{'mean'}), '_fold_aggregate(): avg all-undef → undef');
	}

	# min: correct
	{
		my $rows = [{ score => 9 }, { score => 5 }, { score => 7 }];
		my $spec = $mk_spec->([], { fn => 'min', col => 'score', as => 'lo' });
		my $out  = $db->_fold_aggregate($rows, $spec);
		is($out->[0]{'lo'}, 5, '_fold_aggregate(): min correct');
	}

	# max: correct
	{
		my $rows = [{ score => 9 }, { score => 5 }, { score => 7 }];
		my $spec = $mk_spec->([], { fn => 'max', col => 'score', as => 'hi' });
		my $out  = $db->_fold_aggregate($rows, $spec);
		is($out->[0]{'hi'}, 9, '_fold_aggregate(): max correct');
	}

	# min/max all undef → undef (no match to compare against)
	{
		my $rows = [{ score => undef }, { score => undef }];
		my $spec = $mk_spec->([], { fn => 'min', col => 'score', as => 'lo' });
		my $out  = $db->_fold_aggregate($rows, $spec);
		ok(!defined($out->[0]{'lo'}), '_fold_aggregate(): min all-undef → undef');
	}

	# Grouped by one column → multiple groups, first-seen order
	{
		my $rows = [
			{ status => $ACTIVE,   score => 9.5 },
			{ status => $INACTIVE, score => 7.0 },
			{ status => $ACTIVE,   score => 8.5 },
		];
		my $spec = $mk_spec->(['status'], { fn => 'sum', col => 'score', as => 'total' });
		my $out  = $db->_fold_aggregate($rows, $spec);
		is(scalar @{$out}, 2, '_fold_aggregate(): two groups produced');
		# First-seen order: active first
		is($out->[0]{'status'}, $ACTIVE,   '_fold_aggregate(): first group is active (first-seen)');
		is($out->[0]{'total'},  18.0,       '_fold_aggregate(): active total correct');
		is($out->[1]{'status'}, $INACTIVE, '_fold_aggregate(): second group is inactive');
		is($out->[1]{'total'},  7.0,        '_fold_aggregate(): inactive total correct');
	}

	# undef group key treated as '' (same group as empty string)
	{
		my $rows = [{ cat => undef }, { cat => '' }, { cat => 'x' }];
		my $spec = $mk_spec->(['cat'], { fn => 'count', as => 'n' });
		my $out  = $db->_fold_aggregate($rows, $spec);
		# undef and '' should collapse to one group; 'x' is a second group
		is(scalar @{$out}, 2,
			'_fold_aggregate(): undef and empty-string collapse to same group key');
	}

	# Empty input → empty arrayref (not undef)
	{
		my $spec = $mk_spec->(['status'], { fn => 'sum', col => 'score', as => 'total' });
		my $out  = $db->_fold_aggregate([], $spec);
		is(ref($out), 'ARRAY', '_fold_aggregate(): empty input → arrayref');
		is(scalar @{$out}, 0, '_fold_aggregate(): empty input → zero groups');
	}

	# sum with non-numeric value → bad counter incremented, warning emitted
	# The §5.5 warning fires at finalisation, once per measure per call.
	{
		my $rows = [{ score => 'abc' }, { score => 5 }];
		my $spec = $mk_spec->([], { fn => 'sum', col => 'score', as => 'total' });
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		my $out = $db->_fold_aggregate($rows, $spec);
		# 'abc' is skipped; only 5 contributes
		is($out->[0]{'total'}, 5, '_fold_aggregate(): non-numeric value skipped for sum');
		ok(scalar @warnings, '_fold_aggregate(): non-numeric value triggers warning');
		like($warnings[0], qr/non-numeric/,
			'_fold_aggregate(): warning text mentions non-numeric');
	}

	# Warning emitted at most once per measure per call (even for multiple bad values)
	{
		my $rows = [{ score => 'x' }, { score => 'y' }, { score => 5 }];
		my $spec = $mk_spec->([], { fn => 'sum', col => 'score', as => 'total' });
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		$db->_fold_aggregate($rows, $spec);
		is(scalar @warnings, 1,
			'_fold_aggregate(): warning fires at most once per measure per call');
	}

	# avg non-numeric → warning, count stays 0 → avg result is undef
	{
		my $rows = [{ score => 'bad' }];
		my $spec = $mk_spec->([], { fn => 'avg', col => 'score', as => 'mean' });
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		my $out = $db->_fold_aggregate($rows, $spec);
		ok(!defined($out->[0]{'mean'}),
			'_fold_aggregate(): avg with only non-numeric → undef (0/0)');
		ok(scalar @warnings, '_fold_aggregate(): avg non-numeric triggers warning');
	}

	# Multiple measures accumulated per group simultaneously
	{
		my $rows = [{ s => $ACTIVE, v => 3 }, { s => $ACTIVE, v => 7 }];
		my $spec = $mk_spec->(['s'],
			{ fn => 'sum', col => 'v', as => 'total' },
			{ fn => 'count', as => 'n' },
		);
		my $out = $db->_fold_aggregate($rows, $spec);
		is($out->[0]{'total'}, 10, '_fold_aggregate(): multi-measure sum correct');
		is($out->[0]{'n'},     2,  '_fold_aggregate(): multi-measure count correct');
	}

	# Return value is always an arrayref (no undef)
	{
		my $rows = [{ a => 1 }];
		my $spec = $mk_spec->([], { fn => 'count', as => 'n' });
		my $out  = $db->_fold_aggregate($rows, $spec);
		returns_ok($out, { type => 'arrayref' }, '_fold_aggregate(): return type is arrayref');
	}
}

# ---------------------------------------------------------------------------
# PART B (continued) — Query builder aggregate additions (0.49)
# ---------------------------------------------------------------------------

note '';
note '=== Query builder aggregate additions (0.49) ===';

SKIP: {
	skip 'DBD::SQLite not available for Query aggregate tests', 40 unless $have_sqlite;

	my $qdir  = File::Temp::tempdir(CLEANUP => 1);
	my $qfile = File::Spec->catfile($qdir, 'qagg.sql');
	my $qdsn  = "dbi:SQLite:dbname=$qfile";
	{
		my $s = DBI->connect($qdsn, undef, undef, { RaiseError => 1 });
		$s->do('CREATE TABLE qagg (entry TEXT PRIMARY KEY, score REAL, status TEXT)');
		for my $r (
			['a', 9.5, $ACTIVE],   ['b', 7.0, $INACTIVE],
			['c', 8.5, $ACTIVE],   ['d', 6.0, $INACTIVE],
			['e', 10.0, $ACTIVE],
		) {
			$s->do('INSERT INTO qagg VALUES (?,?,?)', undef, @{$r});
		}
		$s->disconnect();
	}

	{ package Database::qagg; use parent 'Database::Abstraction'; }
	my $qdb = Database::qagg->new(dsn => $qdsn, no_entry => 1);

	# ---- B13: group_by() -------------------------------------------------------
	note '--- B13: Query group_by()';

	# List form: multiple args stored as arrayref
	{
		my $q = $qdb->query();
		my $ret = $q->group_by('status', 'score');
		is($ret, $q, 'group_by(): returns $self for chaining');
		is(ref($q->{'_group_by'}), 'ARRAY', 'group_by(): _group_by stored as arrayref');
		is(scalar @{$q->{'_group_by'}}, 2, 'group_by(): two columns stored');
		is($q->{'_group_by'}[0], 'status', 'group_by(): first column correct');
	}

	# Arrayref form: single arrayref argument unpacked
	{
		my $q = $qdb->query();
		$q->group_by(['a', 'b', 'c']);
		is(scalar @{$q->{'_group_by'}}, 3, 'group_by(): arrayref form → three cols stored');
	}

	# group_by replaces previous value (not append)
	{
		my $q = $qdb->query->group_by('x');
		$q->group_by('y');
		is(scalar @{$q->{'_group_by'}}, 1, 'group_by(): replaces existing, not appends');
		is($q->{'_group_by'}[0], 'y', 'group_by(): new value replaces old');
	}

	# Clearing with empty list → empty arrayref
	{
		my $q = $qdb->query->group_by('x');
		$q->group_by();
		is(scalar @{$q->{'_group_by'}}, 0, 'group_by(): empty arg → clears list');
	}

	# ---- B14: measure() -------------------------------------------------------
	note '--- B14: Query measure()';

	# Three-arg form: col, fn, as
	{
		my $q = $qdb->query();
		my $ret = $q->measure('score', 'sum', 'total');
		is($ret, $q, 'measure(): returns $self for chaining');
		is(scalar @{$q->{'_measures'}}, 1, 'measure(): one measure appended');
		is($q->{'_measures'}[0]{'col'}, 'score', 'measure(): col stored');
		is($q->{'_measures'}[0]{'fn'},  'sum',   'measure(): fn stored');
		is($q->{'_measures'}[0]{'as'},  'total', 'measure(): as stored');
	}

	# Hashref form: single hashref accepted
	{
		my $q = $qdb->query()->measure({ col => 'score', fn => 'avg', as => 'mean' });
		is($q->{'_measures'}[0]{'fn'}, 'avg', 'measure(): hashref form fn stored');
	}

	# count(*) via undef col: col => undef is stored (aggregate() validates)
	{
		my $q = $qdb->query()->measure(undef, 'count', 'n');
		ok(!defined($q->{'_measures'}[0]{'col'}),
			'measure(): undef col stored (count(*) pattern)');
	}

	# Multiple measure() calls accumulate (not replace)
	{
		my $q = $qdb->query()
			->measure('score', 'sum', 'total')
			->measure(undef, 'count', 'n');
		is(scalar @{$q->{'_measures'}}, 2, 'measure(): second call appends, not replaces');
	}

	# ---- B15: having() --------------------------------------------------------
	note '--- B15: Query having()';

	# Named-pair form
	{
		my $q = $qdb->query();
		my $ret = $q->having(total => { '>' => 10 });
		is($ret, $q, 'having(): returns $self for chaining');
		ok(exists($q->{'_having'}{'total'}), 'having(): key stored in _having');
	}

	# Hashref form
	{
		my $q = $qdb->query()->having({ status => $ACTIVE });
		is($q->{'_having'}{'status'}, $ACTIVE, 'having(): hashref form stored correctly');
	}

	# Multiple calls merge with AND semantics (later key added alongside earlier)
	{
		my $q = $qdb->query()
			->having(total => { '>' => 10 })
			->having(n     => { '<' => 100 });
		ok(exists($q->{'_having'}{'total'}), 'having(): first call key retained');
		ok(exists($q->{'_having'}{'n'}),     'having(): second call key added');
	}

	# ---- B16: all() aggregate path --------------------------------------------
	note '--- B16: Query all() aggregate path';

	# group_by + measure + all() returns same data as $db->aggregate(...)
	{
		my $q_rows = $qdb->query
			->group_by('status')
			->measure('score', 'sum', 'total')
			->all();
		returns_is($q_rows, { type => 'arrayref' },
			'Query all() aggregate: returns arrayref');
		is(scalar @{$q_rows}, 2, 'Query all() aggregate: two status groups');
	}

	# with where() criteria: pre-aggregation filter applied
	{
		my $rows = $qdb->query
			->where(status => $ACTIVE)
			->group_by('status')
			->measure('score', 'sum', 'total')
			->all();
		is(scalar @{$rows}, 1, 'Query all() aggregate: where() filter applies before group');
		is($rows->[0]{'status'}, $ACTIVE, 'Query all() aggregate: only active group returned');
	}

	# with having() post-group filter
	{
		my $rows = $qdb->query
			->group_by('status')
			->measure('score', 'sum', 'total')
			->having(total => { '>' => 20 })
			->all();
		# Only active group (total=28.0) passes HAVING >20; inactive=13.0 does not
		is(scalar @{$rows}, 1, 'Query all() aggregate: having() filters result');
		is($rows->[0]{'status'}, $ACTIVE, 'Query all() aggregate: having() keeps correct group');
	}

	# order_by maps into sort_by for aggregate path
	{
		my $rows = $qdb->query
			->group_by('status')
			->measure('score', 'sum', 'total')
			->order_by('total DESC')
			->all();
		is($rows->[0]{'status'}, $ACTIVE,
			'Query all() aggregate: order_by("total DESC") sorts by total descending');
	}

	# limit: only first N groups
	{
		my $rows = $qdb->query
			->group_by('status')
			->measure('score', 'sum', 'total')
			->limit(1)
			->all();
		is(scalar @{$rows}, 1, 'Query all() aggregate: limit(1) returns one group');
	}

	# Query builder matches direct aggregate() call (two-fronts-one-implementation)
	{
		my $q_out = $qdb->query
			->group_by('status')
			->measure('score', 'sum', 'total')
			->all();
		my $d_out = $qdb->aggregate(
			by       => ['status'],
			measures => [{ col => 'score', fn => 'sum', as => 'total' }],
		);
		is(scalar @{$q_out}, scalar @{$d_out},
			'Query->all() matches aggregate(): same row count');
		# Sort both by status for a stable comparison
		my @qs = sort { $a->{'status'} cmp $b->{'status'} } @{$q_out};
		my @ds = sort { $a->{'status'} cmp $b->{'status'} } @{$d_out};
		is($qs[0]{'total'}, $ds[0]{'total'},
			'Query->all() matches aggregate(): first group total equal');
	}

	# ---- B17: count() croaks when measures are set ----------------------------
	note '--- B17: Query count() with measures → croak';

	throws_ok {
		$qdb->query->measure('score', 'sum', 'total')->count()
	} qr/count\(\) is not available once measure\(\) has been called/,
	'Query count(): after measure() → exact croak message';

	# Without measures: count() still works normally
	{
		my $n = $qdb->query->where(status => $ACTIVE)->count();
		is($n, 3, 'Query count(): without measures → normal count');
	}

	# ---- B18: first() aggregate path ------------------------------------------
	note '--- B18: Query first() aggregate path';

	# first() with measures → one row (the first group)
	{
		my $row = $qdb->query
			->group_by('status')
			->measure('score', 'sum', 'total')
			->order_by('status ASC')
			->first();
		returns_is($row, { type => 'hashref' },
			'Query first() aggregate: returns hashref');
		ok(defined($row->{'status'}), 'Query first() aggregate: row has status key');
		ok(defined($row->{'total'}),  'Query first() aggregate: row has total key');
	}

	# first() with measures and no match → undef
	{
		my $row = $qdb->query
			->where(status => 'no_such_status')
			->group_by('status')
			->measure('score', 'sum', 'total')
			->first();
		returns_is($row, { type => 'void' },
			'Query first() aggregate: no match → undef');
	}

	# ---- B19: each() aggregate path -------------------------------------------
	note '--- B19: Query each() aggregate path';

	# each() with measures: iterates over aggregate rows, returns count
	{
		my @visited;
		my $n = $qdb->query
			->group_by('status')
			->measure('score', 'sum', 'total')
			->each(sub { push @visited, shift });
		is($n, 2, 'Query each() aggregate: returns row count (2 groups)');
		is(scalar @visited, 2, 'Query each() aggregate: callback called once per group');
		returns_is($visited[0], { type => 'hashref' },
			'Query each() aggregate: callback receives hashref');
		ok(exists($visited[0]{'total'}), 'Query each() aggregate: row has measure alias key');
	}

	# each() non-code-ref argument → croak
	throws_ok {
		$qdb->query->each('not a coderef')
	} qr/callback must be a code reference/,
	'Query each(): non-code-ref → croak';
}

done_testing();

