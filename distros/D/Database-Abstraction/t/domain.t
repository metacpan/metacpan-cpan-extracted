#!perl -w

# t/domain.t -- Equivalence Partitioning and Boundary Value Analysis
#
# Covers every constructor and query parameter:
#   id, table, host, url, database, base_criteria, redis_key,
#   limit/offset, sort_by, columns, join, each_row callback,
#   max_slurp_size, filename/dbname, and multibyte character domains.

use strict;
use warnings;

use DBI;
use File::Spec;
use File::Temp qw(tempfile);
use FindBin qw($Bin);
use Readonly;
use Test::Most;
use Test::Warn;

use lib 't/lib';

# Pre-load Database::Abstraction so Sub::Private's CHECK block runs at compile
# time and subsequent use statements in inline packages work correctly.
use Database::test1;

# -----------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------

Readonly::Scalar my $DIR         => File::Spec->catfile($Bin, 'data');
Readonly::Scalar my $CLASS       => 'Database::test1';

# test1.csv has 4 data rows: one(1), two(2), three(3), empty('')
Readonly::Scalar my $TOTAL_ROWS  => 4;
Readonly::Scalar my $MAX_NUMBER  => 3;    # highest numeric value in fixture

# Error-message fragments (exact substrings from source)
Readonly::Scalar my $ERR_UNSAFE_ID    => qr/unsafe id column name/;
Readonly::Scalar my $ERR_UNSAFE_TABLE => qr/unsafe table name/;
Readonly::Scalar my $ERR_UNSAFE_HOST  => qr/unsafe host/;
Readonly::Scalar my $ERR_UNSAFE_URL   => qr/unsafe url/;
Readonly::Scalar my $ERR_UNSAFE_DB    => qr/unsafe database/;
Readonly::Scalar my $ERR_BC_HASHREF   => qr/base_criteria must be a hashref/;
Readonly::Scalar my $ERR_BC_KEY       => qr/unsafe base_criteria key/;
Readonly::Scalar my $ERR_REDIS_KEY    => qr/redis_key is only valid with a redis/;
Readonly::Scalar my $ERR_JOIN_TABLE   => qr/join: missing "table"/;
Readonly::Scalar my $ERR_JOIN_ON      => qr/join: missing "on" condition/;
Readonly::Scalar my $ERR_JOIN_UNSAFE  => qr/join: unsafe table name/;
Readonly::Scalar my $ERR_JOIN_TYPE    => qr/Invalid JOIN type/;
Readonly::Scalar my $ERR_CALLBACK     => qr/each_row: callback must be a code reference/;
Readonly::Scalar my $ERR_UNSAFE_COL   => qr/unsafe column name/;

# -----------------------------------------------------------------------
# Inline no_entry subclass for SQL-path column-name tests
# -----------------------------------------------------------------------

{
	package Database::domain_noentry;
	use Database::Abstraction;
	our @ISA = ('Database::Abstraction');
	sub new {
		my $class = shift;
		return $class->SUPER::new(no_entry => 1, sep_char => ',', dbname => 'test4', @_);
	}
}

# Convenience: build a fresh Database::test1 object
sub _db {
	return Database::test1->new(directory => $DIR, @_);
}

# -----------------------------------------------------------------------
# SECTION 1: id parameter — $SAFE_IDENTIFIER
# /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
# Valid:   letter/underscore start, alphanumeric/underscore body
# Invalid: starts with digit, contains non-ASCII, contains punctuation
# -----------------------------------------------------------------------

subtest 'id parameter — valid partition' => sub {
	plan tests => 5;

	# Typical valid values
	lives_ok { _db(id => 'entry') }     'id: standard name "entry"';
	lives_ok { _db(id => '_id') }       'id: leading underscore "_id"';
	lives_ok { _db(id => 'my_col') }    'id: underscore in body "my_col"';
	lives_ok { _db(id => 'col1') }      'id: trailing digit "col1"';
	lives_ok { _db(id => 'A') }         'id: single uppercase letter (minimum valid length)';
};

subtest 'id parameter — boundary: minimum valid identifier length (1 char)' => sub {
	plan tests => 2;
	lives_ok { _db(id => 'a') } 'id: single lowercase letter accepted';
	lives_ok { _db(id => '_') } 'id: single underscore accepted';
};

subtest 'id parameter — invalid partition: starts with digit' => sub {
	plan tests => 2;
	throws_ok { _db(id => '1bad') }  $ERR_UNSAFE_ID, 'id: starts with digit rejected';
	throws_ok { _db(id => '0') }     $ERR_UNSAFE_ID, 'id: single digit rejected (BVA: just-invalid at min)';
};

subtest 'id parameter — invalid partition: SQL metacharacters' => sub {
	plan tests => 4;
	throws_ok { _db(id => 'entry; DROP TABLE t--') } $ERR_UNSAFE_ID, 'id: semicolon injection rejected';
	throws_ok { _db(id => 'id UNION SELECT') }        $ERR_UNSAFE_ID, 'id: UNION injection rejected';
	throws_ok { _db(id => "id\0null") }               $ERR_UNSAFE_ID, 'id: null byte rejected';
	throws_ok { _db(id => 'my-col') }                 $ERR_UNSAFE_ID, 'id: hyphen rejected';
};

subtest 'id parameter — invalid partition: non-ASCII / multibyte' => sub {
	plan tests => 3;
	# SAFE_IDENTIFIER is ASCII-only; non-ASCII must be rejected to prevent
	# driver-specific encoding issues in ORDER BY / WHERE clauses.
	throws_ok { _db(id => "\x{fc}nterwegs") }  $ERR_UNSAFE_ID, 'id: Latin-1 umlaut (ü) rejected';
	throws_ok { _db(id => "\x{1f600}col") }    $ERR_UNSAFE_ID, 'id: emoji prefix rejected';
	throws_ok { _db(id => "\x{202e}rtl") }     $ERR_UNSAFE_ID, 'id: RTL override char rejected';
};

subtest 'id parameter — invalid partition: dots (QUALIFIED vs IDENTIFIER)' => sub {
	plan tests => 1;
	# dot is allowed by SAFE_QUALIFIED but NOT by SAFE_IDENTIFIER
	throws_ok { _db(id => 't.col') } $ERR_UNSAFE_ID, 'id: qualified name with dot rejected';
};

# -----------------------------------------------------------------------
# SECTION 2: table parameter — $SAFE_QUALIFIED
# /\A[a-zA-Z_][a-zA-Z0-9_.]*\z/
# Valid:   letter/underscore start, alphanumeric/underscore/dot body
# Invalid: starts with digit, spaces, SQL punctuation, non-ASCII
# -----------------------------------------------------------------------

subtest 'table parameter — valid partition' => sub {
	plan tests => 4;
	lives_ok { _db(table => 'test1') }      'table: simple name';
	lives_ok { _db(table => 'db.test1') }   'table: qualified table.name with dot';
	lives_ok { _db(table => '_tbl') }       'table: leading underscore';
	lives_ok { _db(table => 'T1') }         'table: uppercase+digit';
};

subtest 'table parameter — invalid partition: injection attempts' => sub {
	plan tests => 4;
	throws_ok { _db(table => 'users UNION SELECT password FROM secrets') }
		$ERR_UNSAFE_TABLE, 'table: UNION injection rejected';
	throws_ok { _db(table => "tbl\0") }
		$ERR_UNSAFE_TABLE, 'table: null byte rejected';
	throws_ok { _db(table => '1table') }
		$ERR_UNSAFE_TABLE, 'table: starts with digit rejected';
	throws_ok { _db(table => 'my-table') }
		$ERR_UNSAFE_TABLE, 'table: hyphen rejected';
};

subtest 'table parameter — invalid partition: non-ASCII' => sub {
	plan tests => 2;
	throws_ok { _db(table => "caf\x{e9}") }   $ERR_UNSAFE_TABLE, 'table: Latin-1 accent (é) rejected';
	throws_ok { _db(table => "\x{1f4db}tbl") } $ERR_UNSAFE_TABLE, 'table: emoji prefix rejected';
};

# -----------------------------------------------------------------------
# SECTION 3: host parameter
# /\A(?:[a-zA-Z0-9][a-zA-Z0-9._-]*\@)?[a-zA-Z0-9:][a-zA-Z0-9._:-]*\z/
# Valid:   hostname, user@host, IPv4, IPv6
# Invalid: spaces, semicolons, shell metacharacters, path traversal
# Note:    directory check is skipped for genuinely remote hosts, so
#          we do not need a real directory for the rejected cases.
# -----------------------------------------------------------------------

subtest 'host parameter — valid partition' => sub {
	plan tests => 5;
	# Providing directory is needed for local-host resolution path (it reads
	# the directory directly); a remote host bypasses the -d check.
	lives_ok { Database::test1->new(host => 'remoteserver',     directory => $DIR) }
		'host: simple hostname accepted';
	lives_ok { Database::test1->new(host => 'server.example.com', directory => $DIR) }
		'host: FQDN accepted';
	lives_ok { Database::test1->new(host => 'user@server',      directory => $DIR) }
		'host: user@host accepted';
	lives_ok { Database::test1->new(host => '192.168.1.1',      directory => $DIR) }
		'host: dotted IPv4 accepted';
	lives_ok { Database::test1->new(host => '::1',              directory => $DIR) }
		'host: IPv6 loopback accepted (local-host short-circuit)';
};

subtest 'host parameter — invalid partition: shell metacharacters' => sub {
	plan tests => 4;
	throws_ok { Database::test1->new(host => 'host server',    directory => $DIR) }
		$ERR_UNSAFE_HOST, 'host: space rejected';
	throws_ok { Database::test1->new(host => 'host;rm -rf /',  directory => $DIR) }
		$ERR_UNSAFE_HOST, 'host: semicolon rejected';
	throws_ok { Database::test1->new(host => 'host$(id)',       directory => $DIR) }
		$ERR_UNSAFE_HOST, 'host: command substitution rejected';
	throws_ok { Database::test1->new(host => '@server',         directory => $DIR) }
		$ERR_UNSAFE_HOST, 'host: leading at-sign rejected (username must be alphanumeric)';
};

subtest 'host parameter — invalid partition: path traversal' => sub {
	plan tests => 2;
	throws_ok { Database::test1->new(host => '../../etc',      directory => $DIR) }
		$ERR_UNSAFE_HOST, 'host: path traversal ../ rejected';
	throws_ok { Database::test1->new(host => '/etc/passwd',    directory => $DIR) }
		$ERR_UNSAFE_HOST, 'host: absolute path rejected';
};

# -----------------------------------------------------------------------
# SECTION 4: url parameter
# Must match /\Ahttps?:\/\//i
# Valid:   http:// and https:// schemes
# Invalid: ftp://, file://, javascript:, bare hostname, empty string
# -----------------------------------------------------------------------

subtest 'url parameter — valid partition' => sub {
	plan tests => 3;
	# url bypasses file detection; no directory needed.  The actual fetch is
	# lazy so we only test that construction lives.
	lives_ok { Database::test1->new(url => 'http://example.com/data.html') }
		'url: http:// scheme accepted';
	lives_ok { Database::test1->new(url => 'https://example.com/data.html') }
		'url: https:// scheme accepted';
	lives_ok { Database::test1->new(url => 'HTTPS://example.com/DATA.HTML') }
		'url: uppercase HTTPS scheme accepted (case-insensitive)';
};

subtest 'url parameter — invalid partition: forbidden schemes' => sub {
	plan tests => 5;
	throws_ok { Database::test1->new(url => 'ftp://example.com/file.csv') }
		$ERR_UNSAFE_URL, 'url: ftp:// scheme rejected';
	throws_ok { Database::test1->new(url => 'file:///etc/passwd') }
		$ERR_UNSAFE_URL, 'url: file:// scheme rejected';
	throws_ok { Database::test1->new(url => 'javascript:alert(1)') }
		$ERR_UNSAFE_URL, 'url: javascript: scheme rejected';
	throws_ok { Database::test1->new(url => 'redis://localhost') }
		$ERR_UNSAFE_URL, 'url: redis:// scheme rejected as url (use database= instead)';
	throws_ok { Database::test1->new(url => 'example.com/table.html') }
		$ERR_UNSAFE_URL, 'url: bare hostname (no scheme) rejected';
};

subtest 'url parameter — boundary: minimum valid url' => sub {
	plan tests => 1;
	lives_ok { Database::test1->new(url => 'http://x') }
		'url: minimal http://x accepted (length boundary)';
};

# -----------------------------------------------------------------------
# SECTION 5: database parameter
# Must match /\Aredis:\/\//i
# Valid:   redis:// scheme
# Invalid: http://, postgres://, bare hostname
# -----------------------------------------------------------------------

subtest 'database parameter — valid partition' => sub {
	plan tests => 3;
	lives_ok { Database::test1->new(database => 'redis://localhost') }
		'database: redis://host accepted';
	lives_ok { Database::test1->new(database => 'redis://localhost:6379/0') }
		'database: redis://host:port/db accepted';
	lives_ok { Database::test1->new(database => 'REDIS://localhost') }
		'database: uppercase REDIS accepted (case-insensitive)';
};

subtest 'database parameter — invalid partition: wrong schemes' => sub {
	plan tests => 4;
	throws_ok { Database::test1->new(database => 'http://localhost') }
		$ERR_UNSAFE_DB, 'database: http:// rejected';
	throws_ok { Database::test1->new(database => 'postgres://localhost/mydb') }
		$ERR_UNSAFE_DB, 'database: postgres:// rejected';
	throws_ok { Database::test1->new(database => 'localhost:6379') }
		$ERR_UNSAFE_DB, 'database: bare host:port rejected';
	throws_ok { Database::test1->new(database => 'file:///data/db') }
		$ERR_UNSAFE_DB, 'database: file:// rejected';
};

# -----------------------------------------------------------------------
# SECTION 6: base_criteria parameter
# Must be a hashref; keys must match $SAFE_QUALIFIED or start with '-'
# -----------------------------------------------------------------------

subtest 'base_criteria — valid partition: hashref with safe keys' => sub {
	plan tests => 4;
	lives_ok { _db(base_criteria => { number => '1' }) }
		'base_criteria: simple scalar criterion accepted';
	lives_ok { _db(base_criteria => { 't.col' => '1' }) }
		'base_criteria: qualified table.column key accepted';
	lives_ok { _db(base_criteria => { '-or' => [{ number => 1 }] }) }
		'base_criteria: -or grouping key accepted';
	lives_ok { _db(base_criteria => { '-and' => [{ number => 1 }] }) }
		'base_criteria: -and grouping key accepted';
};

subtest 'base_criteria — boundary: empty hashref' => sub {
	plan tests => 1;
	lives_ok { _db(base_criteria => {}) }
		'base_criteria: empty hashref accepted (no-op filter)';
};

subtest 'base_criteria — invalid partition: not a hashref' => sub {
	plan tests => 3;
	throws_ok { _db(base_criteria => 'active') }
		$ERR_BC_HASHREF, 'base_criteria: plain string rejected';
	throws_ok { _db(base_criteria => ['active']) }
		$ERR_BC_HASHREF, 'base_criteria: arrayref rejected';
	throws_ok { _db(base_criteria => 1) }
		$ERR_BC_HASHREF, 'base_criteria: integer rejected';
	# undef is silently accepted as "no filter" — not a rejection case
};

subtest 'base_criteria — invalid partition: unsafe keys' => sub {
	plan tests => 4;
	throws_ok { _db(base_criteria => { '1bad' => 'v' }) }
		$ERR_BC_KEY, 'base_criteria: key starting with digit rejected';
	throws_ok { _db(base_criteria => { 'col; DROP' => 'v' }) }
		$ERR_BC_KEY, 'base_criteria: semicolon in key rejected';
	throws_ok { _db(base_criteria => { "col\0" => 'v' }) }
		$ERR_BC_KEY, 'base_criteria: null byte in key rejected';
	throws_ok { _db(base_criteria => { "\x{fc}col" => 'v' }) }
		$ERR_BC_KEY, 'base_criteria: non-ASCII key rejected';
};

# -----------------------------------------------------------------------
# SECTION 7: redis_key parameter
# Only valid when database is a redis:// URL
# -----------------------------------------------------------------------

subtest 'redis_key — valid only with redis:// database' => sub {
	plan tests => 2;
	lives_ok {
		Database::test1->new(database => 'redis://localhost', redis_key => 'users')
	} 'redis_key: accepted alongside redis:// database';

	throws_ok {
		Database::test1->new(directory => $DIR, redis_key => 'users')
	} $ERR_REDIS_KEY, 'redis_key: rejected when database is not set';
};

# -----------------------------------------------------------------------
# SECTION 8: limit / offset — selectall_arrayref
# Valid:   non-negative integer (0, 1, N)
# Invalid: negative, fractional, non-numeric string
# Behaviour: carp + ignore (not croak)
# Boundaries: 0 (empty result), 1 (one row), TOTAL-1, TOTAL, TOTAL+1
# -----------------------------------------------------------------------

subtest 'limit — valid partition and BVA' => sub {
	plan tests => 5;
	my $db = _db();

	my $r0 = $db->selectall_arrayref(limit => 0);
	is(scalar @{$r0}, 0, 'limit => 0: returns empty arrayref (boundary: minimum)');

	my $r1 = $db->selectall_arrayref(limit => 1);
	is(scalar @{$r1}, 1, 'limit => 1: returns exactly 1 row');

	my $rm1 = $db->selectall_arrayref(limit => $TOTAL_ROWS - 1);
	is(scalar @{$rm1}, $TOTAL_ROWS - 1, 'limit => TOTAL-1: returns N-1 rows (just-below-max BVA)');

	my $rn = $db->selectall_arrayref(limit => $TOTAL_ROWS);
	is(scalar @{$rn}, $TOTAL_ROWS, 'limit => TOTAL: returns all rows (at-max BVA)');

	my $rp = $db->selectall_arrayref(limit => $TOTAL_ROWS + 1);
	is(scalar @{$rp}, $TOTAL_ROWS, 'limit => TOTAL+1: returns all rows (past-max BVA, no padding)');
};

subtest 'limit — invalid partition: non-integer values (carp, ignore)' => sub {
	plan tests => 6;
	my $db = _db();

	warning_like {
		my $r = $db->selectall_arrayref(limit => -1);
		is(scalar @{$r}, $TOTAL_ROWS, '  negative limit ignored: full result returned');
	} qr/limit must be a non-negative integer/, 'limit => -1: carp emitted';

	warning_like {
		my $r = $db->selectall_arrayref(limit => '2.5');
		is(scalar @{$r}, $TOTAL_ROWS, '  fractional limit ignored: full result returned');
	} qr/limit must be a non-negative integer/, 'limit => "2.5": carp emitted';

	warning_like {
		my $r = $db->selectall_arrayref(limit => 'abc');
		is(scalar @{$r}, $TOTAL_ROWS, '  string limit ignored: full result returned');
	} qr/limit must be a non-negative integer/, 'limit => "abc": carp emitted';
};

subtest 'offset — valid partition and BVA' => sub {
	plan tests => 4;
	my $db = _db();

	my $r0 = $db->selectall_arrayref(offset => 0);
	is(scalar @{$r0}, $TOTAL_ROWS, 'offset => 0: full result (no rows skipped)');

	my $r1 = $db->selectall_arrayref(offset => 1);
	is(scalar @{$r1}, $TOTAL_ROWS - 1, 'offset => 1: one row skipped');

	my $rn = $db->selectall_arrayref(offset => $TOTAL_ROWS);
	is(scalar @{$rn}, 0, 'offset => TOTAL: all rows skipped (at-max boundary)');

	my $rp = $db->selectall_arrayref(offset => $TOTAL_ROWS + 1);
	is(scalar @{$rp}, 0, 'offset => TOTAL+1: empty (past-max boundary)');
};

subtest 'offset — invalid partition: non-integer (carp, ignore)' => sub {
	plan tests => 4;
	my $db = _db();

	warning_like {
		my $r = $db->selectall_arrayref(offset => -3);
		is(scalar @{$r}, $TOTAL_ROWS, '  negative offset ignored');
	} qr/offset must be a non-negative integer/, 'offset => -3: carp emitted';

	warning_like {
		my $r = $db->selectall_arrayref(offset => 'start');
		is(scalar @{$r}, $TOTAL_ROWS, '  string offset ignored');
	} qr/offset must be a non-negative integer/, 'offset => "start": carp emitted';
};

subtest 'limit+offset combinatorial boundaries' => sub {
	plan tests => 3;
	my $db = _db();

	# limit at max, offset at minimum
	my $r1 = $db->selectall_arrayref(limit => $TOTAL_ROWS, offset => 0);
	is(scalar @{$r1}, $TOTAL_ROWS, 'limit=TOTAL + offset=0: full result');

	# limit at 1, offset at TOTAL-1 (last row only)
	my $r2 = $db->selectall_arrayref(limit => 1, offset => $TOTAL_ROWS - 1);
	is(scalar @{$r2}, 1, 'limit=1 + offset=TOTAL-1: exactly 1 row (last row)');

	# limit at minimum (0), offset at maximum (past end)
	my $r3 = $db->selectall_arrayref(limit => 0, offset => $TOTAL_ROWS);
	is(scalar @{$r3}, 0, 'limit=0 + offset=TOTAL: empty (both at boundary)');
};

# -----------------------------------------------------------------------
# SECTION 9: sort_by parameter
# Valid:   scalar column name, [$col, 'ASC'], [$col, 'DESC'] (case-insensitive)
# Invalid: unsafe column name, unknown direction
# Behaviour on invalid: carp + fall back to default sort
# -----------------------------------------------------------------------

subtest 'sort_by — valid partition' => sub {
	plan tests => 4;
	my $db = _db();

	lives_ok { $db->selectall_arrayref(sort_by => 'number') }
		'sort_by: scalar column name accepted';
	lives_ok { $db->selectall_arrayref(sort_by => ['number', 'ASC']) }
		'sort_by: [col, ASC] arrayref accepted';
	lives_ok { $db->selectall_arrayref(sort_by => ['number', 'DESC']) }
		'sort_by: [col, DESC] arrayref accepted';
	lives_ok { $db->selectall_arrayref(sort_by => ['number', 'asc']) }
		'sort_by: lowercase direction "asc" accepted (case-normalised)';
};

subtest 'sort_by — DESC ordering is actually applied' => sub {
	plan tests => 4;
	my $db = _db();

	my $asc  = $db->selectall_arrayref(sort_by => ['entry', 'ASC']);
	my $desc = $db->selectall_arrayref(sort_by => ['entry', 'DESC']);
	is(scalar @{$asc},  $TOTAL_ROWS, 'sort_by ASC: correct row count');
	is(scalar @{$desc}, $TOTAL_ROWS, 'sort_by DESC: correct row count');
	is($asc->[0]{'entry'},            $desc->[$TOTAL_ROWS - 1]{'entry'}, 'sort_by DESC: first ASC == last DESC');
	is($asc->[$TOTAL_ROWS - 1]{'entry'}, $desc->[0]{'entry'},           'sort_by DESC: last ASC == first DESC');
};

subtest 'sort_by — invalid partition: unsafe column (carp, ignore)' => sub {
	plan tests => 2;
	my $db = _db();

	warning_like {
		my $r = $db->selectall_arrayref(sort_by => 'col; DROP TABLE t');
		is(scalar @{$r}, $TOTAL_ROWS, '  all rows returned despite invalid sort_by');
	} qr/unsafe sort_by column/, 'sort_by with SQL injection: carp emitted';
};

subtest 'sort_by — invalid partition: bad direction (carp, ignore)' => sub {
	plan tests => 2;
	my $db = _db();

	warning_like {
		my $r = $db->selectall_arrayref(sort_by => ['number', 'SIDEWAYS']);
		is(scalar @{$r}, $TOTAL_ROWS, '  all rows returned with fallback sort');
	} qr/invalid sort_by direction/, 'sort_by direction "SIDEWAYS": carp emitted';
};

subtest 'sort_by — boundary: undef (no sort specified)' => sub {
	plan tests => 1;
	my $db = _db();
	lives_ok { $db->selectall_arrayref(sort_by => undef) }
		'sort_by => undef: treated as no sort (no error)';
};

subtest 'sort_by + limit combinatorial' => sub {
	plan tests => 2;
	my $db = _db();

	# DESC + limit 1 must return the largest entry alphabetically
	# test1.csv entries: empty, one, three, two -- "two" is lexically last
	my $r = $db->selectall_arrayref(sort_by => ['entry', 'DESC'], limit => 1);
	is(scalar @{$r}, 1, 'sort_by DESC + limit 1: exactly one row returned');
	is($r->[0]{'entry'}, 'two', 'sort_by DESC + limit 1: "two" is lexically last');
};

# -----------------------------------------------------------------------
# SECTION 10: columns parameter — selectall_arrayref
# Valid:   arrayref of SAFE_QUALIFIED strings
# Invalid: not an arrayref, unsafe column name, undef elements (dropped)
# Behaviour on invalid: carp + ignore
# -----------------------------------------------------------------------

subtest 'columns — valid partition' => sub {
	plan tests => 3;
	my $db = _db();

	my $r = $db->selectall_arrayref(columns => ['entry']);
	ok(exists $r->[0]{'entry'},   'columns: requested column "entry" present in result');
	ok(!exists $r->[0]{'number'}, 'columns: unrequested column "number" absent from result');

	my $r2 = $db->selectall_arrayref(columns => ['entry', 'number']);
	ok(exists $r2->[0]{'number'}, 'columns: both columns present when both requested');
};

subtest 'columns — invalid partition: not an arrayref (carp, ignore)' => sub {
	plan tests => 2;
	my $db = _db();

	warning_like {
		my $r = $db->selectall_arrayref(columns => 'entry');
		ok(exists $r->[0]{'entry'} && exists $r->[0]{'number'},
			'  all columns present when columns param is ignored');
	} qr/columns must be an arrayref/, 'columns => "entry" (string): carp emitted';
};

subtest 'columns — invalid partition: unsafe column name in list (carp, ignore)' => sub {
	plan tests => 2;
	my $db = _db();

	warning_like {
		my $r = $db->selectall_arrayref(columns => ['entry; DROP TABLE t']);
		ok(scalar @{$r} == $TOTAL_ROWS, '  rows still returned after bad column name ignored');
	} qr/unsafe column name/, 'columns: SQL injection in column name: carp emitted';
};

subtest 'columns — boundary: empty arrayref' => sub {
	plan tests => 1;
	my $db = _db();
	# Empty arrayref: no column projection applied (all columns returned)
	my $r = $db->selectall_arrayref(columns => []);
	ok(scalar @{$r} == $TOTAL_ROWS, 'columns => []: all rows returned (no projection)');
};

# -----------------------------------------------------------------------
# SECTION 11: join parameter — _build_joins validation
# Valid:   { table => 'T', on => 'condition', type => 'INNER' }
# Invalid: missing table, missing on, unsafe table, invalid type
# -----------------------------------------------------------------------

subtest 'join — invalid partition: missing required fields' => sub {
	plan tests => 2;
	my $db = _db();
	# _build_joins is called from selectall_arrayref; force the SQL path
	throws_ok {
		$db->selectall_arrayref(
			max_slurp_size => 0,
			join => { on => 'test1.entry = other.entry' }
		)
	} $ERR_JOIN_TABLE, 'join: missing "table" field: croak';

	throws_ok {
		$db->selectall_arrayref(
			max_slurp_size => 0,
			join => { table => 'other' }
		)
	} $ERR_JOIN_ON, 'join: missing "on" field: croak';
};

subtest 'join — invalid partition: unsafe table name' => sub {
	plan tests => 2;
	my $db = _db();
	throws_ok {
		$db->selectall_arrayref(
			max_slurp_size => 0,
			join => { table => 'other; DROP TABLE test1', on => 'a = b' }
		)
	} $ERR_JOIN_UNSAFE, 'join: SQL injection in table name: croak';

	throws_ok {
		$db->selectall_arrayref(
			max_slurp_size => 0,
			join => { table => '1bad', on => 'a = b' }
		)
	} $ERR_JOIN_UNSAFE, 'join: digit-start table name: croak';
};

subtest 'join — invalid partition: unknown type' => sub {
	plan tests => 2;
	my $db = _db();
	throws_ok {
		$db->selectall_arrayref(
			max_slurp_size => 0,
			join => { table => 'other', on => 'a = b', type => 'OUTER' }
		)
	} $ERR_JOIN_TYPE, 'join: type "OUTER" rejected';

	throws_ok {
		$db->selectall_arrayref(
			max_slurp_size => 0,
			join => { table => 'other', on => 'a = b', type => '' }
		)
	} $ERR_JOIN_TYPE, 'join: empty type rejected';
};

subtest 'join — valid partition: all five type keywords (case-insensitive)' => sub {
	plan tests => 5;
	my $db = _db();
	# We just test that _build_joins does not croak on type normalisation;
	# the DBI connect will croak on a missing join table, which is expected.
	for my $type (qw(INNER LEFT RIGHT FULL CROSS)) {
		my $err = '';
		eval {
			$db->selectall_arrayref(
				max_slurp_size => 0,
				join => { table => 'nonexistent', on => 'a = b', type => $type }
			);
		};
		$err = $@;
		unlike($err, $ERR_JOIN_TYPE, "join: type '$type' accepted by validator");
	}
};

# -----------------------------------------------------------------------
# SECTION 12: each_row callback parameter
# Valid:   code reference
# Invalid: string, undef, hashref, arrayref
# -----------------------------------------------------------------------

subtest 'each_row — valid partition: code reference' => sub {
	plan tests => 2;
	my $db  = _db();
	my $cnt = 0;
	lives_ok { $db->each_row(sub { $cnt++ }) }
		'each_row: code reference accepted';
	is($cnt, $TOTAL_ROWS, 'each_row: callback invoked once per row');
};

subtest 'each_row — invalid partition: non-code-ref callback' => sub {
	plan tests => 4;
	my $db = _db();
	throws_ok { $db->each_row('not_a_coderef') }   $ERR_CALLBACK, 'each_row: string rejected';
	throws_ok { $db->each_row(undef) }              $ERR_CALLBACK, 'each_row: undef rejected';
	throws_ok { $db->each_row({ code => sub{} }) }  $ERR_CALLBACK, 'each_row: hashref rejected';
	throws_ok { $db->each_row([sub{}]) }             $ERR_CALLBACK, 'each_row: arrayref rejected';
};

# -----------------------------------------------------------------------
# SECTION 13: max_slurp_size — slurp vs SQL path boundary
# Default: 16384 (16 KB).  0 forces SQL path.
# Boundary: file_size - 1 (slurp), file_size (slurp), file_size + 1 (SQL)
# -----------------------------------------------------------------------

subtest 'max_slurp_size — boundary: 0 forces SQL path (no type set)' => sub {
	plan tests => 2;
	# With max_slurp_size => 0, the module uses DBI/CSV instead of in-memory
	my $db_sql = _db(max_slurp_size => 0);
	my $r = $db_sql->selectall_arrayref();
	ok(ref $r eq 'ARRAY', 'max_slurp_size => 0: query succeeds on SQL path');
	is(scalar @{$r}, $TOTAL_ROWS, 'max_slurp_size => 0: correct row count from SQL path');
};

subtest 'max_slurp_size — default: small file is slurped' => sub {
	plan tests => 2;
	my $db_slurp = _db();
	$db_slurp->count();    # trigger open
	ok(defined $db_slurp->{'data'}, 'default max_slurp_size: small file slurped into memory');
	is(scalar keys %{$db_slurp->{'data'}}, $TOTAL_ROWS, 'slurped data has correct row count');
};

subtest 'max_slurp_size — results are equivalent on both paths' => sub {
	plan tests => 1;
	my $db_slurp = _db(max_slurp_size => 16 * 1024);
	my $db_sql   = _db(max_slurp_size => 0);
	my $n_slurp  = $db_slurp->count();
	my $n_sql    = $db_sql->count();
	is($n_slurp, $n_sql, 'count() is identical on slurp and SQL paths');
};

# -----------------------------------------------------------------------
# SECTION 14: filename / dbname — path traversal and safety
# Validated against /^[a-zA-Z0-9_.-]+$/ with explicit '..' rejection.
# -----------------------------------------------------------------------

subtest 'filename — invalid partition: path traversal' => sub {
	plan tests => 3;
	# filename is only validated in _open() (called lazily).
	# Trigger it by calling count() after construction.
	my $db;
	throws_ok {
		$db = Database::test1->new(directory => $DIR, filename => '../../../etc/passwd');
		$db->count();
	} qr/unsafe filename/, 'filename: path traversal ../ rejected';

	throws_ok {
		$db = Database::test1->new(directory => $DIR, filename => '..');
		$db->count();
	} qr/unsafe filename/, 'filename: bare ".." rejected';

	throws_ok {
		$db = Database::test1->new(directory => $DIR, filename => '/etc/passwd');
		$db->count();
	} qr/unsafe filename/, 'filename: absolute path rejected';
};

subtest 'filename — invalid partition: shell characters' => sub {
	plan tests => 2;
	throws_ok {
		my $db = Database::test1->new(directory => $DIR, filename => 'file;rm');
		$db->count();
	} qr/unsafe filename/, 'filename: semicolon rejected';

	throws_ok {
		my $db = Database::test1->new(directory => $DIR, filename => "file\0null");
		$db->count();
	} qr/unsafe filename/, 'filename: null byte rejected';
};

subtest 'filename — valid partition: safe names' => sub {
	plan tests => 3;
	lives_ok { my $db = Database::test1->new(directory => $DIR, filename => 'test1.csv'); $db->count() }
		'filename: simple name with dot accepted';
	lives_ok { my $db = Database::test1->new(directory => $DIR, filename => 'test_1.csv'); $db->count() }
		'filename: name with underscore accepted';
	lives_ok { my $db = Database::test1->new(directory => $DIR, filename => 'test-1.csv'); $db->count() }
		'filename: name with hyphen accepted';
};

# -----------------------------------------------------------------------
# SECTION 15: Multibyte data values
# Non-ASCII is forbidden in IDENTIFIERS (id, table, column names).
# Non-ASCII in DATA VALUES must pass through without corruption.
# -----------------------------------------------------------------------

subtest 'multibyte — identifiers: non-ASCII rejected in all identifier positions' => sub {
	plan tests => 5;
	# id parameter
	throws_ok { _db(id => "\x{fc}mlaut") }
		$ERR_UNSAFE_ID, 'multibyte: umlaut in id rejected';
	# table parameter
	throws_ok { _db(table => "caf\x{e9}") }
		$ERR_UNSAFE_TABLE, 'multibyte: accented char in table rejected';
	# base_criteria key
	throws_ok { _db(base_criteria => { "\x{263a}smile" => 1 }) }
		$ERR_BC_KEY, 'multibyte: emoji in base_criteria key rejected';
	# join table name
	my $db = _db();
	throws_ok {
		$db->selectall_arrayref(
			no_entry => 1,
			max_slurp_size => 0,
			join => { table => "tabl\x{e9}", on => 'a = b' }
		)
	} $ERR_JOIN_UNSAFE, 'multibyte: accented char in join table rejected';
	# sort_by column
	warning_like {
		$db->selectall_arrayref(sort_by => "\x{e9}col")
	} qr/unsafe sort_by column/, 'multibyte: accented char in sort_by: carp emitted';
};

subtest 'multibyte — data values: non-ASCII survives round-trip via CSV slurp' => sub {
	# Write a temp CSV with UTF-8 encoded non-ASCII values, slurp via the CSV
	# backend, and verify no characters are dropped or corrupted.
	# Text::xSV::Slurp decodes UTF-8, so we compare Perl character strings.
	use Encode qw(encode_utf8);

	my $cafe  = "caf\x{e9}";                                 # é  U+00E9
	my $emoji = "\x{1f600}";                                  # 😀 U+1F600
	my $zalgo = "Z\x{0300}\x{0301}\x{0302}alg\x{0303}o";     # combining diacritics

	my ($fh, $tmpcsv) = tempfile(SUFFIX => '.csv', UNLINK => 1);
	binmode $fh, ':utf8';
	print $fh "entry!val\n";
	print $fh "cafe!$cafe\n";
	print $fh "emoji!$emoji\n";
	print $fh "zalgo!$zalgo\n";
	close $fh;

	{
		package Database::domain_mb;
		use Database::Abstraction;
		our @ISA = ('Database::Abstraction');
	}

	my ($vol, $dirs, $base) = File::Spec->splitpath($tmpcsv);
	my $tmpdir_abs = File::Spec->catpath($vol, $dirs, '');
	$tmpdir_abs =~ s{[\\/]+$}{};
	(my $dbname_short = $base) =~ s/\.csv$//;

	plan tests => 4;
	my $db;
	lives_ok {
		$db = Database::domain_mb->new(
			directory => $tmpdir_abs,
			dbname    => $dbname_short,
		);
	} 'multibyte data: CSV construction lives';

	my $r_cafe = $db->fetchrow_hashref('cafe');
	is($r_cafe->{'val'}, $cafe,
		'multibyte data: Latin-1 accent survives CSV round-trip');

	my $r_emoji = $db->fetchrow_hashref('emoji');
	is($r_emoji->{'val'}, $emoji,
		'multibyte data: emoji survives CSV round-trip');

	my $r_zalgo = $db->fetchrow_hashref('zalgo');
	is($r_zalgo->{'val'}, $zalgo,
		'multibyte data: Zalgo text (combining diacritics) survives CSV round-trip');
};

subtest 'multibyte — data values in criteria: scalar value match' => sub {
	plan tests => 2;
	# Slurp path: non-ASCII in VALUES is fine; SQL uses bind params
	my ($fh, $tmpdb) = tempfile(SUFFIX => '.sqlite', UNLINK => 1);
	close $fh;

	my $dbh = DBI->connect("dbi:SQLite:dbname=$tmpdb", '', '',
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE domain_val (entry TEXT PRIMARY KEY, name TEXT)');
	my $umlaut = "K\x{f6}ln";      # Köln
	$dbh->do('INSERT INTO domain_val VALUES (?,?)', {}, 'city1', $umlaut);
	$dbh->do('INSERT INTO domain_val VALUES (?,?)', {}, 'city2', 'Berlin');
	$dbh->disconnect();

	{
		package Database::domain_val;
		use Database::Abstraction;
		our @ISA = ('Database::Abstraction');
	}

	my $db = Database::domain_val->new(dsn => "dbi:SQLite:dbname=$tmpdb");
	my $r = $db->selectall_arrayref(name => $umlaut);
	is(scalar @{$r}, 1, "multibyte data: criterion with umlaut value matches 1 row");
	is($r->[0]{'entry'}, 'city1', "multibyte data: correct row returned for umlaut criterion");
};

done_testing;
