use strict;
use warnings;
use Test::More tests => 5;
use Dwarf::Validator;
use Plack::Request;

my $q = Plack::Request->new(
		{
			QUERY_STRING   => 'foo=00:00&bar=ppppp',
			REQUEST_METHOD => 'POST',
			'psgi.input'   => *STDIN,
		},
	);
my $v = Dwarf::Validator->new($q);
$v->load_constraints('+Dwarf::Validator::Constraint');
ok(!$v->has_error);
is($v->query, $q);
$v->check(
    'foo' => [qw/TIME NOT_NULL/],
    'bar' => [qw/TIME NOT_NULL/],
);
ok($v->has_error);
ok(!$v->is_error('foo'));
ok($v->is_error('bar'));

