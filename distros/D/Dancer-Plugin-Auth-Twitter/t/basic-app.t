use strict;
use warnings;

use lib 't/lib';

use Dancer::Test;
use HTTP::Request::Common;
use Test::MockObject::Extends;
use Test::More import => ['!pass'];
use Class::Load qw/ try_load_class /;

use MyApp;

my %user = (
    id => 'bumblebee',
    access_token => 'abc123',
    access_token_secret => 'def456',
);

for my $engine ( qw/ Net::Twitter Net::Twitter::Lite::WithAPIv1_1 / ) {
    subtest "engine $engine" => sub {
        plan skip_all => "test needs module $engine" 
            unless try_load_class($engine);

        MyApp::change_engine($engine);
        my $twitter = MyApp::twitter();

        $twitter = Test::MockObject::Extends->new($twitter);

        $twitter->set_always(get_authentication_url => 'https://twitter.burp/auth');
        $twitter->set_always(request_token => 'request_token');
        $twitter->set_always(request_token_secret => 'request_token_secret');
        $twitter->set_always(request_access_token => 'request_access_token');
        $twitter->set_always(access_token => 'access_token');
        $twitter->set_always(access_token_secret => 'access_token_secret');
        $twitter->mock('verify_credentials' => sub { return \%user });

        $Dancer::Plugin::Auth::Twitter::_twitter = $twitter;

        dancer_response GET => '/clear';

        my $resp;

        $resp = dancer_response GET => '/';
        response_redirect_location_is $resp, $twitter->get_authentication_url,
            'Unauthenticated access redirects to authentication URL';

        ok defined MyApp::session('request_token'), 'Request token is stored in session';

        # Failed authentication
        $resp = dancer_response GET => '/auth/twitter/callback?denied=1';
        response_redirect_location_is $resp, 'http://localhost/fail',
            'Failed authentication redirects to callback_fail URL';

        # Successful authentication
        $resp = dancer_response GET => '/auth/twitter/callback?oauth_verifier=1';
        response_redirect_location_is $resp, 'http://localhost/success',
            'Successful authentication redirects to callback_success';

        is_deeply MyApp::session('twitter_user'), \%user,
            'Twitter user data is stored in session';

    };
}


done_testing;
