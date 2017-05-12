#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 4;
use Catalyst::Test 'TestApp';

TestApp->config->{require_ssl} = {
    no_cache => 1,
};

# test an SSL redirect
ok( my $res = request('http://localhost/ssl/secured'), 'request ok' );
is( $res->code, 302, 'redirect code ok' );
is( $res->header('location'), 'https://localhost/ssl/secured', 'redirect uri ok' );

# test that the http/https server info wasn't cached
ok( !TestApp->config->{https}, 'domain was not cached' );