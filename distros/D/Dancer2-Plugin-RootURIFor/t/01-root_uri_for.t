use strict;
use warnings;

use Test::More tests => 6;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;

{
    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::RootURIFor;

    get '/uri_for' => sub {
        uri_for '/foo';
    };

    get '/root_uri_for' => sub {
        root_uri_for '/foo';
    };

    get '/root_uri_for_with_param' => sub {
        root_uri_for '/foo', { bar => 'baz' };
    };

}

{
    my $app = builder {
        mount '/app1' => TestApp->psgi_app;
        mount '/app2' => TestApp->psgi_app;
        mount '/'     => TestApp->psgi_app;
    };

    test_psgi $app, sub {
        my ( $app ) = @_;

        is (
            $app->( GET '/app1/uri_for' )->content,
            'http://localhost/app1/foo',
            "app1's uri_for returns relative uri"
        );
        is (
            $app->( GET '/app2/uri_for' )->content,
            'http://localhost/app2/foo',
            "app2's uri_for returns relative uri"
        );
        is (
            $app->( GET '/app1/root_uri_for' )->content,
            'http://localhost/foo',
            "app1's root_uri_for returns root uri"
        );
        is (
            $app->( GET '/app2/root_uri_for' )->content,
            'http://localhost/foo',
            "app2's root_uri_for returns root uri"
        );
        is (
            $app->( GET '/root_uri_for' )->content,
            $app->( GET '/uri_for' )->content,
            "root_uri_for equals uri_for on root mounted app"
        );
        is (
            $app->( GET '/app1/root_uri_for_with_param' )->content,
            'http://localhost/foo?bar=baz',
            "root_uri_for generates URI parameters"
        );
    };
}

