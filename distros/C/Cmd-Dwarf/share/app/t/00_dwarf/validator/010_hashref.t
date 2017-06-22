use strict;
use warnings;
use Test::More tests => 8;
use Test::Requires 'Plack::Request';
use Dwarf::Validator;
use Plack::Request;

my $q = {
	foo => 'bar'
};

my $v = Dwarf::Validator->new($q);
ok(!$v->has_error);
is($v->query->query, $q);
$v->check(
	'foo' => [qw/NOT_NULL/],
	'baz' => [qw/NOT_NULL/],
);
ok($v->has_error);
ok(!$v->is_error('foo'));
ok($v->is_error('baz'), 'baz');

ok(!$v->is_error('boy'));
$v->set_error('boy' => 'is_girl');
ok($v->is_error('boy'));

is_deeply(
	$v->errors,
	{
		'baz' => {
			'NOT_NULL' => 1
		},
		'boy' => {
			'is_girl' => 1
		},
	},
	'errors()',
);
