use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 8;
use Catalyst::Test 'TestApp';
use JSON ();

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

my $entrypoint = 'http://localhost/rpc';

run_tests();

sub run_tests {

    # test echo
    {
        my $content = JSON::objToJson({ method => 'echo', params => [ 'hello' ], id => 1 });
        my $request = HTTP::Request->new( POST => $entrypoint );
        $request->header( 'Content-Length' => length($content) );
        $request->header( 'Content-Type'   => 'text/javascript+json' );
        $request->content($content);

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        my $expected = JSON::objToJson({ error => undef, id => 1, result => 'hello' });
        is( $response->content, $expected, 'Content OK' );

    }

    # test add
    {
        my $content = JSON::objToJson({ method => 'add', params => [ 1, 2 ], id => 2 });
        my $request = HTTP::Request->new( POST => $entrypoint );
        $request->header( 'Content-Length' => length($content) );
        $request->header( 'Content-Type'   => 'text/xml' );
        $request->content($content);

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        my $expected = JSON::objToJson({ error => undef, id => 2, result => 3 });
        is( $response->content, $expected, 'Content OK' );
    }
}
