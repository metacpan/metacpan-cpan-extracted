# Pragmas.
use strict;
use warnings;

# Modules.
use CGI::Pure;
use IO::Scalar;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = CGI::Pure->new(
	'init' => {'foo' => '1', 'bar' => [2, 3, 4]},
);
my $ret = $obj->query_string;
is($ret, 'bar=2&bar=3&bar=4&foo=1');

# Test.
$ENV{'CONTENT_LENGTH'} = 32;
$ENV{'REQUEST_METHOD'} = 'POST';
my $tmp = IO::Scalar->new(\"color=red&color=green&color=blue");
local *STDIN = $tmp;
$obj = CGI::Pure->new;
$ret = $obj->query_string;
is($ret, "color=blue&color=green&color=red");

# Test.
# TODO Multipart.

# Test.
$ENV{'QUERY_STRING'} = 'color=red&color=green&color=blue';
$ENV{'REQUEST_METHOD'} = 'GET';
$obj = CGI::Pure->new;
$ret = $obj->query_string;
is($ret, 'color=blue&color=green&color=red');

# Test.
$ENV{'QUERY_STRING'} = 'utf8_string=%C4%9B%C5%A1%C4%8D%C5%99%C5%BE'.
	'%C3%BD%C3%A1%C3%AD%C3%A9%C3%B3';
$ENV{'REQUEST_METHOD'} = 'GET';
$obj = CGI::Pure->new;
$ret = $obj->query_string;
my $right_ret = 'utf8_string=%C4%9B%C5%A1%C4%8D%C5%99%C5%BE'.
	'%C3%BD%C3%A1%C3%AD%C3%A9%C3%B3';
is($ret, $right_ret, 'QUERY_STRING with encoded utf8 string.');
