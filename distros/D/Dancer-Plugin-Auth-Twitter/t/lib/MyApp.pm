package MyApp;

use strict;
use warnings;

use Dancer;
use Dancer::Plugin::Auth::Twitter;

config->{plugins}->{'Auth::Twitter'} = {
    consumer_key        => 'consumer_key',
    consumer_secret     => 'consumer_secret',
    callback_url        => 'http://localhost:3000/auth/twitter/callback',
    callback_success    => '/success',
    callback_fail       => '/fail',
};
config->{session} = 'Simple';

auth_twitter_init();

hook before => sub {
    return if request->path =~ m{/auth/twitter/callback};

    if (not session('twitter_user')) {
        redirect auth_twitter_authenticate_url;
    }
};
    
get '/' => sub {
    'This is index.'
};

get '/success' => sub {
    'Welcome, ' . session('twitter_user')->{'screen_name'};
};
    
get '/fail' => sub { 'FAIL' };

get '/clear' => sub { session twitter_user => undef; 1 };

true;
