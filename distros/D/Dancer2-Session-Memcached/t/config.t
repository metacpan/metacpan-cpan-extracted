package MyApp;

use Test::More;
use Test::Exception;

use Dancer2;

sub session_setting($) {
    setting(
        engines => {
            session => {
                Memcached => {
                    memcached_servers => shift,
                }
            }
        }
    );
    setting( session => 'Memcached' );
}

my @servers = (
    '127.0.0.1:11211', '127.0.0.2:11211',
);

for my $config ( \@servers, join ',', @servers ) {
    session_setting( $config );

    is_deeply engine('session')->memcached_servers,
        [qw/ 127.0.0.1:11211 127.0.0.2:11211/];
}

throws_ok {
    session_setting(  { a => 1 } )
} qr/MemcachedServers/;

throws_ok {
    session_setting( '127.0.0.1' )
} qr/port is missing/;

done_testing;
