#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most tests => 10;
use Test::NoWarnings;

BEGIN { use_ok('CGI::Info') }

delete $ENV{'REMOTE_ADDR'};
delete $ENV{'HTTP_USER_AGENT'};

$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
$ENV{'REQUEST_METHOD'} = 'GET';
$ENV{'QUERY_STRING'} = '';

my $obj = new_ok('CGI::Info');
is($obj->as_string(), '', 'Returns empty string when params is empty');

$ENV{'QUERY_STRING'} = 'key=value';
$obj = new_ok('CGI::Info');
is($obj->as_string(), 'key=value', 'Single key-value pair without special characters');

$ENV{'QUERY_STRING'} = 'a=1&b=2';
$obj = new_ok('CGI::Info');
cmp_ok($obj->as_string(), 'eq', 'a=1;b=2', 'More than one key-value pair sorted by key');

$ENV{'QUERY_STRING'} = 'value=1&with=special\\chars';
$obj = new_ok('CGI::Info');
cmp_ok($obj->as_string(), 'eq', 'value=1;with=special\\\\chars', 'Handles special characters (;, =, \\) in values');
