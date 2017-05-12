package TestApp;

use strict;
use warnings;

use Dancer;
use Dancer::Plugin::Memcached;

get '/' => sub
{
    'Test Module Loaded';
};

get '/set_test/:data' => sub
{
    my $data = params->{data};
    memcached_set $data;
};

post '/get_test' => sub
{
    my $uri = params->{data};
    memcached_get $uri;
};

post '/store_test' => sub
{
    my $key  = params->{key};
    my $data = params->{data};

    memcached_store $key, $data;
};

get '/fetch_stored' => sub
{
    my $key = params->{key};
    memcached_get $key;
};

1;
