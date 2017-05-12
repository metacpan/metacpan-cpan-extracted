use strict;
use Plack::Test;
use Test::More tests => 8;
use HTTP::Request;
use HTTP::Request::Common;
use URI;
use URI::QueryParam;
use JSON;

{
    package testState;
    BEGIN { $ENV{DANCER_ENVIRONMENT} = 'uri'; }
    use Dancer2;
    use Dancer2::Plugin::OAuth2::Server;
}

my $app = testState->to_app;
my $test = Plack::Test->create($app);

my $request  = HTTP::Request->new( GET => '/oauth/authorize' );
my $response = $test->request($request);
is $response->code, 400, "Default authorize route created";

my $uri = URI->new( '/oauth/authorize' );
$uri->query_param( client_id => 'client1' );
$uri->query_param( redirect_uri => 'http://localhost/wrongcb' );
$uri->query_param( response_type => 'code' );
$uri->query_param( scope => 'other' );
$request  = HTTP::Request->new( GET => $uri );
$response = $test->request($request);
is $response->code, 302, "Get a redirection header redirect_uri not correct";
my $cburi = URI->new( $response->header('location') );
my $error = $cburi->query_param( 'error' );
my $code = $cburi->query_param( 'code' );
is $error, 'unauthorized_uri', "error provided";
ok !$code, "and authorization code is not provided";

#add state parameter to the query
$uri->query_param( redirect_uri => 'http://localhost/cb' );
$request  = HTTP::Request->new( GET => $uri );
$response = $test->request($request);
is $response->code, 302, "Get a redirection header with the first whitelisted uri";
$cburi = URI->new( $response->header('location') );
$code = $cburi->query_param( 'code' );
ok $code, "and authorization code is provided";

$uri->query_param( redirect_uri => 'http://localhost/callback' );
$request  = HTTP::Request->new( GET => $uri );
$response = $test->request($request);
is $response->code, 302, "Get a redirection header with the second whitelisted uri";
$cburi = URI->new( $response->header('location') );
$code = $cburi->query_param( 'code' );
ok $code, "and authorization code is provided";

1;
