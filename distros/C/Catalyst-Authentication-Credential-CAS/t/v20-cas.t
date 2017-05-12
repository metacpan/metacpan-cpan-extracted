use lib qw( t/lib t/lib/MyApp/lib );

BEGIN { $ENV{_CAS_VERSION} = '2.0' }

use Catalyst::Test qw( MyApp );
use Test::More;

ok( request( '/' )->is_redirect, 'Should redirect for auth' );
ok( request( '/?ticket=ST-USER:user' )->is_success, 'Should succeed' );
ok( request( '/?ticket=ST-USER:notuser' )->is_error, 'User not found' );
ok( request( '/?ticket=ST-FAIL' )->is_error, 'Should fail' );
ok( request( '/?ticket=ST-ERROR' )->is_error, 'Should fail' );

done_testing();
