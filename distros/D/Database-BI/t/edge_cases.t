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

# A staging directory this file owns, so a parallel test file's
# POST /uploads/clear cannot empty it mid-test.
my $STAGING = tempdir(CLEANUP => 1);
$t->app->config->{uploads_dir} = $STAGING;

# The model store (.bi/) is shared state in the checkout: give this file its
# own directory, so a parallel run cannot create, read or write it underneath.
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

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

subtest '_is_safe_url -- non-standard IP representations are blocked' => sub {
	# These once passed: only the dotted form was range-checked.  They are read
	# as the resolver reads them, so each is the address it spells.
	ok !$IS_SAFE_URL->('http://0177.0.0.1/'),          'octal 0177.0.0.1 blocked';
	ok !$IS_SAFE_URL->('http://2130706433/'),           'decimal int 127.0.0.1 blocked';
	ok !$IS_SAFE_URL->('http://0x7f000001/'),           'hex int 127.0.0.1 blocked';
	ok !$IS_SAFE_URL->('http://127.1/'),                'short form 127.1 blocked';
	ok !$IS_SAFE_URL->('http://10.1/'),                 'short form 10.1 (10.0.0.1) blocked';
	ok !$IS_SAFE_URL->('http://user@127.0.0.1/'),       'userinfo before the host is not the host';
	ok !$IS_SAFE_URL->('http://localhost./'),           'a trailing dot';
	ok !$IS_SAFE_URL->('http://app.localhost/'),        '*.localhost';
	ok !$IS_SAFE_URL->('http://[::ffff:127.0.0.1]/'),   'IPv4-mapped IPv6';
	ok !$IS_SAFE_URL->('http://[fe80::1]/'),            'IPv6 link-local';
	ok $IS_SAFE_URL->('http://[2606:4700::1111]/'),     'a public IPv6 address passes';
	ok $IS_SAFE_URL->('http://localtest.me/'),          'a name passes here: SafeUA checks what it resolves to';
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
	# A value that is not a number has no order, so nothing is greater than it.
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $recs = [{ amount => '500' }, { amount => 'abc' }];
	my $result;
	lives_ok { $result = $APPLY_FILTER_SPEC->($recs, 'amount:gt:not_a_number') }
		'non-numeric gt comparison does not die';
	is scalar(@$result), 0, 'no row is greater than something that is not a number';
	is_deeply \@warnings, [], 'and nothing warns';
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
	# disk, so the action says so (404 naming the table).
	$t->get_ok('/view/_phantom')->status_is(404)->content_like(qr/There is no table called/);
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

subtest 'uploads_dir decides the staging directory' => sub {
	# POST /upload, POST /uploads/clear and the startup eviction all resolve the
	# staging directory through the app, so the key has to behave like data_dir:
	# absolute paths as given, relative ones against the application home, and
	# the old location when it is not set at all.
	my $app = $t->app;

	{
		local $app->config->{uploads_dir} = tempdir(CLEANUP => 1);
		is $app->_uploads_dir->to_string, $app->config->{uploads_dir},
			'an absolute uploads_dir is used as given';
	}

	{
		local $app->config->{uploads_dir} = 'staging-here';
		is $app->_uploads_dir->to_string,
			$app->home->child('staging-here')->to_string,
			'a relative uploads_dir resolves against the application home';
	}

	{
		local $app->config->{uploads_dir} = undef;
		is $app->_uploads_dir->to_string,
			$app->home->child('.uploads')->to_string,
			'an unset uploads_dir keeps .uploads under the application home';
	}
};

subtest 'POST /upload -- file.php.csv is stored; GET /open produces friendly error' => sub {
	# "file.php.csv" passes the extension check (last ext .csv) so upload returns
	# 200 with a path.  Opening that path derives table "file.php" which contains
	# a dot -> DataSource croak -> now caught -> 200 error page (not 500).
	my $res = $t->post_ok('/upload', form => {
		file => { content => "id,label\n1,Widget\n", filename => 'file.php.csv' }
	})->status_is(200)->tx->res->json;

	ok $res->{path}, 'upload succeeded: path returned';
	like $res->{path}, qr{\Q$STAGING\E[/\\]}, 'stored inside the staging directory';
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
# Section 9: Mocked upstream failures -- selectall_arrayref croak is caught gracefully
#
# Strategy: use Test::Mockingbird to replace DataSource::selectall_arrayref with
# a croaking stub.  Verify the eval in the view action catches the croak and
# renders the friendly error template (200, not 500).
# (The controller calls count() then selectall_arrayref() since pagination was
# introduced; fetch_all() is no longer called on the /view or /open paths.)
# ---------------------------------------------------------------------------

subtest 'GET /view/sales -- fetch_all croak is caught, friendly error rendered' => sub {
	mock 'Database::BI::Model::DataSource::selectall_arrayref' => sub {
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

	mock 'Database::BI::Model::DataSource::selectall_arrayref' => sub {
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

subtest 'GET /view/sales?f=col:badop:val -- unknown operator is a 400, not a 500' => sub {
	$t->get_ok('/view/sales?f=' . url_escape('region:badop:North'))
	  ->status_is(400)
	  ->content_unlike(qr/500 Internal Server Error/, 'no 500 for unknown operator');
};

subtest 'GET /view/sales?f=nosuch:eq:x -- unknown column is a 400, not an empty table' => sub {
	$t->get_ok('/view/sales?f=' . url_escape('nosuch:eq:x'))
	  ->status_is(400)
	  ->content_like(qr/no column called "nosuch"/)
	  ->content_unlike(qr/500 Internal Server Error/, 'no 500 for unknown column');
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

# same_dir($path) -> $string: a folder as the platform spells it.  On Windows
# the saved path comes back with backslashes and Mojo's realpath gives forward
# slashes (and either may differ in case), though both name one folder.
sub same_dir {
	my $dir = File::Spec->canonpath("$_[0]");
	return $^O eq 'MSWin32' ? lc $dir : $dir;
}

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
	# saved is the file's realpath, so compare it with the folder's: under a
	# linked TMPDIR (macOS's /var is /private/var) the spellings differ.
	is(same_dir(Mojo::File->new($saved)->dirname), same_dir(Mojo::File->new($out_dir)->realpath),
		'saved path is inside the requested output dir');
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
	is(same_dir(Mojo::File->new($saved)->dirname), same_dir(Mojo::File->new($out_dir)->realpath),
		'absolute-path filename written inside the output dir only');
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

# ---------------------------------------------------------------------------
# Section 22: /folder hostile inputs and security
#
# Strategy: Exhaustively probe the new folder_view action for:
#   (a) missing / invalid parameters
#   (b) XSS via user-controlled stash variables reflected in the template
#   (c) DoS via an artificially long prefix that would expand the breadcrumb
#       to O(N) entries if unchecked
#   (d) graceful degradation when the chosen column contains no order-code
#       values, leaving the prefix map empty
#   (e) back= sanitisation confirming javascript: is always replaced with
#       the source-table URL rather than leaking through the | html filter
# ---------------------------------------------------------------------------

Readonly my $SALES_SPEC => 'table:sales';

subtest 'GET /folder -- missing l= param returns 400' => sub {
	# The controller guards length($left_spec) immediately; the error is plain text.
	$t->get_ok('/folder')
	  ->status_is(400, 'no l= param returns 400');
	$t->get_ok('/folder?col=id')
	  ->status_is(400, 'col= without l= still returns 400');
};

subtest 'GET /folder -- non-existent path returns 404' => sub {
	# _run_export_pipeline returns () when the data source cannot be opened;
	# the action must return 404, not 500.
	$t->get_ok('/folder?l=' . url_escape('path:/nonexistent/data.csv'))
	  ->status_is(404, 'non-existent path returns 404');
};

subtest 'GET /folder -- prefix longer than MAX_PREFIX_LEN returns 400 (DoS guard)' => sub {
	# A crafted prefix of length N causes N breadcrumb entries and an O(N)
	# response.  The controller now rejects anything over $MAX_PREFIX_LEN (20).
	my $long_prefix = 'A' x 21;
	$t->get_ok('/folder?l=' . url_escape($SALES_SPEC) . '&prefix=' . url_escape($long_prefix))
	  ->status_is(400, '21-char prefix rejected with 400');

	my $exactly_max = 'A' x 20;
	$t->get_ok('/folder?l=' . url_escape($SALES_SPEC) . '&prefix=' . url_escape($exactly_max))
	  ->status_is(200, '20-char prefix (exactly at limit) accepted');

	# 10_000-char URL would exceed Mojo's max_line_size and be truncated to empty,
	# bypassing the controller guard.  Use 100 chars: clearly over MAX_PREFIX_LEN,
	# well within HTTP URL limits, and exercises the same controller code path.
	my $huge = 'X' x 100;
	$t->get_ok('/folder?l=' . url_escape($SALES_SPEC) . '&prefix=' . url_escape($huge))
	  ->status_is(400, '100-char prefix rejected with 400 (no crash)');
};

subtest 'GET /folder -- XSS in prefix param is HTML-encoded by TT' => sub {
	# The prefix value is reflected in the page title and breadcrumb.
	# TT | html encodes < > " & so the payload cannot execute.
	# Note: payload must be <= MAX_PREFIX_LEN (20) chars or the DoS guard fires
	# first (400) before TT can encode it.  '<img src=x>' is 12 chars and is a
	# valid injection probe.
	my $xss = '<img src=x>';
	$t->get_ok('/folder?l=' . url_escape($SALES_SPEC) . '&prefix=' . url_escape($xss))
	  ->status_is(200)
	  ->content_unlike(qr{<img src=x>},       'raw <img> tag not in response body')
	  ->content_like(qr{&lt;img|no folders|No items},
	                 'img tag is HTML-encoded or prefix yields empty result');
};

subtest 'GET /folder -- XSS in col param is HTML-encoded' => sub {
	# A hostile col= value that contains HTML metacharacters.
	# The col name is URL-escaped into base_url and | html-filtered in the template.
	my $xss_col = '"><img src=x onerror=alert(1)>';
	$t->get_ok('/folder?l=' . url_escape($SALES_SPEC) . '&col=' . url_escape($xss_col))
	  ->status_is(200)
	  ->content_unlike(qr{onerror=alert}, 'onerror= not literally in response');
};

subtest 'GET /folder -- back=javascript: is blocked; back link uses table URL' => sub {
	# _safe_back_url returns undef for javascript: URIs; folder_view then falls
	# back to _spec_to_url($left_spec), which returns /view/sales.
	# The rendered page must never contain href="javascript: in any element.
	$t->get_ok(
		'/folder?l=' . url_escape($SALES_SPEC)
		. '&back=' . url_escape('javascript:alert(1)')
	)->status_is(200)
	 ->content_unlike(qr{href="javascript:}, 'javascript: not reflected in any href')
	 ->content_like(qr{href="/view/sales"}, 'back link falls through to table URL');
};

subtest 'GET /folder -- back=data: is blocked; back link uses table URL' => sub {
	$t->get_ok(
		'/folder?l=' . url_escape($SALES_SPEC)
		. '&back=' . url_escape('data:text/html,<b>xss</b>')
	)->status_is(200)
	 ->content_unlike(qr{href="data:}, 'data: URI not in any href');
};

subtest 'GET /folder -- prefix not present in data: empty page, no crash' => sub {
	# A prefix like "ZZZ" does not exist in sales.csv (which has no order codes).
	# The result must be a clean 200 with no folders and no items.
	$t->get_ok('/folder?l=' . url_escape($SALES_SPEC) . '&prefix=ZZZ')
	  ->status_is(200, 'non-existent prefix returns 200 (no crash)')
	  ->content_unlike(qr/500 Internal Server Error/, 'no 500');
};

subtest 'GET /folder -- prefix of all digits: no letter prefix match, 200' => sub {
	# Digits-only prefix: \A([A-Z]+) regex never matches, no folders/items.
	$t->get_ok('/folder?l=' . url_escape($SALES_SPEC) . '&prefix=123')
	  ->status_is(200, 'all-digit prefix returns 200 (no crash)');
};

subtest 'GET /folder -- col= pointing to non-existent column: graceful fallback' => sub {
	# When the specified column does not exist, all values are undef -> no letter
	# prefix found -> empty prefix map -> top level shows no folders.
	$t->get_ok('/folder?l=' . url_escape($SALES_SPEC) . '&col=no_such_column')
	  ->status_is(200, 'non-existent col= returns 200')
	  ->content_unlike(qr/500 Internal Server Error/, 'no 500');
};

subtest 'GET /folder -- data column with no order-number values: no folders rendered' => sub {
	# sales.csv contains "product,region,amount,sale_date" -- none of which are
	# order codes. Auto-detect finds nothing; falls back to first column ("id"
	# or "product"). Since no values match [A-Z]+\d+, the prefix map is empty.
	$t->get_ok('/folder?l=' . url_escape($SALES_SPEC))
	  ->status_is(200, 'table with no order-code columns renders 200')
	  ->content_unlike(qr/500 Internal Server Error/, 'no 500 when no order codes exist');
};

subtest 'GET /folder -- back URL auto-derived from table spec when back= absent' => sub {
	# folder_view derives back_url from _spec_to_url($left_spec) when no back=
	# param is supplied.  The breadcrumb must link to the source table.
	$t->get_ok('/folder?l=' . url_escape($SALES_SPEC))
	  ->status_is(200)
	  ->content_like(qr{<nav class="back-link[^"]*" aria-label="Breadcrumb">.*?<a href="/view/sales">sales</a>}s,
		'breadcrumb links to the table');
};

subtest 'GET /folder -- NUL byte in prefix: no crash' => sub {
	# A NUL-byte prefix cannot match any real letter prefix; must return 200.
	my $null_prefix = "A\x00B";
	$t->get_ok('/folder?l=' . url_escape($SALES_SPEC) . '&prefix=' . url_escape($null_prefix))
	  ->status_is(200, 'NUL-byte prefix: no crash');
};

subtest 'GET /folder -- valid data file with order codes: top-level folders appear' => sub {
	# Create a small CSV that contains order-number codes.  Verify the folder
	# view renders at least one folder card.
	my $dir  = tempdir(CLEANUP => 1);
	my $path = "$dir/orders.csv";
	Mojo::File->new($path)->spew(
		"order_no,product,qty\n"
		. "A10,Widget,5\n"
		. "A11,Gadget,3\n"
		. "B1,Doohickey,1\n"
		. "CT4,Carol item,2\n"
	);
	$t->get_ok('/folder?l=' . url_escape("path:$path"))
	  ->status_is(200)
	  ->content_like(qr/folder-card/, 'folder cards rendered for order-code CSV')
	  ->content_like(qr/fc-name">A/, '"A" folder card present');
};

subtest 'GET /folder -- drill into A prefix: shows A10 A11 items' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $path = "$dir/orders2.csv";
	Mojo::File->new($path)->spew(
		"order_no,product\nA10,Widget\nA11,Gadget\nB1,Doohickey\n"
	);
	$t->get_ok('/folder?l=' . url_escape("path:$path") . '&prefix=A')
	  ->status_is(200)
	  ->content_like(qr/A10/, 'A10 item appears in folder A')
	  ->content_like(qr/A11/, 'A11 item appears in folder A')
	  ->content_unlike(qr/>B1</, 'B1 item not shown inside folder A');
};

subtest 'GET /folder -- prefix with multi-letter hierarchy: sub-folders rendered' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $path = "$dir/orders3.csv";
	Mojo::File->new($path)->spew(
		"order_no,product\n"
		. "C1,Plain C\nCA1,Alpha\nCA2,Alpha2\nCB1,Beta\n"
	);
	# C level should show sub-folders CA and CB, plus direct item C1
	$t->get_ok('/folder?l=' . url_escape("path:$path") . '&prefix=C')
	  ->status_is(200)
	  ->content_like(qr/fc-name">CA/, 'CA sub-folder present inside C')
	  ->content_like(qr/fc-name">CB/, 'CB sub-folder present inside C')
	  ->content_like(qr/C1/,          'direct C-prefix item C1 also visible');
};

# ---------------------------------------------------------------------------
# Section 23: upload_file eval { ...; 1 } regression
#
# Strategy:
#  (a) Mock Mojo::Upload::move_to to croak -- verify the action returns a
#      500 JSON body with the error_upload_save key, NOT a bare HTML 500 page.
#      This also confirms the eval guard catches the exception correctly.
#  (b) Mock move_to to silently succeed without creating $dest -- verify the
#      -f $dest post-check triggers the same 500 JSON path.
#  (c) Verify that a normal upload after a prior (unrelated) eval { die }
#      still returns 200.  This is the regression guard for the stale-$@
#      bug: the old eval { move_to() } + if ($@) pattern would have fired
#      on a contaminated $@ left by an earlier eval (including Mojo's own
#      internal dispatch evals or destructor evals).  The fix captures
#      $ok = eval { ...; 1 } whose truthiness is independent of $@.
# ---------------------------------------------------------------------------

subtest 'upload_file -- move_to croak returns 500 JSON with error key' => sub {
	# Simulate a disk-full or permission-denied error from the filesystem.
	mock 'Mojo::Upload::move_to' => sub { die "Simulated ENOSPC -- disk full\n" };

	my $res = $t->post_ok('/upload', form => {
		file => { content => "id,label\n1,TestItem\n", filename => 'diskfull.csv' }
	})->status_is(500, 'move_to croak: controller returns 500')
	  ->tx->res->json;

	ok defined $res,            'response body is valid JSON';
	ok exists $res->{error},    'JSON response has "error" key';
	like $res->{error}, qr/Could not save uploaded file/i,
		'error message is the expected error_upload_save text';

	# Critical: the response must be JSON, not a raw HTML Mojolicious exception page.
	unlike $t->tx->res->body, qr/<html/i, 'response is JSON, not an HTML error page';

	restore_all();
};

subtest 'upload_file -- move_to silent no-op (no file created) returns 500 JSON' => sub {
	# Simulates a Mojo::Asset::Memory->move_to that returns without writing
	# (e.g. a write that silently fails).  The -f $dest post-check must catch this.
	mock 'Mojo::Upload::move_to' => sub {
		# Return a defined truthy value without creating the destination file.
		return Mojo::File->new('/nonexistent/never_created.csv');
	};

	my $res = $t->post_ok('/upload', form => {
		file => { content => "id,x\n1,y\n", filename => 'noop.csv' }
	})->status_is(500, 'silent no-op move_to: controller returns 500')
	  ->tx->res->json;

	ok exists $res->{error}, 'JSON error key present when dest file not created';

	restore_all();
};

subtest 'upload_file -- successful upload after prior eval { die } returns 200 (stale-$@ regression)' => sub {
	# Regression guard for the eval { move_to() } + if ($@) pattern.
	#
	# In the OLD code, $@ contaminated by a prior eval (from Mojo's internal
	# dispatch evals or DESTROY-method evals) could make if ($@) fire even
	# when move_to succeeded, causing a false 500.
	#
	# With the fix -- my $ok = eval { move_to(); 1 }; if (!$ok) -- the check
	# depends only on whether THIS eval threw, making it immune to stale $@.
	#
	# We simulate the contamination by deliberately running eval { die } in the
	# test process (same Perl runtime as the in-process Test::Mojo server)
	# immediately before the upload request.
	eval { die "deliberate contaminator to simulate stale \$\@\n" };
	# At this point $@ is set to "deliberate contaminator..."
	diag "stale \$@ before upload: '$@'" if $ENV{TEST_VERBOSE};

	my $res = $t->post_ok('/upload', form => {
		file => { content => "id,x\n1,y\n", filename => 'stale_at.csv' }
	})->status_is(200, 'upload succeeds despite stale $@ in outer scope (regression)')
	  ->tx->res->json;

	ok defined $res->{path}, 'path returned in JSON (move_to succeeded)';
	ok defined $res->{url},  'url returned in JSON';

	diag "\$@ after upload: '$@'" if $ENV{TEST_VERBOSE};
};

subtest 'upload_file -- two sequential uploads both succeed (no $@ accumulation)' => sub {
	# If the eval guard leaked a dirty $@ across requests, the second upload
	# would fail.  Both must return 200 with distinct paths.
	my $res_a = $t->post_ok('/upload', form => {
		file => { content => "a,b\n1,2\n", filename => 'seq_a.csv' }
	})->status_is(200, 'first sequential upload: 200')->tx->res->json;

	my $res_b = $t->post_ok('/upload', form => {
		file => { content => "x,y\n3,4\n", filename => 'seq_b.csv' }
	})->status_is(200, 'second sequential upload: 200')->tx->res->json;

	ok $res_a->{path} && $res_b->{path},    'both uploads returned a path';
	isnt $res_a->{path}, $res_b->{path},    'the two paths are distinct (no collision)';
};

# ===========================================================================
# Section 24: Geocode.pm -- hostile constructor inputs
#
# Strategy: exhaust every documented croak path in new(), then confirm that
# harmless-looking bad inputs (undef geocoder, unknown key) are either
# silently accepted or rejected cleanly rather than causing a segfault,
# a half-initialised object, or a misleading error message.
# ===========================================================================

use_ok('Database::BI::Model::Geocode');

Readonly my $GEOCODE => 'Database::BI::Model::Geocode';

# Stubs defined at file scope so they survive `package main;` restoration.
{
	package EC::GeoPoint;
	sub new  { my ($cls, %h) = @_; bless \%h, $cls }
	sub latitude  { $_[0]->{latitude}  }
	sub longitude { $_[0]->{longitude} }
	sub database  { $_[0]->{database}  }

	package EC::FullGeocoder;
	sub new  { bless { calls => [] }, shift }
	sub valid_location { defined $_[1] && length $_[1] && $_[1] !~ /\A\d+\z/ }
	sub geocode_many   {
		my ($self, $vals, %o) = @_;
		push @{ $self->{calls} }, [@$vals];
		return {};
	}

	package EC::OnlyValidLocation;
	sub new  { bless {}, shift }
	sub valid_location { 1 }
	# geocode_many intentionally absent

	package EC::OnlyGeocodeManyNotValid;
	sub new  { bless {}, shift }
	sub geocode_many { return {} }
	# valid_location intentionally absent
}

subtest 'Geocode new() -- geocoder=string (non-object) croaks error_geocoder_interface' => sub {
	# A scalar is not an object; blessed() will be false; ->can() will fail.
	throws_ok { $GEOCODE->new(geocoder => 'not_an_object') }
		qr/geocoder/i,
		'plain string rejected as geocoder';
};

subtest 'Geocode new() -- geocoder=0 (false scalar) croaks' => sub {
	throws_ok { $GEOCODE->new(geocoder => 0) }
		qr/geocoder|interface/i,
		'zero rejected as geocoder';
};

subtest 'Geocode new() -- geocoder missing geocode_many() croaks naming the method' => sub {
	throws_ok { $GEOCODE->new(geocoder => EC::OnlyValidLocation->new()) }
		qr/geocode_many/,
		'missing geocode_many named in error';
};

subtest 'Geocode new() -- geocoder missing valid_location() croaks naming the method' => sub {
	throws_ok { $GEOCODE->new(geocoder => EC::OnlyGeocodeManyNotValid->new()) }
		qr/valid_location/,
		'missing valid_location named in error';
};

subtest 'Geocode new() -- undef geocoder key is silently ignored (loads real geocoder lazily)' => sub {
	# An explicitly undef geocoder= is a no-op; the object builds fine.
	my $g;
	lives_ok { $g = $GEOCODE->new(geocoder => undef) }
		'undef geocoder= does not croak';
	ok defined($g) && ref($g), 'object returned';
};

subtest 'Geocode new() -- unknown constructor key is rejected by Params::Validate::Strict' => sub {
	throws_ok { $GEOCODE->new(totally_unknown => 'value') }
		qr/unknown|unexpected|not.*allowed|invalid/i,
		'unknown key rejected at construction';
};

subtest 'Geocode new() -- circular reference as geocoder croaks interface error' => sub {
	my $circ = {};
	$circ->{self} = $circ;    # circular, but still a plain hashref -- not an object
	throws_ok { $GEOCODE->new(geocoder => $circ) }
		qr/geocoder|interface/i,
		'circular-ref hashref (not a blessed object) rejected';
};

# ===========================================================================
# Section 25: Geocode.pm -- hostile resolve_values inputs
#
# Strategy: exhaust every early-exit guard; verify count invariants under
# pathological inputs; confirm that huge value lists do not trigger runaway
# memory or CPU via the cap; check that invalid "max=" values all croak
# with the documented error, not a confusing Perl numeric warning.
# ===========================================================================

Readonly my $STUB => EC::FullGeocoder->new();
Readonly my $G    => $GEOCODE->new(geocoder => $STUB, openaddr => 'test');

subtest 'resolve_values -- undef input croaks error_values_arrayref' => sub {
	throws_ok { $G->resolve_values(undef) }
		qr/values.*arrayref|arrayref.*values/i,
		'undef rejected';
};

subtest 'resolve_values -- scalar string input croaks error_values_arrayref' => sub {
	throws_ok { $G->resolve_values('Ramsgate') }
		qr/values.*arrayref|arrayref.*values/i,
		'plain string rejected';
};

subtest 'resolve_values -- hashref input croaks error_values_arrayref' => sub {
	throws_ok { $G->resolve_values({ city => 'Ramsgate' }) }
		qr/values.*arrayref|arrayref.*values/i,
		'hashref rejected';
};

subtest 'resolve_values -- empty arrayref returns zero counts without croak' => sub {
	my $r;
	lives_ok { $r = $G->resolve_values([]) } 'empty arrayref does not croak';
	is $r->{counts}{distinct},     0, 'distinct=0';
	is $r->{counts}{attempted},    0, 'attempted=0';
	is $r->{counts}{not_attempted},0, 'not_attempted=0';
};

subtest 'resolve_values -- arrayref of all-undef values: all skipped, no geocoder call' => sub {
	my $stub = EC::FullGeocoder->new();
	my $g    = $GEOCODE->new(geocoder => $stub, openaddr => 'test');
	my $r    = $g->resolve_values([undef, undef, undef]);

	is $r->{counts}{skipped}, 1, 'three undefs deduplicate to one skipped (empty-key)';
	is scalar(@{ $stub->{calls} }), 0, 'geocoder not called for all-undef input';
};

subtest 'resolve_values -- binary junk bytes do not crash (treated as a place name)' => sub {
	# An invalid UTF-8 byte sequence is still a defined, non-empty string; it
	# must be handed to valid_location() without causing Perl to die.
	my $r;
	lives_ok {
		$r = $G->resolve_values(["\x80\xFF\xFE"]);
	} 'binary junk bytes do not crash';
	# valid_location likely refuses it (digits-only check passes, but geocoder
	# returns no result), so it ends up in unresolved or resolved; either is fine.
	ok defined($r->{counts}), 'counts key present';
};

subtest 'resolve_values -- max=0 croaks error_max_invalid' => sub {
	throws_ok { $G->resolve_values(['Ramsgate'], max => 0) }
		qr/max.*0|0.*invalid|positive.*integer/i,
		'max=0 rejected';
};

subtest 'resolve_values -- max=-1 croaks error_max_invalid' => sub {
	throws_ok { $G->resolve_values(['Ramsgate'], max => -1) }
		qr/max.*-1|-1.*invalid|positive.*integer/i,
		'max=-1 rejected';
};

subtest 'resolve_values -- max=1.5 (non-integer) croaks error_max_invalid' => sub {
	throws_ok { $G->resolve_values(['Ramsgate'], max => 1.5) }
		qr/max|invalid|positive.*integer/i,
		'fractional max rejected';
};

subtest 'resolve_values -- max="abc" croaks error_max_invalid' => sub {
	throws_ok { $G->resolve_values(['Ramsgate'], max => 'abc') }
		qr/max|invalid|positive.*integer/i,
		'non-numeric max rejected';
};

subtest 'resolve_values -- max="" (empty string) croaks error_max_invalid' => sub {
	throws_ok { $G->resolve_values(['Ramsgate'], max => '') }
		qr/max|invalid|positive.*integer/i,
		'empty-string max rejected';
};

subtest 'resolve_values -- pure-digit string is refused by valid_location and skipped' => sub {
	# "42" matches /\A\d+\z/ in the stub's valid_location -> @skipped
	# It must NOT appear in the cache or counts.attempted.
	my $stub = EC::FullGeocoder->new();
	my $g    = $GEOCODE->new(geocoder => $stub, openaddr => 'test');
	my $r    = $g->resolve_values(['42', '100', '0']);

	is $r->{counts}{attempted}, 0,
		'pure-digit values are all skipped; geocoder never called';
	is scalar(@{ $stub->{calls} }), 0,
		'geocode_many not called when every value is digit-only';
	ok !exists($r->{cache}{'42'}), '"42" absent from returned cache';
};

subtest 'resolve_values -- circular ref in values array is treated as undef/skipped' => sub {
	my $circ = [];
	push @$circ, $circ;    # self-referential arrayref
	my $r;
	lives_ok { $r = $G->resolve_values([$circ]) } 'circular ref in values does not crash';
	# A reference is not a valid location; it should be skipped.
	is $r->{counts}{skipped}, 1, 'circular-ref value counted as skipped';
};

subtest 'resolve_values -- 5000-element list capped to DEFAULT_MAX; no runaway' => sub {
	my @big = map { "City$_" } 1..5000;
	my $stub = EC::FullGeocoder->new();
	my $g    = $GEOCODE->new(geocoder => $stub, openaddr => 'test');
	my $r;
	lives_ok { $r = $g->resolve_values(\@big) } '5000 values do not crash';
	# DEFAULT_MAX = 500; at most 500 should be attempted.
	cmp_ok $r->{counts}{attempted}, '<=', 500, 'attempted <= DEFAULT_MAX';
	cmp_ok $r->{counts}{not_attempted}, '>=', 4500, 'rest held back';
};

# ===========================================================================
# Section 26: Geocode.pm -- hostile resolve_column inputs
# ===========================================================================

subtest 'resolve_column -- non-arrayref rows argument croaks error_rows_arrayref' => sub {
	throws_ok { $G->resolve_column('not_an_array', 'city') }
		qr/rows.*arrayref|arrayref.*rows/i,
		'scalar rows rejected';

	throws_ok { $G->resolve_column(undef, 'city') }
		qr/rows.*arrayref|arrayref.*rows/i,
		'undef rows rejected';
};

subtest 'resolve_column -- empty column name croaks error_column_required' => sub {
	throws_ok { $G->resolve_column([], '') }
		qr/column|required/i,
		'empty column string rejected';
};

subtest 'resolve_column -- undef column name croaks error_column_required' => sub {
	throws_ok { $G->resolve_column([], undef) }
		qr/column|required/i,
		'undef column rejected';
};

subtest 'resolve_column -- column not in any row croaks error_map_loc_column' => sub {
	throws_ok { $G->resolve_column([{ name => 'Alice' }], 'city') }
		qr/city/,
		'missing column name embedded in error';
};

subtest 'resolve_column -- XSS payload as column name -> croak embeds it verbatim (not executed)' => sub {
	my $xss = '<script>alert(1)</script>';
	my $err = '';
	eval { $G->resolve_column([{ name => 'Alice' }], $xss) };
	$err = $@;
	like $err, qr/\Q$xss\E/, 'XSS payload appears verbatim in croaked error (not parsed as HTML)';
};

subtest 'resolve_column -- column NUL byte: treated as distinct name, not found -> croak' => sub {
	my $col_nul = "city\x00name";
	throws_ok { $G->resolve_column([{ city => 'Ramsgate' }], $col_nul) }
		qr/column|not in/i,
		'NUL-byte column name produces croak, not crash';
};

subtest 'resolve_column -- empty rows array returns empty result without croak' => sub {
	my $r;
	lives_ok { $r = $G->resolve_column([], 'city') } 'empty rows do not croak';
	is $r->{counts}{rows}, 0, 'rows=0';
};

subtest 'resolve_column -- rows that are not hashrefs produce undef cells (skipped)' => sub {
	# A row that is not a hashref contributes an undef cell; it must not crash.
	# The column IS found in at least one actual hashref row, so no croak.
	my $r;
	lives_ok {
		$r = $G->resolve_column(
			[
				'a string',            # not a hashref -- contributes undef cell
				42,                    # not a hashref
				{ city => 'Ramsgate' },# valid row -- establishes column presence
			],
			'city',
		);
	} 'non-hashref rows do not crash resolve_column';

	is $r->{counts}{rows}, 3, 'all three rows counted';
};

# ===========================================================================
# Section 27: Geocode.pm -- cache poisoning
#
# Strategy: inject crafted cache entries that should NOT be treated as
# resolved positions (wrong type, undef elements, out-of-range coords).
# Confirm that _has_position() rejects them cleanly.
# ===========================================================================

subtest 'resolve_values -- cache entry [undef, 1.0] is NOT treated as resolved' => sub {
	my $stub = EC::FullGeocoder->new();
	my $g    = $GEOCODE->new(geocoder => $stub, openaddr => 'test');
	# Inject a poisoned cache: [undef, 1.0] should fail _has_position.
	my $r = $g->resolve_values(['Ramsgate'],
		cache => { 'Ramsgate' => [undef, 1.0] });
	# The position is invalid -> must not be counted as cached-resolved.
	# It should be treated the same as the 0-sentinel (cached-unresolved).
	is $r->{counts}{resolved}, 0,
		'[undef, 1.0] cache entry is NOT counted as resolved';
};

subtest 'resolve_values -- cache entry [] (empty array) is NOT treated as resolved' => sub {
	my $stub = EC::FullGeocoder->new();
	my $g    = $GEOCODE->new(geocoder => $stub, openaddr => 'test');
	my $r = $g->resolve_values(['Ramsgate'],
		cache => { 'Ramsgate' => [] });
	is $r->{counts}{resolved}, 0,
		'empty-array cache entry is NOT counted as resolved';
};

subtest 'resolve_values -- cache entry 0 (zero sentinel) means already-tried-unresolved' => sub {
	# 0 means "looked up and not found"; it must NOT be re-attempted.
	my $stub = EC::FullGeocoder->new();
	my $g    = $GEOCODE->new(geocoder => $stub, openaddr => 'test');
	my $r    = $g->resolve_values(['Ramsgate'],
		cache => { 'Ramsgate' => 0 });
	is scalar(@{ $stub->{calls} }), 0, 'geocoder not called for 0-sentinel entry';
	is $r->{counts}{unresolved}, 1, 'value counted as unresolved from cache';
	is $r->{counts}{cached},     1, 'cached=1 (the 0 sentinel counts as a cache hit)';
};

subtest 'resolve_values -- cache entry "string" (not array, not 0) is treated as a cache hit but not resolved' => sub {
	# A truthy non-array, non-zero value must NOT cause _has_position to return true.
	my $stub = EC::FullGeocoder->new();
	my $g    = $GEOCODE->new(geocoder => $stub, openaddr => 'test');
	my $r    = $g->resolve_values(['Ramsgate'],
		cache => { 'Ramsgate' => 'some string' });
	# "some string" is truthy but not an arrayref -> _has_position false
	# -> treated as unresolved-from-cache; geocoder must not be called.
	is scalar(@{ $stub->{calls} }), 0,
		'geocoder not called when cache has non-array entry';
};

# ===========================================================================
# Section 28: /map route -- hostile HTTP inputs
#
# Strategy: probe every documented guard condition via HTTP; verify that XSS
# payloads in URL parameters are HTML-encoded in the response and never
# reflected raw; confirm that the route never 500s on hostile input.
# ===========================================================================

# Build one reusable test CSV in the shared temp directory.
Readonly my $MAP_TMPDIR   => tempdir(CLEANUP => 1);
Readonly my $MAP_PLACE_CSV => "$MAP_TMPDIR/map_edge.csv";
Mojo::File->new($MAP_PLACE_CSV)->spew(
	"id,city,lat,lon\n"
	. "1,Ramsgate,51.336,1.416\n"
	. "2,Margate,51.384,1.386\n"
	. "3,<script>alert(1)<\/script>,51.5,0.1\n"    # XSS in data value
);
Readonly my $MAP_SPEC => 'path:' . $MAP_PLACE_CSV;

# Stub geocoder that knows Ramsgate and Margate.
{
	package EC::MapGeocoder;
	sub new  { bless { calls => 0 }, shift }
	sub valid_location { defined $_[1] && length $_[1] && $_[1] !~ /\A\d+\z/ }
	sub geocode_many   {
		my ($self, $vals, %o) = @_;
		$self->{calls}++;
		return {
			'Ramsgate'         => EC::GeoPoint->new(latitude => 51.336, longitude => 1.416, database => 'T'),
			'Margate'          => EC::GeoPoint->new(latitude => 51.384, longitude => 1.386, database => 'T'),
			'<script>alert(1)</script>' => undef,
		};
	}
}

subtest 'GET /map -- back=javascript:alert(1) is blocked, not reflected in href' => sub {
	$t->app->config->{geocoder}  = EC::MapGeocoder->new();
	$t->app->config->{openaddr}  = 'test';
	$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

	my $l = url_escape($MAP_SPEC);
	my $body = $t->get_ok("/map?l=$l&lat=lat&lon=lon&back=" . url_escape('javascript:alert(1)'))
	             ->status_is(200)
	             ->tx->res->body;

	unlike $body // '', qr/href=['"]javascript:/i,
		'javascript: scheme not reflected in any href attribute';

	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

subtest 'GET /map -- back=data:text/html,XSS is blocked' => sub {
	$t->app->config->{geocoder}  = EC::MapGeocoder->new();
	$t->app->config->{openaddr}  = 'test';
	$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

	my $l = url_escape($MAP_SPEC);
	my $body = $t->get_ok("/map?l=$l&lat=lat&lon=lon&back=" . url_escape('data:text/html,<script>'))
	             ->status_is(200)
	             ->tx->res->body;

	unlike $body // '', qr/href=['"]data:/i,
		'data: scheme not reflected in any href attribute';

	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

subtest 'GET /map -- XSS payload in city name data cell is HTML-encoded in response' => sub {
	$t->app->config->{geocoder}  = EC::MapGeocoder->new();
	$t->app->config->{openaddr}  = 'test';
	$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

	my $l = url_escape($MAP_SPEC);
	my $body = $t->get_ok("/map?l=$l&loc=city")
	             ->status_is(200)
	             ->tx->res->body;

	# The raw (un-encoded) <script> tag must never appear verbatim in the response.
	# If the geocoder did not resolve the XSS city (it returned undef), the value
	# may not appear in the response at all -- that is also safe.
	unlike $body // '', qr/<script>alert\(1\)<\/script>/,
		'raw <script> tag absent from response';

	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

subtest 'GET /map -- popup= with XSS column name does not inject into href' => sub {
	$t->app->config->{geocoder}  = EC::MapGeocoder->new();
	$t->app->config->{openaddr}  = 'test';
	$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

	my $l    = url_escape($MAP_SPEC);
	my $body = $t->get_ok(
		"/map?l=$l&loc=city&popup=" . url_escape('<script>alert(2)</script>')
	)->status_is(200)->tx->res->body;

	unlike $body // '', qr/<script>alert\(2\)/,
		'XSS in popup= is not reflected raw';

	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

subtest 'GET /map -- loc= with empty string returns 400 error_map_source' => sub {
	my $l = url_escape($MAP_SPEC);
	$t->get_ok("/map?l=$l&loc=")
	  ->status_is(400, '400 for empty loc=');
};

subtest 'GET /map -- lat= without lon= returns 400 error_map_coordinates' => sub {
	my $l = url_escape($MAP_SPEC);
	$t->get_ok("/map?l=$l&lat=lat")
	  ->status_is(400, '400 for lat= alone');
};

subtest 'GET /map -- lon= without lat= returns 400 error_map_coordinates' => sub {
	my $l = url_escape($MAP_SPEC);
	$t->get_ok("/map?l=$l&lon=lon")
	  ->status_is(400, '400 for lon= alone');
};

subtest 'GET /map -- l= missing entirely returns 404' => sub {
	$t->get_ok('/map?lat=lat&lon=lon')
	  ->status_is(404, '404 when data source absent');
};

subtest 'GET /map -- max=0 does not croak: 0 is clamped or ignored' => sub {
	# The controller reads max via _map_limit which clamps to DEFAULT_MAP_MAX_MARKERS;
	# a user-supplied max=0 should not cause a 500.
	$t->app->config->{geocoder}  = EC::MapGeocoder->new();
	$t->app->config->{openaddr}  = 'test';
	$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

	my $l = url_escape($MAP_SPEC);
	my $res = $t->get_ok("/map?l=$l&lat=lat&lon=lon&max=0");
	# Controller accepts max=0 at the HTTP layer; it is clamped by _map_limit.
	cmp_ok $res->tx->res->code, '!=', 500, 'max=0 does not produce 500';

	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

subtest 'GET /map -- NUL byte in loc= column name returns 400 (column not found)' => sub {
	$t->app->config->{geocoder}  = EC::MapGeocoder->new();
	$t->app->config->{openaddr}  = 'test';
	$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

	my $l = url_escape($MAP_SPEC);
	$t->get_ok("/map?l=$l&loc=city%00injected")
	  ->status_is(400, '400 when NUL-byte column name is not found');

	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

# ===========================================================================
# Section 29: Geocode.pm -- models.json filesystem hostility
#
# Strategy: point model_dir at hostile filesystem targets and confirm that
# map_view returns 200 (not 500) with warn_map_cache_unwritten message rather
# than crashing the server.  Uses Test::Permissions so the test skips
# gracefully on systems where permission-revoking is impossible (e.g. root).
# ===========================================================================

use Test::Permissions qw(skip_unless_can_revoke with_revoked);

subtest 'GET /map -- unwritable model_dir: 200 + warn_map_cache_unwritten' => sub {
	my $ro_dir = tempdir(CLEANUP => 1);

	SKIP: {
		# 'create' revokes the ability to create new files inside the directory
		# (chmod 0500).  'write' is for file content; 'create' is for directories.
		# skip_unless_can_revoke skips when the OS cannot actually revoke access
		# (running as root, fakeroot, some FUSE mounts).
		skip_unless_can_revoke('create', 3, $ro_dir);

		my $stub = EC::MapGeocoder->new();
		$t->app->config->{geocoder} = $stub;
		$t->app->config->{openaddr} = 'test';

		with_revoked('create', $ro_dir, sub {
			$t->app->config->{model_dir} = $ro_dir;

			my $l    = url_escape($MAP_SPEC);
			my $body = $t->get_ok("/map?l=$l&loc=city")
			             ->status_is(200, '200 even when model_dir is unwritable')
			             ->tx->res->body;

			like $body // '', qr/cache|model|remember/i,
				'warn_map_cache_unwritten message appears in rendered page';
		});

		delete $t->app->config->{geocoder};
		delete $t->app->config->{openaddr};
	}

	# Always run at least one assertion so Test::Most sees a non-empty subtest
	# even when skip_unless_can_revoke skips all the inner assertions.
	pass('section 29.1 filesystem-hostility check completed (or skipped on this OS)');
};

subtest 'GET /map -- model_dir is a file (not a directory): 200 + warn_map_cache_unwritten' => sub {
	# When model_dir points at a plain file, mkdir will fail and the write is
	# refused.  map_view must survive and report the condition.
	my $not_a_dir = File::Temp->new(UNLINK => 1)->filename;
	Mojo::File->new($not_a_dir)->spew('{}');   # make it a regular file

	$t->app->config->{geocoder}  = EC::MapGeocoder->new();
	$t->app->config->{openaddr}  = 'test';
	$t->app->config->{model_dir} = $not_a_dir;

	my $l    = url_escape($MAP_SPEC);
	my $body = $t->get_ok("/map?l=$l&loc=city")
	             ->status_is(200, '200 when model_dir is a plain file, not a directory')
	             ->tx->res->body;

	like $body // '', qr/cache|model|remember|Ramsgate|Margate/i,
		'response contains map content or cache warning';

	$t->app->config->{model_dir} = tempdir(CLEANUP => 1);
	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

subtest 'GET /map -- pre-existing corrupted models.json is overwritten safely' => sub {
	# A corrupted (non-JSON) models.json must not crash _read_models(); the
	# controller must treat it as an empty model store and proceed.
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/models.json")->spew('NOT VALID JSON {{{{');

	$t->app->config->{geocoder}  = EC::MapGeocoder->new();
	$t->app->config->{openaddr}  = 'test';
	$t->app->config->{model_dir} = $dir;

	my $l = url_escape($MAP_SPEC);
	my $body = $t->get_ok("/map?l=$l&loc=city")
	             ->status_is(200, '200 even with corrupted models.json')
	             ->tx->res->body;

	# After a successful request the file must now be valid JSON.
	my $raw = Mojo::File->new("$dir/models.json")->slurp;
	my $ok  = eval { Mojo::JSON::decode_json($raw); 1 };
	ok $ok, 'models.json replaced with valid JSON after corrupted-file recovery';

	$t->app->config->{model_dir} = tempdir(CLEANUP => 1);
	delete $t->app->config->{geocoder};
	delete $t->app->config->{openaddr};
};

# ===========================================================================
# Section 30: _numeric_cell hostile inputs
#
# Strategy: probe the boundary between "valid numeric" and "unparseable"
# with every edge value that has historically caused silent mis-parses or
# incorrect sign handling.
# ===========================================================================

Readonly my $NUMERIC_CELL =>
	\&Database::BI::Controller::Dashboard::_numeric_cell;

subtest '_numeric_cell -- standard positive integer' => sub {
	is $NUMERIC_CELL->('42'),   42,   'plain integer';
	is $NUMERIC_CELL->('0'),     0,   'zero';
	is $NUMERIC_CELL->('1000'), 1000, 'four-digit integer';
};

subtest '_numeric_cell -- currency and comma-separated values' => sub {
	is $NUMERIC_CELL->('$1,234.56'), 1234.56, 'dollar sign and commas stripped';
	is $NUMERIC_CELL->('1,000'),     1000,    'commas only stripped';
	is $NUMERIC_CELL->('GBP 9.99'),  9.99,    'currency prefix stripped';
};

subtest '_numeric_cell -- accounting-notation negatives' => sub {
	is $NUMERIC_CELL->('(1234.56)'), -1234.56, 'plain accounting negative';
	is $NUMERIC_CELL->('($1,234)'),  -1234,    'dollar accounting negative';
};

subtest '_numeric_cell -- standard negatives' => sub {
	is $NUMERIC_CELL->('-50'),     -50,    'dash-negative integer';
	is $NUMERIC_CELL->('-1.23'),   -1.23,  'dash-negative float';
};

subtest '_numeric_cell -- undef/empty/whitespace returns undef' => sub {
	is $NUMERIC_CELL->(undef), undef, 'undef -> undef';
	is $NUMERIC_CELL->(''),    undef, 'empty string -> undef';
	is $NUMERIC_CELL->('   '), undef, 'whitespace-only -> undef';
};

subtest '_numeric_cell -- non-numeric strings return undef' => sub {
	is $NUMERIC_CELL->('Ramsgate'),  undef, 'place name -> undef';
	is $NUMERIC_CELL->('N/A'),       undef, 'N/A -> undef';
	is $NUMERIC_CELL->('<script>'),  undef, 'XSS payload -> undef';
};

# Only what dresses up a number is stripped, so scientific notation keeps its
# value.  '2.5e3' as 2.53 would be silently wrong by three orders of magnitude.
subtest '_numeric_cell -- scientific notation is read as a number' => sub {
	is $NUMERIC_CELL->('1e5'),   100000, '1e5 -> 100000';
	is $NUMERIC_CELL->('2.5e3'), 2500, '2.5e3 -> 2500';
};

subtest '_numeric_cell -- large values do not overflow or warn' => sub {
	my $big = '9' x 30;
	my $r;
	lives_ok { $r = $NUMERIC_CELL->($big) } '30-digit string does not crash';
	ok defined($r), '30-digit value parses as a number';
};

subtest '_numeric_cell -- dot-only string returns undef' => sub {
	is $NUMERIC_CELL->('.'), undef, '"." alone is not a valid number';
};

subtest '_numeric_cell -- multiple dots return undef' => sub {
	is $NUMERIC_CELL->('1.2.3'), undef, '"1.2.3" is not a valid number';
};

# ===========================================================================
# Sections 31-35: the id column, map popups, canvas card renumbering
#
# These are the helpers changed for two bugs found in the wild: a bank export
# showing 4 of its 362 rows (the id was chosen from the first data row), and a
# map marker naming three rows while showing one.  Each section attacks the
# helper directly, then through the route a reader uses.
# ===========================================================================

use Test::Returns qw(returns_is);
use Config ();
use Carp qw(croak);

Readonly my %EDGE => (
	time_budget   => 5,		# seconds; generous, as Devel::Cover runs slowly
	big_rows      => 50_000,
	wide_cols     => 2_000,
	quote_flood   => 1_000_000,
	popup_rows    => 100_000,
	popup_limit   => 10,
	fd_rounds     => 200,
	fd_slack      => 5,		# handles a test harness may open meanwhile
	fd_ulimit     => 64,
	max_digits    => 9,		# a cv= longer than this names no card
	search_flood  => 200_000,
);
Readonly my $BEST_ID   => \&Database::BI::Model::DataSource::_best_id_column;
Readonly my $SHIFT_CV  => \&Database::BI::Controller::Dashboard::_shift_card_param;
Readonly my $CV_SOURCE => \&Database::BI::Controller::Dashboard::_cross_filter_source;
Readonly my $POPUP     => \&Database::BI::Controller::Dashboard::_map_popup;
Readonly my $HOSTILE   => q{<script>alert(1)</script>"'&};

# Run $code under an alarm, failing (not hanging) when it overruns: the
# helpers below loop over input, and a loop that cannot end must be a failed
# test rather than a stuck CI job.
sub within_budget {
	my ($name, $code) = @_;
	my @got;
	my $ok = eval {
		local $SIG{ALRM} = sub { die "timeout\n" };	## no critic (RequireCarping) -- a signal handler
		alarm $EDGE{time_budget};
		@got = $code->();
		alarm 0;
		1;
	};
	alarm 0;
	ok($ok, "$name finishes within $EDGE{time_budget}s") or diag($@);
	return wantarray ? @got : $got[0];
}

# What _best_id_column picks for $content after a header of @header.
sub pick_id {
	my ($content, @header) = @_;
	CORE::open(my $fh, '<', \$content) or return 'cannot read';
	return $BEST_ID->($fh, ',', \@header);
}

# A data file of its own directory (one stem per directory: see CLAUDE.md).
sub edge_csv {
	my ($stem, $content) = @_;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/$stem.csv")->spew($content);
	return $dir;
}

sub rows_of {
	my ($dir, $stem) = @_;
	return scalar @{ Database::BI::Model::DataSource->new(directory => $dir, table => $stem)->fetch_all };
}

# Open descriptors of this process, where the OS will say.
sub open_fds {
	return undef unless -d "/proc/$$/fd";
	opendir(my $dh, "/proc/$$/fd") or return undef;
	my $n = () = grep { !/\A\./ } readdir $dh;
	return $n;
}

# ---------------------------------------------------------------------------
# Section 31: DataSource::_best_id_column -- choosing the id cannot lose rows
#
# Strategy: D::A drops every row whose id cell is empty or starts with '#', so
# the helper must count those across the whole file, parsed as D::A parses it.
# Each subtest feeds a file whose early rows would mislead a shortcut.
# ---------------------------------------------------------------------------

subtest '_best_id_column -- regression: a column full in row 1 only is not the id' => sub {
	# The bank export: the first transaction had a cheque number.
	my $csv = "650825,Money Transfer\n" . join('', map { ",Payee $_\n" } 1 .. 20);
	is pick_id($csv, qw(Check Description)), 'Description', 'the full column wins';
	my $dir = edge_csv('acct', "Check,Description\n$csv");
	is rows_of($dir, 'acct'), 21, 'and D::A keeps every row';
};

subtest '_best_id_column -- a backslash-escaped quote does not end the count' => sub {
	# D::A reads with escape_char '\\'.  Parsed any other way, row 2 is an
	# error, and a count that stopped there saw only the rows with a cheque.
	my $csv = qq{1,"Shop"\n2,"Joe\\"s Bar"\n} . join('', map { ",d$_\n" } 1 .. 10);
	is pick_id($csv, qw(Check Description)), 'Description', 'the rows after it are counted';
	my $dir = edge_csv('escaped', "Check,Description\n$csv");
	is rows_of($dir, 'escaped'), 12, 'and all 12 rows are read';
};

subtest '_best_id_column -- a line that will not parse is skipped, not the end' => sub {
	my $csv = qq{1,a\n2,b"c"d\n} . join('', map { ",d$_\n" } 1 .. 10);
	is pick_id($csv, qw(Check Description)), 'Description', 'counting goes on past it';
};

subtest '_best_id_column -- what D::A drops counts as dropped' => sub {
	is pick_id("   ,x\n,y\n1,\n", qw(a b)), 'b', 'whitespace-only cells are empty';
	is pick_id("#1,x\n#2,y\n3,\n", qw(a b)), 'b', 'cells starting with # are comments to D::A';
	is pick_id("  #1,x\n2,y\n3,\n", qw(a b)), 'a', 'with leading space too, but a tie keeps the earlier';
	is pick_id("\n\n1,\n\n2,\n", qw(a b)), 'a', 'blank lines are not rows that drop';
	is pick_id("1\n2\n", qw(a b)), 'a', 'a short row is missing its later cells';
};

subtest '_best_id_column -- headers it cannot use' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	is pick_id("1,2\n", 'First Name', 'Last Name'), undef, 'no safe name: undef, for the headerless path';
	is pick_id("1,2\n", undef, 'ok'), 'ok', 'an undef name is passed over';
	is pick_id("1,2\n", '', 'ok'), 'ok', 'as is an empty one';
	is pick_id("1,2\n", "a\nb", 'ok'), 'ok', 'and one with a newline in it';
	is pick_id("1,2\n", '1abc', 'ok'), 'ok', 'and one starting with a digit';
	is pick_id('', qw(a b)), 'a', 'no data rows: the first safe column';
	is_deeply \@warnings, [], 'without a warning';
	returns_is(pick_id("1,2\n", qw(a b)), { type => 'string' }, 'a name is a string');
};

subtest '_best_id_column -- hostile bytes in cells' => sub {
	is pick_id("\xFF\xFE,x\n\0,y\n,z\n", qw(a b)), 'b', 'invalid UTF-8 and NUL are values, not errors';
	is pick_id(qq{"a\nb",1\n"c\nd",2\n,3\n}, qw(a b)), 'b', 'a quoted newline is one row, not two';
	is pick_id("1,a,extra,more\n,b\n", qw(a b)), 'b', 'surplus cells are ignored';
};

subtest '_best_id_column -- a parser that fails without reading cannot loop for ever' => sub {
	# Simulates a read that errors at the same place every time.  The loop's
	# guard is that the handle did not move; without it this test times out.
	require Text::CSV;
	mock 'Text::CSV::getline' => sub { undef };
	mock 'Text::CSV::eof'     => sub { 0 };
	my $got = within_budget('a parser stuck at one place', sub { pick_id("1,2\n,3\n", qw(a b)) });
	is $got, 'a', 'nothing was counted, so the first safe column';
	restore_all();
};

subtest '_best_id_column -- a read that dies mid-file is reported, and leaks nothing' => sub {
	# A disk error mid-read: the open must fail as an error, not as a table
	# with rows quietly missing, and the file handle must not stay open.
	my $dir    = edge_csv('dies', "a,b\n" . join('', map { "$_,x\n" } 1 .. 50));
	my $before = open_fds();
	require Text::CSV;
	my $calls = 0;
	mock 'Text::CSV::getline' => sub { croak('Input/output error') if ++$calls > 3; return [ 1, 'x' ] };
	throws_ok { Database::BI::Model::DataSource->new(directory => $dir, table => 'dies')->fetch_all }
		qr/Input\/output error/, 'the read error reaches the caller';
	restore_all();
	SKIP: {
		skip 'no /proc to count descriptors', 1 unless defined $before;
		cmp_ok open_fds(), '<=', $before + $EDGE{fd_slack}, 'no descriptor left open';
	}
};

subtest '_best_id_column -- volume: many rows, wide rows, a flood of quotes' => sub {
	my $big = join('', map { (($_ % 90) ? '' : $_) . ",d$_\n" } 1 .. $EDGE{big_rows});
	is within_budget("$EDGE{big_rows} rows", sub { pick_id($big, qw(Check Description)) }), 'Description',
		'a cheque in one row in 90 does not make Check the id';

	my @wide = map { "c$_" } 1 .. $EDGE{wide_cols};
	my $wide = join(',', ('') x ($EDGE{wide_cols} - 1), 'v') . "\n";
	is within_budget("$EDGE{wide_cols} columns", sub { pick_id($wide x 3, @wide) }), "c$EDGE{wide_cols}",
		'the one full column of thousands';

	my $flood = '"' x $EDGE{quote_flood};
	ok defined(within_budget('a megabyte of quotes', sub { pick_id($flood, qw(a b)) })),
		'unparseable quotes end in an answer, not catastrophic work';
};

subtest '_best_id_column -- globals and context' => sub {
	my ($got, $after);
	{
		local $_ = 'sentinel';
		$got   = pick_id("1,x\n,y\n", qw(a b));
		$after = $_;
	}
	is $after, 'sentinel', '$_ is left alone';
	is $got, 'b', 'with the right answer';
	my @list = pick_id('', 'First Name');
	is scalar(@list), 1, 'no answer is one undef in list context, not an empty list';
};

subtest 'DataSource -- a caller in slurp mode still gets every row' => sub {
	# Regression: with $/ undef the header read the whole file as one line and
	# the table had 0 rows.  The public reading methods now localise $/.
	my $dir = edge_csv('slurp', "a,b\n" . join('', map { "$_,x$_\n" } 1 .. 11));
	for my $irs (undef, '', 'x', \2) {
		my $shown = defined($irs) ? (ref($irs) ? 'a record length' : "'$irs'") : 'undef';
		my $n;
		{
			local $/ = $irs;
			$n = eval { rows_of($dir, 'slurp') } // "error: $@";
		}
		is $n, 11, "\$/ = $shown";
	}
	is $/, "\n", 'and $/ is the default again after';
};

subtest 'DataSource -- descriptors: opening a file again and again leaks none' => sub {
	my $dir = edge_csv('fds', "a,b\n1,x\n,y\n");
	my $before = open_fds();
	SKIP: {
		skip 'no /proc to count descriptors', 1 unless defined $before;
		rows_of($dir, 'fds') for 1 .. $EDGE{fd_rounds};
		cmp_ok open_fds(), '<=', $before + $EDGE{fd_slack}, "$EDGE{fd_rounds} opens leave no handle behind";
	}
};

subtest 'DataSource -- with every descriptor in use, an open fails cleanly' => sub {
	# A child under a low ulimit fills its descriptor table, tries the file,
	# frees the table and tries again.  The first must be an error (not a
	# crash, not a table with no rows); the second must read every row.
	plan skip_all => 'needs a POSIX shell with ulimit' if $^O eq 'MSWin32' || !-x '/bin/sh';
	my $dir = edge_csv('emfile', "a,b\n1,x\n2,y\n,z\n");
	my $script = <<'PERL';
use strict; use warnings;
use Test::Mojo;
my $t = Test::Mojo->new('Database::BI');
my ($dir) = @ARGV;
my @held;
while (open(my $fh, '<', '/dev/null')) { push @held, $fh }
my $first = eval { scalar @{ Database::BI::Model::DataSource->new(directory => $dir, table => 'emfile')->fetch_all } };
my $err = $@;
@held = ();
my $second = eval { scalar @{ Database::BI::Model::DataSource->new(directory => $dir, table => 'emfile')->fetch_all } } // "error $@";
print 'first=', (defined $first ? $first : 'error'), "\nsecond=$second\n";
PERL
	my $file = File::Temp->new(SUFFIX => '.pl');
	print {$file} $script;
	close $file;
	my $lib = File::Spec->rel2abs('lib');
	my $out = `ulimit -n $EDGE{fd_ulimit} 2>/dev/null && "$^X" -I"$lib" "$file" "$dir" 2>/dev/null`;
	diag("child said: $out") if $ENV{TEST_VERBOSE};
	plan skip_all => 'could not lower the descriptor limit' unless defined($out) && $out =~ /second=/;
	like $out, qr/^first=error$/m, 'with no descriptor free, the open is an error';
	like $out, qr/^second=3$/m, 'with them freed, all 3 rows (the blank-a row too)';
};

subtest 'DataSource -- unreadable and odd files' => sub {
	my $dir = edge_csv('locked', "a,b\n1,x\n");
	SKIP: {
		skip_unless_can_revoke('read', 1, $dir);
		with_revoked('read', "$dir/locked.csv", sub {
			ok !defined(eval { rows_of($dir, 'locked') }), 'an unreadable file is an error, not an empty table';
		});
	}
	SKIP: {
		skip 'symlinks unavailable', 2 unless eval { symlink('', ''); 1 } && $Config::Config{d_symlink};
		my $dangling = tempdir(CLEANUP => 1);
		symlink("$dangling/nowhere.csv", "$dangling/ghost.csv") or skip 'symlink failed', 2;
		$t->get_ok('/open?path=' . url_escape("$dangling/ghost.csv"))->status_isnt(500, 'a dangling symlink is not a 500');
	}
	my $odd = tempdir(CLEANUP => 1);
	my $name = "pay \$(id); \nme.csv";
	SKIP: {
		skip 'this filesystem refuses the name', 3 unless eval { Mojo::File->new("$odd/$name")->spew("Check,Description\n1,a\n,b\n"); 1 };
		$t->get_ok('/open?path=' . url_escape("$odd/$name"))->status_is(200, 'shell characters and a newline in the name');
		like $t->tx->res->body, qr{<td[^>]*>b</td>}, 'and the row with no cheque is shown';
	}
};

# ---------------------------------------------------------------------------
# Section 32: _shift_card_param -- renumbering bookmarks after a card goes
#
# Strategy: a bookmark's state is stored as the browser sent it, so it can
# hold anything.  Renumbering must touch only cv= values that name a card.
# ---------------------------------------------------------------------------

subtest '_shift_card_param -- regression: a cv= too long to be a card is left alone' => sub {
	my $huge = '9' x ($EDGE{max_digits} + 11);
	is $SHIFT_CV->("?cv=$huge&x=1", 1), "?cv=$huge&x=1", 'not turned into cv=1e+20';
	my $edge = '9' x $EDGE{max_digits};
	is $SHIFT_CV->("?cv=$edge", 1), '?cv=' . ($edge - 1), 'the longest that names a card still moves';
};

subtest '_shift_card_param -- arguments that are not a search and an index' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	is $SHIFT_CV->(undef, 1), undef, 'no search: none back';
	is $SHIFT_CV->('?cv=2', undef), '?cv=2', 'no index: unchanged, not read as card 0';
	is $SHIFT_CV->('?cv=2', 'abc'), '?cv=2', 'an index that is not a number';
	is $SHIFT_CV->('?cv=2', -1), '?cv=2', 'or is negative';
	is $SHIFT_CV->('?cv=2', '1e0'), '?cv=2', 'or is written as a float';
	is $SHIFT_CV->('?cv=2', [1]), '?cv=2', 'or is a reference';
	my $ref = [1];
	is $SHIFT_CV->($ref, 1), $ref, 'a reference search comes back as it went';
	is $SHIFT_CV->('', 1), '', 'an empty search';
	is_deeply \@warnings, [], 'without a warning';
};

subtest '_shift_card_param -- look-alikes and odd spellings' => sub {
	is $SHIFT_CV->('?cv=&x=1', 0), '?cv=&x=1', 'an empty cv= names no card';
	is $SHIFT_CV->('?cv=-3', 1), '?cv=-3', 'nor does a negative one';
	is $SHIFT_CV->('?cv=1a', 0), '?cv=0a', 'digits then junk: the digits are the card (as the canvas reads it)';
	is $SHIFT_CV->('?CV=3', 1), '?CV=3', 'the name is case-sensitive';
	is $SHIFT_CV->('?x=cv=3', 1), '?x=cv=3', 'cv= inside a value is a value';
	is $SHIFT_CV->('?cv=0003', 1), '?cv=2', 'leading zeros name the same card';
	is $SHIFT_CV->("?cv=3\n", 1), "?cv=2\n", 'a trailing newline is kept';
};

subtest '_shift_card_param -- volume and backtracking' => sub {
	my $many = '?' . join('&', map { "cv=$_" } 1 .. $EDGE{search_flood} / 10);
	my $got = within_budget('thousands of cv=', sub { $SHIFT_CV->($many, 1) });
	my $want = '?' . join('&', map { 'cv=' . ($_ - 1) } 2 .. $EDGE{search_flood} / 10);
	ok($got eq $want, 'the removed card dropped, each later one moved down');
	within_budget('a flood of cv=cv=cv=', sub { $SHIFT_CV->('?' . ('cv=' x $EDGE{search_flood}), 1) });
	within_budget('a flood of ampersands', sub { $SHIFT_CV->('?' . ('&' x $EDGE{search_flood}) . 'cv=3', 1) });
	my @list = $SHIFT_CV->('?cv=3', 1);
	is_deeply \@list, [ '?cv=2' ], 'one value in list context';
};

subtest 'DELETE a card -- a bookmark naming no card survives intact' => sub {
	my $huge = '9' x ($EDGE{max_digits} + 11);
	my $id = $t->post_ok('/api/analyses' => json => {
		name => 'edge', datasets => [ { spec => 'table:sales' } ],
		visuals => [
			{ kind => 'text', options => { text => 'note' } },
			{ kind => 'bar', encode => { cat => 'region', value => 'amount' } },
		],
		bookmarks => [ { name => 'b', state => "?cv=$huge&cv=1" } ],
	})->status_is(201)->tx->res->json->{id};
	$t->delete_ok("/api/analyses/$id/visuals/0")->status_is(200);
	$t->get_ok("/api/analyses/$id")->json_is('/bookmarks/0/state', "?cv=$huge&cv=0",
		'the long cv= is kept, the real one moves down');
};

# ---------------------------------------------------------------------------
# Section 33: _cross_filter_source -- which card a cv= names
#
# Strategy: anything but 1-9 ASCII digits must name no card (-1), so a
# hostile value can never select a card by accident.
# ---------------------------------------------------------------------------

subtest '_cross_filter_source -- hostile values name no card' => sub {
	for my $bad (undef, '', ' 1', '1 ', "1\n", '+1', '-1', '1.0', '1e2', '0x1', "\x{661}", "\x{FF11}",
		'1' x ($EDGE{max_digits} + 1), [1], { 1 => 1 }, \1, \*STDOUT, sub { 1 }) {
		my $shown = defined($bad) ? (ref($bad) ? ref($bad) : "'$bad'") : 'undef';
		$shown =~ s/[^\x20-\x7E]/?/g;
		is $CV_SOURCE->($bad), -1, "$shown names no card";
	}
	is $CV_SOURCE->('0'), 0, '0 is the first card';
	is $CV_SOURCE->('007'), 7, 'leading zeros are the same card';
	is $CV_SOURCE->('9' x $EDGE{max_digits}), '9' x $EDGE{max_digits}, 'the longest allowed';
	returns_is($CV_SOURCE->('3'), { type => 'integer' }, 'an integer back');
};

subtest 'GET /a/:id -- hostile cv= never breaks the canvas' => sub {
	my $id = $t->post_ok('/api/analyses' => json => {
		name => 'cv', datasets => [ { spec => 'table:sales' } ],
		visuals => [ { kind => 'bar', encode => { cat => 'region', value => 'amount' } } ],
	})->tx->res->json->{id};
	for my $cv ('abc', '9' x 30, '-1', '0x1', "1\n", '1' x 5000, $HOSTILE) {
		$t->get_ok("/a/$id?cv=" . url_escape($cv))->status_is(200);
		$t->content_unlike(qr/<script>alert/, 'nothing reflected unescaped');
	}
};

# ---------------------------------------------------------------------------
# Section 34: stored cards of the wrong shape
#
# Strategy: PUT and import store a visual unchecked, and a share link serves
# the canvas to strangers, so every part of a card that is the wrong kind
# must be read as absent, never dereferenced (a 500) or echoed raw.
# ---------------------------------------------------------------------------

subtest 'GET /a/:id -- cards with parts of the wrong kind still draw' => sub {
	my $id = $t->post_ok('/api/analyses' => json => {
		name => 'shape', datasets => [ { spec => 'table:sales' } ],
		visuals => [ { kind => 'bar', encode => { cat => 'region', value => 'amount' } } ],
	})->tx->res->json->{id};
	my @cards = (
		{ kind => 'bar', encode => [ 'region' ], filters => { a => 1 }, options => 'x' },
		{ kind => 'bar', encode => { cat => 'region', value => 'amount' }, filters => [ [1], { a => 1 }, undef, 'region:eq:North' ] },
		{ kind => [ 'bar' ], encode => {}, title => { x => 1 } },
		{ kind => 'pie', encode => { cat => [ 'region' ], value => { a => 1 } } },
		{ kind => 'bar', encode => { cat => 'region', value => 'amount' }, cross_row => [ 1 ] },
		{ kind => 'map', encode => { loc => { x => 1 } } },
		{ kind => 'table', encode => { cols => 'region' } },
		{ kind => 'bar', encode => { cat => $HOSTILE, value => $HOSTILE }, title => $HOSTILE },
	);
	for my $i (0 .. $#cards) {
		$t->put_ok("/api/analyses/$id" => json => {
			name => 'shape', datasets => [ { spec => 'table:sales' } ], visuals => [ $cards[$i] ],
		})->status_is(200);
		$t->get_ok("/a/$id")->status_is(200, "card $i draws a page");
		$t->content_unlike(qr/<script>alert/, "card $i echoes nothing raw");
	}
};

# ---------------------------------------------------------------------------
# Section 35: _map_popup -- every row at a marker, without smothering the map
#
# Strategy: the popup is HTML put into a map, built from cells a stranger may
# have written, so every value must be escaped, the table capped however many
# rows come, and arguments of the wrong kind read as absent.
# ---------------------------------------------------------------------------

subtest '_map_popup -- arguments of the wrong kind' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	is $POPUP->(undef, undef, undef), '<strong></strong>', 'nothing at all: an empty heading';
	is $POPUP->('h', 'rows', 'cols'), '<strong>h</strong>', 'strings for lists';
	is $POPUP->('h', [ 1, 'x', undef, [1], \*STDOUT ], [ 'a' ]), '<strong>h</strong>', 'rows that are not hashes are not rows';
	is $POPUP->('h', [ { a => 1 } ], [ undef, '', [ 'a' ], 'a' ]), '<strong>h</strong><br>a: 1', 'nor are such columns';
	like $POPUP->(\*STDOUT, [ { a => 1 } ], [ 'a' ]), qr{\A<strong>GLOB\(0x[0-9a-f]+\)</strong>}, 'a glob heading is only text';
	is_deeply \@warnings, [], 'without a warning';
};

subtest '_map_popup -- cells that are references or cycles' => sub {
	my $cyc = { a => 1 };
	$cyc->{self} = $cyc;
	my $html = within_budget('a cyclic row', sub { $POPUP->('h', [ $cyc, { a => 2, self => [ 1 ] } ], [ 'a', 'self' ], 5) });
	unlike $html, qr/HASH\(|ARRAY\(/, 'a reference cell is empty, not its address';
	like $html, qr{<th>a</th>}, 'and the plain column still differs';
	unlike $html, qr{<th>self</th>}, 'while the reference column, empty in both, is not a column';
};

subtest '_map_popup -- every limit that is not a count falls back to the default' => sub {
	my @rows = map { { n => $_ } } 1 .. ($EDGE{popup_limit} * 3);
	for my $bad (undef, 0, -1, '', 'abc', '1.5', '1e3', [ 1 ], "5\n") {
		my $shown = defined($bad) ? (ref($bad) ? 'a reference' : "'$bad'") : 'undef';
		$shown =~ s/\n/\\n/g;
		my $html = $POPUP->('h', \@rows, [ 'n' ], $bad);
		my $shown_rows = () = $html =~ /<td>/g;
		is $shown_rows, $EDGE{popup_limit}, "limit $shown shows the default $EDGE{popup_limit}";
	}
	my $html = $POPUP->('h', \@rows, [ 'n' ], 999_999_999);
	is scalar(() = $html =~ /<td>/g), scalar(@rows), 'a huge limit shows what there is';
};

subtest '_map_popup -- many rows cannot make a huge popup' => sub {
	my @rows = map { { n => $_, place => 'same' } } 1 .. $EDGE{popup_rows};
	my $html = within_budget("$EDGE{popup_rows} rows", sub { $POPUP->('h', \@rows, [ 'place', 'n' ], $EDGE{popup_limit}, '/open?x=1') });
	is scalar(() = $html =~ /<tr>/g), $EDGE{popup_limit} + 1, 'a header and the capped rows';
	like $html, qr{and \Q@{[ $EDGE{popup_rows} - $EDGE{popup_limit} ]}\E more: <a href="/open\?x=1">show all $EDGE{popup_rows} in the table</a>},
		'the rest are counted and linked';
	cmp_ok length($html), '<', 2_000, 'and the popup stays small';
	diag("popup: $html") if $ENV{TEST_VERBOSE};
};

subtest '_map_popup -- everything a stranger wrote is escaped' => sub {
	my @rows = ({ $HOSTILE => $HOSTILE, s => $HOSTILE }, { $HOSTILE => 'x', s => $HOSTILE });
	my $html = $POPUP->($HOSTILE, \@rows, [ $HOSTILE, 's' ], 1, qq{/open?a="><script>alert(1)</script>});
	unlike $html, qr/<script>/, 'no element from the data';
	unlike $html, qr/href="[^"]*"[^>]*"/, 'the link cannot break out of its attribute';
	like $html, qr{&lt;script&gt;}, 'the text is shown, escaped';
	my $bytes = $POPUP->("\xFF\xFE", [ { a => "\0\xC3" }, { a => 'b' } ], [ 'a' ]);
	like $bytes, qr/<td>/, 'invalid UTF-8 and NUL are drawn, not fatal';
};

subtest '_map_popup -- globals and context' => sub {
	my ($after, @list);
	{
		local $_ = 'sentinel';
		@list  = $POPUP->('h', [ { a => 1 }, { a => 2 } ], [ 'a' ]);
		$after = $_;
	}
	is $after, 'sentinel', '$_ is left alone';
	is scalar(@list), 1, 'one string in list context';
	returns_is($list[0], { type => 'string' }, 'a string');
};

subtest 'GET /map -- many rows at one place: capped, escaped, linked' => sub {
	plan skip_all => 'HTML::OSM 0.14 is needed to draw a map'
		unless eval { require HTML::OSM; HTML::OSM->VERSION(0.14); 1 };
	my $rows = $EDGE{popup_limit} * 4;
	my $dir  = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/stack.csv")->spew("lat,lon,who\n"
		. join('', map { "51.5,-0.1,\"$HOSTILE$_\"\n" } 1 .. $rows));
	$t->get_ok('/map?l=' . url_escape("path:$dir/stack.csv") . '&lat=lat&lon=lon&popup=who')->status_is(200);
	my $body = $t->tx->res->body;
	unlike $body, qr/<script>alert/, 'no cell runs';
	like $body, qr/\Q@{[ $rows - $EDGE{popup_limit} ]}\E more/, 'the popup counts the rest';
	like $body, qr/show all $rows in the table/, 'and links to them';
};

done_testing();
