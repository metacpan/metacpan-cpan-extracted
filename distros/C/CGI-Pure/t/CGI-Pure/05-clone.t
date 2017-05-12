# Pragmas.
use strict;
use warnings;

# Modules.
use CGI::Pure;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = CGI::Pure->new;
$obj->append_param('foo', 'bar');
my $obj_other = CGI::Pure->new;
$obj_other->append_param('aaa', 'bbb');
$obj->clone($obj_other);
my @ret = $obj->param;
is_deeply(
	\@ret,
	['aaa', 'foo'],
	'Clone parameters from another CGI::Pure to mine.',
);
