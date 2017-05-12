#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Path;

BEGIN {
    eval "use Catalyst::Plugin::Cache";
    plan $@
        ? ( skip_all => 'needs Catalyst::Plugin::Cache for testing' )
        : ( tests => 7 );
}

# This test that options can be passed to cache.

use Catalyst::Test 'TestApp';

# add config option
TestApp->config->{'Plugin::PageCache'}->{set_http_headers} = 1;

# cache a page
my $cache_time = time;
ok( my $res = request('http://localhost/cache/extra_options'), 'request ok' );
is( $res->content, 1, 'count is 1' );

# page will be served from cache and have http headers
ok( $res = request('http://localhost/cache/extra_options'), 'request ok' );
is( $res->content, 1, 'count is still 1 from cache' );

like( $res->headers->{'cache-control'}, qr/max-age=60/, 'cache-control header ok' );
cmp_ok( $res->headers->last_modified, '>=', $cache_time, 'last-modified header matches correct time' );
cmp_ok( $res->headers->expires, '>=', $cache_time + 60, 'expires header matches correct time' );



