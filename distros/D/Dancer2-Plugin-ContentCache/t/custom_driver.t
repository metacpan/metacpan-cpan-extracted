use Test2::V1 -ipP;
use Plack::Test;
use HTTP::Request::Common;
use FindBin;
use lib "$FindBin::Bin/lib";

use TestAppMemoryDriver;

my $test = Plack::Test->create( TestAppMemoryDriver->to_app );

my $uuid = $test->request( GET '/set_html' )->content;
like( $uuid, qr/^[0-9a-f-]{36}$/, 'set_html returned a uuid even with a non-DBIx::Class driver' );

my $res = $test->request( GET "/get/$uuid" );
is( $res->code, 200, 'entry retrieved through the custom MemoryDriver' );
is( $res->content, '<p>hi there</p>', 'content round-tripped through the custom driver' );

my $missing = $test->request( GET '/get/00000000-0000-0000-0000-000000000000' );
is( $missing->code, 404, 'unknown uuid still 404s with a custom driver' );

done_testing;
