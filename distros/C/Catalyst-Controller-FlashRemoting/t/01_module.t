use strict;
use warnings;

use Test::Base;

use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');

use Catalyst::Test 'TestApp';

plan tests => 6;

use HTTP::Request;

use Data::AMF::Packet;
use Data::AMF::Message;

my $amf_req = Data::AMF::Packet->new(
    version  => 0,
    headers  => [],
    messages => [
        Data::AMF::Message->new(
            version      => 0,
            target_uri   => 'echo',
            response_uri => '/1',
            value        => 'foo bar',
            length => -1,
        ),
    ],
);

my $http_req = HTTP::Request->new( POST => 'http://localhost/' );

$http_req->content( $amf_req->serialize );

$http_req->header( 'Content-Type'   => 'application/x-amf' );
$http_req->header( 'Content-Length' => length $http_req->content );


ok( my $res = request($http_req), 'request ok' );
ok( $res->is_success, 'request success' );

is( $res->content_type, 'application/x-amf', 'response type ok' );

my $amf_res = Data::AMF::Packet->deserialize($res->content);

is( $amf_res->version, $amf_req->version, 'response version ok' );

my $result = $amf_res->messages->[0];

is( $result->target_uri, '/1/onResult', 'response target ok' );
is( $result->value, $amf_req->messages->[0]->value, 'response ok' );

