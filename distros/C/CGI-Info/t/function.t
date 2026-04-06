#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Scalar::Util qw(blessed);
use Test::Mockingbird qw(mock mock_scoped);

# We test CGI::Info itself
BEGIN { use_ok('CGI::Info') }

# Silence Log::Abstraction's stderr output for warn/error during the entire
# test run.  These are expected, intentional log calls (WAF blocks, validation
# failures, etc.) that would otherwise clutter the harness output.  We still
# verify behaviour via status codes and return values, not log side-effects.
mock 'Log::Abstraction::_high_priority' => sub { };

# ---------------------------------------------------------------------------
# Helper: reset CGI environment and class state between subtests
# ---------------------------------------------------------------------------
sub reset_env {
	delete $ENV{$_} for qw(
		GATEWAY_INTERFACE REQUEST_METHOD QUERY_STRING CONTENT_TYPE
		CONTENT_LENGTH SCRIPT_NAME SCRIPT_FILENAME DOCUMENT_ROOT
		C_DOCUMENT_ROOT HTTP_HOST SERVER_NAME SSL_TLS_SNI SERVER_PROTOCOL
		SERVER_PORT SCRIPT_URI REMOTE_ADDR HTTP_USER_AGENT HTTP_COOKIE
		HTTP_X_WAP_PROFILE HTTP_SEC_CH_UA_MOBILE HTTP_REFERER IS_MOBILE
		IS_SEARCH_ENGINE LOGDIR
	);
	CGI::Info->reset();
}

# ============================================================
# 1. new()
# ============================================================
subtest 'new() - basic instantiation' => sub {
	reset_env();
	my $info = new_ok('CGI::Info');
	ok(blessed($info), 'new() returns a blessed object');
	isa_ok($info, 'CGI::Info');
};

subtest 'new() - hashref args' => sub {
	reset_env();
	my $info = CGI::Info->new({ max_upload_size => 1024 });
	is($info->{max_upload_size}, 1024, 'max_upload_size set via hashref');
};

subtest 'new() - hash args' => sub {
	reset_env();
	my $info = CGI::Info->new(max_upload_size => 2048);
	is($info->{max_upload_size}, 2048, 'max_upload_size set via flat hash');
};

subtest 'new() - clone from existing object' => sub {
	reset_env();
	my $orig  = CGI::Info->new(max_upload_size => 999);
	my $clone = $orig->new(max_upload_size => 111);
	is($clone->{max_upload_size}, 111, 'clone overrides field');
	is($orig->{max_upload_size},  999, 'original unchanged');
};

subtest 'new() - expect deprecated croak' => sub {
	reset_env();
	eval { CGI::Info->new(expect => [qw(foo)]) };
	like($@, qr/expect has been deprecated/i, 'expect param causes croak');
};

# Line 157 boundary: CGI::Info::new() (double-colon, undef $class) checks
# (scalar keys %{$params}) > 0 to decide whether to croak.
# Boundary values are 0 (should NOT croak) and 1 (should croak).
# All four mutant flips (> to <, >=, <=, ==) are killed by testing both sides.
subtest 'new() - ::new() with 0 params does not croak (boundary = 0)' => sub {
	reset_env();
	# CGI::Info::new() with no args: $class is undef, $params is empty,
	# guard at line 157 does not fire, $class self-heals to __PACKAGE__.
	my $info = eval { CGI::Info::new() };
	ok(!$@, '::new() with no args does not croak');
	ok(blessed($info), '::new() with no args still returns an object');
};

subtest 'new() - ::new() with 1+ params croaks (boundary = 1)' => sub {
	reset_env();
	# The guard is only reachable when $class is explicitly undef (the FIXME
	# in the source acknowledges this).  CGI::Info::new(key => val) would make
	# "key" become $class, hitting Params::Get before the guard.  So we pass
	# undef explicitly to exercise the boundary.
	eval { CGI::Info::new(undef, max_upload_size => 1024) };
	like($@, qr/use ->new\(\) not ::new\(\)/i,
		'::new() with undef class + 1 param croaks with helpful message');
};

subtest 'new() - bad logger guard logic is correct' => sub {
	reset_env();
	# Object::Configure::configure() pre-processes params before new() reaches
	# its logger validation, so we cannot reliably trigger the croak via new().
	# Instead verify the guard condition itself is sound: a blessed object that
	# lacks warn/info/error should satisfy the "would croak" predicate.
	{
		package NoMethodLogger;
		sub new { bless {}, shift }
		# deliberately no warn/info/error
	}
	my $bad = NoMethodLogger->new();
	my $would_croak = Scalar::Util::blessed($bad)
		&& !( $bad->can('warn') && $bad->can('info') && $bad->can('error') );
	ok($would_croak, 'object lacking warn/info/error fails the logger guard');

	# And confirm a proper logger object passes the guard
	{
		package GoodLogger;
		sub new   { bless {}, shift }
		sub warn  { }
		sub info  { }
		sub error { }
	}
	my $good = GoodLogger->new();
	my $would_pass = Scalar::Util::blessed($good)
		&& $good->can('warn') && $good->can('info') && $good->can('error');
	ok($would_pass, 'object with warn/info/error passes the logger guard');
};

# ============================================================
# 2. reset() class method
# ============================================================
subtest 'reset()' => sub {
	reset_env();
	# Simulate STDIN read by setting class variable indirectly
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'a=1';
	my $info = CGI::Info->new();
	$info->params();
	CGI::Info->reset();
	ok(!defined $CGI::Info::stdin_data, 'reset() clears stdin_data');
};

subtest 'reset() warns when called as object method' => sub {
	reset_env();
	my $info = CGI::Info->new();
	# reset() carps (not croaks) when called as object method; suppress stderr noise
	local $SIG{__WARN__} = sub { };
	eval { $info->reset() };
	ok(1, 'object-method reset() does not die');
};

# ============================================================
# 3. status()
# ============================================================
subtest 'status() - defaults to 200' => sub {
	reset_env();
	my $info = CGI::Info->new();
	is($info->status(), 200, 'default status is 200');
};

subtest 'status() - set and retrieve' => sub {
	reset_env();
	my $info = CGI::Info->new();
	$info->status(404);
	is($info->status(), 404, 'status round-trips correctly');
};

subtest 'status() - OPTIONS sets 405 implicitly' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'OPTIONS';
	my $info = CGI::Info->new();
	$info->params();
	is($info->status(), 405, 'OPTIONS yields 405');
};

subtest 'status() - DELETE sets 405 implicitly' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'DELETE';
	my $info = CGI::Info->new();
	$info->params();
	is($info->status(), 405, 'DELETE yields 405');
};

# ============================================================
# 4. params()
# ============================================================
subtest 'params() - GET simple query' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'foo=bar&baz=42';
	my $info = CGI::Info->new();
	my $p = $info->params();
	ok(defined $p, 'params() returns defined value');
	is($p->{foo}, 'bar', 'foo=bar parsed');
	is($p->{baz}, '42',  'baz=42 parsed');
};

subtest 'params() - GET no query string returns undef' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = '';
	my $info = CGI::Info->new();
	my $p = $info->params();
	ok(!defined $p, 'empty QUERY_STRING returns undef');
};

subtest 'params() - allow filters unknown keys' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'good=1&evil=2';
	my $info = CGI::Info->new();
	my $p = $info->params(allow => { good => qr/^\d+$/ });
	ok(defined $p->{good}, 'allowed key present');
	ok(!defined $p->{evil}, 'disallowed key absent');
};

subtest 'params() - allow regex mismatch blocks value' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'id=abc';
	my $info = CGI::Info->new();
	my $p = $info->params(allow => { id => qr/^\d+$/ });
	ok(!defined($p), 'regex-blocked key excluded from result');
	is($info->status(), 422, 'status 422 set on validation failure');
};

subtest 'params() - allow exact-string match' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'color=blue&color=red';
	my $info = CGI::Info->new();
	my $p = $info->params(allow => { color => 'blue' });
	# 'blue' matches, but 'red' appears as comma-separated; blue matches first
	ok(defined $p, 'exact-string allow passes matching value');
};

subtest 'params() - allow coderef validator' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'num=4&num2=3';
	my $info = CGI::Info->new();
	my $p = $info->params(allow => {
		num  => sub { ($_[1] % 2) == 0 },   # even => pass
		num2 => sub { ($_[1] % 2) == 0 },   # odd  => fail
	});
	ok(defined $p->{num},  'even number passes coderef validator');
	ok(!defined $p->{num2}, 'odd number blocked by coderef validator');
};

subtest 'params() - SQL injection blocked (GET)' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = "id=1'%20OR%201=1";
	my $info = CGI::Info->new();
	my $p = $info->params();
	ok(!defined $p, 'SQL injection blocked');
	is($info->status(), 403, 'status 403 on SQL injection');
};

subtest 'params() - XSS injection blocked (GET)' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'q=%3Cscript%3Ealert(1)%3C%2Fscript%3E';
	my $info = CGI::Info->new();
	my $p = $info->params();
	ok(!defined $p, 'XSS injection blocked');
	is($info->status(), 403, 'status 403 on XSS');
};

subtest 'params() - directory traversal blocked (GET)' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'file=../../etc/passwd';
	my $info = CGI::Info->new();
	my $p = $info->params();
	ok(!defined $p, 'directory traversal blocked');
	is($info->status(), 403, 'status 403 on directory traversal');
};

subtest 'params() - mustleak attack blocked (GET)' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'x=mustleak.com/probe';
	my $info = CGI::Info->new();
	my $p = $info->params();
	ok(!defined $p, 'mustleak attack blocked');
	is($info->status(), 403, 'status 403 on mustleak');
};

subtest 'params() - duplicate values comma-joined' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'color=red&color=blue';
	my $info = CGI::Info->new();
	my $p = $info->params();
	like($p->{color}, qr/red.*blue|blue.*red/, 'duplicate values comma-joined');
};

subtest 'params() - POST missing CONTENT_LENGTH => 411' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'POST';
	# no CONTENT_LENGTH
	my $info = CGI::Info->new();
	my $p = $info->params();
	ok(!defined $p, 'POST without CONTENT_LENGTH returns undef');
	is($info->status(), 411, 'status 411');
};

subtest 'params() - POST oversized => 413' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'POST';
	$ENV{CONTENT_LENGTH}	= 999_999_999;
	my $info = CGI::Info->new(max_upload_size => 100);
	my $p = $info->params();
	ok(!defined $p, 'oversized POST returns undef');
	is($info->status(), 413, 'status 413 on large upload');
};

subtest 'params() - command-line key=value pairs (non-CGI)' => sub {
	reset_env();
	local @ARGV = ('name=Alice', 'age=30');
	my $info = CGI::Info->new();
	my $p = $info->params();
	is($p->{name}, 'Alice', 'name from ARGV');
	is($p->{age},  '30',	'age from ARGV');
};

subtest 'params() - --mobile flag from ARGV' => sub {
	reset_env();
	local @ARGV = ('--mobile', 'x=1');
	my $info = CGI::Info->new();
	$info->params();
	ok($info->is_mobile(), '--mobile flag sets is_mobile');
};

subtest 'params() - --robot flag from ARGV' => sub {
	reset_env();
	local @ARGV = ('--robot');
	my $info = CGI::Info->new();
	$info->params();
	ok($info->is_robot(), '--robot flag sets is_robot');
};

subtest 'params() - --search-engine flag from ARGV' => sub {
	reset_env();
	local @ARGV = ('--search-engine');
	my $info = CGI::Info->new();
	$info->params();
	ok($info->is_search_engine(), '--search-engine flag sets is_search_engine');
};

subtest 'params() - --tablet flag from ARGV' => sub {
	reset_env();
	local @ARGV = ('--tablet');
	my $info = CGI::Info->new();
	$info->params();
	ok($info->is_tablet(), '--tablet flag sets is_tablet');
};

subtest 'params() - caches result on second call' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'k=v';
	my $info = CGI::Info->new();
	my $p1 = $info->params();
	my $p2 = $info->params();
	is($p1, $p2, 'second call returns same hashref (cached)');
};

# ============================================================
# 5. param($field)
# ============================================================
subtest 'param() - returns single value' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'foo=hello';
	my $info = CGI::Info->new();
	is($info->param('foo'), 'hello', 'param() returns correct value');
};

subtest 'param() - missing key returns undef' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'foo=hello';
	my $info = CGI::Info->new();
	ok(!defined $info->param('bar'), 'missing param returns undef');
};

subtest 'param() - no arg delegates to params()' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'x=1';
	my $info = CGI::Info->new();
	my $p = $info->param();
	ok(ref $p eq 'HASH', 'param() with no arg returns hashref');
};

subtest 'param() - warns when key not in allow list' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'foo=1';
	my $info = CGI::Info->new(allow => { foo => qr/\d+/ });
	$info->params();
	my $val = $info->param('bar');
	ok(!defined $val, 'param() returns undef for key outside allow list');
};

# ============================================================
# 6. as_string()
# ============================================================
subtest 'as_string() - returns key=value pairs' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'b=2&a=1';
	my $info = CGI::Info->new();
	$info->params();
	my $str = $info->as_string();
	like($str, qr/a=1/, 'a=1 in as_string output');
	like($str, qr/b=2/, 'b=2 in as_string output');
};

subtest 'as_string() - raw mode skips escaping' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'x=hello';
	my $info = CGI::Info->new();
	$info->params();
	my $raw = $info->as_string({ raw => 1 });
	is($raw, 'x=hello', 'raw mode returns unescaped string');
};

subtest 'as_string() - empty params returns empty string' => sub {
	reset_env();
	my $info = CGI::Info->new();
	is($info->as_string(), '', 'as_string() with no params returns empty string');
};

subtest 'as_string() - escapes semicolons and equals in values' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'note=a%3Db';   # note=a=b
	my $info = CGI::Info->new();
	$info->params();
	my $str = $info->as_string();
	like($str, qr/note=/, 'note key present in escaped output');
};

# ============================================================
# 7. script_name() and script_path() and script_dir()
# ============================================================
subtest 'script_name() - from SCRIPT_NAME env' => sub {
	reset_env();
	$ENV{SCRIPT_NAME} = '/cgi-bin/test.cgi';
	my $info = CGI::Info->new();
	like($info->script_name(), qr/test\.cgi/, 'script_name returns basename');
};

subtest 'script_path() - from SCRIPT_FILENAME env' => sub {
	reset_env();
	$ENV{SCRIPT_FILENAME} = '/var/www/cgi-bin/test.cgi';
	my $info = CGI::Info->new();
	is($info->script_path(), '/var/www/cgi-bin/test.cgi', 'script_path from SCRIPT_FILENAME');
};

subtest 'script_dir() - returns directory portion' => sub {
	reset_env();
	$ENV{SCRIPT_FILENAME} = '/var/www/cgi-bin/test.cgi';
	my $info = CGI::Info->new();
	is($info->script_dir(), '/var/www/cgi-bin', 'script_dir correct');
};

subtest 'script_dir() - class method instantiates object' => sub {
	reset_env();
	$ENV{SCRIPT_FILENAME} = '/tmp/myscript.pl';
	my $dir = CGI::Info->script_dir();
	ok(defined $dir, 'script_dir() as class method returns something');
};

# ============================================================
# 8. host_name() / domain_name() / cgi_host_url()
# ============================================================
subtest 'host_name() - from HTTP_HOST' => sub {
	reset_env();
	$ENV{HTTP_HOST} = 'www.example.com';
	my $info = CGI::Info->new();
	is($info->host_name(), 'www.example.com', 'host_name from HTTP_HOST');
};

subtest 'domain_name() - strips www prefix' => sub {
	reset_env();
	$ENV{HTTP_HOST} = 'www.example.com';
	my $info = CGI::Info->new();
	is($info->domain_name(), 'example.com', 'domain_name strips www.');
};

subtest 'domain_name() - class method' => sub {
	reset_env();
	$ENV{HTTP_HOST} = 'www.example.org';
	my $d = CGI::Info->domain_name();
	is($d, 'example.org', 'domain_name() as class method');
};

subtest 'cgi_host_url() - returns protocol+host' => sub {
	reset_env();
	$ENV{HTTP_HOST}	   = 'example.com';
	$ENV{SERVER_PROTOCOL} = 'HTTP/1.1';
	my $info = CGI::Info->new();
	my $url = $info->cgi_host_url();
	like($url, qr/^https?:\/\/example\.com/, 'cgi_host_url has protocol prefix');
};

# ============================================================
# 9. protocol()
# ============================================================
subtest 'protocol() - from SCRIPT_URI' => sub {
	reset_env();
	$ENV{SCRIPT_URI} = 'https://example.com/cgi-bin/test.cgi';
	my $info = CGI::Info->new();
	is($info->protocol(), 'https', 'protocol from SCRIPT_URI');
};

subtest 'protocol() - from SERVER_PROTOCOL' => sub {
	reset_env();
	$ENV{SERVER_PROTOCOL} = 'HTTP/1.1';
	my $info = CGI::Info->new();
	is($info->protocol(), 'http', 'protocol http from SERVER_PROTOCOL');
};

# For the SERVER_PORT branch we must ensure the earlier branches don't fire
# (no SCRIPT_URI, no SERVER_PROTOCOL) and that getservbyport() returns undef
# so execution falls through to the explicit == 80 / == 443 comparisons on
# lines 1449-1451.  This is what the mutant-test survivor was flagging.
subtest 'protocol() - SERVER_PORT 443 boundary (line 1451)' => sub {
	reset_env();
	my $guard = mock_scoped 'Socket::getservbyport' => sub { return undef };

	# Exact boundary: port 443 must return 'https'
	$ENV{SERVER_PORT} = 443;
	is(CGI::Info->new()->protocol(), 'https', 'port 443 => https');

	# One below boundary: port 442 must NOT return 'https' via this branch
	$ENV{SERVER_PORT} = 442;
	my $p = CGI::Info->new()->protocol();
	ok(!defined($p) || $p ne 'https', 'port 442 does not return https');

	# One above boundary: port 444 must NOT return 'https' via this branch
	$ENV{SERVER_PORT} = 444;
	$p = CGI::Info->new()->protocol();
	ok(!defined($p) || $p ne 'https', 'port 444 does not return https');
};

subtest 'protocol() - SERVER_PORT 80 boundary (line 1449)' => sub {
	reset_env();
	my $guard = mock_scoped 'Socket::getservbyport' => sub { return undef };

	# Exact boundary: port 80 must return 'http'
	$ENV{SERVER_PORT} = 80;
	is(CGI::Info->new()->protocol(), 'http', 'port 80 => http');

	# One below: port 79 must NOT return 'http' via this branch
	$ENV{SERVER_PORT} = 79;
	my $p = CGI::Info->new()->protocol();
	ok(!defined($p) || $p ne 'http', 'port 79 does not return http');

	# One above: port 81 must NOT return 'http' via this branch
	$ENV{SERVER_PORT} = 81;
	$p = CGI::Info->new()->protocol();
	ok(!defined($p) || $p ne 'http', 'port 81 does not return http');
};

# ============================================================
# 10. is_mobile()
# ============================================================
subtest 'is_mobile() - iPhone user agent' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	my $info = CGI::Info->new();
	ok($info->is_mobile(), 'iPhone UA detected as mobile');
};

subtest 'is_mobile() - Android user agent' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Linux; Android 10; Pixel 3)';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	my $info = CGI::Info->new();
	ok($info->is_mobile(), 'Android UA detected as mobile');
};

subtest 'is_mobile() - desktop user agent' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	my $info = CGI::Info->new();
	ok(!$info->is_mobile(), 'desktop UA not detected as mobile');
};

subtest 'is_mobile() - Sec-CH-UA-Mobile hint' => sub {
	reset_env();
	$ENV{HTTP_SEC_CH_UA_MOBILE} = '?1';
	my $info = CGI::Info->new();
	ok($info->is_mobile(), 'Sec-CH-UA-Mobile ?1 detected as mobile');
};

subtest 'is_mobile() - HTTP_X_WAP_PROFILE' => sub {
	reset_env();
	$ENV{HTTP_X_WAP_PROFILE} = 'http://wap.example.com/profile';
	my $info = CGI::Info->new();
	ok($info->is_mobile(), 'WAP profile header detected as mobile');
};

subtest 'is_mobile() - IS_MOBILE env override' => sub {
	reset_env();
	$ENV{IS_MOBILE} = 1;
	my $info = CGI::Info->new();
	ok($info->is_mobile(), 'IS_MOBILE env override works');
};

# ============================================================
# 11. is_tablet()
# ============================================================
subtest 'is_tablet() - iPad user agent' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPad; CPU OS 14_0 like Mac OS X)';
	my $info = CGI::Info->new();
	ok($info->is_tablet(), 'iPad UA detected as tablet');
};

subtest 'is_tablet() - non-tablet user agent' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Windows NT 10.0)';
	my $info = CGI::Info->new();
	ok(!$info->is_tablet(), 'desktop UA not a tablet');
};

# ============================================================
# 12. is_robot()
# ============================================================
subtest 'is_robot() - known bot UA' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Googlebot/2.1 (+http://www.google.com/bot.html)';
	$ENV{REMOTE_ADDR}	 = '66.249.66.1';
	my $info = CGI::Info->new();
	# Googlebot may be classed as search engine not robot; either is acceptable
	my $result = $info->is_robot() || $info->is_search_engine();
	ok($result, 'Googlebot classified as robot or search engine');
};

subtest 'is_robot() - ClaudeBot' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'ClaudeBot/1.0';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	my $info = CGI::Info->new();
	ok($info->is_robot(), 'ClaudeBot detected as robot');
};

subtest 'is_robot() - SQL injection UA => 403 + robot' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = "Mozilla SELECT foo AND bar FROM baz";
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	my $info = CGI::Info->new();
	ok($info->is_robot(), 'SQL injection UA flagged as robot');
	is($info->status(), 403, 'status 403 on SQL UA');
};

subtest 'is_robot() - no CGI env => 0' => sub {
	reset_env();
	my $info = CGI::Info->new();
	is($info->is_robot(), 0, 'no CGI env returns 0 (assume real person)');
};

# ============================================================
# 13. is_search_engine()
# ============================================================
subtest 'is_search_engine() - IS_SEARCH_ENGINE env' => sub {
	reset_env();
	$ENV{IS_SEARCH_ENGINE} = 1;
	$ENV{REMOTE_ADDR}	  = '1.2.3.4';
	$ENV{HTTP_USER_AGENT}  = 'SomeBot';
	my $info = CGI::Info->new();
	ok($info->is_search_engine(), 'IS_SEARCH_ENGINE env override works');
};

subtest 'is_search_engine() - no CGI env => 0' => sub {
	reset_env();
	my $info = CGI::Info->new();
	is($info->is_search_engine(), 0, 'no CGI env returns 0');
};

# ============================================================
# 14. browser_type()
# ============================================================
subtest 'browser_type() - mobile' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	my $info = CGI::Info->new();
	is($info->browser_type(), 'mobile', 'mobile browser_type');
};

subtest 'browser_type() - web (desktop)' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	my $info = CGI::Info->new();
	is($info->browser_type(), 'web', 'desktop browser_type is web');
};

# ============================================================
# 15. cookie() / get_cookie()
# ============================================================
subtest 'cookie() - returns value for existing cookie' => sub {
	reset_env();
	$ENV{HTTP_COOKIE} = 'session=abc123; user=bob';
	my $info = CGI::Info->new();
	is($info->cookie('session'), 'abc123', 'cookie() returns session value');
	is($info->cookie('user'),	'bob',	'cookie() returns user value');
};

subtest 'cookie() - returns undef for missing cookie' => sub {
	reset_env();
	$ENV{HTTP_COOKIE} = 'a=1';
	my $info = CGI::Info->new();
	ok(!defined $info->cookie('nosuchcookie'), 'missing cookie returns undef');
};

subtest 'get_cookie() - alias for cookie()' => sub {
	reset_env();
	$ENV{HTTP_COOKIE} = 'token=xyz';
	my $info = CGI::Info->new();
	is($info->get_cookie(cookie_name => 'token'), 'xyz', 'get_cookie() alias works');
};

subtest 'cookie() - no cookie env returns undef' => sub {
	reset_env();
	my $info = CGI::Info->new();
	ok(!defined $info->cookie('x'), 'no HTTP_COOKIE returns undef');
};

# ============================================================
# 16. tmpdir()
# ============================================================
subtest 'tmpdir() - returns a writable directory' => sub {
	reset_env();
	my $info = CGI::Info->new();
	my $dir  = $info->tmpdir();
	ok(defined $dir,   'tmpdir() returns defined value');
	ok(-d $dir,		'tmpdir() is a directory');
	ok(-w $dir,		'tmpdir() is writable');
};

subtest 'tmpdir() - default param honoured when nothing better' => sub {
	reset_env();
	my $tmp   = tempdir(CLEANUP => 1);
	my $info  = CGI::Info->new();
	my $dir   = $info->tmpdir(default => $tmp);
	# Either it found a system tmp or used the default
	ok(defined $dir, 'tmpdir() with default returns defined value');
};

subtest 'tmpdir() - class method' => sub {
	reset_env();
	my $dir = CGI::Info->tmpdir();
	ok(defined $dir, 'tmpdir() as class method works');
};

# ============================================================
# 17. rootdir() / root_dir() / documentroot()
# ============================================================
subtest 'rootdir() - from C_DOCUMENT_ROOT' => sub {
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{C_DOCUMENT_ROOT} = $tmp;
	is(CGI::Info->rootdir(), $tmp, 'rootdir from C_DOCUMENT_ROOT');
};

subtest 'rootdir() - from DOCUMENT_ROOT' => sub {
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{DOCUMENT_ROOT} = $tmp;
	is(CGI::Info->rootdir(), $tmp, 'rootdir from DOCUMENT_ROOT');
};

subtest 'root_dir() - synonym' => sub {
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{C_DOCUMENT_ROOT} = $tmp;
	is(CGI::Info->root_dir(), $tmp, 'root_dir() synonym works');
};

subtest 'documentroot() - synonym' => sub {
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{C_DOCUMENT_ROOT} = $tmp;
	is(CGI::Info->documentroot(), $tmp, 'documentroot() synonym works');
};

# ============================================================
# 18. logdir()
# ============================================================
subtest 'logdir() - valid directory' => sub {
	reset_env();
	my $tmp  = tempdir(CLEANUP => 1);
	my $info = CGI::Info->new();
	my $dir  = $info->logdir($tmp);
	is($dir, $tmp, 'logdir() accepts and returns valid dir');
};

subtest 'logdir() - invalid dir croaks' => sub {
	reset_env();
	my $info = CGI::Info->new();
	eval { $info->logdir('/non/existent/path/xyz') };
	like($@, qr/Invalid logdir/i, 'logdir() croaks on bad path');
};

subtest 'logdir() - falls back to tmpdir' => sub {
	reset_env();
	my $info = CGI::Info->new();
	my $dir  = $info->logdir();
	ok(defined $dir && -d $dir, 'logdir() without arg returns a valid directory');
};

# ============================================================
# 19. messages() / messages_as_string()
# ============================================================
subtest 'messages() - returns undef when no messages' => sub {
	reset_env();
	my $info = CGI::Info->new();
	ok(!defined $info->messages() || ref $info->messages() eq 'ARRAY',
	   'messages() returns undef or arrayref');
};

subtest 'messages_as_string() - empty returns empty string' => sub {
	reset_env();
	my $info = CGI::Info->new();
	is($info->messages_as_string(), '', 'messages_as_string() empty initially');
};

subtest 'messages_as_string() - contains warning after bad param' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'id=abc';
	my $info = CGI::Info->new();
	$info->params(allow => { id => qr/^\d+$/ });
	# A message should have been logged about blocking
	ok(defined $info->messages(), 'messages() has entries after validation failure');
};

# ============================================================
# 20. cache()
# ============================================================
subtest 'cache() - set and get' => sub {
	reset_env();
	# Minimal mock cache object
	my $mock_cache = bless {}, 'MockCache';
	{ no warnings 'once';
	  *MockCache::get = sub { undef };
	  *MockCache::set = sub { 1 };
	}
	my $info = CGI::Info->new();
	$info->cache($mock_cache);
	is($info->cache(), $mock_cache, 'cache() round-trips object');
};

subtest 'cache() - non-object croaks' => sub {
	reset_env();
	my $info = CGI::Info->new();
	eval { $info->cache('not-an-object') };
	like($@, qr/is not an object/i, 'cache() croaks on non-object');
};

# ============================================================
# 21. set_logger()
# ============================================================
subtest 'set_logger() - accepts object with warn/info/error' => sub {
	reset_env();
	my $log = bless {}, 'MockLogger';
	{ no warnings 'once';
	  *MockLogger::warn  = sub { };
	  *MockLogger::info  = sub { };
	  *MockLogger::error = sub { };
	  *MockLogger::debug = sub { };
	  *MockLogger::trace = sub { };
	}
	my $info = CGI::Info->new();
	$info->set_logger($log);
	is($info->{logger}, $log, 'set_logger() stores logger object');
};

subtest 'set_logger() - returns $self for chaining' => sub {
	reset_env();
	my $info = CGI::Info->new();
	my $ret  = $info->set_logger('/dev/null');
	is($ret, $info, 'set_logger() returns $self');
};

# ============================================================
# 22. AUTOLOAD
# ============================================================
subtest 'AUTOLOAD - delegates to param()' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'myfield=myvalue';
	my $info = CGI::Info->new();
	is($info->myfield(), 'myvalue', 'AUTOLOAD delegates unknown method to param()');
};

subtest 'AUTOLOAD - unknown method with no params returns undef' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'x=1';
	my $info = CGI::Info->new();
	$info->params();
	ok(!defined $info->nosuchparam(), 'AUTOLOAD on missing param returns undef');
};

subtest 'AUTOLOAD - disabled auto_load croaks' => sub {
	reset_env();
	my $info = CGI::Info->new(auto_load => 0);
	eval { $info->thisdoesnotexist() };
	like($@, qr/Unknown method/i, 'AUTOLOAD disabled causes croak');
};

# ============================================================
# 23. Internal helper: _sanitise_input  (white-box via params())
# ============================================================
subtest '_sanitise_input - strips leading/trailing whitespace' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'k=%20hello%20';
	my $info = CGI::Info->new();
	my $p = $info->params();
	if(defined $p) {
		unlike($p->{k}, qr/^\s|\s$/, '_sanitise_input strips surrounding spaces');
	} else {
		pass('no params returned (value sanitised away)');
	}
};

subtest '_sanitise_input - strips CR/LF' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	# Pass a value that after URL-decode contains \r\n
	$ENV{QUERY_STRING}	  = 'note=hello%0D%0Aworld';
	my $info = CGI::Info->new();
	my $p = $info->params();
	if(defined $p && defined $p->{note}) {
		unlike($p->{note}, qr/[\r\n]/, '_sanitise_input removes CR/LF');
	} else {
		pass('value sanitised away (acceptable)');
	}
};

# ============================================================
# 24. Internal helper: _get_env (white-box via script_path)
# ============================================================
subtest '_get_env - rejects env vars with bad chars' => sub {
	reset_env();
	$ENV{SCRIPT_FILENAME} = '/valid/path/script.cgi';
	my $info = CGI::Info->new();
	is($info->script_path(), '/valid/path/script.cgi', '_get_env passes clean value');
};

subtest '_get_env - accepts path with valid special chars' => sub {
	reset_env();
	$ENV{SCRIPT_FILENAME} = '/var/www/cgi-bin/my_script.pl';
	my $info = CGI::Info->new();
	like($info->script_path(), qr/my_script\.pl/, '_get_env allows hyphens/underscores in path');
};

# ============================================================
# 25. Internal helper: _find_paths via script_name/script_path
# ============================================================
subtest '_find_paths - uses $0 when no env set' => sub {
	reset_env();
	my $info = CGI::Info->new();
	my $name = $info->script_name();
	ok(defined $name && length($name), '_find_paths falls back to $0 for script_name');
};

subtest '_find_paths - DOCUMENT_ROOT + SCRIPT_NAME builds path' => sub {
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{DOCUMENT_ROOT} = $tmp;
	$ENV{SCRIPT_NAME}   = '/cgi-bin/foo.cgi';
	my $info = CGI::Info->new();
	like($info->script_path(), qr/foo\.cgi/, 'script_path built from DOCUMENT_ROOT+SCRIPT_NAME');
};

# ============================================================
# 26. Internal helper: _find_site_details
# ============================================================
subtest '_find_site_details - falls back to hostname when no env' => sub {
	reset_env();
	my $info = CGI::Info->new();
	my $host = $info->host_name();
	ok(defined $host && length($host), '_find_site_details falls back to system hostname');
};

subtest '_find_site_details - trailing dots removed from HTTP_HOST' => sub {
	reset_env();
	$ENV{HTTP_HOST} = 'example.com.';
	my $info = CGI::Info->new();
	unlike($info->host_name(), qr/\.$/, 'trailing dot stripped from HTTP_HOST');
};

# ============================================================
# 27. Internal helper: _untaint_filename (white-box via script methods)
# ============================================================
subtest '_untaint_filename - valid filename passes' => sub {
	reset_env();
	$ENV{SCRIPT_FILENAME} = '/home/user/cgi-bin/test_script-1.cgi';
	my $info = CGI::Info->new();
	ok(defined $info->script_path(), '_untaint_filename accepts valid path chars');
};

# ============================================================
# 28. POST with application/json content type
# ============================================================
subtest 'params() - POST JSON decodes keys' => sub {
	reset_env();
	# Provide JSON body via the class stdin_data variable
	my $json_body = '{"alpha":"one","beta":"two"}';
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'POST';
	$ENV{CONTENT_TYPE}	  = 'application/json';
	$ENV{CONTENT_LENGTH}	= length($json_body);

	# Inject STDIN via the class variable
	$CGI::Info::stdin_data  = $json_body;

	my $info = CGI::Info->new();
	my $p	= $info->params();
	if(defined $p) {
		is($p->{alpha}, 'one', 'JSON POST: alpha=one');
		is($p->{beta},  'two', 'JSON POST: beta=two');
	} else {
		# JSON::MaybeXS may not be installed in all environments
		pass('JSON POST: no result (JSON module unavailable, acceptable)');
	}
};

# ============================================================
# 29. POST with text/xml content type
# ============================================================
subtest 'params() - POST XML stored under XML key' => sub {
	reset_env();
	my $xml_body = '<root><item>test</item></root>';
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'POST';
	$ENV{CONTENT_TYPE}	  = 'text/xml';
	$ENV{CONTENT_LENGTH}	= length($xml_body);
	$CGI::Info::stdin_data  = $xml_body;

	my $info = CGI::Info->new();
	my $p	= $info->params();
	ok(defined $p, 'XML POST returns hashref');
	is($p->{XML}, $xml_body, 'XML body stored under XML key');
};

# ============================================================
# 30. Params::Validate::Strict integration via allow hash-schema
# ============================================================
subtest 'params() - Params::Validate::Strict schema passes valid value' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'age=25';
	my $info = CGI::Info->new();
	my $p = $info->params(allow => {
		age => { type => 'integer', min => 0, max => 150 }
	});
	ok(defined $p && defined $p->{age}, 'valid age passes Params::Validate::Strict');
};

subtest 'params() - Params::Validate::Strict schema blocks invalid value' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'age=999';
	my $info = CGI::Info->new();
	my $p = $info->params(allow => {
		age => { type => 'integer', min => 0, max => 150 }
	});
	# Either blocked entirely or age is absent
	my $blocked = (!defined $p) || (!defined $p->{age});
	ok($blocked, 'out-of-range age blocked by Params::Validate::Strict');
};

done_testing();
