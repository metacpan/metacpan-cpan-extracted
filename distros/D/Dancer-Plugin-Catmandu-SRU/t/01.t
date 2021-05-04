#!/usr/bin/env perl

use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer;
use Dancer::Test;

use lib 't/lib';
use TestApp;

my $res;
foreach my $sru_route (qw(/sru /sru_override)) {
    response_status_is [ GET => $sru_route ], 200, "response for GET $sru_route is 200";

    response_status_isnt [ GET => $sru_route ], 404,
        "response for GET $sru_route is not a 404";

    $res = dancer_response( "GET", $sru_route,
        { params => { operation => "searchRetrieve"} } );
    like $res->{content}, qr/searchRetrieveResponse/, "Response ok for $sru_route";

    $res = dancer_response( "GET", $sru_route,
        { params => { operation => "explain" } } );
    like $res->{content}, qr/configInfo/, "Explain ok for $sru_route";
}

$res = dancer_response( "GET", "/sru_override",
    { params => { operation => "explain" } } );
like $res->{content}, qr/<default type=\"numberOfRecords\">50<\/default>/, "Overriden value ok";

done_testing;
