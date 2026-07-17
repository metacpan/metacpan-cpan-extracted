use Test2::V1 -ipP;
use Plack::Test;
use HTTP::Request::Common;
use FindBin;
use lib "$FindBin::Bin/lib";

use TestAppDBIC;

my $test = Plack::Test->create( TestAppDBIC->to_app );

# set_cache + retrieve_cache round trip, html
{
    my $uuid = $test->request( GET '/set_html' )->content;
    like( $uuid, qr/^[0-9a-f-]{36}$/, 'set_html returned a uuid' );

    my $res = $test->request( GET "/get/$uuid" );
    is( $res->code, 200, 'html cache entry retrieved' );
    is( $res->header('X-Cache-Format'), 'html', 'data_format is html' );
    is( $res->content, '<p>hi there</p>', 'html content round-tripped exactly' );
    ok( $res->header('X-Cache-Life'), 'life metadata was populated by default_life' );
}

# set_cache + retrieve_cache round trip, JSON
{
    my $uuid = $test->request( GET '/set_json' )->content;

    my $res = $test->request( GET "/get/$uuid" );
    is( $res->code, 200, 'json cache entry retrieved' );
    is( $res->header('X-Cache-Format'), 'JSON', 'data_format is JSON' );
    is( $res->content, '{"foo":"bar"}', 'json content round-tripped exactly' );
}

# retrieving an unknown uuid 404s
{
    my $res = $test->request( GET '/get/00000000-0000-0000-0000-000000000000' );
    is( $res->code, 404, 'unknown uuid gives a 404' );
}

# cache_and_send ships the content directly, no redirect
{
    my $res = $test->request( GET '/send_html' );
    is( $res->code, 200, 'cache_and_send responds directly' );
    is( $res->content, '<p>sent</p>', 'cache_and_send content is correct' );

    my $json_res = $test->request( GET '/send_json' );
    is( $json_res->content, '{"sent":1}', 'cache_and_send JSON content is correct' );
}

# cache_and_redirect issues a redirect to the built-in recall route
{
    my $res = $test->request( GET '/redirect_html' );
    ok( $res->is_redirect, 'cache_and_redirect issued a redirect' );
    like( $res->header('Location'), qr{^/recall/[0-9a-f-]{36}$}, 'redirected to the recall route' );

    my $follow = $test->request( GET $res->header('Location') );
    is( $follow->content, '<p>redirected</p>', 'the recall route serves the cached content' );
}

# aging: an entry with a 1-second life expires and is treated as gone
{
    my $uuid = $test->request( GET '/set_short_life' )->content;

    my $immediate = $test->request( GET "/get/$uuid" );
    is( $immediate->code, 200, 'freshly-set short-lived entry is still there' );

    sleep 2;

    my $later = $test->request( GET "/get/$uuid" );
    is( $later->code, 404, 'expired entry is treated as not found' );

    my $cleaned = $test->request( GET '/cleanup' )->content;
    ok( $cleaned >= 1, 'clean_up_cache purged at least the expired entry' );
}

done_testing;
