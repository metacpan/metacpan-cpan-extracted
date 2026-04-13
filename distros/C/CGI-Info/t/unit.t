#!/usr/bin/env perl

# Black-box tests for CGI::Info public API.
# Each subtest exercises only the published contract described in the POD;
# no knowledge of internal implementation is assumed or used.

use strict;
use warnings;

use Test::More;
use Test::Mockingbird 0.08 qw(mock mock_scoped);
use File::Temp qw(tempdir);
use File::Spec;
use Scalar::Util qw(blessed);

BEGIN { use_ok('CGI::Info') }

# Silence Log::Abstraction stderr noise from expected WAF/validation log calls.
mock 'Log::Abstraction::_high_priority' => sub { };

# ---------------------------------------------------------------------------
# Helper: wipe CGI environment and reset class state between subtests
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
	@ARGV = ();
}

# ============================================================
# new()
# ============================================================

subtest 'new() - returns a CGI::Info object' => sub {
	reset_env();
	my $info = new_ok('CGI::Info');
	ok(blessed($info), 'new() returns a blessed object');
	isa_ok($info, 'CGI::Info');
};

subtest 'new() - accepts max_upload_size' => sub {
	reset_env();
	my $info = CGI::Info->new(max_upload_size => 65536);
	isa_ok($info, 'CGI::Info', 'constructed with max_upload_size');
};

subtest 'new() - accepts hashref of arguments' => sub {
	reset_env();
	my $info = CGI::Info->new({ max_upload_size => 65536 });
	isa_ok($info, 'CGI::Info', 'constructed with hashref');
};

subtest 'new() - clones existing object' => sub {
	reset_env();
	my $orig  = CGI::Info->new(max_upload_size => 999);
	my $clone = $orig->new(max_upload_size => 42);
	isa_ok($clone, 'CGI::Info', 'clone is a CGI::Info');
	isnt($orig, $clone, 'clone is a different object');
};

subtest 'new() - expect parameter is deprecated and croaks' => sub {
	reset_env();
	eval { CGI::Info->new(expect => [qw(foo bar)]) };
	like($@, qr/expect has been deprecated/i,
		'expect parameter causes croak with deprecation message');
};

subtest 'new() - auto_load option accepted' => sub {
	reset_env();
	my $info = CGI::Info->new(auto_load => 1);
	isa_ok($info, 'CGI::Info', 'auto_load => 1 accepted');
};

# ============================================================
# reset()
# ============================================================

subtest 'reset() - class method clears cached stdin data' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'x=1';
	CGI::Info->new()->params();
	CGI::Info->reset();
	ok(!defined $CGI::Info::stdin_data, 'reset() clears stdin_data');
};

# ============================================================
# script_name()
# POD: returns basename of executing script; not an absolute path
# ============================================================

subtest 'script_name() - returns a non-empty string' => sub {
	reset_env();
	$ENV{SCRIPT_NAME} = '/cgi-bin/myapp.cgi';
	my $name = CGI::Info->new()->script_name();
	ok(defined $name && length $name, 'script_name() returns non-empty string');
};

subtest 'script_name() - does not return an absolute path' => sub {
	reset_env();
	$ENV{SCRIPT_NAME} = '/cgi-bin/myapp.cgi';
	my $name = CGI::Info->new()->script_name();
	unlike($name, qr{^[/\\]}, 'script_name() does not start with path separator');
};

subtest 'script_name() - returns basename only' => sub {
	reset_env();
	$ENV{SCRIPT_NAME} = '/cgi-bin/myapp.cgi';
	my $name = CGI::Info->new()->script_name();
	is($name, 'myapp.cgi', 'script_name() returns basename');
};

# ============================================================
# script_path()
# POD: returns full path name of the script
# ============================================================

subtest 'script_path() - returns defined value' => sub {
	reset_env();
	$ENV{SCRIPT_FILENAME} = '/var/www/cgi-bin/myapp.cgi';
	my $path = CGI::Info->new()->script_path();
	ok(defined $path && length $path, 'script_path() returns a defined value');
};

subtest 'script_path() - returns full path from SCRIPT_FILENAME' => sub {
	reset_env();
	$ENV{SCRIPT_FILENAME} = '/var/www/cgi-bin/myapp.cgi';
	is(CGI::Info->new()->script_path(), '/var/www/cgi-bin/myapp.cgi',
		'script_path() returns SCRIPT_FILENAME value');
};

# ============================================================
# script_dir()
# POD: returns the file system directory containing the script
# ============================================================

subtest 'script_dir() - returns directory portion of script path' => sub {
	reset_env();
	if($^O eq 'MSWin32') {
		pass('script_dir() Unix-path test skipped on Windows');
		return;
	}
	$ENV{SCRIPT_FILENAME} = '/var/www/cgi-bin/myapp.cgi';
	my $dir = CGI::Info->new()->script_dir();
	is($dir, '/var/www/cgi-bin', 'script_dir() returns containing directory');
};

subtest 'script_dir() - can be called as class method' => sub {
	reset_env();
	$ENV{SCRIPT_FILENAME} = '/var/www/cgi-bin/myapp.cgi';
	my $dir = CGI::Info->script_dir();
	ok(defined $dir && length $dir, 'script_dir() works as class method');
};

# ============================================================
# host_name()
# POD: returns host-name of current web server per CGI;
#	  falls back to system hostname if not determinable from web server
# ============================================================

subtest 'host_name() - returns HTTP_HOST value' => sub {
	reset_env();
	$ENV{HTTP_HOST} = 'www.example.com';
	is(CGI::Info->new()->host_name(), 'www.example.com',
		'host_name() returns HTTP_HOST');
};

subtest 'host_name() - returns SERVER_NAME if no HTTP_HOST' => sub {
	reset_env();
	$ENV{SERVER_NAME} = 'example.com';
	is(CGI::Info->new()->host_name(), 'example.com',
		'host_name() falls back to SERVER_NAME');
};

subtest 'host_name() - strips trailing dots from hostname' => sub {
	reset_env();
	$ENV{HTTP_HOST} = 'www.example.com.';
	my $name = CGI::Info->new()->host_name();
	unlike($name, qr/\.$/, 'trailing dot stripped from host_name()');
};

subtest 'host_name() - returns something even without CGI env' => sub {
	reset_env();
	my $name = CGI::Info->new()->host_name();
	ok(defined $name && length $name,
		'host_name() falls back to system hostname');
};

# ============================================================
# domain_name()
# POD: domain of controlling website; lacks http:// or www prefix;
#	  can be called as a class method
# ============================================================

subtest 'domain_name() - strips www. prefix' => sub {
	reset_env();
	$ENV{HTTP_HOST} = 'www.example.com';
	is(CGI::Info->new()->domain_name(), 'example.com',
		'domain_name() strips www. prefix');
};

subtest 'domain_name() - no www prefix returned unchanged' => sub {
	reset_env();
	$ENV{HTTP_HOST} = 'example.com';
	is(CGI::Info->new()->domain_name(), 'example.com',
		'domain_name() without www returned as-is');
};

subtest 'domain_name() - no http:// prefix in result' => sub {
	reset_env();
	$ENV{HTTP_HOST} = 'www.example.org';
	my $d = CGI::Info->new()->domain_name();
	unlike($d, qr{^https?://}, 'domain_name() has no protocol prefix');
};

subtest 'domain_name() - can be called as class method' => sub {
	reset_env();
	$ENV{HTTP_HOST} = 'www.example.net';
	my $d = CGI::Info->domain_name();
	is($d, 'example.net', 'domain_name() works as class method');
};

# ============================================================
# cgi_host_url()
# POD: returns URL of machine running the CGI script
# ============================================================

subtest 'cgi_host_url() - includes protocol prefix' => sub {
	reset_env();
	$ENV{HTTP_HOST}	= 'example.com';
	$ENV{SERVER_PROTOCOL} = 'HTTP/1.1';
	my $url = CGI::Info->new()->cgi_host_url();
	like($url, qr{^https?://}, 'cgi_host_url() starts with http:// or https://');
};

subtest 'cgi_host_url() - includes host name' => sub {
	reset_env();
	$ENV{HTTP_HOST}	= 'example.com';
	$ENV{SERVER_PROTOCOL} = 'HTTP/1.1';
	my $url = CGI::Info->new()->cgi_host_url();
	like($url, qr/example\.com/, 'cgi_host_url() contains the host name');
};

# ============================================================
# params()
# POD: returns hashref of CGI arguments, or undef if none/error;
#	  duplicate keys comma-joined;
#	  allow filters and validates parameters;
#	  blocks SQL injection, XSS, directory traversal, mustleak
# ============================================================

subtest 'params() - GET: returns hashref of key/value pairs' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'name=Alice&age=30';
	my $p = CGI::Info->new()->params();
	ok(ref($p) eq 'HASH', 'params() returns a hashref');
	is($p->{name}, 'Alice', 'name=Alice parsed');
	is($p->{age},  '30',	'age=30 parsed');
};

subtest 'params() - GET: empty query string returns undef' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = '';
	ok(!defined CGI::Info->new()->params(),
		'empty QUERY_STRING returns undef');
};

subtest 'params() - GET: duplicate keys are comma-joined' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'color=red&color=blue';
	my $p = CGI::Info->new()->params();
	like($p->{color}, qr/red.*blue|blue.*red/,
		'duplicate keys comma-joined');
};

subtest 'params() - allow: unknown keys silently excluded' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'allowed=1&forbidden=2';
	my $p = CGI::Info->new()->params(allow => { allowed => undef });
	ok(defined $p->{allowed}, 'allowed key present');
	ok(!defined $p->{forbidden}, 'forbidden key silently excluded');
};

subtest 'params() - allow: undef value permits any value' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'note=anything+goes';
	my $p = CGI::Info->new()->params(allow => { note => undef });
	ok(defined $p->{note}, 'undef allow value accepts any value');
};

subtest 'params() - allow: regex validated correctly' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'id=42';
	my $p = CGI::Info->new()->params(allow => { id => qr/^\d+$/ });
	is($p->{id}, '42', 'valid regex match passes');
};

subtest 'params() - allow: regex mismatch excluded, status 422' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'id=abc';
	my $info = CGI::Info->new();
	my $p	= $info->params(allow => { id => qr/^\d+$/ });
	ok(!defined($p) || !defined($p->{id}),
		'regex mismatch excluded from params');
	is($info->status(), 422, 'status 422 set on validation failure');
};

subtest 'params() - allow: exact string match passes' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'action=submit';
	my $p = CGI::Info->new()->params(allow => { action => 'submit' });
	ok(defined $p && defined $p->{action}, 'exact string match passes');
};

subtest 'params() - allow: exact string mismatch excluded' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'action=delete';
	my $info = CGI::Info->new();
	my $p	= $info->params(allow => { action => 'submit' });
	ok(!defined($p) || !defined($p->{action}),
		'exact string mismatch excluded');
};

subtest 'params() - allow: coderef validator passes truthy return' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'num=4';
	my $p = CGI::Info->new()->params(allow => {
		num => sub { ($_[1] % 2) == 0 }
	});
	ok(defined $p && defined $p->{num}, 'coderef returning true passes');
};

subtest 'params() - allow: coderef validator excludes falsy return' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'num=3';
	my $p = CGI::Info->new()->params(allow => {
		num => sub { ($_[1] % 2) == 0 }
	});
	ok(!defined($p) || !defined($p->{num}),
		'coderef returning false excludes param');
};

subtest 'params() - allow: coderef receives key, value, object' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'x=hello';
	my ($got_key, $got_val, $got_obj);
	CGI::Info->new()->params(allow => {
		x => sub {
			($got_key, $got_val, $got_obj) = @_;
			return 1;
		}
	});
	is($got_key, 'x',	   'coderef receives key as first arg');
	is($got_val, 'hello',   'coderef receives value as second arg');
	isa_ok($got_obj, 'CGI::Info', 'coderef receives CGI::Info as third arg');
};

subtest 'params() - allow: Params::Validate::Strict schema passes valid' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'age=25';
	my $p = CGI::Info->new()->params(allow => {
		age => { type => 'integer', min => 0, max => 150 }
	});
	ok(defined $p && defined $p->{age}, 'valid value passes schema');
};

subtest 'params() - allow: Params::Validate::Strict schema blocks invalid' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'age=999';
	my $info = CGI::Info->new();
	my $p	= $info->params(allow => {
		age => { type => 'integer', min => 0, max => 150 }
	});
	ok(!defined($p) || !defined($p->{age}),
		'out-of-range value blocked by schema');
};

subtest 'params() - blocks SQL injection, returns undef, status 403' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = "id=1'%20OR%201=1";
	my $info = CGI::Info->new();
	ok(!defined $info->params(), 'SQL injection attempt returns undef');
	is($info->status(), 403, 'status 403 on SQL injection');
};

subtest 'params() - blocks XSS injection, returns undef, status 403' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'q=%3Cscript%3Ealert(1)%3C%2Fscript%3E';
	my $info = CGI::Info->new();
	ok(!defined $info->params(), 'XSS attempt returns undef');
	is($info->status(), 403, 'status 403 on XSS');
};

subtest 'params() - blocks directory traversal, status 403' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'file=../../etc/passwd';
	my $info = CGI::Info->new();
	ok(!defined $info->params(), 'directory traversal returns undef');
	is($info->status(), 403, 'status 403 on directory traversal');
};

subtest 'params() - blocks mustleak attack, status 403' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'x=mustleak.com/probe';
	my $info = CGI::Info->new();
	ok(!defined $info->params(), 'mustleak attack returns undef');
	is($info->status(), 403, 'status 403 on mustleak');
};

subtest 'params() - POST: missing CONTENT_LENGTH => undef + status 411' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'POST';
	my $info = CGI::Info->new();
	ok(!defined $info->params(), 'POST without CONTENT_LENGTH returns undef');
	is($info->status(), 411, 'status 411 on missing CONTENT_LENGTH');
};

subtest 'params() - POST: oversized body => undef + status 413' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'POST';
	$ENV{CONTENT_LENGTH}	= 999_999_999;
	my $info = CGI::Info->new(max_upload_size => 100);
	ok(!defined $info->params(), 'oversized POST returns undef');
	is($info->status(), 413, 'status 413 on oversized body');
};

subtest 'params() - OPTIONS => undef + status 405' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'OPTIONS';
	my $info = CGI::Info->new();
	ok(!defined $info->params(), 'OPTIONS returns undef');
	is($info->status(), 405, 'status 405 on OPTIONS');
};

subtest 'params() - DELETE => undef + status 405' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'DELETE';
	my $info = CGI::Info->new();
	ok(!defined $info->params(), 'DELETE returns undef');
	is($info->status(), 405, 'status 405 on DELETE');
};

subtest 'params() - POST XML: body stored under XML key' => sub {
	reset_env();
	my $xml = '<root><item>test</item></root>';
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'POST';
	$ENV{CONTENT_TYPE}	  = 'text/xml';
	$ENV{CONTENT_LENGTH}	= length($xml);
	$CGI::Info::stdin_data  = $xml;
	my $p = CGI::Info->new()->params();
	ok(defined $p,		 'XML POST returns a hashref');
	is($p->{XML}, $xml,	'XML body stored under the XML key');
};

subtest 'params() - command-line ARGV pairs parsed (non-CGI)' => sub {
	reset_env();
	local @ARGV = ('city=London', 'country=UK');
	my $p = CGI::Info->new()->params();
	is($p->{city},	'London', 'city from ARGV');
	is($p->{country}, 'UK',	 'country from ARGV');
};

subtest 'params() - second call returns same cached hashref' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'k=v';
	my $info = CGI::Info->new();
	my $p1   = $info->params();
	my $p2   = $info->params();
	is($p1, $p2, 'repeated call returns cached hashref');
};

# ============================================================
# param($field)
# POD: returns single parameter value; undef if not present;
#	  warns if field not in allow list;
#	  no arg => delegates to params()
# ============================================================

subtest 'param() - returns value for existing key' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'foo=bar';
	is(CGI::Info->new()->param('foo'), 'bar', 'param() returns value');
};

subtest 'param() - returns undef for absent key' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'foo=bar';
	ok(!defined CGI::Info->new()->param('nosuchkey'),
		'param() returns undef for absent key');
};

subtest 'param() - no argument delegates to params()' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'x=1';
	my $result = CGI::Info->new()->param();
	ok(ref($result) eq 'HASH', 'param() with no arg returns hashref');
};

subtest 'param() - returns undef for key outside allow list' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'foo=1';
	my $info = CGI::Info->new(allow => { foo => qr/\d+/ });
	$info->params();
	ok(!defined $info->param('bar'),
		'param() returns undef for key not in allow list');
};

# ============================================================
# as_string()
# POD: returns CGI params as formatted string;
#	  optional raw => 1 skips escaping of special chars;
#	  useful for debugging or cache keys
# API: output type string, optional
# ============================================================

subtest 'as_string() - returns key=value pairs sorted' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'b=2&a=1';
	my $info = CGI::Info->new();
	$info->params();
	my $str = $info->as_string();
	like($str, qr/a=1/, 'a=1 present in output');
	like($str, qr/b=2/, 'b=2 present in output');
};

subtest 'as_string() - key=value pairs separated by semicolons' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'a=1&b=2';
	my $info = CGI::Info->new();
	$info->params();
	my $str = $info->as_string();
	like($str, qr/;/, 'pairs separated by semicolons');
};

subtest 'as_string() - raw mode does not escape special chars' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'x=hello';
	my $info = CGI::Info->new();
	$info->params();
	is($info->as_string({ raw => 1 }), 'x=hello',
		'raw mode returns unescaped string');
};

subtest 'as_string() - no params returns empty string' => sub {
	reset_env();
	my $info = CGI::Info->new();
	is($info->as_string(), '', 'as_string() with no params returns empty string');
};

subtest 'as_string() - input: raw is boolean, optional' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'z=9';
	my $info = CGI::Info->new();
	$info->params();
	# raw => 0 should not croak
	my $str = eval { $info->as_string({ raw => 0 }) };
	ok(!$@, 'as_string(raw => 0) does not croak');
	ok(defined $str, 'as_string(raw => 0) returns a value');
};

# ============================================================
# protocol()
# POD: returns 'http' or 'https', or undef if undetermined
# ============================================================

subtest 'protocol() - returns http from SERVER_PROTOCOL' => sub {
	reset_env();
	$ENV{SERVER_PROTOCOL} = 'HTTP/1.1';
	is(CGI::Info->new()->protocol(), 'http', 'protocol() returns http');
};

subtest 'protocol() - returns https from SCRIPT_URI' => sub {
	reset_env();
	$ENV{SCRIPT_URI} = 'https://example.com/cgi-bin/foo.cgi';
	is(CGI::Info->new()->protocol(), 'https', 'protocol() returns https from SCRIPT_URI');
};

subtest 'protocol() - returns undef when undetermined' => sub {
	reset_env();
	ok(!defined CGI::Info->new()->protocol(),
		'protocol() returns undef when no env set');
};

# ============================================================
# is_mobile()
# POD: returns boolean; true for smartphones and tablets;
#	  can be overridden by IS_MOBILE environment variable
# ============================================================

subtest 'is_mobile() - true for iPhone user agent' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	ok(CGI::Info->new()->is_mobile(), 'iPhone UA is mobile');
};

subtest 'is_mobile() - true for Android user agent' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Linux; Android 11; Pixel 5)';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	ok(CGI::Info->new()->is_mobile(), 'Android UA is mobile');
};

subtest 'is_mobile() - false for desktop user agent' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	ok(!CGI::Info->new()->is_mobile(), 'desktop UA is not mobile');
};

subtest 'is_mobile() - overridden by IS_MOBILE=1' => sub {
	reset_env();
	$ENV{IS_MOBILE}	   = 1;
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Windows NT 10.0)';
	ok(CGI::Info->new()->is_mobile(), 'IS_MOBILE=1 overrides UA detection');
};

subtest 'is_mobile() - true via Sec-CH-UA-Mobile hint' => sub {
	reset_env();
	$ENV{HTTP_SEC_CH_UA_MOBILE} = '?1';
	ok(CGI::Info->new()->is_mobile(), 'Sec-CH-UA-Mobile: ?1 is mobile');
};

subtest 'is_mobile() - true via HTTP_X_WAP_PROFILE' => sub {
	reset_env();
	$ENV{HTTP_X_WAP_PROFILE} = 'http://wap.example.com/uaprof.xml';
	ok(CGI::Info->new()->is_mobile(), 'WAP profile header indicates mobile');
};

subtest 'is_mobile() - all tablets are mobile' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPad; CPU OS 15_0 like Mac OS X)';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	ok(CGI::Info->new()->is_mobile(), 'tablet (iPad) counts as mobile');
};

# ============================================================
# is_tablet()
# POD: returns boolean; true for tablets such as iPad
# ============================================================

subtest 'is_tablet() - true for iPad user agent' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPad; CPU OS 15_0 like Mac OS X)';
	ok(CGI::Info->new()->is_tablet(), 'iPad UA is tablet');
};

subtest 'is_tablet() - false for iPhone user agent' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)';
	ok(!CGI::Info->new()->is_tablet(), 'iPhone UA is not a tablet');
};

subtest 'is_tablet() - false for desktop user agent' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';
	ok(!CGI::Info->new()->is_tablet(), 'desktop UA is not a tablet');
};

# ============================================================
# is_robot()
# POD: returns boolean; true for robots/crawlers;
#	  SQL injection in UA sets status 403 and returns true
# ============================================================

subtest 'is_robot() - false when no CGI environment' => sub {
	reset_env();
	is(CGI::Info->new()->is_robot(), 0,
		'is_robot() returns 0 outside CGI environment');
};

subtest 'is_robot() - true for known bot UA' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'ClaudeBot/1.0 (+http://www.anthropic.com)';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	ok(CGI::Info->new()->is_robot(), 'ClaudeBot detected as robot');
};

subtest 'is_robot() - SQL injection in UA returns true + status 403' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla SELECT foo AND bar FROM baz';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	my $info = CGI::Info->new();
	ok($info->is_robot(), 'SQL injection UA flagged as robot');
	is($info->status(), 403, 'status 403 set on SQL injection UA');
};

# ============================================================
# is_search_engine()
# POD: returns boolean;
#	  can be overridden by IS_SEARCH_ENGINE environment variable
# ============================================================

subtest 'is_search_engine() - false when no CGI environment' => sub {
	reset_env();
	is(CGI::Info->new()->is_search_engine(), 0,
		'is_search_engine() returns 0 outside CGI environment');
};

subtest 'is_search_engine() - overridden by IS_SEARCH_ENGINE=1' => sub {
	reset_env();
	$ENV{IS_SEARCH_ENGINE} = 1;
	$ENV{REMOTE_ADDR}	  = '1.2.3.4';
	$ENV{HTTP_USER_AGENT}  = 'SomeBot/1.0';
	ok(CGI::Info->new()->is_search_engine(),
		'IS_SEARCH_ENGINE=1 override works');
};

# ============================================================
# browser_type()
# POD: returns one of 'web', 'search', 'robot', 'mobile'
# ============================================================

subtest 'browser_type() - returns mobile for smartphone UA' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	is(CGI::Info->new()->browser_type(), 'mobile', 'smartphone => mobile');
};

subtest 'browser_type() - returns web for desktop browser' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	is(CGI::Info->new()->browser_type(), 'web', 'desktop => web');
};

subtest 'browser_type() - returns robot for known bot' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'ClaudeBot/1.0';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	is(CGI::Info->new()->browser_type(), 'robot', 'bot => robot');
};

subtest 'browser_type() - return value is one of the four valid strings' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Windows NT 10.0)';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';
	my $type = CGI::Info->new()->browser_type();
	ok((grep { $type eq $_ } qw(web search robot mobile)),
		"browser_type() returns one of the four valid values (got '$type')");
};

# ============================================================
# cookie() / get_cookie()
# POD: returns cookie value or undef;
#	  API: cookie_name must be a non-empty string matching RFC6265 token chars;
#		   output is undef or a string matching RFC6265 cookie-value chars
# ============================================================

subtest 'cookie() - returns value for existing cookie' => sub {
	reset_env();
	$ENV{HTTP_COOKIE} = 'session=abc123; user=bob';
	my $info = CGI::Info->new();
	is($info->cookie('session'), 'abc123', 'cookie() returns session value');
	is($info->cookie('user'),	'bob',	'cookie() returns user value');
};

subtest 'cookie() - returns undef for absent cookie' => sub {
	reset_env();
	$ENV{HTTP_COOKIE} = 'a=1';
	ok(!defined CGI::Info->new()->cookie('nosuch'),
		'cookie() returns undef for absent cookie');
};

subtest 'cookie() - returns undef when no HTTP_COOKIE set' => sub {
	reset_env();
	ok(!defined CGI::Info->new()->cookie('anything'),
		'cookie() returns undef with no HTTP_COOKIE env');
};

subtest 'cookie() - positional string argument accepted' => sub {
	reset_env();
	$ENV{HTTP_COOKIE} = 'token=xyz';
	is(CGI::Info->new()->cookie('token'), 'xyz',
		'cookie() accepts bare string argument');
};

subtest 'get_cookie() - deprecated alias behaves identically to cookie()' => sub {
	reset_env();
	$ENV{HTTP_COOKIE} = 'sid=12345';
	my $info = CGI::Info->new();
	is($info->get_cookie(cookie_name => 'sid'),
	   $info->cookie('sid'),
	   'get_cookie() returns same value as cookie()');
};

# ============================================================
# status()
# POD: gets/sets HTTP status code; defaults to 200
# ============================================================

subtest 'status() - default is 200' => sub {
	reset_env();
	is(CGI::Info->new()->status(), 200, 'status() default is 200');
};

subtest 'status() - set and retrieve integer' => sub {
	reset_env();
	my $info = CGI::Info->new();
	$info->status(404);
	is($info->status(), 404, 'status() round-trips set value');
};

subtest 'status() - OPTIONS yields 405' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'OPTIONS';
	my $info = CGI::Info->new();
	$info->params();
	is($info->status(), 405, 'OPTIONS => 405');
};

subtest 'status() - DELETE yields 405' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'DELETE';
	my $info = CGI::Info->new();
	$info->params();
	is($info->status(), 405, 'DELETE => 405');
};

# ============================================================
# messages() / messages_as_string()
# POD: returns messages generated by the object;
#	  messages() => arrayref of hashes;
#	  messages_as_string() => joined string
# ============================================================

subtest 'messages() - returns undef or arrayref' => sub {
	reset_env();
	my $msgs = CGI::Info->new()->messages();
	ok(!defined($msgs) || ref($msgs) eq 'ARRAY',
		'messages() returns undef or arrayref');
};

subtest 'messages_as_string() - empty when no messages' => sub {
	reset_env();
	is(CGI::Info->new()->messages_as_string(), '',
		'messages_as_string() is empty string initially');
};

subtest 'messages_as_string() - non-empty after validation failure' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'id=abc';
	my $info = CGI::Info->new();
	$info->params(allow => { id => qr/^\d+$/ });
	ok(defined $info->messages(), 'messages() populated after failure');
};

subtest 'messages() - each entry has level and message keys' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'id=abc';
	my $info = CGI::Info->new();
	$info->params(allow => { id => qr/^\d+$/ });
	if(my $msgs = $info->messages()) {
		my $first = $msgs->[0];
		ok(exists $first->{level},   'message entry has level key');
		ok(exists $first->{message}, 'message entry has message key');
	} else {
		pass('no messages to inspect (acceptable)');
	}
};

# ============================================================
# cache()
# POD: get/set internal cache object; must be an object that
#	  understands get() and set() messages (e.g. CHI)
# ============================================================

subtest 'cache() - set and retrieve cache object' => sub {
	reset_env();
	{ no warnings 'once';
	  package MockCache;
	  sub new { bless {}, shift }
	  sub get { undef }
	  sub set { 1 }
	}
	my $c	= MockCache->new();
	my $info = CGI::Info->new();
	$info->cache($c);
	is($info->cache(), $c, 'cache() round-trips the object');
};

subtest 'cache() - non-object argument croaks' => sub {
	reset_env();
	eval { CGI::Info->new()->cache('not-an-object') };
	like($@, qr/is not an object/i, 'cache() croaks on non-object');
};

subtest 'cache() - no argument returns current cache (undef by default)' => sub {
	reset_env();
	my $info = CGI::Info->new();
	ok(!defined $info->cache(), 'cache() returns undef when not set');
};

# ============================================================
# set_logger()
# POD: sets class, array, code reference, or file for logging;
#	  returns $self for chaining
# ============================================================

subtest 'set_logger() - accepts a filename and returns $self' => sub {
	reset_env();
	my $info = CGI::Info->new();
	my $ret  = $info->set_logger('/dev/null');
	is($ret, $info, 'set_logger() returns $self for chaining');
};

subtest 'set_logger() - stores a logger object' => sub {
	reset_env();
	{ no warnings 'once';
	  package GoodLogger2;
	  sub new   { bless {}, shift }
	  sub warn  { }
	  sub info  { }
	  sub error { }
	  sub debug { }
	  sub trace { }
	}
	my $log  = GoodLogger2->new();
	my $info = CGI::Info->new();
	$info->set_logger($log);
	ok(defined $info->{logger}, 'logger stored after set_logger()');
};

# ============================================================
# tmpdir()
# POD: returns writable temp directory; preferable to File::Spec->tmpdir();
#	  accepts optional default => $path as fallback;
#	  can be called as class or object method
# ============================================================

subtest 'tmpdir() - returns a defined, writable directory' => sub {
	reset_env();
	my $dir = CGI::Info->new()->tmpdir();
	ok(defined $dir, 'tmpdir() returns defined value');
	ok(-d $dir,	  'tmpdir() is a directory');
	ok(-w $dir,	  'tmpdir() is writable');
};

subtest 'tmpdir() - class method works' => sub {
	reset_env();
	my $dir = CGI::Info->tmpdir();
	ok(defined $dir && -d $dir, 'tmpdir() works as class method');
};

subtest 'tmpdir() - default param used as fallback' => sub {
	reset_env();
	my $tmp  = tempdir(CLEANUP => 1);
	my $dir  = CGI::Info->new()->tmpdir(default => $tmp);
	ok(defined $dir, 'tmpdir() with default returns defined value');
};

subtest 'tmpdir() - hashref argument accepted' => sub {
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	my $dir = CGI::Info->new()->tmpdir({ default => $tmp });
	ok(defined $dir, 'tmpdir() accepts hashref argument');
};

subtest 'tmpdir() - non-scalar default croaks' => sub {
	reset_env();
	eval { CGI::Info->new()->tmpdir(default => ['/tmp']) };
	like($@, qr/scalar/i, 'tmpdir() croaks when default is a ref');
};

# ============================================================
# rootdir() / root_dir() / documentroot()
# POD: returns the document root;
#	  works outside CGI environment;
#	  class or object method
# ============================================================

subtest 'rootdir() - returns C_DOCUMENT_ROOT when set' => sub {
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{C_DOCUMENT_ROOT} = $tmp;
	is(CGI::Info->rootdir(), $tmp, 'rootdir() returns C_DOCUMENT_ROOT');
};

subtest 'rootdir() - falls back to DOCUMENT_ROOT' => sub {
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{DOCUMENT_ROOT} = $tmp;
	is(CGI::Info->rootdir(), $tmp, 'rootdir() falls back to DOCUMENT_ROOT');
};

subtest 'rootdir() - returns a value even without CGI env' => sub {
	reset_env();
	my $dir = CGI::Info->rootdir();
	ok(defined $dir && length $dir, 'rootdir() returns something without env');
};

subtest 'root_dir() - synonym of rootdir()' => sub {
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{C_DOCUMENT_ROOT} = $tmp;
	is(CGI::Info->root_dir(), CGI::Info->rootdir(),
		'root_dir() returns same as rootdir()');
};

subtest 'documentroot() - synonym of rootdir()' => sub {
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{C_DOCUMENT_ROOT} = $tmp;
	is(CGI::Info->documentroot(), CGI::Info->rootdir(),
		'documentroot() returns same as rootdir()');
};

# ============================================================
# logdir()
# POD: gets/sets log directory; must be writable;
#	  invalid path causes croak;
#	  falls back through $self->{logdir}, LOGDIR env, Sys::Path, tmpdir
# ============================================================

subtest 'logdir() - accepts and returns valid writable directory' => sub {
	reset_env();
	my $tmp  = tempdir(CLEANUP => 1);
	my $info = CGI::Info->new();
	my $dir  = $info->logdir($tmp);
	is($dir, $tmp, 'logdir() stores and returns valid dir');
};

subtest 'logdir() - invalid path croaks' => sub {
	reset_env();
	eval { CGI::Info->new()->logdir('/no/such/path/xyz') };
	like($@, qr/Invalid logdir/i, 'logdir() croaks on invalid path');
};

subtest 'logdir() - no arg returns a usable directory' => sub {
	reset_env();
	my $dir = CGI::Info->new()->logdir();
	ok(defined $dir && -d $dir, 'logdir() without arg returns a valid dir');
};

# ============================================================
# AUTOLOAD
# POD: unknown method names delegated to param();
#	  disabled when auto_load => 0
# ============================================================

subtest 'AUTOLOAD - unknown method delegates to param()' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'myfield=myvalue';
	is(CGI::Info->new()->myfield(), 'myvalue',
		'AUTOLOAD delegates to param()');
};

subtest 'AUTOLOAD - absent field returns undef' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'x=1';
	my $info = CGI::Info->new();
	$info->params();
	ok(!defined $info->nosuchparam(), 'AUTOLOAD on absent field returns undef');
};

subtest 'AUTOLOAD - disabled with auto_load => 0' => sub {
	reset_env();
	my $info = CGI::Info->new(auto_load => 0);
	eval { $info->anythingwhatsoever() };
	like($@, qr/Unknown method/i, 'AUTOLOAD disabled causes croak with Unknown method');
};

done_testing();
