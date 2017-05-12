
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Encode;
use Test::More tests => 7;
use Catalyst::Test 'TestApp';
use RDF::Simple::Parser;

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

my $entrypoint = "http://localhost/foo";

{
    my $request = HTTP::Request->new( GET => $entrypoint );
    ok( my $response = request($request), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->code, 200, 'Response Code' );
    is_deeply( [ $response->content_type ],
        [ 'application/rdf', 'charset=utf-8' ] );

    ok( my $rdf = $response->content );
    my $parser = RDF::Simple::Parser->new();
    ok( my $triples = $parser->parse_rdf($rdf) );

    is( $triples, 9 );
}

