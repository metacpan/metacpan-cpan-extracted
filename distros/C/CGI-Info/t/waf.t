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

	# is(
		# $params->{comment},
		# '&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;',
		# 'XSS content sanitized'
	# );
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

	ok($params->{file} =~ /test\.txt/, 'File uploaded to valid directory');
	unlink $params->{'file'};
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

done_testing();
