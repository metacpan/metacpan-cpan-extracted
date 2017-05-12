package TestApp;

use strict;
use warnings;

use Catalyst 'Twitter';

our $VERSION = '0.01';

my ( $test_username, $test_password )
    = $ENV{TEST_TWITTER_DETAILS}
    ? split( /:/, $ENV{TEST_TWITTER_DETAILS}, 2 )
    : ( 'bob', 'secret' );

TestApp->config(
    name    => 'TestApp',
    twitter => {
        username => $test_username,
        password => $test_password,
    }
);

TestApp->setup;

1;
