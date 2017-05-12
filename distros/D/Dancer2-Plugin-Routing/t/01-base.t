#!perl -T
use strict;
use warnings;
use Plack::Builder;
use Plack::Test;
use Test::More import => ['!pass'];
use HTTP::Request::Common qw(GET POST);
use lib '.';

eval { require Dancer2::Plugin::RootURIFor };
if ($@) {
    plan skip_all => 'Dancer2::Plugin::RootURIFor required to run these tests';
}

use t::lib::TestApp;
use t::lib::TestAPI;

my $app = builder {
    mount '/'    => t::lib::TestApp->to_app;
    mount '/api' => t::lib::TestAPI->to_app;
};
is( ref $app, "CODE", "Got a code ref" );
my $moved = q~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <title>Moved</title>
    </head>
    <body>
   <p>This item has moved <a href="http://localhost/">here</a>.</p>
</body>
</html>
~;
test_psgi $app, sub {
    my $cb = shift;

    {
        my $res = $cb->( GET '/' );
        is $res->content, '/api', 'template var for api';
    }

    {
        my $res = $cb->( POST '/path' );
        is $res->content, $moved, 'post redirect from root path';
    }

    {
        my $res = $cb->( GET '/path' );
        is $res->content, $moved, 'get redirect from root path';
    }

    {
        my $res = $cb->( GET '/routing_for/api' );
        is $res->content, '/api', 'get redirect from root path';
    }

    {
        my $res = $cb->( GET '/routing_for' );
        is $res->content, '', 'get redirect from root path';
    }

    {
        my $res = $cb->( GET '/package_for' );
        is $res->content, '', 'get redirect from root path';
    }

    {
        my $res = $cb->( GET '/package_for/api' );
        is $res->content, 'TestAPI', 'get redirect from root path';
    }

    {
        my $res = $cb->( GET '/packages' );
        is $res->content, 2, 'get packages';
    }

    {
        my $res = $cb->( GET '/api/' );
        is $res->content, $moved, 'get redirect from api root';
    }

    {
        my $res = $cb->( POST '/api/path' );
        is $res->content, $moved, 'post redirect from api path';
    }

    {
        my $res = $cb->( GET '/api/path' );
        is $res->content, $moved, 'get redirect from api path';
    }

};

done_testing();

__END__
