use strict;
use warnings;

use CGI::Pure;
use English;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $obj = CGI::Pure->new;
my @ret = $obj->append_param('param', 'foo');
is_deeply(
	\@ret,
	[
		'foo',
	],
	'Add parameter value.',
);

# Test.
@ret = $obj->append_param('param', 'bar');
is_deeply(
	\@ret,
	[
		'bar',
		'foo',
	],
	'Add another parameter value.',
);

# Test.
$obj = CGI::Pure->new;
@ret = $obj->append_param('param', undef);
is_deeply(
	\@ret,
	[],
	'Undefined parameters not append.',
);

# Test.
$obj = CGI::Pure->new(
	'init' => {
		'param' => 'baz',
	},
);
@ret = $obj->append_param('param', ['foo', 'bar']);
is_deeply(
	\@ret,
	[
		'bar',
		'baz',
		'foo',
	],
	'Add parameters with reference to array.',
);

# Test.
$obj = CGI::Pure->new;
@ret = $obj->append_param('param', 'foo', ['bar'], 'baz');
is_deeply(
	\@ret,
	[
		'bar',
		'baz',
		'foo',
	],
	'Add mixture of scalar and reference to array parameters.',
);

# Test.
$obj = CGI::Pure->new;
eval {
	$obj->append_param('param', {});
};
is($EVAL_ERROR, "Parameter 'param' has bad value.\n",
	"Parameter 'param' has bad value - reference to hash.");

# Test.
$obj = CGI::Pure->new;
eval {
	$obj->append_param('param', CGI::Pure->new);
};
is($EVAL_ERROR, "Parameter 'param' has bad value.\n",
	"Parameter 'param' has bad value - object instance.");
