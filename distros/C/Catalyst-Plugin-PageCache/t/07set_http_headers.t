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
        : ( tests => 11 );
}

use Catalyst::Test 'TestApp';

# add config options
TestApp->config->{'Plugin::PageCache'}->{cache_headers}    = 1;
TestApp->config->{'Plugin::PageCache'}->{set_http_headers} = 1;

# cache a page
my $cache_time = time;
ok( my $res = request('http://localhost/cache/count'), 'request ok' );
is( $res->content, 1, 'count is 1' );

# page will be served from cache and have http headers
ok( $res = request('http://localhost/cache/count'), 'request ok' );
is( $res->content, 1, 'count is still 1 from cache' );

# avoid race conditions by not testing for exact times
like( $res->headers->{'cache-control'}, qr/max-age=\d{3}/, 'cache-control header ok' );
cmp_ok( $res->headers->last_modified, '>=', $cache_time, 'last-modified header matches correct time' );
cmp_ok( $res->headers->expires, '>=', $cache_time + 300, 'expires header matches correct time' );

#check that extension headers are cached and returned
ok( $res = request('http://localhost/cache/cache_extension_header/10'), 'request ok' );
is( $res->headers->header('X-Bogus-Extension'), 'True', 'Bogus header returned');
ok( $res = request('http://localhost/cache/cache_extension_header/10'), 'request ok' );
is( $res->headers->header('X-Bogus-Extension'), 'True', 'Bogus header returned from cache');
