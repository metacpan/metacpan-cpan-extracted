use Dancer2;
use lib '../lib';
use Dancer2::Plugin::HTTP::Caching;

get '/hello' => sub {
    "Hello World"
};

get '/aging' => sub {
    http_cache_max_age 'oops';
    http_cache_private;
    http_cache_must_revalidate;
    http_cache_no_cache 'Set-Cookie';
    http_cache_no_cache 'WWW-Authenticate';
    http_cache_no_cache qw(one two three);
    "1 Hour"
};

dance;