use strict;
use warnings;

use CGI::Pure;
use Error::Pure::Utils qw(clean);
use English qw(-no_match_vars);
use Test::More 'tests' => 26;
use Test::NoWarnings;

# Test.
my $obj = CGI::Pure->new;
isa_ok($obj, 'CGI::Pure');

# Test.
eval {
	CGI::Pure->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", "Unknown parameter ''.");
clean();

# Test.
eval {
	CGI::Pure->new(
		'par_sep' => '+',
	);
};
is($EVAL_ERROR, "Bad parameter separator '+'.\n",
	"Bad parameter separator '+'.");
clean();

# Test.
$obj = CGI::Pure->new(
	'par_sep' => ';',
);
isa_ok($obj, 'CGI::Pure');

# Test.
$obj = CGI::Pure->new(
	'init' => {'foo' => '1', 'bar' => [2, 3, 4]},
	'utf8' => 1,
);
my @params = $obj->param;
is_deeply(
	\@params,
	[
		'bar',
		'foo',
	],
	'Init hash in utf8 mode: CGI parameters.',
);
is($obj->param('foo'), 1, 'Init hash in utf8 mode: Scalar CGI parameter '.
	'value.');
is($obj->param('bar'), 2, 'Init hash in utf8 mode: Array CGI parameter '.
	'values - first.');
@params = $obj->param('bar');
is_deeply(
	\@params,
	[2, 3, 4],
	'Init hash in utf8 mode: Array CGI parameter values.',
);

# Test.
$obj = CGI::Pure->new(
	'init' => {'foo' => '1', 'bar' => [2, 3, 4]}, 
	'utf8' => 0
);
@params = $obj->param;
is_deeply(
	\@params,
	[
		'bar',
		'foo',
	],
	'Init hash in ascii mode: CGI parameters.',
);
is($obj->param('foo'), 1, 'Init hash in ascii mode: Scalar CGI parameter '.
	'value.');
is($obj->param('bar'), 2, 'Init hash in ascii mode: Array CGI parameter '.
	'values - first.');
@params = $obj->param('bar');
is_deeply(
	\@params,
	[2, 3, 4],
	'Init hash in ascii mode: Array CGI parameter values.',
);

# Test.
$obj = CGI::Pure->new(
	'init' => 'foo=5&bar=6&bar=7&bar=8',
	'utf8' => 1,
);
@params = $obj->param;
is_deeply(
	\@params,
	[
		'bar',
		'foo',
	],
	'Init query string in utf8 mode: CGI parameters.',
);
is($obj->param('foo'), 5, 'Init query string in utf8 mode: Scalar CGI '.
	'parameter value.');
is($obj->param('bar'), 6, 'Init query string in utf8 mode: Array CGI '.
	'parameter values - first.');
@params = $obj->param('bar');
is_deeply(
	\@params,
	[6, 7, 8],
	'Init query string in utf8 mode: Array CGI parameter values.',
);

# Test.
$obj = CGI::Pure->new(
	'init' => 'foo=5&bar=6&bar=7&bar=8',
	'utf8' => 0,
);
@params = $obj->param;
is_deeply(
	\@params,
	[
		'bar',
		'foo',
	],
	'Init query string in ascii mode: CGI parameters.',
);
is($obj->param('foo'), 5, 'Init query string in ascii mode: Scalar CGI '.
	'parameter value.');
is($obj->param('bar'), 6, 'Init query string in ascii mode: Array CGI '.
	'parameter values - first.');
@params = $obj->param('bar');
is_deeply(
	\@params,
	[6, 7, 8],
	'Init query string in ascii mode: Array CGI parameter values.',
);

# Test.
my $old_obj = $obj;
$obj = CGI::Pure->new(
	'init' => $old_obj,
);
@params = $obj->param;
is_deeply(
	\@params,
	[
		'bar',
		'foo',
	],
	'Init CGI::Pure object: CGI parameters.',
);
is($obj->param('foo'), 5, 'Init CGI::Pure object: Scalar CGI '.
	'parameter value.');
is($obj->param('bar'), 6, 'Init CGI::Pure object: Array CGI '.
	'parameter values - first.');
@params = $obj->param('bar');
is_deeply(
	\@params,
	[6, 7, 8],
	'Init CGI::Pure object: Array CGI parameter values.',
);

# Test.
$ENV{'QUERY_STRING'} = 'name=JaPh%2C&color=red&color=green&color=blue';
$ENV{'REQUEST_METHOD'} = 'GET';
$obj = CGI::Pure->new;
@params = $obj->param;
is_deeply(
	\@params,
	[
		'color',
		'name',
	],
	'Environment query string: CGI parameters.',
);
