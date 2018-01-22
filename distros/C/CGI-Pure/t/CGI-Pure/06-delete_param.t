use strict;
use warnings;

use CGI::Pure;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = CGI::Pure->new;
$obj->append_param('foo', 'aaa');
$obj->append_param('bar', 'bbb');
my @ret = $obj->param;
is_deeply(
	\@ret,
	['bar', 'foo'],
	'Create object with two CGI parameters.',
);
$obj->delete_param('foo');
@ret = $obj->param;
is_deeply(
	\@ret,
	['bar'],
	"Object after removing of 'foo' CGI parameter.",
);
$obj->delete_param('bar');
@ret = $obj->param;
is_deeply(
	\@ret,
	[],
	"Object after removing of 'bar' CGI parameter.",
);
