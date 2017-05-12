use lib qw( t/lib t/lib/MyApp/lib );

BEGIN { $ENV{_CAS_VERSION} = '0.0' }

use Catalyst::Test qw( MyApp );
use Test::More;

ok( request( '/' )->is_error, 'error: invalid version' );

done_testing();
