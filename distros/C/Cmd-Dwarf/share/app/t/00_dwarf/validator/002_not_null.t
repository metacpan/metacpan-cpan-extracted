use strict;
use warnings;
use Test::More tests => 12;
use Dwarf::Validator;
use Plack::Request;

{
	# optional value 'bar' with undefined string
	my $q = Plack::Request->new(
		{
			QUERY_STRING   => 'foo=1',
			REQUEST_METHOD => 'POST',
			'psgi.input'   => *STDIN,
		},
	);
	my $v = Dwarf::Validator->new($q);
	ok(!$v->has_error);
	$v->check(
		'foo' => [qw/NOT_NULL INT/],
		'baz' => [qw/INT/],
	);
	ok(!$v->has_error, 'has error');
	ok(!$v->is_error('foo'), 'foo');
	ok(!$v->is_error('baz'), 'baz');
}

{
	# optional value 'bar' with empty string
	my $q = Plack::Request->new(
		{
			QUERY_STRING   => 'foo=1&baz=',
			REQUEST_METHOD => 'POST',
			'psgi.input'   => *STDIN,
		},
	);
	my $v = Dwarf::Validator->new($q);
	ok(!$v->has_error);
	$v->check(
		'foo' => [qw/NOT_BLANK INT/],
		'baz' => [qw/INT/],
	);
	ok(!$v->has_error, 'has error');
	ok(!$v->is_error('foo'), 'foo');
	ok(!$v->is_error('baz'), 'baz');
}

{
	# not null with false value
	my $q = Plack::Request->new(
		{
			QUERY_STRING   => 'foo=0',
			REQUEST_METHOD => 'POST',
			'psgi.input'   => *STDIN,
		},
	);
	my $v = Dwarf::Validator->new($q);
	ok(!$v->has_error);
	$v->check(
		'foo' => [qw/NOT_NULL/],
		'baz' => [qw/INT/],
	);
	ok(!$v->has_error, 'has error');
	ok(!$v->is_error('foo'), 'foo');
	ok(!$v->is_error('baz'), 'baz');
}

