use strict;
use warnings;
use Test::More import => ['!pass'];
use JSON ();

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestApp;
use Dancer qw/:syntax/;
use Dancer::Test apps => ['TestApp'];

diag( 'Dancer Version : ', Dancer->VERSION );
my $response = dancer_response 'GET' => '/';
ok $response, 'We should be able to call our routes';
is_deeply JSON::decode_json( $response->content ), [qw/get foo/],
    '... it should have called Redis internally';

done_testing;
