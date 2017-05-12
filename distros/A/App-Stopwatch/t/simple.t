use strict;
use warnings FATAL => 'all';

use Test::More;

sub main_in_test {

    require 'bin/stopwatch';

    pass('Loaded ok');

    is_deeply( [get_h_m_s(0)], [0,0,0], 'get_h_m_s()' );
    is_deeply( [get_h_m_s(59)], [0,0,59], 'get_h_m_s()' );
    is_deeply( [get_h_m_s(60)], [0,1,0], 'get_h_m_s()' );

    is( get_seconds_from_string( '3s' ), 3, 'get_seconds_from_string()' );
    is( get_seconds_from_string( '20m' ), 1200, +'get_seconds_from_string()' );
    is( get_seconds_from_string( '5 S' ), 5, 'get_seconds_from_string()' );
    is( get_seconds_from_string( '10M' ), 600, 'get_seconds_from_string()' );

    eval { get_seconds_from_string( '01000s' ) };
    like( $@, qr/Can't parse/, 'get_seconds_from_string()' );

    eval { get_seconds_from_string( 'asdf' ) };
    like( $@, qr/Can't parse/, 'get_seconds_from_string()' );

    eval { get_seconds_from_string( 4 ) };
    like( $@, qr/Can't parse/, 'get_seconds_from_string()' );

    done_testing();

}
main_in_test();
