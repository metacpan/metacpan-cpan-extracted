#!perl

use strict;
use warnings;
no warnings 'redefine';

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Path;

BEGIN {
    eval "use Catalyst::Plugin::Cache";
    plan $@
        ? ( skip_all => 'needs Catalyst::Plugin::Cache for testing' )
        : ( tests => 16 );
}

# This test that options can be passed to cache.

use Catalyst::Test 'TestApp';

# add config option
TestApp->config->{'Plugin::PageCache'}->{set_http_headers} = 1;
TestApp->config->{'Plugin::PageCache'}->{cache_hook}   = 'use_pagecache';

local *TestApp::use_pagecache = sub { 0 };
cmp_ok( TestApp->use_pagecache(), '==', '0' );

# Load the page that can be cached, but we shouldn't cache it because of
# use_pagecache
ok( my $res = request('http://localhost/cache/no_cache'), 'request ok' );
is( $res->content, 1, 'count is 1' );

# Page won't be served from cache, and shouldn't have any headers
ok( $res = request('http://localhost/cache/no_cache'), 'request ok' );
is( $res->content, 2, 'count is 2' );

isnt( $res->headers->{'cache-control'}, 'no-cache', 'cache-control header ok' );
isnt( $res->headers->{'pragma'}, 'no-cache', 'pragma header ok' );
ok( !$res->headers->last_modified, 'last-modified header not included' );

local *TestApp::use_pagecache = sub { 1 };
cmp_ok( TestApp->use_pagecache(), '==', '1' );

# page will not be served from cache, but will be next request.
ok( $res = request('http://localhost/cache/no_cache'), 'request ok' );
is( $res->content, 3, 'count is 3' );

# page will be served from cache and have http headers
ok( $res = request('http://localhost/cache/no_cache'), 'request ok' );
is( $res->content, 3, 'count is still 3' );

is( $res->headers->{'cache-control'}, 'no-cache', 'cache-control header ok' );
is( $res->headers->{'pragma'}, 'no-cache', 'pragma header ok' );
ok( !$res->headers->last_modified, 'last-modified header not included' );



