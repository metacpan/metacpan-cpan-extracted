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
	isa_ok($ne_cols, 'ARRAY',
		'columns() ARRAY slurp: returns arrayref (not empty)');
	ok(scalar(@{$ne_cols}) > 0,
		'columns() ARRAY slurp: list is non-empty');

	my $ne_schema = $ne->schema();
	isa_ok($ne_schema, 'HASH',
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
		isa_ok($bdb_all->[0], 'HASH', 'Query BDB all(): each row is a hashref');

		# first() must return the first element of the berkeley scan
		my $bdb_first = $bdb->query()->first();
		isa_ok($bdb_first, 'HASH', 'Query BDB first(): returns a hashref');

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
		isa_ok($all, 'ARRAY', '_scan_berkeley(): returns arrayref');
		ok(exists $all->[0]{'entry'}, '_scan_berkeley(): each row has entry key');
		ok(exists $all->[0]{'value'}, '_scan_berkeley(): each row has value key');
		returns_ok($all, { type => 'arrayref' }, '_scan_berkeley(): return type is arrayref');
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
	isa_ok($cols, 'ARRAY', 'columns() SQLite: returns arrayref');
	is(scalar @{$cols}, 3,  'columns() SQLite: exactly 3 columns');
	ok((grep { $_ eq 'entry' } @{$cols}), 'columns() SQLite: entry present');
	ok((grep { $_ eq 'name'  } @{$cols}), 'columns() SQLite: name present');
	ok((grep { $_ eq 'score' } @{$cols}), 'columns() SQLite: score present');

	# schema() — SQLite uses PRAGMA table_info
	my $schema = $db->schema();
	isa_ok($schema, 'HASH', 'schema() SQLite: returns hashref');
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
	isa_ok($ref1, 'ARRAY', 'selectall_hashref(): returns arrayref');

	# selectall_hash is a documented backward-compat alias for selectall_array
	my @arr1 = $db->selectall_hash();
	my @arr2 = $db->selectall_array();
	is(scalar @arr1, scalar @arr2,
		'selectall_hash(): returns same count as selectall_array()');
}

done_testing();
