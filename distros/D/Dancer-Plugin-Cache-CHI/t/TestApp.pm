package
    TestApp;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin::Cache::CHI;

set plugins => {
    'Cache::CHI' => { driver => 'Memory', global => 1, expires_in => '1 min' },
};

get '/set/:attribute/:value' => sub {
    cache_set params->{attribute} => params->{value};
};

get '/get/:attribute' => sub {
    return cache_get params->{attribute};
};

my $counter;
get '/cached' => sub {
    return cache_page ++$counter;
};

get '/counter' => sub { $counter };

get '/check_page_cache' => sub {
    check_page_cache;
};

get '/clear' => sub {
    cache_clear;
};

put '/stash' => sub {
    return cache_set secret_stash => request->body;
};

get '/stash' => sub {
    return cache_get 'secret_stash';
};

del '/stash' => sub {
    return cache_remove 'secret_stash';
};

my $computed = 'aaa';
get '/compute' => sub {
    return cache_compute compute => sub { ++$computed };
};

my $cached_quick;
get '/expire_quick' => sub {
    return cache_page ++$cached_quick, 2;
};

my $headers;
hook before => sub {
    header 'X-Foo' => ++$headers;
};

get '/clear_headers' => sub { $headers = 0 };
get '/headers' => sub {
    cache_page 'gonzo';
};



1;
