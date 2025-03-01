#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 39;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('CGI::Info');
}

PARAM: {
	# Initial sanity tests
	{
		# Preserve the current %ENV, so changes are local to this subtest
		local %ENV = %ENV;

		$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
		$ENV{'REQUEST_METHOD'} = 'GET';
		$ENV{'QUERY_STRING'} = 'foo=bar&baz=qux';
		my $mess = 'mess is undefined';

		{
			package MockLogger;

			sub new { bless { }, shift }
			sub trace { }
			sub debug { }
			sub warn { shift; $mess = join(' ' , @_) }
		}

		my $obj = CGI::Info->new(
			allow => { foo => undef, baz => undef },
			logger => MockLogger->new()
		);

		is_deeply($obj->param, { foo => 'bar', baz => 'qux' }, 'No arguments returns all params');

		is($obj->param('foo'), 'bar', 'Fetching allowed parameter "foo"');

		is($obj->param('baz'), 'qux', 'Fetching allowed parameter "baz"');

		is($obj->param('invalid'), undef, 'Fetching disallowed parameter "invalid" returns undef');
		diag(Data::Dumper->new([$obj->messages()])->Dump()) if($ENV{'TEST_VERBOSE'});
		# Get the warnings that the object has generated
		my @warnings = grep defined, map { ($_->{'level'} eq 'warn') ? $_->{'message'} : undef } @{$obj->messages()};
		like(
			$warnings[0],
			qr/param: invalid isn't in the allow list/,
			'Warning generated for disallowed parameter'
		);

		delete $ENV{'QUERY_STRING'};
		$obj = CGI::Info->new();
		is($obj->param('foo'), undef, 'No params set, fetching "foo" returns undef');
	};

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
	ok($i->as_string() eq 'foo=bar; fred=wilma');

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma&foo=baz';
	$i = new_ok('CGI::Info');
	ok($i->param('foo') eq 'bar,baz');
	ok($i->param('fred') eq 'wilma');
	ok($i->as_string() eq 'foo=bar,baz; fred=wilma');

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
	# ok(defined($i->param('foo')));
	# ok($i->as_string() eq 'foo=&lt\;script&gt\;alert(hello)&lt\;/script&gt\;');
	ok(!defined($i->param('foo')));
	ok($i->as_string() eq '');

	$ENV{'QUERY_STRING'} = 'foo=&fred=wilma&foo=bar';
	$i = new_ok('CGI::Info');
	ok($i->param('foo', logger => MyLogger->new()) eq 'bar');
	ok($i->param('fred') eq 'wilma');
	ok($i->as_string() eq 'foo=bar; fred=wilma');

	subtest 'SQL injection is blocked' => sub {
		# Preserve the current %ENV, so changes are local to this subtest
		local %ENV = %ENV;

		$ENV{'REQUEST_METHOD'} = 'GET';
		$ENV{'QUERY_STRING'} = 'nan=lost&redir=-8717%22%20OR%208224%3D6013--%20ETLn';

		my $info = new_ok('CGI::Info');
		ok(!defined($info->param('nan')));
		ok(!defined($info->param('redir')));
	};

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
	};
}
