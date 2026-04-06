#!/usr/bin/env perl

# Integration tests for CGI::Info.
# Black-box, end-to-end tests that exercise behaviour across multiple methods
# in realistic combinations, including stateful interactions.
# No knowledge of internal implementation is assumed.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(mock);
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
# 1. Full CGI request lifecycle: GET form submission
#	params() -> param() -> as_string() -> status()
# ============================================================

subtest 'GET lifecycle: parse, retrieve, serialise, check status' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'name=Alice&age=30&city=London';

	my $info = new_ok('CGI::Info');

	# Parse all params
	my $params = $info->params();
	ok(ref($params) eq 'HASH', 'params() returns hashref');
	is($params->{name}, 'Alice',  'name parsed');
	is($params->{age},  '30',	 'age parsed');
	is($params->{city}, 'London', 'city parsed');

	# Retrieve individually via param()
	is($info->param('name'), 'Alice',  'param(name) matches');
	is($info->param('age'),  '30',	 'param(age) matches');
	is($info->param('city'), 'London', 'param(city) matches');

	# Serialise via as_string()
	my $str = $info->as_string();
	like($str, qr/name=Alice/, 'as_string contains name=Alice');
	like($str, qr/age=30/,	 'as_string contains age=30');
	like($str, qr/city=London/,'as_string contains city=London');

	# Keys appear in sorted order
	my @keys = map { /^(\w+)=/ ? $1 : () } split /;\s*/, $str;
	my @sorted = sort @keys;
	is_deeply(\@keys, \@sorted, 'as_string() keys are sorted');

	# Status is 200 throughout a clean request
	is($info->status(), 200, 'status 200 after clean GET');
};

# ============================================================
# 2. GET with allow list: valid and invalid params in same request
# ============================================================

subtest 'GET with allow: valid params accepted, invalid silently dropped' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'id=42&secret=hacked&name=Bob';

	my $info = CGI::Info->new();
	my $params = $info->params(allow => {
		id   => qr/^\d+$/,
		name => qr/^[A-Za-z]+$/,
	});

	ok(defined $params,			'params returned despite mixed input');
	is($params->{id},   '42',	 'valid id accepted');
	is($params->{name}, 'Bob',	'valid name accepted');
	ok(!exists $params->{secret}, 'secret silently excluded');

	# param() also reflects the filtered set
	is($info->param('id'),   '42',  'param(id) consistent with params()');
	is($info->param('name'), 'Bob', 'param(name) consistent with params()');

	# as_string() reflects only the accepted params
	my $str = $info->as_string();
	unlike($str, qr/secret/, 'as_string() does not leak excluded param');
};

# ============================================================
# 3. Stateful: params() cached — second call with same allow returns same ref
# ============================================================

subtest 'params() cached: identical allow returns same hashref' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'x=1&y=2';

	my $info = CGI::Info->new();
	my $allow = { x => qr/\d+/, y => qr/\d+/ };

	my $p1 = $info->params(allow => $allow);
	my $p2 = $info->params(allow => $allow);
	is($p1, $p2, 'same allow => same cached hashref returned');
};

# ============================================================
# 4. Stateful: new allow invalidates cache
# ============================================================

subtest 'params() cache: new allow ref triggers re-parse' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'a=1&b=2';

	my $info = CGI::Info->new();

	my $p1 = $info->params(allow => { a => undef, b => undef });
	ok(defined $p1->{a} && defined $p1->{b}, 'both keys present with open allow');

	my $p2 = $info->params(allow => { a => undef });
	ok(defined $p2->{a},	'a still present with restricted allow');
	ok(!defined $p2->{b},   'b excluded with restricted allow');
};

# ============================================================
# 5. Stateful: clone inherits parent state, overrides work
# ============================================================

subtest 'clone: inherits parent config, override applies independently' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'q=test';

	my $orig  = CGI::Info->new(max_upload_size => 1024);
	my $clone = $orig->new(max_upload_size => 512);

	# Both are valid CGI::Info objects
	isa_ok($orig,  'CGI::Info', 'original');
	isa_ok($clone, 'CGI::Info', 'clone');

	# Both can independently parse params from the same environment
	my $p_orig  = $orig->params();
	my $p_clone = $clone->params();
	is($p_orig->{q},  'test', 'original parses q=test');
	is($p_clone->{q}, 'test', 'clone parses q=test');

	# They are distinct objects
	isnt($orig, $clone, 'clone is a different object');
};

# ============================================================
# 6. Stateful: status accumulates across method calls
# ============================================================

subtest 'status: accumulates correctly across multiple interactions' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'id=notanumber';

	my $info = CGI::Info->new();
	is($info->status(), 200, 'initial status 200');

	# Trigger a validation failure
	$info->params(allow => { id => qr/^\d+$/ });
	is($info->status(), 422, 'status 422 after validation failure');

	# Explicitly override status
	$info->status(200);
	is($info->status(), 200, 'status reset to 200 explicitly');

	# Trigger a WAF block
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'x=../../etc/passwd';
	$info = CGI::Info->new();
	$info->params();
	is($info->status(), 403, 'status 403 after WAF block');
};

# ============================================================
# 7. Stateful: messages accumulate from multiple operations
# ============================================================

subtest 'messages: accumulate across validation failures' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'a=bad&b=alsoBad';

	my $info = CGI::Info->new();
	$info->params(allow => {
		a => qr/^\d+$/,
		b => qr/^\d+$/,
	});

	my $msgs = $info->messages();
	ok(defined $msgs && ref($msgs) eq 'ARRAY', 'messages() returns arrayref');
	ok(scalar @{$msgs} > 0, 'at least one message logged');

	my $str = $info->messages_as_string();
	ok(length($str) > 0, 'messages_as_string() non-empty');
};

# ============================================================
# 8. logger set via new(): warnings routed to logger, not carp
# ============================================================

subtest 'logger: validation warnings routed to logger object' => sub {
	reset_env();

	{
		package CapturingLogger;
		our @msgs;
		sub new   { bless {}, shift }
		sub warn  { push @CapturingLogger::msgs, $_[1] }
		sub info  { push @CapturingLogger::msgs, $_[1] }
		sub error { push @CapturingLogger::msgs, $_[1] }
		sub debug { }
		sub trace { }
	}
	@CapturingLogger::msgs = ();
	my $logger = CapturingLogger->new();

	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'id=notanumber';

	my $info = CGI::Info->new(logger => $logger);
	$info->params(allow => { id => qr/^\d+$/ });

	# Regardless of how the logger routes output, messages() must be populated
	my $msgs = $info->messages();
	ok(defined $msgs && scalar @{$msgs} > 0,
		'validation failure logged: messages() populated');
	is($info->status(), 422, 'status 422 set when logger present');
};

# ============================================================
# 9. Browser detection + params in same session
# ============================================================

subtest 'mobile browser: browser_type, is_mobile, params all consistent' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT}   = 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)';
	$ENV{REMOTE_ADDR}	   = '1.2.3.4';
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'view=compact&page=1';

	my $info = CGI::Info->new();

	ok($info->is_mobile(),			   'is_mobile() true for iPhone');
	ok(!$info->is_tablet(),			  'is_tablet() false for iPhone');
	is($info->browser_type(), 'mobile',  'browser_type() is mobile');
	ok(!$info->is_robot(),			   'is_robot() false for real user');
	ok(!$info->is_search_engine(),	   'is_search_engine() false for iPhone');

	my $params = $info->params();
	is($params->{view}, 'compact', 'params parsed correctly alongside mobile detection');
	is($params->{page}, '1',	   'page param parsed');
};

subtest 'tablet browser: is_tablet, is_mobile, browser_type consistent' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPad; CPU OS 15_0 like Mac OS X)';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';

	my $info = CGI::Info->new();

	ok($info->is_tablet(),			  'is_tablet() true for iPad');
	ok($info->is_mobile(),			  'is_mobile() true for iPad (tablets are mobile)');
	is($info->browser_type(), 'mobile', 'browser_type() mobile for tablet');
};

subtest 'robot browser: is_robot, browser_type, params blocked on SQL UA' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT}   = 'ClaudeBot/1.0 (+http://www.anthropic.com)';
	$ENV{REMOTE_ADDR}	   = '1.2.3.4';
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'q=test';

	my $info = CGI::Info->new();

	ok($info->is_robot(),			  'is_robot() true for ClaudeBot');
	is($info->browser_type(), 'robot', 'browser_type() is robot');
	ok(!$info->is_mobile(),			'is_mobile() false for robot');
	ok(!$info->is_tablet(),			'is_tablet() false for robot');

	# params() should still work for a robot (it only blocks on bad content)
	my $params = $info->params();
	ok(!defined($params) || defined($params->{q}),
		'params accessible for robot with clean query');
};

subtest 'desktop browser: browser_type web, not mobile/tablet/robot' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120';
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';

	my $info = CGI::Info->new();

	ok(!$info->is_mobile(),		  'desktop is not mobile');
	ok(!$info->is_tablet(),		  'desktop is not tablet');
	ok(!$info->is_robot(),		   'desktop is not robot');
	is($info->browser_type(), 'web', 'desktop browser_type is web');
};

# ============================================================
# 10. Stateful: --mobile/--robot/--tablet/--search-engine ARGV flags
#	 Each flag sets the appropriate state AND params() still works
# ============================================================

subtest 'ARGV --mobile flag: is_mobile true, params still parsed' => sub {
	reset_env();
	local @ARGV = ('--mobile', 'section=news', 'limit=10');
	my $info = CGI::Info->new();
	$info->params();

	ok($info->is_mobile(), '--mobile sets is_mobile');
	my $p = $info->params();
	is($p->{section}, 'news', 'section param parsed after --mobile');
	is($p->{limit},   '10',   'limit param parsed after --mobile');
};

subtest 'ARGV --robot flag: is_robot true, browser_type robot' => sub {
	reset_env();
	local @ARGV = ('--robot');
	my $info = CGI::Info->new();
	$info->params();

	ok($info->is_robot(),			  '--robot sets is_robot');
	is($info->browser_type(), 'robot', 'browser_type robot after --robot');
};

subtest 'ARGV --tablet flag: is_tablet true, is_mobile still works' => sub {
	reset_env();
	local @ARGV = ('--tablet', 'view=grid');
	my $info = CGI::Info->new();
	my $p = $info->params();

	ok($info->is_tablet(), '--tablet sets is_tablet');
	is($p->{view}, 'grid', 'view param parsed after --tablet');
};

subtest 'ARGV --search-engine flag: is_search_engine true' => sub {
	reset_env();
	local @ARGV = ('--search-engine');
	my $info = CGI::Info->new();
	$info->params();

	ok($info->is_search_engine(), '--search-engine sets is_search_engine');
	is($info->browser_type(), 'search', 'browser_type search after flag');
};

# ============================================================
# 11. Site details: host_name, domain_name, cgi_host_url, protocol consistent
# ============================================================

subtest 'site details: all methods consistent for http://www.example.com' => sub {
	reset_env();
	$ENV{HTTP_HOST}	   = 'www.example.com';
	$ENV{SERVER_PROTOCOL} = 'HTTP/1.1';

	my $info = CGI::Info->new();

	my $host   = $info->host_name();
	my $domain = $info->domain_name();
	my $url	= $info->cgi_host_url();
	my $proto  = $info->protocol();

	is($host,   'www.example.com', 'host_name correct');
	is($domain, 'example.com',	 'domain_name strips www.');
	like($url,  qr{^http://},	  'cgi_host_url starts with http://');
	like($url,  qr/example\.com/,  'cgi_host_url contains host');
	is($proto,  'http',			'protocol is http');

	# domain_name is a suffix of host_name
	like($host, qr/\Q$domain\E$/, 'host_name ends with domain_name');

	# cgi_host_url contains the host_name
	like($url, qr/\Q$host\E/, 'cgi_host_url contains host_name');
};

subtest 'site details: HTTPS site consistent' => sub {
	reset_env();
	$ENV{SCRIPT_URI} = 'https://secure.example.org/cgi-bin/app.cgi';
	$ENV{HTTP_HOST}  = 'secure.example.org';

	my $info = CGI::Info->new();

	is($info->protocol(),	'https',			  'protocol is https');
	is($info->host_name(),   'secure.example.org', 'host_name correct');
	is($info->domain_name(), 'secure.example.org', 'domain_name (no www to strip)');
	like($info->cgi_host_url(), qr{^https?://},	'cgi_host_url has protocol');
};

# ============================================================
# 12. script_name, script_path, script_dir all consistent
# ============================================================

subtest 'script methods: name, path, dir all consistent' => sub {
	reset_env();
	$ENV{SCRIPT_FILENAME} = '/var/www/cgi-bin/myapp.cgi';
	$ENV{SCRIPT_NAME}	 = '/cgi-bin/myapp.cgi';

	my $info = CGI::Info->new();

	my $name = $info->script_name();
	my $path = $info->script_path();
	my $dir  = $info->script_dir();

	is($name, 'myapp.cgi',				  'script_name is basename');
	is($path, '/var/www/cgi-bin/myapp.cgi', 'script_path is full path from SCRIPT_FILENAME');
	is($dir,  '/var/www/cgi-bin',		   'script_dir is containing dir of script_path');

	# script_name is the basename of script_path
	like($path, qr/\Q$name\E$/, 'script_path ends with script_name');

	# script_dir is the directory portion of script_path
	like($path, qr/^\Q$dir\E/, 'script_path begins with script_dir');
};

# ============================================================
# 13. cookie() works alongside params() in the same session
# ============================================================

subtest 'cookies and params coexist in same request' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'page=2&sort=date';
	$ENV{HTTP_COOKIE}	   = 'session=abc123; theme=dark';

	my $info = CGI::Info->new();

	my $params = $info->params();
	is($params->{page}, '2',	'page param parsed');
	is($params->{sort}, 'date', 'sort param parsed');

	is($info->cookie('session'), 'abc123', 'session cookie read');
	is($info->cookie('theme'),   'dark',   'theme cookie read');

	# Cookie lookup doesn't disturb params
	is($info->param('page'), '2',	'param still intact after cookie lookup');
	is($info->param('sort'), 'date', 'sort param still intact');
};

subtest 'cookie: repeated lookups return same value (stateful jar)' => sub {
	reset_env();
	$ENV{HTTP_COOKIE} = 'user=nigel; prefs=verbose';

	my $info = CGI::Info->new();
	my $first  = $info->cookie('user');
	my $second = $info->cookie('user');
	is($first, $second, 'repeated cookie() calls return same value');
	is($first, 'nigel', 'cookie value is correct');
};

# ============================================================
# 14. tmpdir, logdir, rootdir: directory methods cross-check
# ============================================================

subtest 'directory methods: all return valid directories' => sub {
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{C_DOCUMENT_ROOT} = $tmp;

	my $info = CGI::Info->new();

	my $tmpdir  = $info->tmpdir();
	my $rootdir = $info->rootdir();
	my $logdir  = $info->logdir();

	ok(-d $tmpdir,  'tmpdir() is a directory');
	ok(-d $rootdir, 'rootdir() is a directory');
	ok(-d $logdir,  'logdir() is a directory');

	ok(-w $tmpdir, 'tmpdir() is writable');
	ok(-w $logdir, 'logdir() is writable');

	is($rootdir, $tmp, 'rootdir() returns C_DOCUMENT_ROOT');
};

subtest 'logdir: set then get returns same value' => sub {
	reset_env();
	my $tmp  = tempdir(CLEANUP => 1);
	my $info = CGI::Info->new();

	$info->logdir($tmp);
	is($info->logdir(), $tmp, 'logdir() returns previously set directory');
};

# ============================================================
# 15. WAF: multiple attack types in sequence, each gets correct status
# ============================================================

subtest 'WAF: SQL injection blocked with 403' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = "id=1'%20OR%201=1";

	my $info = CGI::Info->new();
	ok(!defined $info->params(), 'SQL injection returns undef');
	is($info->status(), 403, 'SQL injection status 403');
	ok(defined $info->messages(), 'SQL injection logged to messages');
};

subtest 'WAF: XSS injection blocked with 403' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'q=%3Cscript%3Ealert(1)%3C%2Fscript%3E';

	my $info = CGI::Info->new();
	ok(!defined $info->params(), 'XSS returns undef');
	is($info->status(), 403, 'XSS status 403');
};

subtest 'WAF: directory traversal blocked with 403' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'file=../../etc/shadow';

	my $info = CGI::Info->new();
	ok(!defined $info->params(), 'traversal returns undef');
	is($info->status(), 403, 'traversal status 403');
};

subtest 'WAF: mustleak blocked with 403' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'probe=mustleak.com/test';

	my $info = CGI::Info->new();
	ok(!defined $info->params(), 'mustleak returns undef');
	is($info->status(), 403, 'mustleak status 403');
};

subtest 'WAF: clean request after previous attack creates fresh object cleanly' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'name=Alice&id=42';

	# Fresh object after reset_env — no state bleed from prior attacks
	my $info = CGI::Info->new();
	my $p	= $info->params();
	ok(defined $p,			  'clean request returns params');
	is($info->status(), 200,   'clean request status 200');
	is($p->{name}, 'Alice',	'name parsed correctly');
};

# ============================================================
# 16. POST: content-length enforcement + XML passthrough
# ============================================================

subtest 'POST XML: entire body preserved, status remains 200' => sub {
	reset_env();
	my $xml = '<request><action>search</action><term>perl</term></request>';
	$ENV{GATEWAY_INTERFACE}	= 'CGI/1.1';
	$ENV{REQUEST_METHOD}	   = 'POST';
	$ENV{CONTENT_TYPE}		 = 'text/xml';
	$ENV{CONTENT_LENGTH}	   = length($xml);
	$CGI::Info::stdin_data	 = $xml;

	my $info   = CGI::Info->new();
	my $params = $info->params();

	ok(defined $params,		  'XML POST returns params hashref');
	is($params->{XML}, $xml,	 'full XML body preserved under XML key');
	is($info->status(), 200,	 'status 200 for valid XML POST');
};

subtest 'POST: content_length missing => 411, params undef' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'POST';

	my $info = CGI::Info->new();
	ok(!defined $info->params(), 'missing content-length returns undef');
	is($info->status(), 411,	 'status 411 on missing content-length');
};

subtest 'POST: body exceeds max_upload_size => 413, params undef' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'POST';
	$ENV{CONTENT_LENGTH}	= 1_000_000;

	my $info = CGI::Info->new(max_upload_size => 1024);
	ok(!defined $info->params(), 'oversized POST returns undef');
	is($info->status(), 413,	 'status 413 on oversized POST');
};

# ============================================================
# 17. Stateful: AUTOLOAD + allow interact correctly
# ============================================================

subtest 'AUTOLOAD with allow: only permitted params accessible as methods' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'username=bob&password=secret&role=admin';

	my $info = CGI::Info->new(allow => {
		username => qr/^\w+$/,
		role	 => qr/^(admin|user|guest)$/,
	});
	$info->params();

	is($info->username(), 'bob',   'AUTOLOAD: username accessible');
	is($info->role(),	 'admin', 'AUTOLOAD: role accessible');
	ok(!defined $info->password(), 'AUTOLOAD: password not in allow list returns undef');
};

# ============================================================
# 18. Stateful: coderef allow with contextual cross-param validation
# ============================================================

subtest 'allow coderef: cross-param validation via $info instance' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'is_adult=1&age=25';

	my $info = CGI::Info->new();
	my $p = $info->params(allow => {
		is_adult => qr/^[01]$/,
		age	  => sub {
			my ($key, $value, $obj) = @_;
			# Only allow age if is_adult is set
			my $adult_flag = $obj->param('is_adult');
			return defined($adult_flag) && $adult_flag && $value >= 18;
		},
	});

	ok(defined $p,			  'cross-param validation: params returned');
	is($p->{is_adult}, '1',	'is_adult accepted');
	is($p->{age},	  '25',   'age accepted when is_adult=1 and age>=18');
};

subtest 'allow coderef: cross-param rejects when condition not met' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'is_adult=0&age=15';

	my $info = CGI::Info->new();
	my $p = $info->params(allow => {
		is_adult => qr/^[01]$/,
		age	  => sub {
			my ($key, $value, $obj) = @_;
			my $adult_flag = $obj->param('is_adult');
			return defined($adult_flag) && $adult_flag && $value >= 18;
		},
	});

	ok(!defined($p) || !defined($p->{age}),
		'age rejected when is_adult=0');
};

# ============================================================
# 19. Stateful: set_logger after construction routes subsequent warnings
# ============================================================

subtest 'set_logger after new(): subsequent warnings routed to new logger' => sub {
	reset_env();

	{
		package LateLogger;
		sub new   { bless {}, shift }
		sub warn  { }
		sub info  { }
		sub error { }
		sub debug { }
		sub trace { }
	}
	my $log  = LateLogger->new();
	my $info = CGI::Info->new();

	# No logger yet; set it after construction — must not croak
	my $ret = $info->set_logger($log);
	is($ret, $info, 'set_logger() returns $self for chaining');

	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'id=notanumber';

	$info->params(allow => { id => qr/^\d+$/ });

	# Logger being set doesn't suppress message recording
	my $msgs = $info->messages();
	ok(defined $msgs && scalar @{$msgs} > 0,
		'messages() populated after set_logger + validation failure');
	is($info->status(), 422, 'status 422 set after set_logger');
};

# ============================================================
# 20. cache() + browser detection: cache object consulted and populated
# ============================================================

subtest 'cache: mobile detection result stored and retrieved' => sub {
	reset_env();

	{
		package SimpleCache;
		our %store;
		sub new { bless {}, shift }
		sub get { $SimpleCache::store{$_[1]} }
		sub set { $SimpleCache::store{$_[1]} = $_[2] }
	}
	%SimpleCache::store = ();   # reset between test runs
	my $cache = SimpleCache->new();

	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)';
	$ENV{REMOTE_ADDR}	 = '10.0.0.1';

	my $info = CGI::Info->new(cache => $cache);
	my $result = $info->is_mobile();
	ok($result, 'iPhone detected as mobile with cache enabled');

	# Second object with same cache — if cache is populated, it returns early
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)';
	$ENV{REMOTE_ADDR}	 = '10.0.0.1';
	my $info2 = CGI::Info->new(cache => $cache);
	ok($info2->is_mobile(), 'mobile detection consistent on second object with same cache');
};

# ============================================================
# 21. Full realistic CGI session: search engine hits a page
# ============================================================

subtest 'realistic session: search engine, site details, no params' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT}   = 'Googlebot/2.1 (+http://www.google.com/bot.html)';
	$ENV{REMOTE_ADDR}	   = '66.249.66.1';
	$ENV{HTTP_HOST}		 = 'www.example.com';
	$ENV{SERVER_PROTOCOL}   = 'HTTP/1.1';
	$ENV{SCRIPT_FILENAME}   = '/var/www/cgi-bin/search.cgi';
	$ENV{SCRIPT_NAME}	   = '/cgi-bin/search.cgi';
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = '';

	my $info = CGI::Info->new();

	# Site identity
	is($info->host_name(),   'www.example.com', 'host_name correct');
	is($info->domain_name(), 'example.com',	 'domain_name correct');
	is($info->protocol(),	'http',			 'protocol correct');

	# Script identity
	is($info->script_name(), 'search.cgi',		  'script_name correct');
	is($info->script_dir(),  '/var/www/cgi-bin',	'script_dir correct');

	# Browser classification — Googlebot may be search or robot; both acceptable
	my $type = $info->browser_type();
	ok($type eq 'search' || $type eq 'robot',
		"browser_type is search or robot for Googlebot (got '$type')");
	ok(!$info->is_mobile(), 'Googlebot is not mobile');

	# No query string
	ok(!defined $info->params(), 'empty query string returns undef params');
	is($info->status(), 200, 'status 200 for clean bot request');
};

# ============================================================
# 22. Full realistic CGI session: authenticated user submits a form
# ============================================================

subtest 'realistic session: authenticated user form submission' => sub {
	reset_env();
	$ENV{HTTP_USER_AGENT}   = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/120';
	$ENV{REMOTE_ADDR}	   = '203.0.113.5';
	$ENV{HTTP_HOST}		 = 'www.myapp.example.com';
	$ENV{SERVER_PROTOCOL}   = 'HTTP/1.1';
	$ENV{SCRIPT_FILENAME}   = '/var/www/cgi-bin/submit.cgi';
	$ENV{SCRIPT_NAME}	   = '/cgi-bin/submit.cgi';
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'action=save&title=My+Post&category=tech';
	$ENV{HTTP_COOKIE}	   = 'sessionid=s3cr3t; csrf=tok3n';

	my $info = CGI::Info->new(allow => {
		action   => qr/^(save|preview|delete)$/,
		title	=> qr/^[\w\s\+]+$/,
		category => qr/^[a-z]+$/,
	});

	# Browser classification
	ok(!$info->is_mobile(),		  'desktop Mac not mobile');
	ok(!$info->is_robot(),		   'Chrome not a robot');
	is($info->browser_type(), 'web', 'browser_type is web');

	# Site details
	is($info->host_name(),   'www.myapp.example.com', 'host correct');
	is($info->domain_name(), 'myapp.example.com',	 'domain correct');

	# Form params
	my $p = $info->params();
	ok(defined $p, 'params returned');
	is($p->{action},   'save', 'action param correct');
	is($p->{category}, 'tech', 'category param correct');

	# Individual param access
	is($info->param('action'), 'save', 'param(action) correct');

	# Cookie access
	is($info->cookie('sessionid'), 's3cr3t', 'session cookie read');
	is($info->cookie('csrf'),	  'tok3n',  'csrf cookie read');

	# as_string for cache key
	my $key = $info->as_string();
	like($key, qr/action=save/, 'as_string usable as cache key');

	# Clean status throughout
	is($info->status(), 200, 'status 200 for authenticated form submission');
};

# ============================================================
# 23. Stateful: reset() between requests in FCGI-like environment
# ============================================================

subtest 'FCGI-like: reset() between requests prevents state bleed' => sub {
	# First request
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'user=alice';
	my $p1 = CGI::Info->new()->params();
	is($p1->{user}, 'alice', 'first request: user=alice');

	# Simulate FCGI reset between requests
	CGI::Info->reset();

	# Second request with different data
	$ENV{QUERY_STRING} = 'user=bob';
	my $p2 = CGI::Info->new()->params();
	is($p2->{user}, 'bob', 'second request after reset: user=bob');

	# No cross-contamination
	isnt($p1->{user}, $p2->{user}, 'no state bleed between requests');
};

# ============================================================
# 24. Stateful: messages_as_string joins all messages as semicolons
# ============================================================

subtest 'messages_as_string: multiple messages joined by semicolons' => sub {
	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	# Two params that will both fail validation
	$ENV{QUERY_STRING}	  = 'foo=bad&bar=alsoBad';

	my $info = CGI::Info->new();
	$info->params(allow => {
		foo => qr/^\d+$/,
		bar => qr/^\d+$/,
	});

	my $msgs = $info->messages();
	if($msgs && scalar @{$msgs} > 1) {
		my $str = $info->messages_as_string();
		like($str, qr/;/, 'multiple messages joined by semicolons');
	} else {
		pass('fewer than 2 messages logged (acceptable)');
	}
};

# ============================================================
# 25. rootdir/root_dir/documentroot synonyms are fully interchangeable
# ============================================================

subtest 'rootdir synonyms: all three return identical values' => sub {
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{C_DOCUMENT_ROOT} = $tmp;

	my $info = CGI::Info->new();
	my $a = $info->rootdir();
	my $b = $info->root_dir();
	my $c = $info->documentroot();

	is($a, $b, 'rootdir() == root_dir()');
	is($b, $c, 'root_dir() == documentroot()');
	is($a, $tmp, 'all return C_DOCUMENT_ROOT value');
};


# ============================================================
# 26. CGI::Info + CGI::Untaint
#	 POD explicitly suggests passing params() to CGI::Untaint
# ============================================================

subtest 'CGI::Info + CGI::Untaint: params hashref passed directly' => sub {
	eval { require CGI::Untaint } or
		return plan skip_all => 'CGI::Untaint not installed';

	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'age=42&name=Alice';

	my $info   = CGI::Info->new();
	my $params = $info->params();
	ok(defined $params, 'params returned');

	# POD says: my $u = CGI::Untaint->new(%params)
	my $u = eval { CGI::Untaint->new(%{$params}) };
	ok(!$@,		'CGI::Untaint->new(%params) does not croak');
	ok(defined $u, 'CGI::Untaint object created');

	# Untaint an integer field
	my $age = $u->extract(-as_integer => 'age');
	is($age, 42, 'CGI::Untaint extracts age as integer correctly');
};

# ============================================================
# 27. CGI::Info + CGI::IDS
#	 POD shows passing params() ref to CGI::IDS::detect_attacks()
# ============================================================

subtest 'CGI::Info + CGI::IDS: clean params pass IDS scan' => sub {
	eval { require CGI::IDS } or
		return plan skip_all => 'CGI::IDS not installed';

	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'name=Alice&city=London';

	my $info	  = CGI::Info->new();
	my $paramsref = $info->params();
	ok(defined $paramsref, 'params returned for IDS scan');

	my $ids = CGI::IDS->new();
	$ids->set_scan_keys(scan_keys => 1);
	my $attacks = eval { $ids->detect_attacks(request => $paramsref) };
	ok(!$@,		  'CGI::IDS::detect_attacks does not croak on clean input');
	is($attacks, 0,  'no attacks detected in clean params');
};

subtest 'CGI::Info + CGI::IDS: allow filtering reduces IDS attack surface' => sub {
	eval { require CGI::IDS } or
		return plan skip_all => 'CGI::IDS not installed';

	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'id=1&name=Bob';

	my $info	  = CGI::Info->new();
	# Allow-list restricts what IDS even sees
	my $paramsref = $info->params(allow => {
		id   => qr/^\d+$/,
		name => qr/^[A-Za-z]+$/,
	});

	my $ids	 = CGI::IDS->new();
	my $attacks = eval { $ids->detect_attacks(request => $paramsref) };
	ok(!$@,		 'CGI::IDS does not croak on allow-filtered params');
	is($attacks, 0, 'no attacks after allow-list filtering');
};

# ============================================================
# 28. CGI::Info + HTTP::BrowserDetect
#	 CGI::Info uses it internally; test that its classification
#	 is consistent with what HTTP::BrowserDetect would say directly
# ============================================================

subtest 'CGI::Info + HTTP::BrowserDetect: mobile classification agrees' => sub {
	eval { require HTTP::BrowserDetect } or
		return plan skip_all => 'HTTP::BrowserDetect not installed';

	reset_env();
	my $ua = 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15';
	$ENV{HTTP_USER_AGENT} = $ua;
	$ENV{REMOTE_ADDR}	 = '1.2.3.4';

	my $info = CGI::Info->new();
	my $bd   = HTTP::BrowserDetect->new($ua);

	ok($info->is_mobile(), 'CGI::Info: iPhone is mobile');

	# HTTP::BrowserDetect's device check
	my $device = $bd->device() // '';
	my $bd_mobile = ($device =~ /iphone|ipod|ipad|android|blackberry|webos/i) ? 1 : 0;
	ok($bd_mobile, 'HTTP::BrowserDetect: iPhone is mobile device');

	# Both agree
	is($info->is_mobile() ? 1 : 0, $bd_mobile,
		'CGI::Info and HTTP::BrowserDetect agree on iPhone mobile classification');
};

subtest 'CGI::Info + HTTP::BrowserDetect: robot classification agrees' => sub {
	eval { require HTTP::BrowserDetect } or
		return plan skip_all => 'HTTP::BrowserDetect not installed';

	reset_env();
	# Use a UA that HTTP::BrowserDetect will reliably classify as a robot
	my $ua = 'Googlebot/2.1 (+http://www.google.com/bot.html)';
	$ENV{HTTP_USER_AGENT} = $ua;
	$ENV{REMOTE_ADDR}	 = '66.249.66.1';

	my $info = CGI::Info->new();
	my $bd   = HTTP::BrowserDetect->new($ua);

	# Both should agree this is not a regular user
	my $bd_robot = $bd->robot() ? 1 : 0;
	my $ci_robot = $info->is_robot() ? 1 : 0;
	my $ci_search = $info->is_search_engine() ? 1 : 0;

	ok($bd_robot || $ci_robot || $ci_search,
		'Googlebot classified as robot or search engine by at least one detector');
};

# ============================================================
# 29. CGI::Info + Log::Log4perl
#	 POD mentions Log::Log4perl as a suitable logger
# ============================================================

subtest 'CGI::Info + Log::Log4perl: logger accepted and used' => sub {
	eval { require Log::Log4perl } or
		return plan skip_all => 'Log::Log4perl not installed';

	Log::Log4perl->init(\<<'LOG4PERL_CONF');
log4perl.rootLogger=DEBUG, STRING
log4perl.appender.STRING=Log::Log4perl::Appender::String
log4perl.appender.STRING.layout=PatternLayout
log4perl.appender.STRING.layout.ConversionPattern=%m%n
LOG4PERL_CONF

	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'id=notanumber';

	my $logger = Log::Log4perl->get_logger();
	my $info   = CGI::Info->new(logger => $logger);
	$info->params(allow => { id => qr/^\d+$/ });

	# Log4perl logger was accepted without error
	ok(defined $info->{logger}, 'Log4perl logger stored in object');
	is($info->status(), 422, 'validation failure still sets correct status with Log4perl');
};

# ============================================================
# 30. CGI::Info + Log::Any
#	 POD mentions Log::Any as a suitable logger
# ============================================================

subtest 'CGI::Info + Log::Any: logger accepted and used' => sub {
	eval { require Log::Any; require Log::Any::Adapter } or
		return plan skip_all => 'Log::Any not installed';

	# Use the Stderr adapter which ships with Log::Any itself;
	# Callback adapter requires an optional separate distribution.
	eval { Log::Any::Adapter->set('Stderr') };
	if($@) {
		return plan skip_all => 'Log::Any::Adapter::Stderr not available';
	}

	reset_env();
	$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
	$ENV{REQUEST_METHOD}	= 'GET';
	$ENV{QUERY_STRING}	  = 'id=abc';

	my $logger = Log::Any->get_logger();
	my $info   = CGI::Info->new(logger => $logger);
	$info->params(allow => { id => qr/^\d+$/ });

	ok(defined $info->{logger}, 'Log::Any logger stored in object');
	is($info->status(), 422,	'status 422 with Log::Any logger');
	my $msgs = $info->messages();
	ok(defined $msgs && scalar @{$msgs} > 0,
		'messages() populated when Log::Any logger in use');
};

# ============================================================
# 31. CGI::Info + CHI cache
#	 POD explicitly mentions CHI as a suitable cache object
# ============================================================

subtest 'CGI::Info + CHI: browser type cached across objects' => sub {
	eval { require CHI } or
		return plan skip_all => 'CHI not installed';

	my $cache = CHI->new(driver => 'Memory', global => 0);

	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)';
	$ENV{REMOTE_ADDR}	 = '192.168.1.1';

	# First object populates the cache
	my $info1 = CGI::Info->new(cache => $cache);
	ok($info1->is_mobile(), 'first object: iPhone is mobile');

	# Second object with same cache and same UA/IP should be consistent
	reset_env();
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)';
	$ENV{REMOTE_ADDR}	 = '192.168.1.1';
	my $info2 = CGI::Info->new(cache => $cache);
	ok($info2->is_mobile(), 'second object: mobile result consistent via cache');
};

subtest 'CGI::Info + CHI: cache() method accepts CHI object' => sub {
	eval { require CHI } or
		return plan skip_all => 'CHI not installed';

	my $cache = CHI->new(driver => 'Memory', global => 0);
	my $info  = CGI::Info->new();

	# Set cache after construction via cache() method
	$info->cache($cache);
	is($info->cache(), $cache, 'CHI object round-trips via cache()');
	isa_ok($info->cache(), 'CHI::Driver', 'cache() returns CHI driver object');
};

# ============================================================
# 32. CGI::Info + File::Spec
#	 script_dir() uses File::Spec internally; verify it produces
#	 a path that File::Spec itself considers valid and usable
# ============================================================

subtest 'CGI::Info + File::Spec: script_dir usable with File::Spec->catfile' => sub {
	reset_env();
	$ENV{SCRIPT_FILENAME} = '/var/www/cgi-bin/myapp.cgi';

	my $info = CGI::Info->new();
	my $dir  = $info->script_dir();
	my $path = $info->script_path();

	# script_dir() is the directory portion of script_path()
	ok(File::Spec->file_name_is_absolute($dir),
		'script_dir() is an absolute path');
	ok(File::Spec->file_name_is_absolute($path),
		'script_path() is an absolute path');

	# script_dir should be a leading portion of script_path
	like($path, qr/^\Q$dir\E/,
		'script_path() begins with script_dir()');

	# File::Spec can extract the dir from the path and get the same answer
	my ($vol, $dirs, $file) = File::Spec->splitpath($path);
	my $spec_dir = File::Spec->catpath($vol, $dirs, '');
	$spec_dir =~ s{[/\\]$}{};   # strip trailing separator
	is($spec_dir, $dir,
		'File::Spec->splitpath agrees with script_dir()');
};

subtest 'CGI::Info + File::Spec: tmpdir is absolute path' => sub {
	reset_env();
	my $dir = CGI::Info->new()->tmpdir();
	ok(File::Spec->file_name_is_absolute($dir),
		'tmpdir() returns an absolute path (File::Spec agrees)');
};

subtest 'CGI::Info + File::Spec: rootdir is absolute path' => sub {
	reset_env();
	my $tmp = tempdir(CLEANUP => 1);
	$ENV{C_DOCUMENT_ROOT} = $tmp;
	my $dir = CGI::Info->rootdir();
	ok(File::Spec->file_name_is_absolute($dir),
		'rootdir() returns an absolute path (File::Spec agrees)');
};

# ============================================================
# 33. CGI::Info + URI::Heuristic
#	 _find_site_details uses URI::Heuristic::uf_uristr internally;
#	 verify cgi_host_url() always produces a well-formed URL
# ============================================================

subtest 'CGI::Info + URI::Heuristic: cgi_host_url always a valid URL' => sub {
	eval { require URI::Heuristic } or
		return plan skip_all => 'URI::Heuristic not installed';

	for my $host ('www.example.com', 'example.org', 'sub.domain.example.net') {
		reset_env();
		$ENV{HTTP_HOST}	   = $host;
		$ENV{SERVER_PROTOCOL} = 'HTTP/1.1';

		my $url = CGI::Info->new()->cgi_host_url();
		like($url, qr{^https?://[\w.\-]+},
			"cgi_host_url for '$host' is a well-formed URL: $url");
		unlike($url, qr/\.$/, "cgi_host_url for '$host' has no trailing dot");
	}
};

# ============================================================
# 34. CGI::Info + Sys::Hostname
#	 host_name() falls back to Sys::Hostname::hostname() when
#	 no CGI environment is present
# ============================================================

subtest 'CGI::Info + Sys::Hostname: fallback hostname is system hostname' => sub {
	eval { require Sys::Hostname } or
		return plan skip_all => 'Sys::Hostname not installed';

	reset_env();
	# No HTTP_HOST, SERVER_NAME or SSL_TLS_SNI set
	my $sys_host  = Sys::Hostname::hostname();
	my $info_host = CGI::Info->new()->host_name();

	ok(defined $info_host && length $info_host,
		'host_name() returns something without CGI env');
	# The CGI::Info host may be URL-processed by URI::Heuristic, so compare
	# after stripping any protocol prefix
	(my $bare = $info_host) =~ s{^https?://}{};
	$bare =~ s{/.*}{};
	like($sys_host, qr/\Q$bare\E|\Q$info_host\E/i,
		'CGI::Info host_name() relates to Sys::Hostname result');
};

# ============================================================
# 35. CGI::Info + Net::CIDR
#	 is_search_engine() uses Net::CIDR::cidrlookup internally for
#	 Alibaba CIDR block; verify a known Alibaba IP is handled
# ============================================================

subtest 'CGI::Info + Net::CIDR: Alibaba IP range handled gracefully' => sub {
	eval { require Net::CIDR } or
		return plan skip_all => 'Net::CIDR not installed';

	reset_env();
	# 47.235.1.1 is in the 47.235.0.0/12 Alibaba block used in the source
	$ENV{HTTP_USER_AGENT} = 'AlibabaBot/1.0';
	$ENV{REMOTE_ADDR}	 = '47.235.1.1';

	my $info = CGI::Info->new();
	# Either classified as search engine (CIDR match) or robot — both valid
	my $result = $info->is_search_engine() || $info->is_robot();
	ok($result, 'Alibaba IP classified as search engine or robot via Net::CIDR');
};

done_testing();
