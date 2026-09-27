#!perl -w

# Domain tests: Equivalence Partitioning + Boundary Value Analysis for every
# validated constructor / query / builder parameter in Database::Abstraction.
#
# For each parameter the following partitions are covered:
#   VP  Valid Partition   — representative typical value; system must accept
#   IP  Invalid Partition — representative bad value; system must croak
#   BV  Boundary Value    — absolute min/max edges and the values just outside
#   CB  Combinatorial     — one parameter at its boundary while another varies
#
# Domains analysed:
#   D1   directory          new() positional / named arg
#   D2   id                 primary-key column name (SAFE_IDENTIFIER regex)
#   D3   host               SSH host string (host-regex)
#   D4   url                URL scheme (https?:// only)
#   D5   html_table_index   0-based table index (BV: 0, last-valid, last+1)
#   D6   max_slurp_size     file-size slurp threshold (BV: exact, exact-1, 0)
#   D7   limit              Query::limit() non-negative integer
#   D8   offset             Query::offset() non-negative integer
#   D9   order_by           Query::order_by() injection guard (;, --, /*)
#   D10  join table         _build_joins() SAFE_QUALIFIED table name
#   D11  join type          _build_joins() INNER|LEFT|RIGHT|FULL|CROSS
#   D12  dbname/filename    _open() path-safe name (no .. / /)
#   D13  Combinatorial      max_slurp_size at exact boundary (keyed vs no_entry)
#   D14  sort_by            selectall_arrayref/array sort column+direction
#   D15  base_criteria      constructor filter hashref (key safety, type check)
#   D16  table              constructor table name (SAFE_QUALIFIED)
#   D17  criteria values    scalar/undef/-in/-between/-like/arrayref (invalid)
#   D18  limit/offset       selectall_arrayref direct-method (carp+ignore on bad values)
#   D19  dsn                DSN bypasses file detection (requires DBD::SQLite)
#   D20  non-ASCII          multibyte bytes in criteria values (no crash contract)

use strict;
use warnings;

use FindBin qw($Bin);
use File::Spec;
use File::Temp  ();
use Readonly;
use Test::Most  tests => 112;
use Test::NoWarnings;
use Test::Mockingbird;
use HTTP::Response;

use LWP::UserAgent;
require HTML::TableExtract;

use lib 't/lib';
use Database::test1;
use Database::test4ne;

# ---------------------------------------------------------------------------
# Shared fixture paths and constants
# ---------------------------------------------------------------------------

Readonly my $DATA_DIR => File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
Readonly my $CSV_FILE => File::Spec->catfile($DATA_DIR, 'test1.csv');
Readonly my $CSV_SIZE => (-s $CSV_FILE);	# 83 bytes in the current fixture

# HTML fixture for html_table_index tests (2 tables: 3 rows + 2 rows)
my $HTML_FILE = File::Spec->catfile($DATA_DIR, 'test1.html');
open(my $html_fh, '<', $HTML_FILE) or die "Cannot open $HTML_FILE: $!";
Readonly my $FIXTURE_HTML => do { local $/; <$html_fh> };
close $html_fh;

sub make_ok_response
{
	my $r = HTTP::Response->new(200, 'OK');
	$r->content_type('text/html; charset=UTF-8');
	$r->content($FIXTURE_HTML);
	return $r;
}

# ---------------------------------------------------------------------------
# D1: directory parameter
#
# VP:  an existing, readable directory string or hashref
# IP:  no directory at all, non-existent path, file (not dir)
# ---------------------------------------------------------------------------

note('D1: directory parameter');

# VP1 — bare string form is accepted (the module maps it to directory)
ok(
	eval { Database::test1->new($DATA_DIR); 1 },
	'D1 VP1: bare directory string constructs ok'
);

# VP2 — named hashref form
ok(
	eval { Database::test1->new({ directory => $DATA_DIR }); 1 },
	'D1 VP2: directory as named hashref arg constructs ok'
);

# IP1 — no directory, no dsn, no url → "where are the files?"
throws_ok {
	Database::test1->new({ directory => '' })
} qr/where are the files|is not a directory/i, 'D1 IP1: empty directory string croaks';

# IP2 — non-existent path → "is not a directory"
throws_ok {
	Database::test1->new('/no/such/path/xyzzy42')
} qr/is not a directory/, 'D1 IP2: non-existent path croaks with is not a directory';

# IP3 — a file path (not a directory) → "is not a directory"
throws_ok {
	Database::test1->new($CSV_FILE)
} qr/is not a directory/, 'D1 IP3: a file path croaks with is not a directory';

# ---------------------------------------------------------------------------
# D2: id parameter (SAFE_IDENTIFIER = /\A[a-zA-Z_][a-zA-Z0-9_]*\z/)
#
# VP: any identifier starting with letter or underscore
# BV: single character (min length 1)
# IP: starts with digit, contains punctuation, SQL metacharacters
# ---------------------------------------------------------------------------

note('D2: id parameter');

# VP1 — default 'entry'
ok(
	eval { Database::test1->new({ directory => $DATA_DIR, id => 'entry' }); 1 },
	'D2 VP1: id="entry" (default) is valid'
);

# BV1 — single underscore (minimum-length valid identifier)
ok(
	eval { Database::test1->new({ directory => $DATA_DIR, id => '_' }); 1 },
	'D2 BV1: id="_" (single char, underscore) is valid'
);

# VP2 — trailing digits
ok(
	eval { Database::test1->new({ directory => $DATA_DIR, id => 'col1' }); 1 },
	'D2 VP2: id="col1" (letter+digit) is valid'
);

# IP1 — starts with digit (BV: just past the first-char constraint)
throws_ok {
	Database::test1->new({ directory => $DATA_DIR, id => '1col' })
} qr/unsafe id column name/, 'D2 IP1: id starting with digit is rejected';

# IP2 — contains semicolon (SQL injection vector)
throws_ok {
	Database::test1->new({ directory => $DATA_DIR, id => 'col;drop' })
} qr/unsafe id column name/, 'D2 IP2: id with semicolon is rejected';

# IP3 — contains dot (SAFE_IDENTIFIER forbids dot; SAFE_QUALIFIED allows it but id uses IDENTIFIER)
throws_ok {
	Database::test1->new({ directory => $DATA_DIR, id => 'table.col' })
} qr/unsafe id column name/, 'D2 IP3: id with dot is rejected (SAFE_IDENTIFIER not SAFE_QUALIFIED)';

# IP4 — null byte (bypasses naive string checks)
throws_ok {
	Database::test1->new({ directory => $DATA_DIR, id => "col\x00name" })
} qr/unsafe id column name/, 'D2 IP4: id with null byte is rejected';

# ---------------------------------------------------------------------------
# D3: host parameter
# Regex: /\A(?:[a-zA-Z0-9][a-zA-Z0-9._-]*\@)?[a-zA-Z0-9:][a-zA-Z0-9._:-]*\z/
#
# VP: plain hostname, user@host, IPv4, IPv6
# IP: spaces, semicolons, path-traversal, leading @
# ---------------------------------------------------------------------------

note('D3: host parameter');

# VP1 — plain hostname (local-host short-circuit; no SSH needed for validation)
ok(
	eval { Database::test1->new({ directory => $DATA_DIR, host => 'localhost' }); 1 },
	'D3 VP1: host="localhost" passes validation'
);

# VP2 — user@host form
ok(
	eval { Database::test1->new({ directory => $DATA_DIR, host => 'user@server1.example.com' }); 1 },
	'D3 VP2: user@host form passes validation'
);

# VP3 — IPv6 loopback (contains ':')
ok(
	eval { Database::test1->new({ directory => $DATA_DIR, host => '::1' }); 1 },
	'D3 VP3: host="::1" (IPv6) passes validation'
);

# IP1 — space in hostname (shell injection)
throws_ok {
	Database::test1->new({ directory => $DATA_DIR, host => 'server name' })
} qr/unsafe host/, 'D3 IP1: host with space is rejected';

# IP2 — semicolon (shell metacharacter)
throws_ok {
	Database::test1->new({ directory => $DATA_DIR, host => 'server;ls' })
} qr/unsafe host/, 'D3 IP2: host with semicolon is rejected';

# IP3 — path traversal pattern
throws_ok {
	Database::test1->new({ directory => $DATA_DIR, host => '../server' })
} qr/unsafe host/, 'D3 IP3: host with path traversal is rejected';

# ---------------------------------------------------------------------------
# D4: url parameter — scheme must be http:// or https:// (case-insensitive)
#
# VP: http://, https://, HTTP://, HTTPS://
# IP: ftp://, file://, javascript:, protocol-relative, bare domain
# ---------------------------------------------------------------------------

note('D4: url parameter');

# VP1 — http scheme
ok(
	eval { Database::test1->new({ url => 'http://example.com/data.html' }); 1 },
	'D4 VP1: http:// URL is valid'
);

# VP2 — https scheme
ok(
	eval { Database::test1->new({ url => 'https://example.com/data.html' }); 1 },
	'D4 VP2: https:// URL is valid'
);

# VP3 — uppercase scheme (case-insensitive match)
ok(
	eval { Database::test1->new({ url => 'HTTPS://EXAMPLE.COM/data.html' }); 1 },
	'D4 VP3: HTTPS:// (uppercase) URL is valid'
);

# IP1 — ftp scheme
throws_ok {
	Database::test1->new({ url => 'ftp://example.com/data.html' })
} qr/unsafe url/, 'D4 IP1: ftp:// URL is rejected';

# IP2 — file scheme (local file inclusion)
throws_ok {
	Database::test1->new({ url => 'file:///etc/passwd' })
} qr/unsafe url/, 'D4 IP2: file:// URL is rejected';

# IP3 — javascript: (XSS vector)
throws_ok {
	Database::test1->new({ url => 'javascript:alert(1)' })
} qr/unsafe url/, 'D4 IP3: javascript: URL is rejected';

# IP4 — protocol-relative (no explicit scheme)
throws_ok {
	Database::test1->new({ url => '//example.com/data.html' })
} qr/unsafe url/, 'D4 IP4: protocol-relative URL is rejected';

# ---------------------------------------------------------------------------
# D5: html_table_index parameter
# BV: 0 (min-valid), 1 (last-valid in 2-table fixture), 2 (min-invalid)
# IP: index >= number_of_tables
# ---------------------------------------------------------------------------

note('D5: html_table_index parameter');

{
	my $g = mock_scoped 'LWP::UserAgent::get' => sub { make_ok_response() };

	# BV1 — index 0: first table (3 data rows)
	{
		my $db = Database::test1->new(url => 'http://example.com/t.html', html_table_index => 0);
		cmp_ok($db->count(), '==', 3, 'D5 BV1: html_table_index=0 reads first table (3 rows)');
	}

	# BV2 — index 1: last valid index (second table, 2 data rows)
	{
		my $db = Database::test1->new(
			url            => 'http://example.com/t.html',
			html_table_index => 1,
			no_entry       => 1,
		);
		cmp_ok($db->count(), '==', 2, 'D5 BV2: html_table_index=1 reads second table (2 rows)');
	}

	# BV3 — index 2: first invalid (only 2 tables, 0-based)
	throws_ok {
		Database::test1->new(url => 'http://example.com/t.html', html_table_index => 2)
			->count();
	} qr/html_table_index 2 out of range/, 'D5 BV3: html_table_index=2 croaks (out of range)';

	# IP1 — very large index
	throws_ok {
		Database::test1->new(url => 'http://example.com/t.html', html_table_index => 999)
			->count();
	} qr/html_table_index 999 out of range/, 'D5 IP1: html_table_index=999 croaks';
}

# ---------------------------------------------------------------------------
# D6: max_slurp_size boundary analysis
# The CSV is slurped when (-s $file) <= max_slurp_size.
# test1.csv is CSV_SIZE bytes.
#
# BV1: max_slurp_size = CSV_SIZE     → file size == threshold → slurps  (data is ref)
# BV2: max_slurp_size = CSV_SIZE - 1 → file size > threshold  → SQL mode (data is undef)
# BV3: max_slurp_size = 0            → always SQL mode         (data is undef)
# VP1: max_slurp_size = 1_000_000    → always slurps           (data is ref)
# ---------------------------------------------------------------------------

note("D6: max_slurp_size boundary (CSV_SIZE=$CSV_SIZE bytes)");

{
	# BV1 — exact size → should slurp
	my $db_bv1 = Database::test1->new({ directory => $DATA_DIR, max_slurp_size => $CSV_SIZE });
	$db_bv1->count();
	ok(ref($db_bv1->{'data'}), "D6 BV1: max_slurp_size=CSV_SIZE ($CSV_SIZE) → data slurped (is ref)");

	# BV2 — one byte below threshold → must NOT slurp (SQL mode)
	my $db_bv2 = Database::test1->new({ directory => $DATA_DIR, max_slurp_size => $CSV_SIZE - 1 });
	$db_bv2->count();
	ok(!ref($db_bv2->{'data'}), 'D6 BV2: max_slurp_size=CSV_SIZE-1 → data NOT slurped (SQL mode)');

	# BV3 — zero forces SQL mode for all file sizes
	my $db_bv3 = Database::test1->new({ directory => $DATA_DIR, max_slurp_size => 0 });
	$db_bv3->count();
	ok(!ref($db_bv3->{'data'}), 'D6 BV3: max_slurp_size=0 → always SQL mode (data not ref)');

	# VP1 — very large → always slurps
	my $db_vp1 = Database::test1->new({ directory => $DATA_DIR, max_slurp_size => 1_000_000 });
	$db_vp1->count();
	ok(ref($db_vp1->{'data'}), 'D6 VP1: max_slurp_size=1_000_000 → always slurps');
}

# ---------------------------------------------------------------------------
# D7: Query::limit() — must be a non-negative integer (/\A\d+\z/)
#
# BV: 0 (minimum valid), large value
# IP: -1 (just below min), float, string, undef
# ---------------------------------------------------------------------------

note('D7: Query::limit()');

{
	my $db = Database::test1->new($DATA_DIR);

	# BV1 — 0 (minimum valid)
	ok(eval { $db->query->limit(0); 1 }, 'D7 BV1: limit=0 is valid');

	# VP1 — typical value
	ok(eval { $db->query->limit(10); 1 }, 'D7 VP1: limit=10 is valid');

	# VP2 — large value (no upper bound in spec)
	ok(eval { $db->query->limit(999_999); 1 }, 'D7 VP2: limit=999_999 is valid');

	# IP1 — negative (BV: just below min)
	throws_ok {
		$db->query->limit(-1)
	} qr/non-negative integer/, 'D7 IP1: limit=-1 is rejected';

	# IP2 — float
	throws_ok {
		$db->query->limit('1.5')
	} qr/non-negative integer/, 'D7 IP2: limit=1.5 (float string) is rejected';

	# IP3 — non-numeric string
	throws_ok {
		$db->query->limit('abc')
	} qr/non-negative integer/, 'D7 IP3: limit="abc" is rejected';

	# IP4 — undef
	throws_ok {
		$db->query->limit(undef)
	} qr/non-negative integer/, 'D7 IP4: limit=undef is rejected';
}

# ---------------------------------------------------------------------------
# D8: Query::offset() — same domain as limit()
#
# BV: 0 (minimum valid)
# IP: -1, float, non-numeric, undef
# ---------------------------------------------------------------------------

note('D8: Query::offset()');

{
	my $db = Database::test1->new($DATA_DIR);

	# BV1 — 0 (minimum valid)
	ok(eval { $db->query->offset(0); 1 }, 'D8 BV1: offset=0 is valid');

	# VP1 — typical pagination value
	ok(eval { $db->query->offset(100); 1 }, 'D8 VP1: offset=100 is valid');

	# IP1 — negative
	throws_ok {
		$db->query->offset(-1)
	} qr/non-negative integer/, 'D8 IP1: offset=-1 is rejected';

	# IP2 — float string
	throws_ok {
		$db->query->offset('2.5')
	} qr/non-negative integer/, 'D8 IP2: offset=2.5 (float string) is rejected';

	# IP3 — undef
	throws_ok {
		$db->query->offset(undef)
	} qr/non-negative integer/, 'D8 IP3: offset=undef is rejected';
}

# ---------------------------------------------------------------------------
# D9: Query::order_by() injection guard
# Rejects expressions containing ;  --  /*
# Valid: column name, "col DESC", multi-column, undef (clears ordering)
# ---------------------------------------------------------------------------

note('D9: order_by() injection guard');

{
	my $db = Database::test1->new($DATA_DIR);

	# VP1 — bare column name
	ok(eval { $db->query->order_by('entry'); 1 }, 'D9 VP1: order_by("entry") is valid');

	# VP2 — column with direction
	ok(eval { $db->query->order_by('number DESC'); 1 }, 'D9 VP2: order_by("col DESC") is valid');

	# VP3 — multi-column (comma-separated, legitimate SQL)
	ok(
		eval { $db->query->order_by('number ASC, entry DESC'); 1 },
		'D9 VP3: multi-column order_by is valid'
	);

	# VP4 — undef clears any ordering (no croak)
	ok(eval { $db->query->order_by(undef); 1 }, 'D9 VP4: order_by(undef) is valid (clears)');

	# IP1 — semicolon injection
	throws_ok {
		$db->query->order_by('entry; DROP TABLE test1')
	} qr/unsafe ORDER BY/, 'D9 IP1: semicolon in order_by is rejected';

	# IP2 — SQL comment via double-dash
	throws_ok {
		$db->query->order_by('entry -- comment')
	} qr/unsafe ORDER BY/, 'D9 IP2: double-dash in order_by is rejected';

	# IP3 — C-style block comment
	throws_ok {
		$db->query->order_by('entry /* malicious */')
	} qr/unsafe ORDER BY/, 'D9 IP3: /* comment in order_by is rejected';
}

# ---------------------------------------------------------------------------
# D10: join table name — validated against SAFE_QUALIFIED
# (/\A[a-zA-Z_][a-zA-Z0-9_.]*\z/)
#
# VP: 'dept', 'my_table', 'schema.table'
# IP: 'dept;cmd', '../table'
#
# Note: Params::Get mangles join specs for keyed (no_entry=0) databases because
# it maps the first positional element to 'entry'.  The join spec only reaches
# _build_joins() when no_entry => 1 (get_params(undef, \@_) preserves key names).
# test4ne uses no_entry => 1, so it is the correct fixture for join domain tests.
# ---------------------------------------------------------------------------

note('D10: join table name');

{
	my $db = Database::test4ne->new({ directory => $DATA_DIR });

	# VP1 — simple table name: passes safety guard (may fail in DBI on unknown table)
	# Suppress DBI/CSV warnings about the missing 'dept' table — we are testing the
	# name-guard only, not whether the join itself succeeds.
	{
		local $SIG{__WARN__} = sub {};
		eval {
			$db->selectall_arrayref(join => { table => 'dept', on => 'test4.cardinal = dept.id' })
		};
	}
	unlike($@, qr/unsafe table name/, 'D10 VP1: valid table name "dept" passes the safety guard');

	# VP2 — qualified schema.table
	{
		local $SIG{__WARN__} = sub {};
		eval {
			$db->selectall_arrayref(join => { table => 'schema.dept', on => 'test4.cardinal = schema.dept.id' })
		};
	}
	unlike($@, qr/unsafe table name/, 'D10 VP2: schema.table form passes the safety guard');

	# IP1 — semicolon (command injection)
	throws_ok {
		$db->selectall_arrayref(join => { table => 'dept;ls', on => 'a=b' })
	} qr/unsafe table name/, 'D10 IP1: table name with semicolon is rejected';

	# IP2 — path traversal in table name
	throws_ok {
		$db->selectall_arrayref(join => { table => '../evil', on => 'a=b' })
	} qr/unsafe table name/, 'D10 IP2: table name with path traversal is rejected';
}

# ---------------------------------------------------------------------------
# D11: join type — must be INNER | LEFT | RIGHT | FULL | CROSS (case-insensitive)
#
# VP: each of the 5 valid types, lowercase (normalised)
# IP: unknown type, empty string
# ---------------------------------------------------------------------------

note('D11: join type');

{
	# test4ne (no_entry => 1) so get_params(undef, \@_) correctly preserves the join key
	my $db = Database::test4ne->new({ directory => $DATA_DIR });

	# Suppress DBI/CSV warnings about the missing 'dept' table for the VP tests —
	# we are testing the type guard only, not whether the join succeeds.
	for my $type (qw(INNER LEFT RIGHT FULL CROSS)) {
		local $SIG{__WARN__} = sub {};
		eval {
			$db->selectall_arrayref(join => { table => 'dept', on => 'a=b', type => $type })
		};
		unlike($@, qr/Invalid JOIN type/,
			"D11 VP: type '$type' passes the type guard");
	}

	# VP: lowercase is normalised to uppercase (not rejected)
	{
		local $SIG{__WARN__} = sub {};
		eval {
			$db->selectall_arrayref(join => { table => 'dept', on => 'a=b', type => 'left' })
		};
	}
	unlike($@, qr/Invalid JOIN type/, 'D11 VP: lowercase "left" is normalised, not rejected');

	# IP1 — unknown type
	throws_ok {
		$db->selectall_arrayref(join => { table => 'dept', on => 'a=b', type => 'NOSUCHTYPE' })
	} qr/Invalid JOIN type/, 'D11 IP1: unknown join type is rejected';

	# IP2 — empty string
	throws_ok {
		$db->selectall_arrayref(join => { table => 'dept', on => 'a=b', type => '' })
	} qr/Invalid JOIN type/, 'D11 IP2: empty join type is rejected';
}

# ---------------------------------------------------------------------------
# D12: dbname and filename — validated in _open() against /^[a-zA-Z0-9_.-]+$/
# and must not contain '..'
#
# VP: 'test1', 'my.db', 'data-file'
# IP: '../etc', '/etc/passwd', 'db/sub', 'db;cmd'
# ---------------------------------------------------------------------------

note('D12: dbname and filename safety');

{
	# VP1 — explicit dbname matching the fixture → query succeeds
	my $db_vp = Database::test1->new({ directory => $DATA_DIR, dbname => 'test1' });
	ok(eval { $db_vp->count(); 1 }, 'D12 VP1: explicit dbname="test1" is accepted');

	# IP1 — path traversal in dbname
	my $db_ip1 = Database::test1->new({ directory => $DATA_DIR, dbname => '../etc' });
	throws_ok { $db_ip1->count() } qr/unsafe dbname/, 'D12 IP1: dbname="../etc" is rejected';

	# IP2 — absolute path in dbname (contains '/')
	my $db_ip2 = Database::test1->new({ directory => $DATA_DIR, dbname => '/etc/passwd' });
	throws_ok { $db_ip2->count() } qr/unsafe dbname/, 'D12 IP2: dbname="/etc/passwd" is rejected';

	# IP3 — path traversal in filename
	my $db_ip3 = Database::test1->new({ directory => $DATA_DIR, filename => '../etc/passwd' });
	throws_ok { $db_ip3->count() } qr/unsafe filename/, 'D12 IP3: filename="../etc/passwd" is rejected';
}

# ---------------------------------------------------------------------------
# D13: Combinatorial — max_slurp_size at exact boundary, keyed vs no_entry
#
# Verifies that the <= comparison (not <) fires correctly for both storage
# modes at the precise boundary value.
# ---------------------------------------------------------------------------

note('D13: Combinatorial — slurp boundary for keyed vs no_entry modes');

{
	# Keyed mode at exact boundary → data is HASH ref
	my $db_keyed = Database::test1->new({
		directory     => $DATA_DIR,
		max_slurp_size => $CSV_SIZE,
	});
	$db_keyed->count();
	is(ref($db_keyed->{'data'}), 'HASH',
		"D13 CB1: keyed, max_slurp_size=CSV_SIZE ($CSV_SIZE) → HASH ref");

	# Keyed mode one byte below boundary → SQL mode, no HASH
	my $db_keyed2 = Database::test1->new({
		directory      => $DATA_DIR,
		max_slurp_size => $CSV_SIZE - 1,
	});
	$db_keyed2->count();
	ok(!ref($db_keyed2->{'data'}),
		'D13 CB2: keyed, max_slurp_size=CSV_SIZE-1 → SQL mode (not a ref)');

	# no_entry mode at exact boundary → data is ARRAY ref
	# test4.csv is a comma-separated file; its size may differ from test1.csv
	my $csv4_file = File::Spec->catfile($DATA_DIR, 'test4.csv');
	my $csv4_size = (-s $csv4_file);
	my $db_ne = Database::test4ne->new({
		directory      => $DATA_DIR,
		max_slurp_size => $csv4_size,
	});
	$db_ne->count();
	is(ref($db_ne->{'data'}), 'ARRAY',
		"D13 CB3: no_entry, max_slurp_size=csv4_size ($csv4_size) → ARRAY ref");

	# no_entry mode one byte below boundary → SQL mode
	my $db_ne2 = Database::test4ne->new({
		directory      => $DATA_DIR,
		max_slurp_size => $csv4_size - 1,
	});
	$db_ne2->count();
	ok(!ref($db_ne2->{'data'}),
		'D13 CB4: no_entry, max_slurp_size=csv4_size-1 → SQL mode (not a ref)');
}

# ---------------------------------------------------------------------------
# D14: sort_by parameter for selectall_arrayref / selectall_array
#
# Column name validated against $SAFE_QUALIFIED; direction must be ASC or DESC
# (case-insensitive).  Invalid name or direction: carp + fallback to default
# primary-key sort — NOT a croak.
#
# VP:  'entry' scalar, ['entry','DESC'] arrayref, ['entry','ASC']
# BV:  single-underscore column name (minimum-length SAFE_QUALIFIED)
# IP:  direction 'NOSUCHDIR' (carp+fallback), name '1bad' (carp+fallback)
# ---------------------------------------------------------------------------

note('D14: sort_by parameter');

{
	my $db = Database::test1->new($DATA_DIR);

	# VP1 — scalar column name implies ascending; rows returned
	{
		my $rows = $db->selectall_arrayref(sort_by => 'entry');
		ok(ref($rows) eq 'ARRAY' && @$rows > 0,
			'D14 VP1: sort_by scalar column name returns rows');
	}

	# VP2 — arrayref [col,'DESC'] descending form
	{
		my $rows = $db->selectall_arrayref(sort_by => ['entry', 'DESC']);
		ok(ref($rows) eq 'ARRAY' && @$rows > 0,
			'D14 VP2: sort_by ["entry","DESC"] returns rows');
	}

	# VP3 — arrayref [col,'ASC'] explicit ascending
	{
		my $rows = $db->selectall_arrayref(sort_by => ['entry', 'ASC']);
		ok(ref($rows) eq 'ARRAY' && @$rows > 0,
			'D14 VP3: sort_by ["entry","ASC"] returns rows');
	}

	# BV1 — sort_by with an existing column that is not the default primary key
	{
		my $rows = $db->selectall_arrayref(sort_by => 'number');
		ok(ref($rows) eq 'ARRAY' && @$rows > 0,
			'D14 BV1: sort_by existing non-pk column "number" returns rows');
	}

	# IP1 — invalid direction: carp emitted; rows still returned (fallback)
	{
		my @warns;
		local $SIG{__WARN__} = sub { push @warns, @_ };
		my $rows = $db->selectall_arrayref(sort_by => ['entry', 'NOSUCHDIR']);
		ok(scalar(@warns) > 0,
			'D14 IP1: invalid sort direction triggers a carp');
		ok(ref($rows) eq 'ARRAY' && @$rows > 0,
			'D14 IP1: rows still returned after invalid sort direction (fallback)');
	}

	# IP2 — column name failing SAFE_QUALIFIED (starts with digit): carp + fallback
	{
		my @warns;
		local $SIG{__WARN__} = sub { push @warns, @_ };
		my $rows = $db->selectall_arrayref(sort_by => '1invalid');
		ok(scalar(@warns) > 0,
			'D14 IP2: non-SAFE_QUALIFIED sort column triggers a carp');
		ok(ref($rows) eq 'ARRAY' && @$rows > 0,
			'D14 IP2: rows still returned after invalid sort column (fallback)');
	}
}

# ---------------------------------------------------------------------------
# D15: base_criteria constructor parameter
#
# Must be a hashref.  Keys validated against $SAFE_QUALIFIED unless they
# start with '-' (which allows -or/-and grouping keys).
#
# VP:  {entry=>'one'} (scalar filter), {} (empty — no filter), -or key
# BV:  undef value (IS NULL partition) — accepted at construction time
# IP:  scalar string (not a hashref), key with semicolon, key with null byte
# ---------------------------------------------------------------------------

note('D15: base_criteria constructor parameter');

{
	# VP1 — scalar criterion filters to matching rows only
	{
		my $db = Database::test1->new({
			directory     => $DATA_DIR,
			base_criteria => { entry => 'one' },
		});
		cmp_ok($db->count(), '==', 1,
			'D15 VP1: base_criteria {entry=>"one"} filters to exactly 1 row');
	}

	# VP2 — empty hashref: no rows filtered; count equals unfiltered count
	{
		my $db_full = Database::test1->new({ directory => $DATA_DIR });
		my $db_bc   = Database::test1->new({ directory => $DATA_DIR, base_criteria => {} });
		cmp_ok($db_bc->count(), '==', $db_full->count(),
			'D15 VP2: empty base_criteria {} does not remove any rows');
	}

	# VP3 — -or grouping key (starts with '-') is explicitly allowed
	ok(
		eval {
			Database::test1->new({
				directory     => $DATA_DIR,
				base_criteria => { -or => [ { entry => 'one' }, { entry => 'two' } ] },
			});
			1
		},
		'D15 VP3: -or grouping key in base_criteria is valid (not rejected)'
	);

	# BV1 — undef value (IS NULL filter) is accepted at construction time
	ok(
		eval {
			Database::test1->new({
				directory     => $DATA_DIR,
				base_criteria => { name => undef },
			});
			1
		},
		'D15 BV1: undef value (IS NULL) in base_criteria is accepted'
	);

	# IP1 — non-hashref (plain scalar) must croak
	throws_ok {
		Database::test1->new({ directory => $DATA_DIR, base_criteria => 'not_a_hashref' })
	} qr/base_criteria must be a hashref/,
		'D15 IP1: scalar base_criteria croaks "base_criteria must be a hashref"';

	# IP2 — unsafe key containing semicolon
	throws_ok {
		Database::test1->new({
			directory     => $DATA_DIR,
			base_criteria => { 'col;drop' => 1 },
		})
	} qr/unsafe base_criteria key/,
		'D15 IP2: base_criteria key with semicolon croaks "unsafe base_criteria key"';

	# IP3 — key with null byte (bypasses naive checks)
	throws_ok {
		Database::test1->new({
			directory     => $DATA_DIR,
			base_criteria => { "col\x00name" => 1 },
		})
	} qr/unsafe base_criteria key/,
		'D15 IP3: base_criteria key with null byte croaks "unsafe base_criteria key"';
}

# ---------------------------------------------------------------------------
# D16: table constructor parameter
#
# Validated against $SAFE_QUALIFIED (/\A[a-zA-Z_][a-zA-Z0-9_.]*\z/).
# A dot is allowed (qualified schema.table notation); digit-leading, slash,
# and semicolon names are all rejected.
#
# VP:  'mytable' (simple), 'schema.test1' (qualified with dot)
# IP:  '1bad' (digit-leading), 'tbl;drop' (semicolon), 'dir/table' (slash)
# ---------------------------------------------------------------------------

note('D16: table constructor parameter');

{
	# VP1 — simple valid table name
	ok(
		eval { Database::test1->new({ directory => $DATA_DIR, table => 'mytable' }); 1 },
		'D16 VP1: table="mytable" passes SAFE_QUALIFIED guard'
	);

	# VP2 — qualified schema.table (dot allowed in SAFE_QUALIFIED)
	ok(
		eval { Database::test1->new({ directory => $DATA_DIR, table => 'schema.test1' }); 1 },
		'D16 VP2: table="schema.test1" qualified form passes SAFE_QUALIFIED guard'
	);

	# IP1 — starts with digit
	throws_ok {
		Database::test1->new({ directory => $DATA_DIR, table => '1bad' })
	} qr/unsafe table name/,
		'D16 IP1: table name starting with digit is rejected';

	# IP2 — semicolon (SQL injection vector)
	throws_ok {
		Database::test1->new({ directory => $DATA_DIR, table => 'tbl;drop' })
	} qr/unsafe table name/,
		'D16 IP2: table name with semicolon is rejected';

	# IP3 — slash (path separator, not in SAFE_QUALIFIED charset)
	throws_ok {
		Database::test1->new({ directory => $DATA_DIR, table => 'dir/table' })
	} qr/unsafe table name/,
		'D16 IP3: table name with slash is rejected';
}

# ---------------------------------------------------------------------------
# D17: Criteria value domains for selectall_arrayref
#
# Valid: plain scalar, undef (IS NULL), -in, -not_in, -like
# Invalid: plain arrayref value (croaks from _build_where_conditions)
#
# Note: test4ne (no_entry=1) so Params::Get uses get_params(undef,\@_) and
# correctly preserves the column-name => value mapping without mapping the
# first element to 'entry'.
#
# Note: -between and != are valid API operators but DBD::CSV (the CSV backend)
# does not support them; those operators are covered in t/query_builder.t
# against a SQLite fixture.
# ---------------------------------------------------------------------------

note('D17: criteria value domains');

{
	my $db = Database::test4ne->new({ directory => $DATA_DIR });

	# VP1 — plain scalar equality: matching value returns ARRAY ref
	{
		my $rows = $db->selectall_arrayref(cardinal => 'one');
		ok(ref($rows) eq 'ARRAY' && @$rows == 1,
			'D17 VP1: plain scalar criterion matches and returns a 1-row arrayref');
	}

	# VP2 — undef value (IS NULL filter): lives without croak
	# test4.csv has no NULL values so result is undef (no rows); the contract
	# being tested is that the criteria type is ACCEPTED, not the row count.
	lives_ok {
		$db->selectall_arrayref(cardinal => undef)
	} 'D17 VP2: undef criterion (IS NULL) does not croak';

	# VP3 — -in operator hashref
	{
		my $rows = $db->selectall_arrayref(cardinal => { -in => ['one', 'two'] });
		ok(ref($rows) eq 'ARRAY' && @$rows == 2,
			'D17 VP3: -in operator hashref returns matching rows');
	}

	# VP4 — -not_in operator hashref
	{
		my $rows = $db->selectall_arrayref(cardinal => { -not_in => ['one'] });
		ok(ref($rows) eq 'ARRAY' && @$rows == 2,
			'D17 VP4: -not_in operator hashref returns non-matching rows');
	}

	# VP5 — -like operator hashref (wildcard — all rows match %)
	{
		my $rows = $db->selectall_arrayref(cardinal => { -like => '%' });
		ok(ref($rows) eq 'ARRAY' && @$rows == 3,
			'D17 VP5: -like "%" operator hashref returns all rows');
	}

	# IP1 — plain arrayref as criterion value: _build_where_conditions croaks
	throws_ok {
		$db->selectall_arrayref(cardinal => [1, 2, 3])
	} qr/expected scalar or operator hashref|got ARRAY/i,
		'D17 IP1: plain arrayref as criterion value is rejected';
}

# ---------------------------------------------------------------------------
# D18: limit / offset via selectall_arrayref direct method
#
# Valid non-negative integers are silently applied.
# Invalid values (/\A\d+\z/ fails) trigger carp + the parameter is ignored.
# This is DIFFERENT from Query::limit()/offset() which croak on invalid input.
#
# VP:  limit=2 (returns 2 rows), offset=1 (skips 1 row)
# BV:  limit=0 (returns 0 rows — minimum valid)
# IP:  limit=-1 (carp+ignored → all rows), offset='abc' (carp+ignored → no skip)
# ---------------------------------------------------------------------------

note('D18: limit/offset via selectall_arrayref direct method');

{
	my $db = Database::test1->new($DATA_DIR);

	# VP1 — valid limit restricts the returned row count
	{
		my $rows = $db->selectall_arrayref(limit => 2);
		cmp_ok(scalar @$rows, '==', 2,
			'D18 VP1: limit=>2 returns exactly 2 rows');
	}

	# BV1 — limit=0 is the minimum valid value; returns empty arrayref
	{
		my $rows = $db->selectall_arrayref(limit => 0);
		cmp_ok(scalar @$rows, '==', 0,
			'D18 BV1: limit=>0 returns an empty arrayref');
	}

	# VP2 — valid offset skips the first N rows
	{
		my $all  = $db->selectall_arrayref();
		my $rows = $db->selectall_arrayref(offset => 1);
		cmp_ok(scalar @$rows, '==', scalar(@$all) - 1,
			'D18 VP2: offset=>1 skips exactly one row');
	}

	# IP1 — negative limit: carp emitted; all rows returned (parameter ignored)
	{
		my @warns;
		local $SIG{__WARN__} = sub { push @warns, @_ };
		my $full = scalar @{ $db->selectall_arrayref() };
		my $rows = $db->selectall_arrayref(limit => -1);
		ok(scalar(@warns) > 0,
			'D18 IP1: negative limit triggers a carp');
		cmp_ok(scalar @$rows, '==', $full,
			'D18 IP1: negative limit is ignored (all rows returned)');
	}

	# IP2 — non-numeric offset: carp emitted; no offset applied
	{
		my @warns;
		local $SIG{__WARN__} = sub { push @warns, @_ };
		my $full = scalar @{ $db->selectall_arrayref() };
		my $rows = $db->selectall_arrayref(offset => 'abc');
		ok(scalar(@warns) > 0,
			'D18 IP2: non-numeric offset triggers a carp');
		cmp_ok(scalar @$rows, '==', $full,
			'D18 IP2: non-numeric offset is ignored (all rows returned)');
	}
}

# ---------------------------------------------------------------------------
# D19: dsn parameter — bypasses file detection entirely
#
# When dsn is given, _open() skips the extension probe and calls DBI->connect()
# directly.  No directory is required.  Dialect auto-detected from DSN prefix.
#
# VP:  valid SQLite DSN → count() returns integer, no directory arg needed
# IP:  DSN with missing/non-existent driver → DBI connect error (croak)
# ---------------------------------------------------------------------------

note('D19: dsn parameter');

SKIP: {
	eval { require DBD::SQLite } or skip 'DBD::SQLite not available', 3;

	require File::Temp;
	my $tf    = File::Temp->new(SUFFIX => '.sqlite', UNLINK => 1);
	my $tf_fn = $tf->filename;

	# Bootstrap a minimal SQLite database for the tests below
	{
		require DBI;
		my $dbh = DBI->connect(
			"dbi:SQLite:dbname=$tf_fn", '', '',
			{ RaiseError => 1, AutoCommit => 1, PrintError => 0 }
		);
		$dbh->do('CREATE TABLE test1 (entry TEXT, name TEXT)');
		$dbh->do(q{INSERT INTO test1 VALUES ('a','Alpha')});
		$dbh->do(q{INSERT INTO test1 VALUES ('b','Beta')});
		$dbh->disconnect;
	}

	# VP1 — valid SQLite DSN constructs without a directory argument
	my $db_dsn = eval {
		Database::test1->new({ dsn => "dbi:SQLite:dbname=$tf_fn" })
	};
	ok(defined $db_dsn && !$@,
		'D19 VP1: valid SQLite DSN constructs without a directory');

	# VP2 — count() traverses the SQL path via the DSN connection
	{
		my $n = eval { $db_dsn->count() };
		ok(!$@ && defined $n,
			'D19 VP2: count() works on a DSN-backed SQLite database');
	}

	# IP1 — bogus DSN prefix → DBI fails to load the driver
	{
		local $SIG{__WARN__} = sub {};    # suppress DBI's own warnings
		throws_ok {
			Database::test1->new({ dsn => 'dbi:NOSUCHDRIVER_xyzzy:whatever' })->count()
		} qr/install_driver|could not find|Can't locate|driver/i,
			'D19 IP1: unknown DSN driver croaks with a DBI driver error';
	}
}

# ---------------------------------------------------------------------------
# D20: Non-ASCII / multibyte character values in criteria
#
# The module is not required to decode UTF-8 bytes; it IS required to handle
# multibyte byte-strings in criteria without a fatal crash.
#
# VP:  UTF-8 two-byte umlaut in scalar criterion → lives, returns []
# VP:  Four-byte emoji bytes in scalar criterion → lives, returns []
# VP:  -like pattern containing non-ASCII bytes → lives, returns []
# ---------------------------------------------------------------------------

note('D20: non-ASCII bytes in criteria values (no-crash contract)');

{
	my $db = Database::test1->new($DATA_DIR);

	# VP1 — UTF-8 umlaut (U+00FC = \xc3\xbc) as criteria value: must not croak
	{
		my $rows = eval { $db->selectall_arrayref(entry => "\xc3\xbc") };
		ok(!$@ && ref($rows) eq 'ARRAY',
			'D20 VP1: UTF-8 umlaut in scalar criterion does not croak');
	}

	# VP2 — four-byte emoji bytes (U+1F600 = \xf0\x9f\x98\x80): must not croak
	{
		my $rows = eval { $db->selectall_arrayref(entry => "\xf0\x9f\x98\x80") };
		ok(!$@ && ref($rows) eq 'ARRAY',
			'D20 VP2: four-byte emoji bytes in scalar criterion do not croak');
	}

	# VP3 — -like pattern with non-ASCII bytes: must not croak (no-crash contract)
	# Use no_entry database (test4ne) to avoid the Params::Get positional-arg
	# pitfall that mangles operator-hashref criteria on keyed databases.
	# The return value may be undef (DBD::CSV silently fails non-ASCII LIKE in SQL
	# mode) — that is acceptable; the domain contract is no fatal exception.
	{
		my $db4 = Database::test4ne->new({ directory => $DATA_DIR });
		my $ok   = eval {
			$db4->selectall_arrayref(cardinal => { -like => "%\xc3\xbc%" });
			1
		};
		ok($ok && !$@,
			'D20 VP3: -like pattern with non-ASCII bytes does not croak');
	}
}
