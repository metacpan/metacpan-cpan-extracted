#!perl

use strict;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::More;
use Catalyst::Test 'TestApp';

my $content;
my $response;

$content  = get('index');
is( $content, 'index', 'correct body for index' );

$content  = get('/open');
is( $content, 'open', 'correct body for open' );

# This will fail
$content  = get('/close');
is( $content, 'denied', 'correct body for close' );

$content = get('/submit');
is( $content, 'denied', 'correct body for submit GET' );

use HTTP::Request::Common;
$response = request PUT '/submit', [
    nonsense_value => 'This will not even be looked at by the application. How sad.'
];
is($response->content, 'denied', 'PUT gets denied');


$response = request POST '/submit', [
    return_value => 'This is a message from a POST',
    nonsense_value => 'This will not even be looked at by the application. How sad.'
];
is($response->content, 'This is a message from a POST', 'Correct body for POST');


done_testing;
