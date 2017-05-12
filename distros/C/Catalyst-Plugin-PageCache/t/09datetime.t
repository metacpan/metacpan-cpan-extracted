#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Path;

BEGIN {
    eval "use Catalyst::Plugin::Cache";
    if ( $@ ) {
        plan ( skip_all => 'needs Catalyst::Plugin::Cache for testing' );
    } else {
        eval "use DateTime";
        if ( $@ ) {
            plan ( skip_all => 'needs DateTime for testing' );
        } else {
            plan ( tests => 7 );
        }
    }
}

# This tests that a DateTime object can be passed in.

use Catalyst::Test 'TestApp';

# add config option
TestApp->config->{'Plugin::PageCache'}->{set_http_headers} = 1;

# cache a page
my $cache_time = time + 1;
1 while time < $cache_time; # spin till clock ticks to make test more robust
ok( my $res = request('http://localhost/cache/test_datetime'), 'request ok' );
is( $res->content, 1, 'count is 1' );

# page will be served from cache and have http headers
ok( $res = request('http://localhost/cache/test_datetime'), 'request ok' );
is( $res->content, 1, 'count is still 1 from cache' );

# avoid race conditions by not testing for exact times
like( $res->headers->{'cache-control'}, qr/max-age=\d{3}/, 'cache-control header ok' );
cmp_ok( $res->headers->last_modified, '>=', $cache_time, 'last-modified header matches correct time' );

require DateTime;

my $dt_epoch = DateTime->new( day => 24, month => 1, year => 2026, time_zone => 'UTC' )->epoch;
is( $res->headers->expires, $dt_epoch, 'expires header matches correct time' );



