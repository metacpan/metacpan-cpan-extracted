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
            'Auth::Basic' => {
                'paths' => {
                    '/secret' => {
                        'users' => {
                            'crypt_blowfish' => '$2a$08$4DqiF8T1kUfj.' .
                                'nhxTj2VhuUt1ZX8L.y4aNA3PCAjWLfLEZCw8r0ei',
                            'rfc2307_cleartext' => '{CLEARTEXT}trustno1',
                            'rfc2307_md5' => '{MD5}X8/UHlR6EiFbFz/0f903OQ==',
                            'rfc2307_smd5' => '{SMD5}/Fxomrd4LPr+Hck1AKex8EA=',
                            # Invalid scheme
                            'rfc2307_invalid' => '{FOO}bar',
                            # Malformed passphrase data
                            'rfc2307_malformed' => '{MD5}0'
                        }
                    }
                }
            }
        };
    }
    
    use Dancer::Plugin::Auth::Basic;
    
    get '/public' => sub { };
    get '/secret' => sub { };
}

use Dancer::Test;

my $response;

$response = dancer_response GET => '/public';
is $response->{status}, 200, 'Public path is accessible without authorization';

$response = dancer_response GET => '/secret';
is $response->{status}, 401,
    'Protected path is not accessible without authorization';
is $response->{headers}->{'www-authenticate'},
    'Basic realm="Restricted area"',
    'The proper WWW-Authenticate header is returned';

$response = dancer_response(GET => '/secret', { headers =>
    [ 'Authorization' =>
        'Basic ' . MIME::Base64::encode('crypt_blowfish:trustno1') ] });
is $response->{status}, 200,
    'Protected path is accessible after authorization (Crypt Blowfish)';

$response = dancer_response(GET => '/secret', { headers =>
    [ 'Authorization' =>
        'Basic ' . MIME::Base64::encode('rfc2307_cleartext:trustno1') ] });
is $response->{status}, 200,
    'Protected path is accessible after authorization (RFC 2307 cleartext)';

$response = dancer_response(GET => '/secret', { headers =>
    [ 'Authorization' =>
        'Basic ' . MIME::Base64::encode('rfc2307_md5:trustno1') ] });
is $response->{status}, 200,
    'Protected path is accessible after authorization (RFC 2307 MD5)';

$response = dancer_response(GET => '/secret', { headers =>
    [ 'Authorization' =>
        'Basic ' . MIME::Base64::encode('rfc2307_smd5:trustno1') ] });
is $response->{status}, 200,
    'Protected path is accessible after authorization (RFC 2307 salted MD5)';

$response = dancer_response(GET => '/secret', { headers =>
    [ 'Authorization' =>
        'Basic ' . MIME::Base64::encode('rfc2307_invalid:bar') ] });
like read_logs->[0]->{message},
    qr/^Can't construct an Authen::Passphrase recognizer object/,
    'Error message is produced for invalid passphrase scheme';

$response = dancer_response(GET => '/secret', { headers =>
    [ 'Authorization' =>
        'Basic ' . MIME::Base64::encode('rfc2307_malformed:0') ] });
like read_logs->[0]->{message},
    qr/^Can't construct an Authen::Passphrase recognizer object/,
    'Error message is produced for malformed passphrase data';

done_testing;
