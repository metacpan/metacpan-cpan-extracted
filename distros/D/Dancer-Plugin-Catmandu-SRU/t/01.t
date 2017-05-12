#!/usr/bin/env perl

use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer;
use Dancer::Test;

use lib 't/lib';
use TestApp;

response_status_is [ GET => '/sru' ], 200, "response for GET /sru is 200";

response_status_isnt [ GET => '/sru' ], 404,
    "response for GET /sru is not a 404";

my $res;
$res = dancer_response( "GET", '/sru',
    { params => { operation => "searchRetrieve"} } );
like $res->{content}, qr/searchRetrieveResponse/, "Response ok";

$res = dancer_response( "GET", '/sru',
    { params => { operation => "explain" } } );
like $res->{content}, qr/configInfo/, "Explain ok";

done_testing 4;
