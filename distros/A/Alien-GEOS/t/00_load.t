use Test::More tests => 1;

BEGIN {
    use_ok( 'Alien::GEOS' ) or BAIL_OUT('Unable to load Alien::GEOS!');
}

diag( "Testing Alien::GEOS $Alien::GEOS::VERSION, Perl $], $^X" );