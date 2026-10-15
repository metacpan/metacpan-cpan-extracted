use strict;
use warnings;
use Test::More;
use Test::Mojo;
use File::Spec ();
use File::Temp ();
use Mojo::File  ();
use Mojo::JSON  qw(false);
use Mojo::Util  qw(url_escape);
use Readonly;

# ---------------------------------------------------------------------------
# Syllogistic foundation
#
# Major Premise A: All filesystem-touching parameters (/open, /browse, /api/*)
#   pass through Mojo::File->new($path)->realpath wrapped in eval.  realpath
#   canonicalises the path (collapsing ../) AND raises an exception for null
#   bytes, so path-traversal and null-byte injection are eliminated at the
#   same call site.
#
# Major Premise B: Table names extracted from the :table route placeholder are
#   validated against TABLE_NAME_RE = /\A[A-Za-z0-9_]+\z/ before any file
#   access.  Characters outside that set produce 404 before any I/O.
#
# Major Premise C: /import enforces scheme = http|https via /\Ahttps?:\/\//i AND
#   _is_safe_url() resolves the hostname and rejects RFC 1918, link-local
#   (169.254/16), loopback, and CGNAT ranges.  file://, ftp://, javascript:,
#   and http://localhost/ are all rejected before LWP is called.
#
# Major Premise D: Export Content-Disposition filenames are sanitized:
#   GET /export applies s/[^a-z0-9_]+/_/g; POST /export strips path separators
#   with ([^/\\]+)\z and then requires .csv or .sql extension.
#
# Major Premise E: Uploaded filenames have directory components stripped by
#   s{.*[/\\]}{} before storage; extensions must match EXT_RE.
#
# Major Premise F: DBI column bindings in _write_sqlite_db use parameterised
#   execute() for row data, and double-quote-quoting for identifiers.
#   No raw string interpolation into SQL reaches the database.
# ---------------------------------------------------------------------------

Readonly my $XSS_PAYLOAD    => '<script>alert(1)</script>';
Readonly my $XSS_ONCLICK    => '<img src=x onerror=alert(1)>';
Readonly my $SQL_PAYLOAD     => "'; DROP TABLE data; --";
Readonly my $CMD_PIPE        => '|ls -la /etc|';
Readonly my $CMD_BACKTICK    => '`id`';
Readonly my $CMD_DOLLAR      => '$(id)';
Readonly my $PATH_TRAV_REL   => '../../../etc/passwd';
Readonly my $PATH_TRAV_ABS   => '/etc/passwd';
Readonly my $CRLF_HEADER     => "safe\r\nX-Injected: evil";
Readonly my $SALES_CSV_PATH  => File::Spec->rel2abs('data/sales.csv');

my $t = Test::Mojo->new('Database::BI');

# ---------------------------------------------------------------------------
# Attack vector 1: Table-name injection via the :table route placeholder
#
# The Mojolicious router captures everything between /view/ and the next /
# into :table.  TABLE_NAME_RE /\A[A-Za-z0-9_]+\z/ is applied before any
# file I/O, so XSS, shell metacharacters, and path-traversal chars all
# produce 404 without touching the filesystem.
# ---------------------------------------------------------------------------

subtest 'route :table -- XSS in table name returns 404' => sub {
	# Exploit mechanism: attacker hopes the table name is reflected in the
	# response without HTML-encoding, triggering stored XSS.
	# Proof: TABLE_NAME_RE rejects '<', '>', '/' before any render.
	$t->get_ok('/view/' . url_escape($XSS_PAYLOAD))
	  ->status_is(404);
};

subtest 'route :table -- shell metacharacters return 404' => sub {
	# Exploit mechanism: injecting |, ;, ` into the table name hoping the
	# value is interpolated into a shell command (e.g. open FH, "| cmd").
	# Proof: TABLE_NAME_RE rejects all three characters.
	for my $payload ($CMD_PIPE, $CMD_BACKTICK, $CMD_DOLLAR, 'sales; ls -la', 'sales | cat') {
		$t->get_ok('/view/' . url_escape($payload))
		  ->status_is(404,  "table name '$payload' is rejected");
	}
};

subtest 'route :table -- path-traversal in table name returns 404' => sub {
	# Exploit mechanism: attacker supplies "../../etc/passwd" as :table,
	# hoping the controller appends it to data_dir and reads /etc/passwd.
	# Proof: TABLE_NAME_RE blocks '.' and '/' before any file lookup.
	$t->get_ok('/view/' . url_escape($PATH_TRAV_REL))
	  ->status_is(404);
	$t->get_ok('/view/.hidden')
	  ->status_is(404);
};

subtest 'route :table -- valid alphanumeric names are accepted' => sub {
	# Regression guard: TABLE_NAME_RE must not over-block legitimate names.
	# Proof: 'sales' =~ /\A[A-Za-z0-9_]+\z/ is true; route resolves to 200
	# or a DataSource error (re-renders home with error), never 404.
	$t->get_ok('/view/sales')
	  ->status_is(200);
};

# ---------------------------------------------------------------------------
# Attack vector 2: Path traversal and null-byte injection on /open
#
# /open calls Mojo::File->new($path)->realpath (in eval); then checks
# -f && basename =~ EXT_RE.  realpath resolves ".." and raises an exception
# for embedded null bytes (modern Perl 5.12+), caught by eval => undef => 404.
# /etc/passwd has no supported extension => fails EXT_RE => 404.
# ---------------------------------------------------------------------------

subtest '/open -- absolute path to /etc/passwd returns 404' => sub {
	# Exploit mechanism: attacker reads any file by passing its absolute path.
	# Proof: /etc/passwd lacks a supported extension (csv|db|sql|xml|psv).
	$t->get_ok('/open?path=' . url_escape($PATH_TRAV_ABS))
	  ->status_is(404);
};

subtest '/open -- relative path traversal returns 404' => sub {
	# Exploit mechanism: "../../../etc/passwd" resolves to /etc/passwd via
	# realpath; then the extension guard rejects it.
	$t->get_ok('/open?path=' . url_escape($PATH_TRAV_REL))
	  ->status_is(404);
};

subtest '/open -- null byte in path returns 404' => sub {
	# Exploit mechanism: "file.csv\x00../../etc/passwd" -- some older C-library
	# calls truncate at the null byte, allowing extension forgery.
	# Proof: modern Perl's open() and realpath() raise Errno::ENOENT or croak
	# on null bytes; eval catches the exception => 404.
	my $null_path = "/tmp/innocent.csv\x00../../etc/passwd";
	$t->get_ok('/open?path=' . url_escape($null_path))
	  ->status_is(404);
};

subtest '/open -- missing path param returns 404' => sub {
	# Proof: "defined $file_path" check fires before any realpath call.
	$t->get_ok('/open')
	  ->status_is(404);
};

subtest '/open -- directory path returns 404 (must be a file)' => sub {
	# Exploit mechanism: attacker passes a directory hoping list or open.
	# Proof: -f $file guard rejects directories.
	$t->get_ok('/open?path=' . url_escape('/tmp'))
	  ->status_is(404);
};

# ---------------------------------------------------------------------------
# Attack vector 3: Path traversal on /browse
#
# /browse calls realpath + -d; directories ARE listed (by design -- the
# filesystem browser is intentional).  The security invariant is that
# /etc/passwd (a file) is rejected, and symlink-chased paths are resolved
# to their canonical form before the -d check, preventing confusion attacks.
# ---------------------------------------------------------------------------

subtest '/browse -- file path returns 404 (must be a directory)' => sub {
	# Proof: -d guard fires; /etc/passwd is a file, not a directory.
	$t->get_ok('/browse?path=' . url_escape($PATH_TRAV_ABS))
	  ->status_is(404);
};

subtest '/browse -- non-existent path returns 404' => sub {
	# Proof: realpath throws for non-existent paths; eval returns undef => 404.
	$t->get_ok('/browse?path=' . url_escape('/nonexistent/xyzzy/abc'))
	  ->status_is(404);
};

subtest '/browse -- null byte causes C-library truncation; non-directory result gives 404' => sub {
	# Exploit mechanism: "/etc/passwd\x00evil" -- the C-library realpath(3)
	# truncates the path at the null byte, yielding "/etc/passwd" (a file, not
	# a directory).  The -d guard then produces 404.
	# Note: "\x00" appended after a directory name (e.g. "/tmp\x00/evil")
	# truncates to a valid directory and returns 200 by design -- the filesystem
	# browser intentionally allows any accessible directory.
	my $null_path = "/etc/passwd\x00/../../tmp";
	$t->get_ok('/browse?path=' . url_escape($null_path))
	  ->status_is(404);
};

# ---------------------------------------------------------------------------
# Attack vector 4: XSS via filter values reflected in HTML output
#
# Filter values in the "active filter chips" toolbar and the embedded
# window.__biFilters JSON must not be reflected as raw HTML.
# Template Toolkit applies | html to all interpolated values in the template.
# The controller pre-escapes '</' -> '<\/' in the JSON string so the JSON
# cannot close a <script> tag even when embedded verbatim.
# ---------------------------------------------------------------------------

SKIP: {
	skip 'data/sales.csv not found', 6 unless -f $SALES_CSV_PATH;

	subtest 'XSS in filter value -- reflected chips are HTML-encoded' => sub {
		# Exploit mechanism: attacker injects <script> into ?f= hoping the
		# filter chip template emits [% col | html %] without the html filter.
		# Proof: the raw string '<script>' must not appear in the response body.
		$t->get_ok('/view/sales?f=' . url_escape("region:eq:$XSS_PAYLOAD"))
		  ->status_is(200)
		  ->content_unlike(qr/<script>alert\(1\)<\/script>/,
		     'XSS payload is not reflected verbatim');
	};

	subtest 'XSS in filter value -- img tag is HTML-encoded in the filter chip' => sub {
		# Proof: TT applies | html to filter-chip content; "<img" becomes
		# "&lt;img" so the browser never parses a real tag from the chip.
		# Note: the JSON block (window.__biFilters) contains the value verbatim
		# as a JS string literal, which is safe because the JS code uses
		# `.value =` assignment (not innerHTML) when pre-populating filter rows.
		# The chip HTML-encoding is the primary XSS defence; verify it directly.
		$t->get_ok('/view/sales?f=' . url_escape("region:eq:$XSS_ONCLICK"))
		  ->status_is(200)
		  ->content_like(qr/&lt;img src=x/,
		     'img tag opening bracket is HTML-encoded in the filter chip');
	};

	subtest 'filter value with SQL metacharacters -- treated as plain string' => sub {
		# Exploit mechanism: SQL injection through filter value hoping it
		# reaches a raw string interpolation in a SQL query.
		# Proof: _apply_filter_spec does a Perl string comparison (eq/ne etc.),
		# never passing the value to SQL.
		$t->get_ok('/view/sales?f=' . url_escape("region:eq:$SQL_PAYLOAD"))
		  ->status_is(200);    # must not crash or 500
	};

	subtest 'filter value with shell metacharacters -- treated as plain string' => sub {
		# Exploit mechanism: shell injection through filter value hoping it
		# reaches system() or open(FH, "| cmd").
		# Proof: _apply_filter_spec only uses Perl string/number operators;
		# no code path calls system() or the shell.
		for my $payload ($CMD_PIPE, $CMD_BACKTICK, $CMD_DOLLAR) {
			$t->get_ok('/view/sales?f=' . url_escape("region:eq:$payload"))
			  ->status_is(200, "command payload '$payload' does not crash the app");
		}
	};

	subtest 'window.__biFilters JSON is script-tag-safe' => sub {
		# Exploit mechanism: a filter value of "</script><script>evil()" would
		# end the enclosing <script> block if not escaped.
		# Proof: the controller applies s{</}{<\\/}g to the JSON string before
		# passing it to the template, so "</script>" becomes "<\/script>".
		my $close_tag = '</script><script>evil()';
		my $res = $t->get_ok('/view/sales?f=' . url_escape("region:eq:$close_tag"))
		            ->status_is(200)
		            ->tx->res->body;
		unlike($res, qr{</script><script>evil\(\)},
			'raw </script> is not present in JSON block');
	};

	subtest 'XSS via column name in open spec -- join step with hostile right-table' => sub {
		# Proof: _open_spec for path: runs basename(file) =~ EXT_RE before any
		# render; hostile paths without a data extension are silently skipped.
		my $hostile_j = url_escape('/etc/passwd|id|id');
		$t->get_ok("/join?l=table:sales&j=path:$hostile_j")
		  ->status_is(200);  # join step skipped; left table still renders
	};
}

# ---------------------------------------------------------------------------
# Attack vector 5: URL scheme injection (SSRF) via /import
#
# The controller enforces /\Ahttps?:\/\//i before calling LWP.  Non-http
# schemes are blocked at the string level before any network I/O.
# ---------------------------------------------------------------------------

subtest '/import -- file:// scheme is rejected' => sub {
	# Exploit mechanism: attacker reads local files via the file:// scheme.
	# Proof: /\Ahttps?:\/\//i fails for "file://"; response renders home
	# with error_url_invalid message, not the file contents.
	$t->get_ok('/import?url=' . url_escape('file:///etc/passwd'))
	  ->status_is(200)
	  ->content_unlike(qr{root:x:0:0},
	     'local file content is not returned');
};

subtest '/import -- ftp:// scheme is rejected' => sub {
	# Proof: "ftp://" does not match /\Ahttps?:\/\//i.
	$t->get_ok('/import?url=' . url_escape('ftp://evil.com/data'))
	  ->status_is(200)
	  ->content_like(qr/not a valid/i,
	     'ftp:// scheme triggers the invalid-URL error');
};

subtest '/import -- javascript: scheme is rejected' => sub {
	# Exploit mechanism: attacker injects a JavaScript URI hoping it executes
	# either server-side or is reflected and executed client-side.
	$t->get_ok('/import?url=' . url_escape('javascript:alert(1)'))
	  ->status_is(200)
	  ->content_like(qr/not a valid/i);
};

subtest '/import -- empty url param triggers required-error message' => sub {
	$t->get_ok('/import?url=')->status_is(200)->content_like(qr/Please enter a URL/i);
};

subtest '/import -- missing url param renders prompt' => sub {
	$t->get_ok('/import')
	  ->status_is(200)
	  ->content_like(qr/Please enter a URL/i);
};

# ---------------------------------------------------------------------------
# Attack vector 5b: SSRF via private/loopback/link-local addresses
#
# _is_safe_url() resolves the hostname and rejects RFC 1918 (10/8, 172.16/12,
# 192.168/16), loopback (127/8), link-local (169.254/16), and CGNAT (100.64/10).
# The response must not attempt a network connection; it renders home with an
# error message.
# ---------------------------------------------------------------------------

subtest '/import -- http://localhost/ is rejected (SSRF loopback)' => sub {
	# Exploit mechanism: attacker fetches internal-only services on the loopback
	# interface (e.g. Redis :6379, internal admin panels, Kubernetes API).
	# Proof: _is_safe_url() matches $host eq 'localhost' and returns 0.
	$t->get_ok('/import?url=' . url_escape('http://localhost/'))
	  ->status_is(200)
	  ->content_like(qr/private or reserved/i,
	     'localhost is rejected as a private address');
};

subtest '/import -- http://127.0.0.1/ is rejected (SSRF loopback)' => sub {
	# Exploit mechanism: bare loopback IPv4 bypasses hostname-based blocklists.
	# Proof: $host =~ /\A127\./ check in _is_safe_url() catches all of 127/8.
	$t->get_ok('/import?url=' . url_escape('http://127.0.0.1/'))
	  ->status_is(200)
	  ->content_like(qr/private or reserved/i,
	     '127.0.0.1 is rejected as a loopback address');
};

subtest '/import -- http://169.254.169.254/ is rejected (SSRF cloud metadata)' => sub {
	# Exploit mechanism: AWS/GCP/Azure metadata endpoint returns IAM credentials
	# and instance metadata; no authentication is required from the instance.
	# Proof: 169.254/16 is in the link-local block checked by _is_safe_url().
	$t->get_ok('/import?url=' . url_escape('http://169.254.169.254/latest/meta-data/'))
	  ->status_is(200)
	  ->content_like(qr/private or reserved/i,
	     '169.254.169.254 (cloud metadata) is rejected');
};

# ---------------------------------------------------------------------------
# Attack vector 6: Join left-spec injection
#
# The l= param is parsed by _open_spec.  "table:" accepts only [A-Za-z0-9_]+;
# "path:" requires realpath + EXT_RE; "url:" requires https?:// scheme.
# All other prefixes fall through to the final "return ()" -- 404.
# ---------------------------------------------------------------------------

subtest 'join l= -- path traversal via table: prefix is rejected' => sub {
	# Proof: "table:../../etc" contains '.' and '/' which fail [A-Za-z0-9_]+.
	$t->get_ok('/join?l=' . url_escape('table:../../etc'))
	  ->status_is(404);
};

subtest 'join l= -- path to /etc/passwd via path: prefix is rejected' => sub {
	# Proof: /etc/passwd has no supported extension => EXT_RE fails => 404.
	$t->get_ok('/join?l=' . url_escape('path:/etc/passwd'))
	  ->status_is(404);
};

subtest 'join l= -- javascript: url is rejected' => sub {
	# Proof: _open_spec url: branch requires /\Aurl:(https?:\/\/.+)\z/i.
	$t->get_ok('/join?l=' . url_escape('url:javascript:alert(1)'))
	  ->status_is(404);
};

subtest 'join l= -- unknown spec prefix is rejected' => sub {
	# Proof: _open_spec returns () for any spec that doesn't match table:/path:/url:.
	$t->get_ok('/join?l=' . url_escape('exec:/usr/bin/id'))
	  ->status_is(404);
};

SKIP: {
	skip 'data/sales.csv not found', 1 unless -f $SALES_CSV_PATH;

	subtest 'join j= -- path traversal in right-table spec is silently skipped' => sub {
		# Exploit mechanism: j= with a path: spec pointing to /etc/passwd.
		# Proof: _open_spec rejects /etc/passwd (no ext); step is skipped.
		# Left table (sales) still renders.
		my $hostile = url_escape('path:/etc/passwd|id|id');
		$t->get_ok("/join?l=table:sales&j=$hostile")
		  ->status_is(200);
	};
}

# ---------------------------------------------------------------------------
# Attack vector 7: Header injection via Content-Disposition in GET /export
#
# The export_data action sanitizes the filename stem:
#   (my $safe_name = lc $left_label) =~ s/[^a-z0-9_]+/_/g
# CRLF characters, angle brackets, and quotes are all replaced by '_'.
# The resulting value is safe to embed in the Content-Disposition header.
# ---------------------------------------------------------------------------

SKIP: {
	skip 'data/sales.csv not found', 2 unless -f $SALES_CSV_PATH;

	subtest 'GET /export -- CRLF in format param does not split headers' => sub {
		# Exploit mechanism: attacker injects \r\n into ?format= hoping to
		# add a rogue HTTP header (e.g. Content-Type: text/html).
		# Proof: format is sanitized to 'csv' unless it equals exactly 'sqlite'.
		# Any other value, including one containing \r\n, becomes 'csv'.
		my $payload = "csv\r\nX-Evil: injected";
		$t->get_ok('/export?l=table:sales&format=' . url_escape($payload))
		  ->status_is(200)
		  ->header_unlike('Content-Disposition', qr/X-Evil/,
		     'CRLF in format does not inject a rogue header');
	};

	subtest 'GET /export -- Content-Disposition filename is safe' => sub {
		# Proof: safe_name = s/[^a-z0-9_]+/_/g removes all special chars.
		# The Content-Disposition header value must not contain raw special chars.
		$t->get_ok('/export?l=table:sales&format=csv')
		  ->status_is(200)
		  ->header_like('Content-Disposition', qr{attachment; filename="[a-z0-9_]+\.csv"},
		     'Content-Disposition filename is safe');
	};
}

# ---------------------------------------------------------------------------
# Attack vector 8: Export write -- path injection via POST /export
#
# export_write applies realpath to dir= and strips separators from filename=
# with ([^/\\]+)\z.  Extension must be .csv or .sql; anything else is 415.
# ---------------------------------------------------------------------------

subtest 'POST /export -- non-existent dir= returns 404' => sub {
	# Proof: realpath throws for a non-existent path; eval returns undef;
	# "-d $dest_dir" guard fires => 404 JSON.
	$t->post_ok('/export', form => {
		l        => 'table:sales',
		dir      => '/nonexistent/path/xyzzy',
		filename => 'out.csv',
	})->status_is(404);
};

subtest 'POST /export -- unsupported extension returns 415' => sub {
	# Exploit mechanism: attacker tries to write a PHP/ASP file to a web root.
	# Proof: format detection requires exactly .csv or .sql extension; anything
	# else (including .php, .html, .exe) returns 415 before any file I/O.
	for my $ext (qw( php html exe sh )) {
		$t->post_ok('/export', form => {
			l        => 'table:sales',
			dir      => File::Spec->tmpdir(),
			filename => "evil.$ext",
		})->status_is(415, "extension .$ext returns 415");
	}
};

subtest 'POST /export -- path traversal in filename= is stripped to basename' => sub {
	# Exploit mechanism: "../../evil.csv" in filename= hoping to escape $dir.
	# Proof: ([^/\\]+)\z extracts the basename only ("evil.csv"), so the
	# traversal prefix is silently discarded before constructing the path.
	# The file is written to $tmp/evil.csv, NOT to $tmp/../../evil.csv.
	# We verify this by asserting the saved path is inside $tmp.
	# Resolve through realpath so the comparison works on macOS, where
	# File::Temp returns /var/folders/... but the controller uses
	# Mojo::File->realpath which canonicalises to /private/var/folders/...
	my $tmp = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1))->realpath->to_string;
	my $res = $t->post_ok('/export', form => {
		l        => 'table:sales',
		dir      => $tmp,
		filename => '../../evil.csv',
	})->status_is(200)->tx->res->json;
	# Canonicalize both paths to allow for Windows backslash variations
	my $saved_canonical = Mojo::File->new($res->{saved})->realpath->to_string;
	my $tmp_canonical   = Mojo::File->new($tmp)->realpath->to_string;
	like($saved_canonical, qr{\A\Q$tmp_canonical\E[\\/]}, 'saved path is inside the requested dir');
	unlike($saved_canonical, qr{\.\.},        'saved path contains no ".." traversal');
};

# ---------------------------------------------------------------------------
# Attack vector 9: Upload extension bypass and filename traversal
#
# upload_file strips directory components (s{.*[/\\]}{}) then validates the
# cleaned filename against EXT_RE before any filesystem write.
# ---------------------------------------------------------------------------

subtest 'POST /upload -- PHP extension is rejected' => sub {
	# Exploit mechanism: upload a PHP file to be executed by the web server.
	# Proof: EXT_RE = /\.(?:csv|db|sql|xml|psv)$/i; .php fails.
	$t->post_ok('/upload', form => {
		file => { content => '<?php system($_GET["cmd"]); ?>', filename => 'shell.php' }
	})->status_is(415)->json_like('/error', qr/Unsupported/i);
};

subtest 'POST /upload -- double-extension bypass is rejected' => sub {
	# Exploit mechanism: "evil.csv.php" -- regex applied to the full
	# (dir-stripped) filename; /\.php$/ does not match .csv.
	# Proof: EXT_RE matches $filename at the end via /i pattern.
	$t->post_ok('/upload', form => {
		file => { content => '<?php system("id"); ?>', filename => 'evil.csv.php' }
	})->status_is(415);
};

subtest 'POST /upload -- missing file returns 400' => sub {
	# Proof: $upload->filename guard fires => 400.
	$t->post_ok('/upload', form => { notfile => 'dummy' })->status_is(400)->json_like('/error', qr/No file/i);
};

subtest 'POST /upload -- filename directory traversal is stripped' => sub {
	# Exploit mechanism: "../../evil.csv" as filename hoping to write outside
	# .uploads/.  The upload itself may succeed (extension is valid); what
	# matters is that the file lands in .uploads/<random>/evil.csv, not ../../.
	# Proof: s{.*[/\\]}{} strips "../../" leaving "evil.csv", then stored in
	# a randomly-named subdirectory of .uploads/.
	my $res = $t->post_ok('/upload', form => {
		file => {
			content  => "id,name\n1,safe\n",
			filename => '../../evil.csv',
		}
	})->status_is(200)->tx->res->json;
	like($res->{path}, qr{\.uploads[/\\]}, 'upload path is inside .uploads/');
	unlike($res->{path}, qr{\.\.},     'upload path has no directory traversal');
};

# ---------------------------------------------------------------------------
# Attack vector 10: HTTP header injection via Accept-Language
#
# _resolve_language extracts only [a-z]{2} from Accept-Language.
# CRLF sequences, script tags, and long injected strings are ignored because
# the regex discards everything that isn't a two-letter lowercase code.
# ---------------------------------------------------------------------------

subtest 'Accept-Language -- arbitrary garbage yields default language' => sub {
	# Exploit mechanism: an oversized or random-chars Accept-Language header
	# hoping the regex match fails in an exploitable way (e.g. catastrophic
	# backtracking) or reflects content into the response.
	# Proof: /\b([a-z]{2})(?:-[A-Z]{2})?\b/ produces undef for non-matching
	# strings; undef falls through to the configured default language ("en").
	# The response must be 200 (not 500) and must render the English home page.
	# Note: Mojo correctly refuses to send literal CRLF in request headers
	# (HTTP/1.1 header injection is blocked at the transport layer), so the
	# CRLF injection vector is prevented by the framework itself.
	my $garbage = 'X' x 4096;   # very long, no two-letter lowercase sequence
	$t->get_ok('/', { 'Accept-Language' => $garbage })
	  ->status_is(200);
};

subtest 'Accept-Language -- XSS payload is ignored, falls back to default' => sub {
	# Proof: /\b([a-z]{2})\b/ extracts at most 2 chars; "<script>" has no
	# two-letter match in a word-boundary context => $lang is undef => $default.
	$t->get_ok('/', {
		'Accept-Language' => '<script>alert(1)</script>'
	})->status_is(200)
	  ->content_unlike(qr/<script>alert\(1\)<\/script>/,
	     'XSS in Accept-Language is not reflected');
};

# ---------------------------------------------------------------------------
# Attack vector 11: API endpoint parameter hardening
# ---------------------------------------------------------------------------

subtest 'GET /api/stat -- null byte path returns exists:false, not a crash' => sub {
	# Exploit mechanism: "/tmp/file.csv\x00../../etc" -- C-library realpath(3)
	# truncates at null; Perl 5.12+ eval catches the exception or the truncated
	# path is non-existent.  Either way, defined $file is false => {exists:false}.
	# Proof: response is HTTP 200 (no crash) with JSON exists:false.
	my $null = "/tmp/file.csv\x00../../etc";
	$t->get_ok('/api/stat?path=' . url_escape($null))
	  ->status_is(200)
	  ->json_is('/exists', false);
};

subtest 'GET /api/stat -- missing path returns 400' => sub {
	$t->get_ok('/api/stat')
	  ->status_is(400);
};

subtest 'GET /api/stat -- /etc/passwd returns exists:false (extension guard)' => sub {
	# Exploit mechanism: attacker uses stat_api as a filesystem oracle to map
	# the server's filesystem by probing arbitrary paths for existence, size,
	# and modification time -- useful for fingerprinting or side-channel attacks.
	# Fix: stat_api now requires the path basename to match EXT_RE (supported
	# data file extensions: csv, db, sql, xml, psv).  /etc/passwd has no such
	# extension, so it is treated as non-existent from the caller's perspective.
	$t->get_ok('/api/stat?path=' . url_escape('/etc/passwd'))
	  ->status_is(200)
	  ->json_is('/exists', false, '/etc/passwd is not stat-able via stat_api');
};

subtest 'GET /api/columns -- XSS in table name returns 404' => sub {
	$t->get_ok('/api/columns?table=' . url_escape($XSS_PAYLOAD))
	  ->status_is(404);
};

subtest 'GET /api/columns -- path traversal to /etc/passwd returns 404' => sub {
	$t->get_ok('/api/columns?path=' . url_escape('/etc/passwd'))
	  ->status_is(404);
};

subtest 'GET /api/dirs -- file path returns 404 (must be directory)' => sub {
	$t->get_ok('/api/dirs?path=' . url_escape('/etc/passwd'))
	  ->status_is(404);
};

subtest 'GET /api/dirs -- non-existent path returns 404' => sub {
	$t->get_ok('/api/dirs?path=' . url_escape('/nonexistent/xyzzy'))
	  ->status_is(404);
};

# ---------------------------------------------------------------------------
# Attack vector 12: Oversized upload (DoS via disk/memory exhaustion)
#
# When Mojolicious's max_request_size is exceeded it sets req->is_limit_exceeded
# and still dispatches to the controller (with partial content in the upload
# asset).  upload_file checks is_limit_exceeded first and returns 413 with a
# JSON error before any write to .uploads/.
#
# We prove the guard by temporarily shrinking max_request_size to 1 KiB and
# uploading 5 KiB — identical semantics to the 50 MiB real limit but without
# allocating 50 MiB in the test process.
# ---------------------------------------------------------------------------

subtest 'POST /upload -- oversized file returns 413' => sub {
	# Exploit mechanism: attacker streams a large body to exhaust disk space or
	# RAM during multipart parsing.
	# Proof: req->is_limit_exceeded triggers a 413 JSON error before any write.
	my $orig_limit = $t->app->max_request_size;
	$t->app->max_request_size(1024);  # 1 KiB for the duration of this subtest

	$t->post_ok('/upload', form => {
		file => { content => 'A' x 5000, filename => 'huge.csv' },
	})->status_is(413)
	  ->json_like('/error', qr/too large/i,
	     'oversized upload returns 413 with too-large message');

	$t->app->max_request_size($orig_limit);  # restore
};

# ---------------------------------------------------------------------------
# Attack vector 13: Hostile Calc expressions
#
# Database::BI::Calc MUST reject expressions that contain shell metacharacters,
# Perl eval, require, backticks, BEGIN blocks, or other injection vectors.
# The module uses a pure recursive-descent parser with no string eval; any
# attempt to inject code must surface as a compile-time error from ->error,
# not as execution.  The ?c= URL parameter feeds expressions to Calc->new,
# so a hostile value arriving via HTTP must also be rejected as a 400.
# ---------------------------------------------------------------------------

subtest 'GET /pivot -- hostile ?c= calc expression returns 400' => sub {
	# Proof: Calc->new rejects the expression at compile time; the controller
	# returns 400 and the expression is never executed.
	my @hostile = (
		'0; system("rm -rf /")',
		'`id`',
		'eval("die")',
		'require POSIX',
	);
	for my $h (@hostile) {
		$t->get_ok('/pivot?l=table:sales&rows=product&m=amount:sum:total'
		    . '&c=evil:' . Mojo::Util::url_escape($h))
		  ->status_is(400, "hostile calc expr rejected: $h");
	}
};

subtest 'Calc->new -- hostile expressions produce compile errors, not execution' => sub {
	use_ok 'Database::BI::Calc';

	my @cases = (
		'0; system("rm -rf /")',
		'`id`',
		'${\ system("id")}',
		'eval("die")',
		'require POSIX',
		'BEGIN { die }',
	);
	for my $expr (@cases) {
		my $c = Database::BI::Calc->new(expr => $expr, columns => []);
		ok $c->has_error, "hostile expr has error: $expr";
		ok defined $c->error, "hostile expr error is defined: $expr";
	}
};

done_testing();
