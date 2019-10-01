use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer;
use Dancer::Test;

use lib 't/lib';
use TestApp;

response_status_is [GET => '/oai'], 200, "response for GET /oai is 200";

response_status_is [POST => '/oai'], 200, "response for POST /oai is 200";

response_status_isnt [GET => '/oai'], 404,
    "response for GET /oai is not a 404";

response_content_like [GET => '/oai'], qr/illegal OAI verb/,
    "got expected response content for GET /oai";

my $res;
$res = dancer_response("GET", '/oai', {params => {verb => "Identify"}});
like $res->{content}, qr/request verb="Identify"/, "Identify";

$res = dancer_response("GET", '/oai',
    {params => {verb => "ListMetadataFormats"}});
like $res->{content}, qr/request verb="ListMetadataFormats"/,
    "ListMetadataFormats";

$res = dancer_response("GET", '/oai', {params => {verb => "ListSets"}});
like $res->{content}, qr/setSpec>journal_article<\/setSpec/, "ListSets";

done_testing;
