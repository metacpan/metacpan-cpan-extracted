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
	isa_ok($d, 'HASH', 'init() returns a hashref');
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
	isa_ok($obj, 'Database::test1', 'new(): bare string → directory');
	is($obj->{'id'}, $ENTRY_COL, 'new(): id defaults to "entry"');
	ok(!$obj->{'no_entry'}, 'new(): no_entry defaults to 0');
	is($obj->{'cache_duration'}, '1 hour', 'new(): cache_duration defaults to 1 hour');

	# Hashref form
	my $obj2 = Database::test1->new({ directory => $DATA_DIR });
	isa_ok($obj2, 'Database::test1', 'new(): hashref args accepted');

	# Named-list form
	my $obj3 = Database::test1->new(directory => $DATA_DIR);
	isa_ok($obj3, 'Database::test1', 'new(): named-list args accepted');

	# Clone form: $obj->new(extra_key => 1) merges into a new object
	my $clone = $obj->new(extra_key => 'clone_val');
	isa_ok($clone, 'Database::test1', 'new(): clone retains class');
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

# ---- A12: _is_berkeley_db / _is_berkeley_db_0 / _is_berkeley_db_12 ------
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

	# _is_berkeley_db_0: handles a file handle with < 4 bytes → returns 0
	{
		my $tiny = File::Temp->new();
		print {$tiny} 'XY';
		$tiny->flush();
		open my $fh, '<', $tiny->filename();	## no critic
		binmode $fh;
		ok(!$db->_is_berkeley_db_0($fh), '_is_berkeley_db_0(): <4 bytes → 0');
		close $fh;
	}

	# _is_berkeley_db_12: handles a file too short for seek → returns 0
	{
		my $tiny2 = File::Temp->new();
		print {$tiny2} 'X';
		$tiny2->flush();
		open my $fh, '<', $tiny2->filename();	## no critic
		binmode $fh;
		ok(!$db->_is_berkeley_db_12($fh), '_is_berkeley_db_12(): too short → 0');
		close $fh;
	}
}

# ---- A13: fetchrow_hashref() with slurped data ---------------------------
note '--- A13: fetchrow_hashref() — slurp path';
{
	my $db = Database::test1->new($DATA_DIR);

	# Hit
	my $row = $db->fetchrow_hashref(entry => 'one');
	isa_ok($row, 'HASH', 'fetchrow_hashref(): returns hashref on hit');
	is($row->{$ENTRY_COL}, 'one', 'fetchrow_hashref(): correct row returned');
	returns_ok($row, { type => 'hashref' }, 'fetchrow_hashref(): return type is hashref');

	# Miss → undef (not throw, even with locked hash)
	my $miss = $db->fetchrow_hashref(entry => '__nonexistent__');
	ok(!defined($miss), 'fetchrow_hashref(): miss returns undef');

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
	isa_ok($all, 'ARRAY', 'selectall_arrayref(): no criteria → arrayref');
	ok(scalar @{$all} >= 4, 'selectall_arrayref(): returns all rows (>=4)');
	returns_ok($all, { type => 'arrayref' }, 'selectall_arrayref(): return type is arrayref');

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
	ok(!defined($miss), 'AUTOLOAD(): missing entry returns undef');

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
	isa_ok($rows[0], 'HASH', 'execute(): each row is a hashref');

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
	isa_ok($cols, 'ARRAY', 'columns(): returns arrayref');
	ok(grep({ $_ eq $ENTRY_COL } @{$cols}), 'columns(): entry column present');

	# Cached on second call
	my $cols2 = $db->columns();
	is($cols, $cols2, 'columns(): returns cached ref on second call');

	my $schema = $db->schema();
	isa_ok($schema, 'HASH', 'schema(): returns hashref');
	ok(exists $schema->{$ENTRY_COL}, 'schema(): entry key present');
	ok(exists $schema->{$ENTRY_COL}{'type'}, 'schema(): type sub-key present');
	ok(exists $schema->{$ENTRY_COL}{'nullable'}, 'schema(): nullable sub-key present');
	ok(exists $schema->{$ENTRY_COL}{'pk'}, 'schema(): pk sub-key present');
	is($schema->{$ENTRY_COL}{'pk'}, 1, 'schema(): entry column is pk');

	# Cached on second call
	my $schema2 = $db->schema();
	is($schema, $schema2, 'schema(): cached ref returned on second call');
}

# ---- A20: query() — returns Query object ---------------------------------
note '--- A20: query()';
{
	my $db = Database::test1->new($DATA_DIR);

	# Mocking is not needed here; just verify the object type
	SKIP: {
		skip 'DBD::SQLite not available for query() path', 1 unless $have_sqlite;
		my $q = $db->query();
		isa_ok($q, 'Database::Abstraction::Query', 'query(): returns Query object');
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
	isa_ok($q, 'Database::Abstraction::Query', 'Query->new(): valid object');

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
	isa_ok($all, 'ARRAY', 'all(): returns arrayref');
	is(scalar @{$all}, 5, 'all(): returns all 5 rows');

	# where() + all()
	my $active = $db->query->where(status => 'active')->all();
	is(scalar @{$active}, 3, 'all(): with where filter returns 3 rows');

	# ---- B4: first() -------------------------------------------------
	note '--- B4: Query->first()';

	my $first = $db->query->where(name => 'Alice')->first();
	isa_ok($first, 'HASH', 'first(): returns hashref');
	is($first->{'name'}, 'Alice', 'first(): correct row returned');

	my $miss = $db->query->where(name => '__nobody__')->first();
	ok(!defined($miss), 'first(): no match returns undef');

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
}

done_testing();
