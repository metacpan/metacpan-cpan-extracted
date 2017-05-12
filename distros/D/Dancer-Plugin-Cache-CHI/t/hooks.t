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

hook before_create_cache => sub {
    config->{plugins}{'Cache::CHI'}{namespace} = 'Foo';
};

get '/namespace' => sub {
    cache->namespace;
};

plan tests => 1;

response_content_is '/namespace', 'Foo', 'namespace configured';
