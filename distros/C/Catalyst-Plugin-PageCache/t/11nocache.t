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
ok( my $res = request('http://localhost/cache/no_cache'), 'request ok' );
is( $res->content, 1, 'count is 1' );

# page will be served from cache and have http headers
ok( $res = request('http://localhost/cache/no_cache'), 'request ok' );
is( $res->content, 1, 'count is still 1 from cache' );

is( $res->headers->{'cache-control'}, 'no-cache', 'cache-control header ok' );
is( $res->headers->{'pragma'}, 'no-cache', 'pragma header ok' );
ok( !$res->headers->last_modified, 'last-modified header not included' );



