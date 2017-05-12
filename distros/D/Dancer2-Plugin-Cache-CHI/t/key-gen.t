use strict;
use warnings;

use Test::More tests => 7;
use Plack::Test;
use HTTP::Request::Common;

{
    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Cache::CHI;

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
}

my $app = Dancer2->runner->psgi_app;
is ref $app, 'CODE', 'got app';

test_psgi $app, sub {
    my $cb  = shift;
    is $cb->(GET '/foo')->content, 'foo';
    is $cb->(GET '/bar')->content, 'bar';
    is $cb->(GET '/keys')->content, '/bar : /foo';
};

{
    package TestApp;
    cache_page_key_generator sub {
        return join ":", request()->host, request()->path_info;
    };
}

test_psgi $app, sub {
    my $cb  = shift;
    is $cb->(GET '/foo')->content, 'foo';
    is $cb->(GET '/bar')->content, 'bar';
    is $cb->(GET '/keys')->content, '/bar : /foo : localhost:/bar : localhost:/foo';
};
