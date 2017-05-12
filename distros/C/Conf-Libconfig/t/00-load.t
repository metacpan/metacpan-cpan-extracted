#!perl -T
use Test::More tests => 1;

BEGIN {
    use_ok( 'Conf::Libconfig' );
}

diag( "Testing Conf::Libconfig $Conf::Libconfig::VERSION, Perl $], $^X" );
