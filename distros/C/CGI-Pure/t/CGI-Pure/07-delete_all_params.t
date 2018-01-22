use strict;
use warnings;

use CGI::Pure;
use Test::More 'tests' => 3;
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
$obj->delete_all_params;
@ret = $obj->param;
is_deeply(
	\@ret,
	[],
	"Object after removing of all CGI parameters.",
);
