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
        : ( tests => 8 );
}

use Catalyst::Test 'TestApp';

# add config option
TestApp->config->{'Plugin::PageCache'}->{auto_cache} = [
    '/cache/auto_count',
    '/cache/another.+',
];

# cache a page
ok( my $res = request('http://localhost/cache/auto_count'), 'request ok' );
is( $res->content, 1, 'count is 1' );

# page will be served from cache
ok( $res = request('http://localhost/cache/auto_count'), 'request ok' );
is( $res->content, 1, 'count is still 1 from cache' );

# test regex auto cache
ok( $res = request('http://localhost/cache/another_auto_count'), 'request ok' );
is( $res->content, 2, 'count is 2' );

# page will be served from cache
ok( $res = request('http://localhost/cache/another_auto_count'), 'request ok' );
is( $res->content, 2, 'count is still 2 from cache' );



