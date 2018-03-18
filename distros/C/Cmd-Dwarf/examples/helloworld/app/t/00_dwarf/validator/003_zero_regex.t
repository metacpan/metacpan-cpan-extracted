use strict;
use warnings;
use Test::More tests => 6;
use Dwarf::Validator;
use Plack::Request;

{
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
		'foo' => [['REGEX' => qr/\d/]],
		'baz' => [qw/INT/],
	);
	ok(!$v->has_error, 'has error');
	ok(!$v->is_error('foo'), 'foo');
	ok(!$v->is_error('baz'), 'baz');
}

{
	my $q = Plack::Request->new(
		{
			QUERY_STRING   => 'foo=0',
			REQUEST_METHOD => 'POST',
			'psgi.input'   => *STDIN,
		},
	);
	my $v = Dwarf::Validator->new($q);
	$v->check(
		'foo'=> [['REGEX' => qr/a/]],
	);
	ok($v->has_error, 'has error');
	ok($v->is_error('foo'), 'foo');
}

