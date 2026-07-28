#!/usr/bin/perl

=head1 NAME

t/cgi_security.t - Penetration tests for Database::Abstraction in a CGI/web context

=head1 SYNOPSIS

    prove -l t/cgi_security.t

=head1 DESCRIPTION

Simulates hostile HTTP-parameter inputs being passed to C<Database::Abstraction>
as would occur when the module is consumed by a CGI or web application layer.

Each subtest uses C<local %ENV> to establish an adversarial HTTP-request
context (setting C<QUERY_STRING>, C<HTTP_USER_AGENT>, C<HTTP_COOKIE>, etc.)
and then feeds the weaponised payload into the security-critical parameter path
being exercised.

=head2 Attack Vectors Covered

=over 4

=item * B<SEC1> — SQL injection via column B<values> (DBI bind-parameter defence)

=item * B<SEC2> — SQL injection via the C<id> constructor parameter

=item * B<SEC3> — Path traversal / SQL injection via C<dbname> and C<filename>

=item * B<SEC4> — SQL injection via join C<table> names

=item * B<SEC5> — Operator-hash value injection (C<-in>, C<-between>, C<-like>, etc.)

=item * B<SEC6> — ReDoS via C<-like> / C<-not_like> patterns (slurp DP matcher)

=item * B<SEC7> — AUTOLOAD private-method bypass attempts

=item * B<SEC8> — Null-byte injection across constructor and query parameters

=item * B<SEC9> — CRLF injection in security-critical string contexts

=item * B<SEC10> — Very-long-input resilience (no hang / crash)

=item * B<SEC11> — Query-builder chaining with hostile inputs

=item * B<SEC12> — DSN hostile content (driver and path abuse)

=back

=head3 API SPECIFICATION

=head4 Input (simulated HTTP context)

The module is invoked as if by a CGI layer:

    $db = Database::Foo->new(
        directory => $ENV{DB_DIR},     # validated: directory must exist
        id        => $ENV{ID_COL},     # validated: /^[a-zA-Z_][a-zA-Z0-9_]*$/
    );
    $db->selectall_arrayref(
        $ENV{QUERY_COL} => $ENV{QUERY_VAL},  # col name validated; value bound
    );

=head4 Output

Each subtest asserts one of:

=over 4

=item * The module croaks with a specific security message before reaching the DB.

=item * The query returns an empty or correct result set (injection produced no extra rows).

=item * The process does not crash or hang (ReDoS / null-byte resilience).

=back

=head3 FORMAL SPECIFICATION

Let I = untrusted input string, V = set of valid identifiers, P = parameterized.

Security invariants:

  ∀ col ∈ criteria_keys : col ∉ V ⟹ croak("unsafe column name")
  ∀ v   ∈ criteria_vals : result(query(P(v))) ≡ result(query(literal(v)))
  ∀ f   ∈ {dbname,filename} : f ∉ /^[a-zA-Z0-9_.-]+$/ ∨ f =~ /\.\./ ⟹ croak("unsafe")
  ∀ p   ∈ -like_patterns : time(DP_match(p, s)) ∈ O(|p|·|s|)   [ReDoS-safe]

=cut

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Test::Most;
use Time::HiRes qw(gettimeofday tv_interval);

eval { require DBI; require DBD::SQLite };
my $HAVE_SQLITE = !$@;

use lib 't/lib';
use Database::test1;   # CSV slurp backend, id => 'entry'

my $DATA_DIR = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');

# ---------------------------------------------------------------------------
# Helper: Build a disposable SQLite DB with a (entry TEXT, score INTEGER) table.
# The table name is derived from the last component of $pkg (lowercased) to
# match the table name Database::Abstraction derives from the class name via
#   $table = ref($self); $table =~ s/.*:://;
# Each call creates a fresh file in a tempdir so subtests are isolated.
# ---------------------------------------------------------------------------
sub _make_sqlite_db {
	my ($pkg, %rows) = @_;

	# Derive the table name from the package name, exactly as the module does
	(my $table = $pkg) =~ s/.*:://;
	$table = lc $table;

	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, "${table}.sql");
	my $dsn  = "dbi:SQLite:dbname=$file";

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do("CREATE TABLE $table (entry TEXT PRIMARY KEY, score INTEGER)");
	my $ins = $setup->prepare("INSERT INTO $table VALUES (?,?)");
	while(my ($k, $v) = each %rows) { $ins->execute($k, $v) }
	$setup->disconnect();

	{
		no strict 'refs';
		@{"${pkg}::ISA"} = ('Database::Abstraction');
	}

	# no_entry => 1: all columns are equal-weight criteria; also makes
	# Params::Get use get_params(undef, \@_) so that named pairs like
	# (join => {...}) are parsed correctly and not treated as positional args.
	return $pkg->new(dsn => $dsn, no_entry => 1);
}

# ---------------------------------------------------------------------------
# SEC1: SQL injection via column VALUES (DBI bind-parameter defence)
# ---------------------------------------------------------------------------

subtest 'SEC1: column-value SQL injection is neutralised by DBI bind params' => sub {
	# Attack: classic Boolean-injection and UNION-injection placed in the VALUE
	# side of a criterion.  DBI bind parameters always treat the string as data
	# rather than SQL syntax, so hostile strings must produce 0 rows, not extra
	# rows or table destruction.

	plan skip_all => 'DBD::SQLite required' unless $HAVE_SQLITE;

	local %ENV;
	$ENV{REQUEST_METHOD} = 'GET';
	$ENV{QUERY_STRING}   = "entry=' OR '1'='1";  # simulated hostile GET param

	my $db = _make_sqlite_db('Database::sec1', alice => 10, bob => 20, carol => 30);

	# 1.1 Boolean injection: classic tautology via entry value
	# Exploits naive string interpolation: SELECT … WHERE entry = '' OR '1'='1'
	# Bind params prevent this; the literal string is matched literally (no rows).
	my $rows = $db->selectall_arrayref(entry => "' OR '1'='1");
	is(scalar @{$rows}, 0,
		'SEC1.1 Boolean tautology via entry value returns 0 rows (bind param)');

	# 1.2 Statement-terminator injection: ; DROP TABLE
	my $row = $db->fetchrow_hashref(entry => "'; DROP TABLE sec; --");
	ok(!defined($row),
		'SEC1.2 statement-terminator injection returns undef (bind param)');

	# 1.3 UNION injection via value — must return 0 rows, table must survive
	$rows = $db->selectall_arrayref(
		entry => "' UNION SELECT entry,score FROM sec --");
	is(scalar @{$rows}, 0, 'SEC1.3 UNION injection via value returns 0 rows');

	# 1.4 count() with injection value must return 0, not real row count
	my $cnt = $db->count(entry => "' OR 1=1 --");
	is($cnt, 0,
		'SEC1.4 count() with Boolean injection value returns 0 not 3');

	# 1.5 fetchrow_hashref with injection value
	$row = $db->fetchrow_hashref(entry => "x' OR score > 0 --");
	ok(!defined($row),
		'SEC1.5 fetchrow_hashref Boolean injection returns undef');

	# 1.6 The table must be intact after all injection attempts
	my $all = $db->selectall_arrayref();
	is(scalar @{$all}, 3,
		'SEC1.6 table intact after value-injection attempts (3 rows)');
};

# ---------------------------------------------------------------------------
# SEC2: SQL injection via the `id` constructor parameter
# ---------------------------------------------------------------------------

subtest 'SEC2: hostile id constructor parameter is rejected before DB access' => sub {
	# Attack: an adversary crafts a hostile string as the key-column name (the
	# `id` arg to new()).  The constructor validates id against
	# /^[a-zA-Z_][a-zA-Z0-9_]*$/ and croaks "unsafe id column name" before
	# the object is blessed.

	local %ENV;
	$ENV{REQUEST_METHOD} = 'GET';
	$ENV{QUERY_STRING}   = 'id=entry%3B+DROP+TABLE+test1--';   # hostile id

	{	# Scope to avoid ISA pollution between sub-subtests
		package Database::sec2a;
		use base 'Database::Abstraction';
	}

	# 2.1 Semicolon + SQL keyword — the canonical statement-terminator payload
	throws_ok {
		Database::sec2a->new(directory => $DATA_DIR,
			id => "entry; DROP TABLE test1--")
	} qr/unsafe id column name/i,
	  'SEC2.1 semicolon in id croaks "unsafe id column name"';

	# 2.2 Single-quote injection — would break a quoted identifier
	throws_ok {
		Database::sec2a->new(directory => $DATA_DIR, id => "entry'")
	} qr/unsafe id column name/i,
	  'SEC2.2 single-quote in id croaks';

	# 2.3 UNION keyword injection via id — space not in valid set
	throws_ok {
		Database::sec2a->new(directory => $DATA_DIR, id => 'entry UNION SELECT')
	} qr/unsafe id column name/i,
	  'SEC2.3 UNION keyword in id croaks';

	# 2.4 Null-byte injection — \x00 not in [a-zA-Z0-9_]
	throws_ok {
		Database::sec2a->new(directory => $DATA_DIR, id => "entry\x00injected")
	} qr/unsafe id column name/i,
	  'SEC2.4 null byte in id croaks';

	# 2.5 Double-dash SQL comment suffix
	throws_ok {
		Database::sec2a->new(directory => $DATA_DIR, id => 'entry--')
	} qr/unsafe id column name/i,
	  'SEC2.5 double-dash comment in id croaks';

	# 2.6 CRLF injection — could split HTTP headers if reflected in a CGI error page
	# CR and LF are outside [a-zA-Z_][a-zA-Z0-9_]* so the regex rejects them.
	throws_ok {
		Database::sec2a->new(directory => $DATA_DIR,
			id => "entry\r\nSet-Cookie: sessionid=evil")
	} qr/unsafe id column name/i,
	  'SEC2.6 CRLF in id croaks (CRLF header-split prevention)';

	# 2.7 Backtick command injection (not in valid set)
	throws_ok {
		Database::sec2a->new(directory => $DATA_DIR, id => 'entry`id`')
	} qr/unsafe id column name/i,
	  'SEC2.7 backtick command injection in id croaks';

	# 2.8 A well-formed id must still be accepted after all the above rejections
	{
		package Database::sec2b;
		use base 'Database::Abstraction';
	}
	my $obj;
	lives_ok {
		$obj = Database::sec2b->new(directory => $DATA_DIR, id => 'entry')
	} 'SEC2.8 legitimate id value is accepted by the constructor';
	ok(defined($obj), 'SEC2.8 object is created with valid id');
};

# ---------------------------------------------------------------------------
# SEC3: Path traversal and SQL injection via dbname / filename
# ---------------------------------------------------------------------------

subtest 'SEC3: path traversal and injection via dbname / filename' => sub {
	# Attack: supply a hostile path as dbname / filename to open a sensitive
	# system file as a "database" (path traversal), or to inject SQL via a
	# crafted string that reaches the DBI DSN (SQLite file path injection).
	#
	# Guard in _open(): $dbname =~ /^[a-zA-Z0-9_.-]+$/ && $dbname !~ /\.\./
	# This rejects: slash, null byte, shell metacharacters, CRLF, and ".." sequences.

	local %ENV;
	$ENV{REQUEST_METHOD} = 'GET';
	$ENV{QUERY_STRING}   = 'db=..%2F..%2Fetc%2Fpasswd';

	{
		package Database::sec3;
		use base 'Database::Abstraction';
	}

	# 3.1 Classic dotted path traversal (contains '/') — rejected by regex
	throws_ok {
		my $db = Database::sec3->new(directory => $DATA_DIR,
			dbname => '../../etc/passwd');
		$db->count();
	} qr/unsafe dbname/i,
	  'SEC3.1 ../../../etc/passwd in dbname croaks "unsafe dbname"';

	# 3.2 Double-dot alone — explicitly rejected by !~ /\.\./
	throws_ok {
		my $db = Database::sec3->new(directory => $DATA_DIR, dbname => 'test1..');
		$db->count();
	} qr/unsafe dbname/i,
	  'SEC3.2 trailing ".." in dbname croaks';

	# 3.3 Null byte in dbname — terminates C string on older Perl / OS
	# \x00 is not in [a-zA-Z0-9_.-] so the regex rejects it.
	throws_ok {
		my $db = Database::sec3->new(directory => $DATA_DIR,
			dbname => "test1\x00.sql");
		$db->count();
	} qr/unsafe dbname/i,
	  'SEC3.3 null byte in dbname croaks';

	# 3.4 Shell metacharacters in dbname — ; not in valid set
	throws_ok {
		my $db = Database::sec3->new(directory => $DATA_DIR,
			dbname => 'test1;rm -rf /');
		$db->count();
	} qr/unsafe dbname/i,
	  'SEC3.4 shell metacharacters in dbname croak';

	# 3.5 CRLF in dbname — could inject HTTP response headers if reflected
	throws_ok {
		my $db = Database::sec3->new(directory => $DATA_DIR,
			dbname => "test1\r\nX-Inject: evil");
		$db->count();
	} qr/unsafe dbname/i,
	  'SEC3.5 CRLF in dbname croaks (HTTP header-split prevention)';

	# 3.6 Backtick command injection in dbname
	throws_ok {
		my $db = Database::sec3->new(directory => $DATA_DIR,
			dbname => '`id`');
		$db->count();
	} qr/unsafe dbname/i,
	  'SEC3.6 backtick injection in dbname croaks';

	# 3.7 Absolute path (contains '/') — rejected by character class
	throws_ok {
		my $db = Database::sec3->new(directory => $DATA_DIR,
			dbname => '/etc/passwd');
		$db->count();
	} qr/unsafe dbname/i,
	  'SEC3.7 absolute path /etc/passwd as dbname croaks';

	# 3.8 Percent-encoded slash — not URL-decoded by the module; '%' not in set
	throws_ok {
		my $db = Database::sec3->new(directory => $DATA_DIR,
			dbname => '..%2Fetc%2Fpasswd');
		$db->count();
	} qr/unsafe dbname/i,
	  'SEC3.8 percent-encoded path traversal in dbname croaks';

	# 3.9 filename parameter with path traversal
	throws_ok {
		my $db = Database::sec3->new(directory => $DATA_DIR,
			filename => '../../etc/passwd');
		$db->count();
	} qr/unsafe filename/i,
	  'SEC3.9 path traversal in filename param croaks "unsafe filename"';

	# 3.10 A safe dbname must still be accepted (confirms guard is correctly gated).
	# Create a minimal CSV fixture in a tempdir so the open succeeds.
	{
		my $tmpdir = tempdir(CLEANUP => 1);
		open(my $fh, '>', File::Spec->catfile($tmpdir, 'sec3.csv'))
			or die "Cannot create fixture: $!";
		print $fh "entry!val\none!x\n";
		close $fh;

		my $db = Database::sec3->new(directory => $tmpdir);
		my $n;
		lives_ok { $n = $db->count() }
			'SEC3.10 default safe dbname is accepted';
	}
};

# ---------------------------------------------------------------------------
# SEC4: SQL injection via join table name
# ---------------------------------------------------------------------------

subtest 'SEC4: hostile join table name is rejected before SQL construction' => sub {
	# Attack: an adversary supplies a hostile string as the join "table" field.
	# _build_joins() validates against /^[a-zA-Z_][a-zA-Z0-9_.]*$/ and croaks
	# "join: unsafe table name" before any SQL is built.

	plan skip_all => 'DBD::SQLite required' unless $HAVE_SQLITE;

	local %ENV;
	$ENV{REQUEST_METHOD} = 'POST';
	$ENV{HTTP_X_JOIN_TABLE} = 'real_table; DROP TABLE real_table--';

	my $db = _make_sqlite_db('Database::sec4', alice => 10);

	# 4.1 Semicolon / statement-terminator injection in table name
	throws_ok {
		$db->selectall_arrayref(join => {
			table => 'real_table; DROP TABLE real_table--',
			on    => 'a.entry = b.entry',
		})
	} qr/unsafe table name/i,
	  'SEC4.1 semicolon in join table name croaks "join: unsafe table name"';

	# 4.2 UNION injection — space not in valid set
	throws_ok {
		$db->selectall_arrayref(join => {
			table => 'real_table UNION SELECT 1',
			on    => 'a.entry = b.entry',
		})
	} qr/unsafe table name/i,
	  'SEC4.2 UNION keyword in join table name croaks';

	# 4.3 Single-quote injection — ' not in valid set
	throws_ok {
		$db->selectall_arrayref(join => {
			table => "real_table'",
			on    => 'a.entry = b.entry',
		})
	} qr/unsafe table name/i,
	  "SEC4.3 single-quote in join table name croaks";

	# 4.4 Null byte injection — \x00 not in valid set
	throws_ok {
		$db->selectall_arrayref(join => {
			table => "real_table\x00evil",
			on    => 'a.entry = b.entry',
		})
	} qr/unsafe table name/i,
	  'SEC4.4 null byte in join table name croaks';

	# 4.5 Hyphen in table name — '-' not in valid set
	throws_ok {
		$db->selectall_arrayref(join => {
			table => 'real-table',
			on    => 'a.entry = b.entry',
		})
	} qr/unsafe table name/i,
	  'SEC4.5 hyphen in join table name croaks';

	# 4.6 CRLF injection in table name
	throws_ok {
		$db->selectall_arrayref(join => {
			table => "sec\r\nX-Inject: evil",
			on    => 'a.entry = b.entry',
		})
	} qr/unsafe table name/i,
	  'SEC4.6 CRLF in join table name croaks (header-split prevention)';

	# 4.7 schema.table dotted notation passes the guard (dot is valid)
	# It will ultimately fail because the table does not exist — we only care
	# that it does NOT croak "unsafe table name".
	eval {
		$db->selectall_arrayref(join => {
			table => 'schema.tablename',
			on    => 'sec.entry = schema.tablename.entry',
		})
	};
	unlike($@ // '',
		qr/unsafe table name/i,
		'SEC4.7 schema.table dotted notation passes the injection guard');
};

# ---------------------------------------------------------------------------
# SEC5: Operator-hash value injection (-in, -not_in, -between, -like, !=)
# ---------------------------------------------------------------------------

subtest 'SEC5: operator-hash value injection is neutralised by bind params' => sub {
	# Attack: hostile SQL is placed inside operator-hash value arrays (-in, -not_in,
	# -between) or string values (-like, !=, >).  Because _build_where_conditions()
	# always uses bind parameters for values, the SQL is treated as literal data
	# and produces 0 rows, not extra rows.

	plan skip_all => 'DBD::SQLite required' unless $HAVE_SQLITE;

	local %ENV;
	$ENV{REQUEST_METHOD} = 'GET';
	$ENV{QUERY_STRING}   = "score=-1+UNION+SELECT+*+FROM+sec";

	my $db = _make_sqlite_db('Database::sec5', alice => 10, bob => 20, carol => 30);

	# 5.1 -in with Boolean injection payload mixed with a real value
	# Exploit: if the injected string were interpolated, the DB would match all rows.
	# With bind params it is treated as a literal string; only 'alice' matches.
	my $rows = $db->selectall_arrayref(
		entry => { '-in' => ["' OR '1'='1", 'alice'] });
	is(scalar @{$rows}, 1,
		'SEC5.1 -in with injection payload returns only the literal match');
	is($rows->[0]{entry}, 'alice',
		'SEC5.1 -in returns alice, not all rows');

	# 5.2 -not_in with statement-terminator payload: should exclude no real rows
	$rows = $db->selectall_arrayref(
		entry => { '-not_in' => ["'; DROP TABLE sec5;--"] });
	is(scalar @{$rows}, 3,
		'SEC5.2 -not_in with injection string returns all 3 rows (no literal match)');

	# 5.3 -between with injection strings in bounds
	# "0 OR 1=1--" is cast to 0 by SQLite; all scores are > 0, but the cast
	# makes this a string-vs-int comparison that matches nothing.
	$rows = $db->selectall_arrayref(
		score => { '-between' => ["0 OR 1=1--", 100] });
	is(scalar @{$rows}, 0,
		'SEC5.3 -between with injection lower bound returns 0 rows (string vs int cast)');

	# 5.4 -like with injection payload — value is a bind param, not interpolated SQL
	$rows = $db->selectall_arrayref(
		entry => { '-like' => "' OR '1'='1" });
	is(scalar @{$rows}, 0,
		"SEC5.4 -like with injection string returns 0 rows (literal data)");

	# 5.5 -not_like with injection — all rows survive because the pattern matches nothing
	$rows = $db->selectall_arrayref(
		entry => { '-not_like' => "' OR 1=1--" });
	is(scalar @{$rows}, 3,
		'SEC5.5 -not_like with injection returns all 3 rows (no literal match)');

	# 5.6 != with Boolean injection — comparison is literal, not SQL
	$rows = $db->selectall_arrayref(
		entry => { '!=' => "' OR 1=1--" });
	is(scalar @{$rows}, 3,
		'SEC5.6 != with injection returns all 3 rows (bind param)');

	# 5.7 > operator with injection in value — coerced to numeric 0, no score matches
	$rows = $db->selectall_arrayref(
		score => { '>' => "0; DROP TABLE sec5--" });
	is(scalar @{$rows}, 0,
		'SEC5.7 > with injection value returns 0 rows (string coerced to 0)');

	# 5.8 Table must still be intact after all injection attempts
	my $all = $db->selectall_arrayref();
	is(scalar @{$all}, 3,
		'SEC5.8 table intact after operator-hash injection attempts (3 rows)');
};

# ---------------------------------------------------------------------------
# SEC6: ReDoS via -like / -not_like patterns (slurp DP matcher)
# ---------------------------------------------------------------------------

subtest 'SEC6: catastrophic -like patterns are bounded by the DP matcher (ReDoS-safe)' => sub {
	# Attack: a naive LIKE→regex translation (%→.*, _→.) is vulnerable to
	# catastrophic backtracking.  For example, the pattern %a%a%a%a%a%a%b
	# against a long string of 'a' characters causes exponential backtracking
	# in a regex approach.
	#
	# Database::Abstraction uses an O(m×n) dynamic-programming matcher for the
	# slurp fast-path, so timing must be bounded regardless of pattern shape.
	# These tests assert correctness AND a strict wall-clock upper bound.

	# Build a 200-character string of 'a' — the adversary-controlled haystack
	my $long_a = 'a' x 200;

	# Classic catastrophic LIKE pattern: 20 interleaved wildcards then a 'b'
	# that never appears.  Regex approach: /.*a.*a.*a…b/ → exponential.
	my $evil_pattern = ('%a' x 20) . '%b';

	my $t0 = [gettimeofday];
	my $result = Database::Abstraction::_like_match($long_a, $evil_pattern);
	my $elapsed = tv_interval($t0);

	ok(!$result,
		'SEC6.1 catastrophic LIKE pattern returns false (no match)');
	cmp_ok($elapsed, '<', 1.0,
		'SEC6.1 catastrophic pattern completes in < 1 s (DP is O(m×n))');

	# A second stress pattern: alternating wildcards and literal dots
	my $dotted = ('%.' x 30) . '%z';
	my $haystack2 = 'x' x 150;
	$t0 = [gettimeofday];
	$result = Database::Abstraction::_like_match($haystack2, $dotted);
	$elapsed = tv_interval($t0);

	ok(!$result,
		'SEC6.2 dotted catastrophic pattern returns false (no match)');
	cmp_ok($elapsed, '<', 1.0,
		'SEC6.2 dotted pattern completes in < 1 s');

	# Third pattern: all wildcards — should match anything instantly
	$t0 = [gettimeofday];
	$result = Database::Abstraction::_like_match('hello world', '%' x 50);
	$elapsed = tv_interval($t0);

	ok($result,
		'SEC6.3 all-wildcard pattern matches any string');
	cmp_ok($elapsed, '<', 0.5,
		'SEC6.3 all-wildcard pattern is fast');

	# Sanity: simple %foo% must match and be fast
	$t0 = [gettimeofday];
	$result = Database::Abstraction::_like_match('hello', '%hello%');
	$elapsed = tv_interval($t0);

	ok($result,          'SEC6.4 simple %foo% match returns true');
	cmp_ok($elapsed, '<', 0.1, 'SEC6.4 simple match is fast');
};

# ---------------------------------------------------------------------------
# SEC7: AUTOLOAD private-method bypass prevention
# ---------------------------------------------------------------------------

subtest 'SEC7: AUTOLOAD _ guard prevents private-method name as column lookup' => sub {
	# Attack: an adversary sends a request parameter whose name starts with '_',
	# hoping AUTOLOAD will treat it as a column name and execute an unintended
	# DB query (or worse, dispatch to a private method with crafted arguments).
	#
	# Guard: AUTOLOAD contains "return if($column =~ /^_/);" which causes
	# immediate return (undef) for any _-prefixed name before any DB access.

	local %ENV;
	$ENV{REQUEST_METHOD} = 'GET';
	$ENV{QUERY_STRING}   = 'col=_fixate';   # adversary trying to invoke _fixate

	my $db = Database::test1->new($DATA_DIR);
	$db->count();  # force _open_table() and slurp so AUTOLOAD is reachable

	# 7.1 _nonexistent_column — not defined in module; AUTOLOAD intercepts;
	#     the guard "return if /^_/" fires; no DB query, no croak.
	my $val;
	lives_ok { $val = $db->_nonexistent_security_test_xyz() }
		'SEC7.1 calling _-prefixed nonexistent method via AUTOLOAD does not throw';
	ok(!defined($val),
		'SEC7.1 _-prefixed AUTOLOAD returns undef (not a column lookup)');

	# 7.2 _number — looks like it could be a column name "number" with a _ prefix
	lives_ok { $val = $db->_number() }
		'SEC7.2 _number via AUTOLOAD returns immediately (not treated as column)';
	ok(!defined($val),
		'SEC7.2 _number returns undef');

	# 7.3 _entry — the actual key column name with a _ prefix
	lives_ok { $val = $db->_entry('one') }
		'SEC7.3 _entry via AUTOLOAD returns immediately (not a key column lookup)';
	ok(!defined($val),
		'SEC7.3 _entry returns undef (not the entry value "one")');

	# 7.4 Verify the REAL column lookup still works (guard only blocks _ prefix)
	$val = $db->number('one');
	is($val, 1,
		'SEC7.4 legitimate AUTOLOAD column lookup still works after guard checks');
};

# ---------------------------------------------------------------------------
# SEC8: Null-byte injection across constructor and query parameters
# ---------------------------------------------------------------------------

subtest 'SEC8: null-byte injection is rejected at every security boundary' => sub {
	# Attack: null bytes (\x00) in file paths can truncate C-level strings on
	# older Perl / OS combinations (Perl < 5.20 truncated open() paths at \x00).
	# In column names they fall outside the valid identifier regex.
	# In column values they are passed as bind parameters and treated as data.

	plan skip_all => 'DBD::SQLite required' unless $HAVE_SQLITE;

	local %ENV;
	$ENV{REQUEST_METHOD} = 'GET';
	$ENV{QUERY_STRING}   = "col=entry\x00injected";

	my $db = _make_sqlite_db('Database::sec8', alice => 10, bob => 20);

	# 8.1 Null byte in criteria column name — rejected by identifier guard
	# Exploit: "entry\x00 OR 1=1" might truncate to "entry" on old systems
	# and bypass the guard.  The regex /^[a-zA-Z_][a-zA-Z0-9_.]*$/ rejects \x00.
	throws_ok {
		$db->selectall_arrayref("entry\x00 OR 1=1" => 'alice')
	} qr/unsafe column name/i,
	  'SEC8.1 null byte in criteria column name croaks "unsafe column name"';

	# 8.2 Null byte in column VALUE — treated as literal data by bind param; 0 rows.
	# Perl does not truncate strings at \x00 (unlike C), so the full string
	# "alice\x00evil" is passed to the bind parameter and compared literally.
	my $rows = $db->selectall_arrayref(entry => "alice\x00evil");
	is(scalar @{$rows}, 0,
		'SEC8.2 null byte in column value returns 0 rows (literal bind, no match)');

	# 8.3 Null byte in AUTOLOAD param key (non-entry param)
	throws_ok {
		$db->score("entry\x00" => 'alice')
	} qr/unsafe column name/i,
	  'SEC8.3 null byte in AUTOLOAD param key is rejected by column guard';

	# 8.4 Null byte in dbname — rejected before filesystem access
	{
		package Database::sec8b;
		use base 'Database::Abstraction';
	}
	throws_ok {
		my $x = Database::sec8b->new(directory => $DATA_DIR,
			dbname => "test1\x00.csv");
		$x->count();
	} qr/unsafe dbname/i,
	  'SEC8.4 null byte in dbname croaks "unsafe dbname"';
};

# ---------------------------------------------------------------------------
# SEC9: CRLF injection in security-critical string contexts
# ---------------------------------------------------------------------------

subtest 'SEC9: CRLF injection is rejected in id, column names, and param keys' => sub {
	# Attack: CRLF sequences (\r\n) in the id param or column names could split
	# HTTP response headers if a CGI layer reflects the module's croak message
	# verbatim.  The validation regexes exclude \r and \n, so hostile strings
	# are rejected before any DB access or error message is constructed.

	local %ENV;
	$ENV{REQUEST_METHOD} = 'GET';
	$ENV{HTTP_USER_AGENT} = "Mozilla/5.0\r\nSet-Cookie: sessionid=evil";

	{
		package Database::sec9;
		use base 'Database::Abstraction';
	}

	# 9.1 CRLF in id param — the regex /^[a-zA-Z_][a-zA-Z0-9_]*$/ excludes \r\n
	throws_ok {
		Database::sec9->new(directory => $DATA_DIR,
			id => "entry\r\nSet-Cookie: sessionid=evil")
	} qr/unsafe id column name/i,
	  'SEC9.1 CRLF in id param croaks before the DB (header-split prevention)';

	# 9.2 Bare LF in criteria column name (SQL-backed object — guard fires in
	# _build_where_conditions; slurp path uses in-memory scan without SQL).
	{
		my $db = _make_sqlite_db('Database::sec9b', alice => 10);
		throws_ok {
			$db->selectall_arrayref("entry\nX-Inject: evil" => 'one')
		} qr/unsafe column name/i,
		  'SEC9.2 linefeed in criteria column name croaks (SQL path)';
	}

	# 9.3 CRLF in AUTOLOAD non-entry param key (SQL-backed; data is not slurped
	# so AUTOLOAD takes the SQL branch where the column-safety guard fires).
	{
		my $db = _make_sqlite_db('Database::sec9c', alice => 10);
		throws_ok {
			$db->score("entry\r\nX-Inject: evil" => 'alice')
		} qr/unsafe column name/i,
		  'SEC9.3 CRLF in AUTOLOAD param key croaks (SQL path)';
	}

	# 9.4 CRLF in dbname param
	throws_ok {
		my $db = Database::sec9->new(directory => $DATA_DIR,
			dbname => "test1\r\nX-Inject: evil");
		$db->count();
	} qr/unsafe dbname/i,
	  'SEC9.4 CRLF in dbname param croaks "unsafe dbname"';
};

# ---------------------------------------------------------------------------
# SEC10: Very-long-input resilience (no hang or crash)
# ---------------------------------------------------------------------------

subtest 'SEC10: very long hostile inputs do not hang or crash' => sub {
	# Attack: adversaries send very long strings hoping to trigger a regex
	# engine catastrophic slowdown (the identifier guard uses a simple anchored
	# regex; anchored patterns are safe), excessive memory allocation, or a
	# Perl panic.  The tests assert:
	#   (a) hostile long inputs are rejected promptly (< 2 s) by the guard
	#   (b) very long VALUES are handled as bind params without a crash

	plan skip_all => 'DBD::SQLite required' unless $HAVE_SQLITE;

	local %ENV;
	$ENV{REQUEST_METHOD} = 'GET';
	$ENV{CONTENT_LENGTH}  = '1000000';

	# 10.1 Very long hostile column name with embedded SQL — rejected by guard.
	# Uses a SQL-backed object; the slurp in-memory scan does not validate
	# column names (no SQL is executed), so the test must go through the SQL path.
	my $long_col = 'a' . (';DROP TABLE t;--' x 300);
	my $db = _make_sqlite_db('Database::sec10a', one => 1, two => 2, three => 3);

	my $t0 = [gettimeofday];
	throws_ok {
		$db->selectall_arrayref($long_col => 'one')
	} qr/unsafe column name/i,
	  'SEC10.1 very long hostile column name is rejected by identifier guard (SQL path)';
	cmp_ok(tv_interval($t0), '<', 2.0,
		'SEC10.1 identifier guard rejects 5 KB hostile name in < 2 s');

	# 10.2 Very long column VALUE — passed as bind param; no crash, 0 rows
	my $long_val = ("' UNION SELECT 1--" x 1_000);
	my $rows;
	$t0 = [gettimeofday];
	lives_ok {
		$rows = $db->selectall_arrayref(entry => $long_val)
	} 'SEC10.2 very long injection value does not crash';
	is(scalar @{$rows}, 0,
		'SEC10.2 very long injection value returns 0 rows (bind param)');
	cmp_ok(tv_interval($t0), '<', 5.0,
		'SEC10.2 very long value query completes in < 5 s');

	# 10.3 Very long string in -in array — bind params, no injection, 0 matches.
	# _has_complex_criteria returns true for hashrefs so the SQL path is taken;
	# every item is a bind parameter; result must be 0 rows with no crash.
	my $sqli_item = "' OR 1=1--" x 100;
	my $db_sql = _make_sqlite_db('Database::sec10b', alice => 10, bob => 20);
	$t0 = [gettimeofday];
	lives_ok {
		$rows = $db_sql->selectall_arrayref(
			entry => { '-in' => [($sqli_item) x 10] })
	} 'SEC10.3 very long injection strings in -in do not crash';
	is(scalar @{$rows}, 0,
		'SEC10.3 -in with long injection items returns 0 rows');
	cmp_ok(tv_interval($t0), '<', 5.0,
		'SEC10.3 large -in with injection items completes in < 5 s');
};

# ---------------------------------------------------------------------------
# SEC11: Query-builder chaining with hostile inputs
# ---------------------------------------------------------------------------

subtest 'SEC11: query builder applies the same injection guards as direct methods' => sub {
	# Attack: hostile column names or values are fed through the chained query
	# builder API ($db->query->where(col => val)->all()).  The builder must
	# apply the same _build_where_conditions identifier guard as direct select
	# methods, and must bind values as parameters.

	plan skip_all => 'DBD::SQLite required' unless $HAVE_SQLITE;

	local %ENV;
	$ENV{REQUEST_METHOD}  = 'GET';
	$ENV{QUERY_STRING}    = "col=entry%3B+DROP+TABLE+sec--&val='+OR+1%3D1--";

	my $db = _make_sqlite_db('Database::sec11', alice => 10, bob => 20);

	# 11.1 Hostile column name in where() — must croak "unsafe column name"
	throws_ok {
		$db->query->where("entry; DROP TABLE sec--" => 'alice')->all()
	} qr/unsafe column name/i,
	  'SEC11.1 hostile column name in query->where() croaks';

	# 11.2 Boolean injection in column VALUE via query builder — 0 rows, no throw
	my $rows;
	lives_ok {
		$rows = $db->query->where(entry => "' OR 1=1--")->all()
	} 'SEC11.2 injection value in query->where() does not throw';
	is(scalar @{$rows}, 0,
		'SEC11.2 injection value in query->where() returns 0 rows (bind param)');

	# 11.3 Hostile join table name via query->join() — must croak
	throws_ok {
		$db->query->join({ table => "sec; DROP TABLE sec--",
		                   on    => 'a.entry = b.entry' })->all()
	} qr/unsafe table name/i,
	  'SEC11.3 hostile join table in query->join() croaks';

	# 11.4 Legitimate chained query must still work after the security probes
	lives_ok {
		$rows = $db->query->where(entry => 'alice')->all()
	} 'SEC11.4 legitimate query->where()->all() succeeds after security probes';
	is(scalar @{$rows}, 1,    'SEC11.4 returns 1 row for entry=alice');
	is($rows->[0]{entry}, 'alice', 'SEC11.4 correct row returned');
};

# ---------------------------------------------------------------------------
# SEC12: DSN with hostile content fails safely
# ---------------------------------------------------------------------------

subtest 'SEC12: DSN with hostile content causes a safe error, not silent success' => sub {
	# Attack: an adversary provides a crafted DSN.  The module passes the DSN
	# directly to DBI->connect(); DBI validates the driver prefix and the
	# connection string.  Hostile DSNs must produce a croak from DBI/the module
	# rather than a silent no-op or unexpected behaviour.

	plan skip_all => 'DBD::SQLite required' unless $HAVE_SQLITE;

	local %ENV;
	$ENV{REQUEST_METHOD} = 'GET';
	$ENV{QUERY_STRING}   = 'dsn=dbi%3AHack%3Aevil';

	{
		package Database::sec12;
		use base 'Database::Abstraction';
	}

	# 12.1 Completely bogus DSN driver prefix — DBI cannot load it
	throws_ok {
		my $db = Database::sec12->new(dsn => 'dbi:NonexistentDriver_sec12:dbname=x');
		$db->count();
	} qr/./,
	  'SEC12.1 bogus DSN driver causes a croak, not silent failure';

	# 12.2 DSN pointing at a non-SQLite file — SQLite attempts to open it as a DB.
	#      It is not a valid SQLite file so the query must return 0 rows or throw.
	#      We use a temp file with arbitrary binary content rather than /etc/passwd
	#      to avoid macOS TCC prompts: SQLite's WAL mode tries to create journal
	#      files alongside the target, so pointing at /etc/ triggers an admin dialog.
	{
		my $tmp = File::Temp->new(SUFFIX => '.db', UNLINK => 1);
		print $tmp "NOT A SQLITE DATABASE\x00\x01\x02\x03\n" x 10;
		$tmp->flush();
		my $non_sqlite_path = $tmp->filename();

		my $got_rows = eval {
			my $db = Database::sec12->new(dsn => "dbi:SQLite:dbname=$non_sqlite_path");
			my $r = $db->selectall_arrayref();
			scalar @{$r // []}
		};
		# If it threw (expected) OR returned 0 rows — both are safe outcomes.
		ok(!defined($got_rows) || $got_rows == 0,
			'SEC12.2 DSN pointing at a non-SQLite file returns 0 rows or throws');
	}

	pass('SEC12 completed without Perl crash');
};

done_testing();
