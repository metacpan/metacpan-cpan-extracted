#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
BEGIN { plan skip_all => 'Broken tests'; exit; }

use Catalyst::Test 'TestApp';
use RPC::XML;

BEGIN {
    no warnings 'redefine';

    *Catalyst::Test::local_request = sub {
        my ( $class, $request ) = @_;

        require HTTP::Request::AsCGI;
        my $cgi = HTTP::Request::AsCGI->new( $request, %ENV )->setup;

        $class->handle_request;

        return $cgi->restore->response;
    };
}

# init
$RPC::XML::ENCODING = 'UTF-8';
my $entrypoint = 'http://localhost/rpc';

run_tests();

sub run_tests {

    # test echo
    {
        my $content =
          RPC::XML::request->new( 'myAPI.echo', 'hello' )->as_string;
        my $request = HTTP::Request->new( POST => $entrypoint );
        $request->header( 'Content-Length' => length($content) );
        $request->header( 'Content-Type'   => 'text/xml' );
        $request->content($content);

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        my $expected = RPC::XML::response->new('hello')->as_string;
        is( $response->content, $expected, 'Content OK' );
    }

    # test add
    {
        my $content =
          RPC::XML::request->new( 'plugin.xmlrpc.add', ( 1, 2 ) )->as_string;
        my $request = HTTP::Request->new( POST => $entrypoint );
        $request->header( 'Content-Length' => length($content) );
        $request->header( 'Content-Type'   => 'text/xml' );
        $request->content($content);

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        my $expected = RPC::XML::response->new('3')->as_string;
        is( $response->content, $expected, 'Content OK' );
    }
}
