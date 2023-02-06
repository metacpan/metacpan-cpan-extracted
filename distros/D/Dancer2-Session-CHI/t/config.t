package MyApp;

use Test::More;
use Test::Exception;

use Dancer2;

sub session_setting {
    my $set = shift // 0;

    if( $set ) {
        setting(
            engines => {
                session => {
                    CHI => {
                        driver => 'FastMmap'
                    }
                }
            }
        );
    }
    setting( session => 'CHI' );
}

throws_ok { session_setting() }
    qr/Missing required arguments: driver/,
    'Dies ok when no driver specified';

session_setting( 1 );
is( engine( 'session' )->driver, 'FastMmap', 'Set the session driver successfully' );

done_testing;
