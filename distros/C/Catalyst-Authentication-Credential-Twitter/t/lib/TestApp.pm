package TestApp;

use strict;
use warnings;

use Catalyst qw/
    Authentication
    Session
    Session::Store::FastMmap
    Session::State::Cookie
    Session::PerUser
/;


__PACKAGE__->config(
    "Plugin::Authentication" => {
        default_realm => "twitter",
        realms => {
            twitter => { 
                credential => { class => "Twitter", },
                store => { class => 'Null' },
                consumer_key    => 'twitter-consumer_key-here',
                consumer_secret => 'twitter-secret-here',
                callback_url => 'http://homysite.com/callback',
                    # you can bypass the above by including
                    # "twitter_consumer_key", "twitter_consumer_secret",
                    # and "twitter_callback_url" in your Catalyst site
                    # configuration or yml file
                }
       }
    },
);

TestApp->setup;

1;
