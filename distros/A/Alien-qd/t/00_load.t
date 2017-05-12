use Test::More tests => 1;

BEGIN {
    use_ok( 'Alien::qd' ) or BAIL_OUT('Unable to load Alien::qd!');
}

diag( "Testing Alien::qd $Alien::qd::VERSION, Perl $], $^X" );