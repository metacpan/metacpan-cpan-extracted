#!perl -w

use strict;
use warnings;
use Test::Most tests => 38;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Info');
}

ALLOWED: {
	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'GET';

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma';
	my %allowed = ('fred' => undef);
	my $i = new_ok('CGI::Info');
	my %p = %{$i->params({allow => \%allowed})};
	ok(!exists($p{foo}));
	cmp_ok($p{fred}, 'eq', 'wilma', 'check valid param');
	ok($i->as_string() eq 'fred=wilma');

	$ENV{'QUERY_STRING'} = 'barney=betty&fred=wilma';
	%allowed = ('fred' => 'barney', 'wilma' => 'betty');
	$i = new_ok('CGI::Info');
	is($i->params({allow => \%allowed}), undef, 'Check when different parameter is given');
	cmp_ok($i->as_string(), 'eq', '', 'no valid args gives empty as_string()');

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma&foo=baz';
	%allowed = ('foo' => undef);
	$i = new_ok('CGI::Info' => [
		allow => \%allowed
	]);
	%p = %{$i->params()};
	ok($p{foo} eq 'bar,baz');
	ok(!exists($p{fred}));
	ok($i->as_string() eq 'foo=bar,baz');

	# Reading twice should yield the same result
	%p = %{$i->params()};
	ok($p{foo} eq 'bar,baz');

	%allowed = ('foo' => qr(\d+));
	$i = new_ok('CGI::Info' => [
		allow => \%allowed
	]);
	ok(!defined($i->params()));
	ok($i->as_string() eq '');
	local $SIG{__WARN__} = sub { die $_[0] };
	eval { $i->param('fred') };
	ok($@ =~ /fred isn't in the allow list at/);

	$ENV{'QUERY_STRING'} = 'foo=123&fred=wilma';

	$i = new_ok('CGI::Info' => [
		allow => \%allowed
	]);
	%p = %{$i->params()};
	ok($p{foo} eq '123');
	ok(!exists($p{fred}));
	ok($i->param('foo') eq '123');
	eval { $i->param('fred') };
	ok($@ =~ /fred isn't in the allow list at/);
	ok($i->as_string() eq 'foo=123');

	#---------------------
	# What if the allowed parameters become more restrictive, that can
	#	happen when a client did a peek then sets the allowed

	$ENV{'QUERY_STRING'} = 'foo=123&fred=wilma&admin=1';
	$i = new_ok('CGI::Info');
	ok($i->param('fred') eq 'wilma');
	ok($i->param('admin') == 1);
	%p = %{$i->params(allow => \%allowed)};
	ok($p{foo} eq '123');
	ok(!exists($p{fred}));
	ok(!exists($p{'admin'}));
	eval { $i->param('admin') };
	ok($@ =~ /admin isn't in the allow list at/);
	ok($i->param('foo') eq '123');
	eval { $i->param('fred') };
	ok($@ =~ /fred isn't in the allow list at/);
	ok($i->as_string() eq 'foo=123');

	%allowed = ('foo' => qr([a-z]+));
	$i = new_ok('CGI::Info' => [
		allow => \%allowed
	]);
	ok(!defined($i->params()));
}

subtest 'Allowed Parameters Regex' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'GET',
		QUERY_STRING => 'allowed_param=123&disallowed_param=evil',
	);

	my $info = CGI::Info->new(allow => { allowed_param => qr/^\d{3}$/ });
	my $params = $info->params();

	is_deeply(
		$params,
		{ allowed_param => '123' },
		'Only allowed parameters are present'
	);
	cmp_ok($info->status(), '==', 422, 'Status is not OK when disallowed params are used');
};

subtest 'Allow Parameters Rules' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'GET',
		QUERY_STRING => 'username=test_user&email=test@example.com&age=30&bio=a+test+bio&ip_address=192.168.1.1'
	);

	my $allowed = {
		username => { type => 'string', min => 3, max => 50, matches => qr/^[a-zA-Z0-9_]+$/ },
		email => { type => 'string', matches => qr/^[^@]+@[^@]+\.[^@]+$/ },
		age => { type => 'integer', min => 0, max => 150 },
		bio => { type => 'string', optional => 1 },
		ip_address => { type => 'string', matches => qr/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/ },	# Basic IPv4 validation
	};

	my $info = CGI::Info->new(allow => $allowed);
	my $params = $info->params();
	diag(Data::Dumper->new([$params])->Dump()) if($ENV{'TEST_VERBOSE'});

	is_deeply(
		$params,
		{
			'username' => 'test_user',
			'email' => 'test@example.com',
			'age' => 30,
			'bio' => 'a test bio',
			'ip_address' => '192.168.1.1',
		},
		'Command line parameters parsed correctly'
	);

	local $ENV{'QUERY_STRING'} = 'username=te&email=test@example.com&age=300&bio=a+test+bio&ip_address=192.168.1.1';
	$info = new_ok('CGI::Info');
	$params = $info->params(allow => $allowed);
	is_deeply(
		$params,
		{
			'email' => 'test@example.com',
			'bio' => 'a test bio',
			'ip_address' => '192.168.1.1',
		},
		'min/max rule works on integers and strings'
	);

	local $ENV{'QUERY_STRING'} = 'username=' . 'x' x 51 . '&email=test@example.com&age=30&bio=a+test+bio&ip_address=192.168.1.1';
	$info = CGI::Info->new();
	$params = $info->params(allow => $allowed);
	is_deeply(
		$params,
		{
			'email' => 'test@example.com',
			'age' => 30,
			'bio' => 'a test bio',
			'ip_address' => '192.168.1.1',
		},
		'max rule works on strings'
	);

	local $ENV{'QUERY_STRING'} = 'username=test_user&email=test@example&age=30&bio=a+test+bio&ip_address=192.168.1.1';
	$info = CGI::Info->new();
	$params = $info->params({ allow => $allowed });
	is_deeply(
		$params,
		{
			'username' => 'test_user',
			'age' => 30,
			'bio' => 'a test bio',
			'ip_address' => '192.168.1.1',
		},
		'string regex rule works'
	);

	local $ENV{'QUERY_STRING'} = 'username=test_user&email=test@example.com&age=-1&bio=a+test+bio&ip_address=192.168.1.1';
	$info = CGI::Info->new();
	$params = $info->params({ allow => $allowed });
	is_deeply(
		$params,
		{
			'username' => 'test_user',
			'bio' => 'a test bio',
			'email' => 'test@example.com',
			'ip_address' => '192.168.1.1',
		},
		'min rule works on integers'
	);

	local $ENV{'QUERY_STRING'} = 'username=test_user&email=test@example.com&age=150&bio=a+test+bio&ip_address=192.168.1.';
	$info = CGI::Info->new();
	$params = $info->params({ allow => $allowed });
	is_deeply(
		$params,
		{
			'age' => 150,
			'username' => 'test_user',
			'bio' => 'a test bio',
			'email' => 'test@example.com',
		},
		'string regex rule works',
	);
};
