use strict;
use warnings;

use Test::More tests => 1;
use t::lib::TestApp;

use Plack::Test;
use HTTP::Request::Common;

test_psgi( t::lib::TestApp::dance, sub {
    my ($app) = @_;

    my $response = $app->(GET '/optional/');
    is $response->content, 'success', 'Do not bail out on missing/undef optional params';
});

