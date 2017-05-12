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
                            'rfc2307_cleartext' => '{CLEARTEXT}trustno1',
                        }
                    }
                }
            }
        };
    }
    
    use lib path(dirname(__FILE__), 'data', 'skip_lib');
    use Dancer::Plugin::Auth::Basic;
    
    get '/secret' => sub { };
}

use Dancer::Test;

my $response;

$response = dancer_response(GET => '/secret', { headers =>
    [ 'Authorization' =>
        'Basic ' . MIME::Base64::encode('rfc2307_cleartext:trustno1') ] });
like read_logs->[0]->{message},
    qr/^Can't use Authen::Passphrase/,
    'Error message is produced when Authen::Passphrase can\'t be used';

done_testing;
