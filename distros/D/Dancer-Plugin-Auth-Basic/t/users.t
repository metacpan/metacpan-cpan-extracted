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
                        users => {
                            'scott' => 'summers',
                            'hank' => 'mccoy'
                        }
                    },
                    '/secret-2' => {
                        users => {
                            'reed' => 'richards',
                            'ben' => 'grimm'
                        }
                    },
                    '/secret-3' => {
                    }
                },
                'users' => {
                    'steve' => 'rogers',
                    'tony' => 'stark'
                }
            }
        };
    }
    
    use Dancer::Plugin::Auth::Basic;   
    
    get '/secret-1' => sub {
        $remote_user = request->user;
    };
    get '/secret-2' => sub {
        $remote_user = request->user;       
    };
    get '/secret-3' => sub {
        $remote_user = request->user;
    };
}

use Dancer::Test;

my $response;

$response = dancer_response GET => '/secret-1';
is $response->{status}, 401,
    'Protected path is not accessible without authorization';

$response = dancer_response(GET => '/secret-1', { headers =>
    [ 'Authorization' => 'Basic ' .
        MIME::Base64::encode('scott:summers') ] });
is $response->{status}, 200,
    'Protected path is accessible for first user';

is $remote_user, 'scott', 'The remote user is set correctly';

$response = dancer_response(GET => '/secret-1', { headers =>
    [ 'Authorization' => 'Basic ' .
        MIME::Base64::encode('hank:mccoy') ] });
is $response->{status}, 200,
    'Protected path is accessible for second user';

$response = dancer_response(GET => '/secret-1', { headers =>
    [ 'Authorization' => 'Basic ' .
        MIME::Base64::encode('steve:rogers') ] });
is $response->{status}, 200,
    'Protected path is accessible for top-level user';

$response = dancer_response GET => '/secret-2';
is $response->{status}, 401,
    'Second protected path is not accessible without authorization';

$response = dancer_response(GET => '/secret-2', { headers =>
    [ 'Authorization' => 'Basic ' .
        MIME::Base64::encode('reed:richards') ] });
is $response->{status}, 200,
    'Second protected path is accessible for first user';

is $remote_user, 'reed', 'The remote user is set correctly';
    
$response = dancer_response(GET => '/secret-2', { headers =>
    [ 'Authorization' => 'Basic ' .
        MIME::Base64::encode('ben:grimm') ] });
is $response->{status}, 200,
    'Second protected path is accessible for second user';

$response = dancer_response(GET => '/secret-2', { headers =>
    [ 'Authorization' => 'Basic ' .
        MIME::Base64::encode('tony:stark') ] });
is $response->{status}, 200,
    'Second protected path is accessible for top-level user';

$response = dancer_response GET => '/secret-3';
is $response->{status}, 401,
    'Third protected path is not accessible without authorization';

$response = dancer_response(GET => '/secret-3', { headers =>
    [ 'Authorization' => 'Basic ' .
        MIME::Base64::encode('steve:rogers') ] });
is $response->{status}, 200,
    'Third protected path is accessible for first top-level user';

$response = dancer_response(GET => '/secret-3', { headers =>
    [ 'Authorization' => 'Basic ' .
        MIME::Base64::encode('tony:stark') ] });
is $response->{status}, 200,
    'Third protected path is accessible for second top-level user';

is $remote_user, 'tony', 'The remote user is set correctly';
    
done_testing;
