use Test::More tests => 1;

BEGIN {
    use_ok( 'Alien::FFCall' ) or BAIL_OUT('Unable to load Alien::FFCall!');
}

diag( "Testing Alien::FFCall $Alien::FFCall::VERSION, Perl $], $^X" );
