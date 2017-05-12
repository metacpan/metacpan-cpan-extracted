#!perl -T

use strict;
use warnings;
use File::Spec;
use MIME::Base64;
use Test::More;

{
    package DancerApp;
    use Dancer;
    
    BEGIN {
        setting 'plugins' => {
            'Auth::Htpasswd' => {
                'paths' => {
                    '/secret.txt' => path(dirname(__FILE__), 'data', 'htpasswd')
                }
            }
        };
    }
    
    use Dancer::Plugin::Auth::Htpasswd;   

    setting 'public' => path(dirname(__FILE__), 'data', 'public');
}

use Dancer::Test;

my $response;

$response = dancer_response GET => '/hello.txt';
is $response->{status}, 200, 'Public path is accessible without authorization';

$response = dancer_response GET => '/secret.txt';
is $response->{status}, 401,
    'Protected path is not accessible without authorization';
is $response->{headers}->{'www-authenticate'},
    'Basic realm="Restricted area"',
    'The proper WWW-Authenticate header is returned';

$response = dancer_response(GET => '/secret.txt', { headers =>
    [ 'Authorization' => 'Basic ' . MIME::Base64::encode('joe:trustno1') ] });
is $response->{status}, 200,
    'Protected path is accessible after authorization';
   
done_testing;
