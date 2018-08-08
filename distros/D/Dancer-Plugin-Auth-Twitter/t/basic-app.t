use strict;
use warnings;

use lib 't/lib';

use Dancer::Test;
use HTTP::Request::Common;
use Test::MockObject::Extends;
use Test::More import => ['!pass'];

use MyApp;

my %user = (
    id => 'bumblebee',
    access_token => 'abc123',
    access_token_secret => 'def456',
);

my $twitter = MyApp::twitter();

$twitter = Test::MockObject::Extends->new($twitter);

$twitter->set_always(oauth_authentication_url => 'https://twitter.burp/authenticate');
$twitter->set_always(oauth_authorization_url => 'https://twitter.burp/authorize');
$twitter->set_always(oauth_request_token => {
    oauth_token        => 'my_test_request_token',
    oauth_token_secret => 'my_test_request_token_secret',
});
$twitter->set_always(oauth_access_token => {
    oauth_token        => 'access_token',
    oauth_token_secret => 'access_token_secret',
});
#$twitter->set_always(access_token_secret => 'access_token_secret');
$twitter->mock('verify_credentials' => sub { return \%user });

$Dancer::Plugin::Auth::Twitter::_twitter = $twitter;

dancer_response GET => '/clear';

my $resp;

ok $resp = dancer_response(GET => '/'), 'got / from test app';
response_redirect_location_is $resp, $twitter->oauth_authentication_url,
    'Unauthenticated access redirects to authentication URL';

is(
    MyApp::session('request_token'),
    'my_test_request_token',
    'Request token is stored in session'
);
is(
    MyApp::session('request_token_secret'),
    'my_test_request_token_secret',
    'Request token secret is stored in session'
);

# Failed authentication
$resp = dancer_response GET => '/auth/twitter/callback?denied=1';
response_redirect_location_is $resp, 'http://localhost/fail',
    'Failed authentication redirects to callback_fail URL';

# after a failed authentication we must start over:
is(
    MyApp::session('request_token'),
    '',
    'Request token is cleared after failed login'
);
is(
    MyApp::session('request_token_secret'),
    '',
    'Request token secret is cleared after failed login'
);

ok $resp = dancer_response(GET => '/'), 'got / from test app (second time)';
response_redirect_location_is $resp, $twitter->oauth_authentication_url,
    'Unauthenticated access still redirects to authentication URL';

# Successful authentication
$resp = dancer_response GET => '/auth/twitter/callback?oauth_verifier=1';
response_redirect_location_is $resp, 'http://localhost/success',
    'Successful authentication redirects to callback_success';

is_deeply MyApp::session('twitter_user'), \%user,
    'Twitter user data is stored in session';


done_testing;
