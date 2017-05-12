# Pragmas.
use strict;
use warnings;

# Modules.
use CGI::Pure;
use IO::Scalar;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = CGI::Pure->new(
	'init' => {'foo' => '1', 'bar' => [2, 3, 4]},
);
my $ret = $obj->query_data;
is($ret, 'Not saved query data.');

# Test.
$obj = CGI::Pure->new(
	'init' => {'foo' => '1', 'bar' => [2, 3, 4]},
	'save_query_data' => 1,
);
$ret = $obj->query_data;
is($ret, '');

# Test.
$obj = CGI::Pure->new(
	'init' => 'color=red&color=green&color=blue',
	'save_query_data' => 1,
);
$ret = $obj->query_data;
is($ret, '');

# Test.
$ENV{'CONTENT_LENGTH'} = 33;
$ENV{'REQUEST_METHOD'} = 'POST';
my $tmp = IO::Scalar->new(\"color=red&color=green&color=blue\n");
local *STDIN = $tmp;
$obj = CGI::Pure->new(
	'save_query_data' => 1,
);
$ret = $obj->query_data;
is($ret, "color=red&color=green&color=blue\n");

# Test.
# TODO Multipart.

# Test.
$ENV{'QUERY_STRING'} = 'color=red&color=green&color=blue';
$ENV{'REQUEST_METHOD'} = 'GET';
$obj = CGI::Pure->new(
	'save_query_data' => 1,
);
$ret = $obj->query_data;
is($ret, 'color=red&color=green&color=blue');
