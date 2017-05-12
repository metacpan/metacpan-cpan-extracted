#! perl

use strict;
use warnings;
use Test::More;

use lib qw(lib t/lib);

BEGIN {
    $ENV{CATALYST_DEBUG} = 0;
}

use Test::WWW::Mechanize 1.46;    # For the header_xxx tests
use Test::WWW::Mechanize::Catalyst;

my $no_cache
    = 'no-cache, no-store, must-revalidate, max-age=0, max-stale=0, post-check=0, pre-check=0, private';

my $mech = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'Test::App' );

{
    note('Testing no special headers');

    $mech->get('/');
    $mech->content_contains("index page");

    $mech->lacks_header_ok( 'Surrogate-Control',
        'No Surrogate-Control header' );
    $mech->lacks_header_ok( 'Cache-Control', 'No Cache-Control header' );
    $mech->lacks_header_ok( 'Pragma',        'No Pragma header' );
    $mech->lacks_header_ok( 'Expires',       'No Expires header' );
}

{
    note('Testing XXX_never_cache headers');

    $mech->get('/page_with_no_caching');
    $mech->content_contains("No caching here");

    $mech->lacks_header_ok( 'Surrogate-Control',
        'Surrogate-Control not there as expected' );
    $mech->header_is( 'Cache-Control', $no_cache,
        'Cache-Control for no-cache' );
    $mech->header_is( 'Pragma',  'no-cache', 'Pragma: no-cache' );
    $mech->header_is( 'Expires', '0',        'Expires: 0' );
}

{
    note('Some caching headers');

    $mech->get('/some_caching');
    $mech->content_contains("Browser and CDN cacheing different max ages");

    $mech->header_is(
        'Surrogate-Control',
        'max-age=600, stale-while-revalidate=86400, stale-if-error=172800',
        'Surrogate-Control: set to max-age=600, stale-while-revalidate=86400, stale-if-error=172800'
    );
    $mech->header_is(
        'Cache-Control',
        'max-age=10, stale-while-revalidate=172800, stale-if-error=259200',
        'Cache-Control for browser set to max-age=10, stale-while-revalidate=172800, stale-if-error=259200'
    );
    $mech->lacks_header_ok( 'Pragma',  'No Pragma header' );
    $mech->lacks_header_ok( 'Expires', 'No Expires header' );

}

{
    note('Browser caching, but not CDN');

    $mech->get('/cdn_no_cache_browser_cache');
    $mech->content_contains("Browser cacheing, CDN no cache");

    $mech->header_is(
        'Cache-Control',
        'max-age=10, private',
        'Cache-Control, with private for CDN set to max-age=10, private'
    );
    $mech->lacks_header_ok( 'Surrogate-Control',
        'No Surrogate-Control header' );
    $mech->lacks_header_ok( 'Pragma',  'No Pragma header' );
    $mech->lacks_header_ok( 'Expires', 'No Expires header' );

}

{
    note('Browser caching NOT set, and not CDN');

    $mech->get('/cdn_no_browser_cache_not_set');
    $mech->content_contains("Browser cacheing not set, CDN no cache");

    $mech->header_is( 'Cache-Control', 'private',
        'Cache-Control, with private for CDN' );
    $mech->lacks_header_ok( 'Surrogate-Control',
        'No Surrogate-Control header' );
    $mech->lacks_header_ok( 'Pragma',  'No Pragma header' );
    $mech->lacks_header_ok( 'Expires', 'No Expires header' );

}

{
    note('Surrogate keys - basic');

    $mech->get('/some_surrogate_keys');
    $mech->content_contains("surrogate keys");

    $mech->header_is(
        'Surrogate-Key',
        'f%oo W1-BBL3!',
        'Surrogate-Keys: set to "f%oo W1BBL3"'
    );

    $mech->lacks_header_ok( 'Surrogate-Control',
        'No Surrogate-Control header' );
    $mech->lacks_header_ok( 'Cache-Control', 'No ache-Control header' );

    $mech->lacks_header_ok( 'Pragma',  'No Pragma header' );
    $mech->lacks_header_ok( 'Expires', 'No Expires header' );

}

done_testing();

