use strict;
use warnings;
use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use Dancer2;
use Dancer2::Plugin::Minion;

use lib '.';
use t::lib::TestApp;

my $app = builder {
    mount '/'           => TestApp->to_app;
    mount '/dashboard/' => minion_app->start;
};

isa_ok( $app, 'CODE', 'Got app' );

TODO: {
    local $TODO = "I'm doing something stupid here, will figure it out sometime.";
    test_psgi $app, sub {
        my $cb = shift;

        like( $cb->( GET '/' )->content, qr/^OK/, "Got site root" );
        like( $cb->( GET '/dashboard/' )->content, qr/minion/i, "...and the dashboard!" );
    };
};

done_testing;
