use strict;
use warnings;

use Test::Most;
use Test::Mojo;
use Test::Mockingbird qw(mock restore_all);
use Readonly;
use File::Spec ();
use File::Temp qw(tempdir tempfile);
use Mojo::File ();
use Mojo::Util qw(url_escape);
use Scalar::Util qw(reftype);

# ---------------------------------------------------------------------------
# Bootstrap: Test::Mojo FIRST so the app loads all controller modules before
# Sub::Private's CHECK-phase cleanup can run.  Subsequent require calls are
# no-ops that leave the stash intact, letting us reference private subs.
# ---------------------------------------------------------------------------
my $t = Test::Mojo->new('Database::BI');

# Package-level aliases to package-scoped (non-:Private) helpers.
# These survive in the stash because they were loaded via require (post-CHECK).
my $IS_SAFE_URL       = \&Database::BI::Controller::Dashboard::_is_safe_url;
my $APPLY_FILTER_SPEC = \&Database::BI::Controller::Dashboard::_apply_filter_spec;
my $CSV_ROW           = \&Database::BI::Controller::Dashboard::_csv_row;

# Temp directory for data files created by edge-case subtests.
Readonly my $TMPDIR   => tempdir(CLEANUP => 1);

# Canonical small dataset for filter tests.
Readonly my @RECS => (
	{ name => 'Alice', amount => '500', region => 'North', notes => 'foobar' },
	{ name => 'Bob',   amount => '100', region => 'South', notes => 'bazqux' },
	{ name => 'Carol', amount => '300', region => 'North', notes => ''       },
);

# ---------------------------------------------------------------------------
# Section 1: _is_safe_url -- unit tests for the SSRF guard
#
# Strategy: call the non-:Private function directly so we get deterministic
# pass/block decisions without any LWP network activity.
# ---------------------------------------------------------------------------

subtest '_is_safe_url -- loopback aliases are blocked' => sub {
	ok !$IS_SAFE_URL->('http://localhost/'),           'localhost blocked';
	ok !$IS_SAFE_URL->('http://localhost:8080/path'),  'localhost with port blocked';
	ok !$IS_SAFE_URL->('http://127.0.0.1/'),           '127.0.0.1 blocked';
	ok !$IS_SAFE_URL->('http://127.255.255.255/'),     '127.255.255.255 blocked (still 127/8)';
	ok !$IS_SAFE_URL->('http://0.0.0.0/'),             '0.0.0.0 blocked';
	ok !$IS_SAFE_URL->('http://[::1]/'),               'IPv6 [::1] blocked (URL regex fails -- [ excluded)';
	ok !$IS_SAFE_URL->('https://localhost/ssl'),       'localhost blocked on https';
	ok !$IS_SAFE_URL->('HTTP://LOCALHOST/caps'),       'LOCALHOST (caps) blocked';
};

subtest '_is_safe_url -- RFC 1918 and special ranges are blocked' => sub {
	ok !$IS_SAFE_URL->('http://10.0.0.1/'),            '10/8 start blocked';
	ok !$IS_SAFE_URL->('http://10.255.255.255/'),      '10/8 end blocked';
	ok !$IS_SAFE_URL->('http://172.16.0.1/'),          '172.16/12 start blocked';
	ok !$IS_SAFE_URL->('http://172.31.255.255/'),      '172.31.255.255 -- end of 172.16/12 blocked';
	ok !$IS_SAFE_URL->('http://192.168.0.1/'),         '192.168/16 start blocked';
	ok !$IS_SAFE_URL->('http://192.168.255.255/'),     '192.168/16 end blocked';
	ok !$IS_SAFE_URL->('http://169.254.169.254/'),     '169.254 link-local (AWS/GCP metadata) blocked';
	ok !$IS_SAFE_URL->('http://100.64.0.0/'),          '100.64.0.0 -- CGNAT start blocked';
	ok !$IS_SAFE_URL->('http://100.127.255.255/'),     '100.127.255.255 -- CGNAT end blocked';
};

subtest '_is_safe_url -- range boundary: just outside private ranges is allowed' => sub {
	ok  $IS_SAFE_URL->('http://172.32.0.0/'),          '172.32.0.0 just outside 172.16/12 is allowed';
	ok  $IS_SAFE_URL->('http://100.128.0.0/'),         '100.128.0.0 just outside CGNAT is allowed';
	ok  $IS_SAFE_URL->('http://11.0.0.0/'),            '11.0.0.0 outside 10/8 is allowed';
	ok  $IS_SAFE_URL->('http://192.169.0.1/'),         '192.169.0.1 just outside 192.168/16 is allowed';
};

subtest '_is_safe_url -- public IPs and hostnames are allowed' => sub {
	ok  $IS_SAFE_URL->('http://8.8.8.8/'),             'public IP 8.8.8.8 allowed';
	ok  $IS_SAFE_URL->('http://example.com/'),         'public hostname allowed';
	ok  $IS_SAFE_URL->('https://api.example.org/data'),'https public hostname allowed';
};

subtest '_is_safe_url -- non-standard IP representations pass Perl layer (documented bypass)' => sub {
	# These non-decimal IP representations are NOT blocked at the Perl layer by
	# design; see the _is_safe_url comment: "The authoritative defence against
	# hostname-based SSRF is a network-layer egress firewall."
	ok  $IS_SAFE_URL->('http://0177.0.0.1/'),          'octal 0177.0.0.1 passes Perl layer (documented)';
	ok  $IS_SAFE_URL->('http://2130706433/'),           'decimal int 127.0.0.1 passes Perl layer (documented)';
	ok  $IS_SAFE_URL->('http://0x7f000001/'),           'hex int 127.0.0.1 passes Perl layer (documented)';
	diag 'NOTE: above URLs may still reach loopback; egress firewall must block them'
		if $ENV{TEST_VERBOSE};
};

subtest '_is_safe_url -- non-http/https schemes are rejected' => sub {
	ok !$IS_SAFE_URL->('ftp://example.com/'),          'ftp:// scheme blocked (wrong scheme)';
	ok !$IS_SAFE_URL->('file:///etc/passwd'),          'file:// scheme blocked';
	ok !$IS_SAFE_URL->('gopher://example.com/'),       'gopher:// scheme blocked';
	ok !$IS_SAFE_URL->(''),                            'empty string blocked';
	ok !$IS_SAFE_URL->('not-a-url'),                   'non-URL string blocked';
};

# ---------------------------------------------------------------------------
# Section 2: _apply_filter_spec -- pure function boundary and security tests
# ---------------------------------------------------------------------------

subtest '_apply_filter_spec -- malformed / empty specs are no-ops' => sub {
	my $recs = [@RECS];

	# Empty spec: split returns (''); length('' // '') == 0 -> unchanged.
	is_deeply $APPLY_FILTER_SPEC->($recs, ''), $recs, 'empty spec returns all records';

	# Only colon: col='', op='', length 0 -> unchanged.
	is_deeply $APPLY_FILTER_SPEC->($recs, ':'), $recs, 'single colon is no-op';

	# Empty column, valid op: col='' -> unchanged.
	is_deeply $APPLY_FILTER_SPEC->($recs, ':eq:alice'), $recs, 'empty col is no-op';

	# Valid column, empty op: op='' -> unchanged.
	is_deeply $APPLY_FILTER_SPEC->($recs, 'name::alice'), $recs, 'empty op is no-op';
};

subtest '_apply_filter_spec -- unknown operator passes all rows' => sub {
	# Spec says: "Unknown operators fall through to 1 (all rows pass)".
	my $result = $APPLY_FILTER_SPEC->([@RECS], 'name:regex:alice');
	is scalar(@$result), scalar(@RECS), 'unknown op returns all rows';

	$result = $APPLY_FILTER_SPEC->([@RECS], 'name:XYZ:anything');
	is scalar(@$result), scalar(@RECS), 'unknown op XYZ returns all rows';
};

subtest '_apply_filter_spec -- eq/ne are case-insensitive' => sub {
	my $result = $APPLY_FILTER_SPEC->([@RECS], 'name:eq:alice');
	is scalar(@$result), 1, 'eq finds one match';
	is $result->[0]{name}, 'Alice', 'matched row is Alice';

	$result = $APPLY_FILTER_SPEC->([@RECS], 'name:eq:ALICE');
	is scalar(@$result), 1, 'eq is case-insensitive (ALICE matches Alice)';

	$result = $APPLY_FILTER_SPEC->([@RECS], 'name:ne:alice');
	is scalar(@$result), 2, 'ne excludes the match, leaves 2 rows';
};

subtest '_apply_filter_spec -- contains and starts operators' => sub {
	my $result = $APPLY_FILTER_SPEC->([@RECS], 'notes:contains:bar');
	is scalar(@$result), 1, 'contains finds foobar';
	is $result->[0]{name}, 'Alice', 'Alice has notes containing bar';

	$result = $APPLY_FILTER_SPEC->([@RECS], 'notes:starts:foo');
	is scalar(@$result), 1, 'starts matches foobar';

	$result = $APPLY_FILTER_SPEC->([@RECS], 'notes:starts:FOO');
	is scalar(@$result), 1, 'starts is case-insensitive';
};

subtest '_apply_filter_spec -- numeric operators gt/lt/ge/le' => sub {
	my $result = $APPLY_FILTER_SPEC->([@RECS], 'amount:gt:200');
	is scalar(@$result), 2, 'gt:200 keeps Alice(500) and Carol(300)';

	$result = $APPLY_FILTER_SPEC->([@RECS], 'amount:lt:300');
	is scalar(@$result), 1, 'lt:300 keeps Bob(100)';

	$result = $APPLY_FILTER_SPEC->([@RECS], 'amount:ge:300');
	is scalar(@$result), 2, 'ge:300 keeps Carol and Alice';

	$result = $APPLY_FILTER_SPEC->([@RECS], 'amount:le:100');
	is scalar(@$result), 1, 'le:100 keeps Bob';
};

subtest '_apply_filter_spec -- empty and notempty operators' => sub {
	my $result = $APPLY_FILTER_SPEC->([@RECS], 'notes:empty:');
	is scalar(@$result), 1, 'empty: only Carol has empty notes';
	is $result->[0]{name}, 'Carol', 'Carol matched';

	$result = $APPLY_FILTER_SPEC->([@RECS], 'notes:notempty:ignored_val');
	is scalar(@$result), 2, 'notempty: Alice and Bob have non-empty notes';
};

subtest '_apply_filter_spec -- filter on non-existent column' => sub {
	# Missing col -> $_->{'nonexistent'} // '' = ''. 'eq:something' -> '' ne 'something' -> 0 rows.
	my $result = $APPLY_FILTER_SPEC->([@RECS], 'nonexistent:eq:something');
	is scalar(@$result), 0, 'filter on missing col returns 0 rows (cell is empty)';

	$result = $APPLY_FILTER_SPEC->([@RECS], 'nonexistent:empty:');
	is scalar(@$result), 3, 'missing col treated as empty -> all pass empty check';
};

subtest '_apply_filter_spec -- value containing colons (split limit 3)' => sub {
	# split(/:/, 'name:eq:val:with:colons', 3) -> ('name', 'eq', 'val:with:colons')
	my $recs = [{ name => 'val:with:colons' }, { name => 'other' }];
	my $result = $APPLY_FILTER_SPEC->($recs, 'name:eq:val:with:colons');
	is scalar(@$result), 1, 'value containing colons is preserved after split limit 3';
	is $result->[0]{name}, 'val:with:colons', 'matched the colon-containing value';
};

subtest '_apply_filter_spec -- undef cells are treated as empty string' => sub {
	my $recs = [{ name => undef }, { name => 'Bob' }];
	my $result = $APPLY_FILTER_SPEC->($recs, 'name:eq:');
	is scalar(@$result), 1, 'undef cell eq empty-string filter matches';

	$result = $APPLY_FILTER_SPEC->($recs, 'name:empty:');
	is scalar(@$result), 1, 'undef cell passes empty filter';
};

subtest '_apply_filter_spec -- gt with non-numeric value does not crash' => sub {
	# Perl converts non-numeric strings to 0 for numeric comparison (with warning).
	# This test verifies the comparison does not die; the result is deterministic
	# (Perl numeric semantics) even if surprising.
	local $SIG{__WARN__} = sub {};  # silence "isn't numeric" warnings for this test
	my $recs = [{ amount => '500' }, { amount => 'abc' }];
	my $result;
	lives_ok { $result = $APPLY_FILTER_SPEC->($recs, 'amount:gt:not_a_number') }
		'non-numeric gt comparison does not die';
	# '500' > 'not_a_number' -> 500 > 0 -> 1 (passes).
	# 'abc' > 'not_a_number' -> 0 > 0 -> 0 (fails).
	is scalar(@$result), 1, 'Perl numeric semantics: 500 > 0 (true), abc > 0 (false)';
	diag "result: amount=$result->[0]{amount}" if $ENV{TEST_VERBOSE};
};

subtest '_apply_filter_spec -- original arrayref is not mutated' => sub {
	my @orig = ({ name => 'Alice' }, { name => 'Bob' });
	my $in   = \@orig;
	my $out  = $APPLY_FILTER_SPEC->($in, 'name:eq:Alice');
	is scalar(@orig), 2, 'original array untouched after filter';
	is scalar(@$out), 1, 'filtered result has 1 row';
	isnt $out, $in,      'returned arrayref is a different reference';
};

subtest '_apply_filter_spec -- 100 filter applications do not crash' => sub {
	# Verify degenerate depth (many sequential filters on the same dataset)
	# does not exhaust stack or memory.
	my $recs = [@RECS];
	lives_ok {
		for (1 .. 100) {
			$recs = $APPLY_FILTER_SPEC->($recs, 'region:eq:north');
		}
	} '100 sequential filter applications complete without error';
	is scalar(@$recs), 2, 'North region rows survive all 100 filters';
};

# ---------------------------------------------------------------------------
# Section 3: _csv_row -- RFC 4180 boundary tests
# ---------------------------------------------------------------------------

subtest '_csv_row -- RFC 4180 edge cases' => sub {
	# Plain fields, no quoting needed.
	is $CSV_ROW->('a', 'b', 'c'), "a,b,c\r\n",          'plain fields';

	# undef treated as empty string.
	is $CSV_ROW->(undef, 'b'),   ",b\r\n",              'undef field becomes empty';

	# '0' must not be quoted (falsy but no special characters).
	is $CSV_ROW->('0', ''),      "0,\r\n",              "'0' is not quoted";

	# Field containing comma triggers quoting.
	is $CSV_ROW->('a', 'has,comma'), "a,\"has,comma\"\r\n", 'comma triggers quoting';

	# Embedded double-quote doubled; whole field quoted.
	is $CSV_ROW->('say "hi"'),   "\"say \"\"hi\"\"\"\r\n", 'double-quote doubled inside quotes';

	# Field containing only a double-quote.
	is $CSV_ROW->('"'),          "\"\"\"\"\r\n",         'single quote field: ""\"\"';

	# Embedded newline (LF only) requires quoting.
	is $CSV_ROW->("has\nnewline"), "\"has\nnewline\"\r\n", 'LF inside field is quoted';

	# Embedded CRLF inside the field (CRLF is the line terminator; must be quoted).
	is $CSV_ROW->("a\r\nb"),     "\"a\r\nb\"\r\n",       'CRLF inside field is quoted';

	# Empty call -- no fields -- produces just CRLF.
	is $CSV_ROW->(),             "\r\n",                  'no fields -> bare CRLF';
};

# ---------------------------------------------------------------------------
# Section 4: TABLE_NAME_RE fix -- regression tests for the digit-leading bug
#
# Bug: Controller's old TABLE_NAME_RE was \A[A-Za-z0-9_]+\z (allows digit
# start). DataSource's is \A[A-Za-z_][A-Za-z0-9_]*\z (requires letter/under-
# score start). A GET /view/1sales would pass the controller check, call
# open_table('1sales'), and receive an unhandled croak from DataSource -> 500.
#
# Fix: Controller's TABLE_NAME_RE now matches DataSource's exactly, so
# digit-leading names return 404 from the route guard, never reaching
# open_table.
# ---------------------------------------------------------------------------

subtest 'GET /view/<digit-start> returns 404 (regression: was 500)' => sub {
	$t->get_ok('/view/1sales')->status_is(404);
	$t->get_ok('/view/123')->status_is(404);
	$t->get_ok('/view/9')->status_is(404);
	diag 'Regression: these were 500 before TABLE_NAME_RE was tightened' if $ENV{TEST_VERBOSE};
};

subtest 'GET /view/<letter-start> still works (normal tables)' => sub {
	# Valid table names (letters / underscores start) must still be routed.
	# /view/sales loads the real sales.csv -> 200.
	$t->get_ok('/view/sales')->status_is(200);

	# Underscore-start is allowed by DataSource's regex; it doesn't exist on
	# disk, so DataSource init fails gracefully and renders the error page (200).
	$t->get_ok('/view/_phantom')->status_is(200);
};

# ---------------------------------------------------------------------------
# Section 5: open_file with formerly-problematic filenames
#
# Originally these produced 500 (open_table outside eval).  Then open_table
# moved inside eval and they produced a friendly error page.  As of 0.006.x,
# DataSource sanitizes illegal characters in table names (hyphens, dots,
# digits-at-start -> underscores/prefix), so these files now open successfully.
# ---------------------------------------------------------------------------

subtest 'GET /open with digit-leading filename succeeds (stem sanitized to _1data)' => sub {
	my $path = Mojo::File->new($TMPDIR)->child('1data.csv');
	$path->spew("id,name\n1,Widget\n");

	$t->get_ok('/open?path=' . url_escape($path->to_string))
	  ->status_is(200)
	  ->content_like(qr/Widget/,
	      'CSV data is rendered: digit-leading filename opens successfully after sanitization');
	diag "Previously produced friendly error; now sanitized and opened" if $ENV{TEST_VERBOSE};
};

subtest 'GET /open with double-extension filename succeeds (stem sanitized to file_php)' => sub {
	# "file.php.csv": stem = "file.php", sanitized internal name = "file_php",
	# dbname stays "file.php" so D::A finds the actual file on disk.
	my $path = Mojo::File->new($TMPDIR)->child('file.php.csv');
	$path->spew("id,label\n1,safe\n");

	$t->get_ok('/open?path=' . url_escape($path->to_string))
	  ->status_is(200)
	  ->content_like(qr/safe/,
	      'CSV data is rendered: double-extension filename opens successfully after sanitization');
};

# ---------------------------------------------------------------------------
# Section 6: Path traversal / hostile paths via GET /open
# ---------------------------------------------------------------------------

subtest 'GET /open -- path traversal attempts return 404' => sub {
	# realpath resolves ../ sequences; the resulting path has no supported extension.
	$t->get_ok('/open?path=' . url_escape('../../etc/passwd'))->status_is(404);
	$t->get_ok('/open?path=' . url_escape('/etc/passwd'))->status_is(404);
	$t->get_ok('/open?path=' . url_escape('/dev/null'))->status_is(404);   # not regular file
	$t->get_ok('/open?path=')->status_is(404);                              # empty path
	$t->get_ok('/open')->status_is(404);                                    # no param at all
	$t->get_ok('/open?path=' . url_escape('/nonexistent/file.csv'))->status_is(404);
};

subtest 'GET /open -- path with unsupported extension returns 404' => sub {
	# A real file but not a supported data format.
	my $bad = Mojo::File->new($TMPDIR)->child('script.sh');
	$bad->spew("echo hi\n");
	$t->get_ok('/open?path=' . url_escape($bad->to_string))->status_is(404);
};

# ---------------------------------------------------------------------------
# Section 7: Upload hostile filename inputs
#
# NOTE: Several upload security vectors are already in cgi_security.t.
# This section covers the complementary "upload succeeds, open fails" path
# that cgi_security.t does not test.
# ---------------------------------------------------------------------------

subtest 'POST /upload -- file.php.csv is stored; GET /open produces friendly error' => sub {
	# "file.php.csv" passes the extension check (last ext .csv) so upload returns
	# 200 with a path.  Opening that path derives table "file.php" which contains
	# a dot -> DataSource croak -> now caught -> 200 error page (not 500).
	my $res = $t->post_ok('/upload', form => {
		file => { content => "id,label\n1,Widget\n", filename => 'file.php.csv' }
	})->status_is(200)->tx->res->json;

	ok $res->{path}, 'upload succeeded: path returned';
	like $res->{path}, qr{\.uploads[/\\]}, 'stored inside .uploads/';
	like $res->{path}, qr{file\.php\.csv\z}, 'filename preserved intact (double-extension on disk)';

	# Opening via the URL in the response must yield 200 with an error message.
	$t->get_ok($res->{url})
	  ->status_is(200)
	  ->content_like(qr/Could not open/i,
	      'opening double-extension file renders friendly error, not 500');
};

subtest 'POST /upload -- zero-content file with valid extension is stored' => sub {
	# A 0-byte file passes extension validation and is stored.  When opened,
	# DataSource sees an empty file; fetch_all returns [].  View renders with 0 rows.
	my $res = $t->post_ok('/upload', form => {
		file => { content => '', filename => 'empty.csv' }
	})->status_is(200)->tx->res->json;

	ok $res->{path}, 'zero-byte upload accepted';
	# Opening should yield 200 (no crash), even though there are 0 rows.
	$t->get_ok($res->{url})->status_is(200);
};

# ---------------------------------------------------------------------------
# Section 8: Empty CSV file opened via /open
# ---------------------------------------------------------------------------

subtest 'GET /open -- 0-byte CSV file renders without crashing' => sub {
	my ($fh, $fname) = tempfile(SUFFIX => '.csv', DIR => $TMPDIR);
	close $fh;  # 0 bytes written
	$t->get_ok('/open?path=' . url_escape($fname))
	  ->status_is(200, '200 (no crash for empty CSV)');
};

subtest 'GET /open -- headers-only CSV renders with 0 data rows' => sub {
	my $path = Mojo::File->new($TMPDIR)->child('headers_only.csv');
	$path->spew("id,name,amount\n");  # header line only
	$t->get_ok('/open?path=' . url_escape($path->to_string))
	  ->status_is(200)
	  ->content_unlike(qr/500 Internal Server Error/, 'no 500 error for headers-only file');
};

# ---------------------------------------------------------------------------
# Section 9: Mocked upstream failures -- fetch_all croak is caught gracefully
#
# Strategy: use Test::Mockingbird to replace DataSource::fetch_all with a
# croaking stub.  Verify the eval in the view action catches the croak and
# renders the friendly error template (200, not 500).
# ---------------------------------------------------------------------------

subtest 'GET /view/sales -- fetch_all croak is caught, friendly error rendered' => sub {
	mock 'Database::BI::Model::DataSource::fetch_all' => sub {
		die "Simulated upstream database failure\n"
	};

	$t->get_ok('/view/sales')
	  ->status_is(200, 'controller returns 200 (error page), not 500')
	  ->content_like(qr/Could not open table/i,
	      'error_table_open message appears in error page');

	restore_all();
};

subtest 'GET /open -- fetch_all croak is caught, friendly error rendered' => sub {
	my $path = Mojo::File->new($TMPDIR)->child('sales.csv');
	$path->spew("id,name\n1,Widget\n");

	mock 'Database::BI::Model::DataSource::fetch_all' => sub {
		die "Simulated read failure\n"
	};

	$t->get_ok('/open?path=' . url_escape($path->to_string))
	  ->status_is(200)
	  ->content_like(qr/Could not open/i, 'error_file_open message in error page');

	restore_all();
};

# ---------------------------------------------------------------------------
# Section 10: SSRF via GET /import endpoint -- HTTP-level verification
#
# For blocked IPs the controller short-circuits before any LWP call, so
# these are fast and deterministic (no network required).
# ---------------------------------------------------------------------------

subtest 'GET /import -- private IP in URL triggers SSRF error response' => sub {
	for my $ip ('127.0.0.1', '10.0.0.1', '192.168.1.1', '172.16.0.1', '169.254.169.254', '100.64.0.0') {
		$t->get_ok("/import?url=" . url_escape("http://$ip/"))
		  ->status_is(200)
		  ->content_like(qr/private or reserved address/i,
		      "$ip: SSRF error shown");
	}
};

subtest 'GET /import -- localhost by name triggers SSRF error' => sub {
	$t->get_ok('/import?url=' . url_escape('http://localhost/'))
	  ->status_is(200)
	  ->content_like(qr/private or reserved address/i, 'localhost SSRF error shown');
};

subtest 'GET /import -- missing URL triggers required-field error' => sub {
	$t->get_ok('/import')
	  ->status_is(200)
	  ->content_like(qr/Please enter a URL/i, 'empty url error shown');
};

subtest 'GET /import -- non-http:// URL triggers invalid-URL error' => sub {
	$t->get_ok('/import?url=' . url_escape('ftp://example.com/data.csv'))
	  ->status_is(200)
	  ->content_like(qr/not a valid http/i, 'invalid scheme error shown');
};

# ---------------------------------------------------------------------------
# Section 11: Filter via HTTP -- malformed f= params do not break the view
# ---------------------------------------------------------------------------

subtest 'GET /view/sales?f= -- empty filter spec is harmless' => sub {
	$t->get_ok('/view/sales?f=')
	  ->status_is(200)
	  ->content_unlike(qr/500 Internal Server Error/, 'no 500 for empty f=');
};

subtest 'GET /view/sales?f=:eq:val -- empty column name is harmless' => sub {
	$t->get_ok('/view/sales?f=' . url_escape(':eq:val'))
	  ->status_is(200)
	  ->content_unlike(qr/500 Internal Server Error/, 'no 500 for missing column in f=');
};

subtest 'GET /view/sales?f=col:badop:val -- unknown operator is harmless' => sub {
	$t->get_ok('/view/sales?f=' . url_escape('region:badop:North'))
	  ->status_is(200)
	  ->content_unlike(qr/500 Internal Server Error/, 'no 500 for unknown operator');
};

subtest 'GET /view/sales -- many f= params are handled without crash' => sub {
	my $url = '/view/sales?' . join('&', map { 'f=' . url_escape("region:eq:North$_") } 1 .. 50);
	$t->get_ok($url)
	  ->status_is(200)
	  ->content_unlike(qr/500 Internal Server Error/, 'no 500 for 50 filter conditions');
};

# ---------------------------------------------------------------------------
# Section 12: DataSource direct constructor hostile inputs
# ---------------------------------------------------------------------------

subtest 'DataSource::new -- hostile directory arguments croak correctly' => sub {
	require Database::BI::Model::DataSource;

	# Non-existent directory.
	throws_ok {
		Database::BI::Model::DataSource->new(directory => '/nonexistent/path', table => 'sales')
	} qr/does not exist or is not readable/i, 'croak for non-existent directory';

	# Character device, not a directory.
	throws_ok {
		Database::BI::Model::DataSource->new(directory => '/dev/null', table => 'sales')
	} qr/does not exist or is not readable/i, 'croak for /dev/null as directory';

	# Empty string as directory.
	throws_ok {
		Database::BI::Model::DataSource->new(directory => '', table => 'sales')
	} qr/does not exist or is not readable/i, 'croak for empty directory';
};

subtest 'DataSource::new -- table name sanitization and remaining croak cases' => sub {
	require Database::BI::Model::DataSource;
	my $dir = $t->app->home->child('data')->to_string;

	# Digit-leading name: sanitized to _1data (underscore prefix), not rejected.
	{
		my $src;
		lives_ok { $src = Database::BI::Model::DataSource->new(directory => $dir, table => '1data') }
			'digit-leading table name is sanitized, not rejected';
		is $src->table_name, '_1data', 'sanitized: digit-leading name prefixed with underscore';
	}

	# Dot: sanitized to file_php.
	{
		my $src;
		lives_ok { $src = Database::BI::Model::DataSource->new(directory => $dir, table => 'file.php') }
			'dot-in-table-name is sanitized, not rejected';
		is $src->table_name, 'file_php', 'sanitized: dot replaced with underscore';
	}

	# Semicolons: sanitized to name_ls.
	{
		my $src;
		lives_ok { $src = Database::BI::Model::DataSource->new(directory => $dir, table => 'name;ls') }
			'semicolon-in-table-name is sanitized, not rejected';
		is $src->table_name, 'name_ls', 'sanitized: semicolon replaced with underscore';
	}

	# Path separators still croak (security: prevent directory traversal via dbname).
	throws_ok {
		Database::BI::Model::DataSource->new(directory => $dir, table => '../../../etc/passwd')
	} qr/contains illegal characters/i, 'croak for path-traversal as table name';

	# Empty table name still croaks.
	throws_ok {
		Database::BI::Model::DataSource->new(directory => $dir, table => '')
	} qr/contains illegal characters/i, 'croak for empty table name';
};

subtest 'DataSource::new -- undef required arguments croak' => sub {
	require Database::BI::Model::DataSource;

	# All arguments missing.
	throws_ok {
		Database::BI::Model::DataSource->new()
	} qr/./, 'croak for no arguments at all';
};

# ---------------------------------------------------------------------------
# Header-less CSV detection: hostile and boundary inputs
# ---------------------------------------------------------------------------

subtest 'DataSource -- headerless CSV: single amount column' => sub {
	# A one-column file where the only value is a number.  Must synthesise
	# "amount" as the single column name and return all rows.
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/onecol.csv")->spew(
		"-10.00\n-20.00\n30.00\n"
	);
	my $src;
	lives_ok { $src = Database::BI::Model::DataSource->new(directory => $dir, table => 'onecol') }
		'single-amount-column CSV accepted without error';
	is_deeply $src->columns, ['Amount'], 'single synthesized column: Amount';
	is $src->id_column, 'Amount',        'id_column is Amount';
	my $rows = eval { $src->fetch_all };
	is $@, '', 'fetch_all does not throw';
	is scalar @{$rows}, 3, 'all three rows returned';
	is $rows->[2]{Amount}, '30.00', 'third row Amount correct';
};

subtest 'DataSource -- headerless CSV: many numeric columns -> amount2, amount3 ...' => sub {
	# Three numeric columns must be disambiguated as amount, amount2, amount3.
	# At least one value in the first row must be signed so _values_are_data_like
	# fires; positive-only decimals ("100.00") are not signed and don't trigger it.
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/multiamt.csv")->spew(
		"-100.00,200.00,300.00\n-400.00,500.00,600.00\n"
	);
	my $src;
	lives_ok { $src = Database::BI::Model::DataSource->new(directory => $dir, table => 'multiamt') }
		'three-amount-column CSV accepted';
	is_deeply $src->columns, [qw(Amount Amount2 Amount3)],
		'three numeric cols synthesised as Amount, Amount2, Amount3';
	my $rows = eval { $src->fetch_all };
	is scalar @{$rows}, 2,        'two rows returned';
	is $rows->[0]{Amount2}, '200.00', 'Amount2 on row 1 correct';
};

subtest 'DataSource -- headerless CSV: hyphenated names NOT treated as headerless' => sub {
	# "first-name" fails $SAFE_IDENTIFIER but looks like a header (no date/number).
	# _values_are_data_like must return false; croak error_no_safe_id as before.
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/hyphdr.csv")->spew(
		"first-name,last-name\nAlice,Smith\n"
	);
	throws_ok {
		Database::BI::Model::DataSource->new(directory => $dir, table => 'hyphdr')
	} qr/no column with a safe identifier/i,
		'hyphenated-header CSV still croaks error_no_safe_id (not treated as headerless)';
};

subtest 'DataSource -- headerless CSV via HTTP: /open returns 200 with data' => sub {
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/bank-export.csv")->spew(
		"2026-09-01,-75.00,SUPERMARKET\n" .
		"2026-09-02,-12.50,COFFEE SHOP\n"
	);
	use Mojo::Util qw(url_escape);
	my $path = "$dir/bank-export.csv";
	$t->get_ok('/open?path=' . url_escape($path))
	  ->status_is(200, 'headerless CSV opens successfully via /open')
	  ->content_like(qr/SUPERMARKET/i, 'description column value appears in rendered page')
	  ->content_like(qr/-75/,           'amount value appears in rendered page');
};

# ---------------------------------------------------------------------------
# Section 15: Empty and near-empty file handling
#
# Strategy: verify that 0-byte files and files containing only a newline are
# handled gracefully — no crash, no 500, no misleading "no safe identifier"
# error.  The expected behaviour is an empty table view (200 OK, "No records
# found") rather than an error page, for both CSV and PSV.
#
# A file with a blank first line is effectively empty: _detect_file_info
# returns the _file_is_empty sentinel (same path as a 0-byte file), so
# _init_backend skips Database::Abstraction entirely and fetch_all returns [].
# ---------------------------------------------------------------------------

# 0-byte CSV via DataSource constructor
subtest 'DataSource -- 0-byte CSV: fetch_all returns [] without croak' => sub {
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/emptysrc.csv")->spew('');
	my $src;
	lives_ok {
		$src = Database::BI::Model::DataSource->new(directory => $dir, table => 'emptysrc');
	} '0-byte CSV: constructor succeeds';
	my $rows = $src->fetch_all;
	is_deeply $rows, [], '0-byte CSV: fetch_all returns []';
};

# 0-byte PSV via DataSource constructor
subtest 'DataSource -- 0-byte PSV: fetch_all returns [] without croak' => sub {
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/emptypsv.psv")->spew('');
	my $src;
	lives_ok {
		$src = Database::BI::Model::DataSource->new(directory => $dir, table => 'emptypsv');
	} '0-byte PSV: constructor succeeds';
	my $rows = $src->fetch_all;
	is_deeply $rows, [], '0-byte PSV: fetch_all returns []';
};

# Newline-only CSV via DataSource constructor
subtest 'DataSource -- newline-only CSV: fetch_all returns [] without croak' => sub {
	# A file containing exactly "\n" has a blank first line.  After chomp the
	# line is "", yielding zero column names.  This must be treated as an empty
	# file (returning []), not as "no safe identifier" (which would croak).
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/newlinecsv.csv")->spew("\n");
	my $src;
	lives_ok {
		$src = Database::BI::Model::DataSource->new(directory => $dir, table => 'newlinecsv');
	} 'newline-only CSV: constructor succeeds (no croak)';
	my $rows = $src->fetch_all;
	is_deeply $rows, [], 'newline-only CSV: fetch_all returns []';
};

# Newline-only PSV via DataSource constructor
subtest 'DataSource -- newline-only PSV: fetch_all returns [] without croak' => sub {
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/newlinepsv.psv")->spew("\n");
	my $src;
	lives_ok {
		$src = Database::BI::Model::DataSource->new(directory => $dir, table => 'newlinepsv');
	} 'newline-only PSV: constructor succeeds (no croak)';
	my $rows = $src->fetch_all;
	is_deeply $rows, [], 'newline-only PSV: fetch_all returns []';
};

# 0-byte CSV via HTTP /open endpoint
subtest 'HTTP -- 0-byte CSV via /open: 200 with empty-table message' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $path = "$dir/emptyhttp.csv";
	Mojo::File->new($path)->spew('');
	$t->get_ok('/open?path=' . url_escape($path))
	  ->status_is(200, '0-byte CSV: /open returns 200')
	  ->content_like(qr/No records found/i, '0-byte CSV: empty-state message present');
};

# 0-byte PSV via HTTP /open endpoint
subtest 'HTTP -- 0-byte PSV via /open: 200 with empty-table message' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $path = "$dir/emptyhttppsv.psv";
	Mojo::File->new($path)->spew('');
	$t->get_ok('/open?path=' . url_escape($path))
	  ->status_is(200, '0-byte PSV: /open returns 200')
	  ->content_like(qr/No records found/i, '0-byte PSV: empty-state message present');
};

# Newline-only CSV via HTTP /open endpoint
subtest 'HTTP -- newline-only CSV via /open: 200 with empty-table message' => sub {
	# Regression guard: before the _file_is_empty fix, a blank first line caused
	# _init_backend to croak "no safe identifier", and the controller rendered a
	# 200 error page — but the error message was confusing for what is simply an
	# empty file.  After the fix, the response is a clean empty-table view.
	my $dir  = tempdir(CLEANUP => 1);
	my $path = "$dir/nlcsv.csv";
	Mojo::File->new($path)->spew("\n");
	$t->get_ok('/open?path=' . url_escape($path))
	  ->status_is(200, 'newline-only CSV: /open returns 200')
	  ->content_like(qr/No records found/i, 'newline-only CSV: empty-state message present');
};

# Newline-only PSV via HTTP /open endpoint
subtest 'HTTP -- newline-only PSV via /open: 200 with empty-table message' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $path = "$dir/nlpsv.psv";
	Mojo::File->new($path)->spew("\n");
	$t->get_ok('/open?path=' . url_escape($path))
	  ->status_is(200, 'newline-only PSV: /open returns 200')
	  ->content_like(qr/No records found/i, 'newline-only PSV: empty-state message present');
};

# ---------------------------------------------------------------------------
# Section 16: _safe_back_url -- XSS / scheme injection guard
#
# Strategy: Verify that the _safe_back_url helper (added to fix the reflected
# XSS where javascript: URIs passed through | html unchanged and executed on
# click) correctly allows safe URLs and blocks hostile schemes.
# ---------------------------------------------------------------------------

Readonly my $SAFE_BACK_URL => \&Database::BI::Controller::Dashboard::_safe_back_url;

subtest '_safe_back_url -- javascript: scheme is blocked' => sub {
	is $SAFE_BACK_URL->('javascript:alert(1)'),     undef, 'bare javascript: blocked';
	is $SAFE_BACK_URL->('javascript:void(0)'),      undef, 'javascript:void(0) blocked';
	is $SAFE_BACK_URL->('JAVASCRIPT:alert(1)'),     undef, 'JAVASCRIPT: (caps) blocked';
	is $SAFE_BACK_URL->('Javascript:alert(1)'),     undef, 'Javascript: (mixed) blocked';
};

subtest '_safe_back_url -- data: and vbscript: schemes are blocked' => sub {
	is $SAFE_BACK_URL->('data:text/html,<h1>XSS'),  undef, 'data: scheme blocked';
	is $SAFE_BACK_URL->('vbscript:MsgBox(1)'),      undef, 'vbscript: scheme blocked';
	is $SAFE_BACK_URL->('DATA:text/html,foo'),       undef, 'DATA: (caps) blocked';
};

subtest '_safe_back_url -- relative paths are allowed' => sub {
	is $SAFE_BACK_URL->('/view/sales'),              '/view/sales',     'root-relative path allowed';
	is $SAFE_BACK_URL->('/pie?l=table:sales'),       '/pie?l=table:sales', 'root-relative with query allowed';
	is $SAFE_BACK_URL->('/open?path=/tmp/f.csv'),    '/open?path=/tmp/f.csv', 'root-relative open path allowed';
};

subtest '_safe_back_url -- http/https absolute URLs are allowed' => sub {
	is $SAFE_BACK_URL->('https://example.com/path'), 'https://example.com/path', 'https: allowed';
	is $SAFE_BACK_URL->('http://example.com/'),      'http://example.com/',      'http: allowed';
	is $SAFE_BACK_URL->('HTTPS://EXAMPLE.COM/'),     'HTTPS://EXAMPLE.COM/',     'HTTPS (caps) allowed';
};

subtest '_safe_back_url -- undef, empty, and non-path strings are blocked' => sub {
	is $SAFE_BACK_URL->(undef),   undef, 'undef blocked';
	is $SAFE_BACK_URL->(''),      undef, 'empty string blocked';
	is $SAFE_BACK_URL->('  '),    undef, 'whitespace-only blocked';
	is $SAFE_BACK_URL->('alert(1)'), undef, 'bare JS expression blocked';
	is $SAFE_BACK_URL->('//evil.com'), undef, 'protocol-relative URL blocked';
};

# ---------------------------------------------------------------------------
# Section 17: HTTP back= and back2= XSS reflected in the rendered page
#
# Strategy: Send requests with javascript: payloads in back= (pie, graph) and
# back2= (dashboard) params.  Verify the rendered HTML does NOT contain the
# raw javascript: string as an href value -- it must be sanitized away
# (rendered as "/" fallback or entirely absent from the breadcrumb).
# ---------------------------------------------------------------------------

subtest 'GET /pie?back=javascript:alert(1) -- javascript: not reflected in href' => sub {
	eval { require HTML::D3 } or plan skip_all => 'HTML::D3 not available';

	$t->get_ok(
		'/pie?l=table:sales&cat=region&val=amount'
		. '&back=' . url_escape('javascript:alert(1)')
	)->status_is(200)
	 ->content_unlike(qr{href="javascript:}, 'javascript: not in any href after sanitisation')
	 ->content_unlike(qr{data-back-url="javascript:}, 'javascript: not in data-back-url attr');
};

subtest 'GET /graph?back=javascript:alert(1) -- javascript: not reflected in href' => sub {
	eval { require HTML::D3 } or plan skip_all => 'HTML::D3 not available';

	$t->get_ok(
		'/graph?l=table:sales&x=sale_date&y=amount'
		. '&back=' . url_escape('javascript:alert(1)')
	)->status_is(200)
	 ->content_unlike(qr{href="javascript:}, 'javascript: not in graph page href');
};

subtest 'GET /open?back2=javascript:alert(1) -- javascript: not in third breadcrumb' => sub {
	my $enc = url_escape(File::Spec->rel2abs('data/sales.csv'));
	$t->get_ok(
		"/open?path=$enc"
		. '&back2=' . url_escape('javascript:alert(1)')
		. '&back2_label=XSS'
	)->status_is(200)
	 ->content_unlike(qr{href="javascript:}, 'javascript: blocked from back2 href')
	 ->content_unlike(qr{href="[^"]*javascript:}, 'no javascript: in any href');
};

subtest 'GET /view/sales?back2=javascript:alert(1) -- promoted back2 blocked' => sub {
	# view promotes back2 to back_url; the javascript: scheme must still be blocked
	$t->get_ok(
		'/view/sales'
		. '?back2=' . url_escape('javascript:alert(1)')
		. '&back2_label=XSS'
	)->status_is(200)
	 ->content_unlike(qr{href="javascript:}, 'javascript: not promoted to back href');
};

subtest 'GET /view/sales?back2=data:text/html,XSS -- data: scheme blocked' => sub {
	$t->get_ok(
		'/view/sales'
		. '?back2=' . url_escape('data:text/html,<b>xss</b>')
		. '&back2_label=D'
	)->status_is(200)
	 ->content_unlike(qr{href="data:}, 'data: URI not reflected in href');
};

subtest 'GET /open?back2_label=<script> -- label is HTML-encoded by TT | html' => sub {
	my $enc = url_escape(File::Spec->rel2abs('data/sales.csv'));
	# Even with a sanitised back2_url, a hostile label must be HTML-encoded.
	$t->get_ok(
		"/open?path=$enc"
		. '&back2=' . url_escape('/view/sales')
		. '&back2_label=' . url_escape('<script>alert(1)</script>')
	)->status_is(200)
	 ->content_unlike(qr{<script>alert},   'raw <script> tag not in label')
	 ->content_like(qr{&lt;script&gt;|&amp;lt;script&amp;gt;}, 'script tag is HTML-encoded');
};

subtest 'GET /view/sales?back2=/view/sales -- legitimate relative URL passes through' => sub {
	$t->get_ok(
		'/view/sales?back2=' . url_escape('/view/sales') . '&back2_label=Back+to+sales'
	)->status_is(200)
	 ->content_like(qr{href="/view/sales"}, 'legitimate relative back2 URL rendered in breadcrumb');
};

# ---------------------------------------------------------------------------
# Section 18: graph_view hostile data inputs
#
# Strategy: Test what graph_view does when the Y column contains all
# non-numeric values, all empty values, or extreme numbers.
# ---------------------------------------------------------------------------

subtest 'GET /graph -- all-text Y column returns "No plottable data"' => sub {
	eval { require HTML::D3 } or plan skip_all => 'HTML::D3 not available';

	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/textonly.csv")->spurt(
		"label,description\nA,hello\nB,world\n"
	);
	$t->get_ok(
		'/graph?l=path:' . url_escape("$dir/textonly.csv") . '&x=label&y=description'
	)->status_is(200)
	 ->content_like(qr/No plottable data/i, 'all-text Y column: No plottable data message');
};

subtest 'GET /graph -- all-empty Y values return "No plottable data"' => sub {
	eval { require HTML::D3 } or plan skip_all => 'HTML::D3 not available';

	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/emptyvals.csv")->spurt(
		"label,score\nA,\nB,\nC,\n"
	);
	$t->get_ok(
		'/graph?l=path:' . url_escape("$dir/emptyvals.csv") . '&x=label&y=score'
	)->status_is(200)
	 ->content_like(qr/No plottable data/i, 'all-empty Y values: No plottable data message');
};

subtest 'GET /graph -- accounting-notation negatives in Y are handled correctly' => sub {
	eval { require HTML::D3 } or plan skip_all => 'HTML::D3 not available';

	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/accounting.csv")->spurt(
		"month,amount\nJan,(1500.00)\nFeb,2000.00\nMar,(500.00)\n"
	);
	# The chart must render (not "No plottable data") and the page must not crash.
	$t->get_ok(
		'/graph?l=path:' . url_escape("$dir/accounting.csv") . '&x=month&y=amount'
	)->status_is(200)
	 ->content_unlike(qr/No plottable data/i, 'accounting negatives are plottable')
	 ->content_like(qr/Jan/,                  'Jan label appears in graph output');
};

# ---------------------------------------------------------------------------
# Section 19: pie_view hostile data inputs
#
# Strategy: Category names containing HTML metacharacters must be entity-encoded
# in the slice output to prevent reflected XSS through data values.
# ---------------------------------------------------------------------------

subtest 'GET /pie -- XSS payload in category name does not crash the page' => sub {
	eval { require HTML::D3 } or plan skip_all => 'HTML::D3 not available';

	my $dir = tempdir(CLEANUP => 1);
	# Category name contains an XSS payload.  HTML::D3 embeds data as JSON inside
	# a <script> block; the label is rendered via D3's .text() (not innerHTML) so
	# it does not execute as HTML.  The critical check is that the page loads (200)
	# and the back-url mechanism does not reflect the payload as an executable href.
	Mojo::File->new("$dir/xsscat.csv")->spurt(
		"region,amount\n"
		. "<script>alert(1)</script>,1000\n"
		. "North,2000\n"
	);
	$t->get_ok(
		'/pie?l=path:' . url_escape("$dir/xsscat.csv") . '&cat=region&val=amount'
	)->status_is(200, 'XSS category name: page renders without crash')
	 ->content_unlike(qr{href="javascript:}, 'javascript: scheme not in any href on XSS-category pie page');
};

subtest 'GET /pie -- all-zero amounts render pie without crash' => sub {
	eval { require HTML::D3 } or plan skip_all => 'HTML::D3 not available';

	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/zeroes.csv")->spurt(
		"region,amount\nNorth,0\nSouth,0\nEast,0\n"
	);
	# D3 pie with all-zero values might render empty; the controller must not crash.
	$t->get_ok(
		'/pie?l=path:' . url_escape("$dir/zeroes.csv") . '&cat=region&val=amount'
	)->status_is(200, 'all-zero amounts: page renders (200 or No plottable data, not 500)');
};

subtest 'GET /pie -- very long category name does not crash the page' => sub {
	eval { require HTML::D3 } or plan skip_all => 'HTML::D3 not available';

	my $dir = tempdir(CLEANUP => 1);
	my $long_name = 'A' x 500;
	Mojo::File->new("$dir/longcat.csv")->spurt(
		"region,amount\n${long_name},9999\nNorth,1000\n"
	);
	$t->get_ok(
		'/pie?l=path:' . url_escape("$dir/longcat.csv") . '&cat=region&val=amount'
	)->status_is(200, '500-char category name: page renders without crash');
};

# ---------------------------------------------------------------------------
# Section 20: export_write path traversal -- filename sanitisation
#
# Strategy: Confirm the export_write action strips path separators from the
# filename param so an attacker cannot write to an arbitrary filesystem
# location by supplying ../../etc/passwd.csv as the filename.
# ---------------------------------------------------------------------------

subtest 'POST /export -- filename with ../ is sanitized to basename only' => sub {
	my $out_dir = tempdir(CLEANUP => 1);

	# Attempt to write to ../../evil.csv by supplying a traversal filename.
	$t->post_ok('/export', form => {
		l        => 'table:sales',
		dir      => $out_dir,
		filename => '../../evil.csv',
	})->status_is(200)
	  ->json_has('/saved');

	my $saved = $t->tx->res->json('/saved');
	# The saved path must be inside $out_dir, not two levels up.
	like $saved, qr{\Q$out_dir\E}, 'saved path is inside the requested output dir';
	unlike $saved, qr{\.\.},       'saved path contains no .. components';
};

subtest 'POST /export -- absolute path as filename is stripped to basename' => sub {
	my $out_dir = tempdir(CLEANUP => 1);
	$t->post_ok('/export', form => {
		l        => 'table:sales',
		dir      => $out_dir,
		filename => '/etc/cron.d/payload.csv',
	})->status_is(200)
	  ->json_has('/saved');

	my $saved = $t->tx->res->json('/saved');
	# Must land inside the specified output directory.
	like $saved, qr{\Q$out_dir\E}, 'absolute-path filename written inside the output dir only';
};

# ---------------------------------------------------------------------------
# Section 21: /combine hostile inputs
#
# Strategy: Verify graceful degradation when the left source is missing (404)
# or a combined source is invalid (silently skipped).
# ---------------------------------------------------------------------------

subtest 'GET /combine -- missing l= param returns 404' => sub {
	$t->get_ok('/combine')
	  ->status_is(404, 'combine with no l= param returns 404');
};

subtest 'GET /combine -- invalid c= spec is silently skipped' => sub {
	# combine_tables silently skips a c= spec that cannot be opened.
	# The result must still return 200 with just the left table's data.
	$t->get_ok(
		'/combine?l=' . url_escape('table:sales')
		. '&c=' . url_escape('path:/nonexistent/file.csv')
	)->status_is(200, 'combine with invalid c= skips bad source gracefully')
	 ->content_like(qr/Widget A/, 'left table data visible despite bad c= spec');
};

subtest 'GET /combine -- l= pointing to non-existent file returns 404' => sub {
	$t->get_ok(
		'/combine?l=' . url_escape('path:/nonexistent/missing.csv')
	)->status_is(404, 'combine with non-existent left source returns 404');
};

done_testing();
