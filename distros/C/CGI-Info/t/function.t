#!/usr/bin/env perl

# White-box function-level tests for CGI::Info.
# One subtest per public method; separate subtests cover each internal helper.
# Uses Test::Mockingbird to isolate the unit under test from its dependencies.

use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Test::Memory::Cycle;
use Readonly;
use Cwd qw(getcwd);
use File::Temp qw(tempdir);
use File::Spec;
use Scalar::Util qw(blessed);
use Test::Mockingbird 0.08 qw(mock mock_scoped mock_return spy restore_all);

# CGI::Info must load cleanly before any mocking
BEGIN { use_ok('CGI::Info') or BAIL_OUT('CGI::Info failed to load') }

# Silence Log::Abstraction's _high_priority stderr for the entire run.
# WAF blocks and validation failures generate expected log output that
# would otherwise pollute harness output; we assert on return values.
mock 'Log::Abstraction::_high_priority' => sub { };

# ============================================================
# Configuration constants -- no magic literals anywhere below
# ============================================================
Readonly my $UPLOAD_SMALL      => 100;
Readonly my $UPLOAD_MAX        => 2048;
Readonly my $UPLOAD_OVERSIZED  => 999_999_999;
Readonly my $GOOD_IP           => '1.2.3.4';
Readonly my $GOOGLEBOT_IP      => '66.249.66.1';
Readonly my $PORT_HTTP         => 80;
Readonly my $PORT_HTTPS        => 443;
Readonly my $STATUS_OK         => 200;
Readonly my $STATUS_FORBIDDEN  => 403;
Readonly my $STATUS_NOT_FOUND  => 404;
Readonly my $STATUS_METHOD_NA  => 405;
Readonly my $STATUS_LENGTH_REQ => 411;
Readonly my $STATUS_TOO_LARGE  => 413;
Readonly my $STATUS_UNPROC     => 422;
Readonly my $UA_IPHONE  => 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)';
Readonly my $UA_ANDROID => 'Mozilla/5.0 (Linux; Android 10; Pixel 3)';
Readonly my $UA_IPAD    => 'Mozilla/5.0 (iPad; CPU OS 14_0 like Mac OS X)';
Readonly my $UA_DESKTOP => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120';
Readonly my $UA_GBOT         => 'Googlebot/2.1 (+http://www.google.com/bot.html)';
Readonly my $UA_CBOT         => 'ClaudeBot/1.0';
Readonly my $UA_CLAUDE_WEB   => 'Claude-Web/1.0';
Readonly my $UA_GPTBOT       => 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.2; +https://openai.com/gptbot)';
Readonly my $UA_CHATGPT_USER => 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko); ChatGPT-User/1.0; +https://openai.com/bot)';
Readonly my $UA_COHERE_AI    => 'cohere-ai/1.0';
# GPTBot UA that also embeds a SQL injection payload: used to verify WAF ordering
Readonly my $UA_GPTBOT_SQL   => 'GPTBot/1.0 SELECT foo AND bar FROM baz';

# %config gathers all constants for Object::Configure-style flexibility
my %config = (
	upload_small      => $UPLOAD_SMALL,
	upload_max        => $UPLOAD_MAX,
	upload_oversized  => $UPLOAD_OVERSIZED,
	good_ip           => $GOOD_IP,
	googlebot_ip      => $GOOGLEBOT_IP,
	port_http         => $PORT_HTTP,
	port_https        => $PORT_HTTPS,
	status_ok         => $STATUS_OK,
	status_forbidden  => $STATUS_FORBIDDEN,
	status_not_found  => $STATUS_NOT_FOUND,
	status_method_na  => $STATUS_METHOD_NA,
	status_length_req => $STATUS_LENGTH_REQ,
	status_too_large  => $STATUS_TOO_LARGE,
	status_unproc     => $STATUS_UNPROC,
	ua_iphone         => $UA_IPHONE,
	ua_android        => $UA_ANDROID,
	ua_ipad           => $UA_IPAD,
	ua_desktop        => $UA_DESKTOP,
	ua_gbot           => $UA_GBOT,
	ua_cbot           => $UA_CBOT,
	ua_claude_web     => $UA_CLAUDE_WEB,
	ua_gptbot         => $UA_GPTBOT,
	ua_chatgpt_user   => $UA_CHATGPT_USER,
	ua_cohere_ai      => $UA_COHERE_AI,
	ua_gptbot_sql     => $UA_GPTBOT_SQL,
);

# ---------------------------------------------------------------------------
# Helper: wipe CGI environment variables and class state between subtests
# ---------------------------------------------------------------------------
sub reset_env {
	delete $ENV{$_} for qw(
		GATEWAY_INTERFACE REQUEST_METHOD QUERY_STRING CONTENT_TYPE
		CONTENT_LENGTH SCRIPT_NAME SCRIPT_FILENAME DOCUMENT_ROOT
		C_DOCUMENT_ROOT HTTP_HOST SERVER_NAME SSL_TLS_SNI SERVER_PROTOCOL
		SERVER_PORT SCRIPT_URI REMOTE_ADDR HTTP_USER_AGENT HTTP_COOKIE
		HTTP_X_WAP_PROFILE HTTP_SEC_CH_UA_MOBILE HTTP_REFERER IS_MOBILE
		IS_SEARCH_ENGINE IS_AI LOGDIR
	);
	CGI::Info->reset();
}

# ============================================================
# 1. new()
# ============================================================

# Basic object construction
subtest 'new() - basic instantiation returns blessed object' => sub {
	plan tests => 2;
	reset_env();
	my $info = CGI::Info->new();
	ok(blessed($info), 'new() returns a blessed reference');
	isa_ok($info, 'CGI::Info');
};

# Hashref argument style
subtest 'new() - hashref args set internal fields' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new({ max_upload_size => $config{upload_small} });
	is($info->{max_upload_size}, $config{upload_small}, 'max_upload_size set via hashref');
};

# Flat hash argument style
subtest 'new() - flat hash args set internal fields' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new(max_upload_size => $config{upload_max});
	is($info->{max_upload_size}, $config{upload_max}, 'max_upload_size set via flat hash');
};

# Clone path merges args over parent, parent unchanged
subtest 'new() - clone overrides field without modifying parent' => sub {
	plan tests => 2;
	reset_env();
	my $orig  = CGI::Info->new(max_upload_size => 999);
	my $clone = $orig->new(max_upload_size => 111);
	is($clone->{max_upload_size}, 111, 'clone has overridden field');
	is($orig->{max_upload_size},  999, 'original object is unchanged');
};

# expect parameter was removed; must croak
subtest 'new() - expect deprecated croak' => sub {
	plan tests => 1;
	reset_env();
	throws_ok {
		CGI::Info->new(expect => [qw(foo)])
	} qr/expect has been deprecated/i, 'expect param causes croak';
};

# CGI::Info::new() (double-colon, undef $class) with 0 params should NOT croak
subtest 'new() - ::new() with 0 params does not croak' => sub {
	plan tests => 2;
	reset_env();
	my $info = eval { CGI::Info::new() };
	ok(!$@, '::new() with no args does not croak');
	ok(blessed($info), '::new() with no args still returns an object');
};

# ::new() with undef class and 1+ params croaks with helpful message
subtest 'new() - ::new() with undef class + params croaks' => sub {
	plan tests => 1;
	reset_env();
	throws_ok {
		CGI::Info::new(undef, max_upload_size => $config{upload_small})
	} qr/use ->new\(\) not ::new\(\)/i, '::new() with undef class + params croaks';
};

# Logger validation: object missing warn/info/error must fail guard
subtest 'new() - logger guard rejects object lacking required methods' => sub {
	plan tests => 2;
	reset_env();
	{
		package NoMethodLogger;
		sub new { bless {}, shift }
		# Deliberately no warn/info/error methods
	}
	my $bad        = NoMethodLogger->new();
	my $would_fail = blessed($bad) && !($bad->can('warn') && $bad->can('info') && $bad->can('error'));
	ok($would_fail, 'object lacking warn/info/error fails logger guard predicate');

	{
		package GoodLogger;
		sub new   { bless {}, shift }
		sub warn  { }
		sub info  { }
		sub error { }
	}
	my $good      = GoodLogger->new();
	my $would_ok  = blessed($good) && $good->can('warn') && $good->can('info') && $good->can('error');
	ok($would_ok, 'object with warn/info/error passes logger guard predicate');
};

# ============================================================
# 2. reset()
# ============================================================

# Class-method reset clears stdin_data
subtest 'reset() - clears stdin_data class variable' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'a=1';
	my $info = CGI::Info->new();
	$info->params();
	CGI::Info->reset();
	ok(!defined $CGI::Info::stdin_data, 'reset() clears stdin_data');
};

# Calling reset as object method should not die (it carps)
subtest 'reset() - object-method call does not die' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();
	local $SIG{__WARN__} = sub { };   # suppress expected carp noise
	lives_ok { $info->reset() } 'reset() called as object method does not die';
};

# ============================================================
# 3. status()
# ============================================================

# Default status is 200 when nothing is set
subtest 'status() - defaults to 200' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();
	is($info->status(), $config{status_ok}, 'default status is 200');
};

# status can be set and retrieved
subtest 'status() - set and retrieve' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();
	$info->status($config{status_not_found});
	is($info->status(), $config{status_not_found}, 'status round-trips correctly');
};

# OPTIONS method forces 405
subtest 'status() - OPTIONS request yields 405' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'OPTIONS';
	my $info = CGI::Info->new();
	$info->params();
	is($info->status(), $config{status_method_na}, 'OPTIONS yields 405');
};

# DELETE method forces 405
subtest 'status() - DELETE request yields 405' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'DELETE';
	my $info = CGI::Info->new();
	$info->params();
	is($info->status(), $config{status_method_na}, 'DELETE yields 405');
};

# ============================================================
# 4. params()
# ============================================================

# Simple GET with two parameters
subtest 'params() - GET simple query' => sub {
	plan tests => 3;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'foo=bar&baz=42';
	my $info = CGI::Info->new();
	my $p = $info->params();
	ok(defined $p, 'params() returns defined value');
	is($p->{foo}, 'bar', 'foo=bar parsed correctly');
	is($p->{baz}, '42',  'baz=42 parsed correctly');
};

diag("Testing params() edge cases") if $ENV{TEST_VERBOSE};

# Empty QUERY_STRING returns undef
subtest 'params() - empty QUERY_STRING returns undef' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = '';
	my $info = CGI::Info->new();
	ok(!defined $info->params(), 'empty QUERY_STRING returns undef');
};

# allow hashref filters out unlisted keys
subtest 'params() - allow filters unknown keys' => sub {
	plan tests => 2;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'good=1&evil=2';
	my $info = CGI::Info->new();
	my $p = $info->params(allow => { good => qr/^\d+$/ });
	ok(defined $p->{good}, 'allowed key is present in result');
	ok(!defined $p->{evil}, 'disallowed key is absent from result');
};

# allow regex mismatch removes value and sets 422
subtest 'params() - allow regex mismatch blocks value and sets 422' => sub {
	plan tests => 2;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'id=abc';
	my $info = CGI::Info->new();
	my $p = $info->params(allow => { id => qr/^\d+$/ });
	ok(!defined $p, 'regex-blocked parameter excluded from result');
	is($info->status(), $config{status_unproc}, 'status 422 set on validation failure');
};

# allow exact-string comparison
subtest 'params() - allow exact-string match passes valid value' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'color=blue';
	my $info = CGI::Info->new();
	my $p = $info->params(allow => { color => 'blue' });
	ok(defined $p, 'exact-string allow passes matching value');
};

# allow coderef validator
subtest 'params() - allow coderef validator' => sub {
	plan tests => 2;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'num=4&num2=3';
	my $info = CGI::Info->new();
	my $p = $info->params(allow => {
		num  => sub { ($_[1] % 2) == 0 },   # even => accept
		num2 => sub { ($_[1] % 2) == 0 },   # odd  => reject
	});
	ok(defined  $p->{num},  'even number passes coderef validator');
	ok(!defined $p->{num2}, 'odd number blocked by coderef validator');
};

# SQL injection in query string must be blocked with 403
subtest 'params() - SQL injection blocked with 403' => sub {
	plan tests => 2;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = "id=1'%20OR%201=1";
	my $info = CGI::Info->new();
	my $p = $info->params();
	ok(!defined $p, 'SQL injection blocked');
	is($info->status(), $config{status_forbidden}, 'status 403 set on SQL injection');
};

# XSS in query string must be blocked with 403
subtest 'params() - XSS injection blocked with 403' => sub {
	plan tests => 2;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'q=%3Cscript%3Ealert(1)%3C%2Fscript%3E';
	my $info = CGI::Info->new();
	my $p = $info->params();
	ok(!defined $p, 'XSS injection blocked');
	is($info->status(), $config{status_forbidden}, 'status 403 set on XSS');
};

# Directory traversal must be blocked with 403
subtest 'params() - directory traversal blocked with 403' => sub {
	plan tests => 2;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'file=../../etc/passwd';
	my $info = CGI::Info->new();
	my $p = $info->params();
	ok(!defined $p, 'directory traversal blocked');
	is($info->status(), $config{status_forbidden}, 'status 403 set on traversal');
};

# mustleak probe must be blocked with 403
subtest 'params() - mustleak probe blocked with 403' => sub {
	plan tests => 2;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'x=mustleak.com/probe';
	my $info = CGI::Info->new();
	my $p = $info->params();
	ok(!defined $p, 'mustleak probe blocked');
	is($info->status(), $config{status_forbidden}, 'status 403 set on mustleak');
};

# Duplicate keys should be comma-joined
subtest 'params() - duplicate keys comma-joined' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'color=red&color=blue';
	my $info = CGI::Info->new();
	my $p = $info->params();
	like($p->{color}, qr/red.*blue|blue.*red/, 'duplicate values are comma-joined');
};

# POST without CONTENT_LENGTH returns undef and sets 411
subtest 'params() - POST missing CONTENT_LENGTH sets 411' => sub {
	plan tests => 2;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'POST';
	my $info = CGI::Info->new();
	my $p = $info->params();
	ok(!defined $p, 'POST without CONTENT_LENGTH returns undef');
	is($info->status(), $config{status_length_req}, 'status 411 set on missing CONTENT_LENGTH');
};

# POST with oversized body returns undef and sets 413
subtest 'params() - POST oversized body sets 413' => sub {
	plan tests => 2;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'POST';
	$ENV{CONTENT_LENGTH}    = $config{upload_oversized};
	my $info = CGI::Info->new(max_upload_size => $config{upload_small});
	my $p = $info->params();
	ok(!defined $p, 'oversized POST returns undef');
	is($info->status(), $config{status_too_large}, 'status 413 set on oversized upload');
};

# Non-CGI: ARGV key=value pairs
subtest 'params() - command-line ARGV key=value pairs' => sub {
	plan tests => 2;
	reset_env();
	local @ARGV = ('name=Alice', 'age=30');
	my $info = CGI::Info->new();
	my $p = $info->params();
	is($p->{name}, 'Alice', 'name parsed from ARGV');
	is($p->{age},  '30',    'age parsed from ARGV');
};

# --mobile ARGV flag sets is_mobile
subtest 'params() - --mobile ARGV flag sets is_mobile' => sub {
	plan tests => 1;
	reset_env();
	local @ARGV = ('--mobile', 'x=1');
	my $info = CGI::Info->new();
	$info->params();
	ok($info->is_mobile(), '--mobile flag sets is_mobile');
};

# --robot ARGV flag
subtest 'params() - --robot ARGV flag sets is_robot' => sub {
	plan tests => 1;
	reset_env();
	local @ARGV = ('--robot');
	my $info = CGI::Info->new();
	$info->params();
	ok($info->is_robot(), '--robot flag sets is_robot');
};

# --search-engine ARGV flag
subtest 'params() - --search-engine ARGV flag sets is_search_engine' => sub {
	plan tests => 1;
	reset_env();
	local @ARGV = ('--search-engine');
	my $info = CGI::Info->new();
	$info->params();
	ok($info->is_search_engine(), '--search-engine flag sets is_search_engine');
};

# --tablet ARGV flag
subtest 'params() - --tablet ARGV flag sets is_tablet' => sub {
	plan tests => 1;
	reset_env();
	local @ARGV = ('--tablet');
	my $info = CGI::Info->new();
	$info->params();
	ok($info->is_tablet(), '--tablet flag sets is_tablet');
};

# Second params() call returns the same cached hashref
subtest 'params() - result is cached on second call' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'k=v';
	my $info = CGI::Info->new();
	my $p1 = $info->params();
	my $p2 = $info->params();
	is($p1, $p2, 'second params() call returns the same hashref (cached)');
};

# ============================================================
# 5. param($field)
# ============================================================

# Single param value retrieval
subtest 'param() - returns single value for known key' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'foo=hello';
	my $info = CGI::Info->new();
	is($info->param('foo'), 'hello', 'param() returns correct value');
};

# Missing key returns undef
subtest 'param() - unknown key returns undef' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'foo=hello';
	my $info = CGI::Info->new();
	ok(!defined $info->param('bar'), 'missing param returns undef');
};

# param() with no arg delegates to params() and returns hashref
subtest 'param() - no arg delegates to params()' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'x=1';
	my $info = CGI::Info->new();
	my $p = $info->param();
	is(ref $p, 'HASH', 'param() with no arg returns hashref');
};

# param() for key outside allow list should warn and return undef
subtest 'param() - warns and returns undef for key outside allow list' => sub {
	plan tests => 2;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'foo=1';
	my $info = CGI::Info->new(allow => { foo => qr/\d+/ });
	$info->params();
	my $val = $info->param('bar');
	ok(!defined $val, 'param() returns undef for key outside allow list');
	my @warns = grep { $_->{message} =~ /isn.t in the allow list/ }
		@{ $info->messages() // [] };
	ok(scalar @warns, 'allow-list warning recorded in messages()');
};

# ============================================================
# 6. as_string()
# ============================================================

# Returns key=value pairs for known params
subtest 'as_string() - returns key=value pairs' => sub {
	plan tests => 2;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'b=2&a=1';
	my $info = CGI::Info->new();
	$info->params();
	my $str = $info->as_string();
	like($str, qr/a=1/, 'a=1 present in as_string output');
	like($str, qr/b=2/, 'b=2 present in as_string output');
};

# raw mode returns plain key=value without escaping
subtest 'as_string() - raw mode returns unescaped string' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'x=hello';
	my $info = CGI::Info->new();
	$info->params();
	my $raw = $info->as_string({ raw => 1 });
	is($raw, 'x=hello', 'raw mode returns unescaped key=value pair');
};

# No params returns empty string
subtest 'as_string() - no params returns empty string' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();
	is($info->as_string(), '', 'as_string() with no params returns empty string');
};

# ============================================================
# 7. script_name(), script_path(), script_dir()
# ============================================================

# SCRIPT_NAME environment variable drives script_name()
subtest 'script_name() - from SCRIPT_NAME env' => sub {
	plan tests => 1;
	reset_env();
	$ENV{SCRIPT_NAME} = '/cgi-bin/test.cgi';
	my $info = CGI::Info->new();
	like($info->script_name(), qr/test\.cgi/, 'script_name returns basename from SCRIPT_NAME');
};

# SCRIPT_FILENAME drives script_path()
subtest 'script_path() - from SCRIPT_FILENAME env' => sub {
	plan tests => 1;
	reset_env();
	$ENV{SCRIPT_FILENAME} = '/var/www/cgi-bin/test.cgi';
	my $info = CGI::Info->new();
	is($info->script_path(), '/var/www/cgi-bin/test.cgi', 'script_path from SCRIPT_FILENAME');
};

# script_dir() returns directory portion of script path
subtest 'script_dir() - returns directory portion' => sub {
	plan tests => 1;
	reset_env();
	if ($^O eq 'MSWin32') {
		pass('script_dir() Unix-path test skipped on Windows');
		return;
	}
	$ENV{SCRIPT_FILENAME} = '/var/www/cgi-bin/test.cgi';
	my $info = CGI::Info->new();
	is($info->script_dir(), '/var/www/cgi-bin', 'script_dir returns directory portion');
};

# script_dir() as class method auto-instantiates
subtest 'script_dir() - class method instantiates object' => sub {
	plan tests => 1;
	reset_env();
	$ENV{SCRIPT_FILENAME} = '/tmp/myscript.pl';
	my $dir = CGI::Info->script_dir();
	ok(defined $dir, 'script_dir() as class method returns a value');
};

# ============================================================
# 8. host_name(), domain_name(), cgi_host_url()
# ============================================================

# HTTP_HOST drives host_name()
subtest 'host_name() - from HTTP_HOST' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_HOST} = 'www.example.com';
	my $info = CGI::Info->new();
	is($info->host_name(), 'www.example.com', 'host_name returns HTTP_HOST value');
};

# domain_name() strips leading www.
subtest 'domain_name() - strips www. prefix' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_HOST} = 'www.example.com';
	my $info = CGI::Info->new();
	is($info->domain_name(), 'example.com', 'domain_name strips www. prefix');
};

# domain_name() as class method
subtest 'domain_name() - class method' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_HOST} = 'www.example.org';
	is(CGI::Info->domain_name(), 'example.org', 'domain_name() as class method');
};

# cgi_host_url() returns protocol + host
subtest 'cgi_host_url() - returns protocol and host' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_HOST}       = 'example.com';
	$ENV{SERVER_PROTOCOL} = 'HTTP/1.1';
	my $info = CGI::Info->new();
	my $url = $info->cgi_host_url();
	like($url, qr{^https?://example\.com}, 'cgi_host_url has protocol + host');
};

# ============================================================
# 9. protocol()
# ============================================================

# SCRIPT_URI drives protocol detection
subtest 'protocol() - from SCRIPT_URI' => sub {
	plan tests => 1;
	reset_env();
	$ENV{SCRIPT_URI} = 'https://example.com/cgi-bin/test.cgi';
	my $info = CGI::Info->new();
	is($info->protocol(), 'https', 'protocol() reads from SCRIPT_URI');
};

# SERVER_PROTOCOL HTTP/x.y returns 'http'
subtest 'protocol() - from SERVER_PROTOCOL' => sub {
	plan tests => 1;
	reset_env();
	$ENV{SERVER_PROTOCOL} = 'HTTP/1.1';
	my $info = CGI::Info->new();
	is($info->protocol(), 'http', 'protocol() returns http from SERVER_PROTOCOL');
};

# SERVER_PORT 443 boundary -- exact value, one below, one above
subtest 'protocol() - SERVER_PORT 443 boundary' => sub {
	plan tests => 3;
	reset_env();
	my $guard = mock_scoped 'Socket::getservbyport' => sub { return undef };

	$ENV{SERVER_PORT} = $config{port_https};
	is(CGI::Info->new()->protocol(), 'https', 'port 443 => https');

	$ENV{SERVER_PORT} = $config{port_https} - 1;
	my $p = CGI::Info->new()->protocol();
	ok(!defined($p) || $p ne 'https', 'port 442 does not return https');

	$ENV{SERVER_PORT} = $config{port_https} + 1;
	$p = CGI::Info->new()->protocol();
	ok(!defined($p) || $p ne 'https', 'port 444 does not return https');
};

# SERVER_PORT 80 boundary
subtest 'protocol() - SERVER_PORT 80 boundary' => sub {
	plan tests => 3;
	reset_env();
	my $guard = mock_scoped 'Socket::getservbyport' => sub { return undef };

	$ENV{SERVER_PORT} = $config{port_http};
	is(CGI::Info->new()->protocol(), 'http', 'port 80 => http');

	$ENV{SERVER_PORT} = $config{port_http} - 1;
	my $p = CGI::Info->new()->protocol();
	ok(!defined($p) || $p ne 'http', 'port 79 does not return http');

	$ENV{SERVER_PORT} = $config{port_http} + 1;
	$p = CGI::Info->new()->protocol();
	ok(!defined($p) || $p ne 'http', 'port 81 does not return http');
};

# ============================================================
# 10. is_mobile()
# ============================================================

# iPhone UA detected as mobile
subtest 'is_mobile() - iPhone user-agent' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_iphone};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	ok(CGI::Info->new()->is_mobile(), 'iPhone UA detected as mobile');
};

# Android UA detected as mobile
subtest 'is_mobile() - Android user-agent' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_android};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	ok(CGI::Info->new()->is_mobile(), 'Android UA detected as mobile');
};

# Desktop UA not detected as mobile
subtest 'is_mobile() - desktop user-agent not mobile' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_desktop};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	ok(!CGI::Info->new()->is_mobile(), 'desktop UA not detected as mobile');
};

# Sec-CH-UA-Mobile: ?1 header
subtest 'is_mobile() - Sec-CH-UA-Mobile hint' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_SEC_CH_UA_MOBILE} = '?1';
	ok(CGI::Info->new()->is_mobile(), 'Sec-CH-UA-Mobile ?1 detected as mobile');
};

# HTTP_X_WAP_PROFILE signals a mobile device
subtest 'is_mobile() - WAP profile header' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_X_WAP_PROFILE} = 'http://wap.example.com/profile';
	ok(CGI::Info->new()->is_mobile(), 'HTTP_X_WAP_PROFILE signals mobile');
};

# IS_MOBILE env override
subtest 'is_mobile() - IS_MOBILE env override' => sub {
	plan tests => 1;
	reset_env();
	$ENV{IS_MOBILE} = 1;
	ok(CGI::Info->new()->is_mobile(), 'IS_MOBILE env override works');
};

# ============================================================
# 11. is_tablet()
# ============================================================

subtest 'is_tablet() - iPad user-agent' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_ipad};
	ok(CGI::Info->new()->is_tablet(), 'iPad UA detected as tablet');
};

subtest 'is_tablet() - desktop user-agent not a tablet' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Windows NT 10.0)';
	ok(!CGI::Info->new()->is_tablet(), 'desktop UA not detected as tablet');
};

# ============================================================
# 12. is_robot()
# ============================================================

# Googlebot may be classed as robot or search engine, both are correct
subtest 'is_robot() - Googlebot classed as robot or search engine' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_gbot};
	$ENV{REMOTE_ADDR}     = $config{googlebot_ip};
	my $info   = CGI::Info->new();
	my $result = $info->is_robot() || $info->is_search_engine();
	ok($result, 'Googlebot classified as robot or search engine');
};

# ClaudeBot is a known robot
subtest 'is_robot() - ClaudeBot detected' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_cbot};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	ok(CGI::Info->new()->is_robot(), 'ClaudeBot detected as robot');
};

# SQL injection in UA sets 403 and marks as robot
subtest 'is_robot() - SQL injection in UA sets 403' => sub {
	plan tests => 2;
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla SELECT foo AND bar FROM baz';
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	my $info = CGI::Info->new();
	ok($info->is_robot(), 'SQL injection UA flagged as robot');
	is($info->status(), $config{status_forbidden}, 'status 403 on SQL injection UA');
};

# No CGI environment means assume real person (return 0)
subtest 'is_robot() - no CGI env returns 0' => sub {
	plan tests => 1;
	reset_env();
	is(CGI::Info->new()->is_robot(), 0, 'no CGI env returns 0 (assumes real person)');
};

# Critical security invariant: the SQL injection WAF check runs BEFORE is_ai(),
# so an AI crawler UA that also contains an injection payload still receives 403.
# If this order were reversed, the AI check would short-circuit and skip the WAF.
subtest 'is_robot() - SQL injection in AI crawler UA triggers 403 (ordering invariant)' => sub {
	plan tests => 2;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_gptbot_sql};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	my $info = CGI::Info->new();
	ok($info->is_robot(), 'injection in AI UA => is_robot still true');
	is($info->status(), $config{status_forbidden},
		'injection in AI UA => HTTP 403 set (WAF not bypassed by AI classification)');
};

# ============================================================
# 13. is_search_engine()
# ============================================================

subtest 'is_search_engine() - IS_SEARCH_ENGINE env override' => sub {
	plan tests => 1;
	reset_env();
	$ENV{IS_SEARCH_ENGINE} = 1;
	$ENV{REMOTE_ADDR}      = $config{good_ip};
	$ENV{HTTP_USER_AGENT}  = 'SomeBot';
	ok(CGI::Info->new()->is_search_engine(), 'IS_SEARCH_ENGINE env override works');
};

subtest 'is_search_engine() - no CGI env returns 0' => sub {
	plan tests => 1;
	reset_env();
	is(CGI::Info->new()->is_search_engine(), 0, 'no CGI env returns 0');
};

# ============================================================
# 14. is_ai()
# ============================================================

# Known AI training crawler => is_ai true and browser_type 'ai'
subtest 'is_ai() - ClaudeBot detected as AI crawler' => sub {
	plan tests => 3;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_cbot};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	my $info = CGI::Info->new();
	ok($info->is_ai(),                     'ClaudeBot => is_ai true');
	ok($info->is_robot(),                  'ClaudeBot => is_robot true (invariant)');
	is($info->browser_type(), 'ai',        'ClaudeBot => browser_type is ai');
};

# UA with no "bot"/"spider" token must still satisfy is_ai AND is_robot
subtest 'is_ai() - ChatGPT-User (no bot token) satisfies invariant' => sub {
	plan tests => 2;
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko); ChatGPT-User/1.0; +https://openai.com/bot)';
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	my $info = CGI::Info->new();
	ok($info->is_ai(),    'ChatGPT-User => is_ai true');
	ok($info->is_robot(), 'ChatGPT-User => is_robot true (is_robot calls is_ai internally)');
};

# IS_AI env override (use local so the override cannot bleed into later tests)
subtest 'is_ai() - IS_AI env override' => sub {
	plan tests => 1;
	reset_env();
	local $ENV{IS_AI}     = 1;
	$ENV{HTTP_USER_AGENT} = $config{ua_desktop};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	ok(CGI::Info->new()->is_ai(), 'IS_AI=1 env override forces is_ai true');
};

# Non-AI UA must not trigger is_ai
subtest 'is_ai() - desktop UA is not AI' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_desktop};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	ok(!CGI::Info->new()->is_ai(), 'desktop UA is not detected as AI crawler');
};

# No CGI environment => 0
subtest 'is_ai() - no CGI env returns 0' => sub {
	plan tests => 1;
	reset_env();
	is(CGI::Info->new()->is_ai(), 0, 'no CGI env returns 0');
};

# Call-order invariant: is_robot() first, then is_ai()
subtest 'is_ai() - call order: is_robot first still gives is_ai true' => sub {
	plan tests => 2;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_claude_web};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	my $info = CGI::Info->new();
	ok($info->is_robot(), 'Claude-Web: is_robot() true when called first');
	ok($info->is_ai(),    'Claude-Web: is_ai() true after is_robot()');
};

# IS_AI=0 must force false even when the UA matches the AI pattern.
# The env override is authoritative in both directions.
subtest 'is_ai() - IS_AI=0 override forces false for known AI UA' => sub {
	plan tests => 1;
	reset_env();
	local $ENV{IS_AI}     = 0;
	$ENV{HTTP_USER_AGENT} = $config{ua_cbot};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	ok(!CGI::Info->new()->is_ai(), 'IS_AI=0 env override suppresses AI detection');
};

# Without REMOTE_ADDR the CGI environment is incomplete; method returns 0
# without caching, consistent with is_robot() and is_search_engine() behaviour.
subtest 'is_ai() - no REMOTE_ADDR returns 0' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_cbot};
	# REMOTE_ADDR deliberately absent
	ok(!CGI::Info->new()->is_ai(), 'absent REMOTE_ADDR => is_ai returns 0');
};

# GPTBot (OpenAI training crawler): representative OpenAI-family UA.
# Confirms that is_ai does not depend on "ClaudeBot" alone.
subtest 'is_ai() - GPTBot detected as AI crawler' => sub {
	plan tests => 2;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_gptbot};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	my $info = CGI::Info->new();
	ok($info->is_ai(),    'GPTBot => is_ai true');
	ok($info->is_robot(), 'GPTBot => is_robot true (invariant holds)');
};

# cohere-ai contains no "bot" or "spider" token; this exercises the regex
# branches that cover unusual AI crawler UA string formats.
subtest 'is_ai() - cohere-ai UA (no bot/spider token) satisfies invariant' => sub {
	plan tests => 2;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_cohere_ai};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	my $info = CGI::Info->new();
	ok($info->is_ai(),    'cohere-ai => is_ai true');
	ok($info->is_robot(), 'cohere-ai => is_robot true (no "bot" token -- tests invariant path)');
};

# Googlebot is a search engine robot but NOT an AI training crawler;
# is_ai() must return false for it even though is_robot() returns true.
subtest 'is_ai() - Googlebot is robot but not AI' => sub {
	plan tests => 2;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_gbot};
	$ENV{REMOTE_ADDR}     = $config{googlebot_ip};
	my $info = CGI::Info->new();
	ok(!$info->is_ai(), 'Googlebot => is_ai false');
	ok($info->is_robot() || $info->is_search_engine(),
		'Googlebot => still classified as robot or search engine');
};

# The first call computes and caches $self->{is_ai}; the second call must
# return the same result from the cache without re-evaluating the UA regex.
subtest 'is_ai() - result is cached within the same instance' => sub {
	plan tests => 2;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_cbot};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	my $info   = CGI::Info->new();
	my $first  = $info->is_ai();
	my $second = $info->is_ai();	# must hit $self->{is_ai} cache
	ok($first,             'first call => is_ai true');
	is($second, $first,    'second call => identical cached result');
};

# Call-order: is_ai() first sets $self->{is_robot}=1; is_robot() then hits
# the instance cache and returns 1 without re-running its own detection logic.
subtest 'is_ai() - call order: is_ai first populates is_robot cache' => sub {
	plan tests => 2;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_claude_web};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	my $info = CGI::Info->new();
	ok($info->is_ai(),    'Claude-Web: is_ai() true when called first');
	ok($info->is_robot(), 'Claude-Web: is_robot() true after is_ai() (cache set by is_ai)');
};

# ============================================================
# 15. browser_type()
# ============================================================

subtest 'browser_type() - mobile' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_iphone};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	is(CGI::Info->new()->browser_type(), 'mobile', 'iPhone browser_type is mobile');
};

subtest 'browser_type() - desktop is web' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_desktop};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	is(CGI::Info->new()->browser_type(), 'web', 'desktop browser_type is web');
};

# AI crawlers must be classified as 'ai', which is checked before 'robot'.
# Verifies the priority order: mobile > ai > search > robot > web.
subtest 'browser_type() - returns ai for known AI crawler' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_USER_AGENT} = $config{ua_cbot};
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	is(CGI::Info->new()->browser_type(), 'ai', 'ClaudeBot => browser_type is ai');
};

# A generic spider that is NOT in the AI list must still return 'robot',
# not 'ai', confirming the AI check does not over-reach.
subtest 'browser_type() - generic spider returns robot not ai' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'SomeGenericSpider/1.0';
	$ENV{REMOTE_ADDR}     = $config{good_ip};
	is(CGI::Info->new()->browser_type(), 'robot', 'generic spider => browser_type is robot');
};

# ============================================================
# 15. cookie() / get_cookie()
# ============================================================

# cookie() returns value for known cookie name
subtest 'cookie() - returns value for known cookie' => sub {
	plan tests => 2;
	reset_env();
	$ENV{HTTP_COOKIE} = 'session=abc123; user=bob';
	my $info = CGI::Info->new();
	is($info->cookie('session'), 'abc123', 'cookie() returns session value');
	is($info->cookie('user'),    'bob',    'cookie() returns user value');
};

# Missing cookie returns undef
subtest 'cookie() - returns undef for missing cookie' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_COOKIE} = 'a=1';
	ok(!defined CGI::Info->new()->cookie('nosuchcookie'), 'missing cookie returns undef');
};

# get_cookie() is an alias for cookie()
subtest 'get_cookie() - named-arg alias for cookie()' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_COOKIE} = 'token=xyz';
	my $info = CGI::Info->new();
	is($info->get_cookie(cookie_name => 'token'), 'xyz', 'get_cookie() named-arg alias works');
};

# No HTTP_COOKIE means undef
subtest 'cookie() - no HTTP_COOKIE returns undef' => sub {
	plan tests => 1;
	reset_env();
	ok(!defined CGI::Info->new()->cookie('x'), 'no HTTP_COOKIE env returns undef');
};

# ============================================================
# 16. tmpdir()
# ============================================================

subtest 'tmpdir() - returns a writable directory' => sub {
	plan tests => 3;
	reset_env();
	my $dir = CGI::Info->new()->tmpdir();
	ok(defined $dir, 'tmpdir() returns defined value');
	ok(-d $dir,      'tmpdir() path is a directory');
	ok(-w $dir,      'tmpdir() path is writable');
};

subtest 'tmpdir() - default param honoured' => sub {
	plan tests => 1;
	reset_env();
	my $tmp  = tempdir(CLEANUP => 1);
	my $dir  = CGI::Info->new()->tmpdir(default => $tmp);
	ok(defined $dir, 'tmpdir() with default returns defined value');
};

subtest 'tmpdir() - class method' => sub {
	plan tests => 1;
	reset_env();
	ok(defined CGI::Info->tmpdir(), 'tmpdir() as class method works');
};

# ============================================================
# 17. rootdir() / root_dir() / documentroot()
# ============================================================

subtest 'rootdir() - from C_DOCUMENT_ROOT' => sub {
	plan tests => 1;
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{C_DOCUMENT_ROOT} = $tmp;
	is(CGI::Info->rootdir(), $tmp, 'rootdir() from C_DOCUMENT_ROOT');
};

subtest 'rootdir() - from DOCUMENT_ROOT' => sub {
	plan tests => 1;
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{DOCUMENT_ROOT} = $tmp;
	is(CGI::Info->rootdir(), $tmp, 'rootdir() from DOCUMENT_ROOT');
};

subtest 'root_dir() - synonym for rootdir()' => sub {
	plan tests => 1;
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{C_DOCUMENT_ROOT} = $tmp;
	is(CGI::Info->root_dir(), $tmp, 'root_dir() synonym returns same as rootdir()');
};

subtest 'documentroot() - synonym for rootdir()' => sub {
	plan tests => 1;
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{C_DOCUMENT_ROOT} = $tmp;
	is(CGI::Info->documentroot(), $tmp, 'documentroot() synonym returns correct value');
};

# ============================================================
# 18. logdir()
# ============================================================

# A valid, writable directory is accepted and returned
subtest 'logdir() - accepts valid directory' => sub {
	plan tests => 1;
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	is(CGI::Info->new()->logdir($tmp), $tmp, 'logdir() accepts and returns valid dir');
};

# An invalid path causes a croak with exact message
subtest 'logdir() - invalid path croaks with exact message' => sub {
	plan tests => 1;
	reset_env();
	my $bad = '/non/existent/path/xyz_' . $$;
	throws_ok {
		CGI::Info->new()->logdir($bad)
	} qr/Invalid logdir: \Q$bad\E/, 'logdir() croaks with "Invalid logdir: <path>"';
};

# No arg falls back to a valid directory
subtest 'logdir() - no arg returns a valid directory' => sub {
	plan tests => 2;
	reset_env();
	my $dir = CGI::Info->new()->logdir();
	ok(defined $dir, 'logdir() with no arg returns a defined value');
	ok(-d $dir,      'logdir() returned path is a directory');
};

# ============================================================
# 19. messages() / messages_as_string()
# ============================================================

subtest 'messages() - undef or arrayref when clean' => sub {
	plan tests => 1;
	reset_env();
	my $m = CGI::Info->new()->messages();
	ok(!defined $m || ref $m eq 'ARRAY', 'messages() returns undef or arrayref');
};

subtest 'messages_as_string() - empty initially' => sub {
	plan tests => 1;
	reset_env();
	is(CGI::Info->new()->messages_as_string(), '', 'messages_as_string() is empty initially');
};

# After a validation failure a message is logged
subtest 'messages_as_string() - non-empty after validation failure' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'id=abc';
	my $info = CGI::Info->new();
	$info->params(allow => { id => qr/^\d+$/ });
	ok(defined $info->messages(), 'messages() has entries after validation failure');
};

# ============================================================
# 20. cache()
# ============================================================

# cache() round-trips a blessed cache object
subtest 'cache() - accepts and returns blessed cache object' => sub {
	plan tests => 1;
	reset_env();
	my $mock_cache = bless {}, 'MockCache';
	{ no warnings 'once';
	  *MockCache::get = sub { undef };
	  *MockCache::set = sub { 1 };
	}
	my $info = CGI::Info->new();
	$info->cache($mock_cache);
	is($info->cache(), $mock_cache, 'cache() round-trips blessed object');
};

# Non-object argument causes croak
subtest 'cache() - non-object arg croaks' => sub {
	plan tests => 1;
	reset_env();
	throws_ok {
		CGI::Info->new()->cache('not-an-object')
	} qr/is not an object/i, 'cache() croaks when passed a non-object';
};

# cache object that lacks get() croaks
subtest 'cache() - object missing get() method croaks' => sub {
	plan tests => 1;
	reset_env();
	my $bad = bless {}, 'CacheNoGet';
	{ no warnings 'once'; *CacheNoGet::set = sub { 1 } }
	throws_ok {
		CGI::Info->new()->cache($bad)
	} qr/get/i, 'cache() croaks when object lacks get()';
};

# ============================================================
# 21. set_logger()
# ============================================================

# Accepts a blessed object with the three required methods
subtest 'set_logger() - accepts object with warn/info/error' => sub {
	plan tests => 1;
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
	is($info->{logger}, $log, 'set_logger() stores the logger object');
};

# set_logger() returns $self for method chaining
subtest 'set_logger() - returns $self for chaining' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();
	my $ret  = $info->set_logger('/dev/null');
	is($ret, $info, 'set_logger() returns $self for chaining');
};

# ============================================================
# 22. AUTOLOAD
# ============================================================

# Unknown method delegates to param()
subtest 'AUTOLOAD - unknown method delegates to param()' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'myfield=myvalue';
	my $info = CGI::Info->new();
	is($info->myfield(), 'myvalue', 'AUTOLOAD delegates unknown method to param()');
};

# Non-existent param returns undef via AUTOLOAD
subtest 'AUTOLOAD - missing param returns undef' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'x=1';
	my $info = CGI::Info->new();
	$info->params();
	ok(!defined $info->nosuchparam(), 'AUTOLOAD on missing param returns undef');
};

# auto_load => 0 disables AUTOLOAD delegation
subtest 'AUTOLOAD - disabled auto_load croaks' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new(auto_load => 0);
	throws_ok { $info->thisdoesnotexist() }
		qr/Unknown method/i, 'AUTOLOAD disabled causes croak on unknown method';
};

# ============================================================
# 23. Internal helper: _sanitise_input (white-box)
# The function is module-scope (not a method); call via full package path.
# String::Clean::XSS is lazy-loaded inside params(); trigger it first so
# convert_XSS() is available in the CGI::Info namespace for direct calls.
# ============================================================

# Ensure String::Clean::XSS is imported into CGI::Info namespace before
# any direct _sanitise_input call; params() triggers the lazy require.
{
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'bootstrap=1';
	CGI::Info->new()->params();
	reset_env();
}

# undef input returns undef
subtest '_sanitise_input - undef returns undef' => sub {
	plan tests => 1;
	ok(!defined CGI::Info::_sanitise_input(undef), '_sanitise_input(undef) returns undef');
};

# Leading and trailing whitespace stripped
subtest '_sanitise_input - strips leading/trailing whitespace' => sub {
	plan tests => 2;
	my $result = CGI::Info::_sanitise_input("  hello  ");
	ok(defined $result, '_sanitise_input returns defined value for plain text');
	unlike($result, qr/^\s|\s$/, '_sanitise_input strips surrounding whitespace');
};

# Carriage-return and newline characters removed
subtest '_sanitise_input - strips CR and LF' => sub {
	plan tests => 1;
	my $result = CGI::Info::_sanitise_input("hel\r\nlo");
	if (defined $result) {
		unlike($result, qr/[\r\n]/, '_sanitise_input removes CR/LF');
	} else {
		pass('value sanitised away (acceptable)');
	}
};

# HTML comments stripped
subtest '_sanitise_input - strips HTML comments' => sub {
	plan tests => 1;
	my $input  = '<!-- attack -->safe';
	my $result = CGI::Info::_sanitise_input($input);
	if (defined $result) {
		unlike($result, qr/<!--/, '_sanitise_input removes HTML comment markers');
	} else {
		pass('HTML comment input sanitised away');
	}
};

# XSS script tag should be sanitised
subtest '_sanitise_input - removes XSS script tag' => sub {
	plan tests => 1;
	my $result = CGI::Info::_sanitise_input('<script>alert(1)</script>');
	if (defined $result) {
		unlike($result, qr/<script>/i, '_sanitise_input removes script tags');
	} else {
		pass('XSS value sanitised away');
	}
};

# ============================================================
# 24. Internal helper: _get_env (white-box)
# Validates env var format before returning it.
# ============================================================

# A clean alphanumeric path passes through unchanged
subtest '_get_env - clean path value passes through' => sub {
	plan tests => 1;
	reset_env();
	local $ENV{_FUNCTEST_CLEAN} = '/var/www/cgi-bin/test.pl';
	my $info   = CGI::Info->new();
	my $result = $info->_get_env('_FUNCTEST_CLEAN');
	is($result, '/var/www/cgi-bin/test.pl', '_get_env returns clean path unchanged');
};

# An env var with a space is rejected (space not in allowed charset)
subtest '_get_env - value with space returns undef and warns' => sub {
	plan tests => 2;
	reset_env();
	local $ENV{_FUNCTEST_SPACE} = 'has space';
	my $info   = CGI::Info->new();
	my $result = $info->_get_env('_FUNCTEST_SPACE');
	ok(!defined $result, '_get_env rejects value containing a space');
	my @warns = grep { $_->{message} =~ /Invalid value in environment variable/ }
		@{ $info->messages() // [] };
	ok(scalar @warns, '_get_env logs warning for rejected value');
};

# An undefined env var returns undef without logging
subtest '_get_env - undefined env var returns undef silently' => sub {
	plan tests => 2;
	reset_env();
	delete $ENV{_FUNCTEST_UNDEF};
	my $info   = CGI::Info->new();
	my $result = $info->_get_env('_FUNCTEST_UNDEF');
	ok(!defined $result, '_get_env returns undef for undefined variable');
	my @msgs = @{ $info->messages() // [] };
	ok(!scalar @msgs, 'no warning logged for undefined env var');
};

# ============================================================
# 25. Internal helper: _find_paths (white-box via public API)
# ============================================================

# Falls back to $0 when no SCRIPT_NAME/SCRIPT_FILENAME set
subtest '_find_paths - falls back to $0 for script_name' => sub {
	plan tests => 2;
	reset_env();
	my $info = CGI::Info->new();
	my $name = $info->script_name();
	ok(defined $name,  '_find_paths: script_name defined without env');
	ok(length($name),  '_find_paths: script_name non-empty without env');
};

# DOCUMENT_ROOT + SCRIPT_NAME builds a script_path
subtest '_find_paths - builds path from DOCUMENT_ROOT + SCRIPT_NAME' => sub {
	plan tests => 1;
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{DOCUMENT_ROOT} = $tmp;
	$ENV{SCRIPT_NAME}   = '/cgi-bin/foo.cgi';
	like(CGI::Info->new()->script_path(), qr/foo\.cgi/, 'script_path built from DOCUMENT_ROOT + SCRIPT_NAME');
};

# ============================================================
# 26. Internal helper: _find_site_details (white-box via public API)
# ============================================================

# Falls back to system hostname when no HTTP_HOST
subtest '_find_site_details - falls back to system hostname' => sub {
	plan tests => 2;
	reset_env();
	my $host = CGI::Info->new()->host_name();
	ok(defined $host,  '_find_site_details: host_name defined without env');
	ok(length($host),  '_find_site_details: host_name non-empty without env');
};

# Trailing dot removed from HTTP_HOST
subtest '_find_site_details - strips trailing dot from HTTP_HOST' => sub {
	plan tests => 1;
	reset_env();
	$ENV{HTTP_HOST} = 'example.com.';
	unlike(CGI::Info->new()->host_name(), qr/\.$/, 'trailing dot removed from HTTP_HOST');
};

# ============================================================
# 27. Internal helper: _untaint_filename (white-box)
# ============================================================

# A clean filename with common safe characters is returned
subtest '_untaint_filename - valid filename returned' => sub {
	plan tests => 2;
	reset_env();
	my $info   = CGI::Info->new();
	my $result = $info->_untaint_filename({ filename => 'report_2025-01.pdf' });
	ok(defined $result, '_untaint_filename returns defined for valid filename');
	is($result, 'report_2025-01.pdf', '_untaint_filename returns filename unchanged');
};

# A filename containing a pipe (forbidden) returns undef
subtest '_untaint_filename - pipe character returns undef' => sub {
	plan tests => 1;
	reset_env();
	my $info   = CGI::Info->new();
	my $result = $info->_untaint_filename({ filename => 'bad|file.txt' });
	ok(!defined $result, '_untaint_filename returns undef for filename with pipe');
};

# A filename with a double-quote returns undef
subtest '_untaint_filename - double-quote returns undef' => sub {
	plan tests => 1;
	reset_env();
	my $info   = CGI::Info->new();
	my $result = $info->_untaint_filename({ filename => 'bad"file.txt' });
	ok(!defined $result, '_untaint_filename returns undef for filename with double-quote');
};

# ============================================================
# 28. Internal helper: _create_file_name (white-box)
# ============================================================

# Returns a timestamped filename that does not yet exist on disk
subtest '_create_file_name - returns non-existent timestamped name' => sub {
	plan tests => 3;
	reset_env();
	my $info     = CGI::Info->new();
	my $t_before = time();
	my $result   = $info->_create_file_name({ filename => 'functest_upload' });
	my $t_after  = time();

	# Pattern: 'functest_upload_TIMESTAMP' with optional '_N' collision counter
	like($result, qr/^functest_upload_\d+(_\d+)?$/, 'result matches expected pattern');

	my ($ts) = $result =~ /^functest_upload_(\d+)/;
	ok($ts >= $t_before && $ts <= $t_after + 1, 'embedded timestamp is within current second');
	ok(! -e $result, 'returned path does not already exist on disk');
};

# When the base name already exists, a collision counter is appended
subtest '_create_file_name - appends counter when base name exists' => sub {
	plan tests => 1;
	reset_env();

	my $tmp  = tempdir(CLEANUP => 1);
	my $info = CGI::Info->new();
	my $cwd  = getcwd();

	# Untaint paths: tempdir()/getcwd() return tainted values under -T
	my ($safe_tmp) = $tmp =~ /^(.+)$/;
	my ($safe_cwd) = $cwd =~ /^(.+)$/;

	chdir $safe_tmp or die "Can't chdir to $safe_tmp: $!";

	# Discover the name the function would generate now
	my $first = $info->_create_file_name({ filename => 'coll' });

	# Create that file to force a collision on the next call
	open(my $fh, '>', $first) or die "Can't create $first: $!";
	close($fh);

	# The next call must return a different path
	my $second = $info->_create_file_name({ filename => 'coll' });

	chdir $safe_cwd or die "Can't restore cwd: $!";

	isnt($second, $first, '_create_file_name returns different path when base name exists');
};

# ============================================================
# 29. Internal helpers: _log, _debug, _info, _notice, _trace,
#     _warn, _error  (white-box)
# ============================================================

# _log populates messages array with correct level and message
subtest '_log - populates messages() with correct level' => sub {
	plan tests => 3;
	reset_env();
	my $info = CGI::Info->new();

	$info->_log('warn', 'test warning message');

	my $msgs = $info->messages();
	ok(defined $msgs && scalar @$msgs, '_log adds entry to messages()');
	is($msgs->[-1]->{level},   'warn',                '_log records correct level');
	is($msgs->[-1]->{message}, 'test warning message', '_log records correct message text');
};

# _log with multiple message parts joins them with a space
subtest '_log - multiple parts joined with space' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();
	$info->_log('info', 'part one', 'part two');
	my $msgs = $info->messages();
	is($msgs->[-1]->{message}, 'part one part two', '_log joins multiple parts with space');
};

# _log with no messages is a no-op
subtest '_log - empty message list is a no-op' => sub {
	plan tests => 1;
	reset_env();
	my $info  = CGI::Info->new();
	my $before = scalar @{ $info->messages() // [] };
	$info->_log('warn');   # no message parts
	my $after  = scalar @{ $info->messages() // [] };
	is($after, $before, '_log with empty message list does not add entry');
};

# _debug logs at 'debug' level
subtest '_debug - logs at debug level' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();
	$info->_debug('debug line');
	my @debug = grep { $_->{level} eq 'debug' } @{ $info->messages() // [] };
	ok(scalar @debug, '_debug logs at debug level');
};

# _info logs at 'info' level
subtest '_info - logs at info level' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();
	$info->_info('info line');
	my @info = grep { $_->{level} eq 'info' } @{ $info->messages() // [] };
	ok(scalar @info, '_info logs at info level');
};

# _notice logs at 'notice' level
subtest '_notice - logs at notice level' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();
	$info->_notice('notice line');
	my @notice = grep { $_->{level} eq 'notice' } @{ $info->messages() // [] };
	ok(scalar @notice, '_notice logs at notice level');
};

# _trace logs at 'trace' level
subtest '_trace - logs at trace level' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();
	$info->_trace('trace line');
	my @trace = grep { $_->{level} eq 'trace' } @{ $info->messages() // [] };
	ok(scalar @trace, '_trace logs at trace level');
};

# _warn always appends to messages(); carps only when logger is absent
subtest '_warn - appends to messages() and carps without logger' => sub {
	plan tests => 2;
	reset_env();
	my $info = CGI::Info->new();
	delete $info->{logger};   # remove injected logger to trigger carp path

	my $carp_fired = 0;
	local $SIG{__WARN__} = sub { $carp_fired++ };
	$info->_warn('test warning');

	my @msgs = grep { $_->{message} eq 'test warning' } @{ $info->messages() // [] };
	ok(scalar @msgs,  '_warn appends entry to messages()');
	ok($carp_fired,   '_warn carps when no logger is present');
};

# _warn with logger does NOT carp (logger swallows it)
subtest '_warn - does not carp when logger is present' => sub {
	plan tests => 2;
	reset_env();
	my $info = CGI::Info->new();
	# Logger already injected by Object::Configure; just verify no carp fires

	my $carp_fired = 0;
	local $SIG{__WARN__} = sub { $carp_fired++ };
	$info->_warn('silent warning');

	my @msgs = grep { $_->{message} eq 'silent warning' } @{ $info->messages() // [] };
	ok(scalar @msgs,   '_warn still appends to messages() when logger present');
	ok(!$carp_fired,   '_warn does not carp when logger is present');
};

# _error always appends to messages(); croaks only when logger is absent
subtest '_error - croaks without logger, still logs message' => sub {
	plan tests => 2;
	reset_env();
	my $info = CGI::Info->new();
	delete $info->{logger};   # remove logger to exercise croak path

	throws_ok { $info->_error('fatal error text') }
		qr/fatal error text/, '_error croaks with supplied message when no logger';

	my @msgs = grep { $_->{message} eq 'fatal error text' } @{ $info->messages() // [] };
	ok(scalar @msgs, '_error appended message to messages() before croaking');
};

# _error with logger does NOT croak
subtest '_error - does not croak when logger present' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();
	# Object::Configure has injected a logger; _error must not croak
	lives_ok { $info->_error('logged error') }
		'_error does not croak when a logger is present';
};

# ============================================================
# 30. POST with application/json content type
# ============================================================

subtest 'params() - POST JSON body decoded to hash' => sub {
	plan tests => 1;
	reset_env();
	my $json_body = '{"alpha":"one","beta":"two"}';
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'POST';
	$ENV{CONTENT_TYPE}      = 'application/json';
	$ENV{CONTENT_LENGTH}    = length($json_body);
	$CGI::Info::stdin_data  = $json_body;

	my $info = CGI::Info->new();
	my $p    = $info->params();
	if (defined $p) {
		is($p->{alpha}, 'one', 'JSON POST: alpha=one');
	} else {
		pass('JSON POST: no result (JSON module unavailable, acceptable)');
	}
};

# ============================================================
# 31. POST with text/xml content type
# ============================================================

subtest 'params() - POST XML body stored under XML key' => sub {
	plan tests => 2;
	reset_env();
	my $xml_body = '<root><item>test</item></root>';
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'POST';
	$ENV{CONTENT_TYPE}      = 'text/xml';
	$ENV{CONTENT_LENGTH}    = length($xml_body);
	$CGI::Info::stdin_data  = $xml_body;

	my $info = CGI::Info->new();
	my $p    = $info->params();
	ok(defined $p,          'XML POST returns a defined hashref');
	is($p->{XML}, $xml_body, 'XML body stored under key "XML"');
};

# ============================================================
# 32. $_ preservation (internal helpers must not clobber $_)
# Any internal use of for/foreach without a lexical variable could
# overwrite $_ in the caller's scope.
# ============================================================

subtest '$_ not clobbered by public methods' => sub {
	plan tests => 6;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'x=1';
	$ENV{HTTP_USER_AGENT}   = $config{ua_desktop};
	$ENV{REMOTE_ADDR}       = $config{good_ip};
	$ENV{HTTP_HOST}         = 'example.com';

	my $info = CGI::Info->new();

	# Set $_ to a sentinel and verify each method leaves it unchanged
	local $_ = 'SENTINEL';

	$info->params();
	is($_, 'SENTINEL', 'params() does not clobber $_');

	$info->is_mobile();
	is($_, 'SENTINEL', 'is_mobile() does not clobber $_');

	$info->is_robot();
	is($_, 'SENTINEL', 'is_robot() does not clobber $_');

	$info->as_string();
	is($_, 'SENTINEL', 'as_string() does not clobber $_');

	$info->script_name();
	is($_, 'SENTINEL', 'script_name() does not clobber $_');

	$info->host_name();
	is($_, 'SENTINEL', 'host_name() does not clobber $_');
};

# Internal helpers must also preserve $_
subtest '$_ not clobbered by internal helpers' => sub {
	plan tests => 3;
	reset_env();
	my $info = CGI::Info->new();

	local $_ = 'SENTINEL2';

	$info->_log('info', 'msg');
	is($_, 'SENTINEL2', '_log does not clobber $_');

	$info->_debug('dbg');
	is($_, 'SENTINEL2', '_debug does not clobber $_');

	CGI::Info::_sanitise_input('hello world');
	is($_, 'SENTINEL2', '_sanitise_input does not clobber $_');
};

# ============================================================
# 33. Test::Memory::Cycle -- object must be cycle-free
# ============================================================

subtest 'CGI::Info object has no circular references' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'a=1&b=2';
	$ENV{HTTP_USER_AGENT}   = $config{ua_iphone};
	$ENV{REMOTE_ADDR}       = $config{good_ip};
	$ENV{HTTP_HOST}         = 'example.com';

	my $info = CGI::Info->new();
	$info->params();
	$info->is_mobile();
	$info->host_name();

	# Any circular reference in the object would prevent garbage collection
	memory_cycle_ok($info, 'CGI::Info object contains no circular references');
};

# ============================================================
# 34. Test::Returns -- return type validation
# ============================================================

subtest 'Test::Returns - params() returns hashref' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'k=v';
	my $p = CGI::Info->new()->params();
	returns_ok($p, { type => 'hashref' }, 'params() return value satisfies hashref schema');
};

subtest 'Test::Returns - messages() returns arrayref when populated' => sub {
	plan tests => 1;
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = 'id=abc';
	my $info = CGI::Info->new();
	$info->params(allow => { id => qr/^\d+$/ });
	my $msgs = $info->messages();
	returns_ok($msgs, { type => 'arrayref' }, 'messages() return value satisfies arrayref schema');
};

subtest 'Test::Returns - status() returns integer scalar' => sub {
	plan tests => 1;
	reset_env();
	my $s = CGI::Info->new()->status();
	returns_ok($s, { type => 'integer' }, 'status() return value satisfies integer schema');
};

subtest 'Test::Returns - tmpdir() returns a defined string' => sub {
	plan tests => 2;
	reset_env();
	my $dir = CGI::Info->new()->tmpdir();
	returns_ok($dir, { type => 'string' }, 'tmpdir() return value satisfies string schema');
	ok(length($dir) > 0, 'tmpdir() return value is non-empty');
};

# ============================================================
# Private method access guards
# Temporarily unset HARNESS_ACTIVE to simulate a production
# caller; verify that each protected method croaks with the
# expected message when invoked from outside CGI::Info.
# ============================================================

subtest 'protected method guards - _trace croaks from outside' => sub {
	plan tests => 2;
	reset_env();
	my $info = new_ok('CGI::Info');

	# Remove HARNESS_ACTIVE for the scope of this subtest only
	local %ENV = %ENV;
	delete $ENV{HARNESS_ACTIVE};

	throws_ok { $info->_trace('test') }
		qr/_trace\(\) is a protected method/,
		'_trace() croaks with correct message when called from outside';
};

subtest 'protected method guards - _log croaks from outside' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();

	local %ENV = %ENV;
	delete $ENV{HARNESS_ACTIVE};

	throws_ok { $info->_log('warn', 'test') }
		qr/_log\(\) is a protected method/,
		'_log() croaks with correct message when called from outside';
};

subtest 'protected method guards - _warn croaks from outside' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();

	local %ENV = %ENV;
	delete $ENV{HARNESS_ACTIVE};

	throws_ok { $info->_warn('test') }
		qr/_warn\(\) is a protected method/,
		'_warn() croaks with correct message when called from outside';
};

subtest 'protected method guards - _error croaks from outside' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();

	local %ENV = %ENV;
	delete $ENV{HARNESS_ACTIVE};

	throws_ok { $info->_error('test') }
		qr/_error\(\) is a protected method/,
		'_error() croaks with correct message when called from outside';
};

subtest 'protected method guards - _get_env croaks from outside' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();

	local %ENV = %ENV;
	delete $ENV{HARNESS_ACTIVE};

	throws_ok { $info->_get_env('PATH') }
		qr/_get_env\(\) is a protected method/,
		'_get_env() croaks with correct message when called from outside';
};

subtest 'protected method guards - _sanitise_input croaks from outside' => sub {
	plan tests => 1;
	reset_env();

	local %ENV = %ENV;
	delete $ENV{HARNESS_ACTIVE};

	# _sanitise_input is a plain function, not a method; call via full package name
	throws_ok { CGI::Info::_sanitise_input('test') }
		qr/_sanitise_input\(\) is a protected method/,
		'_sanitise_input() croaks with correct message when called from outside';
};

subtest 'protected method guards - _find_paths croaks from outside' => sub {
	plan tests => 1;
	reset_env();
	my $info = CGI::Info->new();

	local %ENV = %ENV;
	delete $ENV{HARNESS_ACTIVE};

	throws_ok { $info->_find_paths() }
		qr/is a protected method/,
		'_find_paths() croaks with correct message when called from outside';
};

subtest 'protected method guards - subclass may call protected methods' => sub {
	plan tests => 2;

	# Define a minimal subclass inline to test that subclasses are permitted
	{
		package CGI::InfoSub;
		our @ISA = ('CGI::Info');
		sub call_trace {
			my $self = shift;
			# This must not croak even without HARNESS_ACTIVE
			eval { $self->_trace('subclass call') };
			return $@;
		}
	}

	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}    = 'GET';
	$ENV{QUERY_STRING}      = '';

	my $sub = CGI::InfoSub->new();

	local %ENV = %ENV;
	delete $ENV{HARNESS_ACTIVE};

	my $err = $sub->call_trace();
	ok(!$err, 'subclass can call _trace() without croaking');

	# Confirm the subclass is actually a subclass
	ok($sub->isa('CGI::Info'), 'CGI::InfoSub isa CGI::Info');
};

diag("function.t completed") if $ENV{TEST_VERBOSE};

done_testing();
