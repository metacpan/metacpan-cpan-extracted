use strict;
use warnings;

use CGI::Pure;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = CGI::Pure->new(
	'init' => {'foo' => '1', 'bar' => [2, 3, 4]},
);
my $ret = $obj->delete_all_params;
is($ret, undef);
my @params = $obj->param;
is_deeply(
	\@params,
	[],
);
