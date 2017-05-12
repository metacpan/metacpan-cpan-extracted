package TestApp2;

use strict;
use warnings;

use Catalyst qw/
    Authentication
    Session
    Session::Store::FastMmap
    Session::State::Cookie
/;


__PACKAGE__->config(
    "Plugin::Authentication" => {
        default_realm => "twitter",
        realms => {
            twitter => { 
                credential => { class => "Twitter", },
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

TestApp2->setup;

1;
