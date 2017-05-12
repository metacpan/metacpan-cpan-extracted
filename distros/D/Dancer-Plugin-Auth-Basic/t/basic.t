#!perl -T

use strict;
use warnings;
use File::Spec;
use MIME::Base64;
use Test::More;

my $remote_user;

{
    package DancerApp;
    use Dancer;
    
    BEGIN {
        setting 'plugins' => {
            'Auth::Basic' => {
                'paths' => {
                    '/secret-1' => {
                        user => 'alice',
                        password => 'wonderland'
                    }
                }
            }
        };
    }
    
    use Dancer::Plugin::Auth::Basic;   
    
    hook before => sub {
        if (request->path =~ m!^/secret-2!) {
            auth_basic realm => 'Secret lair',
                user => 'alice', password => 'wonderland' 
        }
    };
    
    get '/public' => sub { };
    get '/secret-1' => sub { };
    get '/secret-1/:param' => sub { };
    get '/secret-2' => sub { };
    get '/secret-3' => sub {
        auth_basic user => 'alice', password => 'wonderland' 
    };
    get '/secret-2/user' => sub {
        $remote_user = request->user;
    };
}

use Dancer::Test;

my $response;

$response = dancer_response GET => '/public';
is $response->{status}, 200, 'Public path is accessible without authorization';

$response = dancer_response GET => '/secret-1';
is $response->{status}, 401,
    'Protected path is not accessible without authorization';
is $response->{headers}->{'www-authenticate'},
    'Basic realm="Restricted area"',
    'The proper WWW-Authenticate header is returned';

$response = dancer_response(GET => '/secret-1', { headers =>
    [ 'Authorization' => 'Basic ' .
        MIME::Base64::encode('alice:wonderland') ] });
is $response->{status}, 200,
    'Protected path is accessible after authorization';

$response = dancer_response(GET => '/secret-1', { headers =>
    [ 'Authorization' => 'Basic ' . MIME::Base64::encode('alice:hunter1') ] });
is $response->{status}, 401,
    'Protected path is not accessible if wrong password is given';
    
$response = dancer_response(GET => '/secret-1', { headers =>
    [ 'Authorization' => 'Basic ' .
        MIME::Base64::encode('joe:wonderland') ] });
is $response->{status}, 401,
    'Protected path is not accessible if wrong user name is given';
    
$response = dancer_response GET => '/secret-1/foo';
is $response->{status}, 401,
    'Protected sub-path is not accessible without authorization';

$response = dancer_response(GET => '/secret-1/foo', { headers =>
    [ 'Authorization' => 'Basic ' .
        MIME::Base64::encode('alice:wonderland') ] });
is $response->{status}, 200,
    'Protected sub-path is accessible after authorization';

$response = dancer_response GET => '/secret-2';
is $response->{status}, 401,
    'Path protected in a before filter is not accessible without authorization';
is $response->{headers}->{'www-authenticate'},
    'Basic realm="Secret lair"',
    'The proper WWW-Authenticate header is returned';

$response = dancer_response(GET => '/secret-2', { headers =>
    [ 'Authorization' => 'Basic ' .
        MIME::Base64::encode('alice:wonderland') ] });
is $response->{status}, 200,
    'Path protected in a before filter is accessible after authorization';
    
$response = dancer_response GET => '/secret-3';
is $response->{status}, 401,
    'Path protected in route handler is not accessible without authorization';

$response = dancer_response(GET => '/secret-3', { headers =>
    [ 'Authorization' => 'Basic ' .
        MIME::Base64::encode('alice:wonderland') ] });
is $response->{status}, 200,
    'Path protected in route handler is accessible after authorization';
    
dancer_response(GET => '/secret-2/user', { headers =>
    [ 'Authorization' => 'Basic ' .
        MIME::Base64::encode('alice:wonderland') ] });
is $remote_user, 'alice', 'The remote user is set correctly';
    
done_testing;
