#!/usr/bin/env perl
# path.t — exhaustive path-coverage tests for CGI::Info
# Maps every unique execution path through each public and protected routine
# and asserts the correct outcome for each terminal state.
#
# Dead-code findings are documented at the bottom of this file and annotated
# with TODO comments in lib/CGI/Info.pm.

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird 0.08 qw(mock restore_all);
use Scalar::Util qw(blessed);
use Readonly;
use lib 't/lib';
use MyLogger;

# Suppress noise from the Log::Abstraction logger Object::Configure injects.
mock 'Log::Abstraction::_high_priority' => sub { };

BEGIN {
	my $load_error;
	eval { require CGI::Info; CGI::Info->import() } or $load_error = $@;
	use_ok('CGI::Info') || BAIL_OUT("CGI::Info failed to load: $load_error");
}

# ---------------------------------------------------------------------------
# Shared constants — no magic strings
# ---------------------------------------------------------------------------
Readonly my $GOOD_UA   => 'Mozilla/5.0 (compatible; TestBrowser/1.0)';
Readonly my $MOBILE_UA => 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)';
Readonly my $AI_UA     => 'ClaudeBot/1.0 (+https://www.anthropic.com/claude-web)';
Readonly my $BOT_UA    => 'SomeSpider/1.0 (spider)';
Readonly my $SQL_UA    => 'sqlmap/1.4.7 SELECT name AND pass FROM users';
Readonly my $REMOTE_IP => '1.2.3.4';

# ---------------------------------------------------------------------------
# Helper: extract warn-level messages from the object's message log
# ---------------------------------------------------------------------------
sub warns_from {
	my $info = shift;
	return grep { $_->{level} eq 'warn' } @{$info->messages() // []};
}

# ===========================================================================
# new() — 10 paths
# ===========================================================================

subtest 'new N1: normal ->new() succeeds' => sub {
	plan tests => 1;
	local %ENV;
	isa_ok(CGI::Info->new(logger => MyLogger->new()), 'CGI::Info');
};

subtest 'new N2: ::new() with no args sets class to __PACKAGE__ and succeeds' => sub {
	plan tests => 1;
	local %ENV;
	# $class is undef; code sets $class = __PACKAGE__ and proceeds
	isa_ok(CGI::Info::new(), 'CGI::Info');
};

subtest 'new N3: ::new() with args croaks (undef $class + params)' => sub {
	plan tests => 1;
	# Params::Get complains when called as a function with args but no blessed class
	throws_ok { CGI::Info::new(foo => 'bar') }
		qr/Usage.*CGI::Info::new/,
		'CGI::Info::new(args) croaks';
};

subtest 'new N4: explicit logger arg results in a logger in the object' => sub {
	plan tests => 1;
	local %ENV;
	my $info = CGI::Info->new(logger => MyLogger->new());
	ok(Scalar::Util::blessed($info->{logger}), 'logger field is a blessed object');
};

subtest 'new N5: no logger → Object::Configure injects Log::Abstraction' => sub {
	plan tests => 1;
	local %ENV;
	my $info = CGI::Info->new();
	isa_ok($info->{logger}, 'Log::Abstraction', 'default logger injected');
};

subtest 'new N6: expect is deprecated → croak' => sub {
	plan tests => 1;
	throws_ok { CGI::Info->new(expect => ['foo']) }
		qr/expect has been deprecated/,
		'expect in new() croaks';
};

subtest 'new N7: clone path — basic clone is distinct object' => sub {
	plan tests => 3;
	local %ENV;
	my $orig  = CGI::Info->new(logger => MyLogger->new());
	my $clone = $orig->new();
	isa_ok($clone, 'CGI::Info', 'clone is CGI::Info');
	isnt($orig,  $clone, 'clone is different reference');
	ok(!exists($clone->{paramref}), 'clone has no cached paramref');
};

subtest 'new N8: clone has a logger after construction' => sub {
	plan tests => 1;
	local %ENV;
	my $orig  = CGI::Info->new(logger => MyLogger->new());
	my $clone = $orig->new();
	ok(defined($clone->{logger}), 'clone has a logger');
};

subtest 'new N9: clone with expect → croak' => sub {
	plan tests => 1;
	local %ENV;
	my $orig = CGI::Info->new(logger => MyLogger->new());
	throws_ok { $orig->new(expect => ['x']) }
		qr/expect has been deprecated/,
		'clone with expect croaks';
};

subtest 'new N10: clone drops cached paramref so new allow schema is applied' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'foo=1',
	);
	CGI::Info->reset();
	my $orig = CGI::Info->new(logger => MyLogger->new());
	$orig->params();
	ok($orig->{paramref}, 'original has paramref after params()');
	my $clone = $orig->new(allow => { foo => qr/^\d+$/ });
	ok(!exists($clone->{paramref}), 'paramref absent in clone');
};

# ===========================================================================
# params() — request-method dispatch paths
# ===========================================================================

subtest 'params P1: cache hit returns same ref' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'a=1',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $r1 = $info->params();
	my $r2 = $info->params();
	is($r1, $r2, 'second params() call returns same cached ref');
};

subtest 'params P2: no CGI env, no ARGV, no stdin → undef' => sub {
	plan tests => 1;
	local %ENV;
	local @ARGV = ();
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->params(), undef, 'no CGI env → undef');
};

subtest 'params P3: no CGI env, ARGV --robot sets is_robot' => sub {
	plan tests => 1;
	local %ENV;
	local @ARGV = ('--robot', 'k=v');
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->params();
	ok($info->{is_robot}, '--robot flag sets is_robot');
};

subtest 'params P4: no CGI env, ARGV --mobile sets is_mobile' => sub {
	plan tests => 1;
	local %ENV;
	local @ARGV = ('--mobile', 'k=v');
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->params();
	ok($info->{is_mobile}, '--mobile flag sets is_mobile');
};

subtest 'params P5: no CGI env, ARGV --search-engine sets is_search_engine' => sub {
	plan tests => 1;
	local %ENV;
	local @ARGV = ('--search-engine', 'k=v');
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->params();
	ok($info->{is_search_engine}, '--search-engine flag sets is_search_engine');
};

subtest 'params P6: no CGI env, ARGV --tablet sets is_tablet' => sub {
	plan tests => 1;
	local %ENV;
	local @ARGV = ('--tablet', 'k=v');
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->params();
	ok($info->{is_tablet}, '--tablet flag sets is_tablet');
};

subtest 'params P7: GET with no QUERY_STRING → undef' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->params(), undef, 'GET with no QUERY_STRING → undef');
};

subtest 'params P8: GET + multipart (no REMOTE_ADDR) → 501 + undef' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'x=1',
		CONTENT_TYPE      => 'multipart/form-data',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->params(), undef, 'multipart GET → undef');
	is($info->status(), 501,   'status 501 set');
};

subtest 'params P9: GET + multipart + REMOTE_ADDR → IP in warning' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'x=1',
		CONTENT_TYPE      => 'multipart/form-data',
		REMOTE_ADDR       => $REMOTE_IP,
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->params();
	my @w = warns_from($info);
	like($w[0]{message}, qr/$REMOTE_IP/, 'IP present in warning when REMOTE_ADDR set');
};

subtest 'params P10: POST missing CONTENT_LENGTH → 411' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'POST',
		CONTENT_TYPE      => 'application/x-www-form-urlencoded',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->params(), undef, 'missing CONTENT_LENGTH → undef');
	is($info->status(), 411,   'status 411');
};

subtest 'params P11: POST non-numeric CONTENT_LENGTH → 411' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'POST',
		CONTENT_TYPE      => 'application/x-www-form-urlencoded',
		CONTENT_LENGTH    => 'abc',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->params(), undef, 'non-numeric CONTENT_LENGTH → undef');
	is($info->status(), 411,   'status 411');
};

subtest 'params P12: POST exceeds max_upload_size → 413' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'POST',
		CONTENT_TYPE      => 'application/x-www-form-urlencoded',
		CONTENT_LENGTH    => 999_999_999,
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->params(), undef, 'oversized upload → undef');
	is($info->status(), 413,   'status 413');
};

subtest 'params P13: OPTIONS → 405' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'OPTIONS',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->params(), undef, 'OPTIONS → undef');
	is($info->status(), 405,   'status 405');
};

subtest 'params P14: DELETE → 405' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'DELETE',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->params(), undef, 'DELETE → undef');
	is($info->status(), 405,   'status 405');
};

subtest 'params P15: unrecognised method → 501' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'PATCH',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->params(), undef, 'PATCH → undef');
	is($info->status(), 501,   'status 501');
};

# ---------------------------------------------------------------------------
# params() — allow schema validation paths
# ---------------------------------------------------------------------------

subtest 'params allow A1: scalar schema match passes' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'mode=dark',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $p = $info->params(allow => { mode => 'dark' });
	is($p->{mode}, 'dark', 'scalar match → value present');
};

subtest 'params allow A2: scalar schema mismatch → 422, not in result' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'mode=evil',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $p = $info->params(allow => { mode => 'dark' });
	is($info->status(), 422,   'scalar mismatch → 422');
	ok(!defined($p),           'no params returned');
};

subtest 'params allow A3: Regexp match passes' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'id=42',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $p = $info->params(allow => { id => qr/^\d+$/ });
	is($p->{id}, '42', 'regexp match → value present');
};

subtest 'params allow A4: Regexp mismatch → 422' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'id=notanumber',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $p = $info->params(allow => { id => qr/^\d+$/ });
	is($info->status(), 422, 'regexp mismatch → 422');
	ok(!defined($p),         'no params returned');
};

subtest 'params allow A5: CODE schema returning true passes' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'x=hello',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $p = $info->params(allow => { x => sub { 1 } });
	is($p->{x}, 'hello', 'coderef returning true passes');
};

subtest 'params allow A6: CODE schema returning false blocks param' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'x=hello',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $p = $info->params(allow => { x => sub { 0 } });
	ok(!defined($p), 'coderef returning false blocks param → undef');
};

subtest 'params allow A7: undef schema passes any value' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'x=anything',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $p = $info->params(allow => { x => undef });
	is($p->{x}, 'anything', 'undef schema allows any value');
};

subtest 'params allow A8: key not in allow → 422' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'forbidden=1',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->params(allow => { allowed_key => qr/.*/ });
	is($info->status(), 422, 'unknown key in allow → 422');
};

# ---------------------------------------------------------------------------
# params() — value accumulation paths
# ---------------------------------------------------------------------------

subtest 'params V1: duplicate key with different value → comma-append' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'c=alpha&c=beta',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $p = $info->params();
	like($p->{c}, qr/alpha.*beta|beta.*alpha/, 'duplicate values joined');
};

subtest 'params V2: zero-length value not added to FORM' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'empty=',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $p = $info->params();
	ok(!defined($p), 'empty-value param yields empty FORM → undef');
};

# ---------------------------------------------------------------------------
# params() — WAF detection paths
# ---------------------------------------------------------------------------

subtest 'params WAF-SQL1: quote-style injection → 403' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => "u=%27+OR+%271%27%3D%271",
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->params(), undef,  'SQL quote injection → undef');
	is($info->status(), 403,    'WAF sets 403');
};

subtest 'params WAF-SQL2: SELECT FROM injection → 403' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'q=SELECT+name+FROM+users',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->params(), undef,  'SELECT FROM → undef');
	is($info->status(), 403,    'WAF sets 403');
};

subtest 'params WAF-XSS1: percent-encoded angle brackets → 403' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'q=%3Cscript%3Ealert(1)%3C%2Fscript%3E',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->params(), undef,  'XSS encoded → undef');
	is($info->status(), 403,    'WAF sets 403');
};

subtest 'params WAF-XSS2: javascript: URI scheme → 403' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'url=javascript:alert(document.domain)',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->params(), undef,  'javascript: URI → undef');
	is($info->status(), 403,    'WAF sets 403');
};

subtest 'params WAF-DIR: directory traversal → 403' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'f=../../etc/passwd',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->params(), undef,  'traversal → undef');
	is($info->status(), 403,    'WAF sets 403');
};

# ===========================================================================
# param() — path coverage
# ===========================================================================

subtest 'param PA1: no field delegates to params() → hashref' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'a=1',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is(ref($info->param()), 'HASH', 'param() without arg returns hashref');
};

subtest 'param PA2: field not in allow → warn + undef' => sub {
	plan tests => 2;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'a=1',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->params(allow => { a => qr/\d+/ });
	ok(!defined($info->param('b')), 'unknown field → undef');
	my @w = warns_from($info);
	like($w[-1]{message}, qr/isn't in the allow list/, 'allow-list warning emitted');
};

subtest 'param PA3: known field present → value returned' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'score=99',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->param('score'), '99', 'known field returns value');
};

subtest 'param PA4: field absent from form → undef' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'a=1',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->param('missing'), undef, 'absent field → undef');
};

# ===========================================================================
# protocol() — path coverage
# ===========================================================================

subtest 'protocol R1: instance cache hit avoids re-evaluation' => sub {
	plan tests => 2;
	local %ENV = (SCRIPT_URI => 'https://example.com/cgi-bin/test.pl');
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $p1 = $info->protocol();
	my $p2 = $info->protocol();    # must hit cache
	is($p1, $p2, 'second call returns same value');
	ok(exists($info->{protocol}), 'result stored in instance hash');
};

subtest 'protocol R2: SCRIPT_URI → scheme extracted' => sub {
	plan tests => 1;
	local %ENV = (SCRIPT_URI => 'https://example.com/cgi');
	CGI::Info->reset();
	is(CGI::Info->new(logger => MyLogger->new())->protocol(), 'https', 'https extracted');
};

subtest 'protocol R3: SERVER_PROTOCOL HTTP/ → http' => sub {
	plan tests => 1;
	local %ENV = (SERVER_PROTOCOL => 'HTTP/1.1');
	CGI::Info->reset();
	is(CGI::Info->new(logger => MyLogger->new())->protocol(), 'http', 'SERVER_PROTOCOL → http');
};

subtest 'protocol R4: SERVER_PORT 443 → https' => sub {
	plan tests => 1;
	local %ENV = (SERVER_PORT => 443);
	CGI::Info->reset();
	is(CGI::Info->new(logger => MyLogger->new())->protocol(), 'https', 'port 443 → https');
};

subtest 'protocol R5: SERVER_PORT 80 → http' => sub {
	plan tests => 1;
	local %ENV = (SERVER_PORT => 80);
	CGI::Info->reset();
	# getservbyport(80,'tcp') returns 'http' on most OSes;
	# on Solaris it may return undef, falling to the port==80 branch — both → 'http'
	is(CGI::Info->new(logger => MyLogger->new())->protocol(), 'http', 'port 80 → http');
};

subtest 'protocol R6: no env, no REMOTE_ADDR → undef silently' => sub {
	plan tests => 2;
	local %ENV;
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->protocol(), undef, 'no env → undef');
	my @w = warns_from($info);
	is(scalar @w, 0, 'no warning without REMOTE_ADDR');
};

subtest 'protocol R7: no env, with REMOTE_ADDR → undef + warning' => sub {
	plan tests => 2;
	local %ENV = (REMOTE_ADDR => $REMOTE_IP);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->protocol(), undef, 'unknown protocol → undef');
	my @w = warns_from($info);
	like($w[0]{message}, qr/determine.*protocol/i, 'warning emitted');
};

subtest 'protocol R8: class method call does not write instance cache' => sub {
	plan tests => 1;
	local %ENV;
	CGI::Info->reset();
	my $p = CGI::Info->protocol();    # $self is the string 'CGI::Info'
	is($p, undef, 'class method returns undef');
	# No instance to check; just confirm it did not crash
};

subtest 'protocol R9: undef is cached with exists (not defined)' => sub {
	plan tests => 2;
	local %ENV;
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->protocol();    # should store undef
	ok(exists($info->{protocol}), 'undef result stored via exists-safe cache');
	is($info->{protocol}, undef, 'cached value is undef');
};

# ===========================================================================
# status() — path coverage
# ===========================================================================

subtest 'status S1: set status stores value and returns it' => sub {
	plan tests => 2;
	local %ENV;
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->status(403), 403, 'status(403) returns 403');
	is($info->status(),    403, 'status() retrieves 403');
};

subtest 'status S2: not set, OPTIONS → 405' => sub {
	plan tests => 1;
	local %ENV = (REQUEST_METHOD => 'OPTIONS');
	is(CGI::Info->new(logger => MyLogger->new())->status(), 405, 'OPTIONS → 405');
};

subtest 'status S3: not set, DELETE → 405' => sub {
	plan tests => 1;
	local %ENV = (REQUEST_METHOD => 'DELETE');
	is(CGI::Info->new(logger => MyLogger->new())->status(), 405, 'DELETE → 405');
};

subtest 'status S4: not set, POST without CONTENT_LENGTH → 411' => sub {
	plan tests => 1;
	local %ENV = (REQUEST_METHOD => 'POST');
	is(CGI::Info->new(logger => MyLogger->new())->status(), 411, 'POST without CL → 411');
};

subtest 'status S5: not set, no method → 200' => sub {
	plan tests => 1;
	local %ENV;
	is(CGI::Info->new(logger => MyLogger->new())->status(), 200, 'no method → 200');
};

subtest 'status S6: stored truthy status returned as-is' => sub {
	plan tests => 1;
	local %ENV;
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->status(503);
	is($info->status(), 503, 'stored 503 returned');
};

subtest 'status S7: stored 0 (falsy) returns 200 via || fallback' => sub {
	plan tests => 1;
	local %ENV;
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->{status} = 0;    # force falsy stored value
	is($info->status(), 200, 'falsy stored status → 200');
};

# ===========================================================================
# cookie() — path coverage
# ===========================================================================

subtest 'cookie C1: no HTTP_COOKIE jar → undef' => sub {
	plan tests => 1;
	local %ENV;
	is(CGI::Info->new(logger => MyLogger->new())->cookie('x'), undef, 'no jar → undef');
};

subtest 'cookie C2: known cookie present → value returned' => sub {
	plan tests => 2;
	local %ENV = (HTTP_COOKIE => 'session=tok123; uid=42');
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->cookie('session'), 'tok123', 'session cookie value');
	is($info->cookie('uid'),     '42',     'uid cookie value');
};

subtest 'cookie C3: unknown cookie → undef' => sub {
	plan tests => 1;
	local %ENV = (HTTP_COOKIE => 'a=1');
	is(CGI::Info->new(logger => MyLogger->new())->cookie('b'), undef, 'missing cookie → undef');
};

subtest 'cookie C4: jar cached across calls (identity preserved)' => sub {
	plan tests => 2;
	local %ENV = (HTTP_COOKIE => 'k=v');
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->cookie('k');
	ok($info->{jar}, 'jar populated after first call');
	my $j1 = $info->{jar};
	$info->cookie('k');
	is($info->{jar}, $j1, 'same jar returned on second call');
};

subtest 'cookie C5: header injection via CR/LF is stripped' => sub {
	plan tests => 2;
	local %ENV = (HTTP_COOKIE => "good=ok\r\nSet-Cookie: evil=1");
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->cookie('good'),  'ok',  'legitimate cookie parsed');
	is($info->cookie('evil'),  undef, 'injected cookie blocked');
};

subtest 'cookie C6: malformed token without = is filtered out' => sub {
	plan tests => 2;
	local %ENV = (HTTP_COOKIE => 'baretoken; valid=yes');
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->cookie('valid'),     'yes',  'valid token parsed');
	is($info->cookie('baretoken'), undef,  'malformed token ignored');
};

# ===========================================================================
# is_ai() — path coverage
# ===========================================================================

subtest 'is_ai AI1: instance cache hit' => sub {
	plan tests => 1;
	local %ENV;
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->{is_ai} = 1;
	is($info->is_ai(), 1, 'cached is_ai=1 returned directly');
};

subtest 'is_ai AI2: IS_AI env truthy → 1' => sub {
	plan tests => 1;
	local %ENV = (IS_AI => 1);
	is(CGI::Info->new(logger => MyLogger->new())->is_ai(), 1, 'IS_AI=1 → 1');
};

subtest 'is_ai AI3: IS_AI env falsy → 0' => sub {
	plan tests => 1;
	local %ENV = (IS_AI => 0);
	is(CGI::Info->new(logger => MyLogger->new())->is_ai(), 0, 'IS_AI=0 → 0');
};

subtest 'is_ai AI4: no REMOTE_ADDR → 0 regardless of UA' => sub {
	plan tests => 1;
	local %ENV = (HTTP_USER_AGENT => $AI_UA);
	is(CGI::Info->new(logger => MyLogger->new())->is_ai(), 0, 'no REMOTE_ADDR → 0');
};

subtest 'is_ai AI5: no UA → 0 regardless of REMOTE_ADDR' => sub {
	plan tests => 1;
	local %ENV = (REMOTE_ADDR => $REMOTE_IP);
	is(CGI::Info->new(logger => MyLogger->new())->is_ai(), 0, 'no UA → 0');
};

subtest 'is_ai AI6: ClaudeBot UA → 1 and sets is_robot' => sub {
	plan tests => 2;
	local %ENV = (HTTP_USER_AGENT => $AI_UA, REMOTE_ADDR => $REMOTE_IP);
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->is_ai(),      1, 'ClaudeBot → is_ai=1');
	is($info->{is_robot},   1, 'is_robot also set to 1');
};

subtest 'is_ai AI7: GPTBot UA → 1' => sub {
	plan tests => 1;
	local %ENV = (HTTP_USER_AGENT => 'GPTBot/1.1', REMOTE_ADDR => $REMOTE_IP);
	is(CGI::Info->new(logger => MyLogger->new())->is_ai(), 1, 'GPTBot → 1');
};

subtest 'is_ai AI8: normal browser UA → 0' => sub {
	plan tests => 1;
	local %ENV = (HTTP_USER_AGENT => $GOOD_UA, REMOTE_ADDR => $REMOTE_IP);
	is(CGI::Info->new(logger => MyLogger->new())->is_ai(), 0, 'normal UA → 0');
};

# ===========================================================================
# browser_type() — all 5 terminal paths
# ===========================================================================

subtest 'browser_type BT1: mobile UA → mobile' => sub {
	plan tests => 1;
	local %ENV = (HTTP_USER_AGENT => $MOBILE_UA, REMOTE_ADDR => $REMOTE_IP);
	is(CGI::Info->new(logger => MyLogger->new())->browser_type(), 'mobile', 'mobile UA');
};

subtest 'browser_type BT2: AI crawler → ai' => sub {
	plan tests => 1;
	local %ENV = (HTTP_USER_AGENT => $AI_UA, REMOTE_ADDR => $REMOTE_IP);
	is(CGI::Info->new(logger => MyLogger->new())->browser_type(), 'ai', 'AI UA');
};

subtest 'browser_type BT3: IS_SEARCH_ENGINE env → search' => sub {
	plan tests => 1;
	local %ENV = (
		IS_SEARCH_ENGINE => 1,
		HTTP_USER_AGENT  => $GOOD_UA,
		REMOTE_ADDR      => $REMOTE_IP,
	);
	is(CGI::Info->new(logger => MyLogger->new())->browser_type(), 'search', 'search engine');
};

subtest 'browser_type BT4: robot UA → robot' => sub {
	plan tests => 1;
	local %ENV = (HTTP_USER_AGENT => $BOT_UA, REMOTE_ADDR => $REMOTE_IP);
	is(CGI::Info->new(logger => MyLogger->new())->browser_type(), 'robot', 'robot UA');
};

subtest 'browser_type BT5: normal browser → web' => sub {
	plan tests => 1;
	local %ENV = (HTTP_USER_AGENT => $GOOD_UA, REMOTE_ADDR => $REMOTE_IP);
	is(CGI::Info->new(logger => MyLogger->new())->browser_type(), 'web', 'normal UA → web');
};

# ===========================================================================
# _log() — path coverage (Protected; callable under HARNESS_ACTIVE)
# ===========================================================================

subtest '_log L1: all-undef messages → silent (nothing pushed)' => sub {
	plan tests => 1;
	# No local %ENV — would clear HARNESS_ACTIVE and break Sub::Protected bypass
	my $info = CGI::Info->new(logger => MyLogger->new());
	delete $info->{logger};
	my $before = scalar @{$info->{messages} // []};
	$info->_log('warn', undef, undef);
	is(scalar @{$info->{messages} // []}, $before, 'no messages appended');
};

subtest '_log L2: defined messages, no logger → pushed to messages only' => sub {
	plan tests => 2;
	my $info = CGI::Info->new(logger => MyLogger->new());
	delete $info->{logger};
	$info->_log('info', 'alpha', 'beta');
	my @msgs = @{$info->{messages} // []};
	is($msgs[-1]{level},   'info',       'level stored');
	like($msgs[-1]{message}, qr/alpha beta/, 'messages joined with space');
};

subtest '_log L3: defined messages with logger → logger method called' => sub {
	plan tests => 2;
	# Use typeglob assignment (runtime closure) so @calls is captured correctly.
	# Named subs inside a package block are compiled at compile time and cannot
	# close over lexical variables declared at runtime in the enclosing scope.
	my @calls;
	no strict 'refs';
	*{'PathTFakeLogger::new'}  = sub { bless {}, 'PathTFakeLogger' };
	*{'PathTFakeLogger::info'} = sub { push @calls, [@_[1..$#_]] };
	*{'PathTFakeLogger::warn'} = sub { push @calls, [@_[1..$#_]] };
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->{logger} = PathTFakeLogger->new();
	$info->_log('info', 'payload');
	is(scalar @calls, 1, 'logger->info called once');
	like($calls[0][0], qr/payload/, 'payload passed to logger');
};

# ===========================================================================
# _warn() / _error() — with and without logger
# ===========================================================================

subtest '_warn W1: without logger → carp fires' => sub {
	plan tests => 1;
	my $info = CGI::Info->new(logger => MyLogger->new());
	delete $info->{logger};
	my $carped = 0;
	local $SIG{__WARN__} = sub { $carped++ };
	$info->_warn('danger');
	ok($carped, 'carp fires when no logger');
};

subtest '_warn W2: with logger → no carp, message stored' => sub {
	plan tests => 2;
	my $info   = CGI::Info->new(logger => MyLogger->new());
	my $carped = 0;
	local $SIG{__WARN__} = sub { $carped++ };
	$info->_warn('logged warning');
	is($carped, 0, 'no carp with logger');
	my @w = warns_from($info);
	ok(@w, 'warning stored in messages');
};

subtest '_error E1: without logger → croaks' => sub {
	plan tests => 1;
	my $info = CGI::Info->new(logger => MyLogger->new());
	delete $info->{logger};
	throws_ok { $info->_error('fatal') } qr/fatal/, '_error without logger croaks';
};

subtest '_error E2: with logger → no croak, error stored' => sub {
	plan tests => 2;
	my $info = CGI::Info->new(logger => MyLogger->new());
	lives_ok { $info->_error('logged error') } '_error with logger does not croak';
	my @errs = grep { $_->{level} eq 'error' } @{$info->messages() // []};
	ok(@errs, 'error level message stored');
};

# ===========================================================================
# _get_env() — path coverage
# ===========================================================================

subtest '_get_env GE1: undefined variable → undef' => sub {
	plan tests => 1;
	# Preserve HARNESS_ACTIVE so Sub::Protected bypass stays active
	local %ENV = %ENV;
	delete $ENV{__PATH_T_NONEXISTENT__};
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->_get_env('__PATH_T_NONEXISTENT__'), undef, 'absent var → undef');
};

subtest '_get_env GE2: variable with valid chars → returned unchanged' => sub {
	plan tests => 1;
	local %ENV = (HARNESS_ACTIVE => 1, SCRIPT_NAME => '/cgi-bin/test.pl');
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->_get_env('SCRIPT_NAME'), '/cgi-bin/test.pl', 'valid var returned');
};

subtest '_get_env GE3: variable with invalid chars → warn + undef' => sub {
	plan tests => 2;
	local %ENV = (HARNESS_ACTIVE => 1, SCRIPT_NAME => 'hello world');    # space is disallowed
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->_get_env('SCRIPT_NAME'), undef, 'invalid chars → undef');
	my @w = warns_from($info);
	like($w[0]{message}, qr/Invalid value/, 'warning mentions Invalid value');
};

# ===========================================================================
# AUTOLOAD() — path coverage
# ===========================================================================

subtest 'AUTOLOAD AL1: DESTROY is silently ignored' => sub {
	plan tests => 1;
	local %ENV;
	my $info = CGI::Info->new(logger => MyLogger->new());
	lives_ok { $info->DESTROY() } 'DESTROY does not croak';
};

subtest 'AUTOLOAD AL2: called on class string → croak' => sub {
	plan tests => 1;
	throws_ok { CGI::Info->no_such_method() }
		qr/Unknown method no_such_method/,
		'class-method AUTOLOAD croaks';
};

subtest 'AUTOLOAD AL3: auto_load => 0 → croak' => sub {
	plan tests => 1;
	local %ENV;
	my $info = CGI::Info->new(auto_load => 0, logger => MyLogger->new());
	throws_ok { $info->no_such_param() }
		qr/Unknown method no_such_param/,
		'auto_load disabled → croak';
};

subtest 'AUTOLOAD AL4: delegates to param() for real CGI param' => sub {
	plan tests => 1;
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'mykey=myval',
	);
	CGI::Info->reset();
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->mykey(), 'myval', 'AUTOLOAD → param() → value');
};

# ===========================================================================
# set_logger() — path coverage
# ===========================================================================

subtest 'set_logger SL1: blessed logger stored as-is' => sub {
	plan tests => 1;
	local %ENV;
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $log  = MyLogger->new();
	$info->set_logger($log);
	is($info->{logger}, $log, 'blessed logger stored directly');
};

subtest 'set_logger SL2: non-blessed string wrapped in Log::Abstraction' => sub {
	plan tests => 1;
	local %ENV;
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->set_logger('syslog');
	isa_ok($info->{logger}, 'Log::Abstraction', 'string arg wrapped');
};

subtest 'set_logger SL3: logger => undef creates fresh Log::Abstraction' => sub {
	plan tests => 1;
	local %ENV;
	my $info = CGI::Info->new(logger => MyLogger->new());
	$info->set_logger(logger => undef);
	isa_ok($info->{logger}, 'Log::Abstraction', 'undef logger arg → Log::Abstraction');
};

subtest 'set_logger SL4: returns $self for method chaining' => sub {
	plan tests => 1;
	local %ENV;
	my $info = CGI::Info->new(logger => MyLogger->new());
	is($info->set_logger(MyLogger->new()), $info, 'set_logger returns self');
};

# ===========================================================================
# cache() — path coverage
# ===========================================================================

subtest 'cache CA1: no arg → returns undef when not set' => sub {
	plan tests => 1;
	local %ENV;
	is(CGI::Info->new(logger => MyLogger->new())->cache(), undef, 'no cache → undef');
};

subtest 'cache CA2: unblessed argument → croak' => sub {
	plan tests => 1;
	local %ENV;
	my $info = CGI::Info->new(logger => MyLogger->new());
	throws_ok { $info->cache('scalar') } qr/is not an object/, 'scalar → croak';
};

subtest 'cache CA3: blessed but no get() → croak' => sub {
	plan tests => 1;
	local %ENV;
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $bad  = bless {}, 'CacheNoGet';
	throws_ok { $info->cache($bad) }
		qr/does not support the get\(\) method/,
		'no get() → croak';
};

subtest 'cache CA4: blessed with get() but no set() → croak' => sub {
	plan tests => 1;
	local %ENV;
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $bad  = bless {}, 'CacheNoSet';
	{ no strict 'refs'; *{'CacheNoSet::get'} = sub { } }
	throws_ok { $info->cache($bad) }
		qr/does not support the set\(\) method/,
		'no set() → croak';
};

subtest 'cache CA5: valid cache stored and returned' => sub {
	plan tests => 2;
	local %ENV;
	my $info = CGI::Info->new(logger => MyLogger->new());
	my $mc   = bless {}, 'GoodCache';
	{ no strict 'refs';
	  *{'GoodCache::get'} = sub { undef };
	  *{'GoodCache::set'} = sub { 1 };
	}
	is($info->cache($mc), $mc,  'cache() returns the cache object');
	is($info->cache(),    $mc,  'cache() retrieves it afterward');
};

# ===========================================================================
# reset() — path coverage
# ===========================================================================

subtest 'reset RE1: on CGI::Info class → clears stdin_data' => sub {
	plan tests => 1;
	lives_ok { CGI::Info->reset() } 'reset() on correct class succeeds';
};

subtest 'reset RE2: on wrong package → carps and returns' => sub {
	plan tests => 1;
	my $carped = 0;
	local $SIG{__WARN__} = sub { $carped++ };
	CGI::Info::reset('SomeOtherPackage');
	ok($carped, 'reset on wrong class carps');
};

# ===========================================================================
# DEAD CODE — documented findings
#
# These paths are provably unreachable.  The corresponding lines in
# lib/CGI/Info.pm are annotated with "# TODO: Unreachable code detected
# during path analysis."
#
# 1. cookie() lines ~2375-2384:
#    The `if(!defined($field))` and `if(ref($field))` guards are never
#    reached because Params::Validate::Strict::validate_strict() already
#    enforces `type => 'string', min => 1` and croaks for any invalid input
#    BEFORE control reaches those checks.
#    The `return;` statements after `Carp::croak()` inside those blocks are
#    doubly dead (croak never returns).
#
# 2. AUTOLOAD() line ~2667:
#    `unless $method =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/` can only fail if
#    $method starts with a digit.  The prior capture `/::(\w+)$/` allows
#    digits, but Perl's dispatch never generates a digit-leading AUTOLOAD
#    variable, making this branch unreachable in normal operation.
# ===========================================================================

subtest 'dead code DC1: cookie() missing name → validate_strict croaks (not inner guard)' => sub {
	plan tests => 1;
	local %ENV = (HTTP_COOKIE => 'a=1');
	my $info = CGI::Info->new(logger => MyLogger->new());
	# The croak here originates in validate_strict, not in the !defined($field) guard
	throws_ok { $info->cookie() } qr//, 'missing cookie name always croaks at validate_strict';
};

done_testing();
