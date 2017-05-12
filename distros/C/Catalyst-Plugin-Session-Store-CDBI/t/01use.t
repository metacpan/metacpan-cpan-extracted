use Test::More tests => 2;

use_ok('Catalyst::Plugin::Session::Store::CDBI');
can_ok( 'Catalyst::Plugin::Session::Store::CDBI',
    qw/get_session_data store_session_data delete_session_data delete_expired_sessions/
);
