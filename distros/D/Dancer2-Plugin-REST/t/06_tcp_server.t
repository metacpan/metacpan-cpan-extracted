use strict;
use warnings;

use Plack::Test;
use HTTP::Request::Common qw(GET POST PUT DELETE);

use Test::More tests => 1;

{ package Webservice;  

    use Dancer2;
    use Dancer2::Plugin::REST;

    prepare_serializer_for_format;

    get '/:something.:format' => sub {
        { hello => 'world' };
    };
}

my $app = Dancer2->runner->psgi_app;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->( GET "/foo.json", 'Content-Type' => 'application/json' );
    is $res->content => '{"hello":"world"}';
};


