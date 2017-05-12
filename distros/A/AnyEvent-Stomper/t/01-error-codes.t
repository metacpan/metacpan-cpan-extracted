use 5.008000;
use strict;
use warnings;

use Test::More tests => 7;
use AnyEvent::Stomper qw( :err_codes );

is( E_CANT_CONN, 1, 'E_CANT_CONN' );
is( E_IO, 2, 'E_IO' );
is( E_CONN_CLOSED_BY_REMOTE_HOST, 3, 'E_CONN_CLOSED_BY_REMOTE_HOST' );
is( E_CONN_CLOSED_BY_CLIENT, 4, 'E_CONN_CLOSED_BY_CLIENT' );
is( E_OPRN_ERROR, 5, 'E_OPRN_ERROR' );
is( E_UNEXPECTED_DATA, 6, 'E_UNEXPECTED_DATA' );
is( E_READ_TIMEDOUT, 7, 'E_READ_TIMEDOUT' );
