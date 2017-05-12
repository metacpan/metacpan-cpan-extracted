# Tests that cache initialization done by check_page_cache works
# See https://github.com/yanick/Dancer2-Plugin-Cache-CHI/issues/5

use strict;
use warnings;

use Test::More tests => 2;
use Plack::Test;
use HTTP::Request::Common;

{
    package TestApp;

    use Dancer2;
    use Dancer2::Plugin::Cache::CHI;

    set plugins => { 'Cache::CHI' => { driver => 'Memory', global => 1 } };

    check_page_cache;

    get '/test' => sub {
        return 42;
    };
}

my $app = Dancer2->runner->psgi_app;
is ref $app, 'CODE', 'Got app';

test_psgi $app, sub {
    my $cb  = shift;
    is $cb->(GET '/test')->content, 42, 'Simple GET';
};
