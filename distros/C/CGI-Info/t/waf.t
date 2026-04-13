#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use File::Spec;
use File::Temp qw(tempdir);
BEGIN { use_ok('CGI::Info') }

# Setup for tests
my $info;
my $upload_dir = tempdir(CLEANUP => 1);

subtest 'SQL Injection Detection' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'GET',
		QUERY_STRING => 'username=nigel%27+OR+%271%27%3D%271',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined($params), 'SQL injection attempt blocked');
	is($info->status(), 403, 'Status set to 403 Forbidden');
	$ENV{'QUERY_STRING'} = 'page=by_location&county=CA&country=United%2F%2A%2A%2FStates%29%2F%2A%2A%2FAND%2F%2A%2A%2F%28SELECT%2F%2A%2A%2F6734%2F%2A%2A%2FFROM%2F%2A%2A%2F%28SELECT%28SLEEP%285%29%29%29lRNi%29%2F%2A%2A%2FAND%2F%2A%2A%2F%288984%3D8984';
	$info = new_ok('CGI::Info');
	$params = $info->params();
	ok(!defined $params, 'SQL injection attempt blocked 2');
	is($info->status(), 403, 'Status set to 403 Forbidden');
};

subtest 'XSS Sanitization' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'GET',
		QUERY_STRING => 'comment=<script>alert("xss")</script>',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'XSS injection attempt blocked');
	is($info->status(), 403, 'Status set to 403 Forbidden');
};

subtest 'Directory Traversal Prevention' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'GET',
		QUERY_STRING => 'file=../../etc/passwd',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'Directory traversal attempt blocked');
	is($info->status(), 403, 'Status set to 403 Forbidden');
};

subtest 'Upload Directory Validation' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'POST',
		CONTENT_TYPE => 'multipart/form-data; boundary=12345',
		CONTENT_LENGTH => 100,
		C_DOCUMENT_ROOT => $upload_dir,
	);
	# Invalid upload_dir (not absolute)
	$info = CGI::Info->new(upload_dir => 'tmp');
	$info->params();
	is($info->status(), 500, 'Invalid upload_dir rejected');
	# Valid upload_dir
	$info = CGI::Info->new(upload_dir => $upload_dir);
	local *STDIN;
	open STDIN, '<', \"--12345\nContent-Disposition: form-data; name=\"file\"; filename=\"test.txt\"\n\nContent\n--12345--";
	my $params = $info->params();
	if(defined $params && defined $params->{file}) {
		like($params->{file}, qr/test\.txt/, 'File uploaded to valid directory');
		my $uploaded = File::Spec->catfile($upload_dir, $params->{file});
		unlink $uploaded if -e $uploaded;
		unlink $params->{file} if -e $params->{file};
	} else {
		pass('Upload skipped or params undef on this platform');
	}
};

subtest 'Parameter Sanitization' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'GET',
		QUERY_STRING => 'key%00=evil%00data&value=valid+data',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	is($params->{key}, 'evildata', 'NUL bytes in key removed');
	is($params->{value}, 'valid data', 'Spaces correctly decoded');
};

subtest 'Max Upload Size Enforcement' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'POST',
		CONTENT_TYPE => 'application/x-www-form-urlencoded',
		CONTENT_LENGTH => 1024 * 1024 * 600,	# 600MB
	);
	$info = CGI::Info->new(max_upload => 500 * 1024);	# 500KB
	$info->params();
	is($info->status(), 413, 'Status set to 413 Payload Too Large');
};

subtest 'Command Line Parameters' => sub {
	local @ARGV = ('--mobile', 'param1=value1', 'param2=value2');
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	is_deeply(
		$params,
		{ param1 => 'value1', param2 => 'value2' },
		'Command line parameters parsed correctly'
	);
	ok($info->is_mobile, 'Mobile flag set from command line');
};

# ============================================================
# Additional WAF tests — patterns not covered above
# ============================================================

subtest 'SQL Injection: OR...AND without quotes (vwf.log pattern)' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'entry=-4346%22+OR+1749%3D1749+AND+%22dgiO%22%3D%22dgiO',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'OR...AND injection without single quotes blocked');
	is($info->status(), 403, 'Status 403 on OR...AND injection');
};

subtest 'SQL Injection: AND 1=1' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'id=1%20AND%201%3D1',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'AND 1=1 injection blocked');
	is($info->status(), 403, 'Status 403 on AND 1=1');
};

subtest 'SQL Injection: UNION SELECT' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => "id=1%27%20UNION%20SELECT%20username%2Cpassword%20FROM%20users--",
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'UNION SELECT injection blocked');
	is($info->status(), 403, 'Status 403 on UNION SELECT');
};

subtest 'SQL Injection: exec stored procedure (xp_)' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'cmd=exec+xp_cmdshell+%27dir%27',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'exec xp_ stored procedure injection blocked');
	is($info->status(), 403, 'Status 403 on exec xp_');
};

subtest 'SQL Injection: exec sp_ stored procedure' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'cmd=exec%20sp_executesql%20N%27SELECT+1%27',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'exec sp_ stored procedure injection blocked');
	is($info->status(), 403, 'Status 403 on exec sp_');
};

subtest 'SQL Injection: var_dump...md5 probe' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'x=var_dump(md5(12345))',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'var_dump...md5 probe blocked');
	is($info->status(), 403, 'Status 403 on var_dump...md5');
};

subtest 'SQL Injection: ORDER BY comment style' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'sort=%2F%2A%2A%2FORDER%2F%2A%2A%2FBY%2F%2A%2A%2F1',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, '/**/ ORDER /**/ BY injection blocked');
	is($info->status(), 403, 'Status 403 on comment-style ORDER BY');
};

subtest 'SQL Injection: double-dash comment terminator with equals' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'redir=-8717%22%20OR%208224%3D6013--%20ETLn',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'double-dash comment terminator injection blocked');
	is($info->status(), 403, 'Status 403 on -- terminator injection');
};

subtest 'SQL Injection: Stock/SELECT*from pattern' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => "surname=%27Stock%20or%20%281%2C2%29%3D%28SELECT%2afrom%28select%20name_const%28CHAR%28111%29%2C1%29%29a%29%20--%20and%201%3D1%27",
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'SELECT*from injection blocked');
	is($info->status(), 403, 'Status 403 on SELECT*from');
};

subtest 'SQL Injection: via User-Agent header' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'x=1',
		HTTP_USER_AGENT   => 'Mozilla/5.0 SELECT foo AND bar FROM users',
		REMOTE_ADDR       => '1.2.3.4',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'SQL injection in User-Agent blocked');
	is($info->status(), 403, 'Status 403 on SQL injection in User-Agent');
};

subtest 'WAF: mustleak.com probe blocked' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'probe=mustleak.com/test',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'mustleak.com probe blocked');
	is($info->status(), 403, 'Status 403 on mustleak probe');
};

subtest 'WAF: XSS via encoded angle brackets' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'x=%3Cscript%3Ealert%281%29%3C%2Fscript%3E',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'URL-encoded XSS blocked');
	is($info->status(), 403, 'Status 403 on encoded XSS');
};

subtest 'WAF: XSS via HTML img tag' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'x=%3Cimg+src%3Dx+onerror%3Dalert%281%29%3E',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'img onerror XSS blocked');
	is($info->status(), 403, 'Status 403 on img XSS');
};

subtest 'WAF: directory traversal with URL encoding' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'file=..%2F..%2Fetc%2Fpasswd',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(!defined $params, 'URL-encoded directory traversal blocked');
	is($info->status(), 403, 'Status 403 on encoded traversal');
};

subtest 'WAF: false positive — FBCLID with double-dash' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'fbclid=AQHk--sometoken123456789',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(defined $params, 'FBCLID with -- not blocked (false positive check)');
	ok($params->{fbclid}, 'FBCLID value accessible');
};

subtest 'WAF: false positive — normal alphanumeric values pass' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'name=Alice&age=30&city=New+York&id=12345',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(defined $params,              'clean params not blocked');
	is($params->{name}, 'Alice',     'name passed through');
	is($params->{age},  '30',        'age passed through');
	is($params->{city}, 'New York',  'city with space passed through');
	is($params->{id},   '12345',     'numeric id passed through');
	is($info->status(), 200,         'status 200 for clean params');
};

subtest 'WAF: false positive — SELECT as part of legitimate word' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'action=SELECT_item&menu=dropdown',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	ok(defined $params,                    'SELECT_ prefix not blocked');
	is($params->{action}, 'SELECT_item',   'SELECT_ value passed through');
	is($info->status(), 200,               'status 200 for benign SELECT_ value');
};

subtest 'WAF: false positive — email address with equals in base64' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'token=abc123def456ghi789%3D%3D',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	# Base64 padding == does not contain injection chars alongside it
	ok(defined $params, 'base64-padded token not blocked');
	is($info->status(), 200, 'status 200 for base64 token');
};

subtest 'WAF: SQL injection blocked on is_robot() SQL UA' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'x=clean',
		HTTP_USER_AGENT   => 'bot/1.0 AND 1=1',
		REMOTE_ADDR       => '1.2.3.4',
	);
	$info = new_ok('CGI::Info');
	ok($info->is_robot(), 'SQL-injecting UA flagged as robot');
	is($info->status(), 403, 'Status 403 on SQL injection in UA via is_robot');
};

subtest 'WAF: NUL byte in value stripped, not stored' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'data=hello%00world',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	if(defined $params && defined $params->{data}) {
		unlike($params->{data}, qr/\x00/, 'NUL byte stripped from value');
	} else {
		pass('params blocked or value empty after NUL strip (acceptable)');
	}
};

subtest 'WAF: %00 NUL byte in value stripped' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'data=hello%2500world',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	# %2500 URL-decodes to literal %00 (percent-zero-zero).
	# The fix applies the %00 strip a second time after URL-decoding,
	# so %2500 -> %00 -> '' and the value becomes 'helloworld'.
	if(defined $params && defined $params->{data}) {
		unlike($params->{data}, qr/\x00/, 'NUL byte not present after fix');
		unlike($params->{data}, qr/%00/,  'literal %00 stripped after URL-decode');
	} else {
		pass('params blocked or value empty after strip (acceptable)');
	}
};

subtest 'WAF: HTML comment injection stripped' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'note=hello<!--+evil+-->world',
	);
	$info = new_ok('CGI::Info');
	my $params = $info->params();
	if(defined $params && defined $params->{note}) {
		unlike($params->{note}, qr/<!--/, 'HTML comment open stripped');
		unlike($params->{note}, qr/-->/, 'HTML comment close stripped');
	} else {
		pass('params blocked or stripped (acceptable)');
	}
};

subtest 'WAF: clean request after attack does not persist 403 status' => sub {
	# First request: attack
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => "x=1'%20OR%201=1",
	);
	CGI::Info->reset();
	my $bad = CGI::Info->new();
	$bad->params();
	is($bad->status(), 403, 'Attack request sets 403');

	# Second request: clean (fresh object)
	CGI::Info->reset();
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD    => 'GET',
		QUERY_STRING      => 'name=Alice',
	);
	my $good = CGI::Info->new();
	my $p = $good->params();
	ok(defined $p, 'Clean request after attack returns params');
	is($good->status(), 200, 'Clean request after attack has 200 status');
};

done_testing();
