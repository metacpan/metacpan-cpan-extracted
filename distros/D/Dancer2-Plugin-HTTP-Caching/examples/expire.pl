use Dancer2;
use lib '../lib';
use Dancer2::Plugin::HTTP::Caching;

get '/hello' => sub {
    "Hello World"
};

get '/the_end' => sub {
    http_expire "Mon, 31 Dec 2012 23:59:59 GMT";
    "Good Bye World"
};

dance;