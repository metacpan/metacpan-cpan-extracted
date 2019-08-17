use Test::Most;
use Plack::Test;
use HTTP::Request::Common;

use FindBin qw/ $RealBin /;
use lib "$RealBin/../example/lib";

use TestApp;
 
my $test     = Plack::Test->create( TestApp->to_app );
my $response = $test->request( GET '/ping' );
 
ok( $response->is_success,              '[GET /] Successful request' );
is( $response->content, 'Hello, world', '[GET /] Correct content' );
 
done_testing();