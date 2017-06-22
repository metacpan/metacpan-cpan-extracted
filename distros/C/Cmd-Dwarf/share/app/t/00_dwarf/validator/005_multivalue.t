use strict;
use warnings;
use Test::More tests => 11;
use Dwarf::Validator;
use Plack::Request;

{
	# Optional parameter foo has multiple empty string values
	my $q = Plack::Request->new(
		{
			QUERY_STRING   => 'foo=&foo=',
			REQUEST_METHOD => 'POST',
			'psgi.input'   => *STDIN,
		},
	);
	my $v = Dwarf::Validator->new($q);
	ok(!$v->has_error);
	$v->check(
		'foo' => [
			[CHOICE => qw/hoge fuga/],
		],
	);
	ok(!$v->has_error);
};
{
	# Optional parameter foo has multiple zeros and check against ''
	my $q = Plack::Request->new(
		{
			QUERY_STRING   => 'foo=0&foo=0',
			REQUEST_METHOD => 'POST',
			'psgi.input'   => *STDIN,
		},
	);
	my $v = Dwarf::Validator->new($q);
	ok(!$v->has_error);
	$v->check(
		'foo' => [
			[CHOICE => '']
		],
	);
	ok($v->has_error);
	is_deeply($v->errors, {
		foo => {
			CHOICE => 2,
		}
	});
};
{
	# Detect required param foo is not null,
	# first and second items are valid,
	# and third item is invalid
	my $q = Plack::Request->new(
		{
			QUERY_STRING   => 'foo=0&foo=1&foo=3',
			REQUEST_METHOD => 'POST',
			'psgi.input'   => *STDIN,
		},
	);
	my $v = Dwarf::Validator->new($q);
	ok(!$v->has_error);
	$v->check(
		'foo' => [
			'NOT_NULL',
			[CHOICE => qw/0 1 2/],
		],
	);
	ok($v->has_error);
	ok($v->is_error('foo'));
	is_deeply($v->errors, {
		foo => {
			CHOICE => 1
		},
	});
};
{
	# Detect all items in foo are valid
	my $q = Plack::Request->new(
		{
			QUERY_STRING   => 'foo=0&foo=1&foo=3',
			REQUEST_METHOD => 'POST',
			'psgi.input'   => *STDIN,
		},
	);
	my $v = Dwarf::Validator->new($q);
	$v->check(
		foo => [
			'NOT_NULL',
			[CHOICE => qw/0 1 2 3/],
		],
	);
	ok(!$v->has_error);
	is_deeply($v->errors, { });
};
