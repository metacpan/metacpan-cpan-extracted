use Test::More tests => 4;

use lib 'lib';

BEGIN {
    use_ok( 'Apache::Logmonster' );
    use_ok( 'Apache::Logmonster::Utility' );
}

diag( "Testing Apache::Logmonster $Apache::Logmonster::VERSION" );

ok( Apache::Logmonster->new(), 'new Apache::Logmonster');
ok( Apache::Logmonster::Utility->new(), 'new Apache::Logmonster::Utility');

