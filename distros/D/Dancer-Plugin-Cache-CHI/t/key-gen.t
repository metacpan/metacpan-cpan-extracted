package TestApp;

use strict;
use warnings;

use lib 't';

use Dancer qw/:syntax :tests/;
use Dancer::Plugin::Cache::CHI;

use Dancer::Test;
use Test::More;

set plugins => {
    'Cache::CHI' => { driver => 'Memory', global => 1, expires_in => '1 min' },
};

check_page_cache;

for my $i ( qw/ foo bar / ) {
    get "/$i" => sub { cache_page $i };
}

get '/keys' => sub {
    my $cache = cache();
    return join " : ", sort $cache->get_keys('Default');
};

plan tests => 6;

response_content_is '/foo', 'foo';
response_content_is '/bar', 'bar';

response_content_is '/keys', '/bar : /foo';

cache_page_key_generator sub {
    return join ":", request()->host, request()->path_info;
};

response_content_is '/foo', 'foo';
response_content_is '/bar', 'bar';

response_content_is '/keys', '/bar : /foo : localhost:/bar : localhost:/foo';
