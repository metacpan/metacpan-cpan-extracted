use strict;
use Plack::Test;
use Test::More tests => 4;
use HTTP::Request;
use HTTP::Request::Common;
use URI;
use URI::QueryParam;
use JSON;

{
    package testState;
    BEGIN { $ENV{DANCER_ENVIRONMENT} = 'state'; }
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
$uri->query_param( redirect_uri => 'http://localhost/callback' );
$uri->query_param( response_type => 'code' );
$uri->query_param( scope => 'other' );
$request  = HTTP::Request->new( GET => $uri );
$response = $test->request($request);
is $response->code, 400, "State needed when state_required is set to 1";

#add state parameter to the query
$uri->query_param( state => 'mystate' );
$request  = HTTP::Request->new( GET => $uri );
$response = $test->request($request);
is $response->code, 302, "Get a redirection header";

$uri = URI->new( $response->header('location') );
is $uri->query_param( 'state' ), 'mystate', "State returned succesfully";

1;
