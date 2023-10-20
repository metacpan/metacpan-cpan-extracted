#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok 'API::Vultr';
}

use API::Vultr;
use Test::LWP::UserAgent;

my $vultr_api = API::Vultr->new( api_key => 'foo' );

is $vultr_api->api_key, 'foo';
ok $vultr_api->ua;
isa_ok $vultr_api->ua, 'LWP::UserAgent';

$vultr_api->ua( Test::LWP::UserAgent->new );
isa_ok $vultr_api->ua, 'Test::LWP::UserAgent';

$vultr_api->api_key('123');
is $vultr_api->api_key, '123';

is $vultr_api->_make_uri( '/foo', foo => 'bar' ),
  'https://api.vultr.com/v2/foo?foo=bar';

my $application_json = '{
    "applications": 
[
{

    "id": 1,
    "name": "LEMP",
    "short_name": "lemp",
    "deploy_name": "LEMP on CentOS 6 x64",
    "type": "one-click",
    "vendor": "vultr",
    "image_id": ""

},
    {
        "id": 1028,
        "name": "OpenLiteSpeed WordPress",
        "short_name": "openlitespeedwordpress",
        "deploy_name": "OpenLiteSpeed WordPress on Ubuntu 20.04 x64",
        "type": "marketplace",
        "vendor": "LiteSpeed_Technologies",
        "image_id": "openlitespeed-wordpress"
    }
],
"meta": 
{
    "total": 2,
    "links": 
        {
            "next": "",
            "prev": ""
        }
    }
}';

$vultr_api->ua->map_response(
    qr{api.vultr.com/v2/applications},
    HTTP::Response->new(
        '200',                                    'OK',
        [ 'Content-Type' => 'application/json' ], $application_json
    )
);
ok $vultr_api->get_applications->is_success;
ok $vultr_api->get_applications->decoded_content, $application_json;

ok $vultr_api->ua->last_http_request_sent;
is $vultr_api->ua->last_http_request_sent->header('Authorization'),
  'Bearer 123';
is $vultr_api->ua->last_http_request_sent->uri,
  'https://api.vultr.com/v2/applications';
ok $vultr_api->ua->last_http_response_received->is_success;
is $vultr_api->ua->last_http_response_received->decoded_content,
  $application_json;

$vultr_api->ua->map_response(
    qr{api.vultr.com/v2/instances},
    HTTP::Response->new(
        '200',                                    'OK',
        [ 'Content-Type' => 'application/json' ], $application_json
    )
);

ok $vultr_api->create_instance( name => 'foo' )->is_success;
is $vultr_api->ua->last_http_request_sent->uri,
  'https://api.vultr.com/v2/instances';
is $vultr_api->ua->last_http_request_sent->method, 'POST';
is_deeply $vultr_api->ua->last_http_request_sent->content, { name => 'foo' };

done_testing;
