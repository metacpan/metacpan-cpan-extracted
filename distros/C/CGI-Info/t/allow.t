#!perl -w

use strict;
use warnings;

use Data::Dumper;
use Test::Most tests => 42;
use Test::NoWarnings;

BEGIN { use_ok('CGI::Info') }

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
	allow => \%allowed,
	# logger => sub { ($_[0]->{'level'} eq 'warn') && die @{$_[0]->{'message'}} }
]);
ok(!defined($i->params()));
ok($i->as_string() eq '');
local $SIG{__WARN__} = sub { die $_[0] };
eval { $i->param('fred') };
diag($@);
ok($@ =~ /fred isn't in the allow list at/);

$ENV{'QUERY_STRING'} = 'foo=123&fred=wilma';

$i = new_ok('CGI::Info' => [
	allow => \%allowed,
	logger => sub { ($_[0]->{'level'} eq 'warn') && die @{$_[0]->{'message'}} }
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
$i->set_logger(sub { ($_[0]->{'level'} eq 'warn') && die @{$_[0]->{'message'}} });
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

subtest 'Allowed Parameters Regex' => sub {
	local %ENV = (
		GATEWAY_INTERFACE => 'CGI/1.1',
		REQUEST_METHOD => 'GET',
		QUERY_STRING => 'allowed_param=123&disallowed_param=evil',
	);

	my @messages;
	my $info = CGI::Info->new(allow => { allowed_param => qr/^\d{3}$/ }, logger => { array => \@messages, level => 'info' });
	my $params = $info->params();

	is_deeply(
		$params,
		{ allowed_param => '123' },
		'Only allowed parameters are present'
	);
	cmp_ok($info->status(), '==', 422, 'Status is not OK when disallowed params are used');
	ok(scalar(@messages) > 0);
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

	my @messages;
	my $info = CGI::Info->new(allow => $allowed, logger => \@messages);
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
	$info = CGI::Info->new(logger => \@messages);
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
	$info = CGI::Info->new(logger => \@messages);
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
	$info = CGI::Info->new(logger => \@messages);
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
	$info = CGI::Info->new(logger => \@messages);
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
	$info = CGI::Info->new(logger => { array => \@messages, level => 'info' });
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
	ok(scalar(@messages) > 0);
};

{
	# Setup CGI environment
	local %ENV = (
		'GATEWAY_INTERFACE' => 'CGI/1.1',
		'REQUEST_METHOD' => 'GET',
		'QUERY_STRING' => 'name=John&age=25&id=123&score=85'
	);

	sub custom_age_check {
		my ($key, $value) = @_;
		return $value =~ /^\d+$/ && $value >= 18 && $value <= 120;
	}

	sub complex_id_validation {
		my ($value, $cgi_info) = @_;	# Demonstrate access to CGI::Info instance
		return $value =~ /^\d+$/ && $cgi_info->param('age') > 20;
	}

	# Test cases
	subtest 'Basic subroutine validation' => sub {
		my $info = CGI::Info->new(
			allow => {
				name => sub { length($_[1]) > 2 },	# Anonymous subroutine
				age => \&custom_age_check,	# Reference to named sub
				id => qr/^\d+$/,	# Mixed with regex validation
			}
		);

		my $params = $info->params();

		is($params->{name}, 'John', 'Name passed validation');
		is($params->{age}, 25, 'Valid age accepted');
		is($params->{id}, 123, 'ID passed regex validation');
		ok(!exists $params->{score}, 'Unallowed parameter filtered out');
	};

	subtest 'Subroutine with CGI::Info instance access' => sub {
		my $info = CGI::Info->new(
			allow => {
				id => sub { complex_id_validation($_[1], $_[2]) },
				age => \&custom_age_check,
			}
		);

		my $params = $info->params();

		is($params->{id}, 123, 'ID validated with instance access');
		is($params->{age}, 25, 'Age validated normally');
	};

	subtest 'Failed validations' => sub {
		local $ENV{QUERY_STRING} = 'name=Jo&age=170&id=abc';

		my $info = CGI::Info->new(
			allow => {
				name => sub { length($_[1]) > 2 },
				age => \&custom_age_check,
				id => qr/^\d+$/,
			}
		);

		my $params = $info->params();

		ok(!exists $params->{name}, 'Short name rejected');
		ok(!exists $params->{age}, 'Age over 120 rejected');
		ok(!exists $params->{id}, 'Non-numeric ID rejected');
	};

	subtest 'Error handling' => sub {
		local $ENV{QUERY_STRING} = 'test=bad';

		my $info = CGI::Info->new(
			allow => {
				test => sub { die 'Validation error' }	# Force die
			}
		);

		eval { $info->params() };
		like($@, qr/Validation error/, 'Subroutine exceptions propagate correctly');
	};
}
