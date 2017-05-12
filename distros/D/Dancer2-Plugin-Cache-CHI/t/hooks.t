use strict;
use warnings;

use Test::More tests => 2;
use Plack::Test;
use HTTP::Request::Common;

{
    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Cache::CHI;

    set plugins => {
        'Cache::CHI' => { driver => 'Memory', global => 1, expires_in => '1 min' },
    };

    hook 'plugin.cache_chi.before_create_cache' => sub {
        config->{plugins}{'Cache::CHI'}{namespace} = 'Foo';
    };

    get '/namespace' => sub {
        cache()->namespace;
    };
}

my $app = Dancer2->runner->psgi_app;
is ref $app, 'CODE', 'got app';

test_psgi $app, sub {
    my $cb  = shift;

    is $cb->(GET '/namespace')->content, 'Foo', 'namespace configured';
}
