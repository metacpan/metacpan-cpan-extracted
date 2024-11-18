#!perl -w

use strict;
use warnings;
use Test::Most tests => 33;
use Test::NoWarnings;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('CGI::Info');
}

PARAM: {
	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'GET';
	$ENV{'QUERY_STRING'} = 'foo=bar';

	my $i = new_ok('CGI::Info');
	cmp_ok($i->param('foo'), 'eq', 'bar', 'basic param() test');
	is($i->param('fred'), undef, 'param() returns undef when needed');
	cmp_ok($i->as_string(), 'eq', 'foo=bar', 'basic as_string test');

	$ENV{'QUERY_STRING'} = '=bar';

	$i = new_ok('CGI::Info');
	ok(!defined($i->param('fred')));
	ok($i->as_string() eq '');

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma';

	$i = new_ok('CGI::Info');
	ok($i->param('foo') eq 'bar');
	ok($i->param('fred') eq 'wilma');
	ok($i->as_string() eq 'foo=bar;fred=wilma');

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma&foo=baz';
	$i = new_ok('CGI::Info');
	ok($i->param('foo') eq 'bar,baz');
	ok($i->param('fred') eq 'wilma');
	ok($i->as_string() eq 'foo=bar,baz;fred=wilma');

	# Reading twice should yield the same result
	ok($i->param('foo') eq 'bar,baz');

	$ENV{'QUERY_STRING'} = 'foo=&fred=wilma';
	$i = new_ok('CGI::Info');
	my %p = %{$i->param()};
	ok(!defined($i->param('foo')));
	cmp_ok($i->as_string(), 'eq', 'fred=wilma', 'as_string works');
	cmp_ok($p{'fred'}, 'eq', 'wilma', 'param() with no arguments returns correct HASH');

	$ENV{'QUERY_STRING'} = 'foo=bar\u0026fred=wilma';
	$i = new_ok('CGI::Info');
	is($i->param('foo'), 'bar', '\u0026 is interpreted as &');

	# Don't pass XSS through
	$ENV{'QUERY_STRING'} = 'foo=<script>alert(hello)</script>';
	$i = new_ok('CGI::Info');
	ok(defined($i->param('foo')));
	ok($i->as_string() eq 'foo=&lt\;script&gt\;alert(hello)&lt\;/script&gt\;');

	$ENV{'QUERY_STRING'} = 'foo=&fred=wilma&foo=bar';
	$i = new_ok('CGI::Info');
	ok($i->param('foo', logger => MyLogger->new()) eq 'bar');
	ok($i->param('fred') eq 'wilma');
	ok($i->as_string() eq 'foo=bar;fred=wilma');

	subtest 'Test GET' => sub {
		# Preserve the current %ENV, so changes are local to this subtest
		local %ENV = %ENV;

		my $info = CGI::Info->new();

		$ENV{'REQUEST_METHOD'} = 'GET';
		$ENV{'QUERY_STRING'} = 'name=John&age=30';

		is($info->param('name'), 'John', 'name parameter is correct');
		is($info->name(), 'John', 'name parameter is correct with AUTOLOAD')
	};

	subtest 'Test POST' => sub {
		# Preserve the current %ENV, so changes are local to this subtest
		local %ENV = %ENV;

		CGI::Info->reset();	# Force stdin re-read

		my $info = CGI::Info->new();
		my $data = 'name=Jane&age=25';

		$ENV{'CONTENT_LENGTH'} = length($data);
		$ENV{'REQUEST_METHOD'} = 'POST';
		$ENV{'CONTENT_TYPE'} = 'application/x-www-form-urlencoded';

		# Simulate the input stream using an in-memory filehandle
		open(my $fh, '<', \$data);
		local *STDIN = $fh;	# Redirect STDIN to read from our in-memory filehandle
		binmode($fh);

		is($info->param('name'), 'Jane', 'name parameter is correct');
		is($info->name(), 'Jane', 'name parameter is correct with AUTOLOAD');

		close $fh
	}
}
